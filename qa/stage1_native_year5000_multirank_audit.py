#!/usr/bin/env python3
"""Fail-closed independent reconstruction of the Stage-1 Native Year-5000
nine-gate ranked tie/boundary evidence. Only native Befunge computes outputs.
"""
import copy,json,sys
from pathlib import Path
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
SHIFTS=(0,1,123456789,-1,-84,-253,-((1<<127)+19),1<<128)
TIE=((0,6),(1,7),(2,8),(0,7),(1,8),(0,8))
OPEN=((0,6),(1,7),(0,7),(1,8),(0,8))
def need(c,msg):
    if not c:raise AssertionError(msg)
def signmag(n):return [int(n<0),abs(n)]
def raw(s,offset,rank):
    parts=signmag(s+offset)+[0,0,9]
    for i in range(9):parts+=signmag(s+42*i)
    return parts+[rank]
def output(s,indexes):
    i,j=indexes
    return [0,5000,i,j,s+42*i,s+42*j]
def expected():
    rows=[]
    for s in SHIFTS:
        for n,p in enumerate(TIE,1):
            rows.append(("rank_%s_%d"%(s,n),s,100,n,output(s,p)))
        for bad in (0,7):
            rows.append(("invalid_rank_%s_%d"%(s,bad),s,100,bad,[-1]))
    for s in (0,-253):
        for n,p in enumerate(OPEN,1):
            rows.append(("strict_open_%s_%d"%(s,n),s,84,n,output(s,p)))
        rows.append(("strict_open_%s_6"%s,s,84,6,[-1]))
    for s in (0,-253,1<<128):
        for off in (0,337):
            rows.append(("outside_%s_%d"%(s,off),s,off,1,[-1]))
    return rows
def verify(report):
    need(type(report) is dict and
         report.get("schema")=="befunge-stage1-native-year5000-multirank-v1" and
         report.get("source_git_blob")==BLOB and
         report.get("scope")=="NATIVE_RANK_TIES_SIGNED_AXIS_FINITE_STAGE1_OPEN" and
         report.get("functional_acceptance") is False and
         report.get("geometric_acceptance") is False and
         type(report.get("last_completed_stage")) is int and
         report.get("last_completed_stage")==0,
         "Stage1 source or acceptance declaration drift")
    rows=report.get("records")
    exp=expected()
    need(type(rows) is list and len(rows)==len(exp) and
         type(report.get("native_invocations")) is int and
         report["native_invocations"]==len(exp),
         "rank/tie/boundary case count mismatch")
    for row,(name,s,off,r,out) in zip(rows,exp):
        need(type(row) is dict and row.get("case")==name and
             type(row.get("shift")) is int and row["shift"]==s and
             type(row.get("offset")) is int and row["offset"]==off and
             type(row.get("rank")) is int and row["rank"]==r and
             row.get("input")==raw(s,off,r) and row.get("expected")==out and
             row.get("output")==out and type(row.get("return_code")) is int and
             row["return_code"]==0,"tampered Native rank witness "+name)
    return len(exp)
def main(path):
    folder=Path(path)
    x=json.loads((folder/"native_year5000_multirank.json").read_text(
        encoding="utf-8"))
    count=verify(x)
    attacks=[
        ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        ("status",lambda d:d.__setitem__("last_completed_stage",1)),
        ("functional",lambda d:d.__setitem__("functional_acceptance",True)),
        ("geometric",lambda d:d.__setitem__("geometric_acceptance",True)),
        ("count",lambda d:d.__setitem__("native_invocations",count-1)),
        ("deleted",lambda d:d["records"].pop()),
        ("reorder",lambda d:d["records"].reverse()),
        ("wrong rank",lambda d:d["records"][1].__setitem__("rank",6)),
        ("wrong index",lambda d:d["records"][1]["output"].__setitem__(2,4)),
        ("wrong shift",lambda d:d["records"][25].__setitem__("shift",0)),
        ("strict open",lambda d:d["records"][65]["output"].__setitem__(0,1)),
        ("bad sign",lambda d:d["records"][40]["input"].__setitem__(0,0)),
    ]
    rejected=[]
    for name,change in attacks:
        mutant=copy.deepcopy(x)
        change(mutant)
        try:verify(mutant)
        except AssertionError:rejected.append(name)
        else:raise AssertionError("Hostile Native result accepted: "+name)
    data={"schema":"befunge-stage1-native-year5000-multirank-audit-v1",
          "verified_native_records":count,
          "tamper_cases_rejected":rejected,
          "full_functional_acceptance":False,"last_completed_stage":0}
    (folder/"native_year5000_multirank_audit.json").write_text(
        json.dumps(data,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_MULTIRANK_INDEPENDENT_TAMPER_AUDIT_PASS",
          count,"NATIVE_RECORDS",len(rejected),"TAMPERS_REJECTED")
if __name__=="__main__":
    need(len(sys.argv)==2,"evidence path required")
    main(sys.argv[1])
