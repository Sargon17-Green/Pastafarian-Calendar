#!/usr/bin/env python3
"""Independent, fail-closed review of actual BF98 '~' lexeme input evidence."""
import copy,json,sys
from pathlib import Path
BLOB="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
def demand(cond,why):
    if not cond:raise AssertionError(why)
def vector(osign="0",omag="0",rank="1"):
    t=["0","100",osign,omag,"9"]
    for i in range(9):t+=["0",str(i*42)]
    return t+[rank]
def witnesses():
    base=vector()
    results=[
      ("base"," ".join(base),1,[0,5000,0,6,0,252]),
      ("spacing","  "+"  \t".join(base)+"   ",1,[0,5000,0,6,0,252]),
      ("negative_origin"," ".join(vector("1","7")),1,
       [0,5000,-7,-1,0,252]),
      ("rank3"," ".join(vector(rank="3")),1,
       [0,5000,2,8,84,336])
    ]
    for i,t in enumerate(base):
        x=list(base);x[i]="-"+t
        results.append(("negative_slot_%02d"%i," ".join(x),-1,None))
    for i in (0,2,4,5,14,23):
        x=list(base);x[i]="+"+x[i]
        results.append(("plus_slot_%02d"%i," ".join(x),-1,None))
    for name,i,value in (
        ("word",4,"five"),("decimal",1,"10.0"),("comma",3,"1,0"),
        ("hex",7,"0x2"),("double_negative",2,"--1"),
        ("minus_magnitude",3,"-3"),("plus_magnitude",3,"+3"),
        ("slash",23,"1/"),("carriage_return",0,"0\r"),
    ):
        x=list(base);x[i]=value
        results.append(("invalid_"+name," ".join(x),-1,None))
    x=list(base);x[2]="-1";x[3]="3"
    results.append(("negative_sign_bypass"," ".join(x),-1,None))
    return results
def check(d):
    demand(type(d) is dict and
           d.get("schema")=="befunge-stage1-native-year5000-raw-lexeme-preflight-v1" and
           d.get("reference_git_blob")==BLOB and
           d.get("scope")=="CHARACTER_CLASS_ONLY_NOT_FULL_GRAMMAR_STAGE1_OPEN" and
           d.get("functional_acceptance") is False and
           d.get("geometric_acceptance") is False and
           type(d.get("last_completed_stage")) is int and d["last_completed_stage"]==0,
           "false lexical source or acceptance claim")
    spec=witnesses();actual=d.get("records")
    demand(len(spec)==44 and type(actual) is list and len(actual)==len(spec) and
           type(d.get("native_preflight_records")) is int and
           d["native_preflight_records"]==len(spec),"Native lexical records missing")
    for item,(name,raw,guard,reference) in zip(actual,spec):
        demand(type(item) is dict and item.get("case")==name and
               item.get("raw")==raw and item.get("guard_output")==[guard] and
               item.get("reference_output")==reference and
               type(item.get("expected_guard")) is int and
               item["expected_guard"]==guard and
               item.get("expected_reference")==reference and
               type(item.get("exit_code")) is int and item["exit_code"]==0,
               "Native lexical witness forged "+name)
    bypass=d.get("unguarded_reference_bypass")
    name,raw,guard,_=spec[-1]
    demand(type(bypass) is dict and bypass.get("case")==name and
           bypass.get("raw")==raw and
           bypass.get("guarded_native_output")==[-1] and
           bypass.get("unguarded_native_output")==[0,5000,-3,3,0,252],
           "independent native reference bypass witness missing")
    return len(spec)
def main(root):
    folder=Path(root)
    doc=json.loads((folder/"native_year5000_raw_lexeme.json").read_text("utf-8"))
    n=check(doc)
    trials=(
        ("false_stage",lambda x:x.__setitem__("last_completed_stage",1)),
        ("false_scope",lambda x:x.__setitem__("scope","FULL_GRAMMAR_PASS")),
        ("wrong_reference",lambda x:x.__setitem__("reference_git_blob","0"*40)),
        ("false_functional",lambda x:x.__setitem__("functional_acceptance",True)),
        ("lost_record",lambda x:x["records"].pop()),
        ("reorder",lambda x:x["records"].reverse()),
        ("wrong_count",lambda x:x.__setitem__("native_preflight_records",n-1)),
        ("accept_malicious",lambda x:x["records"][-1].__setitem__("guard_output",[1])),
        ("raw_launder",lambda x:x["records"][-1].__setitem__("raw","0 100 1 3")),
        ("reference_forgery",lambda x:x["records"][0].__setitem__("reference_output",[-1])),
        ("fake_exit",lambda x:x["records"][0].__setitem__("exit_code",1)),
        ("bypass_hidden",lambda x:x["unguarded_reference_bypass"].__setitem__(
            "unguarded_native_output",[-1]))
    )
    rejected=[]
    for label,edit in trials:
        m=copy.deepcopy(doc);edit(m)
        try:check(m)
        except AssertionError:rejected.append(label)
        else:raise AssertionError("forged Native lexical report passed "+label)
    result={"schema":"befunge-stage1-year5000-native-lexeme-audit-v1",
            "records_verified":n,"tamper_reports_rejected":rejected,
            "full_parser_certified":False,"last_completed_stage":0}
    (folder/"native_year5000_raw_lexeme_audit.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_RAW_LEXEME_44_12_TAMPER_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    demand(len(sys.argv)==2,"native lexical evidence folder argument required")
    main(sys.argv[1])
