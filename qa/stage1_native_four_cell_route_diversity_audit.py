#!/usr/bin/env python3
"""Independent bounded geometry audit of real Native BF98 fork32 evidence.

Only the first 512 directed instruction records following each observed fork
are analyzed. This is not a full execution graph, numeric oracle or Stage 1
acceptance. Python here audits Native evidence, not calendar computation.
"""
import copy
import hashlib
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
SCRATCH=(1490,1600)
SCHEMA="befunge-stage1-four-cell-native-32-valid-fork-v3"

def need(x,message):
    if not x:raise AssertionError(message)

def memory_map(cells):
    need(type(cells) is list,"missing Native p-memory snapshot")
    out={}
    for item in cells:
        need(type(item) in (list,tuple) and len(item)==3
             and all(type(v) is int for v in item[:2])
             and type(item[2]) is str and item[2].lstrip("-").isdigit(),
             "invalid Native p-memory snapshot cell")
        xy=tuple(item[:2])
        need(xy not in out,"duplicated Native p-memory snapshot cell")
        out[xy]=item[2]
    return out

def join(a,b):
    positions={}
    for i in range(len(a)-4):
        key=tuple(tuple(v) for v in a[i:i+5])
        positions.setdefault(key,i)
    for j in range(len(b)-4):
        key=tuple(tuple(v) for v in b[j:j+5])
        if key in positions:
            return positions[key],j,[list(v) for v in key]
    return None

def audit(doc):
    need(type(doc) is dict and doc.get("schema")==SCHEMA
         and doc.get("status")=="NATIVE_QA_ONLY_FORK_CAUSALITY_PROFILE_STAGE1_OPEN"
         and doc.get("source_git_blob")==SOURCE
         and doc.get("candidate_git_blob")==CANDIDATE
         and doc.get("native_programs")==64
         and doc.get("native_reference_cases")==32
         and doc.get("stage1_complete") is False
         and doc.get("automatic_promotion") is False
         and doc.get("native_pg_lineage_recorded") is True,
         "native fork32 scope/source/nonpromotion drift")
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==32
         and len({r.get("label") for r in rows})==32,
         "exactly 32 distinct native input rows required")
    edges=defaultdict(set)
    all_nodes=set()
    directions=defaultdict(set)
    fingerprints=defaultdict(list)
    offsets=Counter()
    scratch_orientations=Counter()
    causal=Counter()
    snapshot_pairs=0
    for row in rows:
        label=row["label"]
        control=row.get("control");forced=row.get("forced")
        need(type(control) is dict and type(forced) is dict
             and control.get("output")==row.get("reference_7")
             and control.get("status")=="normal"
             and control.get("remaining_ips")==0,
             "real Native control/oracle incomplete: "+label)
        operand=row.get("natural_nonzero")
        need(type(operand) is int and operand in (0,1)
             and row.get("forced_nonzero")==1-operand,
             "fork inversion class drift: "+label)
        causal[(operand,bool(row.get("changed_final_output_or_termination")))]+=1
        paths=[]
        for side,key,summary in (
            ("control","complete_motion_control",control),
            ("forced","complete_motion_forced",forced)):
            path=row.get(key)
            need(type(path) is list and len(path)==512
                 and all(type(v) is list and len(v)==4
                         and all(type(n) is int for n in v) for v in path),
                 "exact 512-event directed Native trace missing: "+label)
            prefix=summary.get("first_5_motion")
            need(type(prefix) is list and len(prefix)==5
                 and [v[:4] for v in prefix]==path[:5],
                 "native first-motion witness mismatch: "+label)
            for i,item in enumerate(path):
                node=tuple(item)
                all_nodes.add(node)
                directions[tuple(item[:2])].add(tuple(item[2:]))
                if i+1<len(path):edges[node].add(tuple(path[i+1]))
            signature=hashlib.sha256(json.dumps(
                path,separators=(",",":"),ensure_ascii=True).encode("ascii")).hexdigest()
            fingerprints[signature].append(label+":"+side)
            paths.append(path)
        matched=join(*paths)
        need(matched is not None
             and list(matched[:2])==row.get("first_shared_motion_offsets")
             and matched[2]==row.get("five_shared_motion"),
             "actual Native 5-event rejoin not reproducible: "+label)
        offsets[tuple(matched[:2])]+=1
        for k in range(5):
            left=memory_map(row["five_p_mutations_control"][k])
            right=memory_map(row["five_p_mutations_forced"][k])
            changed={xy for xy in left.keys()|right.keys()
                     if left.get(xy)!=right.get(xy)}
            need(changed=={SCRATCH},
                 "Native post-join Funge-space difference outside scratch: "+label)
            pair=(left.get(SCRATCH),right.get(SCRATCH))
            need(pair in (("12",None),(None,"12")),
                 "Native scratch not 12-vs-blank: "+label)
            scratch_orientations[pair]+=1
            snapshot_pairs+=1
    result={
       "native_input_cases":len(rows),"native_branch_executions":64,
       "first_postfork_directed_events_per_run":512,
       "distinct_route_fingerprints":len(fingerprints),
       "route_fingerprint_counts":sorted(
           (len(v) for v in fingerprints.values()),reverse=True),
       "directed_unique_nodes":len(all_nodes),
       "directed_nodes_with_outgoing_edges":len(edges),
       "directed_unique_edges":sum(len(v) for v in edges.values()),
       "directed_fork_nodes":sum(len(v)>1 for v in edges.values()),
       "coordinates_with_multiple_directions":sum(
           len(v)>1 for v in directions.values()),
       "first_five_motion_rejoin_offsets":{
           "%d:%d"%k:v for k,v in sorted(offsets.items())},
       "native_snapshot_pairs":snapshot_pairs,
       "scratch_12_natural_blank_forced":scratch_orientations[("12",None)],
       "scratch_blank_natural_12_forced":scratch_orientations[(None,"12")],
       "output_causality":{
           "zero_true":causal[(0,True)],"zero_false":causal[(0,False)],
           "nonzero_true":causal[(1,True)],"nonzero_false":causal[(1,False)]}
    }
    need(result["route_fingerprint_counts"]==[32,20,12]
         and result["distinct_route_fingerprints"]==3
         and result["directed_unique_nodes"]==633
         and result["directed_nodes_with_outgoing_edges"]==632
         and result["directed_unique_edges"]==634
         and result["directed_fork_nodes"]==2
         and result["coordinates_with_multiple_directions"]==6
         and result["first_five_motion_rejoin_offsets"]=={"33:97":12,"109:33":20}
         and result["native_snapshot_pairs"]==160
         and result["scratch_12_natural_blank_forced"]==100
         and result["scratch_blank_natural_12_forced"]==60
         and result["output_causality"]=={
             "zero_true":12,"zero_false":0,"nonzero_true":0,"nonzero_false":20},
         "bounded Native directed geometry or scratch causality drift")
    return result

def main(directory):
    root=Path(directory)
    data=json.loads((root/"four_cell_fork_32_control_mutant.json").read_text(
        encoding="utf-8"))
    measured=audit(data)
    tests=[
       ("false_stage1",lambda d:d.__setitem__("stage1_complete",True)),
       ("wrong_source",lambda d:d.__setitem__("candidate_git_blob","0"*40)),
       ("duplicate_label",lambda d:d["records"][0].__setitem__(
           "label",d["records"][1]["label"])),
       ("fork_operand",lambda d:d["records"][0].__setitem__(
           "forced_nonzero",1)),
       ("route_position",lambda d:d["records"][0][
           "complete_motion_control"][0].__setitem__(0,0)),
       ("route_vector",lambda d:d["records"][0][
           "complete_motion_forced"][1].__setitem__(3,777777)),
       ("join_offsets",lambda d:d["records"][0][
           "first_shared_motion_offsets"].__setitem__(0,0)),
       ("fabricated_shared_motion",lambda d:d["records"][0][
           "five_shared_motion"][0].__setitem__(0,0)),
       ("fake_scratch",lambda d:d["records"][0][
           "five_p_mutations_control"][0][-1].__setitem__(2,"999")),
       ("erase_route",lambda d:d["records"][0][
           "complete_motion_forced"].clear())
    ]
    rejected=[]
    for name,mutate in tests:
        trial=dict(data)
        trial["records"]=list(data["records"])
        trial["records"][0]=copy.deepcopy(data["records"][0])
        mutate(trial)
        try:audit(trial)
        except (AssertionError,KeyError,IndexError,TypeError):
            rejected.append(name)
        else:raise AssertionError("forged bounded Native geometry accepted: "+name)
    need(len(rejected)==10,"Native bounded geometry anti-tamper incomplete")
    output={
       "schema":"befunge-stage1-fork32-limited-route-diversity-audit-v1",
       "scope":"32_INPUTS_TWO_PATHS_FIRST_512_POSTFORK_DIRECTED_EVENTS_ONLY",
       "not_entire_execution":True,
       "not_universal_route_proof":True,
       "stage1_complete":False,
       "automatic_promotion":False,
       "geometric_spaghetti_qa_pass":False,
       "full_functional_qa_pass":False,
       "measured":measured,
       "forged_reports_rejected":rejected}
    (root/"four_cell_route_diversity_audit.json").write_text(
       json.dumps(output,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_FOUR_CELL_BOUNDED_ROUTE_DIVERSITY_AUDIT_PASS",
          json.dumps(measured,sort_keys=True))
    print("NATIVE_FOUR_CELL_ROUTE_DIVERSITY_10_TAMPERS_REJECT_PASS")
    print("CURRENT_STAGE=1 LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    need(len(sys.argv)==2,"Native fork32 artifact directory required")
    main(sys.argv[1])
