#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fail-closed selftests for the NATIVE TRACE VERIFIER, not calendar results.

These small traces are synthetic and do not establish native Befunge-98 QA.
They only prove that the trace verifier accepts well-paired events and
rejects corrupt g/p observations or illegal scanner source ownership.
"""
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
import stage1_native_write_audit as auditor

def good_trace(gates=10):
    rows = []
    tick = 0
    vectors = [(1,0),(-1,0),(0,1),(0,-1)]
    def instruction(x,y,opcode):
        nonlocal tick
        tick += 1
        dx,dy = vectors[tick % 4]
        rows.append("STEP\t%d\t0\t%d\t%d\t%d\t%d\t%d\t0" %
                    (tick,x,y,dx,dy,opcode))
        return tick
    instruction(5,0,ord("x"))  # arithmetic handoff
    for j in range(gates):
        t=instruction(100+j,500,ord("p"))
        rows.append("WRITE_BEFORE\t%d\t%d\t1500\t32\t49" % (t,500+j))
        rows.append("WRITE_AFTER\t%d\t%d\t1500\t49" % (t,500+j))
        instruction(500+j,1500,49)  # previously blank gate, now '1'
    t=instruction(200,500,ord("g"))
    rows.append("READ_BEFORE\t%d\t600\t1500\t32" % t)
    rows.append("READ_AFTER\t%d\t600\t1500\t32" % t)
    instruction(201,500,ord("@"))
    return "\n".join(rows)+"\n"

def analyze(src,gate_count=10):
    with tempfile.NamedTemporaryFile(mode="w",suffix=".tsv",
                                      encoding="utf-8",delete=False) as stream:
        stream.write(src)
        path = stream.name
    try:
        return auditor.inspect_trace(path, gate_count)
    finally:
        os.unlink(path)

def should_reject(label, src):
    try:
        analyze(src)
    except AssertionError as e:
        print("SELFTEST_EXPECTED_REJECTION",label,str(e)[:120])
        return
    raise AssertionError("AUDIT FALSE ACCEPT: "+label)

good = good_trace()
result = analyze(good)
assert result["changed_writes_executed_later"] == 10
assert result["p_writes"] == 10
assert result["g_reads"] == 1
assert result["scanner_owned_cells_protected"] >= 3713
print("SELFTEST_POSITIVE_NATIVE_TRACE_FORMAT_PASS")

# Genuine Funge-98 self-modifying gate loops frequently write the same
# executable byte repeatedly before changing its value. Distinguish
# *executed gate writes* from *content-changing executed gate writes*.
def repeated_gate_trace():
    lines=["STEP\t1\t0\t5\t0\t1\t0\t120\t0"]
    tick=1
    previous=32
    for j in range(10):
        tick+=1
        proposed=118 if j<8 else (62 if j==8 else 118)
        target_y=1500 if j<9 else 1501
        old=previous if j<9 else 32
        lines.append("STEP\t%d\t0\t100\t500\t0\t1\t112\t3" % tick)
        lines.append("WRITE_BEFORE\t%d\t500\t%d\t%d\t%d" %
                     (tick,target_y,old,proposed))
        lines.append("WRITE_AFTER\t%d\t500\t%d\t%d" %
                     (tick,target_y,proposed))
        tick+=1
        lines.append("STEP\t%d\t0\t500\t%d\t1\t0\t%d\t0" %
                     (tick,target_y,proposed))
        if j<9:
            previous=proposed
    tick+=1
    lines.append("STEP\t%d\t0\t200\t500\t0\t-1\t103\t2" % tick)
    lines.append("READ_BEFORE\t%d\t600\t1500\t32" % tick)
    lines.append("READ_AFTER\t%d\t600\t1500\t32" % tick)
    tick+=1
    lines.append("STEP\t%d\t0\t201\t500\t-1\t0\t64\t0" % tick)
    return "\n".join(lines)+"\n"

repeat_result=analyze(repeated_gate_trace())
assert repeat_result["gate_writes_executed_later"]==10
assert repeat_result["content_changing_gate_writes_executed_later"]==3
print("SELFTEST_REPEATED_NATIVE_GATE_WRITES_PASS",
      "executed=10","changed=3")



should_reject("wrong-p-write-after",
    good.replace("WRITE_AFTER\t2\t500\t1500\t49",
                 "WRITE_AFTER\t2\t500\t1500\t50",1))
should_reject("wrong-g-result",
    good.replace("READ_AFTER\t", "READ_AFTER\t",1).replace(
        "\t600\t1500\t32\nSTEP", "\t600\t1500\t33\nSTEP",1))
should_reject("missing-g-after",
    "\n".join(x for x in good.split("\n") if not x.startswith("READ_AFTER"))+"\n")
should_reject("missing-p-after",
    "\n".join(x for x in good.split("\n")
              if not x.startswith("WRITE_AFTER\t2\t"))+"\n")
should_reject("scanner-ip-collision",
    good.replace("STEP\t3\t0\t500\t1500\t",
                 "STEP\t3\t0\t10\t49\t",1))
should_reject("scanner-g-collision",
    good.replace("READ_BEFORE\t", "READ_BEFORE\t",1).replace(
        "\t600\t1500\t32\nREAD_AFTER", "\t10\t49\t32\nREAD_AFTER",1))
should_reject("scanner-p-collision",
    good.replace("WRITE_BEFORE\t2\t500\t1500\t",
                 "WRITE_BEFORE\t2\t10\t49\t",1))
print("STAGE1_NATIVE_TRACE_AUDITOR_SELFTEST_PASS",7,"negative corruptions")
print("TEST_ONLY_SYNTHETIC_TRACE: not a native interpreter result")
