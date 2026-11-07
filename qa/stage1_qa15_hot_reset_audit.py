#!/usr/bin/env python3
"""QA15 independent fail-closed receipt validator. No calendar arithmetic."""
import sys,json,hashlib,copy
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("invalid_valid_cross","i0","v1","v0"),
       ("invalid_valid_large","i4","v2","v5"),
       ("valid_invalid_lexical","v0","v4","i5"),
       ("valid_invalid_numeric","v3","v2","i0"))
BOOLEANS=("same_actor_object","new_actor_space_and_semantics",
          "live_peer_unmodified_at_hot_reset",
          "old_actor_memory_preserved",
          "outputs_match_native_befunge_reference")
def check(x,msg):
    if not x:raise AssertionError(msg)
def verify(d):
    check(type(d) is dict and
          d.get("schema")=="qa15-real-native-live-peer-hot-reset-v1" and
          d.get("source_git_blob")==PIN and d.get("qa_only") is True and
          d.get("stage1_final_accepted") is False and
          d.get("scenario_count")==4 and d.get("native_program_executions")==12
          and d.get("native_reference_invocations")==18,
          "QA15 header/counters/Stage1 assertion invalid")
    rows=d.get("records")
    check(type(rows) is list and len(rows)==4,"QA15 missing or duplicated scenarios")
    oracles={}
    for tup,row in zip(CASES,rows):
        n,first,peer,after=tup
        check((row.get("case"),row.get("before"),row.get("peer"),row.get("after"))==tup,
              "QA15 case roster/ordered transition modified: "+n)
        for k in BOOLEANS:
            check(row.get(k) is True,"QA15 evidence flag false: "+k)
        for k in ("before_reset_overlap","after_reset_overlap","peer_snapshot_checks",
                  "old_actor_written_targets_checked","actor_post_reset_put","peer_put"):
            check(type(row.get(k)) is int and row[k]>0,
                  "QA15 measured counter missing "+k)
        check(row.get("warmup_peer_steps")==1500 and
              row["peer_snapshot_checks"]>=row["before_reset_overlap"],
              "QA15 warmup or peer state verification omitted")
        for label,key in ((first,"before_output"),(peer,"peer_output"),
                          (after,"after_output")):
            values=row.get(key)
            check(type(values) is list and len(values)==7 and
                  all(type(v) is str and v and v.lstrip("-").isdigit()
                      for v in values),
                  "QA15 malformed Native output "+n+key)
            if label.startswith("i"):
                check(values==["-1"]*7,"QA15 invalid input not rejected")
            elif label not in oracles:
                oracles[label]=values
            else:
                check(values==oracles[label],"QA15 repeated Native valid output changed")
    check(len(oracles)==6,"QA15 missing valid oracle classes")
    return {"scenarios":len(rows),
            "before_overlap_rounds":sum(x["before_reset_overlap"] for x in rows),
            "after_overlap_rounds":sum(x["after_reset_overlap"] for x in rows),
            "peer_state_checks":sum(x["peer_snapshot_checks"] for x in rows)}
def main(p):
    b=Path("src/interleaved_work_counts.b98").read_bytes()
    source=hashlib.sha1(b"blob "+str(len(b)).encode()+b"\0"+b).hexdigest()
    check(source==PIN,"QA15 pinned BF98 source changed")
    d=json.loads(Path(p).read_text(encoding="utf-8"))
    summary=verify(d)
    attacks=[
      ("remove_case",lambda z:z["records"].pop()),
      ("forged_source",lambda z:z.__setitem__("source_git_blob","0"*40)),
      ("duplicate_case",lambda z:z["records"].__setitem__(1,copy.deepcopy(z["records"][0]))),
      ("actor_not_same",lambda z:z["records"][0].__setitem__("same_actor_object",False)),
      ("peer_corrupted",lambda z:z["records"][1].__setitem__("live_peer_unmodified_at_hot_reset",False)),
      ("stale_memory_corrupted",lambda z:z["records"][2].__setitem__("old_actor_memory_preserved",False)),
      ("forged_invalid_result",lambda z:z["records"][3]["after_output"].__setitem__(0,"0")),
      ("fake_overlap",lambda z:z["records"][0].__setitem__("after_reset_overlap",0)),
      ("fake_stage1",lambda z:z.__setitem__("stage1_final_accepted",True))]
    for name,attack in attacks:
        fake=copy.deepcopy(d);attack(fake)
        try:verify(fake)
        except AssertionError:pass
        else:raise AssertionError("QA15 forged report accepted: "+name)
    report={"schema":"qa15-live-peer-hot-reset-failclosed-audit-v1",
            "verified":summary,"nine_forged_reports_rejected":[x[0] for x in attacks],
            "stage1_accepted":False}
    output=Path(p).parent/"qa15_hot_reset_independent_audit.json"
    output.write_text(json.dumps(report,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("QA15_NATIVE_HOT_RESET_INDEPENDENT_AUDIT_PASS",json.dumps(summary,sort_keys=True))
    print("QA15_NINE_FORGED_REPORTS_REJECTED")
    print("STAGE1_OPEN")
if __name__=="__main__":
    check(len(sys.argv)==2,"QA15 auditor expects one Native JSON receipt")
    main(sys.argv[1])
