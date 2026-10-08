#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge test for the test-only integrated lexical+2D production candidate.

Expected seven calendar values arise exclusively from independent native
Befunge reference programs; the old production is used only as regression
cross-check. The test does NOT call another language's calendar engine.
"""
from __future__ import print_function
import hashlib
import subprocess
import sys

NEW = "qa/interleaved_work_counts_lexical_candidate.b98"
OLD = "src/interleaved_work_counts.b98"
REF_COUNTS = "reference/work_counts.b98"
REF_SAVE = "reference/save.b98"
CMD = ["pyfunge", "--disable-fprint", "--no-concurrent", "--no-filesystem",
       "-v98", "-d2"]
RUNS = [0]

def invoke(path, stdin, timeout="50s"):
    RUNS[0] += 1
    cmd = ["timeout", "--kill-after=2s", timeout] + CMD + [path]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate(stdin)
    if p.returncode:
        raise AssertionError("native exit %s from %s input=%r stderr=%r" %
                             (p.returncode, path, stdin, stderr[-600:]))
    return stdout.split()

def same(label, got, expected):
    if got != expected:
        raise AssertionError("%s observed=%r expected=%r" %
                             (label, got, expected))

def signed(s, m):
    return int(m) * (-1 if s else 1)

PAIRS = [
    (0,0,0,0), (1,15055671,1,15055671),
    (1,15055672,1,15055670), (0,123456789,1,987654321),
    (1,987654321,0,123456789), (0,0,1,15055671),
    (1,15055671,0,0), (0,1,0,2), (0,2,0,1),
    (0,10**50+987654321,1,10**51+123456789),
    (1,10**77+987654321,0,10**78+123456789),
    (1,1,0,1), (1,2,1,3),
    (0,2**127-1,1,2**127-1),
    (1,2**127-1,0,2**127),
    (0,2**127,0,2**127-1),
    (0,2**126,1,2**127),
    (1,10**40,1,10**39),
    (0,2**128-2,1,2**128-1),
]
for i, pair in enumerate(PAIRS):
    sc, mc, st, mt = pair
    fields = [str(k) for k in pair]
    raw = " ".join(fields)
    reference = (invoke(REF_COUNTS, raw+"\n") +
                 invoke(REF_SAVE, "%d %d\n" % (sc, mc)) +
                 invoke(REF_SAVE, "%d %d\n" % (st, mt)))
    same("reference-field-count %d" % i, len(reference), 7)
    same("old-reference parity %d" % i,
         invoke(OLD, raw+"\n"), reference)
    # Half deliberately rely on the EOF reflection of character input.
    decorated = (raw+"\n") if i % 2 else ("\t"+raw+" ")
    same("candidate-reference parity %d" % i,
         invoke(NEW, decorated), reference)
    if i % 3 == 0:
        with_extra_whitespace = "\r\n".join([fields[0]+" "+fields[1],
                                                fields[2]+"\t"+fields[3]])
        same("candidate-whitespace parity %d" % i,
             invoke(NEW, with_extra_whitespace+"\n"), reference)
    if i % 4 == 0:
        print("NATIVE_INTEGRATED_VALID_PASS", i)

ILLEGAL_NUMERIC = [
    "1 0 0 0", "0 0 1 0", "2 10 0 10",
    "0 10 2 10", "3 2 0 4", "1 0 1 15055671",
]
for raw in ILLEGAL_NUMERIC:
    same("numeric-validation "+raw, invoke(NEW, raw+"\n"), ["-1"]*7)

ILLEGAL_LEXICAL = [
    "0 -1 0 1", "-0 1 0 1", "0 1 -0 1",
    "0 1 0 -1", "0 -0 0 1", "0 0 0 -0",
    "0 -15055671 0 1", "0 15055671 0 -15055670",
    "0 1 0 1 7", "0 1 0", "0 1 0 x",
    "0 1 0 1/", "", "\n", "0 1 0 +1"
]
for i, raw in enumerate(ILLEGAL_LEXICAL):
    same("lexical-rejection-%d %r" % (i,raw),
         invoke(NEW, raw + ("" if i % 2 else "\n")),
         ["-1"]*7)

print("NATIVE_INTEGRATED_LEXICAL_CANDIDATE_PASS",
      len(PAIRS), "valid_pairs",
      len(ILLEGAL_NUMERIC), "numeric_rejections",
      len(ILLEGAL_LEXICAL), "lexical_rejections",
      RUNS[0], "native_executions")
print("ACCEPTANCE_SCOPE=test-only Funge-space integration; full Stage 1 remains OPEN")
