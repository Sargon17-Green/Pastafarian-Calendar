#!/usr/bin/env python3
"""QA08 Funge++ Native 17D split-IP, nested stacks, joined residue and 48-opcode compilation."""
import argparse,hashlib,json,re,subprocess,tempfile
from pathlib import Path

SOURCE=Path("qa/spaghetti08_17d_concurrent_stack_residue.beq")
MANIFEST=Path("qa/SPAGHETTI08_17D_MANIFEST.json")
PARENT_SHA="4c9bff056cb61004d37dd2d949fccf171b4ddf0f"
SOURCE_SHA="0b49d3b4175055d365a089267cfc2450ea6d83aa"
ENGINE_SHA="cd6d7f005b4fc33b486fcc2380b35406f6125ca4"
RECEIPT=Path("spaghetti08_nd17_native_receipt.json")
DIM=17

def need(ok,msg):
    if not ok: raise AssertionError(msg)

def gitblob(raw):
    return hashlib.sha1(("blob %d\0"%len(raw)).encode()+raw).hexdigest()

def native(engine,data,seed,limit=15):
    with tempfile.TemporaryDirectory(prefix="nd17qa08_") as folder:
        src=Path(folder)/"mutant.beq"
        src.write_bytes(data)
        cmd=[str(engine),"-fconcurrent","-fthreads=funge","-fno-execute","-fno-filesystem",str(src)]
        try:
            cp=subprocess.run(cmd,input=("%d\n"%seed).encode("ascii"),
                              stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=limit)
        except subprocess.TimeoutExpired:
            return {"exit":124,"numbers":[],"error":"bounded timeout","timeout":True}
        out=cp.stdout.decode("utf-8","replace")
        try: numbers=[int(x) for x in out.split()]
        except ValueError: numbers=[]
        return {"exit":cp.returncode,"numbers":numbers,
                "error":cp.stderr.decode("utf-8","replace")[-250:],"timeout":False}

def expected(seed):
    output=[31]
    for axis in range(1,17):
        tri=axis*(axis+1)//2
        output.extend([48+10*((tri+seed)%2),36,62,axis])
    return output+[136*seed]

def parse_blocks(data):
    s=data.decode("ascii")
    lines=s.splitlines(True)
    need(lines[0]=="Version 1,Dimensions 17\n","Not real BeQunge 17D")
    need((len(lines)-1)%2==0,"Malformed one-row BeQunge block structure")
    result=[]
    for idx in range(1,len(lines),2):
        head,body=lines[idx],lines[idx+1]
        need(head.startswith("Lines 1,Origin ") and head.endswith(":\n"),
             "Unknown panel header")
        result.append({"index":idx+1,"header":head,"source":body.rstrip("\n")})
    return lines,result

def patch_one(raw,selector,source_fragment,replacement):
    lines,blocks=parse_blocks(raw)
    indices=[z for z in blocks if selector(z)]
    need(len(indices)==1,"Expected exactly one mutation panel "+source_fragment)
    b=indices[0]
    before=lines[b["index"]]
    need(before.count(source_fragment)==1 and len(source_fragment)==len(replacement),
         "Mutation must change exactly one same-width literal "+source_fragment)
    lines[b["index"]]=before.replace(source_fragment,replacement,1)
    return "".join(lines).encode("ascii")

def mutate_worker(raw,old,new):
    lines,blocks=parse_blocks(raw)
    workers=[b for b in blocks if b["header"].startswith("Lines 1,Origin -")]
    need(len(workers)==1,"Expected one and only one worker backwards lane")
    b=workers[0];original=b["source"][::-1]
    need(original.count(old)==1 and len(old)==len(new),"Non-unique worker instruction")
    lines[b["index"]]=original.replace(old,new,1)[::-1]+"\n"
    return "".join(lines).encode("ascii")

def mutate_traps(raw):
    lines,blocks=parse_blocks(raw)
    changed=0
    for b in blocks:
        if b["source"]=="@":
            lines[b["index"]]="q\n";changed+=1
    need(changed==48,"There must be exactly 48 unresolved future opcodes")
    return "".join(lines).encode("ascii")

def mutate_axis(raw,step):
    lines,blocks=parse_blocks(raw)
    x=step["source_x"];i=step["axis"]
    target=[z for z in blocks if z["header"].startswith("Lines 1,Origin %d:"%x)
            and len(z["source"])>100]
    need(len(target)==1,"Missing unique dimensional compiler block "+str(i))
    b=target[0]
    fromval=hex(i)[2:] if i<=15 else decimal(i)
    alt=i+2 if i<=13 or i==16 else i-2
    toval=hex(alt)[2:] if alt<=15 else decimal(alt)
    offset=60 if i==1 else 0
    old=b["source"]
    need(old[offset:offset+len(fromval)]==fromval
         and len(fromval)==len(toval),"Mutation source value not located")
    lines[b["index"]]=old[:offset]+toval+old[offset+len(fromval):]+"\n"
    return "".join(lines).encode("ascii"),alt

def decimal(n):
    return "0"+"".join("a*"+ch+"+" for ch in str(n))

def prior_seeds(path):
    j=json.loads(path.read_text(encoding="utf-8"))
    need(j.get("candidate_blob")==PARENT_SHA and j.get("dimensions")==17,
         "Native QA07 provenance unavailable or wrong parent")
    vals=[x["seed"] for x in j["observations"]]
    need(sorted(vals)==[1,2],"Need two genuine 17D verified historical seeds")
    return vals

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--engine",required=True,type=Path)
    parser.add_argument("--qa07-receipt",type=Path,default=Path("spaghetti07_nd17_native_receipt.json"))
    args=parser.parse_args()
    engine=args.engine.resolve()
    need(engine.is_file(),"Native Funge++ executable absent")
    raw=SOURCE.read_bytes()
    need(gitblob(raw)==SOURCE_SHA,"QA08 source-pinned git blob mismatch")
    manifest=json.loads(MANIFEST.read_text(encoding="utf-8"))
    need(manifest["dimensions"]==17
         and manifest["generated_instruction_traps"]==48
         and manifest["parent07_blob"]==PARENT_SHA
         and manifest["beq_size"]==len(raw),
         "Inconsistent 17D fork source manifest")
    _,blocks=parse_blocks(raw)
    need(len(blocks)==71,"Expected 23 source panels and 48 source-trap sites")
    seeds=prior_seeds(args.qa07_receipt)
    receipt={"schema":"qa08-native-17d-fork-nested-stacks-v1",
       "source_sha":SOURCE_SHA,"engine_sha":ENGINE_SHA,
       "dimensions":17,"native":True,"parent_stage07_sha":PARENT_SHA,
       "seeds":seeds,"normal":[],"mutants":[],"masking":[]}
    for seed in seeds:
        result=native(engine,raw,seed,20)
        need(result["exit"]==0 and result["numbers"]==expected(seed),
             "Native cooperative split-IP failed seed "+str(seed)+": "+repr(result))
        obs={"seed":seed,"worker_residue":result["numbers"][0],
             "generated_bytecode":[result["numbers"][i:i+3] for i in range(1,65,4)],
             "axis_witnesses":[result["numbers"][i] for i in range(4,65,4)],
             "final_checksum":result["numbers"][-1]}
        receipt["normal"].append(obs)
        print("NATIVE_ND17_CONCURRENT_NESTED_STACK_PASS",seed,
              "worker_residue",obs["worker_residue"],"axes",obs["axis_witnesses"])

    masked=mutate_traps(raw)
    for seed in seeds:
        result=native(engine,masked,seed,20)
        need(result["exit"]==0 and result["numbers"]==expected(seed),
             "Native worker-to-future-code masking failed "+str(seed)+repr(result))
        receipt["masking"].append({"seed":seed,"masked_source_bytes":48,"identical_output":True})
        print("NATIVE_ND17_SHARED_48_TRAP_MASK_PASS",seed)

    # Native split, genuine pair of nested stack frames, and 17D worker p/g
    # must cause a detectable output/termination difference if sabotaged.
    worker_mutations=[
       ("fork_suppressed","fork","t","z"),
       ("outer_stack_begin_suppressed","worker","0{0{","0z0{"),
       ("inner_stack_begin_suppressed","worker","0{0{","0{0z"),
       ("understack_transfer_suppressed","worker","01-u1u","01-zu1"),
       ("worker_residue_corrupted","worker","2/","3/"),
       ("worker_gate_corrupted","worker",decimal(31)+"+1}",decimal(32)+"+1}"),
    ]
    for label,which,old,new in worker_mutations:
        if which=="fork":
            bad=patch_one(raw,lambda b:b["header"].startswith("Lines 1,Origin 0:0,"),
                          old,new)
        else:
            bad=mutate_worker(raw,old,new)
        seed=seeds[0]
        result=native(engine,bad,seed,3)
        altered=result["exit"]!=0 or result["numbers"]!=expected(seed)
        need(altered,"Fork/stack/residue corruption was causally inert "+label)
        receipt["mutants"].append({"name":label,"seed":seed,"exit":result["exit"],
           "changed":altered,"timeout":result["timeout"]})
        print("NATIVE_ND17_SHARED_CAUSAL_SABOTAGE",label,result["exit"],altered)

    for stage in manifest["stages"]:
        bad,new=mutate_axis(raw,stage)
        seed=seeds[(stage["axis"]-1)%2]
        result=native(engine,bad,seed,3)
        altered=result["exit"]!=0 or result["numbers"]!=expected(seed)
        need(altered,"Dimensional residue mutation inert: "+str(stage["axis"]))
        receipt["mutants"].append({"name":"stage_%02d"%stage["axis"],
             "axis":stage["axis"],"seed":seed,"replacement":new,
             "exit":result["exit"],"changed":altered,"timeout":result["timeout"]})
        print("NATIVE_ND17_FORK_STAGE_SABOTAGE",stage["axis"],result["exit"],altered)

    RECEIPT.write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_ND17_SPLIT_IP_NESTED_STACK_REJOIN_AND_FUTURE_CODE_PASS")

if __name__=="__main__":
    main()
