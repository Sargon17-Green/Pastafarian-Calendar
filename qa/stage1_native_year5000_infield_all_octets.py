#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 in-field binary lexical classifier: 3 roles x 256 x 2 LF modes.

No Python parsing or numeric oracle.  The same immutable test-only
Befunge-98 2D scanner classifies all 1536 raw byte strings.
The role contract is narrow: origin sign (zero magnitude), origin magnitude
(zero sign), and final rank.  Stage1 acceptance remains OPEN.
"""
from __future__ import print_function
import json,os,subprocess
PIN="c5bd9dd06e227f9f31c8988a51bd114bf67b9af7"
PROGRAM="qa/year5000_raw_eof_candidate.b98"
ROOT="/native-infield"
ROLES=(("zero_magnitude_sign",2),("unsigned_origin_magnitude",3),("rank_token",23))
CMD=["timeout","--kill-after=3s","15s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2",PROGRAM]
def original():
    fields=["0","100","0","0","9"]
    for gate in range(9):
        fields.extend(["0",str(gate*42)])
    return fields+["1"]
def accepted(role,value):
    if role=="zero_magnitude_sign":return value==48
    if role=="unsigned_origin_magnitude":return 48<=value<=57
    if role=="rank_token":return 49<=value<=57
    raise AssertionError("unsupported native role")
def native(raw):
    proc=subprocess.Popen(CMD,stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    output,error=proc.communicate(raw)
    if proc.returncode:
        raise AssertionError("Native role scan rc=%d input=%r stderr=%r"%
                             (proc.returncode,raw[-50:],error[-350:]))
    try:values=list(map(int,output.split()))
    except ValueError:raise AssertionError("Noninteger BF98 output "+repr(output))
    if values not in ([1],[-1]):
        raise AssertionError("Unexpected native token classification "+repr(values))
    return values
def main():
    if not os.path.isdir(ROOT):raise AssertionError("evidence mount missing")
    fields=original()
    if len(fields)!=24 or native(" ".join(fields))!=[1] or native(" ".join(fields)+"\n")!=[1]:
        raise AssertionError("Native baseline input changed")
    rows=[]
    for label,index in ROLES:
        for octet in range(256):
            mutated=list(fields)
            mutated[index]=chr(octet)
            for ending in ("raw_eof","final_lf"):
                raw=" ".join(mutated)+("\n" if ending=="final_lf" else "")
                want=[1] if accepted(label,octet) else [-1]
                result=native(raw)
                if result!=want:
                    raise AssertionError("Native %s octet=%d ending=%s got=%r expected=%r"%
                                         (label,octet,ending,result,want))
                rows.append({"role":label,"field_index":index,"octet":octet,
                             "ending":ending,"raw_hex":raw.encode("hex"),
                             "expected":want,"native_output":result,"native_exit":0})
            print("NATIVE_INFIELD_256_BYTE_ROLE_PASS",label,octet)
    if len(rows)!=1536:raise AssertionError("Native in-field matrix incomplete")
    result={"schema":"befunge-stage1-native-infield-1536-v1",
            "source_git_blob":PIN,
            "scope":"THREE_TOKEN_ROLES_BINARY_INPUT_TEST_ONLY_STAGE1_OPEN",
            "test_only":True,"last_completed_stage":0,
            "full_functional_qa_pass":False,"geometric_qa_pass":False,
            "native_input_count":len(rows),
            "records":rows}
    with open(ROOT+"/native_infield_all_octets.json","wb") as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_INFIELD_1536_BINARY_CASES_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
