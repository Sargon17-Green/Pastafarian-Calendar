#!/usr/bin/env python3
"""Fail-closed independent audit of 21 actual Native u/x two-channel trials."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",10117,17387),
       ("forward_short",10117,19713),
       ("recent_anchor_next",20197,43749))
def need(x,msg):
    if not x:raise AssertionError(msg)
def succeeded(run,ref):
    return run.get("status")=="normal" and run.get("remaining_ips")==0 and run.get("output")==ref
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-real-u-x-two-channel-mediation-v2"
         and d.get("scope")=="THREE_VALID_NATIVE_INPUTS_DIRECTION_ONLY_VS_TWO_STACK_CELLS"
         and d.get("source_git_blob")==PIN
         and d.get("native_executions")==21
         and d.get("independent_native_references")==3
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("geometric_spaghetti_qa_pass") is False
         and d.get("production_modified") is False,
         "Native BF98 x source identity or QA-only scope false")
    records=d.get("records")
    need(type(records) is list and len(records)==3,
         "Native 3-case and 21-run matrix incomplete")
    tally={"direction_only_rescues":0,"full_stack_rescues":0,
           "direction_only_bounded_failures":0,"full_stack_bounded_failures":0}
    for row,(label,tick,steps) in zip(records,CASES):
        ref=row.get("reference_7");base=row.get("control");pairs=row.get("pairs")
        need(row.get("case")==label and type(ref) is list and len(ref)==7
             and all(type(x) is str and x.lstrip("-").isdigit() for x in ref)
             and type(base) is dict and base.get("steps")==steps
             and succeeded(base,ref) and type(pairs) is list and len(pairs)==2,
             "BF98 native control/reference not authentic")
        control_x=base.get("x");control_u=base.get("u")
        need(type(control_x) is dict and type(control_u) is dict
             and control_x.get("tick")==tick+99
             and control_u.get("tick")==tick
             and control_u.get("before")==[["1","0","0"],["3"]]
             and control_u.get("delta")==0
             and control_x.get("opcode")=="x"
             and control_x.get("position")==[950,1335]
             and control_x.get("pre_actual")==[["1","-1","0"]]
             and control_x.get("pre_executed")==[["1","-1","0"]]
             and control_x.get("post_delta")==[-1,0]
             and control_x.get("mode")=="none"
             and control_x.get("changes")==[],
             "Native actual u/x source stepping changed")
        for pair,delta in zip(pairs,(-1,-2)):
            m=pair.get("mutant");v=pair.get("direction_only");f=pair.get("full_x_input")
            need(pair.get("u_delta")==delta and
                 all(type(x) is dict for x in (m,v,f))
                 and m.get("status")=="step-limit"
                 and m.get("steps")==170001,
                 "original u-count mutant unexpectedly altered")
            pre=[[str(1+delta),str(-1+delta),"0"]]
            events=((m,"none",pre,[-1+delta,0],[]),
                    (v,"direction",[[str(1+delta),"-1","0"]],[-1,0],
                     [{"frame":0,"slot":1,"from":str(-1+delta),"to":"-1"}]),
                    (f,"full",[["1","-1","0"]],[-1,0],
                     [{"frame":0,"slot":1,"from":str(-1+delta),"to":"-1"},
                      {"frame":0,"slot":0,"from":str(1+delta),"to":"1"}]))
            for run,mode,executed,direction,changed in events:
                u=run.get("u");x=run.get("x")
                need(type(u) is dict and type(x) is dict
                     and u.get("tick")==tick
                     and u.get("position")==[954,1328]
                     and u.get("before")==[["1","0","0"],["3"]]
                     and u.get("delta")==delta
                     and u.get("executed")==[[str(1+delta),"0","0"],["3"]]
                     and x.get("tick")==tick+99
                     and x.get("position")==[950,1335]
                     and x.get("opcode")=="x"
                     and x.get("mode")==mode
                     and x.get("pre_actual")==pre
                     and x.get("pre_executed")==executed
                     and x.get("post_delta")==direction
                     and x.get("changes")==changed
                     and run.get("status") in ("normal","step-limit")
                     and type(run.get("steps")) is int
                     and run["steps"]>=tick+99
                     and type(run.get("remaining_ips")) is int
                     and type(run.get("output")) is list,
                     "Native u/x physical two-channel restoration evidence forged")
            dgood=succeeded(v,ref);fgood=succeeded(f,ref)
            need(pair.get("direction_reference_restored") is dgood
                 and pair.get("full_x_reference_restored") is fgood,
                 "claimed Native u/x rescue disagrees with actual reference")
            tally["direction_only_rescues"]+=int(dgood)
            tally["full_stack_rescues"]+=int(fgood)
            tally["direction_only_bounded_failures"]+=int(v["status"]=="step-limit")
            tally["full_stack_bounded_failures"]+=int(f["status"]=="step-limit")
    return tally
def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "Native original BF98 source SHA drift")
    root=Path(folder)
    doc=json.loads((root/"native_real_u_x_mediation.json").read_text("utf-8"))
    measured=verify(doc)
    tests=[
      ("false_completion",lambda d:d.__setitem__("stage1_complete",True)),
      ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("drop",lambda d:d["records"].pop()),
      ("case",lambda d:d["records"][0].__setitem__("case","forged")),
      ("oracle",lambda d:d["records"][0]["control"].__setitem__("output",["-1"]*7)),
      ("u",lambda d:d["records"][0]["pairs"][0]["direction_only"]["u"].__setitem__("delta",0)),
      ("x_tick",lambda d:d["records"][0]["pairs"][0]["full_x_input"]["x"].__setitem__("tick",0)),
      ("original_x",lambda d:d["records"][0]["control"]["x"].__setitem__("post_delta",[-2,0])),
      ("direction_x",lambda d:d["records"][0]["pairs"][0]["direction_only"]["x"].__setitem__("post_delta",[-2,0])),
      ("full_x",lambda d:d["records"][0]["pairs"][0]["full_x_input"]["x"].__setitem__("post_delta",[-2,0])),
      ("wrong_stack",lambda d:d["records"][0]["pairs"][0]["direction_only"]["x"]["pre_executed"][0].__setitem__(0,"1")),
      ("fake_effect",lambda d:d["records"][0]["pairs"][0].__setitem__("direction_reference_restored",
                     not d["records"][0]["pairs"][0]["direction_reference_restored"])),
      ("fake_both",lambda d:d["records"][0]["pairs"][0].__setitem__("full_x_reference_restored",
                     not d["records"][0]["pairs"][0]["full_x_reference_restored"]))]
    rejected=[]
    for name,mod in tests:
        forged=copy.deepcopy(doc);mod(forged)
        try:verify(forged)
        except (AssertionError,KeyError,TypeError,IndexError):rejected.append(name)
        else:raise AssertionError("forged Native two-channel x mediator accepted "+name)
    need(len(rejected)==13,"Native x mediation anti-tamper matrix incomplete")
    result={"schema":"befunge-stage1-u-x-two-channel-independent-audit-v2",
            "native_programs":21,"measured":measured,
            "forged_reports_rejected":rejected,
            "stage1_complete":False,"geometric_spaghetti_qa_pass":False}
    (root/"native_real_u_x_mediation_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_U_X_TWO_CHANNEL_MEDIATION_INDEPENDENT_AUDIT_PASS",
          json.dumps(measured,sort_keys=True))
    print("NATIVE_U_X_THIRTEEN_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native BF98 u/x mediation evidence dir required")
    main(sys.argv[1])
