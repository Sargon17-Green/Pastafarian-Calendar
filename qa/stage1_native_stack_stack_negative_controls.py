#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Six hostile Native { 3u } event controls with re-signed trace SHA-256.

Only forge copies of RAW recorded PyFunge-98 traces. The independently
implemented arithmetic graph/memory/stack auditor must reject every one
even when the evidence manifest contains the newly computed digest.
No calendar algorithm, synthetic positive evidence or source promotion.
"""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile

import stage1_native_stack_stack_graph_audit as independent

FOCUS="zero_equal"
PIVOT=(954,1328)
BRACE=(954,1330)
CLOSE=(954,1322)
JUMP=(954,1318)

def require(ok,why):
    if not ok:raise AssertionError(why)

def modified_event(original,kind,point,column,newvalue):
    lines=original.decode("ascii").splitlines(True)
    matches=0
    for index,line in enumerate(lines):
        parts=line.rstrip("\n").split("\t")
        if parts[0]!=kind:
            continue
        if point is not None:
            require(kind=="STEP","coordinates only valid for Native STEP")
            if len(parts)!=9 or tuple(map(int,parts[3:5]))!=point:
                continue
        require(column<len(parts),"wrong Native trace mutation field")
        require(matches==0,"same target event unexpectedly repeated")
        before=parts[column]
        after=str(newvalue(before))
        require(before!=after,"Native tamper attempted to keep same field")
        parts[column]=after
        lines[index]="\t".join(parts)+"\n"
        matches+=1
        break
    require(matches==1,"Native trace did not contain target event")
    result="".join(lines).encode("ascii")
    require(result!=original,"Native trace tamper was not effective")
    return result

def independent_rejection(root,proof,label,raw,expected_reason):
    temp=tempfile.mkdtemp(prefix="befunge-ss-re-signed-native-")
    try:
        for entry in proof["seventeen_native_cases"]:
            filename=entry["case"]+".tsv"
            require(entry["trace_file"]==filename and
                    os.path.basename(filename)==filename,
                    "unsafe Native input case file")
            destination=os.path.join(temp,filename)
            if entry["case"]==FOCUS:
                with open(destination,"wb") as out:out.write(raw)
            else:
                os.symlink(os.path.abspath(os.path.join(root,filename)),
                           destination)
        os.symlink(os.path.abspath(os.path.join(root,
                    "stack_stack_candidate.b98")),
                   os.path.join(temp,"stack_stack_candidate.b98"))
        forged=copy.deepcopy(proof)
        forged["seventeen_native_cases"][0]["trace_sha256"]=(
            hashlib.sha256(raw).hexdigest())
        with open(os.path.join(temp,"native_stack_stack_arithmetic.json"),
                  "w",encoding="utf-8") as sink:
            json.dump(forged,sink,sort_keys=True)
        try:
            independent.main(temp)
        except AssertionError as err:
            require(expected_reason in str(err),
                    "forged Native trace rejected for WRONG reason: "+str(err))
            return str(err)
        raise AssertionError("forged native {u} proof passed independent audit")
    finally:
        shutil.rmtree(temp)

def main(directory):
    require(os.path.isdir(directory),"missing Native stack-stack trace directory")
    with open(os.path.join(directory,"native_stack_stack_arithmetic.json"),
              encoding="utf-8") as stream:
        proof=json.load(stream)
    cases=proof["seventeen_native_cases"]
    require(proof["schema"]=="befunge-stage1-native-stack-stack-arithmetic-v1"
            and len(cases)==17 and cases[0]["case"]==FOCUS and
            cases[0]["observed"]["route"]=="stack_stack",
            "not the exact actual Native stack-stack arithmetic corpus")
    with open(os.path.join(directory,FOCUS+".tsv"),"rb") as stream:
        authentic=stream.read()
    require(hashlib.sha256(authentic).hexdigest()==cases[0]["trace_sha256"],
            "unaltered native positive evidence is already corrupt")
    tests=(
        ("forged_brace_opcode","STEP",BRACE,7,
            lambda s:ord("]"),"executed memory-byte mismatch"),
        ("forged_u_stack_depth","STEP",PIVOT,8,
            lambda s:int(s)+1,
            "Native actual stack-stack opcode/IP/velocity/TOSS depth mismatch"),
        ("forged_close_stack_depth","STEP",CLOSE,8,
            lambda s:int(s)+1,
            "Native actual stack-stack opcode/IP/velocity/TOSS depth mismatch"),
        ("forged_dynamic_x_velocity","STEP",JUMP,5,
            lambda s:int(s)+1,
            "Native actual stack-stack opcode/IP/velocity/TOSS depth mismatch"),
        ("forged_g_return","READ_AFTER",None,4,
            lambda s:int(s)+1,"g returned unexpected cell value"),
        ("forged_p_after_image","WRITE_AFTER",None,4,
            lambda s:int(s)+1,"p after-image mismatched actual value"))
    results=[]
    for label,tag,point,column,rewrite,expected in tests:
        tampered=modified_event(authentic,tag,point,column,rewrite)
        actual=independent_rejection(directory,proof,label,tampered,expected)
        results.append({"name":label,
                        "recomputed_trace_sha256":hashlib.sha256(tampered).hexdigest(),
                        "expected_rejection":expected,
                        "actual_rejection":actual})
        print("NATIVE_STACK_STACK_RECOMPUTED_SHA_TAMPER_REJECTED",label)
    require(len(results)==6,"incomplete native adversarial controls")
    report={"schema":"befunge-stage1-stack-stack-real-native-adversaries-v1",
            "status":"QA_ONLY_NO_STAGE1_ACCEPTANCE",
            "original_native_trace_sha256":hashlib.sha256(authentic).hexdigest(),
            "tamper_signatures_sha_recomputed":True,
            "rejected":results,"total":len(results)}
    with open(os.path.join(directory,"stack_stack_adversarial_controls.json"),
              "w",encoding="utf-8") as stream:
        json.dump(report,stream,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_STACK_STACK_REAL_TRACE_NEGATIVE_CONTROLS_PASS",
          len(results),"of",len(results))

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: real-stack-stack-negative-controls NATIVE_FOLDER")
    main(sys.argv[1])
