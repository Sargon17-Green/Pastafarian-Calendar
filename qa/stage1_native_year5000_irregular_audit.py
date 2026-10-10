#!/usr/bin/env python3
"""Fail-closed independent reconstruction of irregular nine-gate Native proof.
No import from the runner; expected rank orders are fixed explicit witnesses.
"""
import copy,json,sys
from pathlib import Path
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
L=(1<<130)+57
SHIFTS=(0,-L,L)
TABLE=(
 ("cross",(0,60,130,210,280,340,550,605,690),150,
  ((1,7),(0,6),(2,8),(0,7),(1,8),(0,8)),
  ((1,7),(0,6),(0,7),(1,8),(0,8)),
  ((1,7),(2,8),(0,7),(1,8),(0,8))),
 ("floor",(0,42,84,126,168,210,252,302,362),100,
  ((0,6),(1,7),(2,8),(0,7),(1,8),(0,8)),
  ((0,6),(1,7),(0,7),(1,8),(0,8)),
  ((1,7),(2,8),(0,7),(1,8),(0,8))),
 ("ceiling",(0,963,1926,2889,3852,4815,5778,5848,5948),2300,
  ((2,8),(1,7),(1,8),(0,6)),
  ((1,7),(1,8),(0,6)),
  ((2,8),(1,7),(1,8))),
)
def need(x,m):
    if not x:raise AssertionError(m)
def pair(v):return [int(v<0),abs(v)]
def transport(g,s,day,rank):
    v=pair(s+day)+[0,0,9]
    for gate in g:v+=pair(s+gate)
    return v+[rank]
def cases():
    result=[]
    for family,g,interior,allr,opened,after in TABLE:
        for s in SHIFTS:
            for mode,day,ranks in (
                ("interior",interior,allr),
                ("strict_open",g[2],opened),
                ("after_close",g[6]+1,after),
                ("closed_end",g[6],allr)):
                for rank,(i,j) in enumerate(ranks,1):
                    name="%s_%s_%s_%d"%(family,s,mode,rank)
                    result.append((name,family,s,mode,day,rank,
                                   transport(g,s,day,rank),
                                   [0,5000,i,j,s+g[i],s+g[j]]))
                n=len(ranks)+1
                result.append(("%s_%s_%s_overflow"%(family,s,mode),
                               family,s,mode,day,n,transport(g,s,day,n),[-1]))
                if mode=="interior":
                    result.append(("%s_%s_zero_rank"%(family,s),
                                   family,s,mode,day,0,transport(g,s,day,0),[-1]))
    return result
def verify(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-year5000-irregular-native-v1" and
         doc.get("source_git_blob")==BLOB and
         doc.get("scope")=="IRREGULAR_GATES_AND_EXACT_5778_LIMIT_STAGE1_OPEN" and
         doc.get("functional_acceptance") is False and
         doc.get("geometric_acceptance") is False and
         type(doc.get("last_completed_stage")) is int and
         doc["last_completed_stage"]==0,"Native source or Stage status drift")
    ref=cases()
    rows=doc.get("records")
    need(len(ref)==219 and type(rows) is list and len(rows)==219 and
         type(doc.get("native_invocations")) is int and
         doc["native_invocations"]==219,"missing Native evidence")
    for row,t in zip(rows,ref):
        name,family,s,mode,day,rank,inp,expected=t
        need(type(row) is dict and row.get("case")==name and
             row.get("family")==family and
             type(row.get("shift")) is int and row["shift"]==s and
             row.get("mode")==mode and
             type(row.get("day_offset")) is int and row["day_offset"]==day and
             type(row.get("rank")) is int and row["rank"]==rank and
             row.get("input_fields")==inp and row.get("expected")==expected and
             row.get("output")==expected and
             type(row.get("return_code")) is int and row["return_code"]==0,
             "tampered Native case: "+name)
    return len(ref)
def main(path):
    folder=Path(path)
    doc=json.loads((folder/"native_year5000_irregular.json").read_text(
        encoding="utf-8"))
    verified=verify(doc)
    attacks=(
        ("wrong_source",lambda d:d.__setitem__("source_git_blob","0"*40)),
        ("wrong_stage",lambda d:d.__setitem__("last_completed_stage",1)),
        ("false_functional",lambda d:d.__setitem__("functional_acceptance",True)),
        ("false_geometry",lambda d:d.__setitem__("geometric_acceptance",True)),
        ("count",lambda d:d.__setitem__("native_invocations",218)),
        ("missing",lambda d:d["records"].pop()),
        ("reorder",lambda d:d["records"].reverse()),
        ("wrong_rank",lambda d:d["records"][1].__setitem__("rank",8)),
        ("wrong_index",lambda d:d["records"][0]["output"].__setitem__(2,0)),
        ("wrong_expected",lambda d:d["records"][0]["expected"].__setitem__(3,6)),
        ("wrong_sign",lambda d:d["records"][27]["input_fields"].__setitem__(0,0)),
        ("false_success",lambda d:d["records"][2].__setitem__("return_code",1)),
        ("overflow_forgery",lambda d:d["records"][-1]["output"].__setitem__(0,1)),
    )
    rejected=[]
    for name,edit in attacks:
        trial=copy.deepcopy(doc)
        edit(trial)
        try:verify(trial)
        except AssertionError:rejected.append(name)
        else:raise AssertionError("forged Native evidence accepted: "+name)
    result={"schema":"befunge-stage1-year5000-irregular-audit-v1",
            "verified_native_records":verified,"hostile_reports_rejected":rejected,
            "full_functional_acceptance":False,"last_completed_stage":0}
    (folder/"native_year5000_irregular_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_IRREGULAR_219_AND_13_HOSTILE_AUDIT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native artifact directory required")
    main(sys.argv[1])
