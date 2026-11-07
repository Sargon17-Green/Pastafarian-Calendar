#!/usr/bin/env python3
"""QA31BB derived portable fixture, NOT original signed receipt replay."""
import copy
import json
import sys
from pathlib import Path

PIN={
"schema":"qa31bb-original-signed200-derived-fixture-v1",
"project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ",
"source_git_blob":"560d6aa5807a7f766213a33835cce85eab0fa40c",
"original_signed_archive_sha256":"9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49",
"cases":200,"steps":3628390,
"row14_entries_via_x_174_11":1060,
"row32_entries_via_x_211_29":100,
"row14_32_nonx_incoming_entries":0,
"selector_writer_ip":[1335,1354],
"selector_address":[1500,1750],
"selector_original_static_source_character":" ",
"selector_write_and_execute_pairs":365,
"selector_execute_exactly_20_steps_after_write":365,
"selector_value62_right_arrow":140,
"selector_value118_down_arrow":225,
"selector_executions_without_earlier_same_case_write":0,
"selector_execution_without_matching_value":0,
"physical_p_to_protected_parser_rows":0,
"independent_original_signed_full_readers":2,
"independent_original_signed_mutant_reports_rejected":24,
"new_original_native_runs":0,
"stage1_pass":False,
"unobserved_inputs":"UNKNOWN"}
def check(obj):
    assert set(obj)==set(PIN),"fixture schema mismatch"
    for k,v in PIN.items():assert obj[k]==v,k
    assert obj["row14_entries_via_x_174_11"]+obj["row32_entries_via_x_211_29"]==1160
    assert obj["selector_value62_right_arrow"]+obj["selector_value118_down_arrow"]==365
    assert obj["stage1_pass"] is False
    assert obj["unobserved_inputs"]=="UNKNOWN"
def hostile(obj):
    keys=[
      "cases","steps","row14_entries_via_x_174_11","row32_entries_via_x_211_29",
      "row14_32_nonx_incoming_entries","selector_write_and_execute_pairs",
      "selector_execute_exactly_20_steps_after_write","selector_value62_right_arrow",
      "selector_value118_down_arrow","selector_executions_without_earlier_same_case_write",
      "selector_execution_without_matching_value","physical_p_to_protected_parser_rows",
      "independent_original_signed_full_readers",
      "independent_original_signed_mutant_reports_rejected",
      "new_original_native_runs"]
    mutations=[]
    for k in keys:
        other=copy.deepcopy(obj);other[k]+=1;mutations.append(other)
    for k in ("source_git_blob","original_signed_archive_sha256"):
        other=copy.deepcopy(obj);other[k]="0"*len(obj[k]);mutations.append(other)
    for k in ("selector_writer_ip","selector_address"):
        other=copy.deepcopy(obj);other[k][0]+=1;mutations.append(other)
    for k,v in [("selector_original_static_source_character",">"),
                ("unobserved_inputs","PROVEN"),
                ("stage1_pass",True)]:
        other=copy.deepcopy(obj);other[k]=v;mutations.append(other)
    while len(mutations)<24:
        other=copy.deepcopy(obj);other["selector_writer_ip"][1]+=len(mutations);mutations.append(other)
    assert len(mutations)==24
    for other in mutations:
        assert other!=obj
        try:check(other)
        except AssertionError:continue
        raise AssertionError("deliberate non-no-op corruption accepted")
    return len(mutations)
def main():
    obj=json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    check(obj)
    print(json.dumps({"project_id":obj["project_id"],"referenced_original_cases":obj["cases"],
     "referenced_original_signed_steps":obj["steps"],
     "original_46MB_signed_archive_replayed_here":False,
     "nonx_incoming_entries":obj["row14_32_nonx_incoming_entries"],
     "selector_causal_pairs":obj["selector_write_and_execute_pairs"],
     "all_pairs_lag_20":obj["selector_execute_exactly_20_steps_after_write"],
     "hostile_nonnoop_mutations_rejected":hostile(obj),
     "stage1_pass":False},indent=2))
if __name__=="__main__":main()
