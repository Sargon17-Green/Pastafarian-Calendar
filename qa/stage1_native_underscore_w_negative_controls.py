#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Reject changed Native dx/dy/stack evidence, even with a new trace digest.

The 17 source traces come from real PyFunge. Five one-field tamper cases
modify only temporary trace copies; no interpreter or calendar is simulated.
"""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile
import stage1_native_underscore_w_graph_audit as audit

FOCUS="zero_equal"
POINTS={"underscore":(951,1334),"join":(951,1333),"w":(951,1332)}

def require(ok,why):
    if not ok:raise AssertionError(why)

def forge(raw,point,index,replacement):
    lines=raw.decode("ascii").splitlines(True)
    count=0
    for n,line in enumerate(lines):
        parts=line.rstrip("\n").split("\t")
        if len(parts)==9 and parts[0]=="STEP" and (
                int(parts[3]),int(parts[4]))==point:
            count+=1
            require(count==1 and parts[index]!=replacement,
                    "invalid or ineffective Native evidence tamper")
            parts[index]=replacement
            lines[n]="\t".join(parts)+"\n"
    require(count==1,"target Native opcode not executed")
    altered="".join(lines).encode("ascii")
    require(altered!=raw,"Native trace unchanged after tamper")
    return altered

def adversarial_copy(original_dir,proof,altered):
    folder=tempfile.mkdtemp(prefix="underscore-forged-")
    for case in proof["cases"]:
        filename=case["case"]+".tsv"
        require(os.path.basename(filename)==filename,"unsafe case label")
        target=os.path.join(folder,filename)
        if case["case"]==FOCUS:
            with open(target,"wb") as dst:dst.write(altered)
        else:
            os.symlink(os.path.abspath(os.path.join(original_dir,filename)),target)
    for name in ("underscore_w_candidate.b98","underscore_removed.b98"):
        os.symlink(os.path.abspath(os.path.join(original_dir,name)),
                   os.path.join(folder,name))
    p=copy.deepcopy(proof)
    p["cases"][0]["trace_sha256"]=hashlib.sha256(altered).hexdigest()
    with open(os.path.join(folder,"underscore_w_qa_proof.json"),
              "w",encoding="utf-8") as dst:
        json.dump(p,dst,sort_keys=True)
    return folder

def main(directory):
    with open(os.path.join(directory,"underscore_w_qa_proof.json"),
              encoding="utf-8") as stream: proof=json.load(stream)
    require(proof["schema"]=="befunge-stage1-native-underscore-w-v1" and
            len(proof["cases"])==17 and
            proof["cases"][0]["case"]==FOCUS and
            proof["cases"][0]["mode"]=="west",
            "unexpected frozen native QA corpus")
    with open(os.path.join(directory,FOCUS+".tsv"),"rb") as f: genuine=f.read()
    require(hashlib.sha256(genuine).hexdigest()==
            proof["cases"][0]["trace_sha256"],
            "original real Native evidence SHA mismatch")
    cases=(
       ("forge_underscore_direction",POINTS["underscore"],5,"1",
        "Native underscore comparator velocity/stack mismatch"),
       ("forge_underscore_stack",POINTS["underscore"],8,"2",
        "Native underscore comparator velocity/stack mismatch"),
       ("forge_join_direction",POINTS["join"],5,"0",
        "Native underscore rejoin velocity/stack mismatch"),
       ("forge_w_direction",POINTS["w"],5,"1",
        "Native w entry velocity/stack mismatch"),
       ("forge_w_stack",POINTS["w"],8,"4",
        "Native w entry velocity/stack mismatch"))
    records=[]
    for label,point,index,replacement,expected in cases:
        modified=forge(genuine,point,index,replacement)
        temp=adversarial_copy(directory,proof,modified)
        try:
            try:
                audit.main(temp)
            except AssertionError as err:
                require(expected in str(err),
                        "unexpected Native rejection reason %s: %s" %(label,err))
                records.append({"label":label,
                                "recomputed_sha256":hashlib.sha256(modified).hexdigest(),
                                "reason":str(err)})
                print("NATIVE_UNDERSCORE_W_REAL_TRACE_TAMPER_REJECT_PASS",label)
            else:
                raise AssertionError("Native forgery was not rejected: "+label)
        finally:
            shutil.rmtree(temp)
    require(len(records)==5,"incomplete Native tamper rejection coverage")
    out={"schema":"befunge-stage1-underscore-w-negative-native-v1",
         "scope":"QA_ONLY_NO_STAGE1_ACCEPTANCE",
         "original_native_trace_sha256":hashlib.sha256(genuine).hexdigest(),
         "recomputed_sha_per_tamper":True,"rejected":records}
    with open(os.path.join(directory,"underscore_w_tamper_controls.json"),
              "w",encoding="utf-8") as dst:
        json.dump(out,dst,sort_keys=True,indent=2)
        dst.write("\n")
    print("NATIVE_UNDERSCORE_W_REAL_TRACE_NEGATIVE_CONTROLS_PASS",
          len(records),"of",len(records))

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: negative_controls NATIVE_TRACE_DIR")
    main(sys.argv[1])
