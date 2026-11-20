#!/usr/bin/env python3
"""v145: exact source-pinned synthetic bowl / rank stream equivalence witness.

The original calendar F(c,t) is NEVER imported, compiled or invoked.
This audits fixed source snippets, pure math inputs, and prior completed CI.
Toy exhaustive comparisons use moduli 7/11, not original calendar years.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_RANK_STREAM_SOURCE_EQUIVALENCE_V145/1"
REPORT="PASTAFARI_SOAK_RANK_STREAM_EQUIVALENCE_REPORT_V145/1"
REPO="Sargon17-Green/Pastafarian-Calendar"
PY_REF="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PY_BLOB="d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
ADA_REF="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
ADA_BLOB="923733d4f8face03586aee304640bf7540c28b4c"
M=2**127-1
V144_RUN=44826585046
V144_HEAD="9655d09f0f3055201495ec2c925b6ad851c8a2d6"
V144_ART=14674183354
V144_DIGEST="49b999d0fc042fc890cab6afbf38af9f341ed28f21e539b3b46417bc774a1d8c"
N_WIDE_BOWL=(1<<256)+12345

def need(condition,message):
    if not condition:
        raise ValueError(message)

def validate(m):
    need(type(m) is dict and m.get("schema")==SCHEMA
         and m.get("purpose")==
         "ISOLATED_SYNTHETIC_BOWL_AND_SHORT_WIDE_RANK_SELECTOR_NO_REAL_FCT"
         and m.get("repository")==REPO and m.get("modulus_decimal")==str(M),
         "v145 rank-stream source contract changed")
    need(m.get("source_refs")=={
      "python":{"commit":PY_REF,"path":"tests/normative_reference.py","blob":PY_BLOB},
      "ada":{"commit":ADA_REF,"path":"src/normative_oracle.adb","blob":ADA_BLOB}},
      "original rank source pins changed")
    need(m.get("prior_v144")=={"ci":V144_RUN,"head":V144_HEAD,
         "artifact":V144_ART,"digest":V144_DIGEST},
         "prior accepted v144 proof changed")
    need(m.get("short_wide_semantics")=={
         "short":"first accepted rank of cyclic answer_at(k), k>=0, when 1<=N<=M",
         "wide":"digits answer_at(j)-1 in radix M, little endian, minimal places with M^places>=N; shift by direction until <=floor(space/N)*N; output ((wide-1) mod N)+1",
         "accepted_endpoint_equivalence":"for source streams direction +/-1, rejection followed by -1 enters acceptance at floor(space/N)*N; +1 first wraps to 1",
         "no_real_sauce_or_fct":True},
         "source acceptance-order or width contract changed")
    need(m.get("original_source_not_invoked") is True
         and m.get("allowed_Ada_synthetic_build") is True
         and m.get("bounded_gnat_only") is True
         and m.get("scientific_gates")=={
         "issue29_open":True,"STOP_NEW_NATIVE_SOAK_DISPATCH":True,
         "main_frozen":"56bc4173aae4975ded019ef5ab5a36249f1424df",
         "original_Fct_calls":0,"original_native_compiles":0,
         "original_full_years_accepted":0,
         "certified_independent_algorithms":0,"production_patch":False,
         "source_single_root_cause_proven":False},
         "original source dispatch stop improperly lifted")
    direct=m.get("direct_vectors")
    bowls=m.get("synthetic_bowl_vectors")
    need(type(direct) is list and len(direct)==26 and
         type(bowls) is list and len(bowls)==6,
         "v145 direct or bowl golden vector count changed")

def answer(first,step,k,modulus=M):
    need(type(first) is int and 1<=first<=modulus
         and step in (-1,1) and type(k) is int and k>=0,
         "invalid source-defined synthetic +/-1 stream")
    return 1+(first-1+step*k)%modulus

def choose_closed_form(first,step,n,modulus=M):
    need(type(n) is int and 1<=n<2**1024,
         "synthetic family N outside QA bound")
    need(modulus>=2 and 1<=first<=modulus and step in (-1,1),
         "invalid source-defined synthetic stream")
    if n<=modulus:
        limit=(modulus//n)*n
        rejected=first>limit
        x=(1 if step==1 else limit) if rejected else first
        return {"rank":(x-1)%n+1,"mode":"short",
                "places":1,"rejected":rejected}
    places=1
    space=modulus
    while space<n:
        places+=1
        space*=modulus
    wide=1
    weight=1
    for j in range(places):
        wide+=(answer(first,step,j,modulus)-1)*weight
        weight*=modulus
    limit=(space//n)*n
    rejected=wide>limit
    adjusted=(1 if step==1 else limit) if rejected else wide
    return {"rank":(adjusted-1)%n+1,"mode":"wide",
            "places":places,"rejected":rejected}

def choose_literal_walk(first,step,n,modulus):
    """Independent literal cyclic source-loop transcription; tiny moduli only."""
    need(modulus in (7,11) and 1<=n<=modulus**3+1,
         "literal source loop toy scope exceeded")
    if n<=modulus:
        limit=(modulus//n)*n
        k=0
        while True:
            x=answer(first,step,k,modulus)
            if x<=limit:return (x-1)%n+1
            k+=1
    places=1
    space=modulus
    while space<n:
        places+=1
        space*=modulus
    wide=1
    weight=1
    for j in range(places):
        wide+=(answer(first,step,j,modulus)-1)*weight
        weight*=modulus
    limit=(space//n)*n
    while wide>limit:
        wide=1+(wide-1+step)%space
    return (wide-1)%n+1

def toy_exhaustive():
    results=[]
    for modulus in (7,11):
        n_candidates=list(range(1,modulus*modulus+4))+[
            modulus**3-1,modulus**3,modulus**3+1]
        total=0
        rejected=0
        for first in range(1,modulus+1):
            for direction in (-1,1):
                for n in n_candidates:
                    direct=choose_closed_form(first,direction,n,modulus)
                    literal=choose_literal_walk(first,direction,n,modulus)
                    need(direct["rank"]==literal,
                         "actual rejection walk vs endpoint shortcut mismatch")
                    total+=1
                    rejected+=int(direct["rejected"])
        expected={7:770,11:2794}[modulus]
        need(total==expected,"toy exhaustive source family case count changed")
        results.append({"modulus":modulus,"cases":total,
                        "initially_rejected":rejected,
                        "all_literal_vs_shortcut_equal":True})
    return {"toy_moduli":results,"total_exact_literal_walk_checks":3564,
            "endpoint_equivalence_for_pm1_proven_in_toy_domain":True,
            "original_modulus_full_state_exhaustively_checked":False}

def bowl_math(bowls,order,queried,seal):
    need(len(bowls)==6 and len(order)==6
         and sorted(order)==[1,2,3,4,5,6]
         and queried in range(1,7) and seal>=0,
         "invalid synthetic bowl/order")
    nextid=order[(order.index(queried)+1)%6]
    save=lambda a:1+(a-1)%M
    first=save((bowls[queried-1]+seal+181)**2+bowls[nextid-1]*179+seal)
    d=save((first+seal+194)**2+first*193+bowls[5]*197)
    step=1 if d%2==1 else -1
    return first,step

def golden_checks(m):
    validate(m)
    direct_names=set()
    rejected=0
    places=set()
    modes=set()
    for item in m["direct_vectors"]:
        name=item["name"]
        need(type(name) is str and name not in direct_names,
             "duplicate direct synthetic rank fixture")
        direct_names.add(name)
        first=int(item["first"])
        step=item["direction_step"]
        n=int(item["n"])
        want=choose_closed_form(first,step,n)
        need(item=={"name":name,"first":str(first),
                    "direction_step":step,"n":str(n),
                    "rank":str(want["rank"]),
                    "places":want["places"],"rejected":want["rejected"],
                    "mode":want["mode"]},
                    "frozen original source rank golden disagreement: "+name)
        rejected+=int(want["rejected"])
        places.add(want["places"])
        modes.add(want["mode"])
    need(modes=={"short","wide"} and max(places)>=8 and rejected>=8,
         "rank fixture boundary or rejection modes incomplete")
    bowl_directions=[]
    for x in m["synthetic_bowl_vectors"]:
        bowls=[int(a) for a in x["bowls"]]
        first,step=bowl_math(bowls,x["order"],x["queried_id"],x["seal"])
        need(str(first)==x["first"] and step==x["direction_step"]
             and str(choose_closed_form(first,step,37)["rank"])==x["short_37"]
             and str(choose_closed_form(first,step,N_WIDE_BOWL)["rank"])==x["wide_256"],
             "frozen source synthetic Ask_Bowl / rank goldens disagree")
        bowl_directions.append(step)
    need(set(bowl_directions)=={-1,1},"missing both stream directions")
    return {"direct_golden_vectors":len(direct_names),
       "synthetic_bowl_vectors":len(bowl_directions),
       "direct_initial_rejected_cases":rejected,
       "tested_base_M_places":sorted(places),
       "both_directions_covered":True,
       "no_original_calendrical_input":True}

def source_check(m,gh):
    validate(m)
    py,proof=checked_blob(gh,REPO,PY_REF,"tests/normative_reference.py")
    need(proof["git_blob_sha1"]==PY_BLOB,
         "original Python normative rank source blob changed")
    ada,proof=checked_blob(gh,REPO,ADA_REF,"src/normative_oracle.adb")
    need(proof["git_blob_sha1"]==ADA_BLOB,
         "original Ada normative rank source blob changed")
    p=py.decode("utf-8")
    a=ada.decode("utf-8")
    python_tokens=(
       "M = 2**127 - 1",
       "def ask_bowl(result: SauceResult, queried_bowl_id: int, seal: int)",
       "(result.bowls[queried_bowl_id] + seal + 181) ** 2",
       "result.bowls[next_id] * 179",
       "result.bowls[6] * 197",
       "step = 1 if regular_mod(direction_number, 2) == 1 else -1",
       "def answer_at(stream: AnswerStream, k: int)",
       "def choose_rank_short(stream: AnswerStream, n: int)",
       "acceptance_limit = (M // n) * n",
       "def choose_rank_wide(stream: AnswerStream, n: int)",
       "wide += (answer_at(stream, j) - 1) * weight",
       "while wide > acceptance_limit:",
       "wide = 1 + regular_mod(wide - 1 + stream.direction_step, space)",
       "return regular_mod(wide - 1, n) + 1",
       "def choose_rank(stream: AnswerStream, n: int)"
    )
    ada_tokens=(
       "function Ask_Bowl",
       "First := Save",
       "B (179) * R.Bowls (Next_Id)",
       "B (197) * R.Bowls (6)",
       "function Answer_At",
       "Stream.First - B (1) + B (Stream.Direction_Step) * K",
       "function Choose_Rank_Short",
       "Acceptance_Limit : constant Big_Integer := Floor_Div (M, N) * N",
       "function Choose_Rank_Wide",
       "Wide := Wide + (Answer_At (Stream, B (J)) - B (1)) * Weight",
       "when -1 =>", "when 1  =>", "Wide := Acceptance_Limit",
       "Wide := B (1)",
       "function Choose_Rank"
    )
    need(all(t in p for t in python_tokens),
         "original Python short/wide rank and bowl source semantics changed")
    need(all(t in a for t in ada_tokens),
         "original Ada short/wide rank and bowl source semantics changed")
    return {"pinned_source_git_blobs":2,
       "python_source_loop_mimicked_in_toy":True,
       "ada_source_endpoint_replacement_checked":True,
       "original_calendar_Fct_called":False}

def prior_check(gh):
    run=gh.get("/repos/"+REPO+"/actions/runs/"+str(V144_RUN))
    need(run.get("id")==V144_RUN and run.get("head_sha")==V144_HEAD
         and run.get("status")=="completed" and run.get("conclusion")=="success",
         "v144 CI not completed/success at pinned source")
    arts=gh.get("/repos/"+REPO+"/actions/runs/"+str(V144_RUN)+"/artifacts?per_page=100")
    need(type(arts.get("total_count")) is int and arts["total_count"]<=100
         and isinstance(arts.get("artifacts"),list),
         "v144 artifact listing incomplete")
    matches=[a for a in arts["artifacts"] if a.get("id")==V144_ART]
    need(len(matches)==1 and matches[0].get("digest")=="sha256:"+V144_DIGEST
         and matches[0].get("expired") is False,
         "v144 archived GNAT evidence unavailable or wrong SHA")
    issue=gh.get("/repos/"+REPO+"/issues/29")
    need(issue.get("number")==29 and issue.get("state")=="open"
         and "CONFIRMED_ORIGINAL_SOURCE_MISMATCH" in issue.get("body",""),
         "original Fct first mismatch no longer open")
    main=gh.get("/repos/"+REPO+"/branches/main")
    need(main.get("commit",{}).get("sha")==
         "56bc4173aae4975ded019ef5ab5a36249f1424df",
         "main original source frozen SHA changed")
    return {"v144_completed_success_at_exact_SHA":True,
       "v144_log_only_artifact_digest_verified":True,
       "issue29_open":True,"main_unchanged":True}

def audit(m,gh):
    validate(m)
    return {"schema":REPORT,"manifest_sha256":digest(m),
       "original_source":source_check(m,gh),
       "previous_QA":prior_check(gh),
       "fixed_goldens":golden_checks(m),
       "independent_tiny_literal_walk_proof":toy_exhaustive(),
       "actual_Fct_intermediate_rank_values_observed":False,
       "original_Fct_calls_new":0,
       "original_full_years_accepted":0,
       "independent_calendar_algorithms_certified":0,
       "rank_source_equivalence_is_not_full_calendar_equivalence":True,
       "STOP_NEW_NATIVE_SOAK_DISPATCH":True}

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--manifest",required=True,type=Path)
    ap.add_argument("--output",required=True,type=Path)
    args=ap.parse_args()
    r=audit(parse_json(args.manifest.read_bytes()),
            GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with args.output.open("xb") as f:f.write(canonical(r)+b"\n")
    print(json.dumps({"source_blobs":r["original_source"]["pinned_source_git_blobs"],
       "direct_goldens":r["fixed_goldens"]["direct_golden_vectors"],
       "synthetic_bowls":r["fixed_goldens"]["synthetic_bowl_vectors"],
       "small_modulus_literal_checks":r["independent_tiny_literal_walk_proof"]["total_exact_literal_walk_checks"],
       "original_Fct_calls":0,"original_full_years_accepted":0},sort_keys=True))

if __name__=="__main__":
    main()
