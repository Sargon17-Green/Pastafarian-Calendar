#!/usr/bin/env python3
"""Independent audit of QA-only four-cell Native lower arithmetic candidate.

The test source and candidate are actual 2D Funge bytes. This auditor checks
byte-for-byte four-cell changes, known 39-case independent Native differential
evidence, exact causal-trial structure, rejected/eligible decision logic, and
14 forged report negative controls. It NEVER computes numeric calendar values
or permits promotion as a side effect.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
PATCHES=[[948,1331,"6","7"],[951,1337,"^","1"],
         [951,1338," ","^"],[952,1336,"1"," "]]
LOWER=("foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse")

def need(x,msg):
    if not x:raise AssertionError(msg)
def blob(s):
    return hashlib.sha1(b"blob "+str(len(s)).encode("ascii")+b"\0"+s).hexdigest()

def validate(d):
    need(d.get("schema")=="befunge-stage1-native-qa-lower-feedback-four-cell-candidate-v1"
         and d.get("status")=="EXPLORATORY_QA_CANDIDATE_NOT_PROMOTED"
         and d.get("production_git_blob")==PIN
         and d.get("exact_source_cell_changes")==PATCHES
         and d.get("native_oracle_case_count")==39
         and d.get("stage1_functional_acceptance") is False
         and d.get("stage1_geometric_acceptance") is False
         and d.get("qa_production_modified") is False
         and d.get("canonical_branch_modified") is False,
         "test-only QA candidate source/acceptance flags forged")
    rows=d.get("oracle_rows")
    need(isinstance(rows,list) and len(rows)==39
         and len(set(x["case"] for x in rows))==39,
         "thirty-nine exact Native test-case rows missing")
    pass_count=0
    for x in rows:
        want=x.get("reference_output")
        need(isinstance(x.get("case"),str)
             and isinstance(x.get("input_fields"),list)
             and len(x["input_fields"])==4
             and all(type(v) is int for v in x["input_fields"])
             and type(x.get("valid")) is bool
             and isinstance(want,list) and len(want)==7
             and all(isinstance(v,str) for v in want)
             and (x["valid"] or want==["-1"]*7)
             and type(x.get("native_cli_complete")) is bool
             and type(x.get("seven_field_parity")) is bool,
             "Befunge oracle candidate report incomplete")
        measured=(x.get("native_cli_complete") is True
                  and x.get("candidate_output")==want)
        need(x["seven_field_parity"] is measured,
             "real Native candidate parity not evidenced by actual vectors")
        pass_count+=measured
    need(d.get("native_oracle_parity_cases")==pass_count
         and d.get("independent_befunge_reference_parity_full") is (pass_count==39),
         "candidate reported false Native 39-case oracle status")
    trial=d.get("counterfactuals")
    need(isinstance(trial,list)
         and len(trial)==(6 if pass_count==39 else 0)
         and d.get("native_lower_causal_trial_pairs")==len(trial),
         "QA candidate first Native numeric gate not enforced")
    effects=0
    for z,label in zip(trial,LOWER):
        need(z.get("case")==label and type(z.get("valid")) is bool,
             "Native feedback trial input class changed")
        c=z.get("original")
        m=z.get("inverted_turn")
        need(isinstance(c,dict) and isinstance(m,dict)
             and c.get("status")=="normal" and c.get("remaining_ips")==0
             and c.get("gate",{}).get("executed_opcode")=="]"
             and m.get("gate",{}).get("executed_opcode")=="["
             and c.get("gate",{}).get("restored") is True
             and m.get("gate",{}).get("restored") is True
             and c["gate"]["tick"]==m["gate"]["tick"]
             and c["gate"]["direction_after"]!=m["gate"]["direction_after"]
             and c["output"]==next(item["reference_output"]
                                  for item in rows if item["case"]==label),
             "real Native one-instruction turn intervention not executed")
        changed=(m["status"]!="normal" or m["remaining_ips"]!=0
                 or c["output"]!=m["output"])
        need(z.get("native_full_result_or_termination_effect") is changed,
             "Native lower-route causal output/termination effect misreported")
        effects+=changed
    need(d.get("native_lower_causal_effect_cases")==effects
         and d.get("candidate_ready_for_promotion") is
             (pass_count==39 and len(trial)==6 and effects==6),
         "candidate eligibility statement unsupported by finite Native evidence")
    return {"native_differential_cases":39,"oracle_parity":pass_count,
            "causal_pairs":len(trial),"observed_effect_pairs":effects,
            "promotion_automatically_performed":False,
            "stage1_acceptance":"OPEN"}

def main(folder):
    base=Path("src/interleaved_work_counts.b98").read_bytes()
    need(blob(base)==PIN,"QA production source Git bytes moved")
    folder=Path(folder)
    cand=(folder/"lower_feedback_semantic_candidate.b98").read_bytes()
    need(len(cand)==len(base),"candidate source grid size changed")
    original=base.split(b"\n")
    newer=cand.split(b"\n")
    differences=[]
    for y,(r1,r2) in enumerate(zip(original,newer)):
        need(len(r1)==len(r2),"source-map row width changed")
        for x,(old,new) in enumerate(zip(r1,r2)):
            if old!=new: differences.append([x,y,chr(old),chr(new)])
    need(differences==sorted(PATCHES,key=lambda x:(x[1],x[0])),
         "candidate source bytes differ beyond four intended Funge cells")
    d=json.loads((folder/"lower_feedback_candidate_experiment.json").read_text("utf-8"))
    need(d.get("candidate_git_blob")==blob(cand),
         "recorded native candidate Git blob does not match actual artifact")
    summary=validate(d)
    print("NATIVE_QA_CANDIDATE_INDEPENDENT_FOUR_CELL_BYTES_AUDITED_PASS",
          json.dumps(summary,sort_keys=True))
    attacks=[]
    def reject(name,fn):
        mutated=copy.deepcopy(d)
        fn(mutated)
        try:validate(mutated)
        except AssertionError:
            attacks.append(name)
            return
        raise AssertionError("forged Native candidate report accepted "+name)
    reject("source",lambda x:x.__setitem__("production_git_blob","0"*40))
    reject("patches",lambda x:x.__setitem__("exact_source_cell_changes",[]))
    reject("missing_case",lambda x:x["oracle_rows"].pop())
    reject("duplicate_case",lambda x:x["oracle_rows"][0].__setitem__(
        "case",x["oracle_rows"][1]["case"]))
    reject("fake_oracle",lambda x:x["oracle_rows"][0]["reference_output"].pop())
    reject("false_parity",lambda x:x["oracle_rows"][0].__setitem__(
        "seven_field_parity",not x["oracle_rows"][0]["seven_field_parity"]))
    reject("false_total",lambda x:x.__setitem__("native_oracle_parity_cases",-1))
    reject("missing_native_report",lambda x:x["oracle_rows"][0].__setitem__(
        "native_cli_complete",None))
    reject("missing_references",lambda x:x.__setitem__("independent_befunge_reference_parity_full",None))
    reject("fake_ready",lambda x:x.__setitem__("candidate_ready_for_promotion",
        not x["candidate_ready_for_promotion"]))
    reject("invalid_case",lambda x:x["oracle_rows"][0].__setitem__("valid",None))
    reject("changed_production",lambda x:x.__setitem__("qa_production_modified",True))
    reject("changed_canonical",lambda x:x.__setitem__("canonical_branch_modified",True))
    reject("false_completion",lambda x:x.__setitem__("stage1_geometric_acceptance",True))
    need(len(attacks)==14,"candidate anti-forgery suite not complete")
    (folder/"lower_feedback_candidate_audit.json").write_text(
      json.dumps({"schema":"befunge-stage1-native-four-cell-candidate-audit-v1",
                  "observed":summary,"forged_reports_rejected":attacks,
                  "stage1_complete":False},sort_keys=True,indent=2)+"\n",
      encoding="utf-8")
    print("NATIVE_LOWER_CANDIDATE_FOURTEEN_HOSTILE_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: candidate Native evidence directory")
    main(sys.argv[1])
