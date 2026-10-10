#!/usr/bin/env python3
"""Independent Native eight-live peer-memory ownership and hostile-report audit."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GROUPS=(("v0","v1","v2","v3","v4","v5","i0","i1"),("v2","v3","i2","i3","i4","i5","i6","i7"),("v0","v4","i8","i9","i10","i11","i12","i13"),("v1","v5","i14","i15","i16","i17","i18","i19"),("v0","v3","v4","v5","i20","i1","i8","i14"))
PROFILES=(
 {"name":"ABCDEFGH_11_7_13_5_3_2_17_19","quanta":[11,7,13,5,3,2,17,19],
  "order":[0,1,2,3,4,5,6,7]},
 {"name":"HGFEDCBA_2_17_3_19_11_5_7_13","quanta":[2,17,3,19,11,5,7,13],
  "order":[7,6,5,4,3,2,1,0]}
)
INVALID=[
 "1 0 0 0","0 0 1 0","2 10 0 10","0 10 2 10",
 "3 2 0 4","1 0 1 15055671","0 -1 0 1","-0 1 0 1",
 "0 1 -0 1","0 1 0 -1","0 -0 0 1","0 0 0 -0",
 "0 -15055671 0 1","0 15055671 0 -15055670",
 "0 1 0 1 7","0 1 0","0 1 0 x","0 1 0 1/",
 "","\n","0 1 0 +1"
]
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def verify(d):
    labels={t for group in GROUPS for t in group}
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-native-eight-live-ownership-v1" and
         d.get("source_git_blob")==PIN and
         d.get("status")=="FINITE_NATIVE_QA_STAGE1_OPEN" and
         d.get("octads")==[list(g) for g in GROUPS] and
         d.get("schedules")==list(PROFILES) and
         d.get("valid_reference_labels")==sorted(z for z in labels if z[0]=="v") and
         d.get("invalid_reference_labels")==sorted(z for z in labels if z[0]=="i") and
         d.get("invalid_full_corpus")==INVALID and
         type(d.get("native_eight_program_trials")) is int and
         d["native_eight_program_trials"]==10 and
         type(d.get("native_program_executions")) is int and
         d["native_program_executions"]==80 and
         type(d.get("independent_befunge_reference_calls")) is int and
         d["independent_befunge_reference_calls"]==18 and
         d.get("all_eight_programs_ever_simultaneously_live") is True and
         type(d.get("last_completed_stage")) is int and
         d["last_completed_stage"]==0 and
         d.get("stage1_final_acceptance") is False and
         d.get("production_modified") is False,
         "eight-live identities, samples or stage acceptance manipulated")
    oracle=d.get("oracle")
    need(type(oracle) is dict and set(oracle)==labels and
         all(type(x) is list and len(x)==7 and
             all(type(v) is str for v in x) for x in oracle.values()) and
         all(oracle[k]==["-1"]*7 for k in labels if k[0]=="i"),
         "Native BF98 independent source-specific references tampered")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==10,
         "Native octad session count missing")
    signatures={}
    counts={l:0 for l in labels}
    totals={"eight_live_trials":10,"native_program_executions":80,
            "eight_simultaneous_rounds":0,"peer_state_checks":0,
            "physically_written_peer_cells_checked":0}
    for i,row in enumerate(rows):
        group=GROUPS[i%5]
        profile=PROFILES[i//5]
        need(type(row) is dict and row.get("group")==list(group)
             and row.get("profile")==profile["name"]
             and row.get("separate_programs_spaces_semantics_io") is True
             and row.get("every_get_put_owned_by_active") is True
             and row.get("all_seven_peers_frozen_per_quantum") is True
             and row.get("all_eight_terminated_reference_equal") is True
             and row.get("first_finished_label") in group,
             "eight-live independent ownership, schedule or identity mismatch")
        for col in ("all_eight_alive_rounds","seven_passive_state_checks",
                    "previous_written_peer_address_checks","rounds_after_first_finished"):
            need(type(row.get(col)) is int and row[col]>0,
                 "Native eight-live physical overlap or snapshot missing "+col)
        items=row.get("programs")
        need(type(items) is list and len(items)==8 and
             [v.get("label") for v in items]==list(group),
             "Native peer profile labels manipulated")
        for entry in items:
            label=entry["label"]
            need(type(entry.get("ticks")) is int and
                 0<entry["ticks"]<=250000 and
                 type(entry.get("native_get")) is int and
                 entry["native_get"]>0 and
                 type(entry.get("native_put")) is int and
                 entry["native_put"]>0 and
                 type(entry.get("native_direct_p")) is int and
                 entry["native_direct_p"]==entry["native_put"] and
                 type(entry.get("native_putspace")) is int and
                 entry["native_putspace"]==0 and
                 type(entry.get("physical_written_coordinates")) is int and
                 0<entry["physical_written_coordinates"]<=entry["native_put"] and
                 entry.get("output")==oracle[label],
                 "native eight-live termination/reference/physical write disagreement")
            signature=(entry["ticks"],entry["native_get"],entry["native_put"],
                       tuple(entry["output"]))
            if label in signatures:
                need(signatures[label]==signature,
                     "eight-live schedule/peer contamination of output or IP ticks")
            else:signatures[label]=signature
            counts[label]+=1
        totals["eight_simultaneous_rounds"]+=row["all_eight_alive_rounds"]
        totals["peer_state_checks"]+=row["seven_passive_state_checks"]
        totals["physically_written_peer_cells_checked"]+=row["previous_written_peer_address_checks"]
    need(set(signatures)==labels and all(x>=2 for x in counts.values()) and
         set("i"+str(k) for k in range(21)).issubset(labels) and
         set("v"+str(k) for k in range(6)).issubset(labels),
         "not all invalid/native value families covered twice")
    return totals
def main(directory):
    production=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(production)).encode()+b"\0"+production).hexdigest()==PIN,
         "Native production BF98 source drifted")
    root=Path(directory)
    doc=json.loads((root/"native_eight_live_programs.json").read_text("utf-8"))
    observed=verify(doc)
    attacks=[
      ("stage",lambda x:x.__setitem__("last_completed_stage",1)),
      ("fake_acceptance",lambda x:x.__setitem__("stage1_final_acceptance",True)),
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("missing",lambda x:x["records"].pop()),
      ("reordered",lambda x:x["records"].reverse()),
      ("shared_space",lambda x:x["records"][0].__setitem__("separate_programs_spaces_semantics_io",False)),
      ("wrong_owner",lambda x:x["records"][0].__setitem__("every_get_put_owned_by_active",False)),
      ("peer_changed",lambda x:x["records"][0].__setitem__("all_seven_peers_frozen_per_quantum",False)),
      ("overlap",lambda x:x["records"][0].__setitem__("all_eight_alive_rounds",0)),
      ("tamper_output",lambda x:x["records"][0]["programs"][0]["output"].__setitem__(0,"FORGED")),
      ("tamper_ticks",lambda x:x["records"][5]["programs"][0].__setitem__("ticks",1)),
      ("tamper_write",lambda x:x["records"][0]["programs"][0].__setitem__("native_put",0)),
      ("tamper_space",lambda x:x["records"][0]["programs"][0].__setitem__("physical_written_coordinates",0)),
      ("tamper_input",lambda x:x["records"][0]["programs"][0].__setitem__("label","i20")),
      ("tamper_oracle",lambda x:x["oracle"]["i20"].__setitem__(0,"17")),
      ("missing_invalid",lambda x:x["invalid_full_corpus"].pop())
    ]
    rejected=[]
    for name,act in attacks:
        copydoc=copy.deepcopy(doc);act(copydoc)
        try:verify(copydoc)
        except (AssertionError,KeyError,IndexError,TypeError):rejected.append(name)
        else:raise AssertionError("accepted forged eight-program ownership proof "+name)
    need(len(rejected)==16,"Native hostile eight-program controls incomplete")
    result={"schema":"befunge-stage1-native-eight-live-audit-v1",
            "verified":observed,"hostile_reports_rejected":rejected,
            "last_completed_stage":0,"stage1_accepted":False}
    (root/"native_eight_live_programs_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_EIGHT_LIVE_10_TRIALS_80_PROGRAMS_INDEPENDENT_AUDIT_PASS",
          json.dumps(observed,sort_keys=True))
    print("NATIVE_EIGHT_LIVE_16_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native eight-live evidence directory required")
    main(sys.argv[1])
