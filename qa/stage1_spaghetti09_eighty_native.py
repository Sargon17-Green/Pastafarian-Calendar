#!/usr/bin/env python3
"""QA09 full 17D Native two-shard compilation gate; no calendar production change."""
import hashlib,json,subprocess,tempfile
from pathlib import Path

SOURCE=Path("qa/spaghetti09_17d_two_shard_eighty_opcode_candidate.beq")
MANIFEST=Path("qa/SPAGHETTI09_17D_EIGHTY_OPCODE_MANIFEST.json")
SOURCE_SHA="275cec0add8705565d27da4233860bf42d134a27"
FIXTURE_SHA="e22a8b706fb84e3356db6c70aac29b9145642201"
QA08_SHA="4ba6902de08cf9483374f43a33f1d4ae7a14e3f6"
ENG="third_party/funge-plus-plus/bin/funge"

def check(cond,msg):
    if not cond:raise AssertionError(msg)

def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()

def parts(data):
    lines=data.decode("ascii").splitlines(True)
    check(lines[0]=="Version 1,Dimensions 17\n","Wrong BeQ header")
    check((len(lines)-1)%2==0,"Malformed physical source panels")
    return lines,[(i,lines[i],lines[i+1].rstrip("\n")) for i in range(1,len(lines),2)]

def native(data,seed,mode="funge",seconds=12):
    with tempfile.TemporaryDirectory(prefix="qa09_eighty_") as d:
        src=Path(d)/"native.beq";src.write_bytes(data)
        args=[ENG,"-fconcurrent","-fthreads="+mode,"-fno-filesystem","-fno-execute",str(src)]
        try:
            cp=subprocess.run(args,input=(str(seed)+"\n").encode("ascii"),capture_output=True,timeout=seconds)
            txt=cp.stdout.decode("utf-8","replace")
            try: out=[int(x) for x in txt.split()]
            except ValueError:out=[]
            return {"rc":cp.returncode,"out":out,"stderr":cp.stderr.decode("utf-8","replace")[-500:]}
        except subprocess.TimeoutExpired:
            return {"rc":124,"out":[],"stderr":"bounded timeout"}

def expected(seed):
    o=[31,33]
    for axis in range(1,17):
        t=axis*(axis+1)//2
        A=48+10*((t+seed)%2)
        D=48+10*((t+seed+1)%2)
        o.extend([A,36,D,36,62,axis])
    o.append(136*seed)
    return o

def change_block(data,matcher,old,new):
    lines,ps=parts(data)
    matches=[(i,h,s) for i,h,s in ps if matcher(h,s)]
    check(len(matches)==1,"Nonunique mutation site "+str((old,len(matches))))
    index,h,s=matches[0]
    check(s.count(old)==1 and len(old)==len(new),"Not one length-preserving mutation "+old)
    lines[index+1]=s.replace(old,new,1)+"\n"
    return "".join(lines).encode("ascii")

def lit(n):
    if n<=15:return format(n,"x")
    return "0"+"".join("a*"+c+"+" for c in str(n))

def stage_mutant(data,entry):
    axis=entry["axis"]
    x=entry["source_x"]
    offset=0
    if axis==1:
        dec=lambda n:"0"+"".join("a*"+c+"+" for c in str(n))
        addr=lambda n:dec(n)+"0"*16
        offset=len(addr(10001)+"g."+addr(10003)+"g."+"&:"+"0"*17+"p0")
    lines,ps=parts(data)
    sites=[(i,s) for i,h,s in ps if h.startswith("Lines 1,Origin %d:"%x) and len(s)>200]
    check(len(sites)==1,"Stage origin ambiguous "+str(axis))
    i,s=sites[0]
    old=lit(axis);new=lit(axis+2 if axis<=13 or axis==16 else axis-2)
    check(len(old)==len(new) and s[offset:offset+len(old)]==old,
          "No actual dimension-contribution instruction at "+str(axis))
    lines[i+1]=s[:offset]+new+s[offset+len(old):]+"\n"
    return "".join(lines).encode("ascii")

def main():
    data=SOURCE.read_bytes()
    check(gitblob(data)==SOURCE_SHA,"Native 80-opcode source mismatch")
    meta=json.loads(MANIFEST.read_text(encoding="utf-8"))
    check(meta["candidate_blob"]==SOURCE_SHA and meta["fixture_parent_blob"]==FIXTURE_SHA
          and meta["stage08_parent_blob"]==QA08_SHA,"Source provenance mismatch")
    check(meta["dimension_count"]==17 and meta["generated_opcode_count"]==80
          and len(meta["stages"])==16 and meta["source_bytes"]==len(data),
          "False 17-dimensional geometry claim")
    _,ps=parts(data)
    traps=[x for x in ps if x[2]=="@"]
    check(len(traps)==80 and len(ps)==108,"Original future source cells missing")
    # All five emitters on every axis must combine BOTH independent worker
    # residuals into the preceding accumulator expression, not just onto the
    # stack. Missing this + leaves five leaked operands per dimension.
    dec=lambda n:"0"+"".join("a*"+c+"+" for c in str(n))
    addr=lambda n:dec(n)+"0"*16
    shared=addr(10001)+"g"+lit(31)+"-"+addr(10003)+"g"+lit(33)+"-+"
    for entry in meta["stages"]:
        p=[s for _,h,s in ps if h.startswith("Lines 1,Origin %d:"%entry["source_x"])
           and len(s)>700]
        check(len(p)==1 and p[0].count(shared+"+")==5,
              "Stage %s leaks residual operands during future-code synthesis"%entry["axis"])

    check(any("Origin 10005:0" in h and h.endswith(":0:1:\n") for i,h,s in ps),
          "No nonzero 17th-dimensional sentinel")
    qa08=json.loads(Path("spaghetti08_nd17_native_receipt.json").read_text())
    check(qa08["source_sha"]==QA08_SHA and sorted(qa08["seeds"])==[1,2],
          "Missing fresh QA08 Native provenance")
    receipt={"schema":"qa09-native-17d-dual-worker-80-opcodes-v1",
             "source_blob":SOURCE_SHA,"fixture_blob":FIXTURE_SHA,"qa08_blob":QA08_SHA,
             "dimension_count":17,"two_native_worker_shards":True,
             "traps":80,"valid_runs":[],"masked_runs":[],"mutants":[]}
    for mode in ("funge","native"):
        for seed in (1,2):
            for repetition in range(3):
                result=native(data,seed,mode)
                check(result["rc"]==0 and result["out"]==expected(seed),
                      "Native two-worker 80-opcode mismatch "+repr((mode,seed,repetition,result)))
                receipt["valid_runs"].append({"mode":mode,"seed":seed,"repeat":repetition,
                     "out_sha256":hashlib.sha256(str(result["out"]).encode()).hexdigest()})
                print("QA09_NATIVE_17D_80_OPCODE_PASS",mode,seed,repetition,
                      "numeric_cells",len(result["out"]),flush=True)
    lines,_=parts(data)
    for i,h,s in traps:
        lines[i+1]="q\n"
    mask="".join(lines).encode("ascii")
    for seed in (1,2):
        result=native(mask,seed)
        check(result["rc"]==0 and result["out"]==expected(seed),
              "Native 80 original trap source bytes unexpectedly executed "+str(seed))
        receipt["masked_runs"].append({"seed":seed,"source_traps_replaced":80})
        print("QA09_NATIVE_80_TRAP_MASKING_PASS",seed,flush=True)
    cases=[
      ("fork_A",lambda h,s:h.startswith("Lines 1,Origin 0:0,"),"t","z"),
      ("fork_B",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),"t","z"),
      ("worker_B_understack",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),
       "u1u-10","u1uz10"),
      ("worker_B_residue",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),
       "/2:","/3:")
    ]
    for name,match,old,new in cases:
        altered=change_block(data,match,old,new)
        result=native(altered,1,seconds=3)
        check(result["rc"]!=0 or result["out"]!=expected(1),"Causally inert cross-shard attack "+name)
        receipt["mutants"].append({"name":name,"exit":result["rc"]})
        print("QA09_NATIVE_WORKER_SHARD_MUTANT_RED",name,result["rc"],flush=True)
    for stage in meta["stages"]:
        altered=stage_mutant(data,stage)
        seed=1 if stage["axis"]%2 else 2
        result=native(altered,seed,seconds=3)
        check(result["rc"]!=0 or result["out"]!=expected(seed),
              "Dimension %s counterfactual inert"%stage["axis"])
        receipt["mutants"].append({"axis":stage["axis"],"exit":result["rc"]})
        print("QA09_NATIVE_17D_STAGE_MUTANT_RED",stage["axis"],result["rc"],flush=True)
    Path("spaghetti09_nd17_native_receipt.json").write_text(json.dumps(receipt,sort_keys=True,indent=2)+"\n")
    print("QA09_NATIVE_TWO_SHARDS_17D_EIGHTY_OPCODES_PASS",flush=True)

if __name__=="__main__":
    main()
