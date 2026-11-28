#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Befunge-98 Native separator-byte matrix at three structural field gaps.

Three boundaries x all 256 octets x raw EOF/final LF = 1536 Native calls.
Only ASCII TAB and SPACE are valid between tokens. All classification
is measured by the unchanged two-dimensional BF98 input program.
"""
from __future__ import print_function
import json,os,subprocess
PROGRAM="qa/year5000_raw_eof_candidate.b98"
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
ROOT="/native-separators"
BOUNDARIES=(("after_day_sign",0),("after_gate_count",4),
            ("before_rank",22))
ENDINGS=("raw_eof","final_lf")
CMD=["timeout","--kill-after=3s","15s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2",
     PROGRAM]
def original():
    fields=["0","100","0","0","9"]
    for i in range(9):fields.extend(["0",str(42*i)])
    return fields+["1"]
def native(payload):
    p=subprocess.Popen(CMD,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    out,err=p.communicate(payload)
    if p.returncode:
        raise AssertionError("Native boundary parser rc=%d, stderr=%r"%
                             (p.returncode,err[-450:]))
    try:answer=list(map(int,out.split()))
    except ValueError:raise AssertionError("Noninteger Native result "+repr(out))
    if answer not in ([1],[-1]):
        raise AssertionError("BF98 returned invalid boundary decision "+repr(answer))
    return answer
def main():
    if not os.path.isdir(ROOT):
        raise AssertionError("Native evidence mount not found")
    fields=original()
    if len(fields)!=24:raise AssertionError("24 token source cardinality drift")
    baseline=" ".join(fields)
    if native(baseline)!=[1] or native(baseline+"\n")!=[1]:
        raise AssertionError("BF98 original legal input rejected")
    rows=[]
    for label,position in BOUNDARIES:
        for octet in range(256):
            stream=" ".join(fields[:position+1])+chr(octet)+" ".join(fields[position+1:])
            for ending in ENDINGS:
                raw=stream+("\n" if ending=="final_lf" else "")
                want=[1] if octet in (9,32) else [-1]
                got=native(raw)
                if got!=want:
                    raise AssertionError("Native separator gap=%s byte=%d ending=%s observed=%r expected=%r"%
                                         (label,octet,ending,got,want))
                rows.append({"boundary":label,"index":position,
                             "octet":octet,"ending":ending,
                             "raw_hex":raw.encode("hex"),
                             "expected":want,"native_output":got,"native_exit":0})
            print("NATIVE_YEAR5000_SEPARATOR_BYTE_PASS",label,octet)
    if len(rows)!=1536:raise AssertionError("Native separator matrix incomplete")
    report={"schema":"befunge-stage1-native-separator-octets-1536-v1",
            "source_git_blob":PIN,
            "scope":"THREE_TOKEN_GAPS_NATIVE_BINARY_TEST_ONLY_STAGE1_OPEN",
            "last_completed_stage":0,
            "functional_acceptance":False,"geometric_acceptance":False,
            "production_modified":False,
            "case_count":len(rows),"records":rows}
    with open(ROOT+"/native_separator_octets.json","wb") as f:
        f.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_YEAR5000_SEPARATOR_1536_CASES_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
