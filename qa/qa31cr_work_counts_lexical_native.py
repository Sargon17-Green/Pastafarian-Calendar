#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native lexical contract for the active src/work_counts.b98 entry point.

Nine raw-negative probes are tested against the exact production source.
Each probe has a positive control whose seven output fields are compared
with two independent Native Befunge reference programs.
"""
from __future__ import print_function

import hashlib
import json
import os
import subprocess
import sys
import traceback

SOURCE = "src/work_counts.b98"
REF_COUNTS = "reference/work_counts.b98"
REF_SAVE = "reference/save.b98"

EXPECTED_BLOBS = {
    SOURCE: "7418e1ec5fe88fe5c14b75710dea2d5607527f28",
    REF_COUNTS: "f941efc793c9eee4accf5d03873f8ed029b16725",
    REF_SAVE: "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44",
}
EXPECTED_SHA256 = {
    SOURCE: "a59c1066843abfde9b059e9ec62b2c9daf0483f116095bbd78c19cf28ab59137",
    REF_COUNTS: "ae8bb575ec8016f90ed79ab44e114a4a6276dd949f34429105c3988f2259f094",
    REF_SAVE: "899459e3877c29d54267c1942fe0b413875df78c43697ecdd8c481673655ac9f",
}
PYFUNGE_TARBALL_SHA256 = "e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac"
ERROR = ["-1"] * 7
MAX_MAG = "170141183460469231731687303715884105727"

# Exactly one token carries a raw leading minus in each malformed case.
# Slots 1/3 are sign tokens; slots 2/4 are magnitude tokens.
CASES = [
    dict(id="slot1-minus-zero", slot=1, field="sign", bad="-0 1 0 1", good="0 1 0 1"),
    dict(id="slot1-minus-one", slot=1, field="sign", bad="-1 15055671 0 1", good="1 15055671 0 1"),
    dict(id="slot2-minus-one", slot=2, field="magnitude", bad="0 -1 0 1", good="0 1 0 1"),
    dict(id="slot2-minus-zero", slot=2, field="magnitude", bad="0 -0 0 1", good="0 0 0 1"),
    dict(id="slot2-calendar-boundary", slot=2, field="magnitude", bad="0 -15055671 0 1", good="0 15055671 0 1"),
    dict(id="slot3-minus-zero", slot=3, field="sign", bad="0 1 -0 1", good="0 1 0 1"),
    dict(id="slot3-minus-one", slot=3, field="sign", bad="0 1 -1 15055671", good="0 1 1 15055671"),
    dict(id="slot4-minus-zero", slot=4, field="magnitude", bad="0 1 0 -0", good="0 1 0 0"),
    dict(id="slot4-signed-magnitude-boundary", slot=4, field="magnitude",
         bad="0 15055671 0 -" + MAX_MAG,
         good="0 15055671 0 " + MAX_MAG),
]

INVOCATIONS = 0


def file_hashes(path):
    with open(path, "rb") as stream:
        data = stream.read()
    git_blob = hashlib.sha1(("blob %d\0" % len(data)).encode("ascii") + data).hexdigest()
    sha256 = hashlib.sha256(data).hexdigest()
    return len(data), git_blob, sha256


def invoke(path, raw):
    global INVOCATIONS
    INVOCATIONS += 1
    command = [
        "timeout", "--kill-after=2s", "50s",
        "pyfunge", "--disable-fprint", "--no-concurrent",
        "--no-filesystem", "-v98", "-d2", path
    ]
    process = subprocess.Popen(
        command, stdin=subprocess.PIPE,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate(raw + "\n")
    if process.returncode:
        raise AssertionError(
            "NATIVE_PROCESS_FAILURE path=%s input=%r exit=%r stderr=%r" %
            (path, raw, process.returncode, stderr[-1000:]))
    return stdout.split()


def independent_oracle(raw):
    fields = raw.split()
    if len(fields) != 4:
        raise AssertionError("ORACLE_INPUT_NOT_FOUR_TOKENS %r" % raw)
    five = invoke(REF_COUNTS, raw)
    saved_c = invoke(REF_SAVE, fields[0] + " " + fields[1])
    saved_t = invoke(REF_SAVE, fields[2] + " " + fields[3])
    if len(five) != 5 or len(saved_c) != 1 or len(saved_t) != 1:
        raise AssertionError(
            "REFERENCE_FIELD_SHAPE input=%r counts=%r save_c=%r save_t=%r" %
            (raw, five, saved_c, saved_t))
    return five + saved_c + saved_t


def validate_pair(case):
    bad = case["bad"].split()
    good = case["good"].split()
    slot = case["slot"] - 1
    if len(bad) != 4 or len(good) != 4:
        raise AssertionError("PROBE_NOT_FOUR_TOKENS %s" % case["id"])
    if not bad[slot].startswith("-") or bad[slot][1:] != good[slot]:
        raise AssertionError("PROBE_NOT_SINGLE_MINUS_EDIT %s" % case["id"])
    for index in range(4):
        if index != slot and bad[index] != good[index]:
            raise AssertionError("PROBE_CHANGES_MULTIPLE_TOKENS %s" % case["id"])
    if any(not token.isdigit() for token in good):
        raise AssertionError("POSITIVE_CONTROL_NOT_DECIMAL %s" % case["id"])
    if good[0] not in ("0", "1") or good[2] not in ("0", "1"):
        raise AssertionError("POSITIVE_CONTROL_BAD_SIGN %s" % case["id"])


def persist(path, receipt):
    parent = os.path.dirname(path)
    if parent and not os.path.isdir(parent):
        os.makedirs(parent)
    payload = json.dumps(receipt, sort_keys=True, indent=2) + "\n"
    if not isinstance(payload, bytes):
        payload = payload.encode("utf-8")
    with open(path, "wb") as stream:
        stream.write(payload)


def main(output_path):
    receipt = {
        "project_id": "PC-BRANCH-BEFUNGE98-KYRGYZ",
        "scope": "Stage1 QA only; no Stage2, merge, or production-source mutation",
        "test": "QA31CR Native raw-negative lexical contract",
        "interpreter": {
            "package": "PyFunge-0.5-rc2",
            "tarball_sha256": PYFUNGE_TARBALL_SHA256,
        },
        "source": {},
        "oracle": {},
        "expected_malformed_output": ERROR,
        "case_count_expected": len(CASES),
        "cases": [],
        "status": "RUNNING",
    }
    try:
        for path in (SOURCE, REF_COUNTS, REF_SAVE):
            size, blob, sha256 = file_hashes(path)
            receipt["source" if path == SOURCE else "oracle"][path] = {
                "bytes": size, "git_blob": blob, "sha256": sha256,
            }
            if blob != EXPECTED_BLOBS[path] or sha256 != EXPECTED_SHA256[path]:
                raise AssertionError(
                    "SOURCE_IDENTITY_MISMATCH path=%s blob=%s sha256=%s" %
                    (path, blob, sha256))
        persist(output_path, receipt)

        for case in CASES:
            validate_pair(case)
            expected = independent_oracle(case["good"])
            if len(expected) != 7 or expected == ERROR:
                raise AssertionError(
                    "POSITIVE_ORACLE_INVALID id=%s output=%r" %
                    (case["id"], expected))

            positive = invoke(SOURCE, case["good"])
            if positive != expected:
                raise AssertionError(
                    "POSITIVE_CONTROL_MISMATCH id=%s input=%r got=%r oracle=%r" %
                    (case["id"], case["good"], positive, expected))

            malformed = invoke(SOURCE, case["bad"])
            if malformed != ERROR:
                raise AssertionError(
                    "RAW_NEGATIVE_NOT_REJECTED id=%s input=%r got=%r expected=%r" %
                    (case["id"], case["bad"], malformed, ERROR))

            receipt["cases"].append({
                "id": case["id"],
                "token_slot_1_based": case["slot"],
                "token_kind": case["field"],
                "malformed_input": case["bad"],
                "malformed_output": malformed,
                "positive_control_input": case["good"],
                "positive_control_output": positive,
                "independent_oracle_output": expected,
                "positive_control_matches_oracle": True,
                "malformed_is_exactly_seven_minus_ones": True,
            })
            persist(output_path, receipt)
            print("QA31CR_CASE_PASS", case["id"], repr(case["bad"]),
                  "positive-control=oracle", len(expected), "fields")

        receipt["status"] = "PASS"
        receipt["raw_negative_probes_passed"] = len(receipt["cases"])
        receipt["positive_controls_passed"] = len(receipt["cases"])
        receipt["native_invocations"] = INVOCATIONS
        persist(output_path, receipt)
        print("QA31CR_NATIVE_LEXICAL_PASS",
              "raw_negative=9", "positive_oracle=9",
              "native_invocations=%d" % INVOCATIONS)
    except Exception as error:
        receipt["status"] = "FAIL"
        receipt["native_invocations_at_failure"] = INVOCATIONS
        receipt["error"] = repr(error)
        receipt["traceback"] = traceback.format_exc()
        persist(output_path, receipt)
        raise


if __name__ == "__main__":
    destination = sys.argv[1] if len(sys.argv) > 1 else "qa31cr_work_counts_lexical.json"
    main(destination)
