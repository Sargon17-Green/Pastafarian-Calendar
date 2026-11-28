"""Verify the signed-increment BF98 candidate as a local replacement on every reachable arithmetic route."""
import argparse
import json
from pathlib import Path

from qa31cf_independent_native_audit import PIN, git_blob
from qa31ch_scanner_induction import need
from qa31cm_kernel_equations import ARROWS, compose, constant, var

PATCH_PIN = "7418e1ec5fe88fe5c14b75710dea2d5607527f28"
START, LOAD5, JOIN = (959,1050),(960,1050),(961,1050)
GATE, PLUS, MINUS = (1020,1046),(1021,1046),(1020,1047)
EAST = (1,0)


def chamber(rows, sign, stale, force=False):
    previous, magnitude = var("previous sum"),var("strictly positive absolute increment")
    increment=sign*magnitude
    stack=[previous,increment]
    pos,delta=START,EAST
    writes, fetches, arms = [], [], []
    stored=stale
    def glyph(p):
        x,y=p
        need(958<=x<=1023 and 1045<=y<=1050, "left the arithmetic replacement")
        if p==GATE and stored is not None: return stored
        return rows[y][x] if x<len(rows[y]) else 32
    for tick in range(128):
        if pos==JOIN: break
        op=chr(glyph(pos))
        if pos==GATE:
            need(len(writes)==1 and not fetches, "gate was not rewritten before its first fetch")
            fetches.append(op)
            if force: op=">" if op=="v" else "v"
        if pos in (PLUS,MINUS): arms.append((pos,op))
        if op in "0123456789abcdef": stack.append(int(op,16))
        elif op in "+-*`":
            b,a=stack.pop(),stack.pop()
            if op=="+": z=a+b
            elif op=="-": z=a-b
            elif op=="*": z=a*b
            else:
                need(a==0 and b==increment,"predicate detached from actual signed increment")
                z=int(sign<0)
            stack.append(z)
        elif op==":": stack.append(stack[-1])
        elif op=="\\":
            stack[-1],stack[-2]=stack[-2],stack[-1]
        elif op in ARROWS: delta=ARROWS[op]
        elif op=="p":
            y,x=constant(stack.pop()),constant(stack.pop())
            need((x,y)==GATE,"wrong executable write address")
            stored=constant(stack.pop())
            writes.append(stored)
        else: raise ValueError("unmodelled chamber instruction %r at %r"%(op,pos))
        for _ in range(96):
            pos=pos[0]+delta[0],pos[1]+delta[1]
            if glyph(pos)!=32: break
        else: raise ValueError("blank traverse exceeded local chamber")
    else: raise ValueError("chamber did not return")
    emitted = "v" if sign<0 else ">"
    subtract = (sign<0) != force
    need(writes==[ord(emitted)] and fetches==[emitted] and
         arms==([(MINUS,"-")] if subtract else [(PLUS,"+")]),"missing causal fork or merge")
    expected=previous-increment if force else previous+increment
    need(delta==EAST and stack==[expected,5],"replacement stack or outgoing ray")
    return {"fetched":emitted,"operator":"-" if subtract else "+","steps":tick}


def prove(before, after):
    a,b=before.splitlines(),after.splitlines()
    need(len(a)==len(b) and max(map(len,a))==max(map(len,b)), "source bounds")
    changes={GATE}
    for y,(old,new) in enumerate(zip(a,b)):
        if old!=new:
            w=max(len(old),len(new))
            changes.update((x,y) for x,(u,v) in enumerate(zip(old.ljust(w),new.ljust(w))) if u!=v)
    need(all(959<=x<=1022 and 1046<=y<=1050 for x,y in changes),"out-of-chamber changes")
    pre,post,edges=set(),set(),set()
    def inspect(src,dst,direction,op):
        edge=(src,dst,direction)
        if edge in edges: return
        edges.add(edge)
        dx,dy=direction
        # Funge-98 j or # can skip nonblank glyphs; checking intervening
        # lattice cells as well is conservative for this replacement.
        for p in changes:
            if p in (START,LOAD5): continue
            sx,sy=p[0]-src[0],p[1]-src[1]
            if dx*sy!=dy*sx: continue
            if dx:
                if sx%dx: continue
                t=sx//dx
                end=(dst[0]-src[0])//dx
            else:
                if sy%dy: continue
                t=sy//dy
                end=(dst[1]-src[1])//dy
            need(not (min(0,end)<=t<=max(0,end)),"new opcode intersects an external arithmetic ray")
        if dst==START: pre.add((src,direction))
        if src==LOAD5: post.add((dst,direction))
        if src==START: need(dst==LOAD5 and direction==EAST,"other original entry successor")
        if dst==LOAD5: need(src==START and direction==EAST,"another origin at literal 5")
        if op=="k":
            need((dst[0]+dx,dst[1]+dy) not in changes,"peeking k touches chamber")
    _,geometry=compose(a,inspect)
    need(pre=={((958,1050),EAST)} and post=={(JOIN,EAST)},"original ingress/egress")
    need(not changes.intersection(map(tuple,geometry["arithmetic_memory_targets"])),"external p/g aliases candidate")
    for y,row in enumerate(a[:50]):
        need(row==b[y],"scanner changed")
    arms={}
    for s in (-1,0,1):
        for stale in (None,ord(">"),ord("v")):
            actual=chamber(b,s,stale)
            arms[str(s)]=actual
            if s:
                counter=chamber(b,s,stale,True)
                need(counter["operator"]!=actual["operator"],"forced arm fails to change numeric transfer")
    return {"original":git_blob(before),"candidate":git_blob(after),"changed_or_writable_cells":len(changes),
            "distinct_checked_original_directed_edges":len(edges),"sign_classes":arms,
            "gate":GATE,"add":PLUS,"subtract":MINUS,"untouched_external_arithmetic":True,
            "forced_opposite_arms_for_nonzero":"sum minus increment instead of sum plus increment"}


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original",type=Path)
    parser.add_argument("candidate",type=Path)
    parser.add_argument("out",type=Path)
    args=parser.parse_args()
    before,after=args.original.read_bytes(),args.candidate.read_bytes()
    need((git_blob(before),git_blob(after))==(PIN,PATCH_PIN),"exact source pins")
    result=prove(before,after)
    args.out.write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("Every original arithmetic route and three signed increment classes checked.")
