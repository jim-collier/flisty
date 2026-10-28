<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->

<!-- TOC ignore:true -->
# Design

Design, requirements, and direction. The active pre-v1.0.0 bug and feature list is in `backlog.md`.

- Status: draft.

- Started: 2026-10-28.

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Summary](#summary)
- [Background](#background)
- [Goals and non-goals](#goals-and-non-goals)
- [Requirements](#requirements)
	- [Version 1](#version-1)
	- [Version 2](#version-2)
- [Architecture](#architecture)
	- [Software stack](#software-stack)
	- [Folder structure](#folder-structure)
	- [Data flow](#data-flow)
- [Rule pipeline](#rule-pipeline)
	- [Nested rules](#nested-rules)
- [Rule files](#rule-files)
- [Direction decisions](#direction-decisions)
- [Testing](#testing)
- [Need to work out ambiguities](#need-to-work-out-ambiguities)
- [References](#references)

<!-- /TOC -->

## Summary

flisty walks one or more folders and prints the paths that pass a set of include and exclude rules. The rules come from command-line options or from a `.shcl` file. The output goes to stdout or to a file.

## Background

A backup, sync, or archive job usually starts with "which files?" The answer is a list of rules, like skip the trash folders, keep the photos, skip the cache but keep this one folder in it. `find` can do it, but its syntax gets hard to read past a few rules. Each backup tool also has its own rule format, and they don't agree.

flisty answers only that question, and prints a list that other tools can read. It takes the filter options from link-doctor, a sister project, and adds a rule file with nesting. Version 2 adds the rule language sketched in x9incexc's notes, from an older project called Rsyncy.

## Goals and non-goals

- Goals:
	- Filter options that read left to right, one rule at a time.
	- A rule file where nesting limits a rule to what its parent matched.
	- Fast on large trees, and a small binary.
	- Linux, macOS, Windows, and FreeBSD.

- Non-goals:
	- Copying, syncing, or deleting anything. flisty only lists.
	- Searching file contents.

## Requirements

### Version 1

- Positional folders to walk, defaulting to the current folder.

- The same filter options as link-doctor, against each file's path:
	- `--include`, `--exclude`, and `--re-include` regexes.
	- `--name`, `--iname`, `--wholename`, and `--iwholename` globs, as in `find`.
	- `--max-depth`, `--no-cross-device`, and `--follow-links`.

- `--input-config[=]FILE.shcl` reads nested include and exclude rules, through shclwrap.

- Rules come from the options or from the rule file, never both. That's an error, so there's no question of which comes first.

- `--output-file[=]FILE` writes the list there. Otherwise it goes to stdout. The file name is required.

- The output file is left out of the list when it's inside a walked folder. `--include-output-file` keeps it.

- Paths print as given. An absolute start folder gives absolute paths, and a relative one gives relative paths.

- Anything the rules match is listed: files, folders, and links. `--no-folders` and `--no-links` leave those out.

### Version 2

From x9incexc's `notes.txt`. All of this needs more detail before it's built.

- Macros: named regex pieces, used as `$Name`. The notes name some with emoji, which is hard to type and should change.

- Rule files that include other rule files, and inherit their macros.

- Settings that hold for a scope and revert when it ends, such as case sensitivity and how to treat symlinks.

- `consider` roots, which are scanned but list nothing until a rule includes it.

- A built-in set of common excludes, such as trash folders, `.DS_Store`, and swap files.

- Ordering the output by size, by date, and by name groups.

- Sizes with units, where `MB` is 1000 bytes and `MiB` is 1024.

## Architecture

### Software stack

- Go, standard library first.

- `github.com/dlclark/regexp2` for regex, for lookaround and backreferences.

- shclwrap for the rule file, over shcl 3.0.

### Folder structure

| Path                  | What
|:---                   |:---
| `source/cmd/flisty/`  | The command: options, help, and version.
| `source/filter/`      | The rule pipeline, copied from link-doctor.
| `cicd/`               | The pipeline script, its settings, and the regression suite.
| `project/`            | This file and the backlog.

### Data flow

1. The options, or the rule file, become one ordered list of rules.

2. The walk visits each folder in turn and hands each path to the rules.

3. A path that passes goes straight to the output. Nothing is held in memory past the current folder.

## Rule pipeline

Each rule does one fixed thing to a path's keep state, whatever its position:

- An include narrows. The path stays only if it was kept and also matches.

- An exclude subtracts. A path that matches is dropped.

- A re-include widens. A path that matches comes back, even after an exclude dropped it.

So the rules read left to right, one at a time. This is link-doctor's model, and its `filter` package is used as-is.

### Nested rules

A nested list applies only to the paths its parent rule matched. It starts from the state the parent left.

- Under an include, the nested rules narrow or subtract from what that include matched.

- Under an exclude, a nested include brings back part of what was excluded.

Paths the parent didn't match never see the nested rules.

## Rule files

A rule file is shcl. Field names are the long option names, and nesting is by indent:

~~~text
include: `/home/[^/]+/`
	exclude: `/\.cache/`
		include: `/\.cache/keep-me/`
exclude: `\.tmp$`
iname: *.jpg
~~~

- Regexes go in backticks. shcl never decodes a backtick value, and a `#` in one isn't read as a comment.

- shcl gives each kind of field separately, so flisty puts them back in file order by line number.

- shcl merges 2 siblings with the same name and value into one, and reports it as H002. In a rule list that moves the second one to where the first was, and the result can change. flisty refuses a rule file with an H002.

- A rule file can also set `no-folders`, `no-links`, and `include-output-file`. Setting one of those in both places is an error, the same as rules in both places.

## Direction decisions

- The filter engine was copied from link-doctor rather than shared as a module. It's small, and the 2 programs can change it at their own pace.

- regexp2 was chosen over Go's `regexp` for lookaround and backreferences. It's slower and has no linear-time guarantee, so every match has a time limit.

- A hand-written option parser was chosen over go-arg, go-flags, cobra, and docopt. link-doctor's parser already handles prefix abbreviations and repeated options in order, which the libraries don't do well.

- Rules come from one place only. Mixing options and a rule file would need a rule for which goes first, and either answer surprises someone.

- shcl was chosen for the rule file over YAML and TOML. It's the format the sister projects use for config, and its nesting fits nested rules.

## Testing

- Go unit tests for each package, and native fuzz targets for anything that parses input.

- A regression suite that runs the built binary against scratch folder trees.

- Every test has an ID, as described in the pipeline script.

## Need to work out ambiguities

- Should Windows paths print with forward slashes? Version 2's notes want them in rules.

## References

- link-doctor, for the filter options and engine.

- x9incexc's `notes.txt`, for the version 2 rule language.

- shcl and shclwrap, for the rule file.
