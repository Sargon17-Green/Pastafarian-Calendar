#!/usr/bin/env python3
"""Fail-closed independent Native BF98 operator causal evidence auditor."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("zero_equal",(10110,10115,10117,10122)),
       ("forward_short",(10110,10115,10117,10122)),
       ("recent_anchor_next",(20190,20195,20197,20202)))
OP=(("w",(951,1332)),("{",(954,1330)),
    ("u",(954,1328)),("}",(954,1322)))
def need(x,m):
    if not x:raise AssertionError(m)
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="stage1-native-executed-opcode-causality-v1"
         and d.get("source_git_blob")==PIN
         and d.get("sampled_cases")==[c for c,_ in CASES]
         and d.get("real_native_programs")==24 and d.get("pairs")==12
         and d.get("production_modified") is False
         and d.get("last_completed_stage")==0
         and d.get("stage1_complete") is False
         and d.get("geometry_full_pass") is False,
         "Native source, QA scope, or Stage1 completion forged")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==12,"missing opcode causal cases")
    totals=dict((x,0) for x,_ in OP)
    for idx,r in enumerate(rows):
        case,ticks=CASES[idx//4];name,coord=OP[idx%4]
        a,b=r.get("control"),r.get("mutant")
        expected=r.get("reference")
        need(r.get("case")==case and r.get("opcode")==name
             and type(expected) is list and len(expected)==7
             and all(type(v) is str and v.lstrip("-").isdigit()
                     for v in expected)
             and type(a) is dict and type(b) is dict
             and a.get("status")=="normal" and a.get("ips")==0
             and a.get("output")==expected
             and b.get("status") in ("normal","step-limit")
             and type(b.get("steps")) is int and b["steps"]>=ticks[idx%4],
             "Native control, counterfactual or independent reference invalid")
        for run,executed,mut in ((a,name,False),(b,":",True)):
            site=run.get("site")
            need(type(site) is dict
                 and site.get("tick")==ticks[idx%4]
                 and site.get("coordinate")==list(coord)
                 and site.get("original")==name
                 and site.get("executed")==executed
                 and site.get("mutated") is mut
                 and type(site.get("toss_depth")) is int
                 and site["toss_depth"]>=0
                 and type(site.get("frames")) is int
                 and site["frames"]>=1,
                 "real Native physical site, time or operator corrupted")
        need(a["site"]["toss_depth"]==b["site"]["toss_depth"]
             and a["site"]["frames"]==b["site"]["frames"],
             "original BF98 pre-instruction stacks differ")
        changed=b["status"]!="normal" or b["ips"]!=0 or b["output"]!=expected
        need(r.get("effect") is changed,"counterfactual effect count forged")
        totals[name]+=int(changed)
    need(d.get("effects")==totals,"operator causal totals inconsistent")
    return totals
def main(directory):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "QA production BF98 source blob drift")
    root=Path(directory)
    d=json.loads((root/"opcode_causal.json").read_text("utf-8"))
    totals=verify(d)
    muts=[
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("complete",lambda x:x.__setitem__("stage1_complete",True)),
      ("drop",lambda x:x["records"].pop()),
      ("reverse",lambda x:x["records"].reverse()),
      ("oracle",lambda x:x["records"][0]["control"].__setitem__("output",["-1"]*7)),
      ("original",lambda x:x["records"][0].__setitem__("opcode","x")),
      ("step",lambda x:x["records"][0]["mutant"]["site"].__setitem__("tick",0)),
      ("position",lambda x:x["records"][0]["mutant"]["site"].__setitem__(
          "coordinate",[0,0])),
      ("mutated",lambda x:x["records"][0]["mutant"]["site"].__setitem__(
          "mutated",False)),
      ("stack",lambda x:x["records"][0]["mutant"]["site"].__setitem__(
          "toss_depth",999)),
      ("effect",lambda x:x["records"][0].__setitem__("effect",
          not x["records"][0]["effect"])),
      ("summary",lambda x:x["effects"].__setitem__("w",99))]
    rejected=[]
    for name,mut in muts:
        trial=copy.deepcopy(d);mut(trial)
        try:verify(trial)
        except (AssertionError,KeyError,TypeError):rejected.append(name)
        else:raise AssertionError("accepted forged Native BF98 opcode evidence: "+name)
    need(len(rejected)==12,"Native hostile opcode audit incomplete")
    report={"schema":"stage1-native-executed-opcode-audit-v1",
            "source_git_blob":PIN,"native_runs":24,
            "effects":totals,"hostile_reports_rejected":rejected,
            "stage1_complete":False,"geometry_full_pass":False}
    (root/"opcode_causal_audit.json").write_text(
        json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_EXECUTED_OPCODE_CAUSAL_INDEPENDENT_AUDIT_PASS",
          json.dumps(totals,sort_keys=True))
    print("NATIVE_OPCODE_TWELVE_FALSIFIED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"native opcode evidence directory required")
    main(sys.argv[1])
