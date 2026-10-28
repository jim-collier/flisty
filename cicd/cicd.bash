#!/usr/bin/env bash

#  shellcheck disable=1091  ## 'source is valid here, but shellcheck doesn't know the path to it.'
#  shellcheck disable=2001  ## 'See if you can use ${variable//search/replace} instead.' Complains about good uses of sed.
#  shellcheck disable=2034  ## 'variable appears unused.' Complains about valid use of variable indirection (e.g. later use of local -n var=$1)
#  shellcheck disable=2153  ## 'Possible misspelling.' False hits on vars assigned in the sourced config.bash.
#  shellcheck disable=2154  ## 'referenced but not assigned.' False hit on trap strings that assign the var they use (rc=$?).
#  shellcheck disable=2155  ## 'Declare and assign separately to avoid masking return values.' Cumbersome and unnecessary.
#  shellcheck disable=2317  ## 'Can't reach.' (I.e. an 'exit' is used for debugging - and makes an unusable visual mess.)
#  shellcheck enable=require-variable-braces  ## Every expansion braced: "${var}", not "$var".

##	- Purpose: Local CI/CD pipeline for flisty. Project settings live in config.bash.
##	- Steps (fail-fast, any error aborts before the next step):
##	   remote sync, lint, build + tests, fuzz + security, dogfood, backup + publish
##	- Syntax:
##	  cicd/cicd.bash [options]
##	  Options:
##	   -q, --quiet         quiet + unattended (no prompt)
##	   -y, --yes           unattended (no prompt) but not quiet
##	   -m, --message MSG   publish hands-off with this commit message
##	       --msg MSG       alias for --message
##	   --no-sync           skip the remote sync
##	   --no-lint           skip lint
##	   --no-test           skip the build and tests
##	   --no-fuzz           skip fuzz + security
##	   --no-dogfood        skip installing the build locally
##	   --no-publish        skip the git backup + publish
##	   --quick             what fits in about 10 minutes: leaves out govulncheck, which asks a server
##	   --long              everything; nothing here takes hours yet, so the same as no flags
##	       --slow          alias for --long
##	   --leakcheck         run every leak check (there are none yet; see the backlog)
##	   --no-leakcheck      skip the leak checks
##	   --no-container      run on this box (there's no container yet, so every run does)
##	   --no-remote         skip other hosts and VMs (none yet)
##	   --backlog-run-quick [AREA...]
##	                       what a backlog worker runs before it commits, every area or only those named:
##	                         lint    every lint and format check
##	                         unit    the Go unit tests
##	                         suite   the build, then the regression suite
##	                         fuzz    the native fuzz targets
##	   --gate [AREA...]    alias for --backlog-run-quick
##	   --backlog-run-full  what a backlog round runs once at its end: every check of a plain run
##	   --merge-gate        the same checks, before a merge to main
##	       --ci            alias for --merge-gate
##	                       None of those three dogfoods, publishes, commits, pushes, installs, syncs,
##	                       prompts, or rewrites a tracked file.
##	   --keep-temp         keep the run's temp folder, and say where it is at the end
##	   --list              print the steps and test IDs the other options would run, and run nothing
##	   -h, --help          show this help
##	- If neither -q/-y nor -m is given, the run prompts once for a commit message
##	  (blank = git editor; Ctrl+C aborts the whole run), then finishes unattended.

##	History: At bottom of script.

##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under the GNU General Public License v2.0 or later. Full text at:
##		https://spdx.org/licenses/GPL-2.0-or-later.html
##	SPDX-License-Identifier: GPL-2.0-or-later


if (( BASH_VERSINFO[0] * 100 + BASH_VERSINFO[1] < 404 )); then
	printf '%s\n' "${0##*/}: needs bash 4.4 or newer, and this is bash ${BASH_VERSION}. On macOS, install one with 'brew install bash' and put it first on PATH." >&2; exit 1
fi
set -Eeuo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${here}/.." && pwd)"
export PATH="${HOME}/.local/bin:${PATH}"   ## user-prefix npm tools (markdownlint) win
source "${here}/config.bash"
## Go takes only a .git folder for a repo, so from a hook's worktree it stamps the wrong one.
export GOFLAGS="${GOFLAGS:+${GOFLAGS} }-buildvcs=false"
source "${here}/utility/include/gfs-rotate.bash"
source "${here}/utility/include/go-test-lines.bash"
source "${here}/utility/include/safe-rm.bash"
fLowPriority
cd "${root}"
stamp="$(date +%Y%m%d-%H%M%S)"

## printf, not 'echo -e': a typed commit message passes through here.
declare -i __wasLastEchoBlank=0
fEcho_ResetBlankCounter(){ __wasLastEchoBlank=0; }
fEcho_Clean(){
	if [[ -n "${1:-}" ]]; then printf '%s\n' "$*"; __wasLastEchoBlank=0
	elif ((! __wasLastEchoBlank)); then echo; __wasLastEchoBlank=1; fi
}
fEcho(){       if [[ -n "$*"     ]]; then fEcho_Clean "[ $* ]"; else fEcho_Clean ""; fi; }
fEcho_Force(){ fEcho_ResetBlankCounter; fEcho "$*"; }
__letterbox="•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••"
fSection(){ fCpuBudget; fEcho_Clean; fEcho_Clean "${__letterbox}"; fEcho "$*"; [[ "${stagePause:-0}" == 0 ]] || sleep "${stagePause}"; }
declare -A stepTitle=([sync]="Remote sync" [lint]="Lint" [test]="Build + tests" [fuzz]="Fuzz + security" [dogfood]="Dogfood" [publish]="Backup + publish")
stepList=(); stepTotal=0; stepName=""; stepWhere=""
fStepTime(){
	if [[ "${EPOCHREALTIME:-}" =~ ^([0-9]+)[.,]([0-9]{2}) ]]; then printf '%(%Y%m%d-%H%M%S)T.%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
	else printf '%(%Y%m%d-%H%M%S)T.00' -1; fi
}
fStepOf(){ local i; for i in "${!stepList[@]}"; do [[ "${stepList[i]}" != "$1" ]] || { printf 'Step %s of %s' "$((i + 1))" "${stepTotal}"; return 0; }; done ;}
fStep(){ stepName="${stepTitle[$1]:-$1}"; stepWhere="$(fStepOf "$1")"; fSection "$(fStepTime): ${stepWhere}; Starting ${stepName}" ;}
## PASS, or FAIL from the exit trap for a step a failure left open.
fStepEnd(){ [[ -n "${stepName}" ]] || return 0; fEcho "$(fStepTime): ${stepWhere}; ${1:-PASS} ${stepName}"; stepName="" ;}
fDie(){ { fEcho_Force "FAILED: $*"; } >&2; exit 1; }
fUsage(){ fEcho_Clean "$*" >&2; exit 2; }

assumeYes=0; quiet=0; quick=0; leakOpt=""; doSync=1; doLint=1; doTest=1; doFuzz=1; cliMessage=""
gate=0; gateAreas=(); handsOff=""; aliasNote=""; keepTemp=0; listOnly=0; stageOpts=()
while (($#)); do case "$1" in
	-q|--quiet)               quiet=1; assumeYes=1; shift ;;
	-y|--yes)                 assumeYes=1; shift ;;
	--no-sync)                doSync=0; stageOpts+=("$1"); shift ;;
	--no-lint)                doLint=0; stageOpts+=("$1"); shift ;;
	--no-test)                doTest=0; stageOpts+=("$1"); shift ;;
	--no-fuzz)                doFuzz=0; stageOpts+=("$1"); shift ;;
	--no-dogfood)             DOGFOOD_TARGETS=(); stageOpts+=("$1"); shift ;;
	--no-publish)             GIT_PUBLISH=(); stageOpts+=("$1"); shift ;;
	--quick)                  quick=1; stageOpts+=("$1"); shift ;;
	--long|--slow)            stageOpts+=("$1"); shift ;;
	--leakcheck|--no-leakcheck)
		[[ -z "${leakOpt}" || "${leakOpt}" == "$1" ]] || fUsage "--leakcheck and --no-leakcheck are opposites; give one."
		leakOpt="$1"; shift ;;
	## Nothing runs in a container or on another box yet, so both are already true.
	--no-container|--no-remote) shift ;;
	--message=*|--msg=*|-m=*) cliMessage="${1#*=}"; stageOpts+=("${1%%=*}"); shift ;;
	-m|--message|--msg)       cliMessage="${2-}"; stageOpts+=("$1"); shift; (($#)) && shift ;;
	--backlog-run-quick|--gate)
		[[ "$1" == --gate ]] && aliasNote="--gate is another name for --backlog-run-quick"
		gate=1; assumeYes=1; shift
		while (($#)) && [[ "$1" != -* ]]; do gateAreas+=("$1"); shift; done ;;
	--backlog-run-full|--merge-gate|--ci)
		[[ -z "${handsOff}" || "${handsOff}" == "${1/#--ci/--merge-gate}" ]] || fUsage "--backlog-run-full and --merge-gate are separate runs; give one."
		[[ "$1" == --ci ]] && aliasNote="--ci is another name for --merge-gate"
		handsOff="${1/#--ci/--merge-gate}"; assumeYes=1; shift ;;
	--keep-temp)              keepTemp=1; shift ;;
	--list)                   listOnly=1; shift ;;
	-h|--help)                sed -n '/^##	- Purpose:/,/^##	History:/p' "${BASH_SOURCE[0]}" | sed '$d; s/^##	\{0,1\}//'; exit 0 ;;
	*) fUsage "unknown option: ${1} (try --help)" ;;
esac; done

gateName="--backlog-run-quick"; [[ "${aliasNote}" == --gate* ]] && gateName="--gate"
if [[ -n "${handsOff}" ]] && ((gate)); then fUsage "${handsOff} and ${gateName} are separate runs; give one."; fi
gateAreasAll=(lint unit suite fuzz)
for a in "${gateAreas[@]:-}"; do
	[[ -z "${a}" || " ${gateAreasAll[*]} " == *" ${a} "* ]] || fUsage "${gateName}: no area '${a}'. Areas: ${gateAreasAll[*]}"
done
if ((gate && ${#stageOpts[@]})); then fUsage "${gateName} runs a fixed set of checks and takes no stage options (got: ${stageOpts[*]})"; fi
for a in "${stageOpts[@]:-}"; do
	case "${a}" in
		--quick)            [[ " ${stageOpts[*]} " != *" --long "* && " ${stageOpts[*]} " != *" --slow "* ]] || fUsage "--quick and --long are opposites; give one."
		                    [[ -z "${handsOff}" ]] || fUsage "${handsOff} runs every check of a plain run, so it takes no --quick." ;;
		-m|--message|--msg) [[ -z "${handsOff}" ]] || fUsage "${handsOff} never publishes, so it takes no ${a}." ;;
	esac
done
if ((keepTemp && listOnly)); then fUsage "--list runs nothing, so --keep-temp has nothing to keep; give one."; fi
if [[ -n "${handsOff}" ]]; then doSync=0; DOGFOOD_TARGETS=(); GIT_PUBLISH=(); fi
[[ -z "${aliasNote}" ]] || { fEcho_Clean; fEcho_Clean "${aliasNote}"; }

## One folder for the run's temp files, ${HOST_TEMP}/<app>/<start time>_<NNN>. TMPDIR, TEMP and
## TMP point into it. Its run.pid marks it as a run's, and is checked again before removal.
runTmp=""; runName=""; runRe='^[0-9]{8}-[0-9]{6}_[0-9]{3}$'
tidyGone=(); declare -i tidyFreed=0
## Apparent size: what ZFS reports on disk is compressed, and lags fresh writes.
fDirBytes(){ local out=""; out="$(du -sbx -- "$1" 2>/dev/null)" || out=0; echo "${out%%[[:space:]]*}" ;}
## The project's own run folders over 2 days old, whose run is gone.
fSweepRuns(){
	local d pid size
	local -i nStale=0
	while IFS= read -r d; do
		[[ "${d##*/}" =~ ${runRe} && "${d}" != "${runTmp}" && -f "${d}/run.pid" && ! -L "${d}" ]] || continue
		pid=""; read -r pid < "${d}/run.pid" || true
		if [[ "${pid}" =~ ^[0-9]+$ ]] && kill -0 "${pid}" 2>/dev/null; then continue; fi
		size="$(fDirBytes "${d}")"
		if fSafeRm "${d}" >/dev/null; then nStale+=1; tidyFreed+=size; fi
	done < <(find "${runRoot}" -mindepth 1 -maxdepth 1 -type d -mtime +1 2>/dev/null || true)
	((nStale == 0)) || tidyGone+=("${nStale} stale run folder(s)")
}
fRunTmpDone(){
	local rc="${1:-0}" size="" list=""
	((rc == 0)) || fStepEnd FAIL
	[[ -n "${runTmp}" ]] || return 0
	if ((keepTemp)); then fEcho_Clean; fEcho_Clean "Kept the temp folder: ${runTmp}"; fEcho_Clean; fi
	if ((! keepTemp)) && [[ "${runName}" =~ ${runRe} && -f "${runTmp}/run.pid" ]]; then
		size="$(fDirBytes "${runTmp}")"
		if fSafeRm "${runTmp}" >/dev/null; then tidyGone+=("the run folder"); tidyFreed+=size; fi
	fi
	if ((! ${#tidyGone[@]})); then fEcho_Clean "Cleanup: nothing to remove"; fEcho_Clean; return 0; fi
	printf -v list '%s, ' "${tidyGone[@]}"
	fEcho_Clean "Cleanup: removed ${list%, }; freed about $(numfmt --to=si --suffix=B "${tidyFreed}" 2>/dev/null || echo "${tidyFreed} bytes")"
	fEcho_Clean
}
fTmpDone(){ ((keepTemp)) || rm -f -- "$@" ;}
if ((! listOnly)); then
	## Once, so every path under it is spelled the same: macOS's temp folder sits behind a link.
	HOST_TEMP="$(realpath -e -- "${HOST_TEMP:-${TMPDIR:-/tmp}}")" || fDie "no temp folder at ${HOST_TEMP:-${TMPDIR:-/tmp}}"
	export HOST_TEMP
	runRoot="${HOST_TEMP}/${APP_NAME}"
	mkdir -p -- "${runRoot}" || fDie "can't make ${runRoot}"
	## A plain mkdir, so a name another run took fails and the counter goes on.
	for ((runSeq = 1; runSeq < 1000; runSeq++)); do
		printf -v runTmp '%s/%s_%03d' "${runRoot}" "${stamp}" "${runSeq}"
		mkdir -- "${runTmp}" 2>/dev/null && break
		runTmp=""
	done
	[[ -n "${runTmp}" ]] || fDie "can't make a run folder in ${runRoot}"
	runName="${runTmp##*/}"
	echo "$$" > "${runTmp}/run.pid"
	trap 'fRunTmpDone "$?"' EXIT
	trap 'exit 130' INT; trap 'exit 143' TERM
	export TMPDIR="${runTmp}" TEMP="${runTmp}" TMP="${runTmp}"
	fSweepRuns
fi

stagePause=0.4; ((assumeYes)) && stagePause=0

publishMsg=""
if   [[ -n "${cliMessage}" ]];              then publishMsg="${cliMessage}"
elif [[ -n "${PUBLISH_AUTO_MESSAGE:-}" ]]; then publishMsg="${PUBLISH_AUTO_MESSAGE}"
elif ((assumeYes));                       then publishMsg="${APP_NAME} CI/CD ${stamp}"
fi

trap 'rc=$?; printf "\n[ CICD ABORTED (exit %s) at line %s: %s ]\n" "${rc}" "${LINENO}" "${BASH_COMMAND}" >&2; exit "${rc}"' ERR

fGlobFiles(){ ## OUT_ARRAY GLOB...
	local -n out_gF="$1"; shift
	local g f hadNullglob=0
	out_gF=()
	shopt -q nullglob && hadNullglob=1; shopt -s nullglob
	for g in "$@"; do for f in ${g}; do [[ -f "${f}" ]] && out_gF+=("${f}"); done; done
	((hadNullglob)) || shopt -u nullglob
}
fGlobFiles shellFiles "${SHELL_LINT_GLOBS[@]}"

fGoToolPath(){ local found="" dir="" goPath=""
	found="$( command -v "$1" 2>/dev/null || true )"
	goPath="$(go env GOPATH 2>/dev/null || true)"
	for dir in "$(go env GOBIN 2>/dev/null || true)" "${goPath:+${goPath%%:*}/bin}"; do
		if [[ -z "${found}" && -n "${dir}" && -x "${dir}/$1" ]]; then found="${dir}/$1"; fi
	done
	echo "${found}"
}
fToolVersion(){
	case "$1" in
		shellcheck)   shellcheck --version 2>/dev/null | awk '$1=="version:"{print $2}' ;;
		markdownlint) markdownlint --version 2>/dev/null || npx --no-install markdownlint --version 2>/dev/null ;;
	esac
}

fStageLint(){
	local f mdFiles=() toolDrift=() toolSpec toolName toolWant toolPath toolHave unformatted
	((${#shellFiles[@]})) || fDie "no shell files matched SHELL_LINT_GLOBS"
	for f in "${shellFiles[@]}"; do bash -n "${f}" || fDie "syntax error: ${f}"; done
	fEcho_Clean "bash -n: ${#shellFiles[@]} file(s)"
	shellcheck --version >/dev/null 2>&1 || fDie "shellcheck not installed"
	shellcheck "${shellFiles[@]}"
	fEcho_Clean "shellcheck: clean"
	fGlobFiles mdFiles "${MD_LINT_GLOBS[@]}"
	if ((! ${#mdFiles[@]})); then :
	elif command -v markdownlint >/dev/null 2>&1; then
		markdownlint "${mdFiles[@]}"
		fEcho_Clean "markdownlint: clean (${#mdFiles[@]} file(s))"
	else
		fEcho "WARNING: markdownlint skipped (not installed: npm install -g markdownlint-cli)"
	fi
	command -v go >/dev/null 2>&1 || fDie "go toolchain not installed"
	for toolSpec in "${GO_TOOL_VERSIONS[@]}"; do
		toolName="${toolSpec%%=*}"; toolWant="${toolSpec#*=}"
		toolPath="$(fGoToolPath "${toolName}")"
		[[ -n "${toolPath}" ]] || continue
		toolHave="$( go version -m "${toolPath}" 2>/dev/null | awk '$1=="mod"{print $3; exit}' || true )"
		[[ "${toolHave}" == "${toolWant}" ]] || toolDrift+=( "${toolName} ${toolHave:-unknown} (recorded ${toolWant})" )
	done
	for toolSpec in "${TOOL_VERSIONS[@]}"; do
		toolHave="$(fToolVersion "${toolSpec%%=*}" || true)"
		[[ -z "${toolHave}" || "${toolHave}" == "${toolSpec#*=}" ]] || toolDrift+=("${toolSpec%%=*} ${toolHave} (recorded ${toolSpec#*=})")
	done
	((${#toolDrift[@]} == 0)) || fEcho "WARNING: tool versions differ from the recorded set: ${toolDrift[*]}"
	unformatted="$(cd "${root}/${GO_MODULE_DIR}" && gofmt -l .)"
	[[ -z "${unformatted}" ]] || fDie "gofmt wants to reformat: ${unformatted}"
	(cd "${root}/${GO_MODULE_DIR}" && GOMAXPROCS="${BUILD_JOBS}" go vet -p "${BUILD_JOBS}" ./...) || fDie "go vet findings"
	fEcho_Clean "gofmt + go vet: clean"
	toolPath="$(fGoToolPath staticcheck)"
	if [[ -n "${toolPath}" ]]; then
		(cd "${root}/${GO_MODULE_DIR}" && GOMAXPROCS="${BUILD_JOBS}" "${toolPath}" ./...) || fDie "staticcheck findings"
		fEcho_Clean "staticcheck: clean"
	else
		fEcho "WARNING: staticcheck skipped (not installed: go install honnef.co/go/tools/cmd/staticcheck@latest)"
	fi
	toolPath="$(fGoToolPath golangci-lint)"
	if [[ -n "${toolPath}" ]]; then
		(cd "${root}/${GO_MODULE_DIR}" && "${toolPath}" run --concurrency "${BUILD_JOBS}" ./...) || fDie "golangci-lint findings"
		fEcho_Clean "golangci-lint: clean"
	else
		fEcho "WARNING: golangci-lint skipped (not installed: go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest)"
	fi
	"${here}/utility/test-id.bash" --check -q || fDie "test IDs (see above)"
	fEcho_Clean "test IDs: every test has its own"
}
fUnitTests(){
	local log="" rc=0
	log="$(mktemp "${runTmp}/gotest.XXXXXX")"
	## -count=1, since a cached pass proves nothing. -race is one of the hard steps.
	(cd "${root}/${GO_MODULE_DIR}" && GOMAXPROCS="${HEAVY_JOBS}" go test -race -p "${HEAVY_JOBS}" -count=1 -v ./...) >"${log}" 2>&1 || rc=$?
	fGoTestLines "${log}" "${root}/${GO_MODULE_DIR}"
	if ((rc)); then
		grep -vE '^ *(=== (RUN|PAUSE|CONT|NAME)|--- (PASS|SKIP))' "${log}" || true
		fTmpDone "${log:?}"
		fDie "go test failures"
	fi
	fTmpDone "${log:?}"
}
fGoVersion(){ git describe --tags --always --dirty --match 'v*' 2>/dev/null || echo 0.0.0 ;}
## Seconds of the commit, not the clock, so the same source builds to the same bytes.
fGoBuildEpoch(){ git log -1 --format=%ct 2>/dev/null || echo 0 ;}
## BUILD [GOOS GOARCH]: the native build by default.
fGoBuild(){
	local out="$1" goos="${2:-}" goarch="${3:-}"
	(cd "${root}/${GO_MODULE_DIR}" && export CGO_ENABLED=0 GOAMD64=v1 && if [[ -n "${goos}" ]]; then export GOOS="${goos}" GOARCH="${goarch}"; fi \
		&& go build "${GO_BUILD_FLAGS[@]}" -p "${BUILD_JOBS}" -ldflags "${GO_LDFLAGS_COMMON} -X main.version=${goVersion#v} -X main.buildEpoch=${goBuildEpoch}" -o "${out}" "${GO_MAIN_PKG}") \
		|| fDie "go build failed${goos:+ for ${goos}/${goarch}}"
}
fNativeBuild(){
	fGoBuild "${root}/${GO_MODULE_DIR}/${EXE_NAME}"
	fEcho_Clean "go build: v${goVersion#v} -> ${GO_MODULE_DIR}/${EXE_NAME}"
}
fSuite(){ CICDTEST_EXE="${root}/${GO_MODULE_DIR}/${EXE_NAME}" "${TEST_CMD[@]}" ;}
## Coverage-guided fuzzing past the seed corpus, briefly. One target per call is go's rule, and a
## crasher is kept under the package's testdata/fuzz/.
fNativeFuzz(){
	local pkg dir target fuzzId fuzzOut
	while IFS=' ' read -r pkg dir; do
		for target in $(cd "${dir}" && go test -list '^Fuzz' . 2>/dev/null | grep '^Fuzz' || true); do
			fuzzId="$(sed -n "s|^func ${target}(.*// \[\([0-9A-Za-z]*\)\][[:space:]]*\$|\1 |p" "${dir}"/*_test.go 2>/dev/null || true)"
			fuzzOut="$(cd "${dir}" && GOMAXPROCS="${HEAVY_JOBS}" go test -run '^$' -fuzz "^${target}\$" -fuzztime 5s -parallel "${HEAVY_JOBS}" . 2>&1)" \
				|| { fEcho_Clean "$(tail -n 40 <<< "${fuzzOut}")"; fEcho_Clean "  FAIL ${fuzzId}${target}"; fDie "fuzzing found a crasher in ${pkg}.${target} (reproducer under its testdata/fuzz/)"; }
			fEcho_Clean "  PASS ${fuzzId}${target}"
		done
	done < <(cd "${root}/${GO_MODULE_DIR}" && go list -f '{{.ImportPath}} {{.Dir}}' ./...)
}
fListTests(){
	local title="$1" lines=""
	shift
	lines="$("${here}/utility/test-id.bash" --list --root "${root}" "$@")" || fDie "can't list the tests in $*"
	fEcho_Clean
	fEcho_Clean "${title}: $(grep -c . <<< "${lines}" || true) test(s)"
	[[ -z "${lines}" ]] || sed 's/^/  /' <<< "${lines}"
}
fCpuPlan(){ fEcho_Clean "Cores ...............: ${BUILD_JOBS} of ${cpuCores}, ${HEAVY_JOBS} for the hard steps (load ${cpuLoad:-unknown}), at low priority" ;}

#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## --backlog-run-quick: no sync, prompt, log, dogfood or publish.
if ((gate)); then
	stepTitle=([lint]="Lint" [unit]="Unit tests" [suite]="Regression tests" [fuzz]="Native fuzz")
	gateOff=()
	for a in "${gateAreasAll[@]}"; do
		if ((! ${#gateAreas[@]})) || [[ " ${gateAreas[*]} " == *" ${a} "* ]]; then stepList+=("${a}"); else gateOff+=("${a}"); fi
	done
	stepTotal="${#stepList[@]}"
	fEcho_Clean
	fEcho_Clean "${APP_NAME} backlog quick run: ${stepList[*]}"
	fEcho_Clean "Repo root ...........: ${root}"
	fCpuPlan
	((! ${#gateOff[@]})) || fEcho_Clean "Left out ............: ${gateOff[*]} (not named)"
	if ((listOnly)); then
		for a in "${stepList[@]}"; do
			case "${a}" in
				lint)  fEcho_Clean; fEcho_Clean "$(fStepOf "${a}")  ${stepTitle[${a}]}: no test IDs" ;;
				unit)  fListTests "$(fStepOf "${a}")  ${stepTitle[${a}]}" go ;;
				suite) fListTests "$(fStepOf "${a}")  ${stepTitle[${a}]}" "${TEST_CMD[0]}" ;;
				fuzz)  fListTests "$(fStepOf "${a}")  ${stepTitle[${a}]}" gofuzz ;;
			esac
		done
		fEcho_Clean
		exit 0
	fi
	goVersion="$(fGoVersion)"; goBuildEpoch="$(fGoBuildEpoch)"
	for a in "${stepList[@]}"; do
		fStep "${a}"
		case "${a}" in
			lint)  fStageLint ;;
			unit)  fUnitTests ;;
			suite) fNativeBuild; fSuite ;;
			fuzz)  fNativeFuzz ;;
		esac
		fStepEnd
	done
	fSection "${APP_NAME} backlog quick run: passed."
	fEcho_Clean
	exit 0
fi

#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Dogfood destinations, resolved once: per target, the first dir that exists and is writable.
declare -A dogfoodDest=() dogfoodAll=()
for t in "${DOGFOOD_TARGETS[@]:-}"; do
	[[ -n "${t}" ]] || continue
	destVar="DOGFOOD_DESTS_${t^^}"; destVar="${destVar//\//_}"
	declare -n _dests="${destVar}"
	foundDest=""; for cand in "${_dests[@]:-}"; do [[ -d "${cand}" && -w "${cand}" ]] && { foundDest="${cand}"; break; }; done
	dogfoodDest["${t}"]="${foundDest}"; dogfoodAll["${t}"]="${_dests[*]:-}"
	unset -n _dests
done

((! doSync))                    || stepList+=(sync)
((! doLint))                    || stepList+=(lint)
((! doTest))                    || stepList+=(test)
((! doFuzz))                    || stepList+=(fuzz)
((! ${#DOGFOOD_TARGETS[@]}))    || stepList+=(dogfood)
((! ${#GIT_PUBLISH[@]}))        || stepList+=(publish)
stepTotal="${#stepList[@]}"
fOffWhy(){
	if [[ " ${stageOpts[*]:-} " == *" --no-$1 "* ]]; then echo "(skipped --no-$1)"
	elif [[ -n "${handsOff}" && " sync dogfood publish " == *" $1 "* ]]; then echo "(skipped ${handsOff})"
	else echo "(disabled)"; fi
}

fEcho_Clean
if [[ -n "${handsOff}" ]]; then
	fEcho_Clean "${APP_NAME} ${handsOff#--}: every check of a plain run; nothing is synced, dogfooded, published or rewritten"
else
	fEcho_Clean "${APP_NAME} local CI/CD"
fi
fEcho_Clean
fEcho_Clean "Repo root ...........: ${root}"
fCpuPlan
fEcho_Clean "Container ...........: none yet, everything runs on this box"
if ((doSync)); then fEcho_Clean "Remote sync .........: fast-forward from origin first"
else fEcho_Clean "Remote sync .........: $(fOffWhy sync)"; fi
if ((doLint)); then fEcho_Clean "Lint ................: gofmt + go vet, shellcheck on ${#shellFiles[@]} shell file(s), test IDs  (+ staticcheck, golangci-lint, markdownlint if available)"
else fEcho_Clean "Lint ................: $(fOffWhy lint)"; fi
if ((doTest)); then fEcho_Clean "Build + tests .......: ${GO_MODULE_DIR}/${EXE_NAME}, go test -race, ${TEST_CMD[*]}"
else fEcho_Clean "Build + tests .......: $(fOffWhy test)"; fi
if ((doFuzz && quick)); then fEcho_Clean "Fuzz + security .....: native fuzz targets; govulncheck (skipped --quick)"
elif ((doFuzz)); then fEcho_Clean "Fuzz + security .....: native fuzz targets, govulncheck"
else fEcho_Clean "Fuzz + security .....: $(fOffWhy fuzz)"; fi
fEcho_Clean "Leak checks .........: none yet${leakOpt:+ (${leakOpt} has nothing to change)}"
fEcho_Clean "Other hosts .........: none yet"
if ((${#DOGFOOD_TARGETS[@]})); then
	for t in "${DOGFOOD_TARGETS[@]}"; do
		if [[ -n "${dogfoodDest[${t}]}" ]]; then fEcho_Clean "Dogfood (${t%%/*}) .....: build ${t} -> ${dogfoodDest[${t}]}/${EXE_NAME}"
		else fEcho_Clean "Dogfood (${t%%/*}) .....: <none of: ${dogfoodAll[${t}]} exists - will skip>"; fi
	done
else fEcho_Clean "Dogfood .............: $(fOffWhy dogfood)"; fi
if ((${#GIT_PUBLISH[@]} == 0)); then fEcho_Clean "Publish (last) ......: $(fOffWhy publish)"
elif [[ -n "${publishMsg}" ]]; then fEcho_Clean "Publish (last) ......: ${GIT_PUBLISH[*]} (hands-off: \"${publishMsg}\")"
else fEcho_Clean "Publish (last) ......: ${GIT_PUBLISH[*]} (will prompt for message; blank = editor)"; fi
fEcho_Clean
fEcho_Clean "Fail-fast: any error aborts before the next step."
fEcho_Clean

if ((listOnly)); then
	if ((doTest)); then
		fListTests "$(fStepOf test)  Go unit tests" go
		fListTests "$(fStepOf test)  Regression tests" "${TEST_CMD[0]}"
	fi
	((! doFuzz)) || fListTests "$(fStepOf fuzz)  Native fuzz targets" gofuzz
	fEcho_Clean
	exit 0
fi

if ((! assumeYes)) && ((${#GIT_PUBLISH[@]})) && [[ -z "${publishMsg}" ]]; then
	read -r -p "Publish commit message (blank = editor; Ctrl+C aborts): " typedMessage
	fEcho_ResetBlankCounter
	[[ -n "${typedMessage}" ]] && publishMsg="${typedMessage}"
fi

## Tee the rest of the run to a gitignored log, for lint-report.bash.
if [[ -n "${LINT_LOG_DIR:-}" ]] && mkdir -p "${root}/${LINT_LOG_DIR}" 2>/dev/null; then
	gfs_rotate "${root}/${LINT_LOG_DIR}" run log >/dev/null 2>&1 || true
	exec > >(tee "${root}/${LINT_LOG_DIR}/run_${stamp}.log") 2>&1
	## Wait for tee to drain, else the prompt comes back mid-flush.
	teePid=$!
	trap 'fRunTmpDone "$?"; exec 1>&- 2>&-; wait "${teePid}" 2>/dev/null' EXIT
fi

#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Sync first, so the run tests the tree that goes out. Publish pulls again as a late guard.
if ((doSync)); then
	fStep sync
	if ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
		fEcho_Clean "no upstream for this branch - nothing to sync"
	elif ! git fetch --quiet 2>/dev/null; then
		fEcho_Clean "WARNING: can't reach origin - building without refreshing"
	else
		counts="$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null || echo "0	0")"
		behind="${counts%%[[:space:]]*}"; ahead="${counts##*[[:space:]]}"
		if   ((behind == 0)); then fEcho_Clean "up to date with origin (${ahead} to publish)"
		elif ((ahead > 0));   then fDie "diverged from origin: ${ahead} local, ${behind} remote. Reconcile before building."
		else
			fEcho_Clean "fast-forwarding ${behind} commit(s) from origin"
			git merge --ff-only --autostash '@{u}' || fDie "fast-forward from origin failed"
		fi
	fi
	fStepEnd
fi

## Read after the sync, which can move HEAD.
goVersion="$(fGoVersion)"; goBuildEpoch="$(fGoBuildEpoch)"

if ((doLint)); then
	fStep lint
	fStageLint
	fStepEnd
fi

if ((doTest)); then
	fStep test
	fNativeBuild
	fUnitTests
	fSuite
	fStepEnd
fi

if ((doFuzz)); then
	fStep fuzz
	fNativeFuzz
	toolPath="$(fGoToolPath govulncheck)"
	if ((quick)); then
		fEcho_Clean "govulncheck skipped (--quick: it reaches vuln.go.dev)"
	elif [[ -n "${toolPath}" ]]; then
		(cd "${root}/${GO_MODULE_DIR}" && "${toolPath}" -test ./...) || fDie "govulncheck findings"
		fEcho_Clean "govulncheck: clean"
	else
		fEcho "WARNING: govulncheck skipped (not installed: go install golang.org/x/vuln/cmd/govulncheck@latest)"
	fi
	fStepEnd
fi

if ((${#DOGFOOD_TARGETS[@]})); then
	fStep dogfood
	dogfoodDone=0
	for t in "${DOGFOOD_TARGETS[@]}"; do
		exe="${EXE_NAME}"; [[ "${t}" == windows/* ]] && exe="${EXE_NAME}.exe"
		if [[ -z "${dogfoodDest[${t}]}" ]]; then
			fEcho "WARNING: no ${t} dogfood dest exists/writable (${dogfoodAll[${t}]}); skipping"
			continue
		fi
		## Its own name, so the native build the suite ran against isn't overwritten.
		out="${root}/${GO_MODULE_DIR}/${EXE_NAME}-${t//\//-}"
		fGoBuild "${out}" "${t%%/*}" "${t##*/}"
		cp -f "${out}" "${dogfoodDest[${t}]}/${exe}"
		chmod +x "${dogfoodDest[${t}]}/${exe}"
		rm -f -- "${out:?}"
		fEcho_Clean "installed (${t}) -> ${dogfoodDest[${t}]}/${exe}"
		dogfoodDone=1
	done
	((dogfoodDone)) || fEcho_Clean "dogfood: nothing installed"
	fStepEnd
fi

## The publisher always runs quiet: this run already prompted.
if ((${#GIT_PUBLISH[@]})); then
	fStep publish
	if [[ -n "${publishMsg}" ]]; then
		fEcho_Clean "hands-off publish (commit message: \"${publishMsg}\")"
		"${GIT_PUBLISH[@]}" --quiet -m "${publishMsg}"
	else
		"${GIT_PUBLISH[@]}" --quiet
	fi
	fStepEnd
fi

fSection "${APP_NAME} CI/CD: done."
fEcho_Clean


##	History:
##		- 2026-10-28 JC: Created, trimmed from gitsby's. No container, leak checks or other hosts yet.
