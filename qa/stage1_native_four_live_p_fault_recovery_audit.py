#!/usr/bin/env python3
"""Independent fail-closed audit: one Native BF98 fault, 3 live healthy peers."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SCENARIOS=(
    (("v0","v1","v2","i0"),0,1),
    (("i4","v3","i6","v5"),0,1),
    (("v2","v3","v4","v5"),2,20),
    (("i0","v5","i1","v3"),1,5),
)
PROFILES=("ABCD_2_3_5_7","DCBA_11_13_17_19")
def need(v,why):
    if not v:raise AssertionError(why)
def verify(d):
    names={k for (labels,index,depth) in SCENARIOS for k in labels}
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-native-four-live-immediate-fault-recovery-v1"
         and d.get("source_git_blob")==PIN
         and d.get("scope")=="FOUR_LIVE_ONE_REAL_P_FAULT_THREE_PEERS_FINISH"
         and d.get("four_live_sessions")==8
         and d.get("native_programs_recovered_or_survived")==32
         and d.get("actual_real_p_faults")==8
         and d.get("all_three_peers_alive_at_every_fault") is True
         and d.get("all_faulted_same_program_reinitialized_while_three_alive") is True
         and d.get("independent_befunge_reference_labels")==len(names)
         and d.get("last_completed_stage")==0
         and d.get("stage1_final_acceptance") is False
         and d.get("production_modified") is False,
         "Native live fault source/acceptance/case schema forged")
    refs=d.get("oracle")
    need(type(refs) is dict and set(refs)==names
         and all(type(v) is list and len(v)==7 for v in refs.values())
         and all(v==["-1"]*7 for k,v in refs.items() if k.startswith("i")),
         "independent Native BF98 reference missing")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==8,
         "Native four-live fault-recovery sessions incomplete")
    totals={"faults_observed":0,"four_program_outputs":0,
            "three_passive_state_checks":0,
            "prior_written_passive_cell_checks":0,
            "abandoned_space_checks":0}
    signatures={}
    for ix,r in enumerate(rows):
        group,failing,depth=SCENARIOS[ix%4]
        prof=PROFILES[ix//4]
        need(r.get("labels")==list(group) and r.get("profile")==prof
             and r.get("fault_index")==failing
             and r.get("fault_after_real_p")==depth
             and r.get("alive_healthy_peers_at_fault")==3
             and r.get("faulted_same_object_reinitialized_while_three_alive") is True
             and r.get("fresh_funge_space_not_abandoned_memory") is True
             and r.get("passive_peer_state_unchanged_during_reset") is True
             and r.get("original_dirty_memory_unchanged_after_completion") is True
             and r.get("all_four_outputs_reference_equal") is True
             and r.get("all_four_terminated") is True,
             "real Native p fault did not recover without touching three live peers")
        for key in ("fault_round","all_four_live_rounds",
                    "passive_state_quantum_checks","passive_written_cell_checks",
                    "abandoned_memory_periodic_checks","faulted_dirty_steps",
                    "faulted_dirty_puts","faulted_dirty_gets",
                    "faulted_dirty_written_cells"):
            need(type(r.get(key)) is int and r[key]>0,
                 "missing real Native physical write/fault/peer evidence: "+key)
        need(r["faulted_dirty_puts"]==depth
             and r["faulted_dirty_written_cells"]>=len(r.get("programs",[]))
             and r["faulted_dirty_steps"]>r["faulted_dirty_puts"],
             "the native p fault was not at requested actual depth")
        programs=r.get("programs")
        need(type(programs) is list and len(programs)==4
             and [m.get("label") for m in programs]==list(group),
             "four recovered Native Program identities missing")
        for m in programs:
            label=m["label"]
            need(m.get("output")==refs[label]
                 and type(m.get("steps")) is int and m["steps"]>0
                 and type(m.get("native_get")) is int and m["native_get"]>0
                 and type(m.get("native_put")) is int and m["native_put"]>0
                 and m.get("native_put")==m.get("native_direct_p")
                 and m.get("native_putspace")==0,
                 "Native independent reference, real p memory counts or recovery missing")
            metric=(m["steps"],m["native_get"],m["native_put"],
                    tuple(m["output"]))
            if label in signatures:need(signatures[label]==metric,
                                        "Native four Program output depends on peer schedule")
            else:signatures[label]=metric
            totals["four_program_outputs"]+=1
        totals["faults_observed"]+=1
        totals["three_passive_state_checks"]+=r["passive_state_quantum_checks"]
        totals["prior_written_passive_cell_checks"]+=r["passive_written_cell_checks"]
        totals["abandoned_space_checks"]+=r["abandoned_memory_periodic_checks"]
    return totals
def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "Native BF98 original source blob drift")
    root=Path(folder)
    evidence=json.loads((root/"native_quad_fault_recovery.json").read_text("utf-8"))
    result=verify(evidence)
    attacks=[
      ("wrong_source",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("stage",lambda d:d.__setitem__("stage1_final_acceptance",True)),
      ("missing_case",lambda d:d["records"].pop()),
      ("wrong_fault_depth",lambda d:d["records"][0].__setitem__("fault_after_real_p",2)),
      ("fault_lacks_peers",lambda d:d["records"][0].__setitem__("alive_healthy_peers_at_fault",2)),
      ("fault_recovery",lambda d:d["records"][0].__setitem__("faulted_same_object_reinitialized_while_three_alive",False)),
      ("bad_output",lambda d:d["records"][0]["programs"][0]["output"].__setitem__(0,"FAKE")),
      ("fake_oracle",lambda d:d["oracle"]["i0"].__setitem__(0,"7")),
      ("missing_p",lambda d:d["records"][0]["programs"][0].__setitem__("native_put",0)),
      ("no_write_cells",lambda d:d["records"][0].__setitem__("passive_written_cell_checks",0)),
      ("drift_schedule",lambda d:d["records"][4]["programs"][0].__setitem__("steps",1)),
      ("changed_abandoned",lambda d:d["records"][0].__setitem__("original_dirty_memory_unchanged_after_completion",False))]
    rejected=[]
    for name,mut in attacks:
        forged=copy.deepcopy(evidence);mut(forged)
        try:verify(forged)
        except (AssertionError,TypeError,IndexError,KeyError):rejected.append(name)
        else:raise AssertionError("Accepted forged four-live real Native BF98 p failure: "+name)
    need(len(rejected)==12,"Native four-live fault anti-tamper matrix incomplete")
    report={"schema":"befunge-stage1-native-four-live-fault-recovery-independent-audit-v1",
            "observed":result,"forgeries_rejected":rejected,
            "source_git_blob":PIN,
            "last_completed_stage":0,"stage1_final_acceptance":False}
    (root/"native_quad_fault_recovery_audit.json").write_text(
        json.dumps(report,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_FOUR_LIVE_P_FAULT_WITH_THREE_SURVIVORS_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    print("NATIVE_QUAD_P_FAULT_TWELVE_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"four-live BF98 fault evidence dir required")
    main(sys.argv[1])
