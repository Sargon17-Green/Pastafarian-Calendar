#!/usr/bin/env python3
"""Independent fail-closed Native BF98 u reverse-count evidence replay.

Verify actual u site, one stack-cell mutation, oracle and outcome claims.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",10117,17387),
       ("forward_short",10117,19713),
       ("recent_anchor_next",20197,43749))
def need(c,m):
    if not c:raise AssertionError(m)
def verify(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-native-u-reverse-count-v1"
         and doc.get("scope")=="THREE_VALID_NATIVE_INPUTS_U_FIRST_TOSS_SLOT_REDUCED"
         and doc.get("source_git_blob")==PIN
         and doc.get("native_executions")==9
         and doc.get("stage1_complete") is False
         and doc.get("last_completed_stage")==0
         and doc.get("geometric_spaghetti_qa_pass") is False
         and doc.get("production_modified") is False,
         "Native u reverse report source or scope forged")
    cases=doc.get("records")
    need(type(cases) is list and len(cases)==3,"3-case BF98 u-reverse matrix absent")
    totals={"terminated_changed":0,"numerical_output_changed":0,
            "normal_with_changed_output":0,"post128_route_changed":0,
            "immediate_stack_changed":0,"exact_dynamic_vector_divergences":0}
    for case,(name,tick,baseline_steps) in zip(cases,CASES):
        a=case.get("baseline");trials=case.get("trials")
        reference=case.get("reference_7")
        need(case.get("case")==name and type(a) is dict and
             a.get("status")=="normal" and a.get("ips")==0
             and a.get("steps")==baseline_steps and
             a.get("output")==reference
             and type(reference) is list and len(reference)==7
             and type(trials) is list and len(trials)==2,
             "Native BF98 control and independent numerical reference invalid")
        u=a.get("u_event")
        need(type(u) is dict and u.get("tick")==tick
             and u.get("position")==[954,1328] and u.get("opcode")=="u"
             and u.get("first_slot_before")==1
             and u.get("first_slot_executed")==1
             and u.get("delta")==0 and
             u.get("stacks_before")==[["1","0","0"],["3"]]
             and u.get("stacks_executed")==u.get("stacks_before")
             and type(a.get("first_128_post_u_route")) is list
             and len(a["first_128_post_u_route"])==128,
             "pinned physical Native u first TOSS control data drift")
        for trial,delta in zip(trials,(-1,-2)):
            b=trial.get("run")
            q=b.get("u_event") if type(b) is dict else None
            need(trial.get("delta")==delta and type(q) is dict
                 and q.get("tick")==tick and q.get("position")==[954,1328]
                 and q.get("opcode")=="u" and q.get("first_slot_before")==1
                 and q.get("first_slot_executed")==1+delta
                 and q.get("delta")==delta
                 and q.get("stacks_before")==u["stacks_before"]
                 and q.get("stacks_executed")==[[str(1+delta),"0","0"],["3"]]
                 and type(b.get("status")) is str
                 and b["status"] in ("normal","step-limit")
                 and type(b.get("ips")) is int
                 and type(b.get("steps")) is int and b["steps"]>=tick+128
                 and type(b.get("output")) is list
                 and type(b.get("first_128_post_u_route")) is list
                 and len(b["first_128_post_u_route"])==128,
                 "Native u runtime operand reduction not physically witnessed")
            final=b["status"]!="normal" or b["ips"]!=0 or b["output"]!=reference
            normal=b["status"]=="normal" and b["ips"]==0
            numeric=b["output"]!=reference
            stack=q["stacks_after"]!=u["stacks_after"]
            # The actual Native stack-stack u transfers the slot-0 value
            # into the subsequent arithmetic IP-vector construction.
            # Reconstruct the FIRST divergent physical motion, not just
            # the producer's boolean route-difference claim.
            control_motion=a["first_128_post_u_route"]
            mutated_motion=b["first_128_post_u_route"]
            divergence=next((index for index,(left,right) in enumerate(
                zip(control_motion,mutated_motion)) if left!=right),None)
            need(divergence==99
                 and control_motion[:99]==mutated_motion[:99]
                 and control_motion[98]==[950,1335,-77,1]
                 and control_motion[99]==[949,1335,-1,0]
                 and mutated_motion[98]==[950,1335,-77,1]
                 and mutated_motion[99]==[
                     949+delta,1335,-1+delta,0],
                 "Native u payload did not causally alter the exact "
                 "post-transfer dynamic IP-vector at event 99")
            motion=b["first_128_post_u_route"]!=a["first_128_post_u_route"]
            need(trial.get("final_output_or_termination_changed") is final
                 and trial.get("terminated_normally") is normal
                 and trial.get("numerical_output_changed") is numeric
                 and trial.get("immediate_stack_difference") is stack
                 and trial.get("post128_route_difference") is motion,
                 "Native u post-intervention semantic classification forged")
            totals["terminated_changed"]+=int(not normal)
            totals["numerical_output_changed"]+=int(numeric)
            totals["normal_with_changed_output"]+=int(normal and numeric)
            totals["post128_route_changed"]+=int(motion)
            totals["immediate_stack_changed"]+=int(stack)
            totals["exact_dynamic_vector_divergences"]+=int(divergence==99)
    return totals
def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "QA Native source checksum changed")
    root=Path(folder)
    doc=json.loads((root/"u_reverse_native_evidence.json").read_text("utf-8"))
    values=verify(doc)
    challenges=[
      ("identity",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("stage",lambda d:d.__setitem__("stage1_complete",True)),
      ("missing",lambda d:d["records"].pop()),
      ("case",lambda d:d["records"][0].__setitem__("case","forged")),
      ("oracle",lambda d:d["records"][0]["baseline"].__setitem__("output",["-1"]*7)),
      ("opcode",lambda d:d["records"][0]["trials"][0]["run"]["u_event"].__setitem__("opcode","v")),
      ("tick",lambda d:d["records"][0]["trials"][0]["run"]["u_event"].__setitem__("tick",1)),
      ("operand",lambda d:d["records"][0]["trials"][0]["run"]["u_event"].__setitem__("first_slot_executed",400)),
      ("stack",lambda d:d["records"][0]["trials"][0]["run"]["u_event"]["stacks_executed"][0].__setitem__(0,"111")),
      ("vector",lambda d:d["records"][0]["trials"][0]["run"]["first_128_post_u_route"][99].__setitem__(2,-77)),
      ("effect",lambda d:d["records"][0]["trials"][0].__setitem__("final_output_or_termination_changed",
            not d["records"][0]["trials"][0]["final_output_or_termination_changed"]))]
    denied=[]
    for name,mutate in challenges:
        d=copy.deepcopy(doc);mutate(d)
        try:verify(d)
        except (AssertionError,KeyError,TypeError,IndexError):denied.append(name)
        else:raise AssertionError("forged Native u reverse evidence accepted "+name)
    need(len(denied)==11,"incomplete Native u reverse adversarial checks")
    result={"schema":"befunge-stage1-native-u-reverse-independent-audit-v1",
            "real_native_programs":9,"measured":values,
            "forged_reports_rejected":denied,
            "last_completed_stage":0,"geometric_spaghetti_qa_pass":False}
    (root/"u_reverse_native_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_BF98_U_REVERSE_COUNT_INDEPENDENT_AUDIT_PASS",
          json.dumps(values,sort_keys=True))
    print("NATIVE_BF98_U_REVERSE_ELEVEN_FALSIFIED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native u reverse evidence directory required")
    main(sys.argv[1])
