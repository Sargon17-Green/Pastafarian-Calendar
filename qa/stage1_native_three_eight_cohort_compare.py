#!/usr/bin/env python3
"""Independent real Native BF98 3-live vs 8-live ownership cross-check.

These are 2 separately executed, original-source-pinned Native PyFunge
program cohorts downloaded from exactly the same GitHub Actions run.
Validate each entire original report via its own independent auditor, then
compare all 27 input IDs (6 valid, all 21 invalid), exact BF98 IP steps,
every Funge-space API read/write count, and seven actual output words.
No Python calendar algorithm or final Stage1 acceptance.
"""
import copy,hashlib,json,sys
from pathlib import Path
import stage1_native_three_live_audit as triad
import stage1_native_eight_live_programs_audit as octad
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def need(x,why):
    if not x:raise AssertionError(why)
def unpack(report,size):
    signatures={};repetitions={}
    for row in report["records"]:
        for member in row["programs"]:
            name=member["label"]
            sig=(member["ticks"],
                 member["space_get"] if size==3 else member["native_get"],
                 member["space_put"] if size==3 else member["native_put"],
                 tuple(member["output"]))
            need(name not in signatures or signatures[name]==sig,
                 "Native input mutated under peer order in "+str(size)+" cohort")
            signatures[name]=sig
            repetitions[name]=repetitions.get(name,0)+1
    need(all(n>=2 for n in repetitions.values()),
         "native input missing a second genuinely independent scheduling profile")
    return signatures,repetitions
def check(three,eight):
    need(three.get("source_git_blob")==eight.get("source_git_blob")==PIN
         and three.get("final_stage1_accepted") is False
         and eight.get("stage1_final_acceptance") is False
         and eight.get("production_modified") is False,
         "different production source or misleading final Stage1 ownership claim")
    triad.verify(three);octad.verify(eight)
    a,ra=unpack(three,3)
    b,rb=unpack(eight,8)
    correct={"v%d"%i for i in range(6)}|{"i%d"%i for i in range(21)}
    need(set(a)==set(b)==correct and len(a)==len(b)==27
         and len(three["records"])==50 and len(eight["records"])==10,
         "3-vs-8 independent Native owner missing 27 full-corpus cases")
    signatures=[]
    for name in sorted(correct):
        need(a[name]==b[name],
             "Native source BF98 reentrancy drift: "+name+
             " three="+repr(a[name])+" eight="+repr(b[name]))
        need(three["oracle"][name]==eight["oracle"][name]==list(a[name][3]),
             "seven independent Native Befunge words disagree between cohorts")
        if name.startswith("i"):
            need(list(a[name][3])==["-1"]*7,
                 "invalid input produced a non-sentinel under one concurrent cohort")
        signatures.append({"case":name,"native_ip_steps":a[name][0],
                           "native_space_get":a[name][1],
                           "native_space_put":a[name][2],
                           "seven_output_words":list(a[name][3]),
                           "triad_repetitions":ra[name],
                           "octad_repetitions":rb[name]})
    return {"three_live_native_executions":150,
            "eight_live_native_executions":80,
            "full_valid_input_ids":6,"full_invalid_input_ids":21,
            "exact_matching_3_v_8_input_signatures":27,
            "identical_seven_field_output_words":189,
            "identical_native_tick_get_put_signatures":27,
            "same_production_source_git_blob":PIN,
            "members":signatures,"last_completed_stage":0}
def main():
    need(len(sys.argv)==3,"usage: compare.py TRIAD_RUN_DIR OCTAD_RUN_DIR")
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "Native BF98 production source no longer pinned")
    three_path,eight_path=map(Path,sys.argv[1:])
    a=json.loads((three_path/"native_three_live_programs.json").read_text("utf-8"))
    b=json.loads((eight_path/"native_eight_live_programs.json").read_text("utf-8"))
    x=json.loads((three_path/"native_three_live_programs_audit.json").read_text("utf-8"))
    y=json.loads((eight_path/"native_eight_live_programs_audit.json").read_text("utf-8"))
    need(x.get("schema")=="befunge-stage1-native-three-live-audit-v1"
         and x.get("stage1_final_acceptance") is False
         and len(x.get("rejected_adversaries",[]))==16
         and y.get("schema")=="befunge-stage1-native-eight-live-audit-v1"
         and y.get("stage1_accepted") is False
         and len(y.get("hostile_reports_rejected",[]))==16,
         "original Native cohort independent audit not successfully evidenced")
    result=check(a,b)
    attacks=[
      ("triad_source",lambda t,o:t.__setitem__("source_git_blob","0"*40)),
      ("octad_source",lambda t,o:o.__setitem__("source_git_blob","0"*40)),
      ("triad_stage",lambda t,o:t.__setitem__("final_stage1_accepted",True)),
      ("octad_stage",lambda t,o:o.__setitem__("stage1_final_acceptance",True)),
      ("triad_missing",lambda t,o:t["records"].pop()),
      ("octad_missing",lambda t,o:o["records"].pop()),
      ("triad_reorder",lambda t,o:t["records"].reverse()),
      ("octad_reorder",lambda t,o:o["records"].reverse()),
      ("triad_get",lambda t,o:t["records"][0]["programs"][0].__setitem__("space_get",1)),
      ("octad_get",lambda t,o:o["records"][0]["programs"][0].__setitem__("native_get",1)),
      ("triad_put",lambda t,o:t["records"][0]["programs"][0].__setitem__("space_put",0)),
      ("octad_put",lambda t,o:o["records"][0]["programs"][0].__setitem__("native_put",0)),
      ("triad_output",lambda t,o:t["records"][0]["programs"][0]["output"].__setitem__(0,"FAKE")),
      ("octad_output",lambda t,o:o["records"][0]["programs"][0]["output"].__setitem__(0,"FAKE")),
      ("triad_owner",lambda t,o:t["records"][0].__setitem__("two_other_programs_unchanged_each_quantum",False)),
      ("octad_owner",lambda t,o:o["records"][0].__setitem__("all_seven_peers_frozen_per_quantum",False)),
      ("invalid_sentinal",lambda t,o:o["oracle"]["i20"].__setitem__(0,"7")),
    ]
    rejected=[]
    for label,mutate in attacks:
        ta=copy.deepcopy(a);ob=copy.deepcopy(b)
        mutate(ta,ob)
        try:check(ta,ob)
        except (AssertionError,KeyError,IndexError,TypeError):rejected.append(label)
        else:raise AssertionError("forged three/eight Native ownership accepted "+label)
    need(len(rejected)==17,
         "seventeen malicious three/eight cross-cohort reports missing")
    result_doc={"schema":"befunge-stage1-native-three-eight-full-corpus-cross-audit-v1",
                "source_git_blob":PIN,
                "scope":"SAME_RUN_INDEPENDENT_NATIVE_THREE_AND_EIGHT_COHORT_REPORTS",
                "observed":result,"falsified_reports_rejected":rejected,
                "last_completed_stage":0,"stage1_final_acceptance":False,
                "production_modified":False}
    (eight_path/"native_three_eight_owner_cross_audit.json").write_text(
        json.dumps(result_doc,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_BF98_3_TO_8_LIVE_ALL_27_EXACT_INPUT_SIGNATURES_PASS",
          json.dumps({k:v for k,v in result.items() if k!="members"},sort_keys=True))
    print("NATIVE_BF98_THREE_EIGHT_CROSS_17_FORGED_REPORTS_REJECT_PASS")
    print("LAST_COMPLETED_STAGE=0 STAGE1_OWNER_FINAL_GATE=OPEN")
if __name__=="__main__":main()
