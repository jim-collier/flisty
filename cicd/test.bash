#!/usr/bin/env bash

#  shellcheck enable=require-variable-braces  ## Every expansion braced: "${var}", not "$var".

##	Purpose:
##		- Regression suite. Drives the built binary and checks what it prints and returns.
##		- Binary under test: $CICDTEST_EXE, which cicd.bash sets to its fresh build.
##		  Without it, a build of the tree is made in the run's temp folder.
##		- Each check carries its test ID at the front of its label, "[<id>] label".
##		  Mint one with cicd/utility/test-id.bash.
##	History: At bottom of script.

##	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
##	Licensed under the GNU General Public License v2.0 or later. Full text at:
##		https://spdx.org/licenses/GPL-2.0-or-later.html
##	SPDX-License-Identifier: GPL-2.0-or-later


if (( BASH_VERSINFO[0] * 100 + BASH_VERSINFO[1] < 404 )); then
	printf '%s\n' "${0##*/}: needs bash 4.4 or newer, and this is bash ${BASH_VERSION}." >&2; exit 1
fi
set -Eeuo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${here}/.." && pwd)"
declare -i nPass=0 nFail=0

## "[id] label" -> "PASS id label", the per-test line the pipeline prints.
fReport(){ local verdict="$1" label="$2" id="-"
	if [[ "${label}" =~ ^\[([0-9a-z]+)\]\ (.*)$ ]]; then id="${BASH_REMATCH[1]}"; label="${BASH_REMATCH[2]}"; fi
	printf '  %s %s %s\n' "${verdict}" "${id}" "${label}"
	if [[ "${verdict}" == PASS ]]; then nPass+=1; else nFail+=1; fi
}
## fAssertRun LABEL WANT_RC WANT_TEXT ARGS...: runs the binary, checks its exit code and that
## stdout+stderr has WANT_TEXT (empty matches anything).
fAssertRun(){
	local label="$1" wantRc="$2" wantText="$3" out="" rc=0
	shift 3
	out="$("${exe}" "$@" 2>&1)" || rc=$?
	if ((rc != wantRc)); then fReport FAIL "${label} (exit ${rc}, want ${wantRc})"
	elif [[ -n "${wantText}" && "${out}" != *"${wantText}"* ]]; then fReport FAIL "${label} (no '${wantText}' in: ${out})"
	else fReport PASS "${label}"; fi
}

exe="${CICDTEST_EXE:-}"
if [[ -z "${exe}" ]]; then
	exe="$(mktemp "${TMPDIR:-/tmp}/flisty-test.XXXXXX")"
	trap 'rm -f -- "${exe:?}"' EXIT
	(cd "${root}/source" && CGO_ENABLED=0 go build -o "${exe}" ./cmd/flisty) || { echo "test: build failed" >&2; exit 1; }
fi
[[ -x "${exe}" ]] || { echo "test: not executable: ${exe}" >&2; exit 1; }

fAssertRun "[dej9x] --version names the program and its version" 0 "flisty v" --version
fAssertRun "[dej9y] --help prints usage" 0 "Usage:" --help
fAssertRun "[dej9z] -h prints usage" 0 "Usage:" -h
fAssertRun "[deja0] an unbuilt request exits 2" 2 "" some-folder

printf '\n  %d passed, %d failed\n' "${nPass}" "${nFail}"
((nFail == 0))


##	History:
##		- 2026-10-28 JC: Created.
