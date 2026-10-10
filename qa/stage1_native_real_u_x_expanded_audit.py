#!/usr/bin/env python3
"""Independent fail-closed audit of 42 Native BF98 u->x expanded experiments."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
FROZEN=(("reverse_short",10117,19713),
        ("epoch_forward_one",10117,19713),
        ("epoch_reverse_one",10117,19713),
        ("recent_anchor_equal",20197,43749),
        ("positive_negative",23557,51761),
        ("large_values",73957,171941))
LIMIT=260000
def need(ok,why):
    if not ok:raise AssertionError(why)
def succeeded(r,ref):
    return r.get("status")=="normal" and r.get("remaining_ips")==0 and r.get("output")==ref
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-expanded-six-case-native-u-x-mediation-v1"
         and d.get("scope")=="SIX_ADDITIONAL_VALID_INPUTS_WITH_FROZEN_EXECUTED_U_X_TRACE_WITNESSES"
         and d.get("source_git_blob")==PIN
         and d.get("reference_frozen_native_17_trace_cases")==[list(r) for r in FROZEN]
         and d.get("native_programs_executed")==42
         and d.get("independent_native_references")==6
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("automatic_promotion") is False
         and d.get("geometric_spaghetti_qa_pass") is False
         and d.get("production_modified") is False,
         "Native six-case coverage, exact source or QA-only acceptance forged")
    records=d.get("records")
    need(type(records) is list and len(records)==6,"missing Native u-x additional case")
    result={"two_channel_rescues":0,"direction_only_rescues":0,
            "direction_only_normal":0,"unrescued_bounded_divergences":0}
    for row,(name,tick,steps) in zip(records,FROZEN):
        ref=row.get("reference_7")
        base=row.get("control")
        cases=row.get("counterfactuals")
        need(row.get("case")==name and row.get("u_tick")==tick
             and row.get("normal_steps")==steps
             and type(row.get("input_fields")) is list
             and len(row["input_fields"])==4
             and all(type(t) is str and t.isdigit()
                     for t in row["input_fields"])
             and type(ref) is list and len(ref)==7
             and all(type(v) is str and v.lstrip("-").isdigit() for v in ref)
             and type(base) is dict and base.get("steps")==steps
             and succeeded(base,ref)
             and type(cases) is list and len(cases)==2,
             "original actual Native BF98 reference/case witness forged")
        need(base["u"].get("tick")==tick
             and base["u"].get("position")==[954,1328]
             and base["u"].get("delta")==0
             and base["u"].get("before")==[["1","0","0"],["3"]]
             and base["x"].get("tick")==tick+99
             and base["x"].get("position")==[950,1335]
             and base["x"].get("opcode")=="x"
             and base["x"].get("pre_actual")==[["1","-1","0"]]
             and base["x"].get("post_delta")==[-1,0],
             "pinned Native two-opcode physical geometry not witnessed")
        for item,delta in zip(cases,(-1,-2)):
            mut=item.get("unrescued")
            direction=item.get("direction_only")
            full=item.get("full_x_input")
            need(item.get("delta")==delta
                 and all(type(x) is dict for x in (mut,direction,full))
                 and mut.get("status")=="step-limit"
                 and mut.get("steps")==LIMIT+1,
                 "bounded counterfactual control absent")
            original=[[str(1+delta),str(-1+delta),"0"]]
            rows=[
              (mut,"none",original,[-1+delta,0],[]),
              (direction,"direction",[[str(1+delta),"-1","0"]],[-1,0],
                [{"frame":0,"slot":1,"from":str(-1+delta),"to":"-1"}]),
              (full,"full",[["1","-1","0"]],[-1,0],
                [{"frame":0,"slot":1,"from":str(-1+delta),"to":"-1"},
                 {"frame":0,"slot":0,"from":str(1+delta),"to":"1"}])]
            for run,mode,xstack,vector,changes in rows:
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
                     and x.get("pre_actual")==original
                     and x.get("pre_executed")==xstack
                     and x.get("post_delta")==vector
                     and x.get("changes")==changes
                     and run.get("status") in ("normal","step-limit")
                     and type(run.get("steps")) is int
                     and run["steps"]>tick+99
                     and type(run.get("remaining_ips")) is int
                     and type(run.get("output")) is list,
                     "real Native u/x physical mediation source, operand or mode forged")
            b=succeeded(direction,ref);f=succeeded(full,ref)
            need(item.get("direction_only_recovers_reference") is b
                 and item.get("direction_only_terminated_normally") is
                     (direction["status"]=="normal" and direction["remaining_ips"]==0)
                 and item.get("both_channels_recovered") is True
                 and f and full["steps"]==steps,
                 "full BF98 reference/step recovery report forged")
            result["direction_only_rescues"]+=int(b)
            result["direction_only_normal"]+=int(direction["status"]=="normal"
                                                and direction["remaining_ips"]==0)
            result["two_channel_rescues"]+=int(f)
            result["unrescued_bounded_divergences"]+=1
    need(result["two_channel_rescues"]==12
         and result["unrescued_bounded_divergences"]==12,
         "expected 12 exact Native u/x causal rescues absent")
    return result

def main(folder):
    src=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(src)).encode()+b"\0"+src).hexdigest()==PIN,
         "Native BF98 underlying pinned code differs")
    root=Path(folder)
    d=json.loads((root/"expanded_u_x_native_evidence.json").read_text("utf-8"))
    measured=verify(d)
    tests=[
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("stage",lambda x:x.__setitem__("stage1_complete",True)),
      ("drop",lambda x:x["records"].pop()),
      ("swap",lambda x:x["records"].reverse()),
      ("baseline",lambda x:x["records"][0]["control"].__setitem__("output",["-1"]*7)),
      ("u_tick",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"]["u"].__setitem__("tick",1)),
      ("x_opcode",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"]["x"].__setitem__("opcode","y")),
      ("vector",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"]["x"].__setitem__("post_delta",[-2,0])),
      ("only_direction",lambda x:x["records"][0]["counterfactuals"][0]["direction_only"]["x"]["pre_executed"][0].__setitem__(0,"1")),
      ("full_stack",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"]["x"]["pre_executed"][0].__setitem__(0,"0")),
      ("wrong_steps",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"].__setitem__("steps",99)),
      ("bad_result",lambda x:x["records"][0]["counterfactuals"][0]["full_x_input"].__setitem__("output",["-1"]*7)),
      ("false_flag",lambda x:x["records"][0]["counterfactuals"][0].__setitem__("both_channels_recovered",False))]
    rejected=[]
    for name,modify in tests:
        forged=copy.deepcopy(d);modify(forged)
        try:verify(forged)
        except (AssertionError,KeyError,TypeError,IndexError):rejected.append(name)
        else:raise AssertionError("forged Native BF98 expanded mediation report accepted "+name)
    need(len(rejected)==13,"Native expanded anti-forgery matrix incomplete")
    result={"schema":"befunge-stage1-expanded-u-x-two-channel-independent-audit-v1",
            "native_programs":42,"native_legal_input_families":6,
            "scope":"SIX_ADDITIONAL_EXECUTED_U_X_CASES_NOT_UNIVERSAL",
            "measurements":measured,
            "falsified_reports_rejected":rejected,
            "last_completed_stage":0,"geometric_spaghetti_qa_pass":False}
    (root/"expanded_u_x_native_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_BF98_EXPANDED_U_X_MEDIATION_INDEPENDENT_AUDIT_PASS",
          json.dumps(measured,sort_keys=True))
    print("NATIVE_BF98_EXPANDED_U_X_13_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"expanded Native u/x evidence directory required")
    main(sys.argv[1])
