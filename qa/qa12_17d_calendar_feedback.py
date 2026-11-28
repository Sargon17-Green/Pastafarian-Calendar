"""Verify physical feedback from 208 previously executed code bytes into a 16-bit calendar-day query."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

from stage1_spaghetti11b_three_shard_native import expected as ancestor_output

ROOT=Path("qa")
PARENT=ROOT/"spaghetti11_17d_cascade_208_generated_candidate.beq"
SOURCE=ROOT/"spaghetti12_17d_calendar_feedback.beq"
MANIFEST=ROOT/"SPAGHETTI11B_THIRD_RESIDUE_MACRO_MANIFEST.json"
ENGINE="third_party/funge-plus-plus/bin/funge"
PARENT_SHA="afa261c6eab74d69b6c3afbe6c641fc130d627c0"
SOURCE_SHA="4249d4485dbe86aaf8b90ee3f32fe65429a72656"
TRIALS={"cooperative":[(1,0,"healthy"),(1,42405,"healthy"),(2,42405,"healthy")],
        "threads":[(1,42405,"mask"),(2,65535,"healthy")],
        "interventions":[(1,42405,"opposite"),(1,42405,"old-byte")]}


def require(ok,reason):
    if not ok:
        raise ValueError(reason)


def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()


def space(source):
    lines=source.decode("ascii").splitlines()
    require(lines[0]=="Version 1,Dimensions 17" and len(lines)%2==1,"BeQunge header")
    rows={}
    for head,code in zip(lines[1::2],lines[2::2]):
        match=re.fullmatch(r"Lines 1,Origin (-?\d+):(-?\d+),Coord ((?:-?\d+:){15})",head)
        pos=tuple(map(int,[match[1],match[2],*match[3][:-1].split(":")]))
        require(pos not in rows,"duplicate source panel")
        rows[pos]=code
    return rows


def sources():
    raw=SOURCE.read_bytes()
    parent=PARENT.read_bytes()
    require(blob(raw)==SOURCE_SHA and blob(parent)==PARENT_SHA,"source identity")
    old,new=space(parent),space(raw)
    tail=(51847,)+(13,)*16
    require(old[tail]=="*.@" and new[tail].startswith("*.&") and
            all(new[p]==v for p,v in old.items() if p!=tail),"ancestor source changed")
    meta=json.loads(MANIFEST.read_bytes())
    traps=[tuple(t) for s in meta["stages"] for t in s["target_positions"]]
    require(len(set(traps))==208 and all(old[p]=="@" for p in traps),"original executable cells")
    gates=[]
    pos=tail
    for axis in range(16,0,-1):
        row=new[pos]
        require(row.count("@:.")==1 and row.endswith("x"),"feedback gate placement")
        off=row.index("@:.")
        gates.append((pos[0]+off,*pos[1:]))
        jump=list(pos)
        jump[0]+=len(row)-1
        jump[axis]-=1
        pos=tuple(jump)
        require(new[pos].startswith(">"),"descent must continue on the next hyperplane")
    require(len(new)==len(old)+16 and new[pos].endswith("@"),"17D descent closure")
    return raw,traps,gates


def literal(n):
    return format(n,"x") if n<16 else str(n)[0]+"".join("a*"+c+"+" for c in str(n)[1:])


def change(raw,treatment,traps):
    if treatment=="healthy":
        return raw
    if treatment=="mask":
        require(raw.count(b"\n@\n")==208 and raw.count(b"g.@:.")==16,"mask inventory")
        return raw.replace(b"\n@\n",b"\nq\n").replace(b"g.@:.",b"g.q:.")
    lines=raw.decode("ascii").splitlines()
    index=[i for i,s in enumerate(lines) if "g.@:." in s][1]  # descending axis 15
    row=lines[index]
    if treatment=="opposite":
        before,after="z2*4a*3+","!2*4a*3+"
    elif treatment=="old-byte":
        def read(pos):
            return "".join(map(literal,pos))+"g5a*8+-!"
        before,after=read(traps[14*13]),read(traps[14*13+2])
    else:
        raise ValueError(treatment)
    require(row.count(before)==1 and len(before)==len(after),"intervention site")
    lines[index]=row.replace(before,after)
    result=("\n".join(lines)+"\n").encode()
    require(len(raw)==len(result) and sum(x!=y for x,y in zip(raw,result))==1,"single changed source byte")
    return result


def modeled(seed,day,treatment):
    prefix=0
    previous_minus=0
    emitted=[]
    for axis in range(16,0,-1):
        original_bit=(axis*(axis+1)//2+seed)%2
        if axis==15 and treatment=="old-byte":
            original_bit^=1
        minus=(original_bit+previous_minus+(prefix%2))%2
        bit=(day>>(axis-1))&1
        encoded=bit^minus
        actual_minus=minus^int(axis==15 and treatment=="opposite")
        prefix=2*prefix+minus+(-encoded if actual_minus else encoded)
        emitted.extend([45 if actual_minus else 43,prefix])
        previous_minus=actual_minus
    return emitted,prefix


def validate(group,rows,require_reference):
    raw,traps,gates=sources()
    require(len(rows)==len(TRIALS[group]),"missing experiment")
    for row,(seed,day,treatment) in zip(rows,TRIALS[group]):
        actual_source=change(raw,treatment,traps)
        require([row["seed"],row["day"],row["treatment"]]==[seed,day,treatment] and
                row["mode"]==("native" if group=="threads" else "funge") and row["source_blob"]==blob(actual_source),
                "experiment identity")
        older=ancestor_output(seed)
        expected,prefix=modeled(seed,day,treatment)
        out=row["stdout"]
        require(row["exit"]==0 and out[:228]==older and len(out)==262 and out[228:-2]==expected and
                out[-2]==prefix,"wrong original code, emitted instructions, arithmetic or termination")
        require(row["writes"]==[[list(p),n] for p,n in
                zip(traps,[older[3+i*14+j] for i in range(16) for j in range(13)])]+
                [[list(p),n] for p,n in zip(gates,expected[::2])],"224 full 17D physical puts in causal order")
        require(out[-1]==2*(15055671+prefix)+1,"wrong calendar output")
        if require_reference:
            require(row["native_befunge_day_count"]==out[-1] and
                    row["native_reference_blob"]=="9560cc28f77e37ac9b0b9ba4c677a484745b5d89",
                    "independent native calendar reference")
        if treatment=="opposite":
            require(prefix==75173 and prefix!=day,"forced arm must change the final day")
        else:
            require(prefix==day,"healthy calendar-day decoding")
        if treatment=="old-byte":
            normal,_=modeled(seed,day,"healthy")
            require(expected[::2][1:]!=normal[::2][1:] and
                    sum(a!=b for a,b in zip(expected[::2],normal[::2]))>=2,"no downstream history dependency")


def collect(group):
    raw,traps,_=sources()
    result=[]
    mode="native" if group=="threads" else "funge"
    for seed,day,treatment in TRIALS[group]:
        code=change(raw,treatment,traps)
        with tempfile.TemporaryDirectory(prefix="befunge-feedback-") as d:
            path=Path(d)/"probe.beq"
            path.write_bytes(code)
            run=subprocess.run([ENGINE,"-fconcurrent","-fthreads="+mode,"-fno-execute","-fno-filesystem",str(path)],
                               input=("%d\n%d\n"%(seed,day)).encode(),capture_output=True,timeout=235)
        writes=[]
        for line in run.stderr.decode("utf8","replace").splitlines():
            if line.startswith("QA11B_RUNTIME_PUT:"):
                values=list(map(int,line.split(":")[1:]))
                require(len(values)==18,"incomplete physical write")
                writes.append([values[:-1],values[-1]])
        numbers=list(map(int,run.stdout.split()))
        result.append(dict(seed=seed,day=day,treatment=treatment,source_blob=blob(code),mode=mode,
                           exit=run.returncode,stdout=numbers,writes=writes))
        print("Funge++",mode,seed,day,treatment,run.returncode,len(writes),numbers[-6:],flush=True)
    return result


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("group",choices=TRIALS)
    p.add_argument("receipt",type=Path)
    p.add_argument("--audit",action="store_true")
    args=p.parse_args()
    if args.audit:
        rows=json.loads(args.receipt.read_bytes())
        validate(args.group,rows,True)
        for field in ("stdout","writes","native_befunge_day_count"):
            bad=copy.deepcopy(rows)
            if field=="stdout": bad[0][field][230]+=1
            elif field=="writes": bad[0][field][-1][0][16]+=1
            else: bad[0][field]+=1
            try: validate(args.group,bad,True)
            except ValueError: continue
            raise ValueError("accepted forged "+field)
    else:
        rows=collect(args.group)
        args.receipt.write_text(json.dumps(rows,separators=(",",":"))+"\n")
        validate(args.group,rows,False)
    print("QA12_17D_CALENDAR_FEEDBACK_PASS",args.group,len(rows),"runs",224,"physical writes per run")
