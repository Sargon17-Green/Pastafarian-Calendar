#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native-only raw ASCII lexeme guard, then unchanged BF98 Year5000 reference.

This is a **test-only character-class preflight**, not a completed grammar
or a production parser. No Python signed-integer or calendar fallback.
Native '~' sees the original raw stream *before* PyFunge '&' loses '-'.
"""
from __future__ import print_function
import json,os,subprocess

GUARD="qa/year5000_raw_lexeme_guard.b98"
REF="reference/year5000_from_gates_rank.b98"
REF_SHA="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
CMD=("pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2")
ROOT="/raw-lexeme-guard"
RECORDS=[]
def native(program,raw):
    p=subprocess.Popen(["timeout","--kill-after=3s","35s"]+list(CMD)+[program],
                       stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    output,errors=p.communicate(raw+"\n")
    if p.returncode:raise AssertionError("Native %s exit %s stderr %r"%
                                         (program,p.returncode,errors[-400:]))
    try:return [int(v) for v in output.split()]
    except ValueError:raise AssertionError("noninteger Native output "+repr(output))
def vector(origin_sign="0",origin_magnitude="0",rank="1"):
    tokens=["0","100",origin_sign,origin_magnitude,"9"]
    for i in range(9):
        tokens.extend(["0",str(42*i)])
    tokens.append(rank)
    return tokens
def one(label,raw,want_guard,want_reference=None):
    guarded=native(GUARD,raw)
    if guarded!=[want_guard]:
        raise AssertionError("Native raw gate %s: got %r expected %r"%
                             (label,guarded,[want_guard]))
    output=None
    if want_guard==1:
        output=native(REF,raw)
        if output!=want_reference:
            raise AssertionError("Native Year5000 mismatch %s %r != %r"%
                                 (label,output,want_reference))
    RECORDS.append({"case":label,"raw":raw,"guard_output":guarded,
                    "reference_output":output,"expected_guard":want_guard,
                    "expected_reference":want_reference,"exit_code":0})
    print("NATIVE_YEAR5000_RAW_LEXEME_GUARD_PASS",label)
def main():
    if not os.path.isdir(ROOT):raise AssertionError("missing evidence mount")
    # DIAGNOSTIC-ONLY copy: print the actual failing ASCII byte rather than
    # the -1 sentinel. Replacing equal-length cells preserves all BF98 jumps.
    raw_source=open(GUARD,"rb").read()
    assert raw_source.count("$01-.@")==1
    debug_path=ROOT+"/native_ascii_rejection_probe.b98"
    with open(debug_path,"wb") as stream:
        stream.write(raw_source.replace("$01-.@",".@...."))
    for example in ("0","0 100","0 100 0 0 9",
                    "0 100 0 0 9 0 0","-1","0 +1"):
        print("NATIVE_RAW_ASCII_REJECTION_PROBE",repr(example),
              native(debug_path,example))
    base=vector()
    answer=[0,5000,0,6,0,252]
    one("base"," ".join(base),1,answer)
    one("spacing","  "+"  \t".join(base)+"   ",1,answer)
    one("negative_origin"," ".join(vector("1","7")),1,
        [0,5000,-7,-1,0,252])
    one("rank3"," ".join(vector(rank="3")),1,
        [0,5000,2,8,84,336])
    for i,old in enumerate(base):
        mutated=list(base)
        mutated[i]="-"+old
        one("negative_slot_%02d"%i," ".join(mutated),-1)
    for i in (0,2,4,5,14,23):
        mutated=list(base);mutated[i]="+"+mutated[i]
        one("plus_slot_%02d"%i," ".join(mutated),-1)
    for name,i,value in (
        ("word",4,"five"),("decimal",1,"10.0"),("comma",3,"1,0"),
        ("hex",7,"0x2"),("double_negative",2,"--1"),
        ("minus_magnitude",3,"-3"),("plus_magnitude",3,"+3"),
        ("slash",23,"1/"),("carriage_return",0,"0\r"),
    ):
        mutated=list(base);mutated[i]=value
        one("invalid_"+name," ".join(mutated),-1)
    raw=list(base);raw[2]="-1";raw[3]="3"
    payload=" ".join(raw)
    one("negative_sign_bypass",payload,-1)
    # Hostile control: unchanged test-only '&' reference is demonstrably
    # unsafe when called without the Native '~' preflight.
    bypass=native(REF,payload)
    if bypass!=[0,5000,-3,3,0,252]:
        raise AssertionError("expected independent negative bypass changed "+repr(bypass))
    if len(RECORDS)!=44:
        raise AssertionError("Native corpus cardinality "+str(len(RECORDS)))
    report={"schema":"befunge-stage1-native-year5000-raw-lexeme-preflight-v1",
            "reference_git_blob":REF_SHA,"scope":"CHARACTER_CLASS_ONLY_NOT_FULL_GRAMMAR_STAGE1_OPEN",
            "native_preflight_records":len(RECORDS),
            "functional_acceptance":False,"geometric_acceptance":False,
            "last_completed_stage":0,
            "unguarded_reference_bypass":{"case":"negative_sign_bypass",
                                          "raw":payload,
                                          "unguarded_native_output":bypass,
                                          "guarded_native_output":[-1]},
            "records":RECORDS}
    with open(ROOT+"/native_year5000_raw_lexeme.json","wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_YEAR5000_RAW_LEXEME_44_AND_UNGUARDED_BYPASS_PASS_STAGE1_OPEN")
if __name__=="__main__":main()
