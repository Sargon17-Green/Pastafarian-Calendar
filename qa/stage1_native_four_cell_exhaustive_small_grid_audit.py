#!/usr/bin/env python3
"""Independent QA audit of 57 real BF98 production/candidate/reference runs.

Validates an exhaustive finite 7x7 signed square, not universal Stage 1 proof.
The native producer is a separate PyFunge-98 process and is not imported.
"""
import copy
import hashlib
import json
import re
import sys
from pathlib import Path

SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE = "d965ce4bdfa282f2d3b82690808def5a2dde10a8"
DOMAIN = tuple(range(-3,4))
INVALID = (
    (1,0,0,0), (0,0,1,0),
    (2,1,0,1), (0,1,2,1),
    (0,-1,0,1), (0,1,0,-1),
    (-1,1,0,1), (0,1,-1,1),
)
DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z",re.ASCII)
HEX = re.compile(r"[a-f0-9]{64}\Z",re.ASCII)

def need(ok,message):
    if not ok:raise AssertionError(message)

def signed(v):
    return (int(v<0),abs(v))

def expected_roster():
    cases=[]
    for a in DOMAIN:
        for b in DOMAIN:
            sa,ma=signed(a)
            sb,mb=signed(b)
            cases.append(("grid_%+d_%+d"%(a,b),(sa,ma,sb,mb),True))
    for i,values in enumerate(INVALID):
        cases.append(("invalid_%02d"%i,values,False))
    return cases

def verify(report):
    need(type(report) is dict and
         report.get("schema")=="befunge-stage1-four-cell-native-exhaustive-small-grid-v1" and
         report.get("status")=="FINITE_QA_ONLY_NOT_STAGE1_ACCEPTANCE" and
         report.get("production_blob")==SOURCE and
         report.get("candidate_blob")==CANDIDATE and
         report.get("signed_day_domain")==list(DOMAIN) and
         report.get("valid_pairs")==49 and
         report.get("invalid_lexical_domain_cases")==8 and
         report.get("native_production_processes")==57 and
         report.get("native_candidate_processes")==57 and
         report.get("independent_native_reference_processes")==147 and
         report.get("total_fresh_native_processes")==261 and
         report.get("all_seven_field_results_agree") is True and
         report.get("test_only_variant") is True and
         report.get("production_source_modified") is False and
         report.get("stage1_complete") is False and
         report.get("stage2_started") is False,
         "small-grid source/process-count/scope metadata was forged")
    rows=report.get("cases")
    roster=expected_roster()
    need(type(rows) is list and len(rows)==len(roster)==57,
         "57-case exhaustive finite roster missing")
    seen=set()
    for i,(row,(label,fields,valid)) in enumerate(zip(rows,roster)):
        need(type(row) is dict and row.get("index")==i and
             row.get("case")==label and label not in seen and
             type(row.get("fields")) is list and
             all(type(z) is int for z in row["fields"]) and
             tuple(row["fields"])==fields and
             row.get("valid") is valid and
             row.get("reference_native_processes")== (3 if valid else 0) and
             row.get("both_native_programs_completed") is True,
             "Native signed-day pair/validity/coverage drifted: "+label)
        seen.add(label)
        raw=" ".join(map(str,fields))+"\n"
        need(type(row.get("raw_input_sha256")) is str and
             HEX.fullmatch(row["raw_input_sha256"]) and
             row["raw_input_sha256"]==hashlib.sha256(raw.encode("ascii")).hexdigest(),
             "independent Native raw input receipt drifted: "+label)
        a=row.get("production_native_output")
        b=row.get("candidate_native_output")
        c=row.get("independent_befunge_reference_output")
        need(type(a) is list and type(b) is list and type(c) is list and
             len(a)==len(b)==len(c)==7 and a==b==c and
             all(type(z) is str and DECIMAL.fullmatch(z) for z in a),
             "native production/candidate/seven-field reference drifted: "+label)
        if not valid:
            need(a==["-1"]*7,"invalid native field did not preserve seven sentinels")
    return True

def selftest():
    rows=[]
    for i,(label,fields,valid) in enumerate(expected_roster()):
        raw=" ".join(map(str,fields))+"\n"
        vec=["0"]*7 if valid else ["-1"]*7
        rows.append({"index":i,"case":label,"fields":list(fields),"valid":valid,
           "raw_input_sha256":hashlib.sha256(raw.encode("ascii")).hexdigest(),
           "production_native_output":list(vec),"candidate_native_output":list(vec),
           "independent_befunge_reference_output":list(vec),
           "reference_native_processes":3 if valid else 0,
           "both_native_programs_completed":True})
    doc={"schema":"befunge-stage1-four-cell-native-exhaustive-small-grid-v1",
        "status":"FINITE_QA_ONLY_NOT_STAGE1_ACCEPTANCE",
        "production_blob":SOURCE,"candidate_blob":CANDIDATE,
        "signed_day_domain":list(DOMAIN),"valid_pairs":49,
        "invalid_lexical_domain_cases":8,"native_production_processes":57,
        "native_candidate_processes":57,
        "independent_native_reference_processes":147,
        "total_fresh_native_processes":261,
        "all_seven_field_results_agree":True,
        "test_only_variant":True,"production_source_modified":False,
        "stage1_complete":False,"stage2_started":False,"cases":rows}
    need(verify(doc),"clean synthetic small-grid document rejected")
    mutations=(
      ("missing_pair",lambda x:x["cases"].pop()),
      ("duplicated_pair",lambda x:x["cases"][5].__setitem__("case","grid_-3_-3")),
      ("modified_input",lambda x:x["cases"][2]["fields"].__setitem__(3,2)),
      ("signed_zero_alias",lambda x:x["cases"][21]["fields"].__setitem__(0,1)),
      ("wrong_raw_hash",lambda x:x["cases"][3].__setitem__("raw_input_sha256","0"*64)),
      ("coordinated_native_outputs",lambda x:[x["cases"][1][k].__setitem__(0,"999") for k in
          ("production_native_output","candidate_native_output")]),
      ("oracle_not_equal",lambda x:x["cases"][6]["independent_befunge_reference_output"].__setitem__(0,"3")),
      ("invalid_sentinel_loss",lambda x:[x["cases"][49][k].__setitem__(0,"0") for k in
          ("production_native_output","candidate_native_output","independent_befunge_reference_output")]),
      ("missing_reference_process",lambda x:x["cases"][0].__setitem__("reference_native_processes",2)),
      ("partial_domain",lambda x:x.__setitem__("valid_pairs",48)),
      ("wrong_candidate_blob",lambda x:x.__setitem__("candidate_blob","0"*40)),
      ("premature_stage_close",lambda x:x.__setitem__("stage1_complete",True)),
    )
    for name,change in mutations:
        forged=copy.deepcopy(doc)
        change(forged)
        try:verify(forged)
        except AssertionError:pass
        else:raise AssertionError("forged small-grid report accepted: "+name)
    print("NATIVE_FOUR_CELL_SMALL_GRID_12_ADVERSARIAL_DOCUMENTS_REJECTED_PASS")
    return True

def main(folder):
    selftest()
    root=Path(folder)
    file=root/"small_grid_native_parity.json"
    need(file.is_file(),"small-grid Native BF98 evidence missing")
    data=json.loads(file.read_text(encoding="utf8"))
    need(verify(data),"real native source/candidate/reference parity rejected")
    candidate_file=root/"small_grid_candidate.b98"
    need(candidate_file.is_file(),"four-cell Native candidate binary missing")
    raw=candidate_file.read_bytes()
    digest=hashlib.sha1(b"blob "+str(len(raw)).encode("ascii")+b"\0"+raw).hexdigest()
    need(digest==CANDIDATE,"Native candidate 2D source payload drifted")
    print("NATIVE_FOUR_CELL_57_CASES_261_PROCESSES_INDEPENDENT_REPORT_AUDIT_PASS")
    print("LAST_COMPLETED_STAGE=0; GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    need(len(sys.argv)==2 or (len(sys.argv)==1),"usage: audit DIRECTORY or --selftest")
    if len(sys.argv)==1 or sys.argv[1]=="--selftest":selftest()
    else:main(sys.argv[1])
