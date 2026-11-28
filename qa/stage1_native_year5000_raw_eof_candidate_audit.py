#!/usr/bin/env python3
"""Fail-closed independent replay of no-LF Native candidate report."""
import copy,json,sys
from pathlib import Path
from stage1_native_year5000_24token_grammar_audit import make
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def verify(x):
    need(type(x) is dict and
         x.get("schema")=="befunge-stage1-no-lf-native-candidate-v1" and
         x.get("scope")=="TEST_ONLY_RAW_EOF_TWO_ROW_CANDIDATE_NOT_FULL_ACCEPTANCE" and
         x.get("stage1_accepted") is False and
         x.get("production_modified") is False and
         type(x.get("last_completed_stage")) is int and x["last_completed_stage"]==0,
         "Stage1 acceptance or source scope tampered")
    corpus=make();r=x.get("records")
    need(len(corpus)==163 and type(r) is list and len(r)==326 and
         type(x.get("native_case_count")) is int and x["native_case_count"]==326,
         "native corpus count failure")
    for n,(label,raw,want) in enumerate(corpus):
        if label=="multi_line_post_lf_not_checked":want=-1
        for j,end in enumerate(("raw","append_lf")):
            row=r[2*n+j]
            given=raw if end=="raw" else raw+"\n"
            need(type(row) is dict and type(row.get("index")) is int and
                 row["index"]==n and row.get("case")==label and
                 row.get("ending")==end and row.get("raw")==given and
                 row.get("expected")==[want] and row.get("native_output")==[want] and
                 type(row.get("native_exit")) is int and row["native_exit"]==0,
                 "Native no-LF proof manipulated %d %s"%(n,end))
    return 326
def main(folder):
    root=Path(folder)
    x=json.loads((root/"year5000_raw_eof_candidate.json").read_text("utf-8"))
    n=verify(x)
    attacks=[
      ("stage",lambda z:z.__setitem__("last_completed_stage",1)),
      ("scope",lambda z:z.__setitem__("scope","PRODUCTION_ACCEPTED")),
      ("production",lambda z:z.__setitem__("production_modified",True)),
      ("false_acceptance",lambda z:z.__setitem__("stage1_accepted",True)),
      ("count",lambda z:z.__setitem__("native_case_count",325)),
      ("missing",lambda z:z["records"].pop()),
      ("reverse",lambda z:z["records"].reverse()),
      ("raw_launder",lambda z:z["records"][0].__setitem__("raw","0")),
      ("flip_valid_noLF",lambda z:z["records"][0].__setitem__("native_output",[-1])),
      ("flip_valid_LF",lambda z:z["records"][1].__setitem__("native_output",[-1])),
      ("false_trailer_accept",lambda z:z["records"][35].__setitem__("native_output",[1])),
      ("wrong_exit",lambda z:z["records"][0].__setitem__("native_exit",1)),
      ("wrong_index",lambda z:z["records"][2].__setitem__("index",999)),
      ("wrong_variant",lambda z:z["records"][2].__setitem__("ending","append_lf")),
    ]
    denied=[]
    for label,mutate in attacks:
        d=copy.deepcopy(x);mutate(d)
        try:verify(d)
        except AssertionError:denied.append(label)
        else:raise AssertionError("accepted forged no-LF witness "+label)
    out={"schema":"befunge-stage1-no-lf-candidate-audit-v1",
         "native_cases_checked":n,"hostile_reports_rejected":denied,
         "last_completed_stage":0,"final_acceptance":False}
    (root/"year5000_raw_eof_candidate_audit.json").write_text(
        json.dumps(out,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_NO_LF_326_AND_14_HOSTILE_AUDIT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"evidence dir needed")
    main(sys.argv[1])
