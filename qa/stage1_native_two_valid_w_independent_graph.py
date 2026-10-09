#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent Native event/graph and writable-space ownership qualification.

Read RAW PyFunge-98 STEP/READ/WRITE traces from another runner. Check the
18-cell source provenance, real directed fork/rejoin, exact executed opcodes,
native Funge-space g/p read/write history and valid signed-input route
selection. No numeric oracle or calendar arithmetic is implemented here.
"""
import hashlib
import json
import os
import sys

import stage1_native_route_graph as native
import stage1_native_diverse_geometry_audit as corpus
import stage1_native_reflective_candidate_domain_matrix as wide

BASE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
NEW="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BASE_BLOB="31807edb2b44b141d2af340555d6e97e63428613"
CAND_BLOB="b6cf50de9ed45376db5fc4ebd003157210dff03b"
W=(951,1332)
U=(951,1331)
LOWER_TURN=(951,1336)
UPPER_PIVOT=(958,1324)
LOWER=frozenset(("foundation_cross","mixed_small","negative_positive",
                 "invalid_zero_sign","foundation_neighbor_forward",
                 "foundation_neighbor_reverse"))
INVALID_UPPER="invalid_big_sign"

def require(condition,message):
    if not condition:raise AssertionError(message)

def gitblob(payload):
    return hashlib.sha1(("blob %d\0"%len(payload)).encode("ascii")+payload).hexdigest()

def exact_map():
    old=open(BASE,"rb").read();new=open(NEW,"rb").read()
    require(gitblob(old)==BASE_BLOB and gitblob(new)==CAND_BLOB,
            "Native two-valid-w source Git SHA mismatch")
    lines1=old.split(b"\n");lines2=new.split(b"\n")
    require(len(lines1)==len(lines2)==2016 and len(old)==len(new)
            and [len(x) for x in lines1]==[len(x) for x in lines2]
            and max(map(len,lines2))==1531,
            "Native two-valid-w source shape/row lengths changed")
    expected={(951,1334):(ord(":"),ord("0")),
              (951,1333):(ord("0"),ord("^")),
              (951,1331):(ord(">"),ord("_")),
              (951,1336):(ord("["),ord("]")),
              (951,1337):(32,ord("^"))}
    for i,ch in enumerate(b"$100903-x"):
        expected[(950-i,1336)]=(32,ch)
    for x,ch in ((950,ord("0")),(949,ord("8")),
                 (948,ord("6")),(943,ord("x"))):
        expected[(x,1331)]=(32,ch)
    actual={}
    for y,(before,after) in enumerate(zip(lines1,lines2)):
        for x,(a,b) in enumerate(zip(before,after)):
            if a!=b:actual[(x,y)]=(a,b)
    require(len(actual)==18 and actual==expected,
            "unapproved native two-valid w executable cell diff: "+repr(actual))
    print("NATIVE_TWO_VALID_W_INDEPENDENT_18_CELL_MAP_PASS",len(actual))
    return native.load_source(NEW),set(actual)

def incidence(edges,at):
    parents={tuple(e["from"]) for e in edges if tuple(e["to"])==at}
    children={tuple(e["to"]) for e in edges if tuple(e["from"])==at}
    return parents,children

def raw_velocity_probe(path,group):
    positions={W:[],U:[],LOWER_TURN:[]}
    with open(path,"r",encoding="ascii") as stream:
        for line in stream:
            if line.startswith("STEP\t"):
                fields=line.rstrip("\n").split("\t")
                require(len(fields)==9,"malformed full interpreter STEP event")
                step,ip,x,y,dx,dy,opcode,depth=map(int,fields[1:])
                if (x,y) in positions:
                    positions[(x,y)].append((step,ip,dx,dy,opcode,depth))
    require(len(positions[W])==1,"w not executed exactly once")
    observed=positions[W][0]
    require(observed[2:]==(0,-1,ord("w"),3 if group=="lower" else 2),
            "Native true w entry velocity/opcode/stack changed")
    require(len(positions[U])==(0 if group=="upper" else 1),
            "input-selected underscore visitation count changed")
    if positions[U]:
        u=positions[U][0]
        require(u[2:4]==(0,-1) and u[4]==ord("_"),
                "native semantic underscore not entered on proper heading")
    turn=positions[LOWER_TURN]
    if group=="lower":
        require(len(turn)==2 and
                turn[0][2:]==(0,1,ord("]"),1) and
                turn[1][2]==0 and turn[1][3]==-1 and
                turn[1][4]==ord("]") and
                turn[0][0]<observed[0]<turn[1][0],
                "native dual-entry lower junction lost real repeated vectors")
    else:
        require(not turn,"upper path entered lower turn")
    return {"w_tick":observed[0],"w_stack":observed[-1],
            "underscore_executions":len(positions[U]),
            "lower_turn_executions":len(turn)}

def main(directory):
    require(os.path.isdir(directory),"Native two-valid w trace evidence directory missing")
    src,edits=exact_map()
    path=os.path.join(directory,"native_two_valid_w_evidence.json")
    with open(path,"r",encoding="utf-8") as stream: proof=json.load(stream)
    require(proof["schema"]=="befunge-stage1-two-valid-w-native-v2"
            and proof["status"]=="QA_PRODUCTION_ONLY_NOT_STAGE1_ACCEPTANCE"
            and proof["candidate_blob"]==CAND_BLOB
            and proof["source_exact_changed_cells"]==18
            and proof["two_valid_w_comparison_outcomes"] is True
            and proof["wide_oracle_cases"]==22
            and len(proof["causal_controls"])==2
            and all(x["output_changed"] is True for x in proof["causal_controls"]),
            "no exact two-valid-w Native numerical/counterfactual provenance")
    records=proof["cases"]
    require(len(records)==17 and tuple(x["case"] for x in records)==corpus.LABELS,
            "missing or reordered Native two-valid-w signed input corpus")
    results=[]
    valid_modes=set()
    count={"upper":0,"invalid":0,"lower":0}
    for record in records:
        label=record["case"]
        filename=record["trace"]
        require(filename==label+".new.tsv",
                "untrusted Native trace filename/label for "+label)
        file=os.path.join(directory,filename)
        with open(file,"rb") as stream:
            digest=hashlib.sha256(stream.read()).hexdigest()
        require(digest==record["trace_sha256"],
                "Native interpreter trace digest mismatch "+label)
        expected_group="lower" if label in LOWER else \
            "invalid" if label==INVALID_UPPER else "upper"
        expected_mode="right" if expected_group=="upper" else "straight"
        require(record["group"]==expected_group and
                record["mode"]==expected_mode,
                "untrusted native route report label/branch "+label)
        if record["valid"]:
            valid_modes.add(expected_mode)
        count[expected_group]+=1
        analysis=native.analyze(src,file)
        stats=analysis["statistics"]
        ops=analysis["arithmetic_executed_opcodes"]
        edges=analysis["observed_directed_edges"]
        owned={(z["x"],z["y"]) for z in
               (analysis["read_targets"]+analysis["write_targets"])}
        require(not (owned & edits),
                "candidate executable cells overlap native p/g scratch "+label)
        require(stats["native_ip_ids"]==1 and
                stats["reads"]==stats["reads_completed"] and
                stats["writes"]==stats["writes_completed"] and
                stats["executed_content_changing_gate_writes"]>=2,
                "Native mutable Funge-space lifecycle incomplete "+label)
        require(ops.get("w",0)==1,
                "Native comparator w does not execute once "+label)
        wparents,wchildren=incidence(edges,W)
        expected_child=(952,1332) if expected_mode=="right" else (951,1331)
        require(wparents=={(951,1333)} and
                wchildren=={expected_child},
                "w true Native directed edges do not select arithmetic mode "+label)
        uparents,uchildren=incidence(edges,U)
        if expected_group=="upper":
            require(not uparents and not uchildren and ops.get("_",0)==0,
                    "upper Native right-hand path leaked into underscore branch "+label)
        else:
            expected_next=(950,1331) if expected_group=="lower" else (952,1331)
            require(uparents=={W} and uchildren=={expected_next} and
                    ops.get("_",0)==1,
                    "actual Native underscore discriminator graph invalid "+label)
        down=next((x for x in analysis["merge_fork_nodes"]
                   if (x["x"],x["y"])==LOWER_TURN),None)
        upper=next((x for x in analysis["merge_fork_nodes"]
                    if (x["x"],x["y"])==UPPER_PIVOT),None)
        if expected_group=="lower":
            require(down is not None and
                    down["incoming"]==2 and down["outgoing"]==2,
                    "lower candidate lost genuine single-run dual-incident node "+label)
        else:
            require(down is None,
                    "upper route unexpectedly executed lower dual junction "+label)
        if expected_group=="upper" or expected_group=="invalid":
            require(upper is not None and upper["incoming"]==2 and
                    upper["outgoing"]==2,
                    "reflective upper dual merge/fork unexpectedly lost "+label)
        metrics=raw_velocity_probe(file,expected_group)
        results.append({"case":label,"group":expected_group,
                        "valid":record["valid"],"mode":expected_mode,
                        "sha256":digest,"executed_native_w":ops.get("w",0),
                        "executed_native_underscore":ops.get("_",0),
                        "changed_executable_reexecutions":
                           stats["executed_content_changing_gate_writes"],
                        "p_g_scratch_source_overlap":0,
                        "actual_native_velocity":metrics})
        print("NATIVE_TWO_VALID_W_INDEPENDENT_FULL_GRAPH_PASS",
              label,expected_group,expected_mode)
        sys.stdout.flush()
    require(count=={"upper":10,"invalid":1,"lower":6}
            and valid_modes=={"right","straight"},
            "valid domain did not exercise both Native w branches")
    require(len(proof["causal_controls"])==2
            and {x["case"] for x in proof["causal_controls"]}==
                 {"valid_upper","valid_lower"},
            "both valid one-byte Native w removal counterfactuals missing")
    output={"schema":"befunge-stage1-two-valid-w-independent-native-ip-memory-v1",
            "status":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
            "candidate_git_blob":CAND_BLOB,
            "changed_exact_source_cells":len(edits),
            "cases":len(results),"valid_w_outcomes":sorted(valid_modes),
            "real_native_read_write_source_collisions":0,
            "counterfactuals_two_valid_arithmetic":True,
            "result":"PASS","records":results}
    with open(os.path.join(directory,"two_valid_w_independent_graph.json"),
              "w",encoding="utf-8") as stream:
        json.dump(output,stream,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_TWO_VALID_W_INDEPENDENT_REAL_IP_G_P_AUDIT_PASS",
          len(results),"cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; QA production, final gate open")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: two_valid_w_independent_graph NativeTraceDir")
    main(sys.argv[1])
