#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native qualification of a real, data-dependent arithmetic bifurcation.

The candidate substitutes two routes for the actual logical-not + addition.
No Python calendar algorithm or oracle. Every output is checked using the
existing independent Befunge programs. No production or canonical changes.
"""
from __future__ import print_function
import json
import os
import sys
import stage1_native_diverse_geometry as suite

SOURCE="qa/interleaved_work_counts_native_bifurcation_candidate.b98"
OUT="/bifurcation"
GATE=(951,1335)
WATCH=frozenset(((951,1335),(951,1334),(951,1336),
                 (962,1334),(964,1336),(950,1335),(949,1335)))
FORKS={"up":{"entry":(951,1334),"final_x":(962,1334),
             "outer_vector":(-12,1)},
       "down":{"entry":(951,1336),"final_x":(964,1336),
               "outer_vector":(-14,-1)}}

def require(ok,why):
    if not ok:
        raise AssertionError(why)

def parse_route(trace):
    seq=[]
    with open(trace,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):
                continue
            f=line.rstrip("\n").split("\t")
            require(len(f)==9,"malformed native IP step")
            tick,ip,x,y,dx,dy,opcode,depth=map(int,f[1:])
            if (x,y) in WATCH:
                seq.append({"tick":tick,"ip":ip,"x":x,"y":y,
                            "dx":dx,"dy":dy,"opcode":opcode,"depth":depth})
    require(len(seq)==5,
            "expected exactly five executed fork, arm, outer x, inner x, rejoin steps: %r" %
            seq[:12])
    a,b,c,d,e=seq
    require((a["x"],a["y"],a["opcode"],a["dx"],a["dy"],a["depth"])==
            (951,1335,124,-1,0,2),
            "native input-dependent '|' gate not executed with two operands")
    branch=("up" if (b["x"],b["y"])==(951,1334)
            else "down" if (b["x"],b["y"])==(951,1336)
            else None)
    require(branch in FORKS,"native fork did not choose either 2D arm")
    geom=FORKS[branch]
    require((b["opcode"],b["dx"],b["dy"],b["depth"])==
            (ord(">"),0,-1 if branch=="up" else 1,1),
            "native branch entry had wrong instruction, direction, or stack depth")
    require((c["x"],c["y"],c["opcode"],c["dx"],c["dy"],c["depth"])==
            tuple(geom["final_x"])+(ord("x"),1,0,5),
            "native branch did not calculate sum and vector before outer x")
    require((d["x"],d["y"],d["opcode"],d["dx"],d["dy"],d["depth"])==
            (950,1335,ord("x"))+geom["outer_vector"]+(3,),
            "native alternative arithmetic paths did not merge at executable x")
    require((e["x"],e["y"],e["dx"],e["dy"],e["depth"])==
            (949,1335,-1,0,1),
            "rejoined instruction did not resume original west-moving calculation")
    return {"arm":branch,"native_steps":seq}

def main():
    require(os.path.isdir(OUT),"missing Native evidence directory /bifurcation")
    rows=[]
    observed=set()
    for label,fields,valid in suite.CASES:
        data=" ".join(map(str,fields))+"\n"
        path=os.path.join(OUT,label+".tsv")
        try:
            got=suite.native(SOURCE,data,trace=path)
        except Exception:
            print("NATIVE_BIFURCATION_PROCESS_FAIL",label,"trace",path)
            if os.path.isfile(path):
                with open(path,"rb") as stream:
                    tail=stream.read()[-1800:]
                print("NATIVE_BIFURCATION_TRACE_TAIL",tail)
            raise
        expected=suite.expected_for(*fields) if valid else ["-1"]*7
        require(got==expected,"candidate diverged from independent native oracle "+label)
        route=parse_route(path)
        observed.add(route["arm"])
        rows.append({"case":label,"valid":bool(valid),"arm":route["arm"],
                     "native_route":route["native_steps"],"output_fields":len(got)})
        print("NATIVE_BIFURCATION_ROUTE_AND_ORACLE_PASS",label,
              "arm",route["arm"],"steps",len(route["native_steps"]))
        sys.stdout.flush()
    require(observed==set(("up","down")),
            "all native inputs chose same branch; missing true input-dependent geometry")
    with open(os.path.join(OUT,"native_bifurcation_evidence.json"),"wb") as dst:
        dst.write(json.dumps({"schema":"befunge-stage1-native-conditional-fork-v1",
                             "scope":"QA-only actual logic-not/addition branch; not full Stage1 geometry acceptance",
                             "observed_arms":sorted(observed),
                             "cases":rows},indent=2,sort_keys=True)+"\n")
    print("NATIVE_TWO_ARM_MEANINGFUL_ARITHMETIC_FORK_PASS",len(rows),"cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (additional source-wide requirements open)")
if __name__=="__main__":
    main()
