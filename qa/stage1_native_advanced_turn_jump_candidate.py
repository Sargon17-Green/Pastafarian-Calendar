#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Exact Native proof for advanced turn + jump path, QA candidate ONLY.

No calendar algorithm or numerical oracle here: independent Befunge source
programs produce all expected seven fields. Trace assertions cover actual IP,
stack depth, directional turns, a jumped-over gap and the arithmetic rejoin.
"""
from __future__ import print_function
import json
import os
import sys
import stage1_native_diverse_geometry as suite

SOURCE="qa/interleaved_work_counts_advanced_turn_jump_candidate.b98"
OUT="/advanced"
FORK=(951,1335)
ENTRY_UP=(951,1334)
ENTRY_DOWN=(951,1336)
REJOIN=(950,1335)
AFTER=(949,1335)
JUMP_IN=(958,1331)
JUMP_OUT=(958,1325)
WATCH=set((FORK,ENTRY_UP,ENTRY_DOWN,REJOIN,AFTER,
           (962,1334),(964,1336),
           (958,1334),(958,1333),(958,1332),
           (958,1331),(958,1325),(958,1324),(958,1323)))

def require(flag,why):
    if not flag:
        raise AssertionError(why)

def native_route(path):
    hits=[]
    with open(path,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):
                continue
            v=line.rstrip("\n").split("\t")
            require(len(v)==9,"bad STEP event format")
            tick,ip,x,y,dx,dy,op,depth=map(int,v[1:])
            if (x,y) in WATCH:
                hits.append((tick,ip,x,y,dx,dy,op,depth))
    require(hits and (hits[0][2],hits[0][3])==FORK,
            "execution never reached conditional fork")
    branch="up" if (hits[1][2],hits[1][3])==ENTRY_UP else \
           "down" if (hits[1][2],hits[1][3])==ENTRY_DOWN else None
    require(branch in ("up","down"),"Native branch did not use either arm")
    coords=[(e[2],e[3]) for e in hits]
    expected=[FORK,ENTRY_UP,(958,1334),(958,1333),(958,1332),
              JUMP_IN,JUMP_OUT,(958,1324),(958,1323),(962,1334),REJOIN,AFTER] \
            if branch=="up" else [FORK,ENTRY_DOWN,(964,1336),REJOIN,AFTER]
    require(coords==expected,"Native executed arm, jump and rejoin wrong: "+repr(coords))
    require((hits[0][4],hits[0][5],hits[0][6],hits[0][7])==(-1,0,124,2),
            "conditional branch was not the native | gate with original operands")
    turn=hits[1]
    want_turn=(ord("]"),0,-1,1) if branch=="up" else (ord("["),0,1,1)
    require((turn[6],turn[4],turn[5],turn[7])==want_turn,
            "native [] directional turn missing or stack depth wrong")
    final=hits[-3]
    require((final[6],final[4],final[5],final[7])==(ord("x"),1,0,5),
            "terminal native arm x did not preserve arithmetic stack")
    merge=hits[-2]
    velocity=(-12,1) if branch=="up" else (-14,-1)
    require((merge[6],merge[4],merge[5],merge[7])==(ord("x"),)+velocity+(3,),
            "native input-dependent route did not join original executable x")
    tail=hits[-1]
    require((tail[4],tail[5],tail[7])==(-1,0,1),
            "rejoined arithmetic lane's next native stack/vector differs")
    if branch=="up":
        opcodes=[e[6] for e in hits]
        require(opcodes[2:9]==list(map(ord,"^05j1bx")),
                "Native j + skipped-space arithmetic excursion not executed exactly")
        require(hits[5][7]==5 and hits[6][7]==4,
                "native jump must consume the actual 5-cell skip count")
        require(hits[5][4:6]==(0,-1) and hits[6][4:6]==(0,-1),
                "native j changed IP heading unexpectedly")
        require(hits[6][0]==hits[5][0]+1,
                "Native interpreter did not jump across unexecuted intervening cells")
        require(hits[8][7]==6,
                "dynamic x must consume computed rejoin vector from stack")
    return branch, [{"tick":e[0],"x":e[2],"y":e[3],"dx":e[4],
                     "dy":e[5],"opcode":e[6],"depth":e[7]} for e in hits]

def main():
    require(os.path.isdir(OUT),"writable /advanced evidence directory missing")
    all_rows=[]
    observed=set()
    for label,fields,valid in suite.CASES:
        raw=" ".join(map(str,fields))+"\n"
        trace=os.path.join(OUT,label+".tsv")
        got=suite.native(SOURCE,raw,trace=trace)
        expected=suite.expected_for(*fields) if valid else ["-1"]*7
        require(got==expected,"Native candidate numerical oracle mismatch "+label)
        route,path=native_route(trace)
        observed.add(route)
        all_rows.append({"case":label,"valid":valid,
                         "native_arm":route,"executed_path":path})
        print("NATIVE_ADVANCED_TURN_JUMP_REJOIN_PASS",label,
              "arm",route,"events",len(path),"fields",len(got))
        sys.stdout.flush()
    require(observed==set(("up","down")),
            "native inputs do not actually exercise both directional turns")
    with open(os.path.join(OUT,"advanced_native_route_proof.json"),"wb") as out:
        out.write(json.dumps({"schema":"befunge-stage1-native-advanced-turn-jump-v1",
                              "scope":"candidate only; not complete Stage 1",
                              "observed_branches":sorted(observed),
                              "native_proofs":all_rows},sort_keys=True,indent=2)+"\n")
    print("NATIVE_ADVANCED_TURN_JUMP_TEN_CASES_PASS",len(all_rows))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (additional requirements still open)")

if __name__=="__main__":
    main()
