// flisty lists the files under one or more folders that pass a set of include and
// exclude rules, given as options or in a rule file.

//	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
//	Licensed under the GNU General Public License v2.0 or later. Full text at:
//		https://spdx.org/licenses/GPL-2.0-or-later.html
//	SPDX-License-Identifier: GPL-2.0-or-later

package main

import (
	"fmt"
	"io"
	"os"
)

const appName = "flisty"

// Set at build time: -ldflags "-X main.version=x.y.z". The bare default marks a
// build nobody stamped.
var version = "0.0.0-dev"

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(args []string, stdout, stderr io.Writer) int {
	for _, arg := range args {
		switch arg {
		case "--version":
			return say(stdout, 0, "%s %s\nCopyright © 2026 Jim Collier. License: GPL-2.0-or-later. No warranty.\n", appName, versionText())
		case "-h", "--help":
			return say(stdout, 0, "Usage: %s [options] [FOLDER...]\n\n  --version   print the version and exit\n  -h, --help  this help\n\nListing isn't built yet.\n", appName)
		}
	}
	return say(stderr, 2, "%s: listing isn't built yet (try --help)\n", appName)
}

// say prints and returns rc, or 1 when the write fails, as it does into a closed pipe.
func say(w io.Writer, rc int, format string, a ...any) int {
	if _, err := fmt.Fprintf(w, format, a...); err != nil {
		return 1
	}
	return rc
}
