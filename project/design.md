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
	- [Indentation](#indentation)
- [Direction decisions](#direction-decisions)
- [Testing](#testing)
- [Need to work out ambiguities](#need-to-work-out-ambiguities)
- [References](#references)

<!-- /TOC -->

## Summary

flisty walks one or more folders and prints the paths that pass a set of include and exclude rules. The rules come from command-line options or from a rule file. The output goes to stdout or to a file.

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

- `--input-config[=]FILE` reads nested include and exclude rules from a rule file.

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

- A small parser of its own for the rule file.

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

A rule file has one rule per line. The name is the long option name, then a colon, then the value. Nesting is by indent:

~~~text
include: /home/[^/]+/
	exclude: /\.cache/
		include: /\.cache/keep-me/
exclude: \.tmp$
iname: *.jpg
no-links
~~~

- The value is the rest of the line after the colon, with the spaces around it trimmed. Nothing in it is quoted or escaped, so a regex is written as it is.

- A line whose first character after the indent is `#` is a comment. There are no comments at the end of a line, since `#` can be part of a regex.

- Blank lines and comment lines don't count for indent.

- An on/off setting is its bare name, like `no-links`. The settings are `no-folders`, `no-links`, and `include-output-file`, and they go at the top level only. Setting one in both the file and the options is an error, the same as rules in both places.

- An unknown name, a rule with no value, or a value on a setting is an error, with its line number.

- The file is UTF-8. A byte order mark and CRLF line ends are accepted.

### Indentation

- Tabs or spaces, but not both. A file that uses both anywhere in its indents is an error.

- The step doesn't have to be even. A line indented more than the one above it is that line's child, by any amount.

- A line indented less goes back to the open level with exactly that indent. If no open level has it, the line falls between two levels and could belong to either, so it's an error.

- The first rule sets the top level. A line left of it is an error.

~~~text
include: a
    exclude: b
            include: c      <- child of b, an uneven step is fine
    exclude: d              <- back to b's level
  include: e                <- error, between the top level and b's
~~~

## Direction decisions

- The filter engine was copied from link-doctor rather than shared as a module. It's small, and the 2 programs can change it at their own pace.

- regexp2 was chosen over Go's `regexp` for lookaround and backreferences. It's slower and has no linear-time guarantee, so every match has a time limit.

- A hand-written option parser was chosen over go-arg, go-flags, cobra, and docopt. link-doctor's parser already handles prefix abbreviations and repeated options in order, which the libraries don't do well.

- Rules come from one place only. Mixing options and a rule file would need a rule for which goes first, and either answer surprises someone.

- The rule file has its own small format rather than shcl, YAML, or TOML. A rule list is order that matters, with repeats. shcl merges 2 siblings with the same name and value, and hands back each kind of field on its own, so the order had to be rebuilt by line number. Regexes also had to go in backticks. A line format with indent for nesting has none of those problems, and is easy to parse.

## Testing

- Go unit tests for each package, and native fuzz targets for anything that parses input.

- A regression suite that runs the built binary against scratch folder trees.

- Every test has an ID, as described in the pipeline script.

## Need to work out ambiguities

- Should Windows paths print with forward slashes? Version 2's notes want them in rules.

## References

- link-doctor, for the filter options and engine.

- x9incexc's `notes.txt`, for the version 2 rule language.
