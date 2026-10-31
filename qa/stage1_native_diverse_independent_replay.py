#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Fresh PyFunge replays: independent Native reference versus archived output.

Python only dispatches Befunge-98 programs and compares their seven output
fields. This is an independent second run, not a Python calendar oracle and
not full Stage-1 acceptance. Python 2.7 and Python 3 compatible.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys

ROOT = "/diverse"
SOURCE = "src/interleaved_work_counts.b98"
COUNT_REFERENCE = "reference/work_counts.b98"
SAVE_REFERENCE = "reference/save.b98"
PINS = {
    SOURCE: "560d6aa5807a7f766213a33835cce85eab0fa40c",
    COUNT_REFERENCE: "f941efc793c9eee4accf5d03873f8ed029b16725",
    SAVE_REFERENCE: "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44",
}
COMMAND = ("pyfunge", "--disable-fprint", "--no-concurrent",
           "--no-filesystem", "-v98", "-d2")
# Independent of the native producer and its Python-3 manifest validator.
CASES = (
    ("zero_equal", (0,0,0,0), True),
    ("foundation_cross", (1,15055672,1,15055670), True),
    ("forward_short", (0,1,0,2), True),
    ("reverse_short", (0,2,0,1), True),
    ("mixed_small", (1,1,0,1), True),
    ("positive_negative", (0,123456789,1,987654321), True),
    ("negative_positive", (1,987654321,0,123456789), True),
    ("large_values", (0,2**127,1,2**127-1), True),
    ("invalid_zero_sign", (1,0,0,0), False),
    ("invalid_big_sign", (2,10,0,10), False),
    ("epoch_forward_one", (0,0,0,1), True),
    ("epoch_reverse_one", (0,1,0,0), True),
    ("recent_anchor_equal", (0,2461319,0,2461319), True),
    ("recent_anchor_next", (0,2461319,0,2461320), True),
    ("foundation_neighbor_forward", (1,15055671,1,15055670), True),
    ("foundation_neighbor_reverse", (1,15055670,1,15055671), True),
    ("invalid_target_zero_sign", (0,0,1,0), False),
)

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def sha_git_blob(path):
    with open(path, "rb") as f:
        payload = f.read()
    header = b"blob " + str(len(payload)).encode("ascii") + b"\0"
    return hashlib.sha1(header + payload).hexdigest()

def replay(path, input_text):
    env = os.environ.copy()
    env.pop("BF98_TRACE_LOG", None)
    # Each call is a fresh native interpreter with isolated Funge-space.
    cmd = ("timeout", "--kill-after=2s", "50s") + COMMAND + (path,)
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                            env=env)
    out,err = proc.communicate(input_text.encode("ascii"))
    need(proc.returncode == 0,
         "independent Native replay failed for %s (exit=%s): %s" %
         (path, proc.returncode, repr(err[-500:])))
    return [part.decode("ascii") for part in out.split()]

def read_saved(folder, label):
    path = os.path.join(folder, label + ".out")
    with open(path, "rb") as f:
        return f.read()

def verify_output(label, manifest_output, saved, production, independent):
    need(manifest_output == production and len(production) == 7,
         "archived manifest differs from fresh native production: " + label)
    need(saved == (" ".join(production) + "\n").encode("ascii"),
         "saved native output differs from fresh production: " + label)
    need(production == independent and len(independent) == 7,
         "native production differs from independent Befunge references: " + label)

def adversarial_controls(clean):
    label, native = "zero_equal", list(clean)
    forged = list(native)
    forged[0] = str(int(forged[0]) + 1)
    clean_bytes = (" ".join(native) + "\n").encode("ascii")
    forged_bytes = (" ".join(forged) + "\n").encode("ascii")
    cases = (
        ("forged_manifest", forged, clean_bytes, native, native),
        ("forged_saved_stdout", native, forged_bytes, native, native),
        ("coordinated_manifest_and_saved_stdout", forged, forged_bytes,
         native, native),
        ("coordinated_production_claim_and_saved_stdout", forged, forged_bytes,
         forged, native),
    )
    rejected = []
    for name, claim, saved, fresh, reference in cases:
        try:
            verify_output(label, claim, saved, fresh, reference)
        except AssertionError:
            rejected.append(name)
        else:
            raise AssertionError("Native replay falsely accepted " + name)
    need(len(rejected) == 4,
         "independent Native replay hostile report controls incomplete")
    print("NATIVE_DIVERSE_REPLAY_4_COORDINATED_OUTPUT_FORGERIES_REJECT_PASS")
    return rejected

def main():
    need(os.path.isdir(ROOT), "Native diverse trace directory missing")
    for path, pin in PINS.items():
        need(sha_git_blob(path) == pin,
             "Native program identity changed: " + path)
    with open(os.path.join(ROOT, "diverse_manifest.json"), "rb") as f:
        manifest = json.load(f)
    rows = manifest.get("cases")
    need(manifest.get("schema") == "befunge-stage1-diverse-native-v1" and
         type(rows) is list and len(rows) == len(CASES),
         "Native 17-case replay manifest incomplete")
    report = []
    reference_runs = 0
    for i, (label, fields, valid) in enumerate(CASES):
        row = rows[i]
        need(row.get("case") == label and row.get("fields") == list(fields)
             and row.get("valid") is valid and
             row.get("trace_file") == label + ".tsv",
             "independent native replay input/case provenance changed: " + label)
        raw = "%d %d %d %d\n" % fields
        observed_production = replay(SOURCE, raw)
        if valid:
            expected = (replay(COUNT_REFERENCE, raw) +
                        replay(SAVE_REFERENCE, "%d %d\n" % fields[:2]) +
                        replay(SAVE_REFERENCE, "%d %d\n" % fields[2:]))
            reference_runs += 3
        else:
            expected = ["-1"] * 7
        saved = read_saved(ROOT, label)
        verify_output(label, row.get("output"), saved,
                      observed_production, expected)
        report.append({
            "case": label,
            "valid": valid,
            "fields": list(fields),
            "native_production_output": observed_production,
            "native_reference_output": expected,
            "saved_output_sha256": hashlib.sha256(saved).hexdigest(),
            "reference_native_runs": 3 if valid else 0,
        })
        print("NATIVE_DIVERSE_INDEPENDENT_REPLAY_PASS", label,
              "native_reference_runs", 3 if valid else 0)
        sys.stdout.flush()
    need(reference_runs == 42, "expected 42 actual native reference invocations")
    rejected = adversarial_controls(report[0]["native_production_output"])
    summary = {
        "schema": "befunge-stage1-diverse-independent-native-replay-v1",
        "scope": "QA_ONLY_NOT_STAGE1_ACCEPTANCE",
        "source_git_blobs": PINS,
        "native_production_reexecutions": 17,
        "independent_native_reference_executions": reference_runs,
        "fresh_native_processes": 17 + reference_runs,
        "invalid_cases_checked_with_native_production_and_sentinels": 3,
        "hostile_output_reports_rejected": rejected,
        "stage1_complete": False,
        "functional_stage1_gate": "OPEN",
        "geometric_stage1_gate": "OPEN",
        "records": report,
    }
    with open(os.path.join(ROOT, "native_diverse_independent_replay.json"), "wb") as f:
        f.write((json.dumps(summary, sort_keys=True, indent=2) + "\n").encode("ascii"))
    print("NATIVE_DIVERSE_59_FRESH_PROCESS_INDEPENDENT_REFERENCE_REPLAY_PASS")
    print("FULL_FUNCTIONAL_QA_PASS=NO; GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__ == "__main__":
    main()
