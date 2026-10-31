#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge-98 opcode capability probes; NOT calendar computation.

Each candidate is executable Befunge-98, interpreted by the same pinned
PyFunge used for the production tests. Python only launches programs and
checks their public output. These microprograms are NOT production route
or final GEOMETRIC_SPAGHETTI_QA_PASS evidence.
"""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile

NATIVE = ["pyfunge", "--disable-fprint", "--no-concurrent",
          "--no-filesystem", "-v98", "-d2"]
# Program coordinates matter; do not trim indentation on any line.
CASES = [
    ("turn_left_up", "v @\nv .\n>2[\n", ["2"]),
    ("turn_right_down", ">2]\n  .\n  @\n", ["2"]),
    ("compare_right", ">21w\n   7\n   .\n   @\n", ["7"]),
    ("compare_equal", ">22w7.@\n", ["7"]),
    ("vertical_if_zero", ">0|\n  7\n  .\n  @\n", ["7"]),
    ("horizontal_if_zero", ">0_7.@\n", ["7"]),
    ("iterate_digit", ">3k1++.@\n", ["3"]),
    ("jump_and_reverse", "v\n>92j@.r\n", ["9"]),
    ("begin_end_stack", ">70{0}.@\n", ["7"]),
    ("stack_under_transfer", ">70{3u.@\n", ["7"]),
]

def check(condition, message):
    if not condition:
        raise AssertionError(message)

def main():
    folder = tempfile.mkdtemp(prefix="befunge-native-opcodes-")
    try:
        for name, code, expected in CASES:
            path = os.path.join(folder, name + ".b98")
            with open(path, "wb") as handle:
                handle.write(code)
            p = subprocess.Popen(["timeout", "--kill-after=2s", "8s"] +
                                 NATIVE + [path], stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = p.communicate("")
            actual = out.split()
            check(p.returncode == 0 and actual == expected,
                  "%s: exit=%r native=%r expected=%r stderr=%r" %
                  (name, p.returncode, actual, expected, err[-800:]))
            print("NATIVE_OPCODE_CAPABILITY_PASS", name,
                  "tokens", len(actual))
            sys.stdout.flush()
    finally:
        shutil.rmtree(folder)
    print("NATIVE_OPCODE_CAPABILITIES_PASS", len(CASES), "of", len(CASES))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (test-only probes)")

if __name__ == "__main__":
    main()
