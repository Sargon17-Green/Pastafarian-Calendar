#!/usr/bin/env python3
"""Independent review of 42 Native same-Program invalid-to-valid resets.

Verifies immutable source SHA, exact ordered invalid corpus, alternating
native reference anchors, same Program identity, prior-space snapshot
accounting and eight forged report rejections. Real Native PyFunge is the
only executor; this Python3 verifier never calculates calendar values.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
NUMERIC=["1 0 0 0","0 0 1 0","2 10 0 10",
         "0 10 2 10","3 2 0 4","1 0 1 15055671"]
LEXICAL=["0 -1 0 1","-0 1 0 1","0 1 -0 1",
         "0 1 0 -1","0 -0 0 1","0 0 0 -0",
         "0 -15055671 0 1","0 15055671 0 -15055670",
         "0 1 0 1 7","0 1 0","0 1 0 x",
         "0 1 0 1/","","\n","0 1 0 +1"]
VALID=["0 0 0 0","1 15055672 1 15055670","0 1 0 2"]
def need(cond,msg):
    if not cond:raise AssertionError(msg)
def pin():
    b=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\0"+b).hexdigest()
    need(sha==PIN,"pinned QA source changed")
def verify(report):
    need(report.get("schema")=="befunge-stage1-invalid-valid-same-object-reset-v1"
         and report.get("source_git_blob")==PIN
         and report.get("status")=="QA_ONLY_STAGE1_OPEN"
         and report.get("same_program_native_executions")==42
         and report.get("invalid_inputs")==21
         and report.get("valid_recovery_runs")==21
         and report.get("native_independent_reference_invocations")==9
         and report.get("program_identity_consistent") is True
         and report.get("all_previous_space_write_targets_rechecked") is True
         and report.get("stage1_final_acceptance") is False,
         "source, bounded scope or reset manifest forged")
    records=report.get("records")
    need(isinstance(records,list) and len(records)==42,
         "same-Program 42 Native runs missing")
    identity=records[0].get("program_identity")
    need(type(identity) is int and identity>0,"Native Program identity invalid")
    anchor_outputs={}
    invalids=NUMERIC+LEXICAL
    for i,raw in enumerate(invalids):
        family="numeric" if i<6 else "lexical"
        index=i if i<6 else i-6
        for sub in range(2):
            ix=2*i+sub
            row=records[ix]
            kind="invalid" if sub==0 else "valid"
            expected_raw=raw if sub==0 else VALID[i%3]
            need(row.get("ordinal")==ix and row.get("kind")==kind
                 and row.get("invalid_family")==family
                 and row.get("invalid_index")==index
                 and row.get("raw")==expected_raw
                 and row.get("program_identity")==identity
                 and row.get("new_space_after_reset") is True
                 and row.get("new_semantics_after_reset") is True
                 and row.get("fresh_io_after_reset") is True
                 and row.get("terminated") is True
                 and row.get("previous_space_preserved") is True
                 and row.get("output")==row.get("expected")
                 and isinstance(row.get("output"),list)
                 and len(row["output"])==7,
                 "Native invalid/valid interleaving or ownership check forged")
            need(all(isinstance(v,str) for v in row["output"]),
                 "Native output tokens invalid")
            if kind=="invalid":
                need(row["output"]==["-1"]*7,
                     "Native invalid lexical/numeric input not rejected")
            else:
                if expected_raw in anchor_outputs:
                    need(row["output"]==anchor_outputs[expected_raw],
                         "freshly reset valid reference changed across invocations")
                else:anchor_outputs[expected_raw]=row["output"]
            prev=records[ix-1]["snapshot_cells"] if ix else 0
            need(type(row.get("snapshot_cells")) is int
                 and row["snapshot_cells"]>=9
                 and type(row.get("write_targets_checked")) is int
                 and 0<=row["write_targets_checked"]<=row["snapshot_cells"]
                 and row.get("previous_space_checked_before")==prev
                 and row.get("previous_space_checked_after")==prev,
                 "Native stale-space write destinations/snapshots not retained")
    need(len(anchor_outputs)==3,
         "three native Befunge independent recovery references missing")
    return {"same_program_runs":42,"invalid":21,"valid_recovery":21,
            "native_references":3,
            "actual_write_target_cells_total":
                 sum(r["write_targets_checked"] for r in records),
            "old_space_snapshot_cells_verified":
                 sum(r["previous_space_checked_after"] for r in records)}
def main(folder):
    pin()
    source=Path(folder)/"native_invalid_valid_same_program_reset.json"
    with source.open(encoding="utf-8") as f:data=json.load(f)
    verified=verify(data)
    print("NATIVE_INVALID_VALID_42_RESET_INDEPENDENT_AUDIT_PASS",verified)
    def reject(name,fn):
        tampered=copy.deepcopy(data);fn(tampered)
        try:verify(tampered)
        except AssertionError:
            print("NATIVE_INVALID_VALID_RESET_TAMPER_REJECT_PASS",name)
            return name
        raise AssertionError("Native same-object reset forged proof accepted: "+name)
    forged=[
        reject("wrong_source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        reject("dropped_run",lambda d:d["records"].pop()),
        reject("swapped_invalid_raw",lambda d:d["records"][0].__setitem__("raw","0 0 0 0")),
        reject("fake_sentinel",lambda d:d["records"][0]["output"].__setitem__(0,"0")),
        reject("identity_changed",lambda d:d["records"][1].__setitem__(
            "program_identity",d["records"][1]["program_identity"]+1)),
        reject("stale_space_dirty",lambda d:d["records"][1].__setitem__(
            "previous_space_preserved",False)),
        reject("skip_write_targets",lambda d:d["records"][1].__setitem__(
            "previous_space_checked_after",0)),
        reject("fake_final_acceptance",lambda d:d.__setitem__("stage1_final_acceptance",True))
    ]
    need(len(forged)==8,"same Program negative audit incomplete")
    evidence={"schema":"befunge-stage1-invalid-valid-reset-audit-v1",
              "verified":verified,"eight_negative_reports_rejected":forged,
              "stage1_final_acceptance":False}
    with (Path(folder)/"native_invalid_valid_reset_audit.json").open(
         "w",encoding="utf-8") as f:
        json.dump(evidence,f,sort_keys=True,indent=2);f.write("\n")
    print("NATIVE_INVALID_VALID_RESET_8_NEGATIVE_REPORTS_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"expected native reset evidence directory")
    main(sys.argv[1])
