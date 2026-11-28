#!/usr/bin/env python3
"""Independent fail-closed reconstruction of EOF-sensitive Native BF98 inputs."""
import copy,json,sys
from pathlib import Path
def check(p,msg):
    if not p:raise AssertionError(msg)
def base():
    tokens=["0","100","0","0","9"]
    for gate in range(9):tokens+=["0",str(gate*42)]
    return tokens
def cases():
    b=base()
    s=" ".join(b+["1"])
    def changed(idx,val,rank="1"):
        t=b+[rank];t[idx]=val;return " ".join(t)
    return [
       ("ordinary_no_lf",s,1,1),
       ("ordinary_with_lf",s+"\n",1,1),
       ("spaces_before_lf","  "+s+"   \n",1,1),
       ("no_lf_trailing_spaces",s+"   ",1,1),
       ("negative_index_no_lf",changed(2,"1").replace("1 0 9","1 7 9",1),1,1),
       ("negative_index_lf",changed(2,"1").replace("1 0 9","1 7 9",1)+"\n",1,1),
       ("rank3_lf",changed(23,"3")+"\n",1,1),
       ("tabs_lf","\t".join(b+["1"])+"\n",1,1),
       ("big_magnitude_no_lf",changed(1,"9"*72),1,1),
       ("new_line_followed_by_ascii",s+"\nEXTRA",-1,1),
       ("new_line_followed_by_digit",s+"\n1",-1,1),
       ("new_line_followed_by_space",s+"\n ",-1,1),
       ("new_line_followed_by_tab",s+"\n\t",-1,1),
       ("new_line_followed_by_second_lf",s+"\n\n",-1,1),
       ("new_line_followed_by_cr",s+"\n\r",-1,1),
       ("new_line_followed_by_minus",s+"\n-",-1,1),
       ("new_line_followed_by_plus",s+"\n+",-1,1),
       ("new_line_followed_by_second_line",s+"\n"+s,-1,1),
       ("new_line_followed_by_whitespace_line",s+"\n \t \n",-1,1),
       ("new_line_followed_by_colon",s+"\n:",-1,1),
       ("new_line_followed_by_slash",s+"\n/",-1,1),
       ("new_line_followed_by_formfeed",s+"\n\f",-1,1),
       ("missing_early_lf"," ".join((b+["1"])[:12])+"\n"+" ".join((b+["1"])[12:]),-1,-1),
       ("one_extra_same_line",s+" 1",-1,-1),
       ("missing_last_field"," ".join(b),-1,-1),
       ("bad_sign_no_lf",changed(2,"2"),-1,-1),
       ("negative_raw_no_lf",changed(0,"-0"),-1,-1),
       ("positive_raw_no_lf",changed(3,"+0"),-1,-1),
       ("negative_zero",changed(2,"1").replace("1 0 9","1 0 9",1),-1,-1),
       ("gate_count_eight",changed(4,"8"),-1,-1),
       ("gate_count_09",changed(4,"09"),-1,-1),
       ("nondigit_inside",changed(11,"garbage"),-1,-1),
       ("empty","",-1,-1),("single_lf","\n",-1,-1),
       ("spaces_only","  \t  ",-1,-1),
       ("carriage_in_firstline","\r"+s,-1,-1),
       ("carriage_before_lf",s+"\r\n",-1,-1),
    ]
def verify(doc):
    check(type(doc) is dict and
          doc.get("schema")=="befunge-stage1-eof-reflection-grammar-composition-v1" and
          doc.get("scope")=="TEST_ONLY_TWO_NATIVE_GUARDS_NOT_INTEGRATED_PRODUCTION" and
          doc.get("stage1_complete") is False and
          doc.get("full_functional_acceptance") is False and
          doc.get("geometric_acceptance") is False and
          type(doc.get("last_completed_stage")) is int and
          doc["last_completed_stage"]==0 and
          doc.get("eof_reflection_uses_native_torus") is True,
          "Source or stage acceptance metadata invalid")
    expected=cases();rows=doc.get("records")
    check(len(expected)==37 and type(rows) is list and len(rows)==37 and
          type(doc.get("native_cases")) is int and doc["native_cases"]==37,
          "Native EOF evidence cardinality mismatch")
    for case,ref in zip(rows,expected):
        name,raw,composed,line=ref
        end=(-1 if "\n" in raw and raw.index("\n")<len(raw)-1 else 1)
        check(type(case) is dict and case.get("case")==name and
              case.get("raw")==raw and case.get("native_eof")==end and
              case.get("native_line_grammar")==line and
              case.get("composed")==composed and case.get("expected")==composed and
              type(case.get("return_code")) is int and case["return_code"]==0,
              "Native EOF witness forged: "+name)
    return len(expected)
def main(directory):
    folder=Path(directory)
    doc=json.loads((folder/"native_eof_full_stream.json").read_text(encoding="utf-8"))
    n=verify(doc)
    mutants=[
      ("stage",lambda x:x.__setitem__("last_completed_stage",1)),
      ("full_acceptance",lambda x:x.__setitem__("full_functional_acceptance",True)),
      ("geometry",lambda x:x.__setitem__("geometric_acceptance",True)),
      ("scope",lambda x:x.__setitem__("scope","FULL_PRODUCTION_PARSER_CERTIFIED")),
      ("wrong_total",lambda x:x.__setitem__("native_cases",n-1)),
      ("lost_case",lambda x:x["records"].pop()),
      ("reorder",lambda x:x["records"].reverse()),
      ("hidden_trailer",lambda x:x["records"][9].__setitem__("native_eof",1)),
      ("accepted_trailer",lambda x:x["records"][10].__setitem__("composed",1)),
      ("invalid_firstline",lambda x:x["records"][25].__setitem__("native_line_grammar",1)),
      ("input_forgery",lambda x:x["records"][0].__setitem__("raw","0")),
      ("failed_native",lambda x:x["records"][0].__setitem__("return_code",1)),
      ("eof_fake",lambda x:x.__setitem__("eof_reflection_uses_native_torus",False)),
    ]
    denied=[]
    for name,change in mutants:
        d=copy.deepcopy(doc);change(d)
        try:verify(d)
        except AssertionError:denied.append(name)
        else:raise AssertionError("accepted forged EOF proof "+name)
    response={"schema":"befunge-stage1-native-eof-independent-audit-v1",
              "verified_native_records":n,"negative_tamper_reports_rejected":denied,
              "full_production_acceptance":False,"last_completed_stage":0}
    (folder/"native_eof_full_stream_audit.json").write_text(
        json.dumps(response,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_YEAR5000_EOF_FULL_STREAM_%d_AND_%d_TAMPER_AUDIT_PASS"%
          (n,len(denied)))
if __name__=="__main__":
    check(len(sys.argv)==2,"Native evidence folder argument is required")
    main(sys.argv[1])
