#!/usr/bin/env python3
"""Independent Native auditor: 12 valid loop-dependent, one invalid preserved.

Check source bytes for all FOUR and ONLY four real Befunge changes.
Verify real Native full-output and one-step modified opcode against pinned
12 valid and one error case; reject 16 falsified outcome/scope reports.
Not a calendar implementation and not Stage-1 acceptance.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
PATCHES=[[948,1331,"6","7"],[951,1337,"^","1"],
         [951,1338," ","^"],[952,1336,"1"," "]]
LABELS=(
 "foundation_cross","mixed_small","negative_positive",
 "foundation_neighbor_forward","foundation_neighbor_reverse",
 "negative_equal_high","negative_high_forward","negative_high_reverse",
 "cross_high_forward","foundation_to_origin","foundation_to_recent",
 "decimal_cross_reverse","invalid_zero_sign"
)

def need(ok,reason):
    if not ok:raise AssertionError(reason)

def blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode("ascii")+b"\0"+data).hexdigest()

def check(d):
    need(d.get("schema")=="befunge-stage1-native-four-cell-12-valid-causality-v1"
         and d.get("status")=="EXPLORATORY_NOT_PRODUCTION_STAGE1_OPEN"
         and d.get("original_production_git_blob")==PIN
         and d.get("candidate_git_blob")==CANDIDATE
         and d.get("four_cells_modified")==PATCHES
         and d.get("real_native_programs")==26
         and d.get("real_native_intervention_pairs")==13
         and d.get("valid_cases")==12
         and d.get("invalid_cases")==1
         and d.get("native_valid_oracle_cases")==12
         and d.get("stage1_complete") is False
         and d.get("qa_production_modified") is False
         and d.get("canonical_branch_modified") is False,
         "Befunge four-cell candidate source/QA boundary changed")
    rows=d.get("records")
    need(isinstance(rows,list) and len(rows)==13
         and tuple(r.get("case") for r in rows)==LABELS,
         "pinned Native wide-case matrix missing or reordered")
    changed_valid=0
    preserved_invalid=0
    ctl_reads=0
    mutant_reads=0
    for n,r in enumerate(rows):
        valid=n!=12
        vals=r.get("input_fields")
        expect=r.get("reference_output")
        need(r.get("valid") is valid
             and isinstance(vals,list) and len(vals)==4
             and all(type(x) is int for x in vals)
             and isinstance(expect,list) and len(expect)==7
             and all(isinstance(x,str) for x in expect)
             and (valid or expect==["-1"]*7),
             "expected independent native input or reference malformed")
        original=r.get("original")
        inverted=r.get("opposite_turn")
        need(isinstance(original,dict) and isinstance(inverted,dict),
             "real Native control/mutant pair missing")
        for entry,expected_opcode in ((original,"]"),(inverted,"[")):
            g=entry.get("gate")
            need(isinstance(g,dict)
                 and g.get("executed_opcode")==expected_opcode
                 and g.get("restored") is True
                 and type(g.get("tick")) is int
                 and 1<g["tick"]<210000
                 and isinstance(g.get("direction_before"),list)
                 and len(g["direction_before"])==2
                 and isinstance(g.get("direction_after"),list)
                 and len(g["direction_after"])==2
                 and type(entry.get("steps")) is int
                 and g["tick"]<entry["steps"]<=210001
                 and entry.get("status")=="normal"
                 and entry.get("remaining_ips")==0
                 and isinstance(entry.get("output"),list)
                 and len(entry["output"])==7
                 and all(isinstance(x,str) for x in entry["output"]),
                 "Native physical one-op turn/witness invalid")
        need(original["gate"]["tick"]==inverted["gate"]["tick"]
             and original["gate"]["direction_before"]==
                 inverted["gate"]["direction_before"]
             and original["gate"]["direction_after"]!=
                 inverted["gate"]["direction_after"]
             and original["output"]==expect,
             "candidate Native unmodified replay diverges from oracle or gate")
        effect=(original["status"]!=inverted["status"] or
                original["remaining_ips"]!=inverted["remaining_ips"] or
                original["output"]!=inverted["output"])
        need(r.get("changed_output_or_termination") is effect
             and effect is valid
             and r.get("changed_all_seven_fields") is all(
                 a!=b for a,b in zip(original["output"],inverted["output"])),
             "Native effect or full-output difference claim invented")
        literal_control=r.get("real_literal_executed_control")
        literal_mutated=r.get("real_literal_executed_opposite")
        need(type(literal_control) is int and literal_control>=1
             and literal_control<=256
             and type(literal_mutated) is int and literal_mutated==0,
             "actual newly routed Native literal was not uniquely loop-side")
        ctl_reads+=literal_control
        mutant_reads+=literal_mutated
        shared=r.get("first_shared_native_motion_indices")
        states=r.get("five_shared_native_motion_comparisons")
        if shared is None:
            need(states==[],"shared native state present without matching motion")
        else:
            need(isinstance(shared,list) and len(shared)==2
                 and all(type(x) is int and 0<=x<252 for x in shared)
                 and isinstance(states,list) and len(states)==5,
                 "five actual native shared events missing")
            for state in states:
                need(isinstance(state.get("native_motion"),list)
                     and len(state["native_motion"])==4
                     and type(state.get("native_opcode")) is int
                     and 0<=state["native_opcode"]<=255,
                     "Native shared IP motion/opcode forged")
                for name,left,right in (
                    ("equal_frames","control_frames","flipped_frames"),
                    ("equal_context","control_ip_context","flipped_ip_context"),
                    ("equal_p_modified","control_p_modified","flipped_p_modified")):
                    need(state.get(name) is (state.get(left)==state.get(right)),
                         "fake Native "+name+" raw state comparison")
        if valid:changed_valid+=effect
        else:preserved_invalid+=not effect
    need(d.get("native_valid_causal_cases")==changed_valid==12
         and d.get("native_invalid_preserved")==preserved_invalid==1
         and d.get("valid_literal_control_visits")==ctl_reads-(
             rows[-1]["real_literal_executed_control"])
         and d.get("valid_literal_mutant_visits")==mutant_reads-
             rows[-1]["real_literal_executed_opposite"],
         "false Native 12+1 effect or literal count")
    return {"valid_native_causal_cases":changed_valid,"invalid_preserved":preserved_invalid,
            "native_programs":26,"stage1_final_acceptance":False}

def main(folder):
    root=Path(folder)
    original=Path("src/interleaved_work_counts.b98").read_bytes()
    mutated=(root/"four_cell_candidate.b98").read_bytes()
    need(blob(original)==PIN and blob(mutated)==CANDIDATE,
         "Native physical 2D production/candidate bytes not pinned")
    a=original.split(b"\n")
    b=mutated.split(b"\n")
    need(len(a)==len(b),"Native source line count mutated")
    differences=[]
    for y,(line_a,line_b) in enumerate(zip(a,b)):
        need(len(line_a)==len(line_b),"Native 2D Funge width changed")
        for x,(v,w) in enumerate(zip(line_a,line_b)):
            if v!=w:differences.append([x,y,chr(v),chr(w)])
    need(differences==sorted(PATCHES,key=lambda e:(e[1],e[0])),
         "Native candidate changed any source cell outside exact four")
    report=json.loads((root/"four_cell_twelve_valid_causality.json").read_text("utf-8"))
    result=check(report)
    print("NATIVE_12_VALID_FOUR_CELL_INDEPENDENT_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    attacks=[]
    def reject(name,alter):
        bad=copy.deepcopy(report)
        alter(bad)
        try:check(bad)
        except AssertionError:
            attacks.append(name)
            print("NATIVE_12_VALID_FOUR_CELL_FORGERY_REJECT_PASS",name)
            return
        raise AssertionError("falsified Native twelve-case report wrongly accepted: "+name)
    reject("source",lambda d:d.__setitem__("candidate_git_blob","0"*40))
    reject("missing_case",lambda d:d["records"].pop())
    reject("wrong_case",lambda d:d["records"][0].__setitem__("case","wrong"))
    reject("change_input_shape",lambda d:d["records"][0]["input_fields"].pop())
    reject("wrong_reference",lambda d:d["records"][0]["reference_output"].pop())
    reject("bad_sham",lambda d:d["records"][0]["original"]["output"].__setitem__(0,"FORGED"))
    reject("wrong_mutant",lambda d:d["records"][0]["opposite_turn"]["output"].__setitem__(0,
            d["records"][0]["original"]["output"][0]))
    reject("wrong_gate_opcode",lambda d:d["records"][0]["opposite_turn"]["gate"].__setitem__("executed_opcode","]"))
    reject("source_not_restored",lambda d:d["records"][0]["opposite_turn"]["gate"].__setitem__("restored",False))
    reject("bad_turn",lambda d:d["records"][0]["opposite_turn"]["gate"].__setitem__(
           "direction_after",d["records"][0]["original"]["gate"]["direction_after"]))
    reject("mutant_visited_literal",lambda d:d["records"][0].__setitem__("real_literal_executed_opposite",1))
    reject("wrong_valid_status",lambda d:d["records"][-1].__setitem__("valid",True))
    reject("fake_count",lambda d:d.__setitem__("native_valid_causal_cases",11))
    reject("lie_about_error",lambda d:d["records"][-1].__setitem__("changed_output_or_termination",True))
    reject("fake_source_changes",lambda d:d.__setitem__("four_cells_modified",[]))
    reject("premature_acceptance",lambda d:d.__setitem__("stage1_complete",True))
    need(len(attacks)==16,"Native adversarial controls incomplete")
    (root/"four_cell_twelve_valid_causality_audit.json").write_text(
        json.dumps({"schema":"befunge-stage1-twelve-valid-four-cell-audit-v1",
                    "observed":result,"forgeries_rejected":attacks,
                    "stage1_complete":False},sort_keys=True,indent=2)+"\n",
        encoding="utf-8")
    print("NATIVE_12_VALID_FOUR_CELL_SIXTEEN_TAMPERS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: four-cell wide Native evidence directory")
    main(sys.argv[1])
