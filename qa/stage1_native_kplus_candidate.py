#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native differential and executed-route guard for test-only k+ 2D detour.

This Python module does not implement calendar arithmetic or an oracle:
all expected valid outputs come from existing independent Befunge references.
It does not certify full production geometry or Stage 1 completion.
"""
from __future__ import print_function
import os
import shutil
import sys
import tempfile
import stage1_native_diverse_geometry as native_suite

SOURCE = "qa/interleaved_work_counts_kplus_2d_candidate.b98"
PICK = ("zero_equal", "forward_short", "foundation_cross",
        "large_values", "invalid_big_sign")
STEPS = ((1470, 100, 118), (1472, 101, 107),
         (1480, 101, 120), (1471, 100, 120))

def require(ok, message):
    if not ok:
        raise AssertionError(message)

def main():
    cases = dict((name, (fields, valid)) for name, fields, valid
                 in native_suite.CASES)
    folder = tempfile.mkdtemp(prefix="befunge-kplus-native-")
    try:
        for label in PICK:
            values, valid = cases[label]
            raw = " ".join(map(str, values)) + "\n"
            trace = os.path.join(folder, label + ".tsv")
            actual = native_suite.native(SOURCE, raw, trace=trace)
            expect = (native_suite.expected_for(*values) if valid
                      else ["-1"] * 7)
            require(actual == expect,
                    "candidate native differential mismatch for %s: %r != %r" %
                    (label, actual, expect))
            seq = []
            with open(trace, "rb") as stream:
                for line in stream:
                    if not line.startswith("STEP\t"):
                        continue
                    parts = line.rstrip("\n").split("\t")
                    require(len(parts) == 9, "malformed native STEP record")
                    x, y, opcode = map(int, (parts[3], parts[4], parts[7]))
                    if (x, y, opcode) in STEPS:
                        seq.append((x, y, opcode))
                        if (x, y) == (1471, 100):
                            require((int(parts[5]), int(parts[6])) == (-9, -1),
                                    "return did not land on native x with vector (-9,-1)")
            require(seq == list(STEPS),
                    "native executed k+ route missing/reordered for %s: %r" %
                    (label, seq))
            print("NATIVE_KPLUS_CANDIDATE_DIFF_AND_ROUTE_PASS", label,
                  "route", len(seq), "outputs", len(actual))
            sys.stdout.flush()
    finally:
        shutil.rmtree(folder)
    print("NATIVE_KPLUS_CANDIDATE_TEST_ONLY_PASS", len(PICK), "of", len(PICK))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (candidate only)")

if __name__ == "__main__":
    main()
