#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Second Native BF98 numeric oracle for the existing 24 live-pair records.

Independent PyFunge CLI subprocesses re-execute 18 valid-case reference
programs and six invalid-case production programs. They check numeric outputs
against both the report oracle and each record, and prove that coordinated
report-only changes are caught by fresh native replay.
No Python calendar arithmetic; QA only, Stage 1 remains open.
"""
from __future__ import print_function
import copy, hashlib, json, os, subprocess, sys

ROOT = "/pairs"
PINS = {
    "src/interleaved_work_counts.b98": "560d6aa5807a7f766213a33835cce85eab0fa40c",
    "reference/work_counts.b98": "f941efc793c9eee4accf5d03873f8ed029b16725",
    "reference/save.b98": "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"
}
VALID = (
    "0 0 0 0", "1 15055672 1 15055670",
    "0 123456789 1 987654321", "1 987654321 0 123456789",
    "0 10 0 20", "0 1 0 2"
)
INVALID = (
    "1 0 0 0", "0 0 1 0", "2 10 0 10",
    "0 -1 0 1", "0 1 0 x", "0 1 0 1 7"
)
PAIRS = (
    ("v0", "v1"), ("v2", "v3"), ("v4", "v5"),
    ("v0", "i0"), ("v2", "i3"), ("v4", "i4"),
    ("i1", "v1"), ("i2", "v3"), ("i5", "v5"),
    ("i0", "i3"), ("i1", "i4"), ("i2", "i5")
)
CLI = ["timeout", "--kill-after=2s", "45s", "pyfunge",
       "--disable-fprint", "--no-concurrent", "--no-filesystem", "-v98", "-d2"]


def need(ok, why):
    if not ok:
        raise AssertionError(why)


def pin(path):
    raw = open(path, "rb").read()
    return hashlib.sha1("blob %d\0%s" % (len(raw), raw)).hexdigest()


def native(path, stdin):
    p = subprocess.Popen(CLI + [path], stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate(stdin)
    need(p.returncode == 0, "fresh BF98 CLI error: " + path + repr(stderr[-200:]))
    words = stdout.split()
    need(len(words) > 0 and all(w.lstrip("-").isdigit() for w in words),
         "fresh BF98 nonnumeric output: " + path)
    return words


def consistent(doc):
    rows = doc.get("records")
    expected = doc.get("expected_by_label")
    if not isinstance(rows, list) or len(rows) != 24 or not isinstance(expected, dict):
        return False
    for i, row in enumerate(rows):
        a, b = PAIRS[i % 12]
        if (row.get("left") != a or row.get("right") != b or
                row.get("schedule") != ("AB" if i < 12 else "BA") or
                row.get("left_output") != expected.get(a) or
                row.get("right_output") != expected.get(b)):
            return False
    return True


def verify_report(doc, replay):
    """The same full numeric/identity verifier must reject original and mutated evidence."""
    need(doc.get("schema") == "befunge-stage1-live-pair-matrix-v1"
         and doc.get("source_git_blob") == PINS["src/interleaved_work_counts.b98"]
         and doc.get("stage1_final_acceptance") is False,
         "live pair report identity or stage status changed")
    need(consistent(doc), "original Native pair records inconsistent")
    need(doc["expected_by_label"] == replay,
         "reported expected values differ from freshly executed Native BF98")
    for i, row in enumerate(doc["records"]):
        a, b = PAIRS[i % 12]
        need(row["left_output"] == replay[a] and
             row["right_output"] == replay[b],
             "Native pair output differs from second Native reference")


def reject_control(mutant, replay, expected_reason):
    """A forged document must be rejected by verify_report itself, at the right gate."""
    try:
        verify_report(mutant, replay)
    except AssertionError as error:
        need(str(error) == expected_reason,
             "mutant rejected by wrong gate: " + repr(error))
        return
    need(False, "mutant was accepted by full native evidence verifier")


def main():
    need(os.path.isdir(ROOT), "pair evidence directory missing")
    for path, sha in PINS.items():
        need(pin(path) == sha, "BF98 source changed: " + path)
    replay = {}
    for i, line in enumerate(VALID):
        a, b, c, d = line.split()
        words = (native("reference/work_counts.b98", line + "\n") +
                 native("reference/save.b98", a + " " + b + "\n") +
                 native("reference/save.b98", c + " " + d + "\n"))
        need(len(words) == 7, "fresh BF98 seven numeric fields missing")
        replay["v%d" % i] = words
    for i, line in enumerate(INVALID):
        words = native("src/interleaved_work_counts.b98", line + "\n")
        need(words == ["-1"] * 7,
             "fresh Native BF98 invalid-case rejection failed: i%d" % i)
        replay["i%d" % i] = words
    doc = json.load(open(ROOT + "/native_live_pair_matrix.json", "rb"))
    verify_report(doc, replay)
    controls = []
    for label in ("v%d" % i for i in range(6)):
        mutant = copy.deepcopy(doc)
        old = mutant["expected_by_label"][label][0]
        new = "-999999999" if old != "-999999999" else "-888888888"
        mutant["expected_by_label"][label][0] = new
        for row in mutant["records"]:
            for side in ("left", "right"):
                if row[side] == label:
                    row[side + "_output"][0] = new
        need(consistent(mutant),
             "coordinated control did not preserve internal report consistency")
        reject_control(mutant, replay,
                       "reported expected values differ from freshly executed Native BF98")
        controls.append(label)
    for label in ("i%d" % i for i in range(6)):
        mutant = copy.deepcopy(doc)
        new = "-999999999"
        mutant["expected_by_label"][label][0] = new
        for row in mutant["records"]:
            for side in ("left", "right"):
                if row[side] == label:
                    row[side + "_output"][0] = new
        need(consistent(mutant),
             "invalid-case coordinated control lost internal consistency")
        reject_control(mutant, replay,
                       "reported expected values differ from freshly executed Native BF98")
        controls.append(label)
    need(len(controls) == 12, "coordinated report controls incomplete")
    integrity = []
    for label, field, val, reason in (
            ("source", "source_git_blob", "0" * 40,
             "live pair report identity or stage status changed"),
            ("stage", "stage1_final_acceptance", True,
             "live pair report identity or stage status changed")):
        mutant = copy.deepcopy(doc)
        mutant[field] = val
        reject_control(mutant, replay, reason)
        integrity.append(label)
    mutant = copy.deepcopy(doc)
    mutant["records"][0]["schedule"] = "BA"
    reject_control(mutant, replay, "original Native pair records inconsistent")
    integrity.append("pair_schedule")
    need(len(integrity) == 3, "report integrity controls incomplete")
    result = {
        "schema": "befunge-stage1-native-second-oracle-live-pair-v1",
        "source_git_blobs": PINS,
        "native_reference_invocations": 18,
        "native_production_invalid_invocations": 6,
        "independent_valid_vectors": 6,
        "fresh_invalid_rejection_vectors": 6,
        "paired_program_outputs_checked": 48,
        "coordinated_output_controls_rejected": controls,
        "report_integrity_controls_rejected": integrity,
        "replayed_seven_field_oracles": replay,
        "stage1_final_acceptance": False
    }
    with open(ROOT + "/native_second_oracle_live_pair.json", "wb") as out:
        out.write((json.dumps(result, sort_keys=True, indent=2) + "\n").encode("utf-8"))
    print("NATIVE_BF98_SECOND_ORACLE_18_REFERENCE_6_INVALID_PRODUCTION_48_OUTPUTS_PASS")
    print("NATIVE_BF98_TWELVE_COORDINATED_REPORT_CHANGES_REJECTED_PASS")
    print("NATIVE_BF98_THREE_REPORT_INTEGRITY_MUTATIONS_REJECTED_PASS")
    print("STAGE1_FINAL_ACCEPTANCE=OPEN")


if __name__ == "__main__":
    main()
