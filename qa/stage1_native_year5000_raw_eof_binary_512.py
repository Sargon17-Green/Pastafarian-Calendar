#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 512-case binary EOF/LF transport differential.

256 post-LF bytes must be rejected. 256 raw-EOF bytes in an extra field
must be rejected unless they are one of three whitespace delimiters:
HT, LF, SPACE.  Python marshals binary bytes and records Native outputs;
ALL classifications are from pinned Befunge-98 executable.
"""
from __future__ import print_function
import json,os,subprocess
PROGRAM="qa/year5000_raw_eof_candidate.b98"
UNGUARDED="qa/year5000_exact_line_grammar.b98"
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
ROOT="/year5000-raw-binary"
CONTROL=(0,10,13,32,65,127,128,255)
CMD=["timeout","--kill-after=3s","12s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
def base():
    tokens=["0","100","0","0","9"]
    for i in range(9):tokens+=["0",str(i*42)]
    return " ".join(tokens+["1"])
def invoke(program,data):
    p=subprocess.Popen(CMD+[program],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    output,error=p.communicate(data)
    if p.returncode:
        raise AssertionError("Native binary rc %d src=%s suffix=%r stderr=%r"%
                             (p.returncode,program,data[-5:],error[-350:]))
    try:result=list(map(int,output.split()))
    except ValueError:raise AssertionError("Noninteger Native answer "+repr(output))
    if result not in ([1],[-1]):
        raise AssertionError("Unexpected BF98 output "+repr(result))
    return result
def main():
    if not os.path.isdir(ROOT):raise AssertionError("Native evidence mount missing")
    stem=base()
    if invoke(PROGRAM,stem)!=[1] or invoke(PROGRAM,stem+"\n")!=[1]:
        raise AssertionError("Valid native raw EOF or LF stream rejected")
    rows=[]
    for octet in range(256):
        suffix=chr(octet)
        for kind in ("after_lf","extra_raw_field"):
            raw=(stem+"\n"+suffix if kind=="after_lf" else stem+" "+suffix)
            want=([1] if kind=="extra_raw_field" and octet in (9,10,32)
                  else [-1])
            got=invoke(PROGRAM,raw)
            if got!=want:
                raise AssertionError("Native BF98 %s byte=%d got=%r want=%r"%
                                     (kind,octet,got,want))
            row={"octet":octet,"variant":kind,"raw_hex":raw.encode("hex"),
                 "native_output":got,"expected":want,"native_return_code":0}
            if kind=="after_lf" and octet in CONTROL:
                old=invoke(UNGUARDED,raw)
                if old!=[1]:
                    raise AssertionError("Expected native unguarded bypass absent %d"%octet)
                row["unguarded_native_output"]=old
            rows.append(row)
        print("NATIVE_YEAR5000_RAW_EOF_BINARY_PAIR_PASS",octet)
    if len(rows)!=512:raise AssertionError("incomplete Native binary corpus")
    report={"schema":"befunge-stage1-raw-eof-binary-512-v1",
            "source_git_blob":PIN,
            "scope":"TEST_ONLY_BINARY_FIRST_SUFFIX_NOT_PRODUCTION_STAGE1_OPEN",
            "native_case_count":len(rows),"last_completed_stage":0,
            "stage1_complete":False,"full_functional_acceptance":False,
            "geometric_acceptance":False,"records":rows}
    with open(ROOT+"/native_year5000_512_raw_binary.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_RAW_EOF_BINARY_512_CASES_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
