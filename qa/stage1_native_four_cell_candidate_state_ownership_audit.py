#!/usr/bin/env python3
"""Independent finite ownership audit for exact four-cell Native candidate.

Verifies source identity, 12 concurrent program pair runs in both orders,
12 explicit same-Program invalid/valid resets, private Funge-space and
p-write API custody, and 16 negative forged reports. Stage1 stays OPEN.
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
PAIRS=(("v0","v1"),("v2","v3"),("v4","i4"),
       ("i1","v1"),("i0","i3"),("i2","i5"))
RESET=(("i0","v0"),("i3","v2"),("i4","v4"),
       ("i1","v1"),("i2","v3"),("i5","v5"))
LABELS=tuple("v%d"%i for i in range(6))+tuple("i%d"%i for i in range(6))

def need(ok,reason):
    if not ok:raise AssertionError(reason)
def gitblob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()

def audit(doc):
    need(doc.get("schema")=="befunge-stage1-four-cell-candidate-native-ownership-v1"
         and doc.get("status")=="FINITE_NATIVE_QA_OWNERSHIP_STAGE1_OPEN"
         and doc.get("production_git_blob")==PIN
         and doc.get("candidate_git_blob")==CANDIDATE
         and doc.get("four_physical_source_changes")==PATCHES
         and doc.get("native_independent_reference_calls")==18
         and doc.get("native_live_pair_cases")==12
         and doc.get("native_live_program_executions")==24
         and doc.get("native_same_object_explicit_reset_runs")==12
         and doc.get("native_invalid_reset_runs")==6
         and doc.get("native_valid_recovery_runs")==6
         and doc.get("both_pair_schedules")==["AB","BA"]
         and doc.get("stage1_complete") is False
         and doc.get("production_edited") is False
         and doc.get("canonical_branch_edited") is False,
         "candidate Native source identity/coverage/Stage1 status changed")
    expected=doc.get("expected_by_label")
    need(isinstance(expected,dict) and set(expected)==set(LABELS),
         "12 candidate Native input labels missing")
    for label in LABELS:
        value=expected[label]
        need(isinstance(value,list) and len(value)==7
             and all(isinstance(v,str) and v.lstrip("-").isdigit() for v in value)
             and (value==["-1"]*7 if label[0]=="i" else value!=["-1"]*7),
             "Native independent Befunge oracle vector invalid")
    pairs=doc.get("pairs")
    need(isinstance(pairs,list) and len(pairs)==12,"12 Native pair records incomplete")
    once={}
    for record,(sched,(left,right)) in zip(pairs,
            ((schedule,p) for schedule in ("AB","BA") for p in PAIRS)):
        need(record.get("schedule")==sched
             and record.get("left")==left and record.get("right")==right
             and record.get("left_output")==expected[left]
             and record.get("right_output")==expected[right]
             and record.get("terminated") is True
             and all(record.get(key) is True for key in (
                 "private_programs","private_spaces","private_semantics",
                 "private_io","cross_program_state_unchanged",
                 "every_api_read_write_owned_by_active_program")),
             "native two-live-Program reference or state ownership invalid")
        need(type(record.get("overlap_rounds")) is int
             and record["overlap_rounds"]>0
             and type(record.get("cross_program_checks")) is int
             and record["cross_program_checks"]>=16,
             "Native peer did not overlap or was not checked")
        for label,side in ((left,"left"),(right,"right")):
            ticks=record.get(side+"_steps")
            gets=record.get(side+"_memory_gets")
            puts=record.get(side+"_memory_puts")
            direct=record.get(side+"_direct_p_steps")
            putspace=record.get(side+"_runtime_putspace")
            need(all(type(v) is int and v>0 for v in (ticks,gets,puts,direct))
                 and puts==direct and putspace==0,
                 "Native Funge-space p/get/put API evidence invalid")
            stats=(ticks,gets,puts)
            if label in once:
                need(stats==once[label],
                     "candidate steps/get/put vary across peer or order")
            else:once[label]=stats
    need(set(once)==set(LABELS),"12 live candidate input classes incomplete")
    rows=doc.get("resets")
    need(isinstance(rows,list) and len(rows)==12,
         "12 exact-object invalid-valid resets incomplete")
    identity=doc.get("native_program_reused_identity")
    need(type(identity) is int and identity>0,
         "Native reused Program identity invalid")
    for i,row in enumerate(rows):
        label=RESET[i//2][i%2]
        need(row.get("ordinal")==i and row.get("batch")==i//2
             and row.get("label")==label
             and row.get("native_output")==expected[label]
             and row.get("expected_output")==expected[label]
             and row.get("program_identity")==identity
             and row.get("fresh_semantics") is True
             and row.get("fresh_space") is True
             and row.get("fresh_io") is True
             and row.get("previous_memory_preserved") is True
             and row.get("terminated") is True
             and row.get("source_four_cells")==
                 [[x,y,ord(new)] for x,y,old,new in PATCHES],
             "same Native Program reset, four candidate cells or output forged")
        need(type(row.get("p_write_target_count")) is int
             and row["p_write_target_count"]>0
             and type(row.get("snapshot_cell_count")) is int
             and row["snapshot_cell_count"]>=row["p_write_target_count"],
             "native actual p destinations not protected")
        for key in ("previous_snapshot_checked_before",
                    "previous_snapshot_checked_after"):
            value=row.get(key)
            need(type(value) is int
                 and (value==0 if i==0 else value>=17),
                 "prior completed Funge-space unchecked during reset")
    return {"native_pair_runs":12,"native_live_programs":24,
            "same_object_resets":12,"stage1_ownership_gate":"OPEN"}

def main(folder):
    root=Path(folder)
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(gitblob(source)==PIN,"original Native production source drifted")
    rows=source.split(b"\n")
    amended=[bytearray(row) for row in rows]
    for x,y,old,new in PATCHES:
        need(amended[y][x]==ord(old),"physical Native candidate preimage changed")
        amended[y][x]=ord(new)
    candidate=b"\n".join(bytes(row) for row in amended)
    need(gitblob(candidate)==CANDIDATE,
         "physical candidate does not match exact four Native source cells")
    report=json.loads((root/"native_four_cell_candidate_ownership.json")
                      .read_text(encoding="utf-8"))
    result=audit(report)
    print("NATIVE_FOUR_CELL_CANDIDATE_PRIVATE_SPACE_RESET_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    attacks=[]
    def reject(name,fn):
        corrupt=copy.deepcopy(report)
        fn(corrupt)
        try:audit(corrupt)
        except AssertionError:
            attacks.append(name)
            print("NATIVE_FOUR_CELL_OWNERSHIP_FALSIFICATION_REJECT_PASS",name)
            return
        raise AssertionError("Native candidate state forgery accepted: "+name)
    reject("source",lambda z:z.__setitem__("candidate_git_blob","0"*40))
    reject("missing_pair",lambda z:z["pairs"].pop())
    reject("wrong_order",lambda z:z["pairs"][0].__setitem__("schedule","BA"))
    reject("wrong_oracle",lambda z:z["pairs"][0]["left_output"].__setitem__(0,"WRONG"))
    reject("cross_space",lambda z:z["pairs"][0].__setitem__("every_api_read_write_owned_by_active_program",False))
    reject("no_overlap",lambda z:z["pairs"][0].__setitem__("overlap_rounds",0))
    reject("write_missing",lambda z:z["pairs"][0].__setitem__("left_memory_puts",0))
    reject("peer_mutation",lambda z:z["pairs"][0].__setitem__("cross_program_state_unchanged",False))
    reject("order_sensitive",lambda z:z["pairs"][6].__setitem__("left_steps",z["pairs"][6]["left_steps"]+1))
    reject("missing_reset",lambda z:z["resets"].pop())
    reject("new_identity",lambda z:z["resets"][1].__setitem__("program_identity",-1))
    reject("stale_space",lambda z:z["resets"][1].__setitem__("fresh_space",False))
    reject("source_cell",lambda z:z["resets"][0]["source_four_cells"][0].__setitem__(2,32))
    reject("missing_put",lambda z:z["resets"][0].__setitem__("p_write_target_count",0))
    reject("old_memory",lambda z:z["resets"][1].__setitem__("previous_memory_preserved",False))
    reject("premature_stage",lambda z:z.__setitem__("stage1_complete",True))
    need(len(attacks)==16,"Native ownership adversarial coverage incomplete")
    (root/"native_four_cell_candidate_ownership_audit.json").write_text(
      json.dumps({"schema":"befunge-stage1-four-cell-candidate-state-audit-v1",
                  "verified":result,"forgeries_rejected":attacks,
                  "stage1_accepted":False},sort_keys=True,indent=2)+"\n",
      encoding="utf-8")
    print("NATIVE_FOUR_CELL_CANDIDATE_SIXTEEN_OWNERSHIP_TAMPERS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: Native candidate ownership artifact folder")
    main(sys.argv[1])
