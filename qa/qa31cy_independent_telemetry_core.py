#!/usr/bin/env python3
"""QA31CY v2 independent finite audit core. No PyFunge imports.

Checks source/receipt pins, sparse memory, logical operands, intermediate x/j,
block offsets, physical trace continuity and scanner geometry. Deliberately
NOT a full VM, corpus reconciliation, or Stage1 acceptance. Unsupported
mutation paths fail closed. Run selftest before any real trace audit.
"""
import argparse
import gzip
import hashlib
import json
from collections import Counter
from pathlib import Path

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
RUNTIME = "e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac"

def need(ok, msg):
    if not ok:
        raise ValueError(msg)

def xy(v):
    need(isinstance(v, (list, tuple)) and len(v) == 2
         and all(type(i) is int for i in v), "invalid vector")
    return tuple(v)

def add(a, b):
    return tuple(x+y for x,y in zip(a,b))

def scale(a, n):
    return tuple(x*n for x in a)

def inside(p, lo, hi):
    return all(a <= x <= b for x,a,b in zip(p,lo,hi))

def wrap(p, d, lo, hi):
    # Maximal integer reverse displacement on the original ray. The pinned
    # runtime may return an outside point for a ray missing the rectangle.
    if inside(p, lo, hi):
        return p
    upper = [(x-a)//v if v>0 else (b-x)//(-v)
             for x,v,a,b in zip(p,d,lo,hi) if v]
    need(bool(upper), "zero-delta outside rectangle")
    return add(p, scale(d, -min(upper)))

def pop(s, queue):
    return s.pop(0 if queue else -1) if s else 0

def popvec(s, queue):
    y = pop(s, queue)
    x = pop(s, queue)
    return (x,y)

def push(s, v, invert):
    s.insert(0,v) if invert else s.append(v)

def scan(mem, p, d, value, until, lo, hi):
    seen = set()
    wraps = []
    while (mem.get(p,32) != value) if until else (mem.get(p,32) == value):
        need(p not in seen and len(seen)<2000000, "scan cycle/bound")
        seen.add(p)
        q = add(p,d)
        if not inside(q,lo,hi):
            p = wrap(q,d,lo,hi)
            wraps.append((q,d,p))
        else:
            p = q
    return p, wraps

def source(raw):
    need(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()==PIN,
         "production blob mismatch")
    lines=raw.replace(b"\f",b"").splitlines()
    need(bool(lines), "empty source")
    mem={(x,y):v for y,line in enumerate(lines) for x,v in enumerate(line) if v!=32}
    return mem, [(0,0),(max(map(len,lines))-1,len(lines)-1),True]

def bounds(b):
    need(len(b)==3 and type(b[2]) is bool,"invalid bounds")
    return [xy(b[0]),xy(b[1]),b[2]]

def state(s):
    need(len(s)==6 and all(type(v) is bool for v in s[3:]),"bad IP")
    return [xy(s[0]),xy(s[1]),xy(s[2]),*s[3:]]

def command(op, pre, after, stack, result, events):
    """Local transition oracle. Inputs are snapshots, not independent lineage."""
    s=list(stack)
    p,d,o,sm,q,inv=pre
    target=None
    if op in ("p","g"):
        target=add(popvec(s,q),o)
        if op=="p":
            val=pop(s,q)
            puts=[e for e in events if e[0]=="put"]
            need(len(puts)==1 and xy(puts[0][1])==target and puts[0][2]==val,"p operand")
        else:
            gets=[e for e in events if e[0]=="get"]
            need(len(gets)==1 and xy(gets[0][1])==target,"g operand")
            push(s,gets[0][2],inv)
    elif op=="x":
        d=popvec(s,q)
    elif op=="j":
        n=pop(s,q)
        norms=[e for e in events if e[0]=="normalize"]
        need(len(norms)==1 and xy(norms[0][1])==add(p,scale(d,n))
             and xy(norms[0][2])==d,"j operand")
        p=xy(norms[0][4])
    else:
        raise ValueError("unsupported local opcode")
    need(after==[p,d,o,sm,q,inv] and s==result,"local command post-state")
    return target

def audit(raw, trace, receipt, head):
    mem,b=source(raw)
    # Initial notifyrect sets dirty even if source has trailing blanks.
    need(receipt["schema"]=="qa31cy-production-telemetry-v2" and
         receipt["source"]==PIN and receipt["runtime"]==RUNTIME and
         receipt["head"]==head and receipt["stage1_accepted"] is False,"receipt pin")
    with open(trace,"rb") as f:
        need(hashlib.file_digest(f,"sha256").hexdigest()==receipt["trace_sha256"],"trace digest")
    counts=Counter()
    owners=set()
    prev=None
    tick=0
    with gzip.open(trace,"rt",encoding="ascii") as f:
        for line in f:
            t,pre,opcode,events,post=json.loads(line)
            need(t==tick+1 and t<=750000,"tick order/bound")
            tick=t
            pre=state(pre)
            if t==1:
                need(pre==[(0,0),(1,0),(0,0),False,False,False],"initial state")
            else:
                need(pre==prev,"physical continuity")
            need(mem.get(pre[0],32)==opcode,"source fetch")
            frames=[]
            pending_put=None
            pending_wraps=[]
            offset=pre[2]
            for i,e in enumerate(events):
                typ=e[0]
                counts[typ]+=1
                if typ=="command":
                    op=e[1]
                    st=state(e[2])
                    need(st[2]==offset,"command offset")
                    frames.append((i,e))
                elif typ=="return":
                    need(bool(frames),"orphan return")
                    start,c=frames.pop()
                    need(c[1]==e[1],"dispatch nesting")
                    op=e[1]
                    a,z=state(c[2]),state(e[2])
                    segment=events[start+1:i]
                    if op in "pgxj":
                        need(c[4]==e[4],"frame count")
                        target=command(op,a,z,c[3],e[3],segment)
                        if op=="p":
                            owners.add((a[0],target))
                        if op=="j":
                            need(len(pending_wraps)==1,"j normalize event missing")
                            pending_wraps=[]
                    elif op=="{":
                        need(c[5] is not None and e[5] is not None and
                             len(e[5])==len(c[5])+1 and z[2]==add(a[0],a[1]),"begin block offset")
                        offset=z[2]
                    elif op=="}":
                        need(c[5] is not None and e[5] is not None,"end block snapshots")
                        if len(c[5])<2:
                            need(z[2]==a[2],"end block underflow offset")
                        else:
                            s=list(c[5][-2])
                            need(z[2]==popvec(s,a[4]) and len(e[5])==len(c[5])-1,"end block offset")
                        offset=z[2]
                    elif op=="k":
                        need(z[2]==offset,"nested offset")
                    else:
                        raise ValueError("unclassified command")
                elif typ=="put":
                    need(pending_put is None and frames and frames[-1][1][1]=="p",
                         "unsupported mutation path")
                    p,v=xy(e[1]),e[2]
                    need(mem.get(p,32)==e[3] and bounds(e[4])==b,"put before")
                    pending_put=[p,v,p in mem,False]
                elif typ in ("dict_set","dict_del"):
                    p=xy(e[1])
                    need(pending_put is not None and p==pending_put[0] and
                         not pending_put[3] and mem.get(p,32)==e[2],"unowned dictionary mutation")
                    v,existed=pending_put[1:3]
                    if typ=="dict_set":
                        need(v!=32 and e[3]==v,"dictionary set value")
                        mem[p]=v
                        if not existed:
                            lo=tuple(min(x,y) for x,y in zip(b[0],p))
                            hi=tuple(max(x,y) for x,y in zip(b[1],p))
                            b=[lo,hi,b[2] or lo!=b[0] or hi!=b[1]]
                    else:
                        need(v==32 and e[3]==existed,"dictionary delete value")
                        mem.pop(p,None)
                        b[2]=b[2] or existed
                    pending_put[3]=True
                elif typ=="put_after":
                    need(pending_put is not None and pending_put[3] and
                         xy(e[1])==pending_put[0] and e[2]==pending_put[1] and
                         mem.get(xy(e[1]),32)==e[2] and bounds(e[3])==b,"put after")
                    pending_put=None
                elif typ=="get":
                    need(mem.get(xy(e[1]),32)==e[2],"get value")
                elif typ=="normalize":
                    p,d=xy(e[1]),xy(e[2])
                    need(bounds(e[3])==b and wrap(p,d,*b[:2])==xy(e[4]),"normalize")
                    pending_wraps.append((p,d,xy(e[4])))
                elif typ in ("scanwhile","scanuntil"):
                    need(bounds(e[4])==b,"scan bounds")
                    endpoint,steps=scan(mem,xy(e[1]),xy(e[2]),e[3],typ=="scanuntil",*b[:2])
                    need(endpoint==xy(e[5]) and steps==pending_wraps,"scan endpoint/wrap sequence")
                    pending_wraps=[]
                elif typ=="getrect":
                    need(bounds(e[1])==b,"getrect before")
                    if b[2]:
                        need(bool(mem),"empty getrect")
                        b=[tuple(min(p[i] for p in mem) for i in (0,1)),
                           tuple(max(p[i] for p in mem) for i in (0,1)),False]
                    need(bounds(e[2])==b and [xy(v) for v in e[3]]==b[:2],"getrect result")
                else:
                    raise ValueError("unsupported event "+typ)
            need(not frames and pending_put is None and not pending_wraps,"unclosed events")
            if not pre[3] and chr(opcode) in "pgxj{}k":
                need(bool(events) and events[0][0]=="command" and events[0][1]==chr(opcode),
                     "missing direct dispatch")
            prev=state(post) if post is not None else None
            if prev is not None:
                need(prev[2]==offset,"unexplained offset transition")
            else:
                need(t==receipt["ticks"],"premature halt")
    need(tick==receipt["ticks"] and tick>0 and prev is None,"halt/length")
    need(dict(counts)==receipt["event_counts"],"event counts")
    return {"ticks":tick,"counts":dict(counts),"owners":[[list(a),list(b)] for a,b in sorted(owners)],
            "scope":"local operands, sparse memory, scan/wrap, offsets; NOT full successor/corpus proof",
            "stage1_accepted":False}

def selftest():
    n=0
    def check(ok):
        nonlocal n
        need(ok,"synthetic positive control")
        n+=1
    check(wrap((6,2),(1,0),(0,0),(5,5))==(0,2))
    check(wrap((-1,2),(-1,0),(0,0),(5,5))==(5,2))
    check(wrap((7,7),(2,2),(0,0),(5,5))==(1,1))
    check(wrap((2,2),(0,0),(0,0),(5,5))==(2,2))
    check(scan({(1,0):65},(2,0),(1,0),32,False,(0,0),(2,0))==
          ((1,0),[((3,0),(1,0),(0,0))]))
    for q in (False,True):
        s=[5,7]
        check(popvec(s,q)==((7,5) if q else (5,7)) and not s)
        s=[5]
        check(popvec(s,q)==(0,5) and not s)
    a=[(1,2),(1,0),(3,4),False,False,False]
    check(command("p",a,a,[9,2,1],[],[["put",[5,5],9]])==(5,5))
    check(command("g",a,a,[2,1],[8],[["get",[5,5],8]])==(5,5))
    check(command("x",a,[(1,2),(2,1),(3,4),False,False,False],[2,1],[],[]) is None)
    hostile=0
    for call in (
        lambda:wrap((8,8),(0,0),(0,0),(5,5)),
        lambda:scan({},(0,0),(1,0),32,False,(0,0),(2,0)),
        lambda:command("p",a,a,[9,2,1],[],[["put",[6,5],9]]),
        lambda:command("g",a,a,[2,1],[9],[["get",[5,5],8]]),
        lambda:command("x",a,a,[2,1],[],[]),
        lambda:command("j",a,a,[2],[],[["normalize",[2,2],[1,0],None,[1,2]]]),
    ):
        try: call()
        except ValueError: hostile+=1
        else: raise ValueError("hostile control survived")
    print(json.dumps({"synthetic_positive":n,"synthetic_hostile":hostile,"stage1_accepted":False}))

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("--selftest",action="store_true")
    p.add_argument("--source",type=Path)
    p.add_argument("--trace",type=Path)
    p.add_argument("--receipt",type=Path)
    p.add_argument("--head")
    a=p.parse_args()
    if a.selftest:
        selftest()
    else:
        need(all((a.source,a.trace,a.receipt,a.head)),"missing audit arguments")
        print(json.dumps(audit(a.source.read_bytes(),a.trace,json.loads(a.receipt.read_text()),a.head),sort_keys=True))
