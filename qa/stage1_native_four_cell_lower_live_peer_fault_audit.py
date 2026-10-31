#!/usr/bin/env python3
"""Independent finite Native four-cell lower fault/live peer report audit."""
import copy,hashlib,json,re,sys
from pathlib import Path
BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
CASES=(("v1","v2","AB"),("v3","v2","BA"))
SHA=re.compile(r"[0-9a-f]{64}\Z")
def need(x,why):
    if not x:raise AssertionError(why)
def verify(r):
    need(type(r) is dict and r.get("schema")=="befunge-stage1-four-cell-live-lower-fault-v1" and
         r.get("status")=="TEST_ONLY_LIVE_PEER_FAULT_ISOLATION_STAGE1_OPEN" and
         r.get("base_git_blob")==BASE and r.get("candidate_git_blob")==CAND and
         r.get("trials")==2 and r.get("live_native_programs")==6 and
         r.get("native_reference_programs")==9 and r.get("faulted_lower_literals")==2 and
         r.get("native_clean_peer_completions")==2 and r.get("native_same_object_resets")==2 and
         r.get("candidate_promoted") is False and r.get("stage1_completed") is False,
         "Native four-cell live fault report identity/coverage/status invalid")
    rows=r.get("records")
    need(type(rows) is list and len(rows)==2,
         "two actual live lower Native fault scenarios missing")
    for row,(f,p,s) in zip(rows,CASES):
        need(type(row) is dict and row.get("failed_label")==f and
             row.get("peer_label")==p and row.get("schedule")==s and
             row.get("fault_opcode_coordinate")==[951,1337] and
             row.get("fault_opcode")==ord("1") and
             all(type(row.get(field)) is int and row[field]>0 for field in
                 ("fault_step","peer_step_at_fault","surviving_peer_steps",
                  "overlap_rounds","unique_failed_p_targets",
                  "unique_peer_p_targets","faulted_memory_cells")) and
             row["surviving_peer_steps"]>row["peer_step_at_fault"] and
             row["faulted_memory_cells"]>=row["unique_failed_p_targets"] and
             type(row.get("faulted_memory_sha256")) is str and
             SHA.fullmatch(row["faulted_memory_sha256"]) and
             type(row.get("faulted_memory_snapshot")) is list and
             len(row["faulted_memory_snapshot"])==row["faulted_memory_cells"] and
             all(type(cell) is list and len(cell)==3 and
                 all(type(v) is int for v in cell)
                 for cell in row["faulted_memory_snapshot"]) and
             [tuple(cell[:2]) for cell in row["faulted_memory_snapshot"]]==
                 sorted(set(tuple(cell[:2]) for cell in
                            row["faulted_memory_snapshot"])) and
             (951,1337) in [tuple(cell[:2]) for cell in
                             row["faulted_memory_snapshot"]] and
             row["faulted_memory_sha256"]==hashlib.sha256(
                 json.dumps(row["faulted_memory_snapshot"],
                            sort_keys=True,
                            separators=(",",":")).encode("ascii")).hexdigest() and
             all(row.get(key) is True for key in
                 ("survived_peer_without_space_mutation",
                  "actual_native_execute_step_exception_caught",
                  "no_peer_change_at_injected_step",
                  "recovered_same_program_object","old_io_unchanged")) and
             row.get("stage1_complete") is False,
             "Native live fault, peer survival, state-isolation claim inconsistent")
        for output,oracle in (
            ("surviving_peer_output","reference_peer"),
            ("reset_program_output","reference_failed")):
            val=row.get(oracle)
            need(type(val) is list and len(val)==7 and
                 all(type(v) is str and v.lstrip("-").isdigit() for v in val) and
                 row.get(output)==val,
                 "surviving/restarted Native Befunge output incorrect")
    return True
def main(folder):
    path=Path(folder)/"native_four_cell_lower_live_peer_fault.json"
    report=json.loads(path.read_text(encoding="utf8"))
    need(verify(report),"Native live peer report invalid")
    attacks=[
     ("false_peer_survival",lambda x:x["records"][0].__setitem__(
         "survived_peer_without_space_mutation",False)),
     ("false_runtime_effect",lambda x:x["records"][1].__setitem__(
         "fault_opcode_coordinate",[0,0])),
     ("fake_exception",lambda x:x["records"][0].__setitem__(
         "actual_native_execute_step_exception_caught",False)),
     ("false_reference",lambda x:x["records"][0]["reference_peer"].pop()),
     ("forged_cell_content",lambda x:x["records"][0]
      ["faulted_memory_snapshot"][0].__setitem__(2,123456)),
     ("zero_real_overlap",lambda x:x["records"][0].__setitem__("overlap_rounds",0)),
     ("lost_fault_writes",lambda x:x["records"][1].__setitem__(
         "unique_failed_p_targets",0)),
     ("spurious_reset",lambda x:x["records"][0].__setitem__(
         "recovered_same_program_object",False)),
     ("promoted_without_proof",lambda x:x.__setitem__("candidate_promoted",True)),
     ("premature_completion",lambda x:x.__setitem__("stage1_completed",True)),
    ]
    for name,corrupt in attacks:
        bad=copy.deepcopy(report)
        corrupt(bad)
        try:verify(bad)
        except AssertionError:pass
        else:raise AssertionError("forged lower live fault evidence accepted: "+name)
    print("NATIVE_FOUR_CELL_LOWER_LIVE_PEER_FAULT_AUDIT_10_FALSIFICATIONS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: Native 4-cell live lower fault evidence directory")
    main(sys.argv[1])
