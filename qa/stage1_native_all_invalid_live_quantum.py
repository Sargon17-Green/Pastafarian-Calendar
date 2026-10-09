#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 finite Native QA: all 21 invalid forms in concurrent Program pairs.

Two previously untested quantum schedules; 21 invalid/valid and 11
invalid/invalid peer pairings each repeated in both schedules.
Only actual pinned PyFunge-98 executes arithmetic, no Python calendar code.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_live_pair_matrix as base
import stage1_native_variable_quantum_pairs as quantum
import stage1_native_invalid_memory_ownership as invalid

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT = "/allinvalid/native_full_invalid_live_quantum.json"
PROFILES = (
    ("A7_B11", 7, 11, "AB"),
    ("B5_A13", 13, 5, "BA"),
)

def require(ok, msg):
    if not ok:
        raise AssertionError(msg)

def corpus():
    # The single-Program rejected-input corpus is canonical for this QA
    # extension. Only this process changes imported harness case arrays.
    rejected = list(invalid.NUMERIC) + list(invalid.LEXICAL)
    require(len(rejected) == 21 and len(set(rejected)) == 21,
            "the 21 published invalid forms unexpectedly changed")
    base.INVALID = rejected
    require(len(base.VALID) == 6,
            "native valid peer fixture corpus unexpectedly changed")
    labels = ["i%d" % n for n in range(len(rejected))]
    pairs = [(labels[i], "v%d" % (i % 6)) for i in range(21)]
    pairs += [(labels[i], labels[20 - i]) for i in range(10)]
    pairs.append(("i0", "i12"))
    require(len(pairs) == 32 and len(set(pairs)) == 32,
            "Native invalid pair corpus missing/duplicating pair")
    require(set([a for a, b in pairs if a[0] == "i"]) == set(labels),
            "not all 21 rejected inputs exercised with a real native peer")
    return pairs, labels

def main():
    require(os.path.isdir("/allinvalid"),
            "Native full-invalid concurrent evidence mount missing")
    source = open(base.SOURCE, "rb").read()
    digest = hashlib.sha1("blob %d\0%s" % (len(source), source)).hexdigest()
    require(digest == PIN == base.PIN == quantum.PIN,
            "current QA production Befunge source has drifted")
    pairs, rejected_labels = corpus()
    expected = {}
    for i in range(6):
        label = "v%d" % i
        expected[label] = base.reference(label)
        require(len(expected[label]) == 7,
                "three independent Native Befunge oracle outputs incomplete")
    for label in rejected_labels:
        expected[label] = ["-1"] * 7
    require(len(expected) == 27,
            "real Native valid/invalid reference set incomplete")

    records = []
    signatures = {}
    observations = {}
    for profile in PROFILES:
        for left, right in pairs:
            row = quantum.replay_pair(source, left, right, profile, expected)
            for label, side in ((left, "left"), (right, "right")):
                sig = (row[side + "_steps"], row[side + "_get"],
                       row[side + "_put"], tuple(row[side + "_output"]))
                if label in signatures:
                    require(signatures[label] == sig,
                            "Native concurrent invalid case depended on peer/schedule")
                else:
                    signatures[label] = sig
                observations[label] = observations.get(label, 0) + 1
            records.append(row)
            print("NATIVE_ALL_INVALID_LIVE_PAIR_PASS",
                  profile[0], left, right,
                  "steps", row["left_steps"], row["right_steps"],
                  "peer_checks", row["peer_snapshot_checks"])
            sys.stdout.flush()
    require(len(records) == 64 and len(signatures) == 27 and
            all(observations.get(label, 0) >= 2 for label in rejected_labels),
            "native 21-invalid cross-peer/schedule matrix incomplete")

    report = {
        "schema": "befunge-stage1-full-invalid-concurrent-v1",
        "status": "QA_ONLY_STAGE1_OPEN",
        "source_git_blob": PIN,
        "invalid_forms": 21,
        "valid_reference_forms": 6,
        "native_real_pairs": 64,
        "native_program_executions": 128,
        "independent_native_oracle_invocations": 18,
        "profiles": [
            {"id": p[0], "left_quantum": p[1],
             "right_quantum": p[2], "first": p[3]} for p in PROFILES
        ],
        "input_by_label": dict(
            [("i%d" % i, value) for i, value in
             enumerate(list(invalid.NUMERIC) + list(invalid.LEXICAL))]
            + [("v%d" % i, value) for i, value in enumerate(base.VALID)]
        ),
        "expected_by_label": expected,
        "stage1_final_acceptance": False,
        "records": records,
    }
    with open(OUT, "wb") as stream:
        stream.write(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("NATIVE_ALL_21_INVALID_FORMS_CONCURRENT_64_PAIR_PASS",
          "real_programs", 128,
          "all_invalids_scheduled_at_least_twice", True)
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")

if __name__ == "__main__":
    main()
