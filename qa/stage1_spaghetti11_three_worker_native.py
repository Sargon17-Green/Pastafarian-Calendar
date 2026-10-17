#!/usr/bin/env python3
"""QA11A Native 17D true third worker with shared-history dependency and third barrier."""
import hashlib,json,subprocess,tempfile
from pathlib import Path
SRC=Path("qa/spaghetti11_17d_three_worker_cascade.beq")
MANIFEST=Path("qa/SPAGHETTI11_THREE_WORKER_MANIFEST.json")
SOURCE_SHA="990d8fb2b84c7ee728634bb93a8e7baaef992c40"
ENGINE="third_party/funge-plus-plus/bin/funge"
def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()
def run(data,mode,seed=1,limit=10):
    with tempfile.TemporaryDirectory(prefix="qa11_triplet_") as d:
        p=Path(d)/"source.beq";p.write_bytes(data)
        cmd=[ENGINE,"-fconcurrent","-fthreads="+mode,"-fno-filesystem","-fno-execute",str(p)]
        try:
            q=subprocess.run(cmd,input=(str(seed)+"\n").encode("ascii"),
                capture_output=True,timeout=limit)
            try:nums=[int(x) for x in q.stdout.decode().split()]
            except (UnicodeDecodeError,ValueError):nums=[]
            return {"rc":q.returncode,"out":nums,"stderr":q.stderr.decode("utf-8","replace")[-200:]}
        except subprocess.TimeoutExpired:
            return {"rc":124,"out":[],"stderr":"bounded timeout"}
def patch(data,header,start,replace):
    lines=data.decode("ascii").splitlines(True)
    candidates=[i for i in range(1,len(lines)-1,2) if lines[i].startswith(header)]
    assert len(candidates)==1,(header,candidates)
    i=candidates[0]+1
    assert lines[i].count(start)==1 and len(start)==len(replace)
    lines[i]=lines[i].replace(start,replace,1)
    return "".join(lines).encode("ascii")
def main():
    data=SRC.read_bytes()
    assert gitblob(data)==SOURCE_SHA
    m=json.loads(MANIFEST.read_text("utf-8"))
    assert m["worker_count"]==3 and m["dimensions"]==17
    assert m["source_blob"]==SOURCE_SHA
    receipts={"schema":"qa11-three-worker-native-rendezvous-v1",
              "source_sha":SOURCE_SHA,"positive":[],"negative":[]}
    for mode in ("funge","native"):
        for seed in (1,2):
            for trial in range(3):
                result=run(data,mode,seed)
                assert result["rc"]==0 and result["out"]==[31,33,32],(mode,seed,trial,result)
                receipts["positive"].append({"mode":mode,"seed":seed,"repeat":trial,"out":[31,33,32]})
                print("QA11_NATIVE_THIRD_WORKER_CROSS_SHARD_PASS",mode,seed,trial,flush=True)
    # Physical fork suppression, no third flag can be produced.
    absent=patch(data,"Lines 1,Origin 233:-2,","t",">")
    # Directly damage the actual third worker's 17D g from worker B.
    c_header="Lines 1,Origin %d:-2,"%m["third_worker_start_x"]
    broken_read=patch(data,c_header,"/2+g","/2+z")
    # Wrong physical flag/ready marker, coordinator cannot pass gate.
    poll_header="Lines 1,Origin 233:-2,"
    broken_flag=patch(data,poll_header,"-!|","-z|")
    for label,mut in [("no_third_fork",absent),("worker_B_dependency_broken",broken_read),
                      ("third_completion_predicate_broken",broken_flag)]:
        q=run(mut,"funge",1,8)
        assert q["rc"]!=0 or q["out"]!=[31,33,32],(label,q)
        receipts["negative"].append({"name":label,"rc":q["rc"]})
        print("QA11_NATIVE_THIRD_WORKER_MUTANT_RED",label,q["rc"],flush=True)
    Path("spaghetti11_17d_triplet_native_receipt.json").write_text(
        json.dumps(receipts,indent=2,sort_keys=True)+"\n")
    print("QA11_NATIVE_THREE_WORKER_P_G_BARRIER_PASS",flush=True)
if __name__=="__main__":main()
