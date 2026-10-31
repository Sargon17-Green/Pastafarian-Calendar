#!/usr/bin/env python3
"""Independent finite causal Native report verifier and hostile mutations.

This checks provenance and per-case input, real one-opcode native event,
bounded effect classifications and an independent native oracle result.
It does not compute calendar arithmetic or conclude Stage 1 acceptance.
"""
import copy,hashlib,json,re,sys
from pathlib import Path
BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
DOM=tuple(range(-3,4))
HEX=re.compile(r"[0-9a-f]{64}\Z")
NUM=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def need(x,s):
    if not x:raise AssertionError(s)
def roster():
    return [(x,y,(int(x<0),abs(x),int(y<0),abs(y)))
            for x in DOM for y in DOM]
def verify(doc,require_effect=True):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-four-cell-first-literal-intervention-49-v1" and
         doc.get("status")=="FINITE_NATIVE_ACTUAL_INSTRUCTION_INTERVENTION_STAGE1_OPEN" and
         doc.get("base_git_blob")==BASE and doc.get("candidate_git_blob")==CAND and
         doc.get("literal_coordinate")==[951,1337] and
         doc.get("baseline_opcode")==49 and doc.get("temporary_opcode")==48 and
         doc.get("instruction_restored_after_native_step") is True and
         doc.get("restoration_check")=="immediately_after_edited_native_step" and
         doc.get("final_source_byte_is_ordinary_mutable_funge_space") is True and
         doc.get("grid_domain")==list(DOM) and doc.get("input_cases")==49 and
         doc.get("native_candidate_control_programs")==49 and
         doc.get("native_candidate_intervention_programs")==49 and
         doc.get("independent_befunge_reference_programs")==147 and
         doc.get("test_only") is True and doc.get("stage1_complete") is False and
         doc.get("stage2_started") is False,
         "Native first-literal provenance, executor count or Stage1 scope forged")
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==49,
         "forty-nine Native signed input rows absent")
    reached=0
    causal=0
    for row,(x,y,fields) in zip(rows,roster()):
        raw=" ".join(map(str,fields))+"\n"
        ref=row.get("native_befunge_reference_output")
        control=row.get("control")
        mutant=row.get("intervention")
        need(row.get("signed_days")==[x,y] and
             row.get("fields")==list(fields) and
             row.get("input_sha256")==hashlib.sha256(raw.encode("ascii")).hexdigest() and
             type(ref) is list and len(ref)==7 and
             all(type(v) is str and NUM.fullmatch(v) for v in ref) and
             type(control) is dict and type(mutant) is dict,
             "Native first-literal input or independent oracle forged")
        for candidate in (control,mutant):
            need(candidate.get("status") in ("normal","step_limit") and
                 type(candidate.get("steps")) is int and candidate["steps"]>0 and
                 type(candidate.get("native_lower_literal_visits")) is int and
                 candidate["native_lower_literal_visits"]>=0 and
                 type(candidate.get("native_live_literal_edits")) is int and
                 candidate["native_live_literal_edits"] in (0,1) and
                 type(candidate.get("immediate_restorations")) is int and
                 candidate["immediate_restorations"]==candidate["native_live_literal_edits"] and
                 candidate.get("restored_source_byte")==(
                     49 if candidate["native_live_literal_edits"] else None) and
                 type(candidate.get("final_source_byte")) is int and
                 type(candidate.get("remaining_ips")) is int and
                 candidate.get("remaining_ips") in (0,1) and
                 type(candidate.get("output")) is list and
                 all(type(v) is str and NUM.fullmatch(v) for v in candidate["output"]),
                 "Native actual event/restoration/bounded status forged")
            first=candidate.get("first_literal")
            if candidate["native_lower_literal_visits"]:
                need(type(first) is dict and
                     type(first.get("tick")) is int and
                     first["tick"]>0 and first["tick"]<=candidate["steps"] and
                     type(first.get("stack_depth_before")) is int and
                     first["stack_depth_before"]>=0 and
                     first.get("stringmode") is False and
                     first.get("pushed")== (48-48 if candidate is mutant else 49-48),
                     "Native first-literal executed stack value was forged")
            else:
                need(first is None,"unreached Native literal invented an opcode event")
        hits=control["native_lower_literal_visits"]
        edits=mutant["native_live_literal_edits"]
        need(control["status"]=="normal" and control["remaining_ips"]==0 and
             control["output"]==ref and
             control["native_live_literal_edits"]==0 and
             control["immediate_restorations"]==0 and edits==int(hits>0),
             "Native one-opcode mutation control/oracle/provenance differs")
        if hits==0:
            need(mutant["status"]=="normal" and mutant["remaining_ips"]==0 and
                 mutant["output"]==ref and
                 mutant["native_lower_literal_visits"]==0,
                 "unreached Native lower literal altered an output")
        effect=(mutant["status"]!="normal" or mutant["remaining_ips"]!=0 or
                mutant["output"]!=ref)
        need(row.get("causal_output_or_termination_effect") is effect,
             "Native first literal causal effect classification forged")
        reached+=int(hits>0)
        causal+=int(effect)
    need(doc.get("actual_literal_reached_input_cases")==reached and
         doc.get("literal_not_reached_input_cases")==49-reached and
         doc.get("causal_effect_input_cases")==causal,
         "Native selective literal reach/causal summary inconsistent")
    if require_effect:
        need(reached>0 and reached<49 and causal>0 and causal<=reached,
             "Native 49-grid literal causal witness absent")
    return True
def synthetic():
    rows=[]
    for x,y,fields in roster():
        raw=" ".join(map(str,fields))+"\n"
        control={"status":"normal","steps":100,"remaining_ips":0,"output":["0"]*7,
                 "native_lower_literal_visits":0,"native_live_literal_edits":0,
                 "first_literal":None,"restored_source_byte":None,
                 "immediate_restorations":0,"final_source_byte":32}
        mutant=copy.deepcopy(control)
        rows.append({"signed_days":[x,y],"fields":list(fields),
            "input_sha256":hashlib.sha256(raw.encode("ascii")).hexdigest(),
            "native_befunge_reference_output":["0"]*7,"control":control,
            "intervention":mutant,"causal_output_or_termination_effect":False})
    report={"schema":"befunge-stage1-four-cell-first-literal-intervention-49-v1",
       "status":"FINITE_NATIVE_ACTUAL_INSTRUCTION_INTERVENTION_STAGE1_OPEN",
       "base_git_blob":BASE,"candidate_git_blob":CAND,
       "literal_coordinate":[951,1337],"baseline_opcode":49,
       "temporary_opcode":48,
       "restoration_check":"immediately_after_edited_native_step",
       "final_source_byte_is_ordinary_mutable_funge_space":True,
       "instruction_restored_after_native_step":True,
       "grid_domain":list(DOM),"input_cases":49,
       "native_candidate_control_programs":49,"native_candidate_intervention_programs":49,
       "independent_befunge_reference_programs":147,
       "actual_literal_reached_input_cases":0,
       "literal_not_reached_input_cases":49,"causal_effect_input_cases":0,
       "test_only":True,"stage1_complete":False,"stage2_started":False,
       "records":rows}
    need(verify(report,require_effect=False),"clean synthetic report rejected")
    edits=(
      ("missing_row",lambda d:d["records"].pop()),
      ("wrong_signed_day",lambda d:d["records"][0]["signed_days"].__setitem__(0,3)),
      ("wrong_input_hash",lambda d:d["records"][0].__setitem__("input_sha256","0"*64)),
      ("not_seven_fields",lambda d:d["records"][2]["native_befunge_reference_output"].pop()),
      ("candidate_output_forged",lambda d:d["records"][2]["control"]["output"].__setitem__(0,"1")),
      ("mutation_without_literal",lambda d:d["records"][2]["intervention"].__setitem__("native_live_literal_edits",1)),
      ("fake_reach",lambda d:d.__setitem__("actual_literal_reached_input_cases",1)),
      ("fake_causal",lambda d:d["records"][3].__setitem__("causal_output_or_termination_effect",True)),
      ("fake_immediate_restore",lambda d:d["records"][5]["intervention"].__setitem__("restored_source_byte",48)),
      ("fake_process_count",lambda d:d.__setitem__("independent_befunge_reference_programs",146)),
      ("source_drift",lambda d:d.__setitem__("candidate_git_blob","0"*40)),
      ("stage_closure",lambda d:d.__setitem__("stage1_complete",True)),
    )
    for label,mutate in edits:
        bad=copy.deepcopy(report)
        mutate(bad)
        try:verify(bad,require_effect=False)
        except AssertionError:continue
        raise AssertionError("forged literal intervention report accepted: "+label)
    print("NATIVE_FIRST_LITERAL_INTERVENTION_12_SYNTHETIC_FALSIFICATIONS_REJECT_PASS")
def main(folder):
    synthetic()
    path=Path(folder)/"native_first_literal_intervention_49.json"
    need(path.is_file(),"missing Native first-literal real report")
    report=json.loads(path.read_text("utf8"))
    need(verify(report),"Native actual first-literal causal report invalid")
    print("NATIVE_FIRST_LITERAL_INTERVENTION_49_CASES_INDEPENDENT_AUDIT_PASS")
    print("STAGE1_OPEN; QA_ONLY_NOT_PRODUCTION")

if __name__=="__main__":
    if len(sys.argv)==1 or (len(sys.argv)==2 and sys.argv[1]=="--selftest"):
        synthetic()
    else:
        need(len(sys.argv)==2,"usage: audit --selftest | EVIDENCE_DIRECTORY")
        main(sys.argv[1])
