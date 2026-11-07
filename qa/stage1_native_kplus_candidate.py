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
import subprocess
import sys
import tempfile
import stage1_native_diverse_geometry as native_suite

SOURCE = "qa/interleaved_work_counts_kplus_2d_candidate.b98"
PICK = ("zero_equal", "forward_short", "foundation_cross",
        "large_values", "invalid_big_sign")
STEPS = ((1470, 100, 118), (1475, 101, 107),
         (1483, 101, 120), (1471, 100, 120))

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
            try:
                actual = native_suite.native(SOURCE, raw, trace=trace)
            except Exception:
                print("NATIVE_KPLUS_DIAGNOSTIC_FIRST_FAIL", label)
                if os.path.isfile(trace):
                    recording = False
                    count = 0
                    seen = 0
                    with open(trace, "rb") as failure_log:
                        for event in failure_log:
                            if not event.startswith("STEP\t"):
                                continue
                            fields = event.rstrip("\n").split("\t")
                            if len(fields) != 9:
                                continue
                            if not recording and fields[3:5] == ["1470", "100"]:
                                recording = True
                            if recording and count < 65:
                                print("NATIVE_KPLUS_DIAG_STEP", event.strip())
                                count += 1
                            seen += 1
                    print("NATIVE_KPLUS_DIAG_TOTAL_STEPS", seen)
                    print("NATIVE_KPLUS_DIAG_CAPTURED_AFTER_ENTRY", count)
                else:
                    print("NATIVE_KPLUS_DIAG_TRACE_NOT_FOUND")
                sys.stdout.flush()
                raise
            expect = (native_suite.expected_for(*values) if valid
                      else ["-1"] * 7)
            require(actual == expect,
                    "candidate native differential mismatch for %s: %r != %r" %
                    (label, actual, expect))
            seq = []
            expect_target = False
            with open(trace, "rb") as stream:
                for line in stream:
                    if not line.startswith("STEP\t"):
                        continue
                    parts = line.rstrip("\n").split("\t")
                    require(len(parts) == 9, "malformed native STEP record")
                    x, y, opcode = map(int, (parts[3], parts[4], parts[7]))
                    if expect_target:
                        require((x, y, opcode) == (1430, 1335, 94)
                                and (int(parts[5]), int(parts[6])) == (-41, 1235),
                                "native x rejoin did not preserve original arithmetic continuation")
                        expect_target = False
                    if (x, y, opcode) in STEPS:
                        seq.append((x, y, opcode))
                        if (x, y) == (1471, 100):
                            require((int(parts[5]), int(parts[6])) == (-12, -1),
                                    "return did not land on native x with vector (-12,-1)")
                            require(int(parts[8]) == 5,
                                    "k-assisted arithmetic changed the native pre-x stack depth")
                            expect_target = True
            require(not expect_target, "x rejoin target never executed")
            require(seq == list(STEPS),
                    "native executed k+ route missing/reordered for %s: %r" %
                    (label, seq))
            print("NATIVE_KPLUS_CANDIDATE_DIFF_AND_ROUTE_PASS", label,
                  "route", len(seq), "outputs", len(actual))
            sys.stdout.flush()
        # Native-only differential coverage for every other established
        # production geometry case, without claiming that all these inputs
        # must enter this particular detour. The routed subset above retains
        # its stronger four-event IP/stack assertions.
        remaining = sorted(set(cases) - set(PICK))
        for label in remaining:
            values, valid = cases[label]
            raw = " ".join(map(str, values)) + "\n"
            actual = native_suite.native(SOURCE, raw)
            expect = (native_suite.expected_for(*values) if valid
                      else ["-1"] * 7)
            require(actual == expect,
                    "untraced native candidate parity mismatch %s: %r vs %r" %
                    (label, actual, expect))
            print("NATIVE_KPLUS_FULL_CORPUS_PARITY_PASS", label,
                  "valid", valid, "output_fields", len(actual))
            sys.stdout.flush()
        # Native counterfactual: the 'k' cell must actually influence
        # computation, not merely appear on a rendered source map. A sham
        # exact-byte copy must retain output; replacing precisely one
        # executed opcode with a zero-digit must not retain successful output.
        with open(SOURCE, "rb") as stream:
            original_bytes = stream.read()
        rows = original_bytes.split("\n")
        require(rows[101][1475] == "k", "Native k site changed unexpectedly")
        sham = os.path.join(folder, "control_same_opcode.b98")
        mutant = os.path.join(folder, "mutant_zero_instead_of_k.b98")
        shutil.copyfile(SOURCE, sham)
        rows[101] = rows[101][:1475] + "0" + rows[101][1476:]
        with open(mutant, "wb") as output:
            output.write("\n".join(rows))
        for label in ("zero_equal", "foundation_cross"):
            values, valid = cases[label]
            raw = " ".join(map(str, values)) + "\n"
            natural = native_suite.native(SOURCE, raw)
            sham_output = native_suite.native(sham, raw)
            require(sham_output == natural,
                    "source-copy sham changed native result for " + label)
            cmd = ["timeout", "--kill-after=2s", "8s"] + native_suite.COMMAND + [mutant]
            p = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            counter_output, counter_stderr = p.communicate(raw)
            changed = p.returncode != 0 or counter_output.split() != natural
            require(changed,
                    "native k-to-zero counterfactual had no observable effect: "+
                    label)
            print("NATIVE_KPLUS_COUNTERFACTUAL_NON_INERT_PASS", label,
                  "sham_identical", True,
                  "mutant_exit", p.returncode,
                  "mutant_output_changed", counter_output.split() != natural)
            sys.stdout.flush()
    finally:
        shutil.rmtree(folder)
    print("NATIVE_KPLUS_CANDIDATE_TEST_ONLY_PASS", len(PICK), "of", len(PICK))
    print("NATIVE_KPLUS_ALL_TEN_CASE_NATIVE_DIFFERENTIAL_PASS", len(cases))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (candidate only)")

if __name__ == "__main__":
    main()
