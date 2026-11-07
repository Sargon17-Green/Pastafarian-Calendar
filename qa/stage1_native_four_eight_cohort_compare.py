#!/usr/bin/env python3
"""Independent Native BF98 four-vs-eight live ownership cross-artifact audit.

Both original four- and eight-concurrent BF98 programs remain intact and
execute in independent GitHub Actions jobs of THE SAME workflow run. Verify
each report using its own independent fail-closed auditor, then confirm all
19 common input cases produce the identical real IP ticks, Funge-space API
read/write counts and seven-field numerical outputs regardless of group size
and both asymmetric execution schedules. The 8-live corpus also includes
all 21 invalid inputs. This proves finite observational cohort isolation,
not final Stage 1 semantic ownership, geometric or functional acceptance.
"""
import copy,hashlib,json,sys
from pathlib import Path
import stage1_native_four_live_programs_audit as four
import stage1_native_eight_live_programs_audit as eight
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def need(ok,why):
    if not ok:raise AssertionError(why)
def signatures(doc,n):
    sig={};exposures={};sites={}
    for row in doc["records"]:
        for p in row["programs"]:
            label=p["label"]
            q=(p["ticks"],p["native_get"],p["native_put"],
               tuple(p["output"]))
            need(label not in sig or sig[label]==q,
                 "Native input semantic signature varies within cohort "+str(n))
            sig[label]=q
            exposures[label]=exposures.get(label,0)+1
            need(p["native_putspace"]==0 and
                 p["native_direct_p"]==p["native_put"] and
                 p["physical_written_coordinates"]>0,
                 "Native source Funge-space own write provenance missing")
            sites[label]=max(sites.get(label,0),
                             p["physical_written_coordinates"])
    need(all(v>=2 for v in exposures.values()),
         "one Native input not repeated in both adversarial schedules")
    return sig,exposures,sites
def validate(quads,octads):
    need(quads.get("source_git_blob")==octads.get("source_git_blob")==PIN
         and quads.get("stage1_final_acceptance") is False
         and octads.get("stage1_final_acceptance") is False
         and quads.get("production_modified") is False
         and octads.get("production_modified") is False,
         "Native cohort source or limited QA scope not identical")
    four.verify(quads)
    eight.verify(octads)
    q,qe,qs=signatures(quads,4)
    o,oe,os=signatures(octads,8)
    need(len(q)==19 and len(o)==27 and set(q).issubset(set(o))
         and len(set(o)-set(q))==8,
         "expected 19 four-live input cases not contained in full 27-case octad corpus")
    matches=[]
    for label in sorted(q):
        need(q[label]==o[label],
             "Native four/eight peer count or schedule changes input "+label+
             " four="+repr(q[label])+" eight="+repr(o[label]))
        need(qs[label]==os[label] and qs[label]>0,
             "real native write-coordinate count changed with cohort size")
        need(quads["oracle"][label]==octads["oracle"][label]==list(q[label][3]),
             "Native standalone BF98 oracle not reproducible in both cohorts")
        matches.append({"case":label,"native_ticks":q[label][0],
                        "native_get":q[label][1],"native_put":q[label][2],
                        "native_seven_field_output":list(q[label][3]),
                        "actual_written_addresses":qs[label],
                        "four_executions":qe[label],
                        "eight_executions":oe[label]})
    return {"four_native_programs":56,"eight_native_programs":80,
            "four_cohort_cases":19,"eight_cohort_cases":27,
            "native_common_cases_identical":len(matches),
            "output_words_compared":7*len(matches),
            "native_exact_step_get_put_signatures_identical":len(matches),
            "real_written_coordinate_counts_identical":len(matches),
            "extra_eight_only_cases":sorted(set(o)-set(q)),
            "same_source_git_blob":PIN,"matched":matches,
            "stage1_accepted":False}
def main():
    need(len(sys.argv)==3,
         "usage: compare.py FOUR_COHORT_ARTIFACT_DIR EIGHT_COHORT_ARTIFACT_DIR")
    src=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()==PIN,
         "BF98 original Native production code changed")
    quad_dir,octad_dir=map(Path,sys.argv[1:])
    q=json.loads((quad_dir/"native_four_live_programs.json").read_text("utf-8"))
    o=json.loads((octad_dir/"native_eight_live_programs.json").read_text("utf-8"))
    qa=json.loads((quad_dir/"native_four_live_programs_audit.json").read_text("utf-8"))
    oa=json.loads((octad_dir/"native_eight_live_programs_audit.json").read_text("utf-8"))
    need(qa.get("schema")=="befunge-stage1-four-live-owner-independent-audit-v1"
         and qa.get("source_git_blob")==PIN
         and qa.get("stage1_accepted") is False
         and len(qa.get("hostile_reports_rejected",[]))==13
         and oa.get("schema")=="befunge-stage1-native-eight-live-audit-v1"
         and oa.get("last_completed_stage")==0
         and oa.get("stage1_accepted") is False
         and len(oa.get("hostile_reports_rejected",[]))==16,
         "original independent Native BF98 cohort auditor evidence missing")
    result=validate(q,o)
    tests=[
        ("quad_source",lambda a,b:a.__setitem__("source_git_blob","0"*40)),
        ("octad_source",lambda a,b:b.__setitem__("source_git_blob","0"*40)),
        ("false_quad_completion",lambda a,b:a.__setitem__("stage1_final_acceptance",True)),
        ("false_octad_completion",lambda a,b:b.__setitem__("stage1_final_acceptance",True)),
        ("missing_quad",lambda a,b:a["records"].pop()),
        ("missing_octad",lambda a,b:b["records"].pop()),
        ("reordered_quad",lambda a,b:a["records"].reverse()),
        ("reordered_octad",lambda a,b:b["records"].reverse()),
        ("quad_get",lambda a,b:a["records"][0]["programs"][0].__setitem__("native_get",1)),
        ("octad_get",lambda a,b:b["records"][0]["programs"][0].__setitem__("native_get",1)),
        ("quad_output",lambda a,b:a["records"][0]["programs"][0]["output"].__setitem__(0,"FORGED")),
        ("octad_output",lambda a,b:b["records"][0]["programs"][0]["output"].__setitem__(0,"FORGED")),
        ("quad_owner",lambda a,b:a["records"][0].__setitem__("all_three_peers_frozen_per_quantum",False)),
        ("octad_owner",lambda a,b:b["records"][0].__setitem__("all_seven_peers_frozen_per_quantum",False)),
        ("quad_address",lambda a,b:a["records"][0]["programs"][0].__setitem__("physical_written_coordinates",0)),
        ("octad_address",lambda a,b:b["records"][0]["programs"][0].__setitem__("physical_written_coordinates",0)),
        ("oracle",lambda a,b:b["oracle"]["v0"].__setitem__(0,"-1")),
    ]
    rejected=[]
    for label,attack in tests:
        a=copy.deepcopy(q);b=copy.deepcopy(o)
        attack(a,b)
        try:validate(a,b)
        except (AssertionError,KeyError,TypeError,IndexError):rejected.append(label)
        else:raise AssertionError("forged Native four/eight input accepted "+label)
    need(len(rejected)==17,"Native four/eight hostile corpus incomplete")
    report={"schema":"befunge-stage1-four-versus-eight-native-owner-crosscheck-v1",
            "source_git_blob":PIN,
            "scope":"SAME_RUN_INDEPENDENT_FOUR_AND_EIGHT_NATIVE_OWNER_ARTIFACTS",
            "measured":result,"falsified_reports_rejected":rejected,
            "last_completed_stage":0,"stage1_final_acceptance":False,
            "production_modified":False}
    (octad_dir/"native_four_eight_owner_cross_audit.json").write_text(
        json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_BF98_FOUR_TO_EIGHT_19_EXACT_INPUT_SIGNATURES_PASS",
          json.dumps({k:v for k,v in result.items() if k!="matched"},sort_keys=True))
    print("NATIVE_BF98_FOUR_EIGHT_CROSS_17_FORGED_REPORTS_REJECT_PASS")
    print("LAST_COMPLETED_STAGE=0 STAGE1_OWNER_FINAL_GATE=OPEN")
if __name__=="__main__":main()
