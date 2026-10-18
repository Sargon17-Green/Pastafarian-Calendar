#!/usr/bin/env python3
"""Independent fail-closed audit for 3x3 BF98 executed-u payload trials."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",10117,17387),
       ("forward_short",10117,19713),
       ("recent_anchor_next",20197,43749))
def need(ok,m):
    if not ok:raise AssertionError(m)
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-native-u-live-payload-slots-v1"
         and d.get("scope")=="THREE_NATIVE_INPUTS_ALL_THREE_U_TOSS_SLOTS_PLUS_ONE"
         and d.get("source_git_blob")==PIN
         and d.get("native_executions")==12
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("geometric_spaghetti_qa_pass") is False
         and d.get("production_modified") is False,
         "source identity or QA/Stage1 scope changed")
    records=d.get("records")
    need(type(records) is list and len(records)==3,
         "Native u payload matrix missing input cases")
    results={"immediate_changed":0,"next128_route_changed":0,
             "final_changed":0,"slot_final_changed":[0,0,0]}
    for record,(name,stamp,steps) in zip(records,CASES):
        a=record.get("baseline");m=record.get("mutations")
        ref=record.get("reference_7")
        need(record.get("case")==name and
             type(a) is dict and a.get("status")=="normal"
             and a.get("ips")==0 and a.get("steps")==steps
             and type(ref) is list and len(ref)==7 and
             a.get("output")==ref and
             type(m) is list and len(m)==3,
             "Native u baseline/reference/input drift")
        e=a.get("u")
        need(type(e) is dict and e.get("tick")==stamp
             and e.get("position")==[954,1328] and
             e.get("opcode")=="u" and e.get("changed_slot") is None
             and e.get("pre_original")==e.get("pre_executed")
             and e.get("pre_original")==[["1","0","0"],["3"]]
             and type(e.get("post_executed")) is list
             and a.get("next_128_directed_motions") is not None
             and len(a["next_128_directed_motions"])==128,
             "u actual stack-of-stacks data provenance invalid")
        for i,item in enumerate(m):
            b=item.get("run")
            q=b.get("u") if type(b) is dict else None
            need(item.get("slot")==i and type(q) is dict
                 and q.get("tick")==stamp and q.get("position")==[954,1328]
                 and q.get("opcode")=="u" and q.get("changed_slot")==i
                 and q.get("pre_original")==e["pre_original"]
                 and type(q.get("pre_executed")) is list
                 and len(q["pre_executed"])==2
                 and type(q.get("post_executed")) is list
                 and type(b.get("output")) is list
                 and type(b.get("steps")) is int and b["steps"]>stamp+128
                 and type(b.get("ips")) is int
                 and b.get("status") in ("normal","step-limit")
                 and type(b.get("next_128_directed_motions")) is list
                 and len(b["next_128_directed_motions"])==128,
                 "real Native u intervention source/timing/shape invalid")
            expected=copy.deepcopy(e["pre_original"])
            expected[0][i]=str(int(expected[0][i])+1)
            need(q["pre_executed"]==expected,
                 "not exactly one actually executed u TOSS slot changed")
            immediate=q["post_executed"]!=e["post_executed"]
            route=b["next_128_directed_motions"]!=a["next_128_directed_motions"]
            final=b["status"]!="normal" or b["ips"]!=0 or b["output"]!=ref
            need(item.get("immediate_stack_effect") is immediate
                 and item.get("next_128_route_effect") is route
                 and item.get("final_effect") is final,
                 "Native u payload downstream effect assertion forged")
            results["immediate_changed"]+=int(immediate)
            results["next128_route_changed"]+=int(route)
            results["final_changed"]+=int(final)
            results["slot_final_changed"][i]+=int(final)
    return results
def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "Native BF98 production source fingerprint drift")
    root=Path(folder)
    d=json.loads((root/"native_u_payload_slot_matrix.json").read_text("utf-8"))
    totals=verify(d)
    tests=[
       ("wrong_source",lambda x:x.__setitem__("source_git_blob","0"*40)),
       ("false_complete",lambda x:x.__setitem__("stage1_complete",True)),
       ("missing_case",lambda x:x["records"].pop()),
       ("changed_case",lambda x:x["records"][0].__setitem__("case","fake")),
       ("false_ref",lambda x:x["records"][0]["baseline"].__setitem__("output",["-1"]*7)),
       ("not_u",lambda x:x["records"][0]["mutations"][0]["run"]["u"].__setitem__("opcode","j")),
       ("false_early_tick",lambda x:x["records"][0]["mutations"][0]["run"]["u"].__setitem__("tick",99)),
       ("wrong_slot",lambda x:x["records"][0]["mutations"][0]["run"]["u"].__setitem__("changed_slot",2)),
       ("forged_operand",lambda x:x["records"][0]["mutations"][0]["run"]["u"]["pre_executed"][0].__setitem__(0,"-999")),
       ("fake_effect",lambda x:x["records"][0]["mutations"][0].__setitem__("final_effect",
               not x["records"][0]["mutations"][0]["final_effect"]))]
    denied=[]
    for name,mut in tests:
        t=copy.deepcopy(d);mut(t)
        try:verify(t)
        except (AssertionError,KeyError,TypeError,IndexError):denied.append(name)
        else:raise AssertionError("forged Native u payload accepted "+name)
    need(len(denied)==10,"Native u payload anti-tamper controls incomplete")
    result={"schema":"befunge-stage1-u-payload-independent-audit-v1",
            "scope":"MEASURED_THREE_NATIVE_INPUTS_NOT_STAGE1_ACCEPTANCE",
            "native_executions":12,"measurements":totals,
            "falsified_reports_rejected":denied,
            "last_completed_stage":0,"geometric_spaghetti_qa_pass":False}
    (root/"native_u_payload_audit.json").write_text(
         json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_U_TOSS_PAYLOAD_INDEPENDENT_AUDIT_PASS",
          json.dumps(totals,sort_keys=True))
    print("NATIVE_U_PAYLOAD_TEN_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native u payload evidence directory required")
    main(sys.argv[1])
