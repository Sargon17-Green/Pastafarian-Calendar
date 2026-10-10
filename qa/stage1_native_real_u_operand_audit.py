#!/usr/bin/env python3
"""Fail-closed independent audit of real Native BF98 u operand transfers.

Nine actual PyFunge Program executions; not a Python calendar oracle.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",10117),("forward_short",10117),
       ("recent_anchor_next",20197))
def need(x,m):
    if not x:raise AssertionError(m)
def check(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-native-real-u-operand-transfer-v1"
         and d.get("scope")=="THREE_VALID_NATIVE_INPUTS_ONE_ACTUAL_U_SITE_PLUS_MINUS_ONE"
         and d.get("source_git_blob")==PIN
         and d.get("actual_native_programs")==9
         and d.get("independent_native_references")==3
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("production_modified") is False
         and d.get("full_geometric_acceptance") is False
         and d.get("cases")==[x[0] for x in CASES],
         "Native u evidence scope/source invalid")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==3,
         "Native u 3-case matrix incomplete")
    tally={"positive_output_effect":0,"negative_output_effect":0,
           "immediate_post_state_changed":0,"post128_route_changed":0}
    for row,(name,tick) in zip(rows,CASES):
        need(row.get("case")==name and
             type(row.get("reference_7")) is list and
             len(row["reference_7"])==7 and
             all(type(x) is str and x.lstrip("-").isdigit()
                 for x in row["reference_7"]),
             "independent Native seven-field oracle corrupted")
        control=row.get("control");mutants=row.get("mutants")
        need(type(control) is dict and
             control.get("status")=="normal" and control.get("ips")==0
             and control.get("output")==row["reference_7"] and
             type(mutants) is list and len(mutants)==2,
             "BF98 unmodified u run or interventions incomplete")
        e=control.get("u_event")
        need(type(e) is dict and e.get("tick")==tick and
             e.get("coordinate")==[954,1328] and
             e.get("executed_opcode")=="u" and
             type(e.get("operand_original")) is int and
             e.get("operand_delta")==0 and
             e.get("operand_executed")==e["operand_original"] and
             e.get("pre_original")==e.get("pre_executed"),
             "real Native baseline executed-u evidence forged")
        p=e["pre_original"]
        need(type(p) is dict and
             type(p.get("frames")) is list and len(p["frames"])==2
             and type(p["frames"][0]) is list and len(p["frames"][0])>=1
             and int(p["frames"][0][-1])==e["operand_original"] and
             p.get("position")==[954,1328] and
             type(control.get("post_u_128_real_motion")) is list and
             len(control["post_u_128_real_motion"])==128,
             "Native u stack-of-stacks baseline missing")
        for item,delta in zip(mutants,(1,-1)):
            t=item.get("run");f=t.get("u_event") if type(t) is dict else None
            need(item.get("delta")==delta and type(f) is dict and
                 f.get("tick")==tick and f.get("coordinate")==[954,1328]
                 and f.get("executed_opcode")=="u"
                 and f.get("operand_delta")==delta
                 and f.get("operand_original")==e["operand_original"]
                 and f.get("operand_executed")==e["operand_original"]+delta
                 and f.get("pre_original")==p
                 and type(f.get("pre_executed")) is dict and
                 type(f["pre_executed"].get("frames")) is list
                 and type(t.get("post_u_128_real_motion")) is list
                 and len(t["post_u_128_real_motion"])==128
                 and type(t.get("steps")) is int and t["steps"]>=tick+128
                 and t.get("status") in ("normal","step-limit")
                 and type(t.get("ips")) is int
                 and type(t.get("output")) is list,
                 "real Native executed-u perturbation evidence malformed")
            changed=copy.deepcopy(p)
            changed["frames"][0][-1]=str(e["operand_original"]+delta)
            need(f["pre_executed"]==changed,
                 "not exactly one real Native u operand modified")
            immediate=f.get("post")!=e.get("post")
            downstream=t["post_u_128_real_motion"]!=control["post_u_128_real_motion"]
            effect=(t["status"]!="normal" or t["ips"]!=0 or
                    t["output"]!=row["reference_7"])
            need(item.get("immediate_post_state_differs") is immediate and
                 item.get("first_128_directed_route_differs") is downstream and
                 item.get("output_or_termination_effect") is effect,
                 "Native u downstream causal classification forged")
            tally["immediate_post_state_changed"]+=int(immediate)
            tally["post128_route_changed"]+=int(downstream)
            tally["positive_output_effect" if delta==1 else
                  "negative_output_effect"]+=int(effect)
    return tally
def main(folder):
    src=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()==PIN,
         "real QA Native source changed")
    root=Path(folder)
    doc=json.loads((root/"u_operand_native_witness.json").read_text("utf-8"))
    stats=check(doc)
    trials=[
       ("false_stage",lambda x:x.__setitem__("stage1_complete",True)),
       ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
       ("missing",lambda x:x["records"].pop()),
       ("case",lambda x:x["records"][0].__setitem__("case","fake")),
       ("oracle",lambda x:x["records"][0]["control"].__setitem__("output",["-1"]*7)),
       ("opcode",lambda x:x["records"][0]["mutants"][0]["run"]["u_event"].__setitem__("executed_opcode",":")),
       ("operand",lambda x:x["records"][0]["mutants"][0]["run"]["u_event"].__setitem__("operand_executed",999)),
       ("stack",lambda x:x["records"][0]["mutants"][0]["run"]["u_event"]["pre_executed"]["frames"][0].__setitem__(-1,"888")),
       ("step",lambda x:x["records"][0]["mutants"][0]["run"]["u_event"].__setitem__("tick",1)),
       ("flags",lambda x:x["records"][0]["mutants"][0].__setitem__("immediate_post_state_differs",
              not x["records"][0]["mutants"][0]["immediate_post_state_differs"])),
       ("effect",lambda x:x["records"][0]["mutants"][0].__setitem__("output_or_termination_effect",
              not x["records"][0]["mutants"][0]["output_or_termination_effect"]))]
    denied=[]
    for name,apply in trials:
        test=copy.deepcopy(doc);apply(test)
        try:check(test)
        except (AssertionError,KeyError,TypeError,IndexError):denied.append(name)
        else:raise AssertionError("accepted forged Native u operand evidence "+name)
    need(len(denied)==11,"Native u anti-tamper coverage incomplete")
    result={"schema":"befunge-stage1-native-real-u-operand-independent-audit-v1",
            "native_programs":9,"measured":stats,
            "falsified_reports_rejected":denied,
            "last_completed_stage":0,"geometric_spaghetti_qa_pass":False}
    (root/"u_operand_native_audit.json").write_text(
        json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_REAL_BF98_U_TRANSFER_INDEPENDENT_AUDIT_PASS",
          json.dumps(stats,sort_keys=True))
    print("NATIVE_REAL_BF98_U_TRANSFER_ELEVEN_FALSIFICATIONS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native u evidence directory required")
    main(sys.argv[1])
