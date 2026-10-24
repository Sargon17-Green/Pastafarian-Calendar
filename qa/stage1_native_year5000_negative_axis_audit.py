#!/usr/bin/env python3
"""Independent structural and adversarial audit of Native Year-5000 output.
Independent of runner code; NOT a replacement for exact-SHA Native CI logs.
"""
import json,copy,sys
from pathlib import Path
SHIFTS=(-1,-21,-84,-252,-253,-1000,-123456789,
        -((1<<127)+19),-(10**100+123))
INNER=(1,100,252)
OUTER=(0,253)
RANKS=(0,2)
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
def need(x,msg):
    if not x:raise AssertionError(msg)
def pair(n):return [int(n<0),abs(n)]
def fields(s,o,r):
    result=pair(s+o)+[0,0,7]
    for i in range(7):result+=pair(s+42*i)
    return result+[r]
def cases():
    result=[]
    for o in INNER:result.append(("anchor_%d"%o,fields(0,o,1),
                                  [0,5000,0,6,0,252]))
    for s in SHIFTS:
        for o in INNER:
            result.append(("inside_%s_%d"%(s,o),fields(s,o,1),
                           [0,5000,0,6,s,s+252]))
        for o in OUTER:
            result.append(("outside_%s_%d"%(s,o),fields(s,o,1),[-1]))
        for r in RANKS:
            result.append(("bad_rank_%s_%d"%(s,r),fields(s,100,r),[-1]))
    return result
def verify(d):
    expected=cases()
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-native-year5000-negative-axis-v1" and
         d.get("source_git_blob")==BLOB and
         d.get("scope")=="NEGATIVE_SIGNED_AXIS_FINITE_NATIVE_CORPUS_STAGE1_OPEN" and
         d.get("shift_values")==list(SHIFTS) and
         d.get("functional_acceptance") is False and
         d.get("geometric_acceptance") is False and
         type(d.get("last_completed_stage")) is int and
         d["last_completed_stage"]==0,"source/acceptance drift")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==len(expected) and
         type(d.get("native_invocations")) is int and
         d["native_invocations"]==len(expected),"missing Native evidence")
    for row,(name,inp,out) in zip(rows,expected):
        need(type(row) is dict and row.get("case")==name and
             row.get("input")==inp and row.get("expected")==out and
             row.get("output")==out and
             type(row.get("return_code")) is int and
             row.get("return_code")==0,"bad Native report: "+name)
    return len(expected)
def main(root):
    folder=Path(root)
    d=json.loads((folder/"native_year5000_negative_axis.json").read_text(
        encoding="utf-8"))
    count=verify(d)
    attacks=[
        lambda x:x.__setitem__("source_git_blob","0"*40),
        lambda x:x.__setitem__("functional_acceptance",True),
        lambda x:x.__setitem__("geometric_acceptance",True),
        lambda x:x.__setitem__("last_completed_stage",1),
        lambda x:x.__setitem__("native_invocations",count-1),
        lambda x:x["records"].pop(),
        lambda x:x["records"].reverse(),
        lambda x:x["records"][3]["input"].__setitem__(5,0),
        lambda x:x["records"][3]["expected"].__setitem__(4,0),
        lambda x:x["records"][3]["output"].__setitem__(4,0),
    ]
    rejected=0
    for attack in attacks:
        mutant=copy.deepcopy(d)
        attack(mutant)
        try:verify(mutant)
        except AssertionError:rejected+=1
        else:raise AssertionError("mutated Native evidence accepted")
    report={"schema":"befunge-stage1-native-year5000-signed-axis-audit-v1",
            "verified_native_records":count,"hostile_reports_rejected":rejected,
            "full_functional_acceptance":False,"last_completed_stage":0}
    (folder/"native_year5000_negative_axis_audit.json").write_text(
        json.dumps(report,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_NEGATIVE_AXIS_INDEPENDENT_AUDIT_PASS",
          count,"NATIVE_RECORDS",rejected,"TAMPER_REPORTS_REJECTED")
if __name__=="__main__":
    need(len(sys.argv)==2,"expected evidence directory argument")
    main(sys.argv[1])
