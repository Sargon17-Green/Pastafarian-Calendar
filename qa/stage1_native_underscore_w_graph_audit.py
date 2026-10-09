#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent actual PyFunge STEP/READ/WRITE audit of computed '_' and w.

Checks 13-cell byte-level source map, exact one-byte mutant, Native trace
SHA-256 and temporally replayed Funge-space g/p memory per input. No
Python calendar calculation or final Stage-1 acceptance.
"""
import hashlib
import json
import os
import sys
import stage1_native_route_graph as graph
import stage1_native_diverse_geometry_audit as corpus

BASE="qa/interleaved_work_counts_w_data_branch_candidate.b98"
OUT="/underscore"
CANDIDATE="underscore_w_candidate.b98"
MUTANT="underscore_removed.b98"
EXPECTED_SHA="c0414e8dae9f933b5edb3405f7fc4e7f0684c04ce776acb541b9dd36c9810bbd"
U=(951,1334)
JOIN=(951,1333)
W=(951,1332)
LOWER={"foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse"}

def require(ok,msg):
    if not ok: raise AssertionError(msg)

def source_map(directory):
    a=open(BASE,"rb").read()
    b=open(os.path.join(directory,CANDIDATE),"rb").read()
    m=open(os.path.join(directory,MUTANT),"rb").read()
    require(hashlib.sha256(b).hexdigest()==EXPECTED_SHA,
            "Native underscore input file changed since CI source qualification")
    aa=a.split(b"\n");bb=b.split(b"\n")
    require(len(aa)==len(bb)==2016 and
            [len(x) for x in aa]==[len(x) for x in bb] and
            max(map(len,bb))==1531,
            "Native underscored program changed 2D Funge bounds")
    expected={(951,1334):(ord(":"),ord("_")),
              (951,1333):(ord("0"),ord("^")),
              (953,1334):(ord("+"),ord(":")),
              (955,1334):(ord("1"),ord("^")),
              (955,1333):(32,ord("<"))}
    for offset,ch in enumerate("1:0801-x"):
        expected[(950-offset,1334)]=(32,ord(ch))
    changed={}
    for y,(former,now) in enumerate(zip(aa,bb)):
        for x,(l,r) in enumerate(zip(former,now)):
            if l!=r:changed[(x,y)]=(l,r)
    require(len(expected)==13 and changed==expected,
            "Native underscore code includes extra/unexpected byte edits")
    offset=sum(len(x)+1 for x in bb[:U[1]])+U[0]
    require(len(m)==len(b) and
            [(i,x,y) for i,(x,y) in enumerate(zip(b,m)) if x!=y]
            ==[(offset,ord("_"),32)],
            "alleged Native causal mutant is not EXACT single underscore removal")
    return graph.load_source(os.path.join(directory,CANDIDATE)),set(expected)

def endpoints(edges,point):
    pred={tuple(x["from"]) for x in edges if tuple(x["to"])==point}
    succ={tuple(x["to"]) for x in edges if tuple(x["from"])==point}
    return pred,succ

def main(directory):
    require(os.path.isdir(directory),"Native underscore artifact directory missing")
    source,modified=source_map(directory)
    with open(os.path.join(directory,"underscore_w_qa_proof.json"),encoding="utf-8") as f:
        report=json.load(f)
    require(report["schema"]=="befunge-stage1-native-underscore-w-v1" and
            report["status"]=="QA_TEST_ONLY_UNPROMOTED" and
            report["source_sha256"]==EXPECTED_SHA and
            report["source_exact_edit_count"]==13,
            "Native underscore source provenance/report mismatch")
    samples=report["cases"]
    require(len(samples)==17 and
            tuple(x["case"] for x in samples)==corpus.LABELS and
            len(report["observed_comparator_outcomes"])==2 and
            len(set(report["observed_comparator_outcomes"]))==2,
            "real 17-case input oracle/route evidence missing")
    result=[]
    for row in samples:
        label=row["case"]
        file_name=label+".tsv"
        path=os.path.join(directory,file_name)
        with open(path,"rb") as f:
            sha=hashlib.sha256(f.read()).hexdigest()
        require(sha==row["trace_sha256"],
                "Native underscore raw interpreter trace digest mismatch "+label)
        data=graph.analyze(source,path)
        stats=data["statistics"]
        ops=data["arithmetic_executed_opcodes"]
        edges=data["observed_directed_edges"]
        protected={tuple((c["x"],c["y"])) for c in
                   data["read_targets"]+data["write_targets"]}
        require(not(protected & modified) and
                stats["reads"]==stats["reads_completed"] and
                stats["writes"]==stats["writes_completed"] and
                stats["native_ip_ids"]==1 and
                stats["executed_content_changing_gate_writes"]>=2,
                "Native executable source has collision or incomplete p/g "+label)
        u_pred,u_next=endpoints(edges,U)
        _,join_next=endpoints(edges,JOIN)
        u_node=next((x for x in data["executed_source_map"]
                     if (x["x"],x["y"])==U),None)
        w_node=next((x for x in data["executed_source_map"]
                     if (x["x"],x["y"])==W),None)
        if label in LOWER:
            require(row["branch"]=="lower" and row["mode"] is None and
                    ops.get("_",0)==ops.get("w",0)==0 and
                    not u_pred and not u_next and u_node is None and w_node is None,
                    "unselected Native underscore/w arithmetic corridor executed "+label)
        else:
            mode="east" if label=="invalid_big_sign" else "west"
            downstream={(952,1334)} if mode=="east" else {(950,1334)}
            require(row["branch"]=="upper" and row["mode"]==mode and
                    u_pred=={(951,1335)} and u_next==downstream and
                    join_next=={W} and
                    ops.get("_",0)==1 and ops.get("w",0)==1 and
                    u_node is not None and u_node["visits"]==1 and
                    u_node["initial_byte"]==ord("_") and
                    u_node["final_byte"]==ord("_") and
                    w_node is not None and w_node["visits"]==1 and
                    w_node["initial_byte"]==ord("w"),
                    "Native input-selected underscore did not rejoin real w route "+label)
        result.append({"case":label,"mode":row["mode"],"trace_sha256":sha,
                       "p_events":stats["writes"],"g_events":stats["reads"],
                       "new_source_memory_collisions":0})
        print("NATIVE_UNDERSCORE_INDEPENDENT_IP_MEMORY_GRAPH_PASS",label,row["mode"])
    evidence={"schema":"befunge-stage1-independent-underscore-w-native-graph-v1",
              "status":"QA_ONLY_NOT_STAGE1_ACCEPTANCE","source_sha256":EXPECTED_SHA,
              "source_modified_cells":len(modified),
              "traces":len(result),"new_cell_p_g_collisions":0,
              "cases":result}
    with open(os.path.join(directory,"underscore_independent_graph.json"),
              "w",encoding="utf-8") as f:
        json.dump(evidence,f,sort_keys=True,indent=2);f.write("\n")
    print("NATIVE_UNDERSCORE_INDEPENDENT_FULL_GRAPH_PASS",len(result),
          "Native traces, zero new Funge-space collisions")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: native_underscore_graph_audit TRACE_DIR")
    main(sys.argv[1])
