#!/usr/bin/env python3
"""Independent audit for raw PyFunge integer-sign Native diagnostic.

Separately reconstruct lexical inputs and original malformed index record.
Never endorses the returned Native output as semantically correct.
"""
import copy
import json
import sys
from pathlib import Path
SHA="c70f15354979aafdd0ea0c83045ef2a54dd996f9"
TOKENS=("-1","-2","-3","-7","0","1","2","3","7","-0","+1","+2")
def need(ok,reason):
    if not ok:raise AssertionError(reason)
def verify(d):
    need(d.get("schema")=="befunge-stage1-pyfunge-integer-signed-lexeme-probe-v1"
         and d.get("scope")=="NATIVE_PYFUNGE_INTEGER_INPUT_DIAGNOSTIC_ONLY_STAGE1_OPEN"
         and d.get("reference_git_blob")==SHA
         and d.get("raw_probe_source")=="&.@"
         and d.get("token_count")==len(TOKENS)
         and d.get("stage1_functional_pass") is False
         and d.get("stage1_geometry_pass") is False,
         "Native decimal input transport probe metadata forged")
    rows=d.get("tokens")
    need(isinstance(rows,list) and len(rows)==len(TOKENS),
         "native input lexeme measurements truncated")
    for row,token in zip(rows,TOKENS):
        echoed=row.get("native_echo")
        need(row.get("input_token")==token
             and row.get("decimal_python_expected")==str(int(token))
             and isinstance(echoed,str) and echoed.lstrip("-").isdigit(),
             "Native Befunge echo data missing or malformed")
    fields=[0,100,-1,3,7]
    fields += [a for i in range(7) for a in (0,42*i)]
    fields += [1]
    reported=d.get("malformed_year5000_native_output")
    need(d.get("malformed_year5000_index_sign_raw")=="-1"
         and d.get("malformed_year5000_index_sign_fields")==fields
         and isinstance(reported,list) and len(reported)==6
         and all(isinstance(x,str) and x.lstrip("-").isdigit() for x in reported),
         "Native malformed index-sign year5000 witness modified")
    loss=rows[0]["native_echo"]!="-1"
    need(d.get("requires_lexical_validation_if_sign_is_lost") is loss,
         "Native sign information transport loss misclassified")
    return {"measured_tokens":len(TOKENS),"negative_one_native_echo":rows[0]["native_echo"],
            "malformed_index_returned_fields":reported,
            "lexical_sign_loss_observed":loss,"acceptance":"OPEN"}

def main(p):
    root=Path(p)
    d=json.loads((root/"native_pyfunge_signed_lexeme_probe.json").read_text("utf-8"))
    answer=verify(d)
    forged=[]
    changes=(
      ("wrong_reference",lambda z:z.__setitem__("reference_git_blob","0"*40)),
      ("remove_echo",lambda z:z["tokens"].pop()),
      ("wrong_token",lambda z:z["tokens"][0].__setitem__("input_token","1")),
      ("wrong_int",lambda z:z["tokens"][0].__setitem__("decimal_python_expected","1")),
      ("wrong_raw_probe",lambda z:z.__setitem__("raw_probe_source","&&.@")),
      ("wrong_year_inputs",lambda z:z["malformed_year5000_index_sign_fields"].__setitem__(2,1)),
      ("wrong_year_fields",lambda z:z["malformed_year5000_native_output"].pop()),
      ("wrong_loss",lambda z:z.__setitem__("requires_lexical_validation_if_sign_is_lost",
                                        not z["requires_lexical_validation_if_sign_is_lost"])),
      ("stage_complete",lambda z:z.__setitem__("stage1_functional_pass",True)),
    )
    for label,mutation in changes:
        c=copy.deepcopy(d);mutation(c)
        try:verify(c)
        except AssertionError:forged.append(label)
        else:raise AssertionError("Native integer sign false report accepted: "+label)
    need(len(forged)==len(changes),"native transport negative controls skipped")
    (root/"native_pyfunge_signed_lexeme_probe_audit.json").write_text(json.dumps(
       {"schema":"befunge-stage1-native-integer-lexeme-audit-v1",
        "verified":answer,"hostile_cases_rejected":forged,
        "stage1_accepted":False},indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_PYFUNGE_RAW_INTEGER_LEXEME_AUDIT_PASS",
          json.dumps(answer,sort_keys=True))
    print("NATIVE_INTEGER_INPUT_NINE_HOSTILE_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"usage: Native integer probe report dir")
    main(sys.argv[1])
