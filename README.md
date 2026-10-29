<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
<div align="center">

![Go](https://img.shields.io/badge/Go-00ADD8?logo=go&logoColor=white)
[![License: GPL v2+](https://img.shields.io/badge/License-GPLv2%2B-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
![Lifecycle: Alpha](https://img.shields.io/badge/Lifecycle-Alpha-orange)
![Support](https://img.shields.io/badge/Support-Maintained-brightgreen)

</div>

<!-- TOC ignore:true -->
# Flisty

Problem: Complex selection of files to include for utilities like `rsync`, backup programs, etc. is a mess. Their CLI options are confusing and inconsistent - even with the same program over different versions.

Solution: Flisty does one thing, well: Produces a powerfully-filtered list of files with a powerful but logical and consistent approach, to feed other programs. (Either piped, or as a `--include`-style file that nearly everything supports.)

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Why](#why)
- [Features](#features)
- [Installation](#installation)
	- [DIY](#diy)
- [Set up development environment](#set-up-development-environment)
- [Support](#support)
- [Copyright and license](#copyright-and-license)

<!-- /TOC -->

## Why

Most backup and sync jobs start with the same question: which files? Skip the trash and the cache, keep the photos, but keep this one folder inside the cache. `find` works for small or simple jobs, but past a few rules its syntax is hard to read and harder to change. And every backup tool has its own rule format.

Flisty answers only that question. Its rules read top to bottom, one at a time, and the result is a plain list of files that any other tool can use.

Flisty doesn't do anything to the list of files.

## Features

You have total control over the dynamic generation of the file list, including:

- Multiple search entry points.

- Excluded file specs can be selectively re-included with narrower criteria (E.g. exclude all '.bak' files, except under '~/my-backups/'.)

- Include and/or exclude rules:
	- Based on any of:
		- Full regex
		- '*' style wildcards
		- Modification time
		- Size
		- Type (e.g. file or link)
		- Follow symlinks, or not
		- Follow foreign filesystem, or not
		- Follow nested filesystem (e.g. ZFS, Btrfs), or not
		- Depth limits
		- Looping symlink detection
		- Use apparent or canonical paths

- You can define your own string variables to avoid repetition, and/or to give complex regex expression meaningful names.

- You can also output a separate excluded list at the same time (e.g. for verification).

- Specify rules on as CLI options, or specify a rules list stored as a file.

- Output to stdout, or to a file with `--output-file`.

- Linux, Windows, macOS, and FreeBSD.

## Installation

*There are no releases yet. Packages and install scripts come with the first one*.

### DIY

Build from source with Go 1.26.2 or newer, then copy `flisty` to a folder on your `PATH`:

~~~bash
git clone https://github.com/jim-collier/flisty.git
cd flisty/source
go build -o flisty ./cmd/flisty
~~~

## Set up development environment

- Go 1.26.2 or newer.

- Bash 4.4 or newer, and shellcheck, for the pipeline scripts.

- Used when found: staticcheck, golangci-lint, govulncheck, and markdownlint-cli. `cicd/config.bash` lists the versions in use.

`cicd/cicd.bash` is the full pipeline: lint, tests, and fuzzing, then a local install and a git commit and push. `cicd/cicd.bash --merge-gate` runs the same checks, without the install, commit, or push. `--help` lists the other options.

## Support

- [GitHub Sponsors](https://github.com/sponsors/jim-collier)

- [Ko-fi](https://ko-fi.com/jimcollier)

## Copyright and license

> Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]<br />
> Licensed under the [GNU General Public License v2.0 or later](https://spdx.org/licenses/GPL-2.0-or-later.html)<br />
> SPDX-License-Identifier: `GPL-2.0-or-later` <br />
> No warranty.<br />
> Flisty™ is a [trademark](trademark.md) of Jim Collier.
