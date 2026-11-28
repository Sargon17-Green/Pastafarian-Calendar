#!/usr/bin/env python3
"""Independent fail-closed Native BF98 four-live concurrency and ownership audit."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GROUPS=(("v0","v1","v2","v3"),("v2","v3","i0","i10"),
        ("i1","v0","i16","v5"),("v4","i4","v1","i14"),
        ("i20","v2","i6","v3"),("i9","i18","v0","v4"),
        ("i0","i8","i11","i17"))
PROFILES=({"name":"ABCD_11_7_13_5","quanta":[11,7,13,5],"order":[0,1,2,3]},
          {"name":"DCBA_2_17_3_19","quanta":[2,17,3,19],"order":[3,2,1,0]})
INVALID=["1 0 0 0","0 0 1 0","2 10 0 10",
         "0 10 2 10","3 2 0 4","1 0 1 15055671",
         "0 -1 0 1","-0 1 0 1","0 1 -0 1",
         "0 1 0 -1","0 -0 0 1","0 0 0 -0",
         "0 -15055671 0 1","0 15055671 0 -15055670",
         "0 1 0 1 7","0 1 0","0 1 0 x",
         "0 1 0 1/","","\n","0 1 0 +1"]
def need(ok,why):
    if not ok:raise AssertionError(why)
def verify(d):
    labels={l for group in GROUPS for l in group}
    need(type(d) is dict
         and d.get("schema")=="befunge-stage1-native-four-live-ownership-v1"
         and d.get("source_git_blob")==PIN
         and d.get("status")=="FINITE_NATIVE_QA_STAGE1_OPEN"
         and d.get("quadruples")==[list(x) for x in GROUPS]
         and d.get("schedules")==list(PROFILES)
         and d.get("valid_reference_labels")==sorted(l for l in labels if l[0]=="v")
         and d.get("invalid_reference_labels")==sorted(l for l in labels if l[0]=="i")
         and d.get("invalid_full_corpus")==INVALID
         and d.get("native_four_program_trials")==14
         and d.get("native_program_executions")==56
         and d.get("independent_befunge_reference_calls")==18
         and d.get("all_four_programs_ever_simultaneously_live") is True
         and d.get("last_completed_stage")==0
         and d.get("stage1_final_acceptance") is False
         and d.get("production_modified") is False,
         "Native four-live source/corpus/schedule or Stage1 state forged")
    oracle=d.get("oracle")
    need(type(oracle) is dict and set(oracle)==labels
         and all(type(z) is list and len(z)==7 for z in oracle.values())
         and all(oracle[l]==["-1"]*7 for l in oracle if l[0]=="i"),
         "Native 4-live BF98 reference input labels not covered")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==14,
         "Native 14 four-program trials incomplete")
    signatures={};presence={k:0 for k in labels}
    totals={"four_program_trials":14,"actual_native_programs":56,
            "all_four_overlapping_rounds":0,"passive_state_checks":0,
            "past_written_peer_cell_checks":0,
            "observed_native_gets":0,"observed_native_puts":0}
    for i,row in enumerate(rows):
        group=GROUPS[i%7];profile=PROFILES[i//7]
        need(row.get("group")==list(group) and row.get("profile")==profile["name"]
             and row.get("separate_programs_spaces_semantics_io") is True
             and row.get("every_get_put_owned_by_active") is True
             and row.get("all_three_peers_frozen_per_quantum") is True
             and row.get("all_four_terminated_reference_equal") is True
             and row.get("first_finished_label") in group,
             "Native four-live ownership, identities or scheduling forged")
        for k in ("all_four_alive_rounds","three_passive_state_checks",
                  "previous_written_peer_address_checks","rounds_after_first_finished"):
            need(type(row.get(k)) is int and row[k]>0,
                 "no overlap, passive ownership or physical written-cell evidence")
        details=row.get("programs")
        need(type(details) is list and len(details)==4
             and [x.get("label") for x in details]==list(group),
             "four native results not in declared source order")
        for item in details:
            label=item["label"]
            need(type(item.get("ticks")) is int and 0<item["ticks"]<=250000
                 and type(item.get("native_get")) is int and item["native_get"]>0
                 and type(item.get("native_put")) is int and item["native_put"]>0
                 and item.get("native_put")==item.get("native_direct_p")
                 and item.get("native_putspace")==0
                 and type(item.get("physical_written_coordinates")) is int
                 and 0<item["physical_written_coordinates"]<=item["native_put"]
                 and item.get("output")==oracle[label],
                 "native 4-live outputs/real p writes or lengths invalid")
            metrics=(item["ticks"],item["native_get"],item["native_put"],
                     tuple(item["output"]))
            if label in signatures:
                need(signatures[label]==metrics,
                     "same source depends on its peers or Native scheduling profile")
            else:signatures[label]=metrics
            presence[label]+=1
            totals["observed_native_gets"]+=item["native_get"]
            totals["observed_native_puts"]+=item["native_put"]
        totals["all_four_overlapping_rounds"]+=row["all_four_alive_rounds"]
        totals["passive_state_checks"]+=row["three_passive_state_checks"]
        totals["past_written_peer_cell_checks"]+=row["previous_written_peer_address_checks"]
    need(set(signatures)==labels and
         all(presence[k]>=2 for k in labels),
         "not all Native 4-live input classes repeated under schedules")
    return totals
def main(path):
    src=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()==PIN,
         "BF98 production source identity changed")
    root=Path(path)
    d=json.loads((root/"native_four_live_programs.json").read_text("utf-8"))
    results=verify(d)
    attacks=[
      ("stage",lambda x:x.__setitem__("stage1_final_acceptance",True)),
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("drop",lambda x:x["records"].pop()),
      ("order",lambda x:x["records"].reverse()),
      ("wrong_peer",lambda x:x["records"][0]["programs"][0].__setitem__("label","i0")),
      ("wrong_output",lambda x:x["records"][0]["programs"][0]["output"].__setitem__(0,"-1")),
      ("shared_memory",lambda x:x["records"][0].__setitem__("separate_programs_spaces_semantics_io",False)),
      ("wrong_owner",lambda x:x["records"][0].__setitem__("every_get_put_owned_by_active",False)),
      ("fake_snapshot",lambda x:x["records"][0].__setitem__("all_three_peers_frozen_per_quantum",False)),
      ("missing_writes",lambda x:x["records"][0]["programs"][0].__setitem__("native_put",0)),
      ("wrong_signature",lambda x:x["records"][7]["programs"][0].__setitem__("ticks",1)),
      ("missing_quads",lambda x:x["records"][0].__setitem__("all_four_alive_rounds",0)),
      ("false_oracle",lambda x:x["oracle"]["i0"].__setitem__(0,"7"))]
    rejected=[]
    for name,mutate in attacks:
        f=copy.deepcopy(d);mutate(f)
        try:verify(f)
        except (AssertionError,KeyError,IndexError,TypeError):rejected.append(name)
        else:raise AssertionError("Native four-live owner accepted forged report "+name)
    need(len(rejected)==13,"Native four-live hostile reports missing")
    summary={"schema":"befunge-stage1-four-live-owner-independent-audit-v1",
             "observed":results,"hostile_reports_rejected":rejected,
             "source_git_blob":PIN,"stage1_accepted":False}
    (root/"native_four_live_programs_audit.json").write_text(
        json.dumps(summary,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_FOUR_LIVE_BF98_14_TRIALS_56_PROGRAMS_INDEPENDENT_AUDIT_PASS",
          json.dumps(results,sort_keys=True))
    print("NATIVE_FOUR_LIVE_13_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native quad evidence directory required")
    main(sys.argv[1])
