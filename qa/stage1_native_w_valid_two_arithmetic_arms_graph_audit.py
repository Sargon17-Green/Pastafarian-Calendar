#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent Native trace graph and exact Funge-space lifecycle verifier.

Both VALID arms must visit the SAME executed w. The lower path must visit
the SAME ] twice with distinct predecessor/successor edges. The _ op
protects upper-invalid semantics. All proof comes from native STEP/g/p
records, not Python date calculations or drawn/unused Befunge source.
"""
import hashlib
import json
import os
import sys
import stage1_native_route_graph as graph
import stage1_native_diverse_geometry_audit as corpus

SOURCE="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BASE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
SRC_SHA="b6cf50de9ed45376db5fc4ebd003157210dff03b"
BASE_SHA="31807edb2b44b141d2af340555d6e97e63428613"
W=(951,1332)
SENTRY=(951,1331)
TURN=(951,1336)
REFLECT=(958,1324)
LOWER={"foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse"}
def require(ok,msg):
    if not ok:raise AssertionError(msg)
def blob(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode("ascii")+data).hexdigest()

def exact_diff():
    a=open(BASE,"rb").read();b=open(SOURCE,"rb").read()
    require(blob(a)==BASE_SHA and blob(b)==SRC_SHA,
            "Native candidate or source predecessor SHA changed")
    a=a.split(b"\n");b=b.split(b"\n")
    require(len(a)==len(b)==2016 and
            [len(s) for s in a]==[len(s) for s in b] and
            max(map(len,b))==1531,"source map shape changed")
    permitted={(951,1334):(58,48),(951,1333):(48,94),
       (951,1331):(62,95),(951,1336):(91,93),
       (951,1337):(32,94)}
    for i,v in enumerate(b"$100903-x"):
        permitted[(950-i,1336)]=(32,v)
    for x,v in ((950,48),(949,56),(948,54),(943,120)):
        permitted[(x,1331)]=(32,v)
    observed={}
    for y,(former,current) in enumerate(zip(a,b)):
        for x,(f,c) in enumerate(zip(former,current)):
            if f!=c:observed[(x,y)]=(f,c)
    require(observed==permitted and len(observed)==18,
            "Native source changes not exactly the qualified 18 source cells")
    print("NATIVE_TWO_VALID_W_INDEPENDENT_EXACT_SOURCE_MAP_PASS",len(observed))
    return set(observed)

def incidence(edges,cell):
    return ({tuple(e["from"]) for e in edges if tuple(e["to"])==cell},
            {tuple(e["to"]) for e in edges if tuple(e["from"])==cell})

def main(folder):
    require(os.path.isdir(folder),"Native raw trace directory missing")
    protected=exact_diff()
    path=os.path.join(folder,"native_two_valid_w_evidence.json")
    with open(path,"r",encoding="utf-8") as f:rec=json.load(f)
    require(rec["schema"]=="befunge-stage1-two-valid-w-native-v2" and
            rec["status"]=="QA_HISTORICAL_PRODUCTION_REPLAY_NOT_STAGE1_ACCEPTANCE" and
            rec["candidate_blob"]==SRC_SHA and
            rec["source_exact_changed_cells"]==18 and
            rec["two_valid_w_comparison_outcomes"] is True,
            "Native qualification report scope/provenance invalid")
    data=rec["cases"]
    require(len(data)==17 and
            tuple(x["case"] for x in data)==corpus.LABELS and
            sum(bool(x["valid"]) for x in data)==14 and
            rec["wide_oracle_cases"]==22,
            "Native 17+22 evidence corpus incomplete")
    source=graph.load_source(SOURCE)
    totals={"valid_right":0,"valid_straight":0,"invalid_upper":0,
            "upper":0,"lower":0}
    result=[]
    for item in data:
        label=item["case"]
        filename=item["trace"]
        require(filename==label+".new.tsv","Native trace filename substitution")
        file_path=os.path.join(folder,filename)
        with open(file_path,"rb") as f:digest=hashlib.sha256(f.read()).hexdigest()
        require(digest==item["trace_sha256"],"Native trace changed "+label)
        proof=graph.analyze(source,file_path)
        st=proof["statistics"];ops=proof["arithmetic_executed_opcodes"]
        edges=proof["observed_directed_edges"]
        reads={tuple((v["x"],v["y"])) for v in proof["read_targets"]}
        writes={tuple((v["x"],v["y"])) for v in proof["write_targets"]}
        require(not ((reads|writes)&protected) and
                st["reads"]==st["reads_completed"] and
                st["writes"]==st["writes_completed"] and
                st["native_ip_ids"]==1 and
                st["executed_content_changing_gate_writes"]>=2,
                "Native w patch source read/write collided or g/p incomplete "+label)
        wfrom,wto=incidence(edges,W)
        ufrom,uto=incidence(edges,SENTRY)
        jfrom,jto=incidence(edges,TURN)
        cells={(x["x"],x["y"]):x for x in proof["executed_source_map"]}
        require(wfrom=={(951,1333)} and
                ops.get("w",0)==1 and
                cells[W]["initial_byte"]==ord("w") and
                cells[W]["final_byte"]==ord("w") and
                cells[W]["visits"]==1,
                "actual Native w not executed from common input-selected predecessor "+label)
        if label in LOWER:
            require(item["group"]=="lower" and item["mode"]=="straight" and
                    wto=={SENTRY} and
                    ufrom=={W} and uto=={(950,1331)} and
                    jfrom=={(951,1335),(951,1337)} and
                    jto=={(950,1336),(952,1336)} and
                    cells[TURN]["visits"]==2 and
                    cells[TURN]["arrival_velocity_count"]==2 and
                    ops.get("_",0)==1,
                    "valid/lower Native shared w/_ and exact dual junction lost "+label)
            totals["lower"]+=1
            if item["valid"]:totals["valid_straight"]+=1
        elif label=="invalid_big_sign":
            require(item["group"]=="invalid" and item["mode"]=="straight" and
                    wto=={SENTRY} and ufrom=={W} and
                    uto=={(952,1331)} and not jfrom and not jto and
                    ops.get("_",0)==1,
                    "invalid-upper preserved Native _ exit not exact "+label)
            totals["invalid_upper"]+=1
        else:
            require(item["group"]=="upper" and item["mode"]=="right" and
                    wto=={(952,1332)} and
                    not ufrom and not uto and not jfrom and not jto and
                    ops.get("_",0)==0 and
                    ops.get("r",0)==1,
                    "valid/upper right arm or reflective r lost "+label)
            totals["upper"]+=1
            if item["valid"]:totals["valid_right"]+=1
        result.append({"case":label,"valid":item["valid"],
                       "w_successor":sorted(wto),"underscore_successors":sorted(uto),
                       "lower_node_in_degree":len(jfrom),
                       "lower_node_out_degree":len(jto),
                       "executed_w":ops.get("w",0),"executed_underscore":ops.get("_",0),
                       "native_source_trace_sha256":digest})
        print("NATIVE_TWO_VALID_W_INDEPENDENT_GRAPH_AND_MEMORY_PASS",
              label,item["mode"],"valid",item["valid"])
    require(totals["valid_right"]>=2 and totals["valid_straight"]>=2 and
            totals["invalid_upper"]==1 and totals["upper"]==10 and totals["lower"]==6,
            "VALID two-branch route/invalid-upper totals changed "+repr(totals))
    with open(os.path.join(folder,"native_two_valid_w_graph_audit.json"),
              "w",encoding="utf-8") as writer:
        json.dump({"schema":"stage1-w-two-valid-arms-graph-independent-v1",
           "status":"QA_CANDIDATE_ONLY_FINAL_ACCEPTANCE_OPEN",
           "candidate_blob":SRC_SHA,"measured":totals,
           "native_new_fungespace_cell_collisions":0,"cases":result},
           writer,sort_keys=True,indent=2)
    print("NATIVE_TWO_VALID_W_INDEPENDENT_GRAPH_MEMORY_PASS",
          len(result),"real Native traces",totals)
    print("FUNCTIONAL_QA_PASS=NO GEOMETRIC_SPAGHETTI_QA_PASS=NO")
if __name__=="__main__":
    require(len(sys.argv)==2,"usage: independent Native w audit TRACE_DIRECTORY")
    main(sys.argv[1])
