#!/usr/bin/env python3
"""Stage 1 independent physical stack-lineage audit for exact 4-cell candidate.

This is a finite test of the actual Native PyFunge recorded route, NOT a
universal claim of correctness. The 13 observed branch interventions first
share five EXACT same instructions but differ in all stack frames, while IP
mode/input cursor, observed p-cell map remain identical. Only the 12 valid
branches change final numeric output to seven -1 fields after bypassing the
new literal 1; the invalid input remains rejected. Pin source/measurement,
check raw state pairs (not flags), reject hostile counterexamples.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PRODUCTION="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
LABELS=(
 "foundation_cross","mixed_small","negative_positive",
 "foundation_neighbor_forward","foundation_neighbor_reverse",
 "negative_equal_high","negative_high_forward","negative_high_reverse",
 "cross_high_forward","foundation_to_origin","foundation_to_recent",
 "decimal_cross_reverse","invalid_zero_sign")
CHANGES=[[948,1331,"6","7"],[951,1337,"^","1"],
         [951,1338," ","^"],[952,1336,"1"," "]]
BAD=["-1"]*7

def require(ok,message):
    if not ok:raise AssertionError(message)

def gitblob(b):
    return hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\0"+b).hexdigest()

def check(d):
    require(d.get("schema")=="befunge-stage1-native-four-cell-12-valid-causality-v1"
         and d.get("status")=="EXPLORATORY_NOT_PRODUCTION_STAGE1_OPEN"
         and d.get("original_production_git_blob")==PRODUCTION
         and d.get("candidate_git_blob")==CANDIDATE
         and d.get("four_cells_modified")==CHANGES
         and d.get("real_native_programs")==26
         and d.get("real_native_intervention_pairs")==13
         and d.get("native_valid_causal_cases")==12
         and d.get("native_invalid_preserved")==1
         and d.get("stage1_complete") is False
         and d.get("qa_production_modified") is False
         and d.get("canonical_branch_modified") is False,
         "QA-only pinned Native source, counts or Stage 1 scope changed")
    rows=d.get("records")
    require(isinstance(rows,list) and len(rows)==13
            and tuple(x.get("case") for x in rows)==LABELS,
            "13 Native source-trace input classes missing/reordered")
    counts={"same_motion":0,"stack_divergence":0,"equal_context":0,
            "equal_p_memory":0,"valid_output_causes":0,
            "error_path_preserved":0,"control_literal":0}
    for index,row in enumerate(rows):
        valid=index!=12
        a=row.get("original")
        b=row.get("opposite_turn")
        expect=row.get("reference_output")
        require(row.get("valid") is valid and
                isinstance(a,dict) and isinstance(b,dict)
                and isinstance(expect,list) and len(expect)==7
                and all(isinstance(x,str) for x in expect)
                and a.get("output")==expect and
                a.get("status")=="normal" and b.get("status")=="normal"
                and a.get("remaining_ips")==0 and b.get("remaining_ips")==0,
                "Native control/oracle vector or completion state invalid")
        require(a.get("gate",{}).get("executed_opcode")=="]"
                and b.get("gate",{}).get("executed_opcode")=="["
                and a["gate"].get("restored") is True
                and b["gate"].get("restored") is True
                and a["gate"].get("tick")==b["gate"].get("tick")
                and a["gate"].get("direction_before")==b["gate"].get("direction_before")
                and a["gate"].get("direction_after")!=b["gate"].get("direction_after"),
                "genuine Native one-instruction turn override missing")
        require(row.get("first_shared_native_motion_indices")==[19,0]
                and isinstance(row.get("five_shared_native_motion_comparisons"),list)
                and len(row["five_shared_native_motion_comparisons"])==5,
                "exact first real geometric rejoin is not 19->0 plus five steps")
        require(row.get("real_literal_executed_control")==1
                and row.get("real_literal_executed_opposite")==0,
                "Native moved literal not uniquely executed on original loop")
        counts["control_literal"]+=1
        expect_saved=143 if valid else 19
        require(type(a.get("steps")) is int and type(b.get("steps")) is int
                and a["steps"]-b["steps"]==expect_saved,
                "rejoined Native path no longer has exact observed step delta")
        require(row.get("changed_output_or_termination") is valid
                and (b.get("output")==BAD if valid else b.get("output")==expect),
                "real post-rejoin stack delta did not propagate to expected output")
        if valid:
            require(expect!=BAD,
                    "valid control itself returns error sentinel")
            counts["valid_output_causes"]+=1
        else:
            require(expect==BAD,"error-control not an invalid reference")
            counts["error_path_preserved"]+=1
        previous_position=None
        for step,snap in enumerate(row["five_shared_native_motion_comparisons"]):
            m=snap.get("native_motion")
            require(isinstance(m,list) and len(m)==4
                    and all(type(z) is int for z in m)
                    and isinstance(snap.get("native_opcode"),int)
                    and snap["equal_frames"] is False
                    and snap["equal_context"] is True
                    and snap["equal_p_modified"] is True,
                    "raw five-state Native divergence classification forged")
            for key,ca,cb,required in (
               ("stack","control_frames","flipped_frames",False),
               ("context","control_ip_context","flipped_ip_context",True),
               ("p_memory","control_p_modified","flipped_p_modified",True)):
                aa=snap.get(ca);bb=snap.get(cb)
                require((aa==bb) is required,
                        "raw Native "+key+" values violate measured physical comparison")
            if previous_position is not None:
                require(m[0]==previous_position[0]+previous_position[2] and
                        m[1]==previous_position[1]+previous_position[3],
                        "Native common five IP positions/directions not contiguous")
            previous_position=m
        counts["same_motion"]+=1
        counts["stack_divergence"]+=1
        counts["equal_context"]+=1
        counts["equal_p_memory"]+=1
    require(counts=={"same_motion":13,"stack_divergence":13,
                     "equal_context":13,"equal_p_memory":13,
                     "valid_output_causes":12,"error_path_preserved":1,
                     "control_literal":13},
            "Native stack-lineage evidence matrix not complete")
    return {"native_control_mutant_pairs":13,
            "first_shared_five_state_route":counts["same_motion"],
            "different_full_stack_frames":counts["stack_divergence"],
            "identical_ip_context":counts["equal_context"],
            "identical_observed_p_cells":counts["equal_p_memory"],
            "valid_output_causal":counts["valid_output_causes"],
            "invalid_preserved":counts["error_path_preserved"],
            "still_qa_only":True}

def main(directory):
    root=Path(directory)
    prod=Path("src/interleaved_work_counts.b98").read_bytes()
    variant=(root/"four_cell_candidate.b98").read_bytes()
    require(gitblob(prod)==PRODUCTION and gitblob(variant)==CANDIDATE,
            "Native pinned 2D production/candidate source changed")
    actual=[]
    for y,(left,right) in enumerate(zip(prod.split(b"\n"),variant.split(b"\n"))):
        require(len(left)==len(right),"Native 2D row dimensions changed")
        for x,(p,q) in enumerate(zip(left,right)):
            if p!=q:actual.append([x,y,chr(p),chr(q)])
    require(actual==sorted(CHANGES,key=lambda item:(item[1],item[0])),
            "Native Funge-space source changed beyond precise four cells")
    data=json.loads((root/"four_cell_twelve_valid_causality.json").read_text(encoding="utf-8"))
    result=check(data)
    print("NATIVE_FOUR_CELL_THIRTEEN_PHYSICAL_STACK_LINEAGES_PASS",
          json.dumps(result,sort_keys=True))
    attacks=[]
    def reject(label,callback):
        bad=copy.deepcopy(data);callback(bad)
        try:check(bad)
        except AssertionError:
            attacks.append(label)
            print("NATIVE_FOUR_CELL_STACK_LINEAGE_TAMPER_REJECT_PASS",label)
            return
        raise AssertionError("fake Native stack-lineage proof accepted: "+label)
    reject("fake_production",lambda z:z.__setitem__("original_production_git_blob","0"*40))
    reject("change_rejoin",lambda z:z["records"][0].__setitem__("first_shared_native_motion_indices",[18,0]))
    reject("remove_state",lambda z:z["records"][0]["five_shared_native_motion_comparisons"].pop())
    reject("equalize_real_stack",lambda z:z["records"][0]["five_shared_native_motion_comparisons"][0].__setitem__(
        "flipped_frames",z["records"][0]["five_shared_native_motion_comparisons"][0]["control_frames"]))
    reject("tamper_state_flag",lambda z:z["records"][0]["five_shared_native_motion_comparisons"][0].__setitem__("equal_frames",True))
    reject("change_ip",lambda z:z["records"][0]["five_shared_native_motion_comparisons"][0].__setitem__("flipped_ip_context",None))
    reject("change_p_memory",lambda z:z["records"][0]["five_shared_native_motion_comparisons"][0].__setitem__("flipped_p_modified",None))
    reject("change_motion",lambda z:z["records"][0]["five_shared_native_motion_comparisons"][1].__setitem__("native_motion",[0,0,1,0]))
    reject("bad_steps",lambda z:z["records"][0]["opposite_turn"].__setitem__("steps",z["records"][0]["opposite_turn"]["steps"]+1))
    reject("remove_literal",lambda z:z["records"][0].__setitem__("real_literal_executed_control",0))
    reject("fake_output",lambda z:z["records"][0]["opposite_turn"]["output"].__setitem__(0,"0"))
    reject("fake_error",lambda z:z["records"][-1]["opposite_turn"]["output"].__setitem__(0,"0"))
    reject("invert_gate",lambda z:z["records"][0]["opposite_turn"]["gate"].__setitem__("executed_opcode","]"))
    reject("fake_completion",lambda z:z.__setitem__("stage1_complete",True))
    require(len(attacks)==14,"Native stack-lineage tamper gate missing")
    (root/"four_cell_native_stack_lineage_audit.json").write_text(
       json.dumps({"schema":"befunge-stage1-four-cell-stack-lineage-audit-v1",
                   "physical_rejoin_results":result,
                   "forged_reports_rejected":attacks,
                   "stage1_complete":False},sort_keys=True,indent=2)+"\n",
       encoding="utf-8")
    print("NATIVE_FOUR_CELL_STACK_LINEAGE_FOURTEEN_TAMPERS_REJECTED_PASS")
    print("FULL_GEOMETRIC_SPAGHETTI_QA_PASS=NO LAST_COMPLETED_STAGE=0")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: real Native candidate 12-valid artifact dir")
    main(sys.argv[1])
