#!/usr/bin/env bash

#  shellcheck disable=2034  ## 'variable appears unused.' Everything here is consumed by cicd.bash after sourcing.
#  shellcheck enable=require-variable-braces  ## Every expansion braced: "${var}", not "$var".

##	Purpose:
##		- Project settings for flisty's pipeline. cicd.bash stays generic.
##		- All paths are relative to the repo root; the engine cds there first.
##	History: At bottom of script.

##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under the GNU General Public License v2.0 or later. Full text at:
##		https://spdx.org/licenses/GPL-2.0-or-later.html
##	SPDX-License-Identifier: GPL-2.0-or-later


## Only allow running 'sourced'.
declare -i isSourced_f7kq2=0; [[ "${BASH_SOURCE[0]}" == "${0}" ]] || isSourced_f7kq2=1
((isSourced_f7kq2)) || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}"): This script is meant to be 'sourced' from within another script.\n"; exit 1; }


APP_NAME="flisty"
EXE_NAME="flisty"

## The module root, and the main package under it.
GO_MODULE_DIR="source"
GO_MAIN_PKG="./cmd/flisty"

## Same flags at every build site, so a release can be rebuilt to its published checksum.
## -trimpath and -buildvcs=false keep the box and the repo state out of the binary, -buildid=
## drops the last stamp that varies, and -s -w make it smaller. CGO_ENABLED=0 and GOAMD64=v1
## go with them wherever they're used.
GO_BUILD_FLAGS=(-trimpath -buildvcs=false)
GO_LDFLAGS_COMMON="-s -w -buildid="

## Recorded, compared, and warned about. Never installed or enforced.
GO_TOOL_VERSIONS=(
	"staticcheck=v0.7.0"
	"golangci-lint=v2.12.2"
	"govulncheck=v1.5.0"
)
TOOL_VERSIONS=(
	"shellcheck=0.11.0"
	"markdownlint=0.49.1"
)

## Half the cores, rounded down, or a quarter on a busy box (1-minute load over half the cores).
## HEAVY_JOBS is a quarter either way, for go test -race and native fuzzing. Never under 1.
## fCpuJobs VAR CORES LOAD HEAVY sets VAR, with LOAD as the load average prints it.
fCpuJobs(){
	local -n jobs_cpuJ="$1"
	local -i cores=1 load100=0
	local load="${3:-0}" frac=""
	## Checked first, since arithmetic would run what a bad one holds.
	[[ "$2" =~ ^[1-9][0-9]{0,5}$ ]] && cores="$2"
	frac="${load#*.}"; [[ "${load}" == *.* ]] || frac=""; frac="${frac}00"
	if [[ "${load%%.*}" =~ ^[0-9]+$ && "${frac:0:2}" =~ ^[0-9]+$ ]]; then load100=$(( 10#${load%%.*} * 100 + 10#${frac:0:2} )); fi
	jobs_cpuJ=$(( cores / 2 ))
	if [[ "$4" == 1 ]] || (( load100 * 2 > cores * 100 )); then jobs_cpuJ=$(( cores / 4 )); fi
	(( jobs_cpuJ >= 1 )) || jobs_cpuJ=1
}
fCpuBudget(){
	local rest="" jobs=0
	if [[ -z "${cpuCores:-}" ]]; then
		cpuCores="$( nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2 )"
	fi
	cpuLoad=""
	if [[ -r /proc/loadavg ]]; then read -r cpuLoad rest < /proc/loadavg || true
	else cpuLoad="$( sysctl -n vm.loadavg 2>/dev/null || true )"; cpuLoad="${cpuLoad#\{ }"; cpuLoad="${cpuLoad%% *}"; fi
	fCpuJobs jobs "${cpuCores}" "${cpuLoad}" 0; BUILD_JOBS="${jobs}"
	fCpuJobs jobs "${cpuCores}" "${cpuLoad}" 1; HEAVY_JOBS="${jobs}"
}
fCpuBudget
## Low priority for the caller, and so for everything it starts.
fLowPriority(){
	renice 19 -p "$$" >/dev/null 2>&1 || true
	if command -v ionice >/dev/null 2>&1; then ionice -c 3 -p "$$" >/dev/null 2>&1 || true; fi
}

## Lint. shellcheck gates, and nothing auto-formats the shell scripts.
SHELL_LINT_GLOBS=(
	"cicd/*.bash"
	"cicd/utility/*.bash"
	"cicd/utility/n8git_backup-and-publish"
	"cicd/utility/include/*.bash"
)
## The license, conduct, and contributing texts are stock, so they stay as they came.
MD_LINT_GLOBS=(
	"README.md"
	"changelog.md"
	"style_guide.md"
	"trademark.md"
	"project/*.md"
)

## Regression suite against the built binary.
TEST_CMD=(cicd/test.bash)

## Each run's output, GFS-rotated, for lint-report.bash.
LINT_LOG_DIR="cicd/artifacts/lint"

## Dogfood: the native build goes to the first dir here that exists and is writable.
DOGFOOD_TARGETS=("linux/amd64")
DOGFOOD_DESTS_LINUX_AMD64=(
	"${HOME}/synced/0-0/common/exec/util/linux/bin"
	"${HOME}/.local/bin"
)

## Backup + publish, run from the repo root. The engine passes --quiet, and -m when it has one.
GIT_PUBLISH=(cicd/utility/n8git_backup-and-publish)
PUBLISH_AUTO_MESSAGE=""


##	History:
##		- 2026-10-28 JC: Created, trimmed from gitsby's.
