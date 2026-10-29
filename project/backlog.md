<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->

<!-- TOC ignore:true -->
# Project backlog

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Introduction](#introduction)
- [Issues](#issues)
- [Old format](#old-format)
	- [Bugs](#bugs)
	- [Features and enhancements](#features-and-enhancements)
	- [Done](#done)
		- [Done - Bugs](#done---bugs)
		- [Done - Features and enhancements](#done---features-and-enhancements)
	- [Deferred](#deferred)
	- [Canceled](#canceled)
- [Template](#template)

<!-- /TOC -->

## Introduction

Going forward, new issues in the new template at the bottom of this file, will go in the '## New format' section only. No more status emojis. Refer to '## Reference' for sort order. Issues in the old format (with status emojis) won't be refactored, but will continue to be worked until moved to closed, canceled, or deferred sections, and emojis updated. (Eventually this will all be moved to nano-git-db anyway. This new template is an intermediate effort to make issues going forward more structured and importable.)

This is a product backlog just for pre-v1.0.0 release. After that, bugs, features, and enhancements will be managed in GitHub issues.

## Issues

- CICD reset: standard flags
	- ID: 2026102814515701
	- Type: Task
	- Status: Started
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- The shared flags, run lengths, no dogfood in a backlog round, and the merge gate.
	- Progress log:
		- The flags are in. `--leakcheck`, `--no-container`, and `--no-remote` are taken but change nothing yet.
		- Still needs the pre-push hook that runs `--merge-gate` on a push to main, with a list of doc-only paths that skip it.
		- The hook also runs the content scrub when it's there, as the lint step does now.

- Build the walk: list the paths under the given folders
	- ID: 2026102814515703
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Positional folders, default the current folder.
		- `--max-depth`, `--no-cross-device` (also `--xdev`), and `-L`/`--follow-links` without looping.
		- A folder that can't be read is a warning, and the walk goes on.
		- One path per line, written as found. Nothing held in memory past the current folder.

- Add link-doctor's filter options
	- ID: 2026102814515704
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- `--include`, `--exclude`, and `--re-include` regexes.
		- `--name`, `--iname`, `--wholename`, and `--iwholename` globs.
		- Applied left to right, as in link-doctor.
		- Long options can be shortened to 3 or more letters when that's unambiguous. `--inc` and `--exc` always work.
	- Progress log:
		- The filter engine and its tests came over from link-doctor.

- Read nested rules from `--input-config[=]FILE`
	- ID: 2026102814515705
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A small parser of our own, not shcl.
		- Tabs or spaces for indent, but not both. Uneven steps are fine. A line that falls between 2 open levels is an error.
		- The same rule names as the options. A nested rule applies only to what its parent matched.
		- Rules come from the options or from the file, never both. Both is an error.
		- The file can also set `no-folders`, `no-links`, and `include-output-file`. One set in both places is an error.
		- Every error names the line. A fuzz target covers the parser.
	- Note: design.md has the format and the nesting rules.

- Add `--output-file[=]FILE`
	- ID: 2026102814515706
	- Type: Feature
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Writes the list there in place of stdout.
		- The file name is required. A bare `--output-file` is an error.
		- Written to a temp file beside it and renamed at the end, so a failed run leaves the old file whole.
		- The output file leaves itself out of the list. `--include-output-file` keeps it.

- CICD reset: containers
	- ID: 2026102814515709
	- Type: Task
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Build and test in a pinned container image, and fall back to the host when docker is missing.
		- The image pins Go and the lint tools. Today `config.bash` only records their versions and warns when they differ.

- CICD reset: container cleanup
	- ID: 2026102814515710
	- Type: Task
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Prereq IDs: 2026102814515709
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Labels on what the pipeline makes, and removal of only its own containers and images at the end of a run.

- CICD reset: other hosts and VMs
	- ID: 2026102814515711
	- Type: Task
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Run the tests on Windows, macOS, FreeBSD, and Linux arm64 through the host lock, with each VM put back as it was found. b29w, never b29w-wif.

- CICD reset: a test for every Done item
	- ID: 2026102814515712
	- Type: Task
	- Status: Queued
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Every Done item names its test, or says why it has none.

- File as shcl friction: same name and value siblings merge
	- ID: 2026102814515708
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Report to shcl. Smallest case: `include: a`, `exclude: b`, `include: a` at one level. The third line merges into the first, with only an H002 diagnostic.
		- A silent wrong answer for any program where sibling order matters.
		- Needs a way to keep repeated siblings apart, or to read every field of a level in file order.
	- Note: flisty no longer uses shcl for rules. The report still stands.

- Add `-0`/`--print0` output
	- ID: 2026102814515713
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Paths separated by NUL, for `xargs -0`.

- Write `--help` and `--examples`
	- ID: 2026102814515714
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Help in link-doctor's layout, kept in step with the options as they're added.

- Set exit codes
	- ID: 2026102814515715
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- 0 for a clean run, 1 when a folder couldn't be read, 2 for a bad command line or rule file.

- Print paths as given
	- ID: 2026102814515716
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- An absolute start folder gives absolute paths, and a relative one gives relative paths.
	- Need to work out ambiguities:
		- Forward slashes on Windows too? Version 2's notes want them in rules.

- List files, folders, and links, with options to leave some out
	- ID: 2026102814515717
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Anything the rules match is listed.
		- `--no-folders` and `--no-links`, and the same in a rule file.

- Test on Windows, macOS, and FreeBSD
	- ID: 2026102814515718
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Path separators, drive letters, and folders that ignore case.

- Measure speed on a large tree
	- ID: 2026102814515719
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A timed walk of a few million files, against `find` with the same rules.
		- Profile before changing anything.

- Write the README usage section
	- ID: 2026102814515720
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- Options, a rule file example, and what it doesn't do.

- CICD reset: macOS runner
	- ID: 2026102814515721
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- GitHub's free arm64 macOS runner builds, tests, and runs the CLI once the repo is public.
	- Progress log:
		- The GitHub repo is public since 20261028, so the runner is free now.

- CICD reset: CICD process gaps
	- ID: 2026102814515722
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Leak checks: a soak test, and CodeQL from a pinned CLI.
		- Cross-builds and dogfood for Windows and macOS, and arm64 builds.
		- A check that a release rebuilds to the same bytes, and a README line once it holds.
		- Windows icon and version details in the .exe.
		- Profiling, with a flamegraph and a hotspot report each run.
		- Dogfood skips the copy when the installed binary is in use.
		- The regression suite run on its own builds into the plain temp folder, not a run folder.
	- Note: Release packages moved to their own item, 2026102818015770.

- Build release packages
	- ID: 2026102818015770
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-180157
	- Opened by: JC
	- Requirements:
		- Linux, FreeBSD, Windows, and macOS builds, each for x86_64 and arm64. Names say x86_64, not amd64.
		- `.deb` and `.rpm` for Linux, `.pkg` for FreeBSD, and a single-file Windows installer that updates an installed copy.
		- The version in every artifact name, in one scheme settled before the first tagged release.
		- A sha256 checksums file beside them.
		- Skipped by `--quick`.
	- Note: goreleaser may fit, if its names match the scheme.

- Write install scripts
	- ID: 2026102818015807
	- Type: Feature
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-180157
	- Opened by: JC
	- Prereq IDs: 2026102818015770
	- Requirements:
		- `install.bash` for Linux, BSD, macOS, and WSL, on bash 3.2. `install.ps1` for PowerShell 5 and 7, on any OS.
		- Runs as a one-liner from the README, and gets the latest stable or dev release. It lists releases through the GitHub API, so a prerelease works when there's no stable one.
		- Detects the OS and CPU, checks the checksum, and is safe to run twice.
		- Says what it will do and asks first.
		- Options: release dev or stable, target user or system, yes, help, and version.
		- README gets the one-liners and the install folders, and points to the help option for the rest.

- Make the demo gif
	- ID: 2026102818015844
	- Type: Task
	- Status: Queued
	- Priority: Avg
	- Opened: 20261028-180157
	- Opened by: JC
	- Prereq IDs: 2026102814515703, 2026102814515704
	- Requirements:
		- A faux terminal gif of the main features, about 20 to 30 seconds, rendered headless by the pipeline. Skipped by `--quick`.
		- A short plain-text script for it, kept in `cicd/utility/demo/`, that can be edited by hand.
		- Made-up paths and names only.
		- Shown at the top of the README.

- Version 2 rule language
	- ID: 2026102814515723
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- From x9incexc's `notes.txt`. The items below point back here.

- Version 2: macros
	- ID: 2026102814515724
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Named regex pieces, used as `$Name`, case-insensitive. `\$` is a plain dollar sign.
		- A rule file read by another inherits its macros, and can change or clear them.
		- A built-in set: anything, a dot, a file or folder name, the root of a filesystem or mount, user homes, "don't back up" folder names, and groups of file types.

- Version 2: pick macro names that are easy to type
	- ID: 2026102814515725
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Needs better design:
		- The notes use emoji and box characters for the short names. They're hard to type and to search for.

- Version 2: rule files that read other rule files
	- ID: 2026102814515726
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723

- Version 2: settings scoped by nesting
	- ID: 2026102814515727
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Case sensitivity, and whether symlinks are followed, ignored, or listed.
		- A nested setting reverts when its scope ends.

- Version 2: `consider` roots
	- ID: 2026102814515728
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- A `consider` folder is scanned, but nothing in it is listed until a rule includes it.
		- A folder under an earlier `consider` isn't scanned twice, unless the earlier one skipped links it now follows.

- Version 2: built-in common excludes
	- ID: 2026102814515729
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Temp folders, `lost+found`, trash and recycle bins, `._*` files, `.DS_Store`, `.Spotlight-V*`, swap and page files, `/dev`, `/proc`, and `/var`.
		- On by a setting, and each one can be turned back on.

- Version 2: order the output
	- ID: 2026102814515730
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- By size, in groups that grow by a set multiple, with groups given their own place by a min and max.
		- By name groups, matched by regex, each placed from the top or bottom with a weight.
		- By date, in groups that grow by a set multiple.
		- A setting for which of those orders apply first.
	- Note: Ordering means holding the whole list before printing. design.md's data flow assumes streaming, so this needs more thought.

- Version 2: sizes with units
	- ID: 2026102814515731
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Bytes by default. `KB`, `MB`, and so on are powers of 1000. `KiB`, `MiB`, and so on are powers of 1024.

- Version 2: loose spellings in rule files
	- ID: 2026102814515732
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Short names for rules, such as `incl` for `include`.
		- Booleans as `y`, `yes`, `t`, `true`, `1`, or `on`, and their opposites. Empty or `null` is off.
	- Note: Version 1 takes a bare name for an on/off setting.

- Version 2: path and regex clean-up
	- ID: 2026102814515733
	- Type: Feature
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-145157
	- Opened by: JC
	- Parent ID: 2026102814515723
	- Requirements:
		- Rule paths use forward slashes, on Windows too. Doubled slashes are cleaned up.
		- Regex groups become non-capturing, for speed.
	- Needs more thought: Non-capturing groups break backreferences, which regexp2 was chosen for.

- Dogfood launcher script
	- ID: 2026102818015881
	- Type: Task
	- Status: Queued
	- Priority: Low
	- Opened: 20261028-180157
	- Opened by: JC
	- Requirements:
		- A cross-platform `dogfood_flisty.ps1`, with bash and cmd wrappers, as silkterm's launcher does. Masters kept in the repo's `utility/`.
		- Copies the latest dogfood build into a dated versions folder, links it as the current one, and runs it with the arguments given.
		- Keeps 5 to 10 versions, up to 1 GB, and never removes one in use.
	- Needs more thought: flisty is a CLI already on PATH, so a versioned launcher may add little.

- CICD reset: CPU and priority
	- ID: 2026102814515734
	- Type: Task
	- Status: Done
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
	- Test case: n/a, the plan at the top of each run shows the counts.
	- Acceptance signoff: Self-closed: copied as-is from a sister pipeline.
	- Closed: 20261028-145157

- CICD reset: step output
	- ID: 2026102814515735
	- Type: Task
	- Status: Done
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
	- Test case: n/a, every run prints the step lines.
	- Acceptance signoff: Self-closed: copied as-is from a sister pipeline.
	- Closed: 20261028-145157

- CICD reset: test IDs
	- ID: 2026102814515736
	- Type: Task
	- Status: Done
	- Priority: High
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
	- Test case: the test ID check in the lint step.
	- Acceptance signoff: Self-closed: mechanical.
	- Closed: 20261028-145157

- CICD reset: temp files and safe removal
	- ID: 2026102814515702
	- Type: Task
	- Status: Done
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
		- Each run's temp folder, removal on exit, stale run sweep, and the removal guard.
	- Progress log:
		- In place. Still needs a run killed partway, then a second run, to show nothing piles up.
	- Verified: Runs stopped partway by Ctrl+C and by TERM each removed their folder and left no processes. The next run swept a dead run's folder older than 2 days, and kept a younger one.
	- Test case: n/a, it's the pipeline's own cleanup. Every run prints what it removed.
	- Acceptance signoff: Self-closed: checked, and hard to test by hand.
	- Closed: 20261028-180530

- CICD reset: version line
	- ID: 2026102814515737
	- Type: Task
	- Status: Done
	- Priority: Avg
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- A sweeping override of the 2026-10-24 CICD reset. It supersedes any earlier decision that conflicts with it.
	- Test case: dbsj2, debe5, dej9t, dej9x.
	- Acceptance signoff: Self-closed: its tests pass.
	- Closed: 20261028-145157

- Add shclwrap as a dependency that builds from a fresh clone
	- ID: 2026102814515707
	- Type: Task
	- Status: Moot
	- Opened: 20261028-145157
	- Opened by: JC
	- Requirements:
		- `go mod download` works with nothing from the sister folders.
		- No `replace` line pointing at a local path.
	- Note: The rule file has its own parser now.

## Old format

### Bugs

### Features and enhancements

- Build, CI/CD, and install

	- 🛠️ A CI/CD pipeline kicked off by a bash script (`cicd/cicd.bash`): builds, tests, and can commit and push. Packaging and publishing are opt-in.
		- Started: it syncs, lints, builds, tests, fuzzes, dogfoods, and publishes. The rest is under the "CICD reset" items.

	- 🔘 Dev-environment install script (Linux bash, macOS sh, Windows PowerShell), runnable via a single `curl`/`wget` and documented under "how to develop". Clones main, installs dependencies, and states what it will do with an option to abort.

	- 🔘 Release-install script per platform, runnable via a single `curl`/`wget` and documented under "how to install". Downloads, installs, and runs the latest release, with an option to abort.
		- Superseded by ID: 2026102818015807.

- Configuration and persistence

	- 🔘 Default configuration hard-coded
		- 🔘 Overridden by per-user config file, created the first time a default setting is changed.
			- 🔘 Settings live under `~/.config` (YAML or TOML), resistant to errors (e.g. don't bail on the whole thing due to one bad line).
				- Note: config files use shcl, not YAML or TOML.
		- 🔘 Overridden by program options at run-time.
		- Needs more thought: flisty may not need a user config at all. Rules and settings come from the options or a rule file, never both, per design.md.

### Done

#### Done - Bugs

#### Done - Features and enhancements

### Deferred

### Canceled

## Template

### Old format

- 🔘 Not started

- 🛠️ Started, and/or partially complete

- 🔬 Testing not started or finished

- ✋ Defer

- ✅ Complete

- 🚫 Canceled

### New format

- Notes:

	- Only use rows that you actually need or expect will be filled in. Always fill in the title, ID, Type, Status, Opened and Created by.

	- The ID is the local time to the hundredth of a second. Opened is when it was written down, which may differ. (Use a keyboard macro and possibly something like project 'zuid' to generate.)

	- Status values meaning: Testing means the fix is in and checks are running or still to run. Waiting on signoff means automated testing passed. Moot means something else changed that made it irrelevant. Canceled means it still applies but was decided against. Waiting on automated testing means the fix is in and waits on a test run with no person needed. Waiting on a partial CICD run means it waits on a run of some stages, started by a person or automatically. Waiting on a full CICD run means the same for the whole pipeline, including a remote test host. Waiting on UAT means a person has to try it and judge. Can't reproduce means a real attempt to reproduce it failed.

	- An item waiting on signoff that is hard to test by hand is closed once the fix is sure and a regression test covers it, where one can be written.

	- As issues are worked, and statuses change, place them in correct sorting order within the list:
		- First by status: Waiting for answers, Waiting on signoff, Testing, Waiting on automated testing, Waiting on a partial CICD run, Waiting on a full CICD run, Waiting on UAT, Can't reproduce, Stalled, Started, Queued, Done, Deferred, Canceled, Moot
		- Then by severity|priority: Critical, High, Avg, Low
		- Then by type: Bugs, [not bugs together]

	- Rows marked [Bug] are for bugs only, and rows marked [Feature] for features and enhancements. Priority and Severity share one row and one scale. Priority is for a Feature or Enhancement, and Severity for a Bug. Children are not nested. They sit at the top level and point back with Parent ID.

Template:

- Title
	- ID: YYYYmmDDHHMMSSNN
	- Type: [Bug|Feature|Enhancement|Task]
	- Status: [Queued|Waiting for answers|Waiting on signoff|Waiting on automated testing|Waiting on a partial CICD run|Waiting on a full CICD run|Waiting on UAT|Started|Testing|Stalled|Can't reproduce|Moot|Canceled|Deferred|Done]
	- Needs local test suite run?:
	- Needs external testing:
	- Needs hand testing:
	- Priority [Feature|Enhancement] | Severity [Bug]: [Critical|High|Avg|Low]
	- Opened:
	- Opened by:
	- Assigned to:
	- Parent ID:
	- Prereq IDs:
	- Related IDs:
	- Target OS:
	- Test environment:
	- Version and build:
	- Requirements  [Feature]:
		- Hierarchical bulleted list.
	- Steps to reproduce [Bug]:
		- …
	- Incorrect behavior [Bug]:
	- Expected behavior [Bug]:
	- Reproduced [Bug]: [No, or when, where and how]
	- Possible cause [Bug]:
	- Actual cause [Bug]:
		- …
	- Estimated effort: [High|Avg|Low]
	- Actual effort: [High|Avg|Low]
	- Progress log:
		- …
	- Decisions:
		- …
	- Actual fix [Bug]:
	- Branch:
	- Commit:
	- Test case: [Reason not applicable, or CI test case #]
	- Acceptance signoff:
	- Superseded by ID:
	- Closed:
