#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 QA: real PyFunge-98 two-live-Program variable-quantum scheduling.

No calendar arithmetic in Python. Only the pinned original Native Befunge
source executes, compared with independent test-only Native Befunge oracles.
Quantums (2/3, 1/5, 97/61) expose schedule dependence beyond AB/BA one-step
interleaving. This is a bounded experiment, not final Stage-1 acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_live_pair_matrix as base

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT = "/quantum/native_quantum_pair_matrix.json"
PROFILES = (
    ("A2_B3", 2, 3, "AB"),
    ("B5_A1", 1, 5, "BA"),
    ("A97_B61", 97, 61, "AB"),
)
PAIRS = tuple(base.PAIRS)
MAX_ROUNDS = 250000

def need(cond, reason):
    if not cond:
        raise AssertionError(reason)

def replay_pair(source, left, right, profile, expected):
    name, qa, qb, first = profile
    a, b = base.make(source, left), base.make(source, right)
    need(a["program"] is not b["program"] and
         a["program"].space is not b["program"].space and
         a["program"].semantics is not b["program"].semantics and
         a["stdin"] is not b["stdin"] and a["stdout"] is not b["stdout"],
         "Native live pair did not have private program/space/IO")
    cls = type(a["program"].space)
    need(cls is type(b["program"].space), "Native Funge-space class changed")
    old_get, old_put, old_putspace = cls.get, cls.put, cls.putspace
    active = [None]
    counts = {
        left: {"get": 0, "put": 0, "putspace": 0, "direct_p": 0},
        right: {"get": 0, "put": 0, "putspace": 0, "direct_p": 0},
    }
    def watch_get(self, *args, **kwargs):
        current = active[0]
        if current is not None:
            need(self is current["program"].space,
                 "cross-Program Funge-space.get during native quantum")
            counts[current["label"]]["get"] += 1
        return old_get(self, *args, **kwargs)
    def watch_put(self, *args, **kwargs):
        current = active[0]
        need(current is not None and self is current["program"].space and
             len(args) >= 2, "cross-Program or unattributed native space.put")
        result = old_put(self, *args, **kwargs)
        need(int(old_get(self, args[0])) == int(args[1]),
             "Native space.put did not persist its value")
        counts[current["label"]]["put"] += 1
        return result
    def watch_putspace(self, *args, **kwargs):
        current = active[0]
        need(current is not None and self is current["program"].space,
             "cross-Program or unattributed native space.putspace")
        counts[current["label"]]["putspace"] += 1
        return old_putspace(self, *args, **kwargs)
    order = ((a, qa), (b, qb)) if first == "AB" else ((b, qb), (a, qa))
    rounds = 0
    overlap = 0
    untouched_checks = 0
    first_finished = None
    try:
        cls.get, cls.put, cls.putspace = watch_get, watch_put, watch_putspace
        while a["program"].ips or b["program"].ips:
            rounds += 1
            need(rounds <= MAX_ROUNDS, "quantum scheduling exceeded bound")
            if a["program"].ips and b["program"].ips:
                overlap += 1
            for current, quantum in order:
                other = b if current is a else a
                if not current["program"].ips:
                    continue
                snapshot = base.state(other)
                for step in range(quantum):
                    if not current["program"].ips:
                        break
                    p = current["program"]
                    ip = p.ips[0]
                    op = int(old_get(p.space, ip.position))
                    if op == ord("p") and not ip.stringmode:
                        counts[current["label"]]["direct_p"] += 1
                    active[0] = current
                    try:
                        base.tick(current)
                    finally:
                        active[0] = None
                    if not current["program"].ips and first_finished is None:
                        first_finished = current["label"]
                need(base.state(other) == snapshot,
                     "Native quantum changed peer IP/stack/space/IO snapshot")
                untouched_checks += 1
    finally:
        active[0] = None
        cls.get, cls.put, cls.putspace = old_get, old_put, old_putspace
    got_a, got_b = a["stdout"].getvalue().split(), b["stdout"].getvalue().split()
    need(got_a == expected[left] and got_b == expected[right],
         "variable-quantum native output differs from independent reference")
    need(overlap > 0 and untouched_checks >= 2 and first_finished is not None,
         "variable quantum did not overlap genuine native execution")
    for label in (left, right):
        c = counts[label]
        need(c["get"] > 0 and c["put"] > 0 and c["putspace"] == 0 and
             c["put"] == c["direct_p"],
             "native memory API access/write counts inconsistent")
    return {
        "profile": name, "left": left, "right": right,
        "left_output": got_a, "right_output": got_b,
        "left_steps": a["steps"], "right_steps": b["steps"],
        "left_get": counts[left]["get"], "right_get": counts[right]["get"],
        "left_put": counts[left]["put"], "right_put": counts[right]["put"],
        "left_direct_p": counts[left]["direct_p"],
        "right_direct_p": counts[right]["direct_p"],
        "left_putspace": counts[left]["putspace"],
        "right_putspace": counts[right]["putspace"],
        "overlap_rounds": overlap,
        "peer_snapshot_checks": untouched_checks,
        "first_finished": first_finished,
        "output_matches_reference": True,
        "space_access_owned_by_active_program": True,
        "peer_state_unchanged_after_every_quantum": True,
        "terminated": True,
    }

def main():
    need(os.path.isdir("/quantum"), "native quantum artifact folder absent")
    source = open(base.SOURCE, "rb").read()
    pin = hashlib.sha1("blob %d\0%s" % (len(source), source)).hexdigest()
    need(pin == PIN == base.PIN, "production source Git blob changed")
    expected = {}
    for i in range(6):
        label = "v%d" % i
        expected[label] = base.reference(label)
        need(len(expected[label]) == 7,
             "independent Native Befunge seven-field oracle incomplete")
        expected["i%d" % i] = ["-1"] * 7
    records = []
    per_label = {}
    for profile in PROFILES:
        for left, right in PAIRS:
            row = replay_pair(source, left, right, profile, expected)
            for label, side in ((left, "left"), (right, "right")):
                metrics = (row[side + "_steps"], row[side + "_get"],
                           row[side + "_put"])
                if label in per_label:
                    need(per_label[label] == metrics,
                         "native input result depends on peer/quantum/order")
                else:
                    per_label[label] = metrics
            records.append(row)
            print("NATIVE_QUANTUM_PAIR_PASS", profile[0], left, right,
                  row["left_steps"], row["right_steps"],
                  "snapshot_checks", row["peer_snapshot_checks"])
            sys.stdout.flush()
    need(len(records) == 36 and len(per_label) == 12,
         "36 real native pair routes or 12 distinct labels missing")
    report = {
        "schema": "befunge-stage1-variable-quantum-pair-v1",
        "source_git_blob": PIN, "status": "QA_ONLY_STAGE1_OPEN",
        "native_pairs": len(records),
        "native_program_executions": len(records) * 2,
        "independent_native_oracle_invocations": 18,
        "variable_schedules": [{"id":p[0], "left_quantum":p[1],
                                "right_quantum":p[2], "first":p[3]}
                               for p in PROFILES],
        "expected_by_label": expected,
        "final_stage1_acceptance": False,
        "records": records,
    }
    with open(OUT, "wb") as fh:
        fh.write(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("NATIVE_VARIABLE_QUANTUM_36_PAIR_MATRIX_PASS")
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")

if __name__ == "__main__":
    main()
