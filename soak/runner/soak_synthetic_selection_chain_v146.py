#!/usr/bin/env python3
"""v146: independent pure-math preflight for NEW isolated GNAT chain.

Only symbolic toy month labels. NO original F(c,t), date input, converter
source execution, native original build, or calendar engine import.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import os
import re

from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_rank_stream_source_proof_v145 import (
    bowl_math, choose_closed_form, source_check as original_rank_source_check)
from soak_ada_dp_resource_bounds_v142 import SyntheticDP

REPO="Sargon17-Green/Pastafarian-Calendar"
SCHEMA="PASTAFARI_SOAK_SYNTHETIC_BOWL_RANK_UNRANK_CHAIN_V146/1"
REPORT="PASTAFARI_SOAK_SYNTHETIC_CHAIN_MATHEMATICAL_REPORT_V146/1"
V145_CI=44829715837
V145_HEAD="c365ab7dc7bb13a0382872f395b0e6f305b2b573"
V145_ART=14678040271
V145_DIGEST="88c1413e472b8600464e7153991bacb8eede3525bc89f7bc3f771a135086596f"
V144_CI=44826585046
V144_HEAD="9655d09f0f3055201495ec2c925b6ad851c8a2d6"
V144_ART=14674183354
V144_DIGEST="49b999d0fc042fc890cab6afbf38af9f341ed28f21e539b3b46417bc774a1d8c"
V145_BOWL_BLOB="cfcf75cbe4e31b95027c397449b7145f417e254f"
ALPHABET="123456789ABC"
M=(1<<127)-1
CASES_PER_FAMILY=6
FAMILIES={
    "two4":((4,4),20),
    "three454":((4,5,4),3499),
    "eight16":((16,)*8,None),
    "eight32":((32,)*8,None),
    "twelve12":((12,)*12,None),
}

def need(p,msg):
    if not p:
        raise ValueError(msg)

def validate(m,bowl_manifest):
    need(type(m) is dict and m.get("schema")==SCHEMA
        and m.get("purpose")==
        "ISOLATED_SYNTHETIC_GNAT_ASK_BOWL_CHOOSE_RANK_MONTH_DP_UNRANK_END_TO_END_NO_ORIGINAL_FCT"
        and m.get("repo")==REPO,
        "v146 synthetic chain schema/scope wrong")
    need(m.get("original_source_locks")=={
        "python":{"commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
                  "blob":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"},
        "ada":{"commit":"a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72",
               "month_blob":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
               "rank_blob":"923733d4f8face03586aee304640bf7540c28b4c"}},
        "original source pins changed")
    need(m.get("prior_qa")=={
        "v144":{"run_id":V144_CI,"source_head":V144_HEAD,
                "artifact_id":V144_ART,"digest":V144_DIGEST},
        "v145":{"run_id":V145_CI,"source_head":V145_HEAD,
                "artifact_id":V145_ART,"digest":V145_DIGEST}},
        "prior accepted CI receipt changed")
    need(m.get("golden_bowl_source")=={
        "path":"soak/control/ada_rank_stream_source_v145.json",
        "blob":V145_BOWL_BLOB,"expected_bowls":6},
        "v145 bowl golden source pin changed")
    need(m.get("selector_lib")=="soak/ada_rank_v145/synthetic_rank_stream_v145.adb"
         and m.get("weaving_lib")=="soak/ada_port_v144/legal_month_weave_dp.adb"
         and m.get("output_encoding")==
            "month IDs 1-9 map to characters 1-9 and IDs 10-12 map A-C; ASCII string equality, not hash",
         "chain original QA dependency changed")
    need(m.get("scope_locks")=={
        "family_count":5,"bowl_count":6,"combined_cases":30,
        "full_sequences_compared":30,"wide_rank_cases":18,
        "max_synthetic_days":256,"max_synthetic_months":12,
        "original_date_inputs_used":0,"original_native_calendar_compiles":0,
        "original_Fct_calls":0,"STOP_NEW_NATIVE_SOAK_DISPATCH":True,
        "issue29_open":True,
        "main_frozen":"56bc4173aae4975ded019ef5ab5a36249f1424df",
        "original_soak_years_certified":0,
        "independent_original_algorithms_certified":0,"production_patch":False},
        "scientific stop or synthetic scope was promoted")
    need(type(bowl_manifest) is dict
         and bowl_manifest.get("schema")==
             "PASTAFARI_SOAK_RANK_STREAM_SOURCE_EQUIVALENCE_V145/1"
         and len(bowl_manifest.get("synthetic_bowl_vectors",[]))==6,
         "v145 original synthetic bowl choices absent")
    cases=m.get("cases")
    need(type(cases) is list and len(cases)==30,"v146 golden case inventory must be 30")
    seen=set()
    for c in cases:
        need(type(c) is dict and c["id"] not in seen,
             "v146 duplicate malformed case")
        seen.add(c["id"])
        fam=c["family"]
        need(fam in FAMILIES and c["id"]==f"{fam}_b{c['bowl_index']}",
             "v146 case id/family mismatch")
        lengths,_=FAMILIES[fam]
        need(c["lengths"]==list(lengths)
             and c["bowl_index"] in range(1,7)
             and c["rank_is_wide"] == (fam not in ("two4","three454"))
             and type(c["expected_sequence"]) is str
             and len(c["expected_sequence"])==sum(lengths)
             and all(label in ALPHABET for label in c["expected_sequence"]),
             "v146 fixture domain or sequence encoding changed")
    need(seen=={f"{fam}_b{i}" for fam in FAMILIES for i in range(1,7)},
         "v146 case cross product incomplete")

def compute_expected(m,bowl_manifest):
    validate(m,bowl_manifest)
    bowls=bowl_manifest["synthetic_bowl_vectors"]
    family_models={}
    records=[]
    for c in m["cases"]:
        fam=c["family"]
        lengths=tuple(c["lengths"])
        if fam not in family_models:
            family_models[fam]=SyntheticDP(lengths)
        dp=family_models[fam]
        N=dp.count()
        b=bowls[c["bowl_index"]-1]
        bowl_vals=[int(x) for x in b["bowls"]]
        first,step=bowl_math(bowl_vals,b["order"],b["queried_id"],b["seal"])
        rank=choose_closed_form(first,step,N)["rank"]
        seq=dp.unrank(rank)
        expected_seq="".join(ALPHABET[k-1] for k in seq)
        need(str(N)==c["expected_count"]
             and str(first)==c["expected_first"]
             and step==c["expected_direction"]
             and str(rank)==c["expected_rank"]
             and expected_seq==c["expected_sequence"],
             "source-independent mathematical fixture mismatch: "+c["id"])
        records.append({"id":c["id"],"sequence_length":len(expected_seq),
             "full_sequence_equality_to_immutable_fixture":True,
             "rank_bits":rank.bit_length(),
             "family_count_bits":N.bit_length(),
             "global_rank_wide":N>M})
    need(len(records)==30 and sum(int(r["global_rank_wide"]) for r in records)==18,
         "chain coverage changed or wide count incorrect")
    return {"all_30_complete_sequences_match_independent_pure_math":True,
        "cases":records,"exact_full_sequence_checks":30,"wide_family_cases":18,
        "family_counts":{fam:str(dp.count()) for fam,dp in family_models.items()},
        "maximum_synthetic_days":256,"original_date_values_computed":0}

def verify_ada_source(m,bowl_manifest,ada_source):
    validate(m,bowl_manifest)
    matches=re.findall(r"-- V146_FIXTURE_BEGIN (\w+)\n(.*?)\n\s*-- V146_FIXTURE_END \1",
                       ada_source,re.DOTALL)
    need(len(matches)==30 and len(set(name for name,_ in matches))==30,
         "Ada frozen fixture delimiters missing")
    blocks=dict(matches)
    bowl_vals=bowl_manifest["synthetic_bowl_vectors"]
    for c in m["cases"]:
        block=blocks.get(c["id"],"")
        b=bowl_vals[c["bowl_index"]-1]
        le=", ".join(f"{i} => {n}" for i,n in enumerate(c["lengths"],1))
        be=", ".join(f'{i} => From_String ("{n}")'
                     for i,n in enumerate(b["bowls"],1))
        oe=", ".join(f"{i} => {n}" for i,n in enumerate(b["order"],1))
        expected_tokens=(
            f'Case_Id => "{c["id"]}"',
            f"Lengths => Month_Lengths'({le})",
            f"Bowls => Bowl_Array'({be})",
            f"Order => Bowl_Order'({oe})",
            f"Queried => {b['queried_id']}, Seal => {b['seal']}",
            f'Expected_Count => "{c["expected_count"]}"',
            f'Expected_First => "{c["expected_first"]}"',
            f'Expected_Direction => {c["expected_direction"]}',
            f'Expected_Rank => "{c["expected_rank"]}"'
        )
        need(all(token in block for token in expected_tokens),
             "Ada literal fixture differs from pinned independent math: "+c["id"])
        seq_match=re.search(r"Expected_Text => (.*)\);",block,re.DOTALL)
        need(seq_match is not None,"Ada full-sequence literal missing: "+c["id"])
        pieces=re.findall(r'"([^"]+)"',seq_match.group(1))
        need("".join(pieces)==c["expected_sequence"],
             "Ada FULL-SEQUENCE golden fixture differs: "+c["id"])
    imports=re.findall(r"^with\s+([^;]+);",ada_source,re.MULTILINE)
    need(set(imports)=={"Ada.Numerics.Big_Numbers.Big_Integers",
         "Ada.Text_IO","Legal_Month_Weave_DP","Synthetic_Rank_Stream_V145"},
         "Ada isolated chain imports changed to original converter")
    need("V146_FULL_SEQUENCES_COMPARED_EXACTLY=30" in ada_source
         and "V146_ORIGINAL_CALENDAR_FCT_CALLS=0" in ada_source
         and "V146_PRODUCTION_ADA_PATCH_APPLIED=FALSE" in ada_source,
         "Ada isolated mathematical test verdict markers missing")
    return {"Ada_case_literals_exact":30,
        "Ada_full_sequence_expected_text_literals_exact":30,
        "source_only_pure_math_module_imports":True,
        "original_Fct_imported":False}

def source_locks(gh,v145):
    source=original_rank_source_check(v145,gh)
    need(source["pinned_source_git_blobs"]==2,
         "original short/wide rank source not pinned")
    return source

def prior_ci(gh):
    for id,sha,artifact,digest in (
         (V144_CI,V144_HEAD,V144_ART,V144_DIGEST),
         (V145_CI,V145_HEAD,V145_ART,V145_DIGEST)):
        r=gh.get(f"/repos/{REPO}/actions/runs/{id}")
        need(r.get("id")==id and r.get("status")=="completed"
             and r.get("conclusion")=="success" and r.get("head_sha")==sha,
             "predecessor accepted CI not completed success")
        a=gh.get(f"/repos/{REPO}/actions/runs/{id}/artifacts?per_page=100")
        need(type(a.get("total_count")) is int and a["total_count"]<=100
             and isinstance(a.get("artifacts"),list),
             "predecessor artifact listing incomplete")
        match=[x for x in a["artifacts"] if x.get("id")==artifact]
        need(len(match)==1 and match[0].get("digest")=="sha256:"+digest
             and match[0].get("expired") is False,
             "predecessor artifact digest/availability changed")
    issue=gh.get(f"/repos/{REPO}/issues/29")
    need(issue.get("number")==29 and issue.get("state")=="open"
         and "CONFIRMED_ORIGINAL_SOURCE_MISMATCH" in issue.get("body",""),
         "original mismatch no longer pinned as open")
    main=gh.get(f"/repos/{REPO}/branches/main")
    need(main.get("commit",{}).get("sha")==
         "56bc4173aae4975ded019ef5ab5a36249f1424df",
         "original production main was modified")
    return {"v144_completed_success":True,"v145_completed_success":True,
            "both_SHA_digest_evidence_pinned":True,"issue29_open":True,
            "main_frozen":True}

def audit(manifest,v145,ada,gh):
    validate(manifest,v145)
    return {"schema":REPORT,"manifest_sha256":digest(manifest),
      "original_sources":source_locks(gh,v145),
      "predecessor_CI":prior_ci(gh),
      "Ada_code_literal_audit":verify_ada_source(manifest,v145,ada),
      "pure_mathematical_oracle":compute_expected(manifest,v145),
      "new_original_native_Fct_calls":0,
      "original_full_years_accepted":0,
      "independent_original_algorithms_certified":0,
      "original_calendar_causal_resolution_proven":False,
      "STOP_NEW_NATIVE_SOAK_DISPATCH":True}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--manifest",required=True,type=Path)
    parser.add_argument("--bowl-manifest",required=True,type=Path)
    parser.add_argument("--ada-source",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    a=parser.parse_args()
    m=parse_json(a.manifest.read_bytes())
    bowl=parse_json(a.bowl_manifest.read_bytes())
    code=a.ada_source.read_text(encoding="utf-8")
    result=audit(m,bowl,code,GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with a.output.open("xb") as f:f.write(canonical(result)+b"\n")
    print(json.dumps({"exact_full_sequence_cases":30,
        "wide_global_rank_cases":18,
        "original_git_source_blobs":2,
        "v144_and_v145_success_checked":True,
        "original_Fct_calls":0},sort_keys=True))

if __name__=="__main__":
    main()
