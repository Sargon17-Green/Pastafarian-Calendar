#!/usr/bin/env python3
"""Static v139 original-source month weaving legal-family discriminator.

No original native F(c,t) calls, no Python original engine calls, no compiler,
no subprocess, no SHA claims for executable bytes. Enumerates ONLY a tiny
pure combinatorial (4,4)-month toy family under the two source-defined rules.
"""
from __future__ import annotations
import argparse
from collections import Counter
from itertools import combinations
import json
import os
from pathlib import Path

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_STATIC_WEAVE_FAMILY_DIVERGENCE_V139/1"
REPORT="PASTAFARI_SOAK_STATIC_WEAVE_FAMILY_REPORT_V139/1"
REPO="Sargon17-Green/Pastafarian-Calendar"
ADA="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
PYTHON="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
ADA_FILES={
 "src/month_weaving.adb":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 "src/normative_oracle.adb":"923733d4f8face03586aee304640bf7540c28b4c",
 "tests/stage14_real_oracle.py":"0922f5cbb32697106d4537463e56f7edb74e3355",
 "tests/stage14_real_differential.py":"44a38a1a8d9fac1bf2f454c2828a8545cd0e1d5b"}
PY_FILES={
 "tests/normative_reference.py":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53",
 "src/pastafari_calendar/legacy_month_weaving.py":"b07103088c853f61eafa135eaac3142d58b096d7"}
PY_EXAMPLE=(1,1,1,1,2,2,2,2)
EXPECTED_FCT_PY=(5000,10,503,20,56)
EXPECTED_FCT_ADA=(5000,10,503,30,52)

def need(cond,msg):
    if not cond:raise ValueError(msg)

def validate(m):
    need(type(m) is dict and m.get("schema")==SCHEMA and m.get("repository")==REPO
         and m.get("purpose")==
           "STATIC_SOURCE_FAMILY_DISCRIMINATOR_NOT_PROOF_OF_ALL_FIRST_MISMATCH_CAUSES"
         and m.get("ada")=={"commit":ADA,"files":ADA_FILES}
         and m.get("python_original")=={"commit":PYTHON,"files":PY_FILES},
         "original source ref or blob lock changed")
    observed=m.get("observed_original_Fct",{})
    need(observed=={"c":-15055671,"t":-15055671,
         "python_turkish":list(EXPECTED_FCT_PY),
         "typescript_marathi":list(EXPECTED_FCT_PY),
         "fortran_english":list(EXPECTED_FCT_PY),
         "ada_telugu":list(EXPECTED_FCT_ADA),
         "first_different_field":"month_index",
         "source":"issue_29_original_native_provenance"},
         "original F(c,t) discrepancy evidence changed")
    math=m.get("mathematical_family_scope",{})
    need(math=={"month_lengths":[4,4],"month_count":2,"total_days":8,
         "python_legal_count":20,"ada_two_rail_count":6,
         "python_valid_ada_forbidden_example":list(PY_EXAMPLE),
         "ada_rail_first_ids":[1,2],"ada_rail_last_ids":[1,2],
         "python_allows_interleaved_opens_and_closes":True,
         "ada_requires_fixed_all_opening_prefix_and_all_closing_suffix":True,
         "counts_are_small_model_not_original_Fct_source_execution":True},
         "small-model legal-family contract changed")
    need(m.get("local_ada_provisional_oracle_has_same_ada_foundation")
          ==list(EXPECTED_FCT_ADA)
          and m.get("no_original_native_runs") is True
          and m.get("no_original_10000_years_certified") is True
          and m.get("scientific_soak_dispatch_authorized") is False
          and m.get("year_10000_pass") is False
          and m.get("independent_algorithms_certified")==0
          and m.get("not_proven_that_rail_only_explains_foundation_numeric_difference") is True,
         "scientific Fct stop or unwarranted causal conclusion")

def enumerate_original_legal(lengths):
    """Tiny-model transcription of normative_reference.MonthWeavingFamily._moves."""
    need(lengths==(4,4),"small finite family only")
    results=[]
    def walk(remaining,opened,closed,sequence):
        if not any(remaining):
            need(opened==closed==len(lengths),"invalid closing state")
            results.append(tuple(sequence))
            return
        for idx in range(closed,opened):
            n=remaining[idx]
            if n<=0 or (n==1 and idx!=closed):
                continue
            nxt=list(remaining)
            nxt[idx]-=1
            walk(tuple(nxt),opened,closed+(nxt[idx]==0),sequence+[idx+1])
        if opened<len(lengths):
            idx=opened
            nxt=list(remaining)
            nxt[idx]-=1
            new_closed=closed
            if nxt[idx]==0:
                need(idx==closed,"premature close")
                new_closed+=1
            walk(tuple(nxt),opened+1,new_closed,sequence+[idx+1])
    walk(tuple(lengths),0,0,[])
    need(len(results)==len(set(results)),"duplicate original legal enumeration")
    return sorted(results)

def enumerate_ada_two_rail(lengths):
    """Tiny model of Ada Month_Weaving.From_Choices fixed two rails."""
    need(lengths==(4,4),"small finite family only")
    ids=tuple(range(1,len(lengths)+1))
    inside=(1,1,2,2)
    results=set()
    # Choose two positions for the first month's two interior days.
    for indices in combinations(range(len(inside)),2):
        middle=[2]*len(inside)
        for i in indices:middle[i]=1
        results.add(ids+tuple(middle)+ids)
    return sorted(results)

def check_family(m):
    validate(m)
    python=set(enumerate_original_legal((4,4)))
    ada=set(enumerate_ada_two_rail((4,4)))
    need(len(python)==20 and len(ada)==6 and ada < python,
         "legal family should be strict original superset of Ada fixed-rail")
    need(PY_EXAMPLE in python and PY_EXAMPLE not in ada,
         "source-defined counterexample missing")
    need(all(Counter(seq)==Counter({1:4,2:4}) for seq in python|ada),
         "invalid multiplicity in model")
    return {
       "toy_month_lengths":[4,4],"python_legal_count":len(python),
       "ada_two_rail_count":len(ada),"ada_subset_of_python":True,
       "original_only_legal_sequences":len(python-ada),
       "witness_in_original_not_ada":list(PY_EXAMPLE),
       "source_family_equivalent":False,
       "equivalence_failure_is_static_and_does_not_need_native_date_process":True,
       "foundation_date_causal_trace_completed":False
    }

def check_source(m,gh):
    validate(m)
    files={}
    for kind,rev,group in (("ada",ADA,ADA_FILES),("python",PYTHON,PY_FILES)):
        for path,sha in group.items():
            b,proof=checked_blob(gh,REPO,rev,path)
            need(proof["git_blob_sha1"]==sha,
                 "source Git blob mismatch: "+path)
            files[path]=b.decode("utf-8")
    ada_weave=files["src/month_weaving.adb"]
    ada_date=files["src/normative_oracle.adb"]
    py_norm=files["tests/normative_reference.py"]
    py_prod=files["src/pastafari_calendar/legacy_month_weaving.py"]
    py_local=files["tests/stage14_real_oracle.py"]
    py_local_test=files["tests/stage14_real_differential.py"]
    need("function From_Choices" in ada_weave
         and "for J in Lengths'Range loop" in ada_weave
         and "Output (Pos) := J;" in ada_weave
         and "Remains (J) := Lengths (J) - 2;" in ada_weave
         and "for I in Picks'Range loop" in ada_weave
         and "function Canonical_Weave_Count" in ada_weave,
         "Ada source no longer demands fixed month opening and closing rails")
    need("Interior : constant Natural := Total - 2 * M_Count;" in ada_date
         and "Tickets (I)" in ada_date
         and "Month_Weaving.From_Choices (Lengths, Tickets)" in ada_date
         and "Month_Canonical => Positive (Month_Names (Month_Id))" in ada_date,
         "Ada Calendar_Date original month decoding differs")
    need("class MonthWeavingFamily:" in py_norm
         and "def _moves(" in py_norm
         and "for index in range(closed, opened):" in py_norm
         and "if opened < self.month_count:" in py_norm
         and "next_opened = opened + 1" in py_norm
         and "def choose_month_weaving(" in py_norm
         and "family = MonthWeavingFamily(month_lengths)" in py_norm
         and "rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())" in py_norm
         and "return family.unrank1(rank)" in py_norm,
         "Python original legal weaving transitions/rank changed")
    need("class LegalMonthWeavingDP:" in py_prod
         and "def compatibleMonthWeavingRank(" in py_prod
         and "legal_family = LegalMonthWeavingDP(" in py_prod
         and "correct_weaving = legal_family.unrank1(" in py_prod,
         "Python original production weaving legal family not found")
    need("seq = list(range(len(lengths)))" in py_local
         and "occurrences = [i for i,n in enumerate(lengths) for _ in range(n-2)]" in py_local
         and "return seq+list(range(len(lengths)))" in py_local,
         "Ada local provisional oracle was not two-rail replica")
    need("(5000,10,503,30,52)" in py_local_test
         and "assert date(FOUNDATION,FOUNDATION)==PROVISIONAL[1]" in py_local_test,
         "Ada branch-local Python provisional check no longer matches Ada")
    return {
       "pinned_source_blobs_fetched":len(files),
       "Ada_fixed_two_rail_source_confirmed":True,
       "Python_original_open_close_interleaving_source_confirmed":True,
       "Ada_branch_local_Python_oracle_replicates_two_rail":True,
       "Ada_branch_local_provisional_foundation_not_independent_REF41":True,
       "source_difference_explains_global_family_inequivalence":True,
       "sole_cause_of_original_foundation_Fct_mismatch_proven":False
    }

def check_issue(gh):
    issue=gh.get("/repos/"+REPO+"/issues/29")
    need(issue.get("number")==29 and issue.get("state")=="open"
         and "Ada+" in issue.get("title","")
         and "CONFIRMED_ORIGINAL_SOURCE_MISMATCH" in issue.get("body","")
         and "5000,10,503,30,52" in issue.get("body","").replace(" ","")
         and "5000,10,503,20,56" in issue.get("body","").replace(" ",""),
         "Issue #29 original native divergence not verifiable")
    return {"issue":29,"state":"open","original_mismatch_proven_in_issue":True,
            "new_native_dispatch_allowed":False}

def audit(m,gh):
    validate(m)
    return {"schema":REPORT,"manifest_sha256":digest(m),
        "source":check_source(m,gh),
        "finite_toy_family":check_family(m),
        "original_mismatch_issue":check_issue(gh),
        "original_native_Fct_calls":0,
        "native_builds":0,
        "scientific_years_certified":0,
        "independent_algorithms_certified":0,
        "soak_dispatch_authorized":False,
        "source_family_divergence_proven":True,
        "foundation_mismatch_single_root_cause_not_proven":True}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--manifest",required=True,type=Path)
    p.add_argument("--output",required=True,type=Path)
    args=p.parse_args()
    report=audit(parse_json(args.manifest.read_bytes()),
                 GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with args.output.open("xb") as file:file.write(canonical(report)+b"\n")
    print(json.dumps({"ada_weaving_family":report["finite_toy_family"]["ada_two_rail_count"],
      "python_weaving_family":report["finite_toy_family"]["python_legal_count"],
      "source_blobs":report["source"]["pinned_source_blobs_fetched"],
      "source_families_equivalent":False,
      "sole_root_cause_of_foundation_mismatch_proven":False,
      "certified_10000_original_years":0,
      "soak_dispatch_authorized":False},sort_keys=True))

if __name__=="__main__":main()
