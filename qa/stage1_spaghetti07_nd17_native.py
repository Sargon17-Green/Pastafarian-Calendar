#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""QA07 source-pin, native 17D Funge++, and causal-falsification test."""
from __future__ import annotations
import argparse,hashlib,json,subprocess,tempfile
from pathlib import Path

D=17
BLOB="4c9bff056cb61004d37dd2d949fccf171b4ddf0f"
PARENT="d89c0499f9e006eb62cd5876bd297085265435d6"
ENGINE="cd6d7f005b4fc33b486fcc2380b35406f6125ca4"
BEQ=Path("qa/spaghetti07_17d_residue_mesh.beq")
MANIFEST=Path("qa/SPAGHETTI07_ND17_MANIFEST.json")
RECEIPT=Path("spaghetti07_nd17_native_receipt.json")

def need(flag,message):
    if not flag:raise AssertionError(message)

def dec(n,width=0):
    return "0"+"".join("a*"+d+"+" for d in str(n).zfill(width))

def lit(n):
    return format(n,"x") if n<=15 else dec(n)

def generate(alter=None,trap="@"):
    alter=alter or {}
    need(len(trap)==1,"Expected one-byte source trap")
    pos=[0]*D;x=0;panels=[];traps=[];stages=[]
    for axis in range(1,D):
        pre="&:"+"0"*D+"p0" if axis==1 else ""
        t=axis*(axis+1)//2
        ops=[":"+"0"*D+"g+2%a*68*+",
             ":"+lit(t)+"-:*66*+",":"+lit(t)+"-:*88*2-+"]
        contrib=lit(alter.get(axis,axis))
        need(len(contrib)==len(lit(axis)),"Mutation changes source length")
        end=lit(axis)+"."+lit(axis)+"Z"
        n=len(pre)+len(contrib)+1+sum(map(len,ops))+3*(2*(17+16+1)+1)+len(end)
        tx=x+n-1
        s=pre+contrib+"+";targets=[]
        for j in range(3):
            vec=pos.copy();vec[0]=tx
            for d in range(1,axis):vec[d]=3
            vec[axis]=j+1
            arg=dec(tx,4)+"".join(map(str,vec[1:]))
            need(len(arg)==33,"Bad native coordinate vector encoding")
            s+=ops[j]+arg+"p"+arg+"g."
            targets.append(vec.copy());traps.append((vec.copy(),trap))
        s+=end
        need(len(s)==n,"Bad panel layout")
        panels.append((pos.copy(),s))
        stages.append({"axis":axis,"source_x":x,"contribution_x":x+len(pre),
                       "target_x":tx,"target_coordinates":targets})
        pos=targets[2].copy();pos[0]=tx+1;x=tx+1
    panels.append((pos.copy(),"*.@"))
    out=["Version 1,Dimensions 17\n"]
    for vec,s in panels+traps:
        out.append("Lines 1,Origin %d:%d,Coord %s:\n"%(vec[0],vec[1],":".join(map(str,vec[2:]))))
        out.append(s+"\n")
    return "".join(out).encode("ascii"),panels,traps,stages

def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()

def seed_values(receipt_file):
    j=json.loads(receipt_file.read_text(encoding="utf-8"))
    need(j["qa_only"] and not j["production_modified"] and j["candidate_sha"]==PARENT,
         "Source-pinned Native QA06 provenance missing")
    valid=[r for r in j["cases"] if r.get("valid")]
    need(len(valid)==4,"Expected four native QA06 inputs")
    got=sorted(int(r["compiler"]["stamp"]) for r in valid)
    need(got==[1,1,2,2],"QA06 Native two-branch witness absent")
    return [1,2],got

def expected(seed):
    result=[]
    for axis in range(1,D):
        tri=axis*(axis+1)//2
        result.extend([48+10*((tri+seed)%2),36,62,axis])
    return result+[136*seed]

def native(engine,path,seed,timeout=8):
    try:
        cp=subprocess.run([str(engine),str(path)],input=str(seed)+"\n",
              text=True,capture_output=True,timeout=timeout)
        try: numbers=[int(s) for s in cp.stdout.split()]
        except ValueError:numbers=[]
        return {"exit":cp.returncode,"numbers":numbers,
                "stderr":cp.stderr[-500:],"timeout":False}
    except subprocess.TimeoutExpired:
        return {"exit":124,"numbers":[],"stderr":"timeout","timeout":True}

def native_mut(engine,data,seed,timeout=3):
    with tempfile.TemporaryDirectory(prefix="nd17_") as d:
        f=Path(d)/"mutant.beq";f.write_bytes(data)
        return native(engine,f,seed,timeout)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--engine",required=True,type=Path)
    parser.add_argument("--qa06-receipt",type=Path,default=Path("spaghetti06_native_receipt.json"))
    args=parser.parse_args()
    engine=args.engine.resolve()
    need(engine.is_file(),"Funge++ native engine missing")
    data=BEQ.read_bytes()
    need(gitblob(data)==BLOB,"17D specimen git blob mismatch")
    built,panels,traps,stages=generate()
    need(built==data,"BeQunge specimen is not reproducible")
    manifest=json.loads(MANIFEST.read_text(encoding="utf-8"))
    need(manifest["dimensions"]==D and manifest["generated_instruction_traps"]==48
         and manifest["source_panels"]==17 and manifest["source_length"]==len(data)
         and manifest["engine"]["sha"]==ENGINE,
         "17D manifest malformed")
    need(all(len(v)==D for v,_ in panels+traps),"Source is not genuinely 17D")
    seeds,prior=seed_values(args.qa06_receipt)
    receipt={"schema":"stage07-17d-native-v1","engine_sha":ENGINE,
        "candidate_blob":BLOB,"prior_qa06_blob":PARENT,
        "axes":list(range(D)),"dimensions":D,"prior_native_stamps":prior,
        "source_trap_count":48,"observations":[],"masking":[],"mutations":[]}
    for s in seeds:
        got=native(engine,BEQ,s,12)
        need(got["exit"]==0 and got["numbers"]==expected(s),
             "Wrong native 17D execution for stamp %d: %r"%(s,got))
        code=[got["numbers"][i:i+3] for i in range(0,64,4)]
        receipt["observations"].append({"seed":s,
            "runtime_emitted_opcodes":code,
            "axis_witnesses":got["numbers"][3:64:4],
            "normal_output":got["numbers"][-1]})
        print("NATIVE_ND17_SEED_PASS",s,"axes",got["numbers"][3:64:4],
              "opcodes",["".join(map(chr,a)) for a in code])
    masked,_,_,_=generate(trap="q")
    for s in seeds:
        got=native_mut(engine,masked,s,12)
        need(got["exit"]==0 and got["numbers"]==expected(s),
             "Static source traps were executed, not overwritten for stamp %d: %r"%(s,got))
        receipt["masking"].append({"seed":s,"source_traps_changed":48,"parity":True})
        print("NATIVE_ND17_48_ORIGINAL_TRAPS_MASKED_PASS",s)
    for axis in range(1,D):
        new=axis+2 if axis<=13 or axis==16 else axis-2
        changed,_,_,_=generate(alter={axis:new})
        s=seeds[(axis-1)%len(seeds)]
        got=native_mut(engine,changed,s,3)
        causal=got["exit"]!=0 or got["numbers"]!=expected(s)
        need(causal,"Native dimension %d operand mutation is inert"%axis)
        receipt["mutations"].append({"axis":axis,"seed":s,"from":axis,"to":new,
             "exit":got["exit"],"output_changed":got["numbers"]!=expected(s),
             "timeout":got["timeout"]})
        print("NATIVE_ND17_AXIS_SABOTAGE",axis,"rc",got["exit"],"changed",causal)
    RECEIPT.write_text(json.dumps(receipt,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_ND17_FORTY_EIGHT_EXECUTABLE_RECONSTRUCTIONS_PASS")

if __name__=="__main__":
    main()
