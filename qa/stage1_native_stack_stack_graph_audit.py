#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent replay of actual PyFunge { u } arithmetic Funge-space events.

Checks exact source diff, 17 SHA-256 pinned raw traces, true opcode
execution, 1-IP directed route, temporal p/g execution-cell version
lifecycle and no overlap between new source and existing scratch.
Test-only proof, never a Python calendar oracle.
"""
import hashlib
import json
import os
import sys
import stage1_native_route_graph as graph
import stage1_native_diverse_geometry_audit as corpus
import stage1_native_reflective_candidate_domain_matrix as wide

BASE="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BLOB="b6cf50de9ed45376db5fc4ebd003157210dff03b"
CAND_SHA="9d43930d0b94bb740b117470f5765fd96f77e3447fee391458a126fc1c5be4d4"
OUT="stack_stack_candidate.b98"
CORRIDOR={(954,y) for y in range(1318,1331)} | {(954,1332),(955,1332)}
REJOIN=(955,1332)
CASES_UP={"zero_equal","forward_short","reverse_short","positive_negative",
          "large_values","epoch_forward_one","epoch_reverse_one",
          "recent_anchor_equal","recent_anchor_next","invalid_target_zero_sign"}

def require(flag,msg):
    if not flag:raise AssertionError(msg)
def gitblob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode("ascii")+data).hexdigest()

def source_check(directory):
    old=open(BASE,"rb").read()
    new=open(os.path.join(directory,OUT),"rb").read()
    require(gitblob(old)==BLOB and hashlib.sha256(new).hexdigest()==CAND_SHA,
            "stack-stack source/reference byte provenance changed")
    a=old.split(b"\n");b=new.split(b"\n")
    require(len(a)==len(b)==2016 and len(old)==len(new) and
            [len(row) for row in a]==[len(row) for row in b],
            "Native stack-stack source dimensions/rows changed")
    expected={(954,1332):(ord("0"),ord("^")),(955,1332):(ord("1"),ord(">"))}
    for y,ch in zip(range(1330,1317,-1),b"{3u:1-\\2}11ex"):
        expected[(954,y)]=(32,ch)
    actual={}
    for y,(r,s) in enumerate(zip(a,b)):
        for x,(left,right) in enumerate(zip(r,s)):
            if left!=right:actual[(x,y)]=(left,right)
    require(expected==actual and len(actual)==15,
            "stack-stack source byte edits are off the reserved Native corridor")
    return graph.load_source(os.path.join(directory,OUT)),set(expected)

def edge_set(edges,pt):
    return ({tuple(e["from"]) for e in edges if tuple(e["to"])==pt},
            {tuple(e["to"]) for e in edges if tuple(e["from"])==pt})

def main(directory):
    require(os.path.isdir(directory),"missing Native stack-stack directory")
    source,edited=source_check(directory)
    with open(os.path.join(directory,"native_stack_stack_arithmetic.json"),
              encoding="utf-8") as stream:proof=json.load(stream)
    require(proof["schema"]=="befunge-stage1-native-stack-stack-arithmetic-v1"
            and proof["status"]=="QA_EXPERIMENT_ONLY_NO_STAGE1_ACCEPTANCE"
            and proof["candidate_sha256"]==CAND_SHA
            and proof["changed_exact_executable_cells"]==15,
            "stack-stack runner proof provenance mismatch")
    cases=proof["seventeen_native_cases"]
    require(len(cases)==17 and
            tuple(z["case"] for z in cases)==corpus.LABELS,
            "Native stack-stack evidence must include all 17 original cases")
    extensions=proof["extra_native_signed_cases"]
    require(len(extensions)==22 and
            tuple(x["case"] for x in extensions)==tuple(z[0] for z in wide.CASES)
            and all(x["oracle_equal"] is True for x in extensions),
            "independent wide Native reference proof missing")
    report=[]
    for item in cases:
        label=item["case"]
        file=item["trace_file"]
        require(file==label+".tsv" and os.path.basename(file)==file,
                "unsafe source trace filename")
        path=os.path.join(directory,file)
        with open(path,"rb") as src:sha=hashlib.sha256(src.read()).hexdigest()
        require(sha==item["trace_sha256"],
                "Native stack-stack STEP trace digest mismatch "+label)
        native=graph.analyze(source,path)
        stats=native["statistics"]
        ops=native["arithmetic_executed_opcodes"]
        edges=native["observed_directed_edges"]
        touched={(p["x"],p["y"]) for p in
                 native["read_targets"]+native["write_targets"]}
        require(not(touched & edited),
                "new native stack-stack executable corridor overlaps g/p scratch")
        require(stats["native_ip_ids"]==1 and
                stats["reads"]==stats["reads_completed"] and
                stats["writes"]==stats["writes_completed"] and
                stats["executed_content_changing_gate_writes"]>=2,
                "Native p/g ownership/executable lifecycle compromised")
        upper=label in CASES_UP
        expected_ops=1 if upper else 0
        require(all(ops.get(op,0)==expected_ops for op in ("{","u","}")),
                "Native stack-stack instructions did not all participate exactly once")
        incoming,outgoing=edge_set(edges,(954,1328))
        if upper:
            require(incoming=={(954,1329)} and outgoing=={(954,1327)},
                    "Native u did not execute in correct actual directed arithmetic chain")
            srcnode=next((x for x in native["executed_source_map"] if
                          (x["x"],x["y"])==(954,1328)),None)
            require(srcnode is not None and srcnode["initial_byte"]==ord("u")
                    and srcnode["final_byte"]==ord("u") and
                    srcnode["visits"]==1,
                    "Native actual stack-stack u instruction not byte/visit stable")
            prev,following=edge_set(edges,(954,1318))
            require(prev=={(954,1319)} and following=={REJOIN},
                    "Native actual x detour did not return to arithmetic")
        else:
            require(not incoming and not outgoing and
                    item["observed"]["route"]=="bypass",
                    "unselected stack-stack executed on wrong Native family")
        report.append({"case":label,"executed":upper,
                       "native_sha256":sha,"u":ops.get("u",0),
                       "stack_close":ops.get("}",0),
                       "native_p_g_collision_count":0})
        print("NATIVE_STACK_STACK_INDEPENDENT_IP_G_P_AUDIT_PASS",label,upper)
    require(sum(x["executed"] for x in report)==10,
            "exact ten Native upper stack-stack routes not seen")
    with open(os.path.join(directory,"stack_stack_independent_graph.json"),
              "w",encoding="utf-8") as out:
        json.dump({"schema":"befunge-stage1-native-stack-stack-independent-graph-v1",
                   "status":"QA_ONLY_NOT_STAGE1_ACCEPTANCE",
                   "source_sha256":CAND_SHA,
                   "cases":report,"validated_native_cases":len(report),
                   "native_upper_arithmetic_cases":10,
                   "new_g_p_source_collisions":0},out,sort_keys=True,indent=2)
        out.write("\n")
    print("NATIVE_STACK_STACK_INDEPENDENT_GRAPH_MEMORY_PASS",
          len(report),"Native cases, all source mutations byte verified")
    print("STAGE1_GEOMETRIC_FINAL_GATE=OPEN")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: stage1_native_stack_stack_graph_audit.py DIR")
    main(sys.argv[1])
