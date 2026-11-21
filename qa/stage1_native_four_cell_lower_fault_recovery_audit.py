#!/usr/bin/env python3
"""Independent QA-only audit of real Native lower-literal fault/recovery.

Checks all captured physical p-written cells and prior Program space lifetime.
This remains finite Native evidence; Stage-1 functional/geometry gates OPEN.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
PATCHES=[[948,1331,"6","7"],[951,1337,"^","1"],
         [951,1338," ","^"],[952,1336,"1"," "]]
ROWS=(
    ("fault_lower_foundation","foundation_cross",True),
    ("recover_lower_mixed","mixed_small",False),
    ("fault_lower_negative","negative_positive",True),
    ("recover_upper_zero","zero_equal",False),
    ("fault_lower_neighbor","foundation_neighbor_forward",True),
    ("recover_lower_reverse","foundation_neighbor_reverse",False),
    ("recover_invalid","invalid_zero_sign",False),
)

def need(v,reason):
    if not v:raise AssertionError(reason)

def versioned_digest(entries):
    return hashlib.sha256(json.dumps(entries,separators=(",",":"),
                                  sort_keys=True).encode("ascii")).hexdigest()

def verify(data):
    need(type(data) is dict and
         data.get("schema")=="befunge-stage1-four-cell-native-lower-fault-recovery-v1" and
         data.get("status")=="TEST_ONLY_CANDIDATE_FAULT_RECOVERY_NOT_STAGE1_ACCEPTANCE" and
         data.get("base_git_blob")==BASE and
         data.get("candidate_git_blob")==CANDIDATE and
         data.get("changed_cells")==PATCHES and
         data.get("native_same_program_invocations")==7 and
         data.get("real_native_post_literal_faults")==3 and
         data.get("native_successful_recoveries")==4 and
         data.get("independent_befunge_reference_program_runs")==18 and
         data.get("source_edited") is False and
         data.get("canonical_edited") is False and
         data.get("stage1_completed") is False and
         type(data.get("program_identity")) is int and
         data["program_identity"]>0,
         "candidate real Native fault report source/status/schema forged")
    runs=data.get("records")
    need(type(runs) is list and len(runs)==7,
         "seven actual Native candidate invocations missing")
    identity=data["program_identity"]
    for i,(row,(name,label,fault)) in enumerate(zip(runs,ROWS)):
        need(type(row) is dict and row.get("index")==i and
             row.get("name")==name and row.get("label")==label and
             row.get("fault_expected") is fault and
             row.get("fault_observed") is fault and
             row.get("valid") is (label!="invalid_zero_sign") and
             row.get("program_identity")==identity and
             all(row.get(field) is True for field in
                 ("fresh_space","fresh_semantics","fresh_io")) and
             row.get("source_cells")==
                [[x,y,ord(new)] for x,y,old,new in PATCHES],
             "Native exact Program identity/clean-source/fault schedule forged")
        ref=row.get("expected_native_reference_output")
        out=row.get("actual_native_output")
        need(type(ref) is list and len(ref)==7 and
             all(type(x) is str and x.lstrip("-").isdigit() for x in ref) and
             type(out) is list and
             (out==ref if not fault else row.get("normal_termination") is False) and
             (row.get("normal_termination") is False if fault else
              row.get("normal_termination") is True),
             "native reference/output/termination evidence contradicted")
        need(type(row.get("lower_literal_executions")) is int and
             (row["lower_literal_executions"]==0 if label=="zero_equal" else
              row["lower_literal_executions"]==1 if fault else
              row["lower_literal_executions"]>=1 if label!="invalid_zero_sign"
              else row["lower_literal_executions"]>=0),
             "new lower-loop semantic literal was not executed as expected")
        cells=row.get("owned_cell_values")
        count=row.get("owned_cell_count")
        put_count=row.get("native_p_write_targets")
        need(type(cells) is list and
             type(count) is int and count==len(cells) and count>=10 and
             type(put_count) is int and put_count>0 and put_count<=count and
             type(row.get("later_checks")) is int and
             row["later_checks"]==6-i and
             row.get("owned_cells_digest")==versioned_digest(cells),
             "actual owned Native p-target footprint/digest/legacy checks forged")
        keys=[]
        values={}
        for item in cells:
            need(type(item) is list and len(item)==3 and
                 all(type(x) is int for x in item),
                 "Native Funge-space owned cell witness malformed")
            xy=tuple(item[:2])
            need(xy not in values,"Native writable cell witness duplicated")
            keys.append(xy)
            values[xy]=item[2]
        need(keys==sorted(keys),
             "Funge-space native coordinate snapshot not canonical")
        for x,y,old,new in PATCHES:
            need((x,y) in values,
                 "missing tested modified source cell from Native owned state")
    return {"native_faults":3,"post_fault_clean_recoveries":4,
            "same_program_invocations":7,"stage1_acceptance":"OPEN"}

def main(path):
    report=json.loads((Path(path)/"native_four_cell_lower_fault_recovery.json")
                      .read_text(encoding="utf-8"))
    result=verify(report)
    print("NATIVE_FOUR_CELL_LOWER_FAULT_RECOVERY_INDEPENDENT_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    attacks=(
      ("wrong_program_identity",lambda d:d["records"][2].__setitem__("program_identity",0)),
      ("wrong_fault_schedule",lambda d:d["records"][0].__setitem__("fault_observed",False)),
      ("fabricated_recovery",lambda d:d["records"][1].__setitem__("normal_termination",False)),
      ("bad_reference",lambda d:d["records"][1]["expected_native_reference_output"].pop()),
      ("foreign_space",lambda d:d["records"][3].__setitem__("fresh_space",False)),
      ("missing_owned_cell",lambda d:d["records"][0]["owned_cell_values"].pop()),
      ("missing_retained_old_check",lambda d:d["records"][0].__setitem__("later_checks",0)),
      ("fake_literal",lambda d:d["records"][1].__setitem__("lower_literal_executions",0)),
      ("candidate_changed",lambda d:d.__setitem__("candidate_git_blob","0"*40)),
      ("pretend_stage_complete",lambda d:d.__setitem__("stage1_completed",True)),
    )
    for name,change in attacks:
        forged=copy.deepcopy(report)
        change(forged)
        try:verify(forged)
        except AssertionError:pass
        else:raise AssertionError("adversarial Native candidate report accepted "+name)
    print("NATIVE_FOUR_CELL_LOWER_FAULT_RECOVERY_TEN_FALSIFICATIONS_REJECT_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: native lower candidate fault audit ARTIFACT_DIR")
    main(sys.argv[1])
