#!/usr/bin/env python3
"""New normative 55/56 dependency gate. Historical fixtures are reused only
for physical heap allocation and raw-cell assertions, with independent oracles.
No historical receipt or Stage23 acceptance is altered."""
import itertools
import json
import os
from pathlib import Path
import random
import subprocess
import sys
import stage21_native_diagnostic as d21
import stage22_native_diagnostic as d22

M = (1 << 127) - 1
P = tuple(itertools.permutations(range(6)))
E = Path("evidence/normative_bowls")
REF = "3e9acc012bedf83294a6ec3cccb081a069556b5b"
RT = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
AUX_NEW = b"p;3>[z;b:0a;!b;0h;!!f:]?"
AUX_OLD = b"p;3>[z;b:2a;!b;0h;!!f:]?"
OFFSET = b"  z;b:6a;!b;0h;!!v:\n  z;b:s;a;!v;a;!b;9h;!!s:\n"
OFFSET_ANCHOR = b"  z;b:i;a;!b;0h;!!v:\n  z;b:v;a;!149a;!b;23h;!!v:"
RANK_NEW = b"  z;b:1a;!b;0h;!!v:\n  z;b:t;a;!v;a;!b;10h;!!n:\n  z;b:720a;!b;0h;!!v:\n  z;b:n;a;!v;a;!b;16h;!!n:\n  z;b:n;a;!0a;!b;3h;!!r:\n  r;1+r:"
RANK_OLD = RANK_NEW.replace(b"1a;", b"4a;", 1).replace(b"720a;", b"7a;").replace(b"r;1+r:", b"r;4+r:")
ANCHOR = b"1i:\n [i;47<][\n  w;i;+g;!t:"
FILES = ("src/bigint.false", "src/monster_bootstrap.false", "test/normative_reference.false",
         "tools/stage21_native_diagnostic.py", "tools/stage22_native_diagnostic.py",
         "tools/normative_bowls_native.py", ".github/workflows/false-arabic-normative-bowls.yml")

def save(n):
    assert n > 0
    rem = n % M
    return rem if rem else M

def visible(q, steps, old_aux=False):
    b, drops, stones = q
    for u in range(1, steps + 1):
        t = drops[u-1]
        s = stones[u-1]
        order = P[(t-1) % 720]
        nxt = []
        for j,x in enumerate(b):
            p = order.index(j) + 1
            l = b[order[(p-2) % 6]]
            r = b[order[p % 6]]
            a = save(t*t + x*s[p-1] + u*(2*p+1)) if p <= 3 else (2 if old_aux else 0)
            nxt.append(save(x*x + 2*l + 3*r + a + t + s[(p-1) % 5] + 5*l*r + u*p))
        b = nxt
    return b, [j+1 for j in order]

def batch(initial, steps, offset=False, old_rank=False):
    b = list(initial)
    trace = []
    for u in range(1, steps+1):
        t = save(sum(b) + 149*u + (6 if offset else 0))
        rank = 4 + (t-4) % 7 if old_rank else 1 + (t-1) % 720
        order = P[rank-1]
        nxt = []
        for j,x in enumerate(b):
            p = order.index(j)+1
            l,r = b[order[(p-2)%6]], b[order[p%6]]
            nxt.append(save(x*x + 3*l + 5*r + t + u + p*p + 7*l*r))
        b = nxt
        trace.append({"batch":u,"total":str(t),"rank":rank,"order":[j+1 for j in order],"bowls":list(map(str,b))})
    return b, trace

def replace_once(data, old, new):
    assert data.count(old) == 1 and old != new, old
    return data.replace(old,new,1)

def instrument21(src, steps):
    if steps == 46:
        return src
    assert 1 <= steps < 46
    return replace_once(src, ANCHOR, ANCHOR.replace(b"47<",str(steps+1).encode()+b"<"))

def marker(stage, good, bad, limbs):
    for j,(a,b) in enumerate(zip(good,bad),1):
        for k,(x,y) in enumerate(zip(limbs(a),limbs(b))):
            if x != y:
                assert k >= 2, (stage,j,k,a,b)
                return f"STAGE{stage}_OUT_BOWL_{j}_CELL_{k}_FAIL"
    raise AssertionError("mutant has no numeric witness")

def math_check():
    w = [2,3,5,7,11,13]
    assert batch(w,1)[0] == [510,340,1327,591,432,660]
    assert batch(w,1)[1][0]["rank"] == 190
    assert batch(w,1,True,True)[0] == [529,349,853,394,878,599]
    assert batch([566,1,1,1,1,1],1)[1][0]["rank"] == 720
    assert batch([567,1,1,1,1,1],1)[1][0]["rank"] == 1
    assert batch([M-153,1,1,1,1,1],1)[1][0]["total"] == "1"
    assert save(M)==M and save(M+1)==1
    assert visible(d21.case("ones"),1)[0] == [19,22,25,17,18,19]
    rng = random.Random(20261127)
    for _ in range(384):
        b = [rng.randrange(1,M+1) for _ in range(6)]
        out,trace = batch(b,1)
        t = int(trace[0]["total"])
        assert 1<=t<=M and (t-sum(b)-149)%M == 0
        rank = trace[0]["rank"]
        assert 1<=rank<=720 and (rank-t)%720 == 0
        assert len(set(trace[0]["order"]))==6 and all(1<=v<=M for v in out)
    # Exhaust the full rank space, including the two wrap endpoints.
    for rank in range(1,721):
        assert batch([rank+566,1,1,1,1,1],1)[1][0]["rank"] == rank
    return {"random_batch_properties":384,"rank_space":720,"stage_acceptance":False}

def main():
    design = math_check()
    print(json.dumps(design))
    if "--math-only" in sys.argv:
        return
    E.mkdir(parents=True,exist_ok=True)
    pin = os.environ["SOURCE_PIN"]
    assert os.environ["RUNTIME_PIN"] == RT
    assert subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()==pin
    assert subprocess.check_output(["git","rev-parse",pin+":test/normative_reference.false"],text=True).strip()==REF
    assert (E/"runtime_observed.txt").read_text().strip()==RT
    for f in FILES:
        data = Path(f).read_bytes()
        assert data==subprocess.check_output(["git","show",pin+":"+f])
        dest=E/"source"/f
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(data)
    src=Path("src/monster_bootstrap.false").read_bytes()
    big=Path("src/bigint.false").read_bytes()
    assert src.count(AUX_NEW)==src.count(RANK_NEW)==src.count(OFFSET_ANCHOR)==1
    assert AUX_OLD not in src and RANK_OLD not in src and OFFSET not in src
    # Reuse only fixture encoding and assertion generation, not old expected values.
    d21.oracle=visible
    d22.oracle=batch
    d22.E=E
    rows=[]
    def persist():
        report={"project_id":"PC-BRANCH-FALSE-ARABIC","source_pin":pin,"runtime_pin":RT,
                "reference_blob":REF,"design":design,"cases":rows,
                "native_gate_pass":len(rows)==15 and all(x["passed"] for x in rows),
                "independent_artifact_audit":False,"stage_acceptance":False}
        (E/"receipt.json").write_text(json.dumps(report,indent=2)+"\n")
    def run(stage,label,q,steps,source=src,negative=None):
        if stage==21:
            body,expected,checks=d21.fixture(q,steps)
            source=instrument21(source,steps)
            want=d21.MARKER
        else:
            body,expected,checks,_=d22.fixture(q,steps)
            source=d22.instrument(source,steps)
            want=d22.MARKER
        assert checks>30
        program=big+b"\n"+source+b"\n"+body.encode()
        observation=d22.execute(label,program,600,negative or want,1 if negative else 0)
        rows.append({"name":label,"stage":stage,"steps":steps,"input":q,
                     "expected":expected,"assertions":checks,"negative":negative,**observation})
        persist()
    persist()
    for name,steps in (("ones",1),("reverse",1),("reverse",46),("boundary",46),("boundary",23)):
        run(21,f"visible_{name}_{steps}",d21.case(name),steps)
    q=d21.case("reverse")
    bad=marker(21,visible(q,1)[0],visible(q,1,True)[0],d21.limbs)
    run(21,"old_auxiliary",q,1,replace_once(src,AUX_NEW,AUX_OLD),bad)
    for name,q,steps in (("witness",[2,3,5,7,11,13],1),("witness_full",[2,3,5,7,11,13],12),
                         ("ones",[1]*6,12),("boundary",d22.case("boundary"),12),
                         ("rank720",[566,1,1,1,1,1],1),("rank1",[567,1,1,1,1,1],1),
                         ("save_wrap",[M-153,1,1,1,1,1],1)):
        run(22,"batch_"+name,q,steps)
    q=[20,30,50,70,110,130]
    for label,modified,wrong in (
        ("old_offset",replace_once(src,OFFSET_ANCHOR,OFFSET+OFFSET_ANCHOR),batch(q,1,offset=True)[0]),
        ("old_rank",replace_once(src,RANK_NEW,RANK_OLD),batch(q,1,old_rank=True)[0])):
        bad=marker(22,batch(q,1)[0],wrong,d22.limbs)
        run(22,label,q,1,modified,bad)
    assert len(rows)==15
    print(json.dumps({"cases":len(rows),"passed":sum(r["passed"] for r in rows)}))
    if not all(r["passed"] for r in rows):
        raise SystemExit(1)

if __name__=="__main__":
    main()
