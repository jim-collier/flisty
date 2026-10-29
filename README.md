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
# flisty

List the files under a folder that pass your include and exclude rules. Give the rules as options, or in a rule file where nesting narrows a rule to what its parent matched. The list goes to stdout or to a file, ready for a backup, sync, or archive tool to read.

flisty is in early development. It builds and prints its version, and the listing is what's being built now.

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

Most backup and sync jobs start with the same question: which files? Skip the trash and the cache, keep the photos, but keep this one folder inside the cache. `find` can answer it, but past a few rules its syntax is hard to read and harder to change. And every backup tool has its own rule format.

flisty answers only that question. Its rules read top to bottom, one at a time, and the result is a plain list any other tool can use.

If one or two `find` options do the job, keep using `find`. flisty doesn't copy, sync, or delete anything.

## Features

Planned for the first release:

- Include, exclude, and re-include rules, by regex or by `find`-style glob, applied in the order given.

- Rule files, where a nested rule applies only to what its parent matched:

	~~~text
	include: /home/[^/]+/
		exclude: /\.cache/
			include: /\.cache/keep-me/
	exclude: \.tmp$
	~~~

- Depth limits, staying on one filesystem, and following symlinks without looping.

- Output to stdout, or to a file with `--output-file`.

- Linux, macOS, Windows, and FreeBSD.

## Installation

There are no releases yet. Packages and install scripts come with the first one.

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
> flisty™ is a [trademark](trademark.md) of Jim Collier.
