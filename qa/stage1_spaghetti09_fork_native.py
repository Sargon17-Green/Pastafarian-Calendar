#!/usr/bin/env python3
"""Native QA09 17-dimensional two-worker rendezvous smoke gate."""
import hashlib,json,subprocess,tempfile
from pathlib import Path
SOURCE=Path("qa/spaghetti09_nd17_two_worker_rendezvous_fixture.beq")
PIN="e22a8b706fb84e3356db6c70aac29b9145642201"
def run(data,seed):
    with tempfile.TemporaryDirectory(prefix="qa09fork_") as tmp:
        file=Path(tmp)/"native.beq";file.write_bytes(data)
        cmd=["third_party/funge-plus-plus/bin/funge","-fconcurrent","-fthreads=funge","-fno-filesystem","-fno-execute",str(file)]
        try:
            cp=subprocess.run(cmd,input=(str(seed)+"\n").encode(),capture_output=True,timeout=7)
            return {"rc":cp.returncode,"out":cp.stdout.decode("utf-8","replace").strip(),
                   "err":cp.stderr.decode("utf-8","replace")[-400:]}
        except subprocess.TimeoutExpired as e:
            return {"rc":124,"out":(e.stdout or b"").decode("utf-8","replace").strip(),"err":"bounded timeout"}
data=SOURCE.read_bytes()
sha=hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()
assert sha==PIN,(sha,PIN)
lines=data.decode().splitlines(True)
assert lines[0]=="Version 1,Dimensions 17\n"
def modify(blockfirst,old,new):
    rows=lines[:]
    hits=[i for i in range(1,len(rows)-1,2) if rows[i].startswith(blockfirst)]
    assert len(hits)==1,(blockfirst,hits)
    ix=hits[0]+1
    assert rows[ix].count(old)==1,(blockfirst,old)
    rows[ix]=rows[ix].replace(old,new,1)
    return "".join(rows).encode()
results=[]
for seed in (1,2):
    for repeat in range(6):
        r=run(data,seed)
        assert (r["rc"],r["out"])==(0,"31 33"),("normal",seed,repeat,r)
        results.append({"seed":seed,"repeat":repeat,"output":r["out"],"rc":r["rc"]})
        print("QA09_NATIVE_TWO_FORK_TWO_FLAGS_PASS",seed,repeat,r["out"],flush=True)
# Each fork's physical absence must prevent one of the two completion gates.
muts=[
 ("forkA_suppressed",modify("Lines 1,Origin 0:0,","t","z")),
 ("forkB_suppressed",modify("Lines 1,Origin 1:0,","t","z")),
 ("workerB_instruction_suppressed",modify("Lines 1,Origin 1:0,","u1u-10","u1uz10")),
 ("flagB_g_read_suppressed",modify("Lines 1,Origin 181:-1,","g","z"))]
for name,altered in muts:
    result=run(altered,1)
    assert result["rc"]!=0 or result["out"]!="31 33",(name,result)
    print("QA09_NATIVE_TWO_WORKER_MUTATION_RED",name,result["rc"],repr(result["out"]),flush=True)
Path("spaghetti09_fork_native_receipt.json").write_text(json.dumps({
 "schema":"qa09-native-17d-two-worker-fork-smoke-v1","native":True,
 "source_sha":PIN,"repeated":results,"mutations":[x[0] for x in muts],
 "production_modified":False,"qa09_full_80_opcode_tested":False
},indent=2,sort_keys=True)+"\n")
print("QA09_NATIVE_TWO_WORKER_FORK_SMOKE_PASS",flush=True)
