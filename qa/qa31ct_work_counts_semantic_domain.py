#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""QA31CT: Native semantic-domain checks for the active four-field work_counts entry point."""
import hashlib
import json
import re
import subprocess
import sys
import traceback
from pathlib import Path

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
MODULUS = 170141183460469231731687303715884105727
ABOVE_MODULUS = MODULUS + 1
WIDE = 1 << 128
GRAMMAR = re.compile(rb"[ \t\r\n]*([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]+([0-9]+)[ \t\r\n]*\Z")

BAD = [
    dict(id="signC-two", raw=b"2 1 0 1\n"),
    dict(id="signC-nine", raw=b"9 123 0 1\n"),
    dict(id="signT-two", raw=b"0 1 2 1\n"),
    dict(id="signT-nine", raw=b"0 1 9 123\n"),
    dict(id="negative-zero-C", raw=b"1 0 0 1\n"),
    dict(id="negative-zero-T", raw=b"0 1 1 0\n"),
]
GOOD = [
    dict(id="both-zero", raw=b"0 0 0 0\n"),
    dict(id="small-positive", raw=b"0 1 0 1\n"),
    dict(id="negative-C", raw=b"1 1 0 1\n"),
    dict(id="negative-T", raw=b"0 1 1 1\n"),
    dict(id="modulus-boundary", raw=("1 %d 1 %d\n" % (MODULUS, MODULUS)).encode("ascii")),
    dict(id="above-modulus-C-wide-T", raw=("1 %d 0 %d\n" % (ABOVE_MODULUS, WIDE)).encode("ascii")),
    dict(id="wide-C-above-modulus-T", raw=("0 %d 1 %d\n" % (WIDE, ABOVE_MODULUS)).encode("ascii")),
    dict(id="calendar-and-modulus", raw=("0 15055671 1 %d\n" % MODULUS).encode("ascii")),
]
INVOCATIONS = 0


def need(value, why):
    if not value:
        raise AssertionError(why)


def file_hashes(path):
    raw = Path(path).read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()
    return len(raw), blob, hashlib.sha256(raw).hexdigest()


def parse_fields(raw):
    match = GRAMMAR.fullmatch(raw)
    need(match is not None, "input is not four ASCII decimal fields: " + repr(raw))
    return [int(value) for value in match.groups()]


def semantic_valid(fields):
    sign_c, magnitude_c, sign_t, magnitude_t = fields
    return (
        sign_c in (0, 1)
        and sign_t in (0, 1)
        and (sign_c == 0 or magnitude_c > 0)
        and (sign_t == 0 or magnitude_t > 0)
    )


def invoke(path, raw):
    global INVOCATIONS
    INVOCATIONS += 1
    command = [
        "timeout", "--kill-after=2s", "45s",
        "pyfunge", "--disable-fprint", "--no-concurrent",
        "--no-filesystem", "-v98", "-d2", path,
    ]
    process = subprocess.run(
        command, input=raw, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        timeout=50, check=False,
    )
    if process.returncode:
        raise AssertionError(
            "NATIVE_PROCESS_FAILURE path=%s input_hex=%s exit=%r stderr=%r"
            % (path, raw.hex(), process.returncode, process.stderr[-1500:])
        )
    try:
        return process.stdout.decode("ascii").split()
    except UnicodeDecodeError:
        raise AssertionError("NON_ASCII_NATIVE_OUTPUT path=%s input_hex=%s" % (path, raw.hex()))


def independent_oracle(fields):
    sign_c, magnitude_c, sign_t, magnitude_t = fields
    counts_input = ("%d %d %d %d\n" % tuple(fields)).encode("ascii")
    five = invoke(REF_COUNTS, counts_input)
    saved_c = invoke(REF_SAVE, ("%d %d\n" % (sign_c, magnitude_c)).encode("ascii"))
    saved_t = invoke(REF_SAVE, ("%d %d\n" % (sign_t, magnitude_t)).encode("ascii"))
    need(len(five) == 5 and len(saved_c) == 1 and len(saved_t) == 1,
         "INDEPENDENT_REFERENCE_FIELD_SHAPE")
    return five + saved_c + saved_t, [five, saved_c, saved_t]


def main(destination):
    receipt = {
        "project_id": "PC-BRANCH-BEFUNGE98-KYRGYZ",
        "scope": "Stage1 QA only; no production-source mutation, Stage2, merge, or main write",
        "test": "QA31CT Native semantic sign-domain and unbounded-magnitude contract",
        "source_ids": {},
        "expected_invalid_output": ERROR,
        "invalid_case_count_expected": len(BAD),
        "valid_case_count_expected": len(GOOD),
        "cases": [],
        "native_invocations": 0,
        "status": "RUNNING",
    }
    try:
        for path in (SOURCE, REF_COUNTS, REF_SAVE):
            size, blob, sha256 = file_hashes(path)
            receipt["source_ids"][path] = {"bytes": size, "git_blob": blob, "sha256": sha256}
            need(blob == EXPECTED_BLOBS[path] and sha256 == EXPECTED_SHA256[path],
                 "SOURCE_IDENTITY_MISMATCH " + path)

        for case in BAD:
            fields = parse_fields(case["raw"])
            need(not semantic_valid(fields), "BAD_CASE_IS_SEMANTICALLY_VALID " + case["id"])
            output = invoke(SOURCE, case["raw"])
            need(output == ERROR, "INVALID_SEMANTIC_INPUT_NOT_REJECTED id=%s output=%r" %
                 (case["id"], output))
            receipt["cases"].append({
                "id": case["id"], "class": "invalid-semantic",
                "raw_hex": case["raw"].hex(), "fields": fields,
                "output": output, "expected_output": ERROR,
                "exact_seven_minus_ones": True,
            })
            receipt["native_invocations"] = INVOCATIONS
            Path(destination).write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            print("QA31CT_INVALID_PASS", case["id"], "seven -1 fields")

        for case in GOOD:
            fields = parse_fields(case["raw"])
            need(semantic_valid(fields), "GOOD_CASE_IS_SEMANTICALLY_INVALID " + case["id"])
            expected, parts = independent_oracle(fields)
            need(len(expected) == 7 and expected != ERROR, "INVALID_POSITIVE_ORACLE " + case["id"])
            output = invoke(SOURCE, case["raw"])
            need(output == expected, "POSITIVE_NATIVE_ORACLE_MISMATCH id=%s output=%r oracle=%r" %
                 (case["id"], output, expected))
            receipt["cases"].append({
                "id": case["id"], "class": "valid-semantic",
                "raw_hex": case["raw"].hex(), "fields": fields,
                "output": output, "independent_oracle_parts": parts,
                "matches_independent_native_oracle": True,
                "magnitude_above_modulus": max(fields[1], fields[3]) > MODULUS,
            })
            receipt["native_invocations"] = INVOCATIONS
            Path(destination).write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            print("QA31CT_VALID_PASS", case["id"], "seven fields match independent Native oracle")

        receipt["status"] = "PASS"
        receipt["invalid_semantic_probes_passed"] = len(BAD)
        receipt["valid_native_oracle_controls_passed"] = len(GOOD)
        receipt["above_modulus_valid_controls_passed"] = sum(
            1 for case in receipt["cases"]
            if case["class"] == "valid-semantic" and case["magnitude_above_modulus"]
        )
        receipt["native_invocations"] = INVOCATIONS
        Path(destination).write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print("QA31CT_NATIVE_SEMANTIC_DOMAIN_PASS",
              "invalid=%d" % len(BAD),
              "valid=%d" % len(GOOD),
              "above-modulus-valid=%d" % receipt["above_modulus_valid_controls_passed"],
              "native_invocations=%d" % INVOCATIONS)
    except Exception as error:
        receipt["status"] = "FAIL"
        receipt["native_invocations_at_failure"] = INVOCATIONS
        receipt["error"] = repr(error)
        receipt["traceback"] = traceback.format_exc()
        Path(destination).write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        raise


if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "qa31ct_semantic_domain.json"
    main(output)
