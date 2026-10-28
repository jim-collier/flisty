//	Copyright © 2026 Jim Collier [ID: 2უNაɘ«҂թȹɤξπ๙¿ձϖ]
//	Licensed under the GNU General Public License v2.0 or later. Full text at:
//		https://spdx.org/licenses/GPL-2.0-or-later.html
//	SPDX-License-Identifier: GPL-2.0-or-later

package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestVersionLine(t *testing.T) { // [dej9t]
	var out, errOut bytes.Buffer
	if rc := run([]string{"--version"}, &out, &errOut); rc != 0 {
		t.Fatalf("--version exit %d, want 0", rc)
	}
	first, _, _ := strings.Cut(out.String(), "\n")
	if !strings.HasPrefix(first, appName+" v") {
		t.Errorf("first line %q, want %q then the version", first, appName+" v")
	}
	if !strings.Contains(out.String(), "Copyright ©") {
		t.Errorf("no copyright line in %q", out.String())
	}
}

func TestHelpExitsZero(t *testing.T) { // [dej9v]
	for _, arg := range []string{"-h", "--help"} {
		var out, errOut bytes.Buffer
		if rc := run([]string{arg}, &out, &errOut); rc != 0 || !strings.Contains(out.String(), "Usage:") {
			t.Errorf("%s: exit %d, output %q", arg, rc, out.String())
		}
	}
}

func TestNoArgsIsAnError(t *testing.T) { // [dej9w]
	var out, errOut bytes.Buffer
	if rc := run(nil, &out, &errOut); rc != 2 || errOut.Len() == 0 {
		t.Errorf("no args: exit %d, stderr %q", rc, errOut.String())
	}
}
