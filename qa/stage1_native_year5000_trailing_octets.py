#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Exhaustive native BF98 LF-trailing octet rejection, 0..255 inclusive.

Every decision is made by the original immutable BF98 integrated parser.
Python constructs binary input, checks observed BF98 output and stores
evidence.  Test-only QA: does not qualify no-LF or production integration.
"""
from __future__ import print_function
import json,os,subprocess
SOURCE="qa/year5000_integrated_lf_eof_grammar.b98"
BASELINE="qa/year5000_exact_line_grammar.b98"
PIN="fb6513605febc92c4cd1b453295253cb1cb49740"
ROOT="/year5000-octets"
CMD=["timeout","--kill-after=3s","20s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
CONTROL=(0,10,13,32,65,127,128,255)
def valid_lf():
    fields=["0","100","0","0","9"]
    for i in range(9):fields+=["0",str(i*42)]
    fields+=["1"]
    return " ".join(fields)+"\n"
def invoke(program,data):
    p=subprocess.Popen(CMD+[program],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    output,error=p.communicate(data)
    if p.returncode:
        raise AssertionError("Native BF98 octet rc=%d %s stderr=%r"%
                             (p.returncode,program,error[-500:]))
    try:result=list(map(int,output.split()))
    except ValueError:raise AssertionError("Noninteger native output "+repr(output))
    if result not in ([-1],[1]):
        raise AssertionError("Unexpected BF98 octet response "+repr(result))
    return result
def main():
    if not os.path.isdir(ROOT):raise AssertionError("missing evidence mount")
    prefix=valid_lf()
    baseline=invoke(SOURCE,prefix)
    if baseline!=[1]:raise AssertionError("Valid LF input unexpectedly rejected")
    records=[]
    unguarded=[]
    for octet in range(256):
        binary=prefix+chr(octet)
        result=invoke(SOURCE,binary)
        if result!=[-1]:
            raise AssertionError("Native BF98 accepted trailing octet %d: %r"%
                                 (octet,result))
        row={"octet":octet,"raw_hex":binary.encode("hex"),
             "native_output":result,"native_return_code":0}
        if octet in CONTROL:
            historical=invoke(BASELINE,binary)
            if historical!=[1]:
                raise AssertionError("Unguarded native control changed for %d"%
                                     octet)
            row["unguarded_native_output"]=historical
            unguarded.append(octet)
        records.append(row)
        print("NATIVE_YEAR5000_TRAILING_OCTET_REJECT_PASS",octet)
    report={"schema":"befunge-stage1-all-trailing-octets-native-v1",
            "integrated_source_git_blob":PIN,
            "scope":"LF_TERMINATED_BINARY_SUFFIX_ONLY_NOT_NO_LF_STAGE1_OPEN",
            "baseline_valid_native_output":baseline,
            "octet_count":len(records),"historical_controls":unguarded,
            "full_production_acceptance":False,
            "no_lf_input_certified":False,"last_completed_stage":0,
            "records":records}
    with open(ROOT+"/native_all_256_trailing_octets.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_ALL_256_TRAILING_OCTETS_REJECT_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
