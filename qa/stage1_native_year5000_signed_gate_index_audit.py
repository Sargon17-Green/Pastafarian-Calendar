#!/usr/bin/env python3
"""Independent fail-closed Stage 1 audit: Year-5000 signed gate-index origins."""
import copy,json,sys
from pathlib import Path
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
ORIGINS=(0,-1,-7,-8,1,7,-((1<<129)+13),1<<129)
SHIFTS=(0,-((1<<130)+57))
NINE=((1,(0,6)),(3,(2,8)),(6,(0,8)),(0,None),(7,None))
BAD=((1,0),(2,0),(2,1),(3,3))
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def sm(x):return [int(x<0),abs(x)]
def fields(index,shift,count,rank,invalid=None):
    v=sm(shift+100)+(list(invalid) if invalid is not None else sm(index))
    v.append(count)
    for i in range(count):v+=sm(shift+42*i)
    return v+[rank]
def expected_rows():
    rows=[]
    for shift in SHIFTS:
        for index in ORIGINS:
            for rank,chosen in NINE:
                out=([0,5000,index+chosen[0],index+chosen[1],
                      shift+42*chosen[0],shift+42*chosen[1]]
                     if chosen is not None else [-1])
                rows.append(("nine_%s_%s_rank%d"%(index,shift,rank),
                             index,shift,9,rank,None,fields(index,shift,9,rank),out))
            rows.append(("seven_%s_%s_rank1"%(index,shift),index,shift,7,1,
                         None,fields(index,shift,7,1),
                         [0,5000,index,index+6,shift,shift+252]))
        for pair in BAD:
            rows.append(("invalid_index_sign_%s_%s_%s"%(shift,pair[0],pair[1]),
                         0,shift,7,1,list(pair),fields(0,shift,7,1,pair),[-1]))
    return rows
def verify(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-year5000-signed-gate-index-v1" and
         doc.get("source_git_blob")==BLOB and
         doc.get("scope")=="SIGNED_GATE_INDEX_ORIGIN_NOT_JDN_STAGE1_OPEN" and
         doc.get("functional_acceptance") is False and
         doc.get("geometric_acceptance") is False and
         type(doc.get("last_completed_stage")) is int and
         doc["last_completed_stage"]==0,
         "Stage 1 source or acceptance tamper")
    table=expected_rows()
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==104 and len(table)==104 and
         type(doc.get("native_calls")) is int and doc["native_calls"]==104,
         "Native index evidence count mismatch")
    for record,params in zip(rows,table):
        label,index,shift,count,rank,bad,transport,answer=params
        need(type(record) is dict and
             record.get("case")==label and
             type(record.get("origin")) is int and record["origin"]==index and
             type(record.get("shift")) is int and record["shift"]==shift and
             type(record.get("gate_count")) is int and record["gate_count"]==count and
             type(record.get("rank")) is int and record["rank"]==rank and
             record.get("invalid_pair")==bad and record.get("input")==transport and
             record.get("expected")==answer and record.get("output")==answer and
             type(record.get("return_code")) is int and
             record["return_code"]==0,
             "Native signed gate-index proof manipulated "+label)
    return len(table)
def main(p):
    root=Path(p)
    x=json.loads((root/"native_year5000_signed_gate_index.json").read_text(
        encoding="utf-8"))
    n=verify(x)
    attacks=(
        ("source",lambda z:z.__setitem__("source_git_blob","0"*40)),
        ("stage",lambda z:z.__setitem__("last_completed_stage",1)),
        ("functional",lambda z:z.__setitem__("functional_acceptance",True)),
        ("geometry",lambda z:z.__setitem__("geometric_acceptance",True)),
        ("total",lambda z:z.__setitem__("native_calls",103)),
        ("missing",lambda z:z["records"].pop()),
        ("reorder",lambda z:z["records"].reverse()),
        ("wrong_gate_index",lambda z:z["records"][8]["output"].__setitem__(2,100)),
        ("negative_gate_sign",lambda z:z["records"][7]["input"].__setitem__(2,0)),
        ("invalid_sign",lambda z:z["records"][-1]["invalid_pair"].__setitem__(0,0)),
        ("wrong_rank",lambda z:z["records"][3].__setitem__("rank",1)),
        ("wrong_day",lambda z:z["records"][0]["output"].__setitem__(4,42)),
        ("bad_return",lambda z:z["records"][0].__setitem__("return_code",1)),
    )
    rejected=[]
    for name,edit in attacks:
        trial=copy.deepcopy(x);edit(trial)
        try:verify(trial)
        except AssertionError:rejected.append(name)
        else:raise AssertionError("accepted forged index evidence: "+name)
    result={"schema":"befunge-stage1-year5000-signed-index-audit-v1",
            "verified_native_records":n,"hostile_cases_rejected":rejected,
            "last_completed_stage":0,"full_functional_acceptance":False}
    (root/"native_year5000_signed_gate_index_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_SIGNED_GATE_INDEX_104_AND_13_HOSTILE_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"argument: Native evidence directory")
    main(sys.argv[1])
