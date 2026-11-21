#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Adversarial raw-Native two-valid-w proof controls, with RECOMPUTED SHA.

Operate only on temporary copies of already recorded PyFunge STEP/READ/WRITE
traces, never on Befunge code, live interpreters or source oracles.
The separately implemented full graph auditor must reject all six
single-field forgeries AFTER their manifest SHA256 values are updated.
"""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile
import stage1_native_two_valid_w_independent_graph as audit

W=(951,1332)
TURN=(951,1336)

def require(ok,why):
    if not ok: raise AssertionError(why)

def tamper(trace,which,xy,column,rewrite):
    lines=trace.decode("ascii").splitlines(True)
    seen=0
    for i,line in enumerate(lines):
        f=line.rstrip("\n").split("\t")
        if f[0]!=which:continue
        if xy is not None:
            if len(f)<5 or (int(f[3]),int(f[4]))!=xy:continue
        seen+=1
        if seen>1:break
        original=f[column]
        changed=str(rewrite(original))
        require(original!=changed,
                "Native adversarial mutation changed no value "+which)
        f[column]=changed
        lines[i]="\t".join(f)+"\n"
    require(seen>=1,"Native forged evidence did not contain watched event")
    output="".join(lines).encode("ascii")
    require(output!=trace,"Native trace forgery had no effect")
    return output

def proof_copy(root,proof,label,new_trace):
    folder=tempfile.mkdtemp(prefix="native-two-valid-w-forgery-")
    for row in proof["cases"]:
        file=row["trace"]
        require(file==row["case"]+".new.tsv" and
                os.path.basename(file)==file,
                "unsafe recorded Native evidence filename")
        target=os.path.join(folder,file)
        if row["case"]==label:
            with open(target,"wb") as stream:stream.write(new_trace)
        else:
            os.symlink(os.path.abspath(os.path.join(root,file)),target)
    draft=copy.deepcopy(proof)
    x=next(z for z in draft["cases"] if z["case"]==label)
    x["trace_sha256"]=hashlib.sha256(new_trace).hexdigest()
    with open(os.path.join(folder,"native_two_valid_w_evidence.json"),
              "w",encoding="utf-8") as out:
        json.dump(draft,out,sort_keys=True)
    return folder

def rejection(root,proof,record):
    label,tag,point,column,rewrite,expected=record
    with open(os.path.join(root,label+".new.tsv"),"rb") as stream:
        authentic=stream.read()
    manifest=next(x for x in proof["cases"] if x["case"]==label)
    require(hashlib.sha256(authentic).hexdigest()==manifest["trace_sha256"],
            "untrusted original Native evidence digest "+label)
    altered=tamper(authentic,tag,point,column,rewrite)
    folder=proof_copy(root,proof,label,altered)
    try:
        try:
            audit.main(folder)
        except AssertionError as err:
            require(expected in str(err),
                    "different/unexpected Native audit rejection: "+str(err))
            print("NATIVE_TWO_VALID_W_FORGED_SHA_REJECTED",label,tag,expected)
            return {"label":label,"tag":tag,"expected_rejection":expected,
                    "recalculated_trace_sha256":hashlib.sha256(altered).hexdigest()}
        raise AssertionError("recomputed-SHA Native forgery passed full graph audit")
    finally:
        shutil.rmtree(folder)

def main(root):
    require(os.path.isdir(root),"missing actual Native two-valid-w artifact")
    with open(os.path.join(root,"native_two_valid_w_evidence.json"),
              encoding="utf-8") as stream:proof=json.load(stream)
    require(proof["schema"]=="befunge-stage1-two-valid-w-native-v2"
            and len(proof["cases"])==17 and
            proof["cases"][0]["case"]=="zero_equal" and
            proof["cases"][1]["case"]=="foundation_cross",
            "adversarial inputs cannot be aligned with Native trace case ordering")
    checks=[
        ("zero_equal","STEP",W,7,lambda s:int(s)+1,
         "executed memory-byte mismatch"),
        ("zero_equal","STEP",W,5,lambda s:int(s)+1,
         "Native true w entry velocity/opcode/stack changed"),
        ("zero_equal","STEP",W,8,lambda s:int(s)+1,
         "Native true w entry velocity/opcode/stack changed"),
        ("zero_equal","READ_AFTER",None,4,lambda s:int(s)+1,
         "g returned unexpected cell value"),
        ("zero_equal","WRITE_AFTER",None,4,lambda s:int(s)+1,
         "p after-image mismatched actual value"),
        ("foundation_cross","STEP",TURN,6,lambda s:int(s)*-1,
         "native dual-entry lower junction lost real repeated vectors")
    ]
    results=[rejection(root,proof,x) for x in checks]
    require(len(results)==6,"incomplete tamper proof")
    report={"schema":"befunge-stage1-two-valid-w-native-forgery-controls-v1",
            "status":"QA_ONLY_NOT_STAGE1_ACCEPTANCE",
            "real_native_source":True,"recomputed_manifest_sha256":True,
            "rejected_forged_raw_native_traces":len(results),"cases":results}
    with open(os.path.join(root,"two_valid_w_adversarial_controls.json"),
              "w",encoding="utf-8") as stream:
        json.dump(report,stream,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_TWO_VALID_W_ADVERSARIAL_REAL_TRACE_PASS",len(results),
          "of",len(results))

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: native_two_valid_w_negative_controls ACTUAL_NATIVE_DIR")
    main(sys.argv[1])
