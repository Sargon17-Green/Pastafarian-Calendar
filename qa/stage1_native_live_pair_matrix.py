#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only: alternating TWO simultaneously live PyFunge-98 Program objects.

24 real program pairs (12 case pairs x two step orders); all numerical
expected values are computed only by independent native Befunge programs.
Never substitutes Python arithmetic for the calendar. Finite Stage-1 test.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPStopped, IPQuitted

SOURCE = "src/interleaved_work_counts.b98"
PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT = "/pairs/native_live_pair_matrix.json"
CLI = ["timeout", "--kill-after=3s", "45s", "pyfunge",
       "--disable-fprint", "--no-concurrent", "--no-filesystem", "-v98", "-d2"]
VALID = [
    "0 0 0 0", "1 15055672 1 15055670",
    "0 123456789 1 987654321", "1 987654321 0 123456789",
    "0 10 0 20", "0 1 0 2"
]
INVALID = [
    "1 0 0 0", "0 0 1 0", "2 10 0 10",
    "0 -1 0 1", "0 1 0 x", "0 1 0 1 7"
]
PAIRS = [
    ("v0", "v1"), ("v2", "v3"), ("v4", "v5"),
    ("v0", "i0"), ("v2", "i3"), ("v4", "i4"),
    ("i1", "v1"), ("i2", "v3"), ("i5", "v5"),
    ("i0", "i3"), ("i1", "i4"), ("i2", "i5")
]
SCHEDULES = ("AB", "BA")
GUARDS = [(0, 0), (5, 0), (10, 49), (100, 500), (500, 1500),
          (1528, 2014), (1475, 101), (1476, 101),
          (1490, 1600), (43, 1702), (47, 1703), (53, 1704), (61, 1706)]
BUDGET = 250000

def need(cond, msg):
    if not cond:
        raise AssertionError(msg)

def native_cli(path, raw):
    proc = subprocess.Popen(CLI + [path], stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate(raw)
    need(proc.returncode == 0, "native Befunge reference error %s: %r" %
         (path, err[-400:]))
    return out.split()

def reference(label):
    if label[0] == "i":
        return ["-1"] * 7
    fields = VALID[int(label[1:])].split()
    raw = " ".join(fields) + "\n"
    return (native_cli("reference/work_counts.b98", raw) +
            native_cli("reference/save.b98", fields[0] + " " + fields[1] + "\n") +
            native_cli("reference/save.b98", fields[2] + " " + fields[3] + "\n"))

def raw_for(label):
    return (VALID if label[0] == "v" else INVALID)[int(label[1:])] + "\n"

def make(source, label):
    stdin = StringIO.StringIO(raw_for(label))
    stdout = StringIO.StringIO()
    platform = BufferedPlatform([], {}, stdin=stdin, stdout=stdout)
    program = Program(Befunge98, platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips) == 1, "native fresh program missing original IP")
    return {"program": program, "stdin": stdin, "stdout": stdout,
            "point": program.ips[0].position.__class__, "steps": 0,
            "label": label}

def state(item):
    p = item["program"]
    ips = tuple((tuple(ip.position), tuple(ip.delta), tuple(ip.offset),
                 bool(ip.stringmode),
                 tuple(tuple(str(v) for v in frame) for frame in ip.stack))
                for ip in p.ips)
    coords = tuple(int(p.space.get(item["point"](xy))) for xy in GUARDS)
    return (ips, coords, tuple(p.space.boundmin), tuple(p.space.boundmax),
            item["stdin"].tell(), item["stdout"].tell())

def tick(item):
    p = item["program"]
    if not p.ips:
        return
    need(len(p.ips) == 1, "unexpected Native concurrency in source program")
    ip = p.ips[0]
    try:
        p.execute_step()
    except IPStopped:
        p.remove_ip(ip)
    except IPQuitted:
        for current in list(p.ips):
            p.remove_ip(current)
    item["steps"] += 1
    need(item["steps"] <= BUDGET, "Native Program exceeded bounded step budget")

def pair(source, left, right, schedule, expected):
    a, b = make(source, left), make(source, right)
    need(a["program"] is not b["program"] and
         a["program"].space is not b["program"].space and
         a["program"].semantics is not b["program"].semantics and
         a["stdin"] is not b["stdin"] and a["stdout"] is not b["stdout"],
         "native independent objects share execution state")
    overlap = checks = rounds = 0
    order = (a, b) if schedule == "AB" else (b, a)
    while a["program"].ips or b["program"].ips:
        rounds += 1
        if a["program"].ips and b["program"].ips:
            overlap += 1
        for current, other in ((order[0], order[1]), (order[1], order[0])):
            if not current["program"].ips:
                continue
            witness = rounds <= 8 or rounds % 211 == 0
            before = state(other) if witness else None
            tick(current)
            if witness:
                need(state(other) == before,
                     "one Native Program step mutated another live Program")
                checks += 1
        need(rounds <= BUDGET, "native pair scheduling exceeded budget")
    got_a = a["stdout"].getvalue().split()
    got_b = b["stdout"].getvalue().split()
    need(overlap > 0 and checks >= 16,
         "native pair insufficiently interleaved or insufficient snapshots")
    need(got_a == expected[left] and got_b == expected[right],
         "live pair Native outputs differ from independent Befunge references")
    return {"left": left, "right": right, "schedule": schedule,
            "left_output": got_a, "right_output": got_b,
            "left_steps": a["steps"], "right_steps": b["steps"],
            "overlap_rounds": overlap, "cross_program_checks": checks,
            "terminated": True, "private_programs": True,
            "private_spaces": True, "private_semantics": True,
            "private_io": True, "cross_program_state_unchanged": True}

def main():
    need(os.path.isdir("/pairs"), "Native live-pair evidence directory missing")
    source = open(SOURCE, "rb").read()
    got = hashlib.sha1("blob %d\0%s" % (len(source), source)).hexdigest()
    need(got == PIN, "source Git blob not pinned to QA production")
    expected = {}
    for i in range(6):
        label = "v%d" % i
        expected[label] = reference(label)
        need(len(expected[label]) == 7, "native valid oracle incomplete")
        expected["i%d" % i] = ["-1"] * 7
    results = []
    for schedule in SCHEDULES:
        for l, r in PAIRS:
            info = pair(source, l, r, schedule, expected)
            results.append(info)
            print("NATIVE_LIVE_PAIR_PASS", schedule, l, r,
                  "steps", info["left_steps"], info["right_steps"],
                  "cross_program_checks", info["cross_program_checks"])
            sys.stdout.flush()
    need(len(results) == 24, "native live-pair matrix incomplete")
    report = {"schema": "befunge-stage1-live-pair-matrix-v1",
              "source_git_blob": PIN, "status": "QA_ONLY_STAGE1_OPEN",
              "interpreter": "PyFunge-0.5-rc2", "native_pair_runs": 24,
              "native_program_executions": 48,
              "independent_native_oracle_calls": 18,
              "stage1_final_acceptance": False,
              "expected_by_label": expected, "records": results}
    with open(OUT, "wb") as fh:
        fh.write(json.dumps(report, sort_keys=True, indent=2) + "\n")
    print("NATIVE_LIVE_PAIR_MATRIX_24_REAL_PAIRS_PASS")
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")

if __name__ == "__main__":
    main()
