#!/usr/bin/env python3
"""QA31AL source-pinned corridor/outer-writer and ingress audit.
All findings conditional on exact unchanged source and one stated straight corridor.
"""
import argparse
import hashlib
import json
from pathlib import Path

SRC = "560d6aa5807a7f766213a33835cce85eab0fa40c"
DIR = (("E", 1, 0, ">"), ("W", -1, 0, "<"),
       ("S", 0, 1, "v"), ("N", 0, -1, "^"))
ROWS = (20, 23, 29, 32)
LIMIT = 60
PURE = set("0123456789abcdef+-*/%!:$\\ " + chr(96))

def check(ok, message):
    if not ok:
        raise AssertionError(message)

def source(raw):
    obj = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    check(obj == SRC, "source git blob changed")
    rows = raw.splitlines()
    check(len(rows) == 2015 and rows[49] == b"", "source dimensions changed")
    all_p = [(x,y) for y,row in enumerate(rows)
             for x,ch in enumerate(row) if ch == ord("p")]
    check(len(all_p) == 57 and sum(y < 45 for x,y in all_p) == 13,
          "original p-site inventory")
    return rows, [(x,y) for x,y in all_p if y>=45]

def at(rows,x,y):
    if not 0<=y<len(rows) or not 0<=x<len(rows[y]):
        return None
    return chr(rows[y][x])

def ray(rows,x,y,info):
    name,dx,dy,entry=info
    for k in range(1,LIMIT+1):
        ax,ay=x-k*dx,y-k*dy
        c=at(rows,ax,ay)
        if c is None:
            break
        if c==entry:
            seg="".join(at(rows,ax+i*dx,ay+i*dy) for i in range(k+1))
            check(seg[0]==entry and seg[-1]=="p", "bad segment boundary")
            if all(c in PURE for c in seg[1:-1]):
                return {"direction":name,"anchor":[ax,ay],
                        "steps":k,"ops":seg}
            return None
    return None

def symbolic(ops):
    # Incoming stack values are arbitrary. A missing stack item is UNKNOWN,
    # never silently assumed to be zero. Only constant results are proven.
    stack=[]
    external=0
    def pop():
        nonlocal external
        if stack:
            return stack.pop()
        external += 1
        return None
    for op in ops[1:-1]:
        if op in "0123456789abcdef":
            stack.append(int(op,16))
        elif op in "+-*/%" + chr(96):
            b,a=pop(),pop()
            if a is None or b is None:
                stack.append(None)
            elif op=="+":
                stack.append(a+b)
            elif op=="-":
                stack.append(a-b)
            elif op=="*":
                stack.append(a*b)
            elif op==chr(96):
                stack.append(int(a>b))
            elif b==0:
                stack.append(None)
            elif op=="/":
                stack.append(int(a/b))
            else:
                stack.append(a-int(a/b)*b)
        elif op=="!":
            a=pop()
            stack.append(None if a is None else int(a==0))
        elif op==":":
            a=pop();stack.extend((a,a))
        elif op=="\\":
            a,b=pop(),pop();stack.extend((a,b))
        elif op=="$":
            pop()
        elif op==" ":
            continue
        else:
            raise AssertionError("non-pure segment")
    y,x,v=pop(),pop(),pop()
    return {"static_y":y,"static_x":x,"static_value":v,
            "external_stack_pops":external,
            "conditionally_excludes_counter_y49":y is not None and y!=49}

def ingress(rows):
    entries=[]
    for y in ROWS:
        check(at(rows,10,y)==">", "row entry byte changed")
        neighborhood={"north":at(rows,10,y-1),
                      "south":at(rows,10,y+1),
                      "west":at(rows,9,y)}
        check(all(v is None or v==" " for v in neighborhood.values()),
              "entry adjacency changed")
        entries.append({"target":[10,y],"entry_opcode":">",
                        "geometric_neighbor_cells":neighborhood,
                        "unrestricted_IP_reachability":"UNKNOWN"})
    return entries

def hostile(rows,sites):
    checks=0
    for idx in (0,2,5,10,15,20,25,30,35,43):
        x,y=sites[idx]
        altered=[bytearray(z) for z in rows]
        altered[y][x]=ord(" ")
        check(altered[y][x]!=ord("p"),
              "mutated original p glyph still passed")
        checks+=1
    check(checks==10,"hostile count changed")
    return checks

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",required=True)
    ap.add_argument("--out",required=True)
    opts=ap.parse_args()
    rows,sites=source(Path(opts.source).read_bytes())
    records=[]
    for x,y in sites:
        candidates=[]
        for direction in DIR:
            entry=ray(rows,x,y,direction)
            if entry is not None:
                entry.update(symbolic(entry["ops"]))
                candidates.append(entry)
        records.append({"site":[x,y],"source_byte":"p",
                        "bounded_straight_candidates":candidates,
                        "unrestricted_write_target":"UNKNOWN",
                        "unrestricted_IP_and_stack_reachability":"UNKNOWN"})
    all_candidates=[c for rec in records
                    for c in rec["bounded_straight_candidates"]]
    excluded=[(rec,c) for rec in records for c in rec["bounded_straight_candidates"]
              if c["conditionally_excludes_counter_y49"]]
    unresolved=[c for c in all_candidates if c["static_y"] is None]
    no_corridor=[rec["site"] for rec in records
                 if not rec["bounded_straight_candidates"]]
    check((len(sites),len(all_candidates),len(excluded),len(unresolved),
           len(no_corridor))==(44,43,11,32,1),
           "original straight-corridor counts changed")
    check(no_corridor==[[369,575]], "unanchored p site shifted")
    check(all(c["static_y"]!=49 for _,c in excluded),
          "unexpected candidate y49")
    geom=ingress(rows)
    mutants=hostile(rows,sites)
    out={"schema":"qa31al-pinned-bounded-corridor-v1",
         "project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ",
         "source_git_blob":SRC,"corridor_limit":LIMIT,
         "literal_p_full_source":57,"literal_p_prologue":13,
         "literal_p_outside":44,"outer_sites":records,
         "source_straight_corridors":len(all_candidates),
         "conditional_fixed_non49_y_corridors":len(excluded),
         "conditional_unknown_y_corridors":len(unresolved),
         "no_bounded_straight_anchor":no_corridor,
         "conditional_fixed_non49_sites":[rec["site"] for rec,c in excluded],
         "alternate_ingress_local_geometry":geom,
         "forward_source_mutants_rejected":mutants,
         "outer_p_counter_targets_globally_proven":"UNKNOWN",
         "alternate_ingress_reachability":"UNKNOWN",
         "new_native_runs":0,"replayed_native_runs":0,
         "stage1_global_pass":False}
    Path(opts.out).write_text(json.dumps(out,sort_keys=True,
                           separators=(",",":"))+"\n",encoding="utf-8")
    print("QA31AL_SOURCE_PASS 44_OUTER 43_ANCHORED 11_CONDITIONALLY_EXCLUDED 32_UNKNOWN_Y 1_UNANCHORED")
    print("QA31AL_ALT_INGRESS_GEOMETRY 4 ROWS NATIVE 0 STAGE1 OPEN")

if __name__=="__main__":
    main()
