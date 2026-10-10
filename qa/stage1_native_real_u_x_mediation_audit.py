#!/usr/bin/env python3
"""Independently audit actual native BF98 u->x mediator rescue, fail-closed."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",10117,17387),
       ("forward_short",10117,19713),
       ("recent_anchor_next",20197,43749))
def need(x,msg):
    if not x:raise AssertionError(msg)
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-real-u-to-x-native-mediation-v1"
         and d.get("scope")=="THREE_VALID_NATIVE_INPUTS_X_OPERAND_RESCUE_UNMODIFIED_BF98"
         and d.get("source_git_blob")==PIN
         and d.get("native_executions")==15
         and d.get("independent_native_references")==3
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("geometric_spaghetti_qa_pass") is False
         and d.get("production_modified") is False,
         "Native BF98 source, QA scope or final acceptance forged")
    records=d.get("records")
    need(type(records) is list and len(records)==3,
         "Native 3-case mediator evidence incomplete")
    count=0
    for row,(label,tick,steps) in zip(records,CASES):
        ref=row.get("reference_7")
        ctrl=row.get("control")
        pairs=row.get("pairs")
        need(row.get("case")==label and type(ref) is list and
             len(ref)==7 and type(ctrl) is dict and
             ctrl.get("status")=="normal" and ctrl.get("steps")==steps
             and ctrl.get("remaining_ips")==0 and ctrl.get("output")==ref
             and type(pairs) is list and len(pairs)==2,
             "Native original program or independent reference invalid")
        xu=ctrl.get("u");xx=ctrl.get("x")
        need(type(xu) is dict and xu.get("tick")==tick
             and xu.get("before")==[["1","0","0"],["3"]]
             and xu.get("delta")==0 and xu.get("executed")==xu["before"]
             and type(xx) is dict and xx.get("tick")==tick+99
             and xx.get("position")==[950,1335] and xx.get("opcode")=="x"
             and xx.get("post_delta")==[-1,0]
             and xx.get("restoration") is None,
             "Original BF98 native u->x evidence unpinned")
        for pair,delta in zip(pairs,(-1,-2)):
            m=pair.get("mutant");r=pair.get("rescue")
            need(pair.get("u_delta")==delta and
                 type(m) is dict and type(r) is dict and
                 pair.get("restored_same_reference_7") is True and
                 pair.get("rescue_only_one_x_operand") is True,
                 "Native u/x counterfactual pair missing or false")
            need(m.get("status")=="step-limit" and
                 m.get("steps")==170001 and
                 r.get("status")=="normal" and
                 r.get("remaining_ips")==0 and
                 r.get("output")==ref and
                 type(m.get("x")) is dict and type(r.get("x")) is dict,
                 "real Native BF98 mediation was not rescued")
            for item in (m,r):
                need(item["u"].get("tick")==tick
                     and item["u"].get("before")==xu["before"]
                     and item["u"].get("delta")==delta
                     and item["u"].get("executed")==[[str(1+delta),"0","0"],["3"]]
                     and item["x"].get("tick")==tick+99
                     and item["x"].get("position")==[950,1335]
                     and item["x"].get("opcode")=="x",
                     "Native u or x executed physical event was forged")
            need(m["x"].get("post_delta")==[-1+delta,0]
                 and m["x"].get("restoration") is None
                 and r["x"].get("post_delta")==[-1,0],
                 "actual physical x vector output or rescue changed")
            before=m["x"].get("pre_actual");orig=xx.get("pre_actual")
            repaired=r["x"].get("pre_executed")
            need(before==r["x"].get("pre_actual")
                 and repaired==orig
                 and type(before) is list and type(orig) is list
                 and len(before)==len(orig),
                 "x operand rescue did not restore identical BF98 input stack")
            diffs=[(j,k,va,vb) for j,(a,b) in
                   enumerate(zip(before,orig)) for k,(va,vb) in
                   enumerate(zip(a,b)) if va!=vb]
            need(len(diffs)==1,"u perturbation caused multiple x stack differences")
            j,k,va,vb=diffs[0]
            expected={"stack_index":j,"slot_index":k,
                      "mutant_value":va,"control_value":vb}
            need(r["x"].get("restoration")==expected
                 and j==len(before)-1 and k>=len(before[-1])-2,
                 "the restored x argument was not exactly the mediated one")
            count+=1
    return count
def main(rootdir):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "QA BF98 source blob changed")
    root=Path(rootdir)
    report=json.loads((root/"native_real_u_x_mediation.json").read_text("utf-8"))
    count=verify(report)
    cases=[
      ("completion",lambda d:d.__setitem__("stage1_complete",True)),
      ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("drop",lambda d:d["records"].pop()),
      ("label",lambda d:d["records"][0].__setitem__("case","FORGED")),
      ("baseline",lambda d:d["records"][0]["control"].__setitem__("output",["-1"]*7)),
      ("u-value",lambda d:d["records"][0]["pairs"][0]["rescue"]["u"].__setitem__("delta",0)),
      ("x-tick",lambda d:d["records"][0]["pairs"][0]["rescue"]["x"].__setitem__("tick",1)),
      ("mutated-x",lambda d:d["records"][0]["pairs"][0]["mutant"]["x"].__setitem__("post_delta",[-1,0])),
      ("rescued-x",lambda d:d["records"][0]["pairs"][0]["rescue"]["x"].__setitem__("post_delta",[-2,0])),
      ("fake-rescue",lambda d:d["records"][0]["pairs"][0]["rescue"].__setitem__("output",["-1"]*7)),
      ("multi-cell",lambda d:d["records"][0]["pairs"][0]["rescue"]["x"]["pre_executed"][-1].append("999")),
      ("no-exact",lambda d:d["records"][0]["pairs"][0]["rescue"]["x"].__setitem__("restoration",None))]
    refused=[]
    for name,change in cases:
        forged=copy.deepcopy(report);change(forged)
        try:verify(forged)
        except (AssertionError,KeyError,IndexError,TypeError):refused.append(name)
        else:raise AssertionError("forged Native u/x mediator report passed "+name)
    need(len(refused)==12,"u-x mediation adversarial corpus incomplete")
    summary={"schema":"befunge-stage1-real-u-x-independent-causal-audit-v1",
             "rescue_pairs":count,"native_programs":15,
             "adversarial_evidence_rejected":refused,
             "stage1_complete":False,"geometric_spaghetti_qa_pass":False}
    (root/"native_real_u_x_mediation_audit.json").write_text(
        json.dumps(summary,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_REAL_BF98_U_X_MEDIATION_INDEPENDENT_AUDIT_PASS",count)
    print("NATIVE_U_X_TWELVE_FORGED_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native BF98 u->x mediator artifact dir required")
    main(sys.argv[1])
