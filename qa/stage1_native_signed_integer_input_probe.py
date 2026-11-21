#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge 98 integer-input sign lexeme diagnostic.

Execute an actual 1D embedded Befunge-98 '&.@' microprogram via the
same PyFunge 0.5-rc2 executable used for Stage-1 test-only references.
Measure whether tokens such as '-1' survive Native integer input '&'.
No claim about integer parser internals is made before observation.
Independent comparison with test-only Year5000 reference on exactly
one formerly failing -1 sign token provides a concrete counterexample.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys

OUT="/sign-probe"
REF="reference/year5000_from_gates_rank.b98"
REFERENCE_SHA="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
TOKENS=("-1","-2","-3","-7","0","1","2","3","7","-0","+1","+2")
COMMAND=("pyfunge","--disable-fprint","--no-concurrent","--no-filesystem",
         "-v98","-d2")
def need(ok,reason):
    if not ok:raise AssertionError(reason)
def blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()
def run(path,text):
    proc=subprocess.Popen(["timeout","--kill-after=2s","20s"]+
         list(COMMAND)+[path],stdin=subprocess.PIPE,
         stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=proc.communicate(text+"\n")
    need(proc.returncode==0,
         "PyFunge Native integer probe failed "+repr((text,proc.returncode,err[-500:])))
    return out.split()
def main():
    need(os.path.isdir(OUT),"no signed Native probe destination")
    ref=open(REF,"rb").read()
    need(blob(ref)==REFERENCE_SHA,"Year5000 test-only reference source changed")
    mini=OUT+"/native_integer_read_echo.b98"
    with open(mini,"wb") as f:f.write("&.@\n")
    records=[]
    for token in TOKENS:
        result=run(mini,token)
        need(len(result)==1 and
             result[0].lstrip("-").isdigit(),
             "Native Befunge did not echo exactly one numeric integer")
        records.append({"input_token":token,"native_echo":result[0],
                        "decimal_python_expected":str(int(token))})
        print("NATIVE_PYFUNGE_SIGNED_INTEGER_INPUT_MEASURED",
              repr(token),"native",result[0],"decimal_int",str(int(token)))
        sys.stdout.flush()
    # Replicate the exact contested reference input using the native executor.
    fields=[0,100,-1,3,7]
    for i in range(7):
        day=42*i
        fields.extend([int(day<0),abs(day)])
    fields.append(1)
    got=run(REF," ".join(map(str,fields)))
    need(len(got)==6 and all(z.lstrip("-").isdigit() for z in got),
         "Native Year5000 token-level diagnostic lacks six actual output fields")
    report={"schema":"befunge-stage1-pyfunge-integer-signed-lexeme-probe-v1",
            "scope":"NATIVE_PYFUNGE_INTEGER_INPUT_DIAGNOSTIC_ONLY_STAGE1_OPEN",
            "reference_git_blob":REFERENCE_SHA,
            "raw_probe_source":"&.@",
            "token_count":len(records),
            "tokens":records,
            "malformed_year5000_index_sign_raw":"-1",
            "malformed_year5000_index_sign_fields":fields,
            "malformed_year5000_native_output":got,
            "requires_lexical_validation_if_sign_is_lost":any(
                  row["input_token"]=="-1" and
                  row["native_echo"]!="-1" for row in records),
            "stage1_functional_pass":False,"stage1_geometry_pass":False}
    with open(OUT+"/native_pyfunge_signed_lexeme_probe.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_PYFUNGE_12_RAW_SIGNED_INT_TRANSPORT_MEASURED_PASS")
if __name__=="__main__":main()
