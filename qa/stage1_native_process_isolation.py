#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Stage 1: native-only differential and cross-process isolation regression.
# Expected semantic outputs are computed exclusively by native Befunge-98 references.
from __future__ import print_function
import hashlib
import os
import random
import subprocess
import tempfile

CMD = ["pyfunge", "--disable-fprint", "--no-concurrent",
       "--no-filesystem", "-v98", "-d2"]
PRODUCTION = "src/interleaved_work_counts.b98"
N = 0

def native(path, tokens, limit="50s"):
    global N
    N += 1
    p = subprocess.Popen(
        ["timeout", "--kill-after=2s", limit] + CMD + [path],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = p.communicate(tokens + "\n")
    if p.returncode != 0:
        raise AssertionError("NATIVE_PROCESS_ERROR %s %s rc=%s stderr=%r stdout=%r"
                             % (path, tokens, p.returncode, error, output))
    return output.split()

def check(label, got, expected):
    if got != expected:
        raise AssertionError("%s: got=%r expected=%r" % (label, got, expected))

def source_digest():
    h = hashlib.sha256()
    with open(PRODUCTION, "rb") as f:
        while True:
            buf = f.read(1048576)
            if not buf:
                break
            h.update(buf)
    return h.hexdigest()

M = 2**127 - 1
valid = [
    (0, 0, 0, 0),
    (1, 15055671, 1, 15055671),
    (1, 15055672, 1, 15055670),
    (0, 123456789, 1, 987654321),
    (1, 987654321, 0, 123456789),
    (0, 0, 1, 15055671),
    (1, 15055671, 0, 0),
    (0, 1, 0, 2),
    (0, 2, 0, 1),
    (0, 10**50 + 987654321, 1, 10**51 + 123456789),
    (1, 10**77 + 987654321, 0, 10**78 + 123456789),
    (1, 1, 0, 1),
    (1, 2, 1, 3),
    (0, M, 1, M),
    (1, M, 0, M + 1),
    (0, M + 1, 0, M),
    (0, 2**126, 1, 2**127),
    (1, 10**40, 1, 10**39),
    (0, 2 * M, 1, 2 * M + 1),
]
invalid = [
    (1, 0, 0, 0), (0, 0, 1, 0),
    (2, 10, 0, 10), (0, 10, 2, 10),
    (1, 0, 1, 15055671), (3, 2, 0, 4),
]
cases = [" ".join(map(str, x)) for x in valid + invalid]
expected = {}
before = source_digest()
for c in valid:
    s1, m1, s2, m2 = c
    inp = " ".join(map(str, c))
    five = native("reference/work_counts.b98", inp)
    save1 = native("reference/save.b98", "%d %d" % (s1, m1))
    save2 = native("reference/save.b98", "%d %d" % (s2, m2))
    check("oracle-output-shape " + inp, len(five + save1 + save2), 7)
    expected[inp] = five + save1 + save2
for c in invalid:
    expected[" ".join(map(str, c))] = ["-1"] * 7

orders = [list(cases), list(reversed(cases))]
rng = random.Random(20261008)
shuffled = list(cases)
rng.shuffle(shuffled)
orders.append(shuffled)
orders.append(cases[::2] + cases[1::2])
for round_no, order in enumerate(orders):
    for inp in order:
        check("fresh-process-order-%d %s" % (round_no, inp),
              native(PRODUCTION, inp), expected[inp])
    print("PASS order", round_no, "cases", len(order))

# Two independent native instances execute at the same time with different input
# to detect shared external state or source mutation. This does NOT establish
# reentrancy of two runs inside one interpreter or in one Funge-space.
def parallel_pair(left, right):
    a = tempfile.TemporaryFile()
    b = tempfile.TemporaryFile()
    try:
        a.write(left + "\n")
        b.write(right + "\n")
        a.seek(0)
        b.seek(0)
        cmd = ["timeout", "--kill-after=2s", "50s"] + CMD + [PRODUCTION]
        p = subprocess.Popen(cmd, stdin=a, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        q = subprocess.Popen(cmd, stdin=b, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        po, pe = p.communicate()
        qo, qe = q.communicate()
        if p.returncode or q.returncode:
            raise AssertionError("PARALLEL_NATIVE_FAILED %r %r" %
                                 ((p.returncode, pe), (q.returncode, qe)))
        check("parallel-left " + left, po.split(), expected[left])
        check("parallel-right " + right, qo.split(), expected[right])
    finally:
        a.close()
        b.close()

parallel_pair(cases[10], cases[0])
parallel_pair(cases[-1], cases[13])
check("immutable-source-bytes", source_digest(), before)
print("PASS stage1_native_process_isolation")
print("valid", len(valid), "invalid", len(invalid),
      "orders", len(orders), "native_sequential_invocations", N,
      "native_parallel_invocations", 4)
print("IMPORTANT: in-process interpreter reuse/semantic Funge-space ownership remains UNPROVEN")
