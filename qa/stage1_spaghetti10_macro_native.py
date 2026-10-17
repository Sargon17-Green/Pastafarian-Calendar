#!/usr/bin/env python3
"""Native QA10 17D macro compiler: 208 genuine future instructions, two residue workers."""
from __future__ import annotations
import hashlib,json,subprocess,tempfile
from pathlib import Path

SOURCE=Path("qa/spaghetti10_17d_dual_worker_macro_candidate.beq")
MANIFEST=Path("qa/SPAGHETTI10_17D_MACRO_MANIFEST.json")
SOURCE_BLOB="010efd012ae52a60740aa97750b5a02519912e92"
PARENT="275cec0add8705565d27da4233860bf42d134a27"
FIXTURE="e22a8b706fb84e3356db6c70aac29b9145642201"
ENGINE="third_party/funge-plus-plus/bin/funge"
EVIDENCE=Path("spaghetti10_native_macro_receipt.json")

def check(condition,msg):
    if not condition:raise AssertionError(msg)

def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()

def lines_and_panels(data):
    ls=data.decode("ascii").splitlines(True)
    check(ls[0]=="Version 1,Dimensions 17\n","Missing native BeQunge 17D header")
    check((len(ls)-1)%2==0,"Malformed 17D sparse-panel source")
    return ls,[(i,ls[i],ls[i+1].rstrip("\n")) for i in range(1,len(ls),2)]

def integer_literal(n):
    return format(n,"x") if n<=15 else "0"+"".join("a*"+x+"+" for x in str(n))

def addr(n):
    return integer_literal(n)+"0"*16

def expected(seed):
    out=[31,33]
    for axis in range(1,17):
        tri=axis*(axis+1)//2
        parity=(tri+seed)%2
        m=50+parity
        out.extend([48+10*parity,36,48+10*(1-parity),36,
                    m,42,m,47,58,36,58,36,62,axis])
    return out+[136*seed]

def native(data,seed,mode,timeout=20):
    with tempfile.TemporaryDirectory(prefix="qa10_native_") as p:
        spec=Path(p)/"native.beq";spec.write_bytes(data)
        args=[ENGINE,"-fconcurrent","-fthreads="+mode,
              "-fno-filesystem","-fno-execute",str(spec)]
        try:
            cp=subprocess.run(args,input=(str(seed)+"\n").encode("ascii"),
                  capture_output=True,timeout=timeout)
        except subprocess.TimeoutExpired as ex:
            return {"rc":124,"output":[],"timeout":True,
                    "stdout_len":len(ex.stdout or b""),"stderr":"bounded timeout"}
        try:
            values=[int(t) for t in cp.stdout.decode("utf-8","replace").split()]
        except ValueError:
            values=[]
        return {"rc":cp.returncode,"output":values,"timeout":False,
                "stdout_len":len(cp.stdout),
                "stderr":cp.stderr.decode("utf-8","replace")[-300:]}

def replace_one_panel(original,selector,old,new):
    lines,panels=lines_and_panels(original)
    found=[(i,s) for i,h,s in panels if selector(h,s)]
    check(len(found)==1,"Ambiguous Native mutation panel "+old)
    i,s=found[0]
    check(s.count(old)==1 and len(old)==len(new),
          "Non-unique or width-changing Native mutation "+old)
    lines[i+1]=s.replace(old,new,1)+"\n"
    return "".join(lines).encode("ascii")

def stage_mutant(data,step):
    axis=step["axis"]
    lines,panels=lines_and_panels(data)
    matching=[(i,s) for i,h,s in panels if h.startswith(
      "Lines 1,Origin %d:"%step["source_x"]) and len(s)>900]
    check(len(matching)==1,"No Native dimension source panel "+str(axis))
    index,src=matching[0]
    off=0
    if axis==1:
        off=len(addr(10001)+"g."+addr(10003)+"g."+"&:"+"0"*17+"p0")
    old=integer_literal(axis)
    new=integer_literal(axis+2 if axis<=13 or axis==16 else axis-2)
    check(len(old)==len(new) and src[off:off+len(old)]==old,
         "Native source contribution not found "+str(axis))
    lines[index+1]=src[:off]+new+src[off+len(old):]+"\n"
    return "".join(lines).encode("ascii")

def role_mutant(original,step,from_c,to_c):
    tri=step["axis"]*(step["axis"]+1)//2
    # Change exactly ONE compiler formula for one opcode role.
    shared=addr(10001)+"g"+integer_literal(31)+"-"+addr(10003)+"g"+integer_literal(33)+"-+"
    old=":"+integer_literal(tri)+"-"+shared+"+:*"+integer_literal(from_c)+"+"
    new=":"+integer_literal(tri)+"-"+shared+"+:*"+integer_literal(to_c)+"+"
    # Some role values recur, so select the only occurrence by ordered target.
    ls,panels=lines_and_panels(original)
    matches=[(i,s) for i,h,s in panels if h.startswith("Lines 1,Origin %d:"%step["source_x"])
             and len(s)>900]
    check(len(matches)==1,"Role mutation stage missing")
    i,s=matches[0]
    check(s.count(old)>=1 and len(old)==len(new),"Role expression missing or width drift")
    ls[i+1]=s.replace(old,new,1)+"\n"
    return "".join(ls).encode("ascii")

def main():
    original=SOURCE.read_bytes()
    check(gitblob(original)==SOURCE_BLOB,"QA10 physical source SHA drift")
    meta=json.loads(MANIFEST.read_text("utf-8"))
    check(meta["source_parent_blob"]==PARENT and
          meta["fixture_parent_blob"]==FIXTURE,"Previous Native QA provenance lost")
    check(meta["dimension_count"]==17 and meta["generated_opcode_count"]==208
          and meta["generated_opcodes_per_axis"]==13
          and meta["source_bytes"]==len(original) and len(meta["stages"])==16,
          "False QA10 17-dimensional source manifest")
    ls,panels=lines_and_panels(original)
    traps=[(i,h,s) for i,h,s in panels if s=="@"]
    check(len(traps)==208 and len(panels)==236,"Wrong 208 future code sites")

    # Every operand assembly expression must be truly tied to both workers.
    shared=addr(10001)+"g"+integer_literal(31)+"-"+addr(10003)+"g"+integer_literal(33)+"-+"
    for step in meta["stages"]:
        source=[s for i,h,s in panels if h.startswith("Lines 1,Origin %d:"%step["source_x"])
                and len(s)>900]
        check(len(source)==1 and source[0].count(shared+"+")==13,
              "Not every future code byte depends on both historical residues")
        check(len(step["target_positions"])==13 and
              all(len(v)==17 for v in step["target_positions"]),
              "Incorrect 17D physical target sites")

    prior=json.loads(Path("spaghetti09_nd17_native_receipt.json").read_text("utf-8"))
    check(prior["source_blob"]==PARENT and len(prior["valid_runs"])==12,
          "Missing fresh successful QA09 patched Native parent proof")
    receipt={"schema":"qa10-native-17d-208-runtime-macro-v1",
             "source_blob":SOURCE_BLOB,"parent_blob":PARENT,
             "patched_upstream_engine":True,
             "native":True,"generated_instruction_count":208,
             "healthy_runs":[],"masking":[],"mutants":[]}
    for mode in ("funge","native"):
        for seed in (1,2):
            for repetition in range(2):
                got=native(original,seed,mode,25)
                good=expected(seed)
                check(got["rc"]==0 and got["output"]==good,
                      "Native QA10 208 instruction mismatch "+repr((mode,seed,repetition,got)))
                receipt["healthy_runs"].append({
                    "mode":mode,"seed":seed,"repeat":repetition,
                    "numeric_count":len(good),
                    "output_sha256":hashlib.sha256(str(good).encode()).hexdigest()})
                print("QA10_NATIVE_208_OPCODE_PASS",mode,seed,repetition,
                      len(good),"checksum",good[-1],flush=True)

    masked=ls[:]
    for index,head,body in traps:masked[index+1]="q\n"
    masked_data="".join(masked).encode("ascii")
    for seed in (1,2):
        got=native(masked_data,seed,"funge",25)
        check(got["rc"]==0 and got["output"]==expected(seed),
              "QA10 future 208 source cells executed before generated overwrite "+str(seed))
        receipt["masking"].append({"seed":seed,"masked_bytes":208})
        print("QA10_NATIVE_208_TRAP_MASK_PASS",seed,flush=True)

    mutations=[
        ("fork_A",lambda h,s:h.startswith("Lines 1,Origin 0:0,"),"t","z"),
        ("fork_B",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),"t","z"),
        ("worker_B_understack",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),
            "u1u-10","u1uz10"),
        ("worker_B_residue",lambda h,s:h.startswith("Lines 1,Origin 1:0,"),
            "/2:","/3:"),
    ]
    for name,pred,a,b in mutations:
        corrupt=replace_one_panel(original,pred,a,b)
        got=native(corrupt,1,"funge",3)
        check(got["rc"]!=0 or got["output"]!=expected(1),"Inert worker mutation "+name)
        receipt["mutants"].append({"name":name,"rc":got["rc"],"timed_out":got["timeout"]})
        print("QA10_NATIVE_WORKER_MUTANT_RED",name,got["rc"],flush=True)
    for step in meta["stages"]:
        corrupt=stage_mutant(original,step)
        seed=1 if step["axis"]%2 else 2
        got=native(corrupt,seed,"funge",3)
        check(got["rc"]!=0 or got["output"]!=expected(seed),
              "Inert dimension contribution "+str(step["axis"]))
        receipt["mutants"].append({"axis":step["axis"],"rc":got["rc"],
                                   "timed_out":got["timeout"]})
        print("QA10_NATIVE_AXIS_MUTANT_RED",step["axis"],got["rc"],flush=True)
    for title,step,c,d in [
      ("destroy_multiply",meta["stages"][7],42,43),
      ("destroy_division",meta["stages"][7],47,37),
      ("destroy_stack_drop",meta["stages"][7],36,35),
      ("destroy_direction",meta["stages"][7],62,61),
    ]:
        corrupt=role_mutant(original,step,c,d)
        got=native(corrupt,1,"funge",3)
        check(got["rc"]!=0 or got["output"]!=expected(1),
              "Inert generated-instruction role mutation "+title)
        receipt["mutants"].append({"generated_role":title,"rc":got["rc"],
                                    "timed_out":got["timeout"]})
        print("QA10_NATIVE_EXECUTABLE_MACRO_MUTANT_RED",title,got["rc"],flush=True)

    EVIDENCE.write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("QA10_NATIVE_17D_208_BYTE_MACROS_AND_24_CAUSAL_MUTANTS_PASS",flush=True)

if __name__=="__main__":
    main()
