#!/usr/bin/env python3
"""v140 source-only month selector discrepancy and read-only original archive receipt.

The only numerics run here are *tiny synthetic* (4,4) combinatorics, NOT
original F(c,t). The previously-produced original ZIP artifacts may be read
and hashed, never imported, executed, relinked or rebuilt. Metadata-only CI
is explicitly distinct from local archive-byte verification.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import zipfile

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob
from soak_weave_family_divergence_v139 import (
  enumerate_ada_two_rail,enumerate_original_legal)

REPO="Sargon17-Green/Pastafarian-Calendar"
SCHEMA="PASTAFARI_SOAK_WEAVE_SELECTOR_AND_ORIGINAL_ARCHIVES_V140/1"
REPORT="PASTAFARI_SOAK_WEAVE_SELECTOR_ORIGINAL_ARCHIVE_REPORT_V140/1"
ADA="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
PY="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
FORTRAN="23349b9748859a1032b8a3afad0812b1d392be94"
MOD=2**127-1
BLOBS={
 "ada_month":"9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
 "ada_date":"923733d4f8face03586aee304640bf7540c28b4c",
 "python_oracle":"d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
}
ARTIFACTS={
 "ada":(44394781099,14472835490,
    "v140-original-ada-v103-evidence.zip",
    "3d8c594ae761aa6eeb8c11b241755b2f11ef472d41483ffb5be0c1cdc2bd8cbe",
    9,ADA,(5000,10,503,30,52),
    "v103-original-ada-native.log",
    "cd8d3079a7f158ca454e58226742eab0ce93cf0779e1fae7e8c2aa3d5a38ae78"),
 "python_ts":(44392067310,14469537094,
    "v140-original-py-ts-v101-evidence.zip",
    "bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1",
    53,PY,(5000,10,503,20,56),
    "original-python-0-normalized.jsonl",
    "834cc548105faeadb99e5e3fb384d72e957d55c607847800f7cf0f0c8dc627c4"),
 "fortran":(44397451131,14473652463,
    "v140-original-fortran-v106-evidence.zip",
    "7f8e57308aee0c80ffedc9634e59b65d11a1bc94982830dd3217623878e3e48f",
    26,FORTRAN,(5000,10,503,20,56),
    "v106-native-output.log",
    "e4dbf6d7bb954481eb85f819f4816f90e9413b86afced8b5252512bbd81e85fb")
}
TS_MEMBER_SHA="a0f3a261f8247361d284420984fa6c6a1da84a4075374e89039e3b681d948e5f"
FORTRAN_BINARY_SHA="738a4f48aa9cd489d1cf48882ed15874cbd640600598d87979b8dcd6efc20ef1"
SOURCE_REQUESTS=[
 (ADA,"src/month_weaving.adb",BLOBS["ada_month"]),
 (ADA,"src/normative_oracle.adb",BLOBS["ada_date"]),
 (PY,"tests/normative_reference.py",BLOBS["python_oracle"])
]

def need(c,message):
    if not c:raise ValueError(message)

def validate(m):
    need(isinstance(m,dict) and m.get("schema")==SCHEMA
         and m.get("scope")==
         "TWO_DISTINCT_STATIC_SELECTOR_DIFFERENCES_PLUS_PREVIOUSLY_RUN_ORIGINAL_BYTES_NO_DISPATCH"
         and m.get("repository")==REPO
         and m.get("source_refs")=={"ada":ADA,"python":PY,"fortran":FORTRAN}
         and m.get("source_blobs")==BLOBS,
         "v140 source provenance contract changed")
    need(m.get("source_contract")=={
         "ada":"one rank per remaining interior ticket using shifted successive stream answers",
         "python":"one global rank over the complete legal month-weaving family",
         "families_not_equal":True,"selectors_not_equivalent":True,
         "neither_is_proof_of_sole_foundation_root_cause":True},
         "source selection semantic or confidence scope changed")
    need(m.get("synthetic_stream")=={
       "month_lengths":[4,4],"first":1,"direction":1,
       "modulus_decimal":str(MOD),"ada_tickets":[1,2,1,1],
       "ada_result":[1,2,1,2,1,2,1,2],
       "python_full_family_global_rank":1,
       "python_result":[1,1,1,1,2,2,2,2],
       "counterfactual_ada_rail_global_rank1_result":[1,2,1,1,2,2,1,2]},
       "v140 synthetic first/direction or distinct witness changed")
    entries=m.get("archived_original_runs")
    need(isinstance(entries,list) and len(entries)==3,"three original historical archives required")
    roles=set()
    for row in entries:
        role=row.get("role")
        need(role in ARTIFACTS and role not in roles,"unknown/duplicate original source archive")
        roles.add(role)
        run,aid,filename,sha,members,commit,observed,receipt,receiptsha=ARTIFACTS[role]
        expected={"role":role,"run_id":run,"artifact_id":aid,"file":filename,
           "sha256":sha,"members":members,"source_commit":commit,
           "observed":list(observed),"receipt_file":receipt,
           "receipt_sha256":receiptsha}
        if role=="python_ts":
            expected.update(typescript_member="original-typescript-0-raw.jsonl",
                            typescript_member_sha256=TS_MEMBER_SHA)
        if role=="fortran":
            expected.update(binary_member="v106-original-fortran-native",
                            binary_sha256=FORTRAN_BINARY_SHA)
        need(row==expected,"historical artifact ID, SHA or witness data changed")
    need(roles==set(ARTIFACTS),"original witness roles missing")
    need(m.get("original_fct_coordinates")=={
        "calculation_day":-15055671,"target_day":-15055671}
         and m.get("original_native_executions_in_v140")==0
         and m.get("original_soak_10000_years_certified")==0
         and m.get("independent_algorithms_certified")==0
         and m.get("dispatch_authorized") is False,
         "original source execution/soak admission forbidden")

def select_short(first,direction,offset,n):
    """Toy transcription of the common n<=MOD cyclic rank rule."""
    need(0<first<=MOD and direction in (-1,1) and 0<n<=MOD,
         "bad synthetic selector inputs")
    x=1+(first-1+direction*offset)%MOD
    limit=MOD//n*n
    if x>limit:
        x=1 if direction==1 else limit
    return 1+(x-1)%n

def tiny_selector(m):
    validate(m)
    lengths=(4,4)
    python=enumerate_original_legal(lengths)
    ada=enumerate_ada_two_rail(lengths)
    need(len(python)==20 and len(ada)==6,"original finite families not locked")
    source_first=1
    direction=1
    tickets=[]
    pool=[1,1,2,2]
    interior=[]
    for k,n in enumerate(range(4,0,-1)):
        index=select_short(source_first,direction,k,n)-1
        tickets.append(index+1)
        interior.append(pool.pop(index))
    ada_stream=(1,2)+tuple(interior)+(1,2)
    global_rank=select_short(source_first,direction,0,len(python))
    python_stream=python[global_rank-1]
    restricted_counterfactual=ada[global_rank-1]
    need(tickets==[1,2,1,1] and
         ada_stream==(1,2,1,2,1,2,1,2) and
         python_stream==(1,1,1,1,2,2,2,2) and
         restricted_counterfactual==(1,2,1,1,2,2,1,2) and
         ada_stream!=restricted_counterfactual,
         "month selector synthetic counterexample not source-faithful")
    return {"family_count_python":len(python),
            "family_count_ada":len(ada),
            "global_rank_python":global_rank,
            "per_slot_ada_tickets":tickets,
            "result_python_global_rank":list(python_stream),
            "result_ada_tickets":list(ada_stream),
            "counterfactual_global_rank_in_ada_only_family":list(restricted_counterfactual),
            "two_independent_structural_differences":True,
            "caused_actual_foundation_mismatch_proven":False}

def source_check(m,gh):
    validate(m)
    fetched={}
    for rev,path,sha in SOURCE_REQUESTS:
        raw,proof=checked_blob(gh,REPO,rev,path)
        need(proof["git_blob_sha1"]==sha,
             "frozen original source file bytes changed: "+path)
        fetched[path]=raw.decode("utf-8")
    ada=fetched["src/normative_oracle.adb"]
    source=fetched["src/month_weaving.adb"]
    python=fetched["tests/normative_reference.py"]
    need("Shifted : constant Answer_Stream" in ada
         and "First => Answer_At (Stream, B (I - 1))" in ada
         and "Choose_Rank (Shifted, B (Slots))" in ada
         and "Month_Weaving.From_Choices (Lengths, Tickets)" in ada,
         "Ada selector not proven one shifted rank per ticket")
    need("function From_Choices" in source
         and "Output (Pos) := J;" in source
         and "Remains (J) := Lengths (J) - 2" in source,
         "Ada two-rail source changed")
    need("family = MonthWeavingFamily(month_lengths)" in python
         and "rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())" in python
         and "return family.unrank1(rank)" in python,
         "Python source global rank over full family changed")
    return {"pinned_source_blobs":len(fetched),
            "Ada_rank_per_shifted_interior_ticket":True,
            "Python_one_rank_for_all_legal_weavings":True,
            "exact_foundation_intermediate_values_in_source":False,
            "original_Fct_invocations_here":0}

def archive_metadata(m,gh):
    validate(m)
    out=[]
    for row in m["archived_original_runs"]:
        run=gh.get("/repos/"+REPO+"/actions/runs/"+str(row["run_id"]))
        need(run.get("id")==row["run_id"] and run.get("status")=="completed"
             and run.get("conclusion")=="success",
             "original prior native witness not completed/success")
        items=gh.get("/repos/"+REPO+"/actions/runs/"+str(row["run_id"])+"/artifacts?per_page=100")
        need(isinstance(items.get("total_count"),int)
             and items["total_count"]<=100 and isinstance(items.get("artifacts"),list),
             "historical artifact listing incomplete")
        artifact=[a for a in items["artifacts"] if a.get("id")==row["artifact_id"]]
        need(len(artifact)==1
             and artifact[0].get("digest")=="sha256:"+row["sha256"]
             and artifact[0].get("expired") is False,
             "original historical witness ZIP missing/stale")
        out.append({"role":row["role"],"run_id":row["run_id"],
                    "artifact_id":row["artifact_id"],"zip_sha256":row["sha256"],
                    "examined_historical_zip_bytes_here":False})
    return out

def read_archives(m,directory):
    """Explicit local opt-in. Does not run any original source or native executable."""
    validate(m)
    need(directory.is_dir(),"archive folder unavailable")
    results=[]
    for row in m["archived_original_runs"]:
        path=directory/row["file"]
        need(path.is_file(),"original ZIP not mounted: "+row["file"])
        raw=path.read_bytes()
        need(hashlib.sha256(raw).hexdigest()==row["sha256"],
             "original ZIP SHA-256 mismatch: "+row["role"])
        with zipfile.ZipFile(path) as z:
            names=z.namelist()
            need(len(names)==row["members"] and len(names)==len(set(names))
                 and z.testzip() is None,"archive member count, uniqueness or CRC failed")
            need(all(not x.startswith("/") and ".." not in x.split("/")
                     and "\\" not in x for x in names),
                 "unsafe historical ZIP member path")
            blob=z.read(row["receipt_file"])
            need(hashlib.sha256(blob).hexdigest()==row["receipt_sha256"],
                 "original native witness SHA mismatch")
            if row["role"] in ("ada","fortran"):
                line=blob.decode("utf-8").strip().split()
                need(len(line)==8 and int(line[1])==-15055671
                     and int(line[2])==-15055671,
                     "original native F(c,t) receipt coordinates invalid")
                numbers=tuple(map(int,line[3:]))
                expected_prefix="V103_ADA_ORIGINAL_FCT_NATIVE" if row["role"]=="ada" else "V106_FORTRAN_ORIGINAL_FCT_NATIVE"
                need(line[0]==expected_prefix,"native witness marker changed")
            else:
                record=json.loads(blob)
                need(int(record["calculation_day"])==-15055671
                     and int(record["target_day"])==-15055671,
                     "Python witness coordinates changed")
                numbers=tuple(int(record[k]) for k in
                   ("year","cutlet_index","day_in_cutlet","month_index","day_in_month"))
                ts=z.read(row["typescript_member"])
                need(hashlib.sha256(ts).hexdigest()==TS_MEMBER_SHA,
                     "original TypeScript native raw receipt changed")
                verdict=json.loads(z.read("v101-one-day-verdict-0.json"))
                need(tuple(int(x) for x in verdict["canonical_fields"])==numbers,
                     "old original TypeScript comparison does not match canonical tuple")
            need(numbers==tuple(row["observed"]),
                 "historical original source numeric tuple changed")
            binary=None
            if row["role"]=="fortran":
                binary=hashlib.sha256(z.read(row["binary_member"])).hexdigest()
                need(binary==FORTRAN_BINARY_SHA,
                     "original Fortran archived native executable changed")
            results.append({"role":row["role"],"zip_sha256_recomputed":row["sha256"],
               "zip_member_count":len(names),"crc_verified":True,
               "receipt_sha256_verified":row["receipt_sha256"],
               "original_recorded_fields":list(numbers),
               "embedded_native_binary_sha256_recomputed_without_execution":binary,
               "original_date_executions":0})
    need([x["original_recorded_fields"] for x in results]==[
         [5000,10,503,30,52],[5000,10,503,20,56],[5000,10,503,20,56]],
         "historical first difference not preserved")
    return results

def audit(m,gh,directory=None):
    validate(m)
    return {"schema":REPORT,"manifest_sha256":digest(m),
       "tiny_non_date_selector_discriminator":tiny_selector(m),
       "pinned_original_sources":source_check(m,gh),
       "original_completed_run_artifact_metadata":archive_metadata(m,gh),
       "original_archive_bytes_examined_this_execution":directory is not None,
       "historical_zip_byte_receipts":None if directory is None else read_archives(m,directory),
       "real_foundation_interior_ranks_proven":False,
       "two_structural_selector_differences_proven":True,
       "sole_numeric_cause_proven":False,
       "original_native_calls_new":0,"full_original_years_certified":0,
       "independent_algorithms_certified":0,
       "dispatch_authorized":False}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--manifest",required=True,type=Path)
    p.add_argument("--output",required=True,type=Path)
    p.add_argument("--archives-dir",type=Path)
    a=p.parse_args()
    result=audit(parse_json(a.manifest.read_bytes()),
                 GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")),a.archives_dir)
    with a.output.open("xb") as f:f.write(canonical(result)+b"\n")
    print(json.dumps({"source_blobs":result["pinned_original_sources"]["pinned_source_blobs"],
       "historical_run_artifacts":len(result["original_completed_run_artifact_metadata"]),
       "original_archives_read_this_execution":result["original_archive_bytes_examined_this_execution"],
       "two_structural_selector_differences_proven":True,
       "original_date_executions":0,"full_original_years_certified":0,
       "sole_numeric_cause_proven":False},sort_keys=True))

if __name__=="__main__":main()
