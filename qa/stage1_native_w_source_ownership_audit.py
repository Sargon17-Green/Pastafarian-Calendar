#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independently audit Native PyFunge w-selected arithmetic and mutable geometry.

Input is RAW Native interpreter STEP / g / p trace evidence, not a simulation.
The Native Befunge-only oracle results and one-byte causal control are required
from the separate Python 2 runner. This Python 3 process independently
checks source provenance, instruction-by-instruction executable Funge memory,
real directed per-run edges, all 17 signed-input families and no new p/g
collision with the 28 changed executable cells.

Only a QA candidate; never infers final Stage-1 geometry/ownership acceptance.
"""
import hashlib
import json
import os
import sys

import stage1_native_route_graph as geometry
import stage1_native_diverse_geometry_audit as cases
import stage1_native_reflective_candidate_domain_matrix as wide

BASE="qa/interleaved_work_counts_pre_two_valid_w_production.b98"
FROZEN="qa/interleaved_work_counts_w_data_branch_candidate.b98"
PROOF="w_data_candidate_proof.json"
CANDIDATE="w_data_branch_candidate.b98"
MUTANT="w_removed_counterfactual.b98"
ORIGINAL_BLOB="8f2cf8afef61818244747582fe7c20a74ee18943"
CANDIDATE_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
CANDIDATE_SHA256="9b1fb027286ca8bf881d9edcd97385843760fc0be48eb83d4c08d1a84c3d739e"
W=(951,1332)
PIVOT=(958,1324)
REJOIN=(958,1334)
LANES={"straight":(964,1331),"right":(964,1332)}
LOWER=frozenset(("foundation_cross","mixed_small","negative_positive",
                  "invalid_zero_sign","foundation_neighbor_forward",
                  "foundation_neighbor_reverse"))

def require(flag,why):
    if not flag:
        raise AssertionError(why)

def blob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode("ascii")+data).hexdigest()

def exact_sources(directory):
    before=open(BASE,"rb").read()
    frozen=open(FROZEN,"rb").read()
    candidate=open(os.path.join(directory,CANDIDATE),"rb").read()
    mutant=open(os.path.join(directory,MUTANT),"rb").read()
    require(blob(before)==ORIGINAL_BLOB and
            blob(frozen)==CANDIDATE_BLOB and frozen==candidate and
            hashlib.sha256(candidate).hexdigest()==CANDIDATE_SHA256,
            "Native w evidence and exact committed source blobs diverge")
    src=before.split(b"\n")
    dst=candidate.split(b"\n")
    require(len(src)==len(dst)==2016 and
            [len(row) for row in src]==[len(row) for row in dst] and
            max(map(len,dst))==1531,
            "native candidate unexpectedly widened/moved any source row")
    expected={(951,1334):(ord("]"),ord(":")),
              (951,1333):(32,ord("0")),
              (951,1332):(32,ord("w")),
              (951,1331):(32,ord(">"))}
    for y,start,after in ((1331,952,b"$001-#"),
                          (1331,959,b"006-3x"),
                          (1332,952,b"$101-#"),
                          (1332,959,b"006-2x")):
        for i,ch in enumerate(after):
            expected[(start+i,y)]=(32,ch)
    found={}
    for y,(a,b) in enumerate(zip(src,dst)):
        if a==b:
            continue
        for x,(old,new) in enumerate(zip(a,b)):
            if old!=new:found[(x,y)]=(old,new)
    require(len(found)==28 and found==expected,
            "QA data-dependent w source contains unapproved off-corridor edits")
    mutations=[]
    require(len(candidate)==len(mutant),"Native w mutant source length changed")
    for i,(a,b) in enumerate(zip(candidate,mutant)):
        if a!=b:mutations.append((i,a,b))
    w_offset=sum(len(r)+1 for r in dst[:W[1]])+W[0]
    require(mutations==[(w_offset,ord("w"),32)],
            "claimed causal control is not exactly one executed w-to-space edit")
    print("NATIVE_W_INDEPENDENT_EXACT_SOURCE_AND_MUTANT_PASS",
          len(found),"edits","mutant_changes",len(mutations))
    return geometry.load_source(FROZEN),set(expected)

def evidence_inputs(directory):
    with open(os.path.join(directory,PROOF),"r",encoding="utf-8") as reader:
        payload=json.load(reader)
    require(payload["schema"]=="befunge-stage1-native-w-data-selected-arithmetic-v1" and
            payload["status"]=="QA_CANDIDATE_ONLY_NOT_PROMOTED" and
            payload["exact_source_sha256"]==CANDIDATE_SHA256 and
            payload["frozen_candidate_git_blob"]==CANDIDATE_BLOB and
            payload["single_executed_w_removal_changes_output"] is True,
            "Native original w/mutant evidence provenance or scope invalid")
    entries=payload["cases"]
    require(tuple(x["case"] for x in entries)==cases.LABELS and
            len(entries)==17 and len(set(x["case"] for x in entries))==17,
            "complete and exactly ordered 17-case Native w evidence required")
    extra=payload.get("extended_signed_domain_cases",[])
    require(tuple(x["case"] for x in extra)==tuple(c[0] for c in wide.CASES)
            and len(extra)==22 and
            sum(x["valid"] for x in extra)==18 and
            all(x["native_reference_equal"] is True for x in extra),
            "wide signed-domain Native Befunge reference audit incomplete")
    return entries

def coordinates_edges(edges,point):
    parents={tuple(x["from"]) for x in edges if tuple(x["to"])==point}
    children={tuple(x["to"]) for x in edges if tuple(x["from"])==point}
    return parents,children

def main(directory):
    require(os.path.isdir(directory),"Native w evidence directory missing")
    source,edits=exact_sources(directory)
    entries=evidence_inputs(directory)
    arm_counts={"upper":0,"lower":0}
    modes=set()
    out=[]
    for item in entries:
        label=item["case"]
        filename=item["trace_file"]
        require(filename==label+".tsv","unsafe/incorrect Native trace filename")
        path=os.path.join(directory,filename)
        with open(path,"rb") as stream:
            actual_sha=hashlib.sha256(stream.read()).hexdigest()
        require(actual_sha==item["trace_sha256"],
                "untrusted Native trace digest "+label)
        proof=geometry.analyze(source,path)
        stats=proof["statistics"]
        ops=proof["arithmetic_executed_opcodes"]
        edges=proof["observed_directed_edges"]
        owned={tuple((p["x"],p["y"])) for p in
               (proof["read_targets"]+proof["write_targets"])}
        require(not (owned & edits),
                "Native w inserted executable bytes were overwritten/read as scratch "+label)
        require(stats["native_ip_ids"]==1 and
                stats["reads"]==stats["reads_completed"] and
                stats["writes"]==stats["writes_completed"] and
                stats["executed_content_changing_gate_writes"]>=2,
                "Native Funge-space g/p lifecycle invalid "+label)
        expected_arm="lower" if label in LOWER else "upper"
        require(item["arm"]==expected_arm and
                item["seven_field_native_parity"] is True,
                "Native arithmetic arm or oracle parity report changed "+label)
        arm_counts[expected_arm]+=1
        w_parents,w_children=coordinates_edges(edges,W)
        merge=next((x for x in proof["merge_fork_nodes"]
                    if (x["x"],x["y"])==PIVOT),None)
        if expected_arm=="upper":
            mode=item["w_mode"]
            require(mode in LANES,"upper input did not select real Native w arm "+label)
            modes.add(mode)
            expected_child=(951,1331) if mode=="straight" else (952,1332)
            require(w_parents=={(951,1333)} and
                    w_children=={expected_child} and
                    ops.get("w",0)==1 and
                    ops.get("r",0)==1 and
                    ops.get("[",0)>=2,
                    "actual Native data-dependent w/reflective opcode path absent "+label)
            source_node=next((s for s in proof["executed_source_map"]
                              if (s["x"],s["y"])==W),None)
            require(source_node is not None and source_node["visits"]==1 and
                    source_node["initial_byte"]==ord("w") and
                    source_node["final_byte"]==ord("w"),
                    "Native executed w source byte was not stable "+label)
            join_parents,_=coordinates_edges(edges,REJOIN)
            require(join_parents=={LANES[mode]} and
                    merge is not None and
                    merge["incoming"]==merge["outgoing"]==2,
                    "Native w rejoin or preexisting dual incident arithmetic node missing "+label)
        else:
            require(item["w_mode"] is None and
                    not w_parents and not w_children and ops.get("w",0)==0
                    and merge is None,
                    "unselected Native w route leaked into lower arithmetic branch "+label)
        out.append({"case":label,"arm":expected_arm,
                    "w_selected_mode":item["w_mode"],
                    "native_trace_sha256":actual_sha,
                    "p_writes":stats["writes"],"g_reads":stats["reads"],
                    "later_executed_changed_gates":stats["executed_content_changing_gate_writes"],
                    "new_route_read_write_collisions":0,
                    "old_dual_node_preserved":merge is not None})
        print("NATIVE_W_INDEPENDENT_GRAPH_AND_FUNGESPACE_PASS",label,
              expected_arm,item["w_mode"])
    require(arm_counts=={"upper":11,"lower":6} and
            modes=={"straight","right"},
            "Native 17-case w graph did not demonstrate both real outcomes")
    report={"schema":"befunge-stage1-independent-native-w-graph-v1",
            "status":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
            "source_sha256":CANDIDATE_SHA256,
            "verified_cases":len(out),
            "w_two_real_arithmetic_outcomes":sorted(modes),
            "input_selected_upper_cases":11,
            "lower_cases_excluding_w":6,
            "inserted_fungespace_cell_count":len(edits),
            "read_write_collisions":0,
            "stage1_completion_unchanged":True,
            "cases":out}
    with open(os.path.join(directory,"independent_w_native_graph.json"),
              "w",encoding="utf-8") as writer:
        json.dump(report,writer,sort_keys=True,indent=2)
        writer.write("\n")
    print("NATIVE_W_INDEPENDENT_GRAPH_VALIDATION_PASS",len(out),
          "genuine signed-day IP traces, no mutable Funge-space collision")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; candidate not promoted")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: stage1_native_w_graph_audit.py NATIVE_TRACE_DIR")
    main(sys.argv[1])
