#!/usr/bin/env python3
"""Bounded native QA10 IP-travel experiments; diagnostics, NOT acceptance."""
from __future__ import annotations
import hashlib,json,subprocess,tempfile
from pathlib import Path

FILE=Path("qa/spaghetti10_17d_dual_worker_macro_candidate.beq")
META=Path("qa/SPAGHETTI10_17D_MACRO_MANIFEST.json")
SOURCE_SHA="010efd012ae52a60740aa97750b5a02519912e92"
ENGINE="third_party/funge-plus-plus/bin/funge"

def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()

def stop_before(raw,meta,axis):
    stages=meta["stages"]
    item=stages[axis-1]
    source=raw.decode("ascii").splitlines(True)
    target="Lines 1,Origin %d:%d,Coord %s:\n"%(
        item["source_pos"][0],item["source_pos"][1],
        ":".join(map(str,item["source_pos"][2:])))
    hits=[i for i,h in enumerate(source) if h==target]
    assert len(hits)==1,(axis,hits)
    i=hits[0]+1
    assert len(source[i])>900
    source[i]="@"+source[i][1:]
    return "".join(source).encode("ascii")

def run(raw,seed,tag,limit):
    with tempfile.TemporaryDirectory(prefix="qa10_forensic_") as folder:
        file=Path(folder)/"mutated.beq"
        file.write_bytes(raw)
        args=[ENGINE,"-fconcurrent","-fthreads=funge",
              "-fno-filesystem","-fno-execute",str(file)]
        try:
            cp=subprocess.run(args,input=(str(seed)+"\n").encode("ascii"),
                capture_output=True,timeout=limit)
            out,err,rc=cp.stdout,cp.stderr,cp.returncode
        except subprocess.TimeoutExpired as ex:
            out,err,rc=ex.stdout or b"",ex.stderr or b"",124
        traces=[x for x in err.decode("utf-8","replace").splitlines()
                if "QA10_ENGINE_TRACE" in x]
        try:
            numbers=[int(t) for t in out.decode("utf-8","replace").split()]
        except ValueError:
            numbers=[]
        evidence={"tag":tag,"seed":seed,"exit":rc,"limit":limit,
           "stdout_bytes":len(out),"numeric_count":len(numbers),
           "prefix":numbers[:16],"suffix":numbers[-16:],
           "trace_count":len(traces),"traces":traces[:120]}
        print("QA10_NATIVE_IP_FORENSIC",json.dumps({k:v for k,v in evidence.items()
            if k!="traces"}),flush=True)
        for line in traces[:110]:
            print("QA10_NATIVE_TRACE",tag,line,flush=True)
        return evidence

def main():
    source=FILE.read_bytes()
    assert gitblob(source)==SOURCE_SHA
    meta=json.loads(META.read_text("utf-8"))
    receipts=[]
    for axis in (1,2,3,5,9,16):
        altered=stop_before(source,meta,axis)
        receipts.append(run(altered,1,"stop_before_%02d"%axis,20))
    receipts.append(run(source,1,"full_208_source",110))
    Path("spaghetti10_native_ip_forensics.json").write_text(
       json.dumps({"schema":"qa10-ip-motion-forensic-v1",
           "source_blob":SOURCE_SHA,"not_acceptance":True,"tests":receipts},
           indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("QA10_IP_FORENSICS_COMPLETE",flush=True)

if __name__=="__main__":
    main()
