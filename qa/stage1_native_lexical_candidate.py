#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge-98 qualification for a test-only lexical parser candidate.

This is a parser test only. It does not compute calendar values, run
another-language production fallback, or certify the main production engine. The candidate uses the specified
~ EOF reflection path, not a fictional -1 EOF byte.
"""
from __future__ import print_function
import random
import subprocess

PROGRAM = "qa/lexical_candidate.b98"
CMD = ["timeout", "--kill-after=2s", "20s", "pyfunge",
       "--disable-fprint", "--no-concurrent", "--no-filesystem",
       "-v98", "-d2", PROGRAM]

def check(source, expected):
    proc = subprocess.Popen(CMD, stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate(source)
    if proc.returncode != 0:
        raise AssertionError("NATIVE_CANDIDATE_PROCESS_FAILED %r rc=%s %r"
                             % (source, proc.returncode, err[-400:]))
    tokens = out.split()
    if tokens != expected:
        raise AssertionError("NATIVE_CANDIDATE_MISMATCH %r got=%r exp=%r"
                             % (source, tokens, expected))

valid = [
    "0 1 0 1\n",
    "0 0 0 0",
    "1 15055671 0 12\n",
    "  \t1   15055671\t0 12 \n",
    "0 123456789012345678901234567890 0 3",
    "0 170141183460469231731687303715884105727 1 1\n",
    "0 1 0 1\n\n  ",
    "0 9999999999999999999999999999999999999999999999999999 1 8\n",
]
invalid = [
    "0 -1 0 1\n", "-0 1 0 1\n", "0 1 -0 1\n",
    "0 1 0 -1\n", "0 -0 0 1\n", "0 0 0 -0\n",
    "0 1 0 1 9\n", "0 1 0\n", "0 1 0 a\n",
    "0 1 0 1/", "0 1 0 1 -2", "\n", "",
]
randomizer = random.Random(20261008)
for i in range(35):
    a = randomizer.randint(1, 80)
    b = randomizer.randint(1, 80)
    mag1 = "".join(str(randomizer.randrange(10)) for _ in range(a))
    mag2 = "".join(str(randomizer.randrange(10)) for _ in range(b))
    tokens = ["0", mag1, "1", mag2]
    valid.append(" ".join(tokens) + ("\n" if i % 2 else ""))
    bad = list(tokens)
    position = i % 4
    bad[position] = "-" + bad[position]
    invalid.append(" ".join(bad) + ("\n" if i % 2 else ""))

for source in valid:
    expected = [str(int(t)) for t in source.split()]
    check(source, expected)
for source in invalid:
    check(source, ["-1"])
print("NATIVE_BEFUNGE_LEXICAL_PARSER_CANDIDATE_PASS",
      len(valid), "valid", len(invalid), "invalid")
print("SCOPE_TEST_ONLY_PROTOTYPE; PRODUCTION_INTEGRATION_NOT_DONE")
