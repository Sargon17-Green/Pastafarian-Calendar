#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Befunge-98 lexical contract negative tests.

The production must reject raw '-' in any of its four signed-magnitude
transport slots, even though Funge-98 '&' may skip it. This is a test,
NOT a calendar algorithm, reference oracle, or a production wrapper.
"""
from __future__ import print_function
import subprocess
import sys

PROGRAM = "src/interleaved_work_counts.b98"
CMD = [
    "timeout", "--kill-after=2s", "50s",
    "pyfunge", "--disable-fprint", "--no-concurrent",
    "--no-filesystem", "-v98", "-d2", PROGRAM
]
ERROR = ["-1"] * 7

def native(stdin_text):
    p = subprocess.Popen(
        CMD, stdin=subprocess.PIPE,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate(stdin_text + "\n")
    if p.returncode:
        raise AssertionError(
            "NATIVE_CRASH input=%r code=%r stderr=%r" %
            (stdin_text, p.returncode, err[-700:]))
    return out.split()

def test_case(raw, cleaned):
    malformed = native(raw)
    lawful = native(cleaned)
    if len(lawful) != 7 or lawful == ERROR:
        raise AssertionError(
            "POSITIVE_CONTROL_INVALID input=%r got=%r" %
            (cleaned, lawful))
    if malformed != ERROR:
        print("LEXICAL_REJECTION_FAIL", repr(raw),
              "got=", repr(malformed), "expected=", repr(ERROR),
              "equivalent_legal_input=", repr(cleaned),
              "equivalent_legal_output=", repr(lawful))
        raise AssertionError("native Befunge accepted malformed '-' input")
    print("LEXICAL_REJECTION_PASS", repr(raw))

# The canonical signed-magnitude representation requires all FOUR tokens
# to be nonnegative decimal integers, even when a token spells zero.
PROBES = [
    ("-0 1 0 1", "0 1 0 1"),
    ("0 -1 0 1", "0 1 0 1"),
    ("0 1 -0 1", "0 1 0 1"),
    ("0 1 0 -1", "0 1 0 1"),
    ("0 -0 0 1", "0 0 0 1"),
    ("0 0 0 -0", "0 0 0 0"),
    ("0 -15055671 0 1", "0 15055671 0 1"),
    ("0 15055671 0 -15055670", "0 15055671 0 15055670"),
]
for a, b in PROBES:
    test_case(a, b)
print("NATIVE_LEXICAL_REJECTION_PASS", len(PROBES))
