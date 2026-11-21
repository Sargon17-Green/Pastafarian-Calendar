#!/usr/bin/env python3
"""Independent Stage-1 evidence audit: live peer survives injected native p fault.

Grounds report to the source Git blob and exact six case identities;
cross-checks outputs against native reference fields recorded by producer.
No calendar arithmetic; rejects twelve crafted false QA certificates.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=[
    ("v1","v2","a",1,"AB"),
    ("v0","i3","b",1,"BA"),
    ("i2","v5","a",1,"AB"),
    ("v2","v3","b",20,"BA"),
    ("v5","v0","a",5,"BA"),
    ("i3","v1","a",1,"AB"),
]
def require(ok,why):
    if not ok:raise AssertionError(why)
def pin():
    b=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+
                     b"\0"+b).hexdigest()
    require(sha==PIN,"QA production Git blob changed")
def verify(o):
    labels=sorted(set(c[0] for c in CASES)|set(c[1] for c in CASES))
    require(o.get("schema")=="befunge-stage1-faulted-live-peer-v1"
         and o.get("production_source_git_blob")==PIN
         and o.get("status")=="QA_ONLY_STAGE1_OPEN"
         and o.get("native_pair_trials")==6
         and o.get("native_program_runs")==18
         and o.get("injected_actual_put_failures")==6
         and o.get("reference_labels")==labels
         and o.get("undocumented_memory_apis_covered") is False
         and o.get("stage1_final_acceptance") is False,
         "Native fault-pair evidence manifest or limitations changed")
    e=o.get("expected_by_label")
    require(isinstance(e,dict) and set(e)==set(labels),
            "independent Befunge reference matrix absent")
    for name in labels:
        out=e[name]
        require(isinstance(out,list) and len(out)==7 and
                all(isinstance(x,str) for x in out),
                "Befunge reference output malformed")
        if name[0]=="i":
            require(out==["-1"]*7,"invalid Native reference not rejected")
    rows=o.get("records")
    require(isinstance(rows,list) and len(rows)==6,
            "six Native injection scenarios incomplete")
    totals={"peer_steps":0,"peer_puts":0,"fault_puts":0,"aborted_cells":0}
    for i,(a,b,faulty,depth,schedule) in enumerate(CASES):
        r=rows[i]
        survivor=b if faulty=="a" else a
        victim=a if faulty=="a" else b
        require(r.get("left")==a and r.get("right")==b and
                r.get("fault_side")==faulty and
                r.get("fault_after_put")==depth and
                r.get("schedule")==schedule and
                all(r.get(flag) is True for flag in (
                    "failure_caught","peer_terminated",
                    "peer_unchanged_at_injection","aborted_space_preserved",
                    "same_faulty_object_recovered","abandoned_io_preserved")) and
                r.get("peer_output")==e[survivor] and
                r.get("recovery_output")==e[victim],
                "Native fault injection, peer, or reference output forged")
        for key in ("fault_round","overlap_rounds","peer_steps",
                    "peer_get","peer_put","peer_direct_p",
                    "fault_get","fault_put","fault_direct_p",
                    "prior_peer_write_cells_checked",
                    "aborted_memory_cells_checked","putspace_calls"):
            require(type(r.get(key)) is int and r[key]>=0,
                    "Native report lacks numeric evidence "+key)
        require(r["fault_round"]>0 and r["overlap_rounds"]>0 and
                r["peer_steps"]>0 and r["peer_get"]>0 and
                r["fault_get"]>0 and r["peer_put"]>0 and
                r["fault_put"]==depth and
                r["fault_direct_p"]==r["fault_put"] and
                r["peer_direct_p"]==r["peer_put"] and
                r["putspace_calls"]==0 and
                r["aborted_memory_cells_checked"]>=13,
                "native peer memory-ownership evidence incomplete")
        totals["peer_steps"]+=r["peer_steps"]
        totals["peer_puts"]+=r["peer_put"]
        totals["fault_puts"]+=r["fault_put"]
        totals["aborted_cells"]+=r["aborted_memory_cells_checked"]
    return totals
def main(folder):
    pin()
    path=Path(folder)
    with (path/"native_faulting_peer_survival.json").open(
            encoding="utf-8") as f: report=json.load(f)
    result=verify(report)
    print("NATIVE_LIVE_PEER_FAILURE_INDEPENDENT_AUDIT_PASS",result)
    def reject(name,mutation):
        bad=copy.deepcopy(report);mutation(bad)
        try:verify(bad)
        except AssertionError:
            print("NATIVE_PEER_FAILURE_TAMPER_REJECT_PASS",name)
            return name
        raise AssertionError("forged Native fault isolation accepted: "+name)
    rejects=[
        reject("wrong_source",lambda z:z.__setitem__("production_source_git_blob","0"*40)),
        reject("missing_trial",lambda z:z["records"].pop()),
        reject("wrong_side",lambda z:z["records"][0].__setitem__("fault_side","b")),
        reject("wrong_depth",lambda z:z["records"][3].__setitem__("fault_after_put",1)),
        reject("wrong_peer_output",lambda z:z["records"][0]["peer_output"].__setitem__(0,"BAD")),
        reject("wrong_recovery",lambda z:z["records"][0]["recovery_output"].__setitem__(0,"BAD")),
        reject("lost_fault",lambda z:z["records"][0].__setitem__("failure_caught",False)),
        reject("peer_corruption",lambda z:z["records"][0].__setitem__(
            "peer_unchanged_at_injection",False)),
        reject("dirty_old_space",lambda z:z["records"][0].__setitem__(
            "aborted_space_preserved",False)),
        reject("unowned_write",lambda z:z["records"][0].__setitem__("fault_direct_p",0)),
        reject("undocumented_api",lambda z:z.__setitem__("undocumented_memory_apis_covered",True)),
        reject("falsely_closed_gate",lambda z:z.__setitem__("stage1_final_acceptance",True))
    ]
    require(len(rejects)==12,"12 independent negative probes incomplete")
    out={"schema":"befunge-stage1-native-peer-failure-audit-v1",
         "verified":result,"tampered_reports_rejected":rejects,
         "stage1_final_acceptance":False}
    with (path/"native_faulting_peer_survival_audit.json").open(
         "w",encoding="utf-8") as f:
        json.dump(out,f,sort_keys=True,indent=2);f.write("\n")
    print("NATIVE_PEER_FAILURE_12_NEGATIVE_REPORTS_PASS")
if __name__=="__main__":
    require(len(sys.argv)==2,"expected Native fault-pair evidence directory")
    main(sys.argv[1])
