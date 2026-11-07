#!/usr/bin/env python3
"""QA11B smoke: third native IP residue must alter future 208-byte 17D code."""
from __future__ import annotations
import hashlib,json,subprocess,tempfile,time
from pathlib import Path
SOURCE=Path("qa/spaghetti11_17d_cascade_208_generated_candidate.beq")
MFILE=Path("qa/SPAGHETTI11B_THIRD_RESIDUE_MACRO_MANIFEST.json")
PROVEN_TRIPLET=Path("qa/spaghetti11_17d_three_worker_cascade.beq")
QA11B_SHA="afa261c6eab74d69b6c3afbe6c641fc130d627c0"
QA11A_SHA="990d8fb2b84c7ee728634bb93a8e7baaef992c40"
QA10_SHA="010efd012ae52a60740aa97750b5a02519912e92"
ENGINE="third_party/funge-plus-plus/bin/funge"
RECEIPT=Path("spaghetti11b_three_shard_smoke_receipt.json")
def gb(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()
def verify(test,msg):
    if not test:raise AssertionError(msg)
def expected(seed):
    out=[31,33,32]
    for i in range(1,17):
        T=i*(i+1)//2
        p=(T+seed)%2
        factor=50+p
        out += [48+10*p,36,48+10*(1-p),36,factor,42,factor,47,58,36,58,36,62,i]
    return out+[136*seed]
def run(src,seed,mode,seconds=170):
    with tempfile.TemporaryDirectory(prefix="qa11b_native_") as wd:
        file=Path(wd)/"source.beq"
        file.write_bytes(src)
        args=[ENGINE,"-fconcurrent","-fthreads="+mode,"-fno-execute",
              "-fno-filesystem",str(file)]
        started=time.monotonic()
        try:
            cp=subprocess.run(args,input=(str(seed)+"\n").encode("ascii"),
                              capture_output=True,timeout=seconds)
            data=cp.stdout
            rc=cp.returncode
            err=cp.stderr
        except subprocess.TimeoutExpired as ex:
            rc=124
            data=ex.stdout or b""
            err=ex.stderr or b""
        try:nums=[int(s) for s in data.decode("utf-8","replace").split()]
        except ValueError:nums=[]
        return {"exit":rc,"numbers":nums,"elapsed_seconds":round(time.monotonic()-started,3),
                "output_bytes":len(data),"stderr_tail":err.decode("utf-8","replace")[-250:]}
def mutate_worker_divider(src):
    rows=src.decode("ascii").splitlines(True)
    found=[i for i in range(1,len(rows)-1,2)
           if rows[i].startswith("Lines 1,Origin 67:-2,")]
    verify(len(found)==1,"Third worker was relocated or removed")
    i=found[0]+1
    # Worker source runs WEST. "/2+" in physical eastward layout
    # executes "+2/" and computes 32. Replacing with "/3+"
    # computes 21, but retains all 3 workers and writes readiness.
    verify(rows[i].count("/2+")==1,"Worker C divider not unique")
    rows[i]=rows[i].replace("/2+","/3+",1)
    return "".join(rows).encode("ascii")
def main():
    src=SOURCE.read_bytes()
    verify(gb(src)==QA11B_SHA,"Exact QA11B candidate SHA mismatch")
    verify(gb(PROVEN_TRIPLET.read_bytes())==QA11A_SHA,
           "Existing Native-passed third-worker source unexpectedly changed")
    meta=json.loads(MFILE.read_text("utf-8"))
    verify(meta["qa10_parent_source_sha"]==QA10_SHA
           and meta["qa11a_parent_source_sha"]==QA11A_SHA,
           "Signed QA10/QA11A provenance not preserved")
    verify(meta["source_bytes"]==len(src)
           and meta["generated_opcode_count"]==208
           and meta["dimensions"]==17 and meta["worker_count"]==3
           and len(meta["stages"])==16,
           "Bad third-worker macro metadata")
    lines=src.decode("ascii").splitlines()
    original_traps=[s for s in lines if s=="@"]
    verify(len(original_traps)==208,"Missing all 208 hostile future source cells")
    R=meta["cross_residual_formula"]
    for st in meta["stages"]:
        matches=[lines[i+1] for i in range(1,len(lines)-1,2)
                 if lines[i].startswith("Lines 1,Origin %d:"%st["source_x"])
                 and len(lines[i+1])>1000]
        verify(len(matches)==1 and matches[0].count(R+"+")==13,
               "Third shard not in all 13 code byte emitters, axis "+str(st["axis"]))
        verify(len(st["target_positions"])==13
               and all(len(v)==17 for v in st["target_positions"]),
               "17-dimensional trap geometry lost")
    receipt={"schema":"qa11b-three-ip-cross-history-208-macro-smoke-v1",
             "source_sha":QA11B_SHA,"native":True,
             "patched_engine_scheduler":True,"healthy":[],"counterfactual":[]}
    for seed in (1,2):
        for mode in ("funge","native"):
            got=run(src,seed,mode,170)
            ok=got["exit"]==0 and got["numbers"]==expected(seed)
            receipt["healthy"].append({"seed":seed,"mode":mode,"exit":got["exit"],
                "elapsed_seconds":got["elapsed_seconds"],
                "count":len(got["numbers"]),"pass":ok,
                "last_values":got["numbers"][-4:]})
            print("QA11B_NATIVE_THREE_WORKER_HEALTHY",
                  seed,mode,got["exit"],len(got["numbers"]),
                  got["elapsed_seconds"],"PASS" if ok else "FAIL",flush=True)
            verify(ok,"QA11B healthy 17D result mismatch: "+str((seed,mode,got)))
    broken=mutate_worker_divider(src)
    # Independently prove the altered worker still forks, runs, completes
    # and produces its own physical residue, rather than simply being absent.
    worked=run(mutate_worker_divider(PROVEN_TRIPLET.read_bytes()),1,"funge",15)
    verify(worked["exit"]==0 and worked["numbers"]==[31,33,21],
           "Third-worker residue mutation prevented worker completion")
    print("QA11B_NATIVE_THIRD_WORKER_STILL_COMPLETES_WITH_21",flush=True)
    changed=run(broken,1,"funge",170)
    # The three residues are always printed BEFORE generating the 208 bytes.
    # The first emitted numeric byte must be different too; simply printing
    # changed C is insufficient evidence that it drives later code.
    verify(changed["exit"]!=0 or changed["numbers"]!=expected(1),
           "Mutating third worker did not change QA11B behavior")
    if changed["exit"]==0 and len(changed["numbers"])>4:
        verify(changed["numbers"][3]!=expected(1)[3],
               "Third residue changed, but first generated byte did not")
    receipt["counterfactual"].append({
        "name":"third_worker_divider_2_to_3_still_completes",
        "C_only_fixture":[31,33,21],"qa11b_exit":changed["exit"],
        "output_count":len(changed["numbers"]),
        "prefix":changed["numbers"][:10],
        "changed_first_generated_byte":len(changed["numbers"])>3
            and changed["numbers"][3]!=expected(1)[3]})
    RECEIPT.write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n")
    print("QA11B_NATIVE_THIRD_RESIDUE_CAUSAL_CODE_SMOKE_PASS",flush=True)
if __name__=="__main__":main()
