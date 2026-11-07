#!/usr/bin/env python3
"""Portable derived-fixture check only; this does NOT run original Native traces."""
import copy
import json
import sys
from pathlib import Path

EXPECTED_SHA={
"original_source_git_blob":"560d6aa5807a7f766213a33835cce85eab0fa40c",
"original_original_signed_archive_sha256":"9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49",
"original_QA31AZ_inventory_sha256":"06d0e25b685c00cb8696e22b986aac7b531d98ae95e79406fc82ef0912540358",
"original_QA31AN_signed_target_archive_sha256":"9aebc80a4b9a1c7b8b32482ec2eaeaf0849bbaef382bfc019e5a7e5a5bfe8124"}
COUNTS={"original_cases":200,"shards":8,"steps":3628390,
"physical_x_events":50180,"physical_p_events":14820,
"physical_x_sites":269,"physical_p_sites":56,
"rightward_unresolved_x_original_lexical_sites":180,
"rightward_unresolved_p_original_lexical_sites":30,
"rightward_unresolved_x_original_lexical_sites_physically_observed":178,
"rightward_unresolved_p_original_lexical_sites_physically_observed":30,
"original_lexical_x_sites_unobserved":10,"original_lexical_p_sites_unobserved":1,
"physical_p_writes_into_protected_parser_rows":0,
"physical_counter_q_m_write_events":2920,
"physical_p_writes_selector_1500_1750":365,
"prior_QA31AN_candidate_p_events_reverified":1710,
"synthetic_nonnoop_mutants_rejected":24,
"new_original_native_runs":0,"new_exhaustive_stage1_CI":0}
ROUTES=[{"source":[174,11],"target":[10,14],"events":1060},
{"source":[211,29],"target":[10,32],"events":100}]
CONFLICTS=[
{"source":[369,575],"rightward_syntax_only_target":[5,5],
"actual_200_case_direction":[-1,0],"actual_200_case_target":[7,1692],"actual_events":140},
{"source":[664,860],"rightward_syntax_only_target":[10,5],
"actual_200_case_direction":[-1,0],"actual_200_case_target":[113,1718],"actual_events":140},
{"source":[1041,860],"rightward_syntax_only_target":[10,5],
"actual_200_case_direction":[-1,0],"actual_200_case_target":[47,1703],"actual_events":225}]
def check(v):
    assert v["schema"]=="qa31ba-signed200-aggregates-portable-v1"
    assert v["project_id"]=="PC-BRANCH-BEFUNGE98-KYRGYZ"
    for k,want in EXPECTED_SHA.items(): assert v[k]==want,k
    for k,want in COUNTS.items(): assert v[k]==want,k
    assert v["physical_nonlexical_xp_opcodes"]=={}
    assert v["physical_x_into_row14_row32"]==ROUTES
    assert v["three_forward_syntax_only_false_physical_claims"]==CONFLICTS
    assert v["protected_parser_rows"]==[5,6,8,11,14,17,20,23,26,29,32,35,38,44]
    assert v["independent_original_receipt_readers"]==2
    assert v["global_unreachability"]=="UNKNOWN"
    assert v["stage1_pass"] is False

def hostile(v):
    samples=[]
    for k in list(COUNTS)[:13]:
        m=copy.deepcopy(v);m[k]+=1;samples.append(m)
    for k in EXPECTED_SHA:
        m=copy.deepcopy(v);m[k]="0"*64;samples.append(m)
    for i in range(3):
        m=copy.deepcopy(v)
        m["three_forward_syntax_only_false_physical_claims"][i]["actual_200_case_target"][0]+=1
        samples.append(m)
    for i in range(2):
        m=copy.deepcopy(v);m["physical_x_into_row14_row32"][i]["source"][0]+=1;samples.append(m)
    for key,want in [("stage1_pass",True),("global_unreachability","PROVEN")]:
        m=copy.deepcopy(v);m[key]=want;samples.append(m)
    assert len(samples)==24
    for m in samples:
        assert m!=v
        try:check(m)
        except AssertionError:continue
        raise AssertionError("hostile non-no-op report accepted")
    return len(samples)

def main():
    data=json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    check(data)
    print(json.dumps({"project_id":data["project_id"],
        "original_signed_trace_replay_by_this_CI":False,
        "referenced_original_cases":data["original_cases"],
        "referenced_original_steps":data["steps"],
        "physical_x_events":data["physical_x_events"],
        "physical_p_events":data["physical_p_events"],
        "derived_portable_hostile_controls_rejected":hostile(data),
        "stage1_pass":False},indent=2))
if __name__=="__main__": main()
