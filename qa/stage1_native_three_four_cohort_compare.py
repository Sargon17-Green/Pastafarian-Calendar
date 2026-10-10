#!/usr/bin/env python3
"""Native BF98 3-live vs 4-live independent same-run artifact cross-verifier.

Both source reports are validated by their own fail-closed auditors first.
This new witness matches per-input exact native steps, get/put counts and
seven output words across differently-sized simultaneous live cohorts.
It never computes calendar arithmetic, never changes BF98 source and
never promotes Stage 1 ownership acceptance.
"""
import copy,hashlib,json,sys
from pathlib import Path
import stage1_native_three_live_audit as triple
import stage1_native_four_live_programs_audit as quad
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
def need(ok,why):
    if not ok:raise AssertionError(why)
def collect_three(data):
    signatures={}
    for row in data["records"]:
        for item in row["programs"]:
            v=(item["ticks"],item["space_get"],item["space_put"],
               tuple(item["output"]))
            name=item["label"]
            if name in signatures:
                need(signatures[name]==v,"Native three-live input not peer-independent")
            else:signatures[name]=v
    return signatures
def collect_four(data):
    signatures={};presence={}
    for row in data["records"]:
        for item in row["programs"]:
            v=(item["ticks"],item["native_get"],item["native_put"],
               tuple(item["output"]))
            name=item["label"]
            if name in signatures:
                need(signatures[name]==v,"Native four-live input not peer-independent")
            else:signatures[name]=v
            presence[name]=presence.get(name,0)+1
    return signatures,presence
def validate(t,q):
    need(t.get("source_git_blob")==q.get("source_git_blob")==PIN
         and t.get("final_stage1_accepted") is False
         and q.get("stage1_final_acceptance") is False
         and q.get("production_modified") is False,
         "cross-report production source/stage state changed")
    triple.verify(t)
    quad.verify(q)
    a=collect_three(t)
    b,presence=collect_four(q)
    need(len(a)==27 and len(b)==19 and
         set(b).issubset(set(a)) and
         all(n>=2 for n in presence.values()),
         "expected 19 repeated four-live inputs not shared with three-live corpus")
    same=0
    for name in sorted(b):
        need(a[name]==b[name],
             "actual native 3-live vs 4-live semantic ownership drift: "+
             name+" triad="+repr(a[name])+" quad="+repr(b[name]))
        need(tuple(q["oracle"][name])==tuple(t["oracle"][name])==a[name][3],
             "independent Native Befunge oracle changed between cohort sizes")
        same+=1
    return {"three_live_validated_programs":150,
            "four_live_validated_programs":56,
            "three_live_cases":27,"four_live_cases":19,
            "overlapping_input_signatures_identical":same,
            "output_words_compared":same*7,
            "native_step_get_put_signatures_identical":same,
            "same_exact_production_source":True,
            "stage1_complete":False}
def main():
    need(len(sys.argv)==3,"usage: compare.py THREE_NATIVE_ARTIFACT FOUR_NATIVE_ARTIFACT")
    data=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
    need(sha==PIN,"pinned real Native BF98 production changed")
    tri_dir,quad_dir=map(Path,sys.argv[1:])
    t=json.loads((tri_dir/"native_three_live_programs.json").read_text("utf-8"))
    q=json.loads((quad_dir/"native_four_live_programs.json").read_text("utf-8"))
    # Verify the original independent audit outputs were genuinely produced
    # and retain limited QA scope. Do not trust success text alone.
    tri_audit=json.loads((tri_dir/"native_three_live_programs_audit.json").read_text("utf-8"))
    quad_audit=json.loads((quad_dir/"native_four_live_programs_audit.json").read_text("utf-8"))
    need(tri_audit.get("schema")=="befunge-stage1-three-live-independent-audit-v1"
         and tri_audit.get("stage1_final_acceptance") is False
         and len(tri_audit.get("negative_reports_rejected",[]))==16,
         "original triad independent audit artifact not pinned")
    need(quad_audit.get("schema")=="befunge-stage1-four-live-owner-independent-audit-v1"
         and quad_audit.get("stage1_accepted") is False
         and len(quad_audit.get("hostile_reports_rejected",[]))==13,
         "original quad independent audit artifact not pinned")
    matched=validate(t,q)
    attacks=[
      ("triad_source",lambda a,b:a.__setitem__("source_git_blob","0"*40)),
      ("quad_source",lambda a,b:b.__setitem__("source_git_blob","0"*40)),
      ("triad_status",lambda a,b:a.__setitem__("final_stage1_accepted",True)),
      ("quad_status",lambda a,b:b.__setitem__("stage1_final_acceptance",True)),
      ("triad_drop",lambda a,b:a["records"].pop()),
      ("quad_drop",lambda a,b:b["records"].pop()),
      ("triad_wrong_cohort",lambda a,b:a["records"][0].__setitem__("triad",["v5","v1","v2"])),
      ("quad_wrong_cohort",lambda a,b:b["records"][0].__setitem__("group",["v4","v1","v2","v3"])),
      ("quad_timing",lambda a,b:b["records"][0]["programs"][0].__setitem__("ticks",123456)),
      ("triad_reads",lambda a,b:a["records"][0]["programs"][0].__setitem__("space_get",1)),
      ("quad_writes",lambda a,b:b["records"][0]["programs"][0].__setitem__("native_put",0)),
      ("triad_oracle",lambda a,b:a["oracle"]["v0"].__setitem__(0,"-1")),
      ("quad_oracle",lambda a,b:b["oracle"]["v0"].__setitem__(0,"-1")),
      ("quad_memory_owner",lambda a,b:b["records"][0].__setitem__("every_get_put_owned_by_active",False))]
    refused=[]
    for label,mutate in attacks:
        x=copy.deepcopy(t);y=copy.deepcopy(q)
        mutate(x,y)
        try:validate(x,y)
        except (AssertionError,KeyError,IndexError,TypeError):refused.append(label)
        else:raise AssertionError("forged BF98 Native cohort data accepted "+label)
    need(len(refused)==14,"Native cross-cohort negative tests incomplete")
    report={"schema":"befunge-stage1-three-versus-four-live-source-pinned-crosscheck-v1",
            "source_git_blob":PIN,
            "scope":"SAME_RUN_TWO_INDEPENDENT_NATIVE_OWNERSHIP_ARTIFACTS",
            "measured":matched,
            "falsified_reports_rejected":refused,
            "last_completed_stage":0,
            "stage1_final_acceptance":False,
            "production_modified":False}
    (quad_dir/"native_three_four_cross_audit.json").write_text(
        json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_BF98_3_TO_4_LIVE_19_EXACT_INPUT_SIGNATURES_PASS",
          json.dumps(matched,sort_keys=True))
    print("NATIVE_BF98_THREE_FOUR_CROSS_14_FALSIFIED_REPORTS_REJECT_PASS")
    print("LAST_COMPLETED_STAGE=0 STAGE1_OWNER_FINAL_GATE=OPEN")
if __name__=="__main__":main()
