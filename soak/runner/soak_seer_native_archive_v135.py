#!/usr/bin/env python3
"""Seer historical binary-hash receipt and source-tree ancestry audit.

Read-only repository and GitHub Actions metadata. Optional historical ZIP
for byte-exact verification of 34 JSON members and two recorded binary hashes.
Neither recorded binary hash is proof that binary bytes remain retrievable.
No compiler, linker, original F(c,t) process, or Soak year is executed.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import zipfile

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_SEER_NATIVE_ARCHIVE_V135/1"
REPORT="PASTAFARI_SOAK_SEER_NATIVE_ARCHIVE_WITNESS_V135/1"
REPO="Sargon-17-Green/Pastafarian-Calendar-Seer"
FROZEN="866e9bbff59399310416ae25de1b664f9b6c3124"
CI_SHA="4716594fc98fa882a9401455ae56f30895518e8c"
RUN_ID=42423259653
JOB_ID=128556040187
ARTIFACT_ID=13595506317
ARTIFACT_NAME="seer-next-native-ab-linux-avx2"
ARTIFACT_SHA="ed4757a6f9dde8b5302a73413102cba88fef8f02ac70875b309c2ebea9a56bab"
SCRIPT="research/seer-next/scripts/compare_candidate.mjs"
CI_STEPS=[
  "Build unchanged baseline",
  "Build isolated experimental candidate",
  "Build isolated hybrid day-plus-year cache candidate",
  "Verify hybrid and original against independent canonical oracle",
]

def check(ok,message):
    if not ok:raise ValueError(message)

def validate_manifest(m):
    check(type(m) is dict and m.get("schema")==SCHEMA and
          m.get("seer_repo")==REPO and
          m.get("frozen_commit")==FROZEN and
          m.get("actual_ci_commit")==CI_SHA and
          m.get("evidence_scope")==
          "HISTORIC_CI_ZIP_BYTES_AND_RECORDED_BINARY_HASHES_NOT_SOAK",
          "frozen source manifest identity changed")
    g=m["git_compare"]
    check(g=={
      "ahead_by":2,"behind_by":0,"common_blob_count":1177,
      "source_and_non_results_blob_count":561,
      "only_frozen_results_blob_count":38,
      "changed_common_blob_count":0,
      "all_added_files_under":"research/seer-next/results/"},
      "Seer non-result source equivalence contract changed")
    ci=m["historical_run"]
    check(ci=={"id":RUN_ID,"job_id":JOB_ID,
      "status":"completed","conclusion":"success",
      "required_successful_steps":CI_STEPS},
      "Seer original historical completed job identity changed")
    z=m["archive"]
    check(z=={
      "artifact_id":ARTIFACT_ID,"name":ARTIFACT_NAME,
      "zip_sha256":ARTIFACT_SHA,
      "zip_bytes":206012,"entry_count":34,"uncompressed_bytes":2120061,
      "zip_crc32_all_entries_checked":True,"all_json":True,
      "contains_native_executable_binary":False},
      "Seer original archive hash or binary-absence lock changed")
    files=m["files"]
    check(set(files)=={"ab.json","full-year-512.json","full-year-warm-cold.json"},
          "target original JSON witness set changed")
    ab=files["ab.json"]
    check(ab=={
      "sha256":"62f2c3f44f0638f56864c4a4f08ebd738f5ba555f2226464f96d03124ada78c7",
      "schema":"seer-next-full-year-memo-ab-v1",
      "reported_baseline_binary_sha256":"8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b",
      "reported_candidate_binary_sha256":"46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8",
      "binary_hash_generation_script":SCRIPT,
      "binary_hash_generation_source_blob":"d0b3a9e139c5e41b057eafb2e332914a72a189b1",
      "binary_hash_computed_in_script_via_file_stream":True},
      "original binary SHA receipt changed")
    check(files["full-year-512.json"]=={
      "sha256":"8e701a3f3b49b87cc1195e12c6af75f62dbb0fece48b4b801baf7c56cc8263b7",
      "schema":"seer-next-full-year-512-parity-v1",
      "full_year_comparisons":6,
      "all_uncapped_full_replies_equal":True},
      "original finite full-year parity receipt changed")
    check(files["full-year-warm-cold.json"]=={
      "sha256":"1ae21f9d4b9ea8d00c46954b03be943f272f305e61b777975c7c40a99e5926c0",
      "schema":"seer-next-full-year-warm-cold-v1",
      "complete_full_json_parity":True},
      "original warm/cold parity receipt changed")
    check(all(m.get(k) is True for k in (
      "no_original_native_Fct_invocation","no_new_compiler_or_linker_invocation",
      "reported_binary_hashes_do_not_equal_binary_bytes_rechecked",
      "historical_Seer_full_year_checks_do_not_count_as_10k_original_full_year_soak"
      )) and m.get("independent_algorithms_certified")==0
      and m.get("original_full_years_certified")==0
      and m.get("soak_dispatch_authorized") is False,
      "v135 native and scientific stop state mutated")

def verify_archive(m,data):
    validate_manifest(m)
    check(type(data) is bytes and len(data)==m["archive"]["zip_bytes"]
          and hashlib.sha256(data).hexdigest()==ARTIFACT_SHA,
          "archive full ZIP bytes/digest mismatch")
    try:
        f=zipfile.ZipFile(io.BytesIO(data))
    except (zipfile.BadZipFile,ValueError) as exc:
        raise ValueError("invalid historical ZIP") from exc
    with f:
        items=f.infolist()
        names=[item.filename for item in items]
        check(len(items)==34 and len(set(names))==34
              and all(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*\.json",n) for n in names)
              and sum(x.file_size for x in items)==2120061,
              "archive entries unsafe/duplicate or changed")
        check(all(not item.is_dir() and item.file_size<=1024*1024 for item in items),
              "archive content not finite JSON members")
        check(f.testzip() is None,"archive CRC mismatch")
        proof={}
        for item in items:
            b=f.read(item)
            try: parsed=json.loads(b)
            except (UnicodeError,ValueError) as exc:
                raise ValueError("historical member is not JSON: "+item.filename) from exc
            check(type(parsed) is dict,"nonobject historical JSON")
            proof[item.filename]={"sha256":hashlib.sha256(b).hexdigest(),
                                  "bytes":len(b),
                                  "schema":parsed.get("schema")}
        for name,settings in m["files"].items():
            check(proof[name]["sha256"]==settings["sha256"] and
                  proof[name]["schema"]==settings["schema"],
                  "canonical member digest/schema mismatch: "+name)
        ab=json.loads(f.read("ab.json"))
        check(ab.get("baselineBinarySHA256")==m["files"]["ab.json"]["reported_baseline_binary_sha256"]
              and ab.get("candidateBinarySHA256")==m["files"]["ab.json"]["reported_candidate_binary_sha256"],
              "historically recorded binary hash fields mismatch")
        full=json.loads(f.read("full-year-512.json"))
        check(full.get("fullYearComparisons")==6
              and full.get("allUncappedFullRepliesEqual") is True,
              "six Seer comparison receipts changed")
        warm=json.loads(f.read("full-year-warm-cold.json"))
        check(warm.get("completeFullJsonParity") is True,
              "warm/cold finite JSON parity receipt changed")
    return {
       "archive_zip_sha256_recomputed":ARTIFACT_SHA,
       "archive_zip_crc_verified":True,
       "json_files_byte_verified":34,
       "aggregate_json_bytes":2120061,
       "members":proof,
       "reported_binary_sha256_count":2,
       "actual_binary_file_bytes_present":False,
       "binary_hashes_recomputed_from_executables":False,
       "six_seer_full_year_comparisons_are_not_original_10000_year_soak":True
    }

def verify_remote(m,gh):
    validate_manifest(m)
    a=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID))
    check(a.get("id")==RUN_ID and a.get("head_sha")==CI_SHA
          and a.get("status")=="completed" and a.get("conclusion")=="success"
          and a.get("event")=="push",
          "historic Seer run not completed success at exact CI head SHA")
    jobs=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID)+"/jobs?per_page=100")
    check(0<jobs.get("total_count",0)<=100 and type(jobs.get("jobs")) is list,
          "Seer job pagination missing")
    selected=[j for j in jobs["jobs"] if j.get("id")==JOB_ID]
    check(len(selected)==1 and selected[0].get("status")=="completed"
          and selected[0].get("conclusion")=="success",
          "Seer native job not complete success")
    steps={s["name"]:s.get("conclusion") for s in selected[0]["steps"]}
    check(all(steps.get(s)=="success" for s in CI_STEPS),
          "Seer candidate/hybrid build or oracle stage not successful")
    archive=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID)+"/artifacts?per_page=100")
    check(archive.get("total_count",101)<=100
          and type(archive.get("artifacts")) is list,
          "Seer artifact metadata incomplete")
    items=[x for x in archive["artifacts"] if x.get("id")==ARTIFACT_ID]
    check(len(items)==1 and items[0].get("name")==ARTIFACT_NAME
          and items[0].get("digest")=="sha256:"+ARTIFACT_SHA
          and items[0].get("size_in_bytes")==206012
          and items[0].get("expired") is False,
          "Seer historical archive no longer matches original SHA or is expired")
    t=[]
    for sha in [CI_SHA,FROZEN]:
        x=gh.get("/repos/"+REPO+"/git/trees/"+sha+"?recursive=1")
        check(x.get("truncated") is False and type(x.get("tree")) is list,
              "Seer recursive tree is truncated/incomplete")
        rows={v["path"]:(v.get("sha"),v.get("mode"),v.get("type"))
              for v in x["tree"] if v.get("type")=="blob"}
        check(len(rows)==len([v for v in x["tree"] if v.get("type")=="blob"]),
              "duplicate file path in Seer tree")
        t.append(rows)
    earlier,later=t
    common=earlier.keys()&later.keys()
    only_later=later.keys()-earlier.keys()
    only_earlier=earlier.keys()-later.keys()
    unchanged=sum(earlier[p]==later[p] for p in common)
    check(len(earlier)==1177 and len(later)==1215 and
          len(common)==1177 and unchanged==1177 and
          len(only_later)==38 and len(only_earlier)==0 and
          all(p.startswith("research/seer-next/results/") for p in only_later)
          and len([p for p in earlier if not p.startswith("research/seer-next/results/")])==561,
          "Seer frozen revision differs outside archived CI result files")
    script,proof=checked_blob(gh,REPO,CI_SHA,SCRIPT)
    check(proof["git_blob_sha1"]==m["files"]["ab.json"]["binary_hash_generation_source_blob"],
          "Seer source that reported binary hashes changed")
    code=script.decode("utf-8")
    check("createHash('sha256')" in code and
          "baselineBinarySHA256:await sha256(src)" in code and
          "candidateBinarySHA256:await sha256(candidate)" in code
          and "createReadStream" in code,
          "Seer historic binary hash receipt not generated by file stream")
    return {"historical_CI_sha":CI_SHA,"frozen_commit":FROZEN,
       "successful_candidate_and_hybrid_job_id":JOB_ID,
       "source_git_blob_identical_to_CI_for_common_paths":1177,
       "identical_non_results_repository_files":561,
       "later_result_only_files":38,
       "historical_artifact_id":ARTIFACT_ID,
       "historical_artifact_digest_verified_by_GitHub_API":ARTIFACT_SHA,
       "binary_hash_reporter_source_sha1_verified":proof["git_blob_sha1"],
       "actual_binary_retrieved":False,
       "no_new_original_Fct_execution":True}

def audit(m,gh,archive=None):
    validate_manifest(m)
    remote=verify_remote(m,gh)
    local=None if archive is None else verify_archive(m,archive)
    return {
      "schema":REPORT,
      "manifest_sha256":digest(m),
      "read_only_cross_commit_ci_and_archive_metadata":remote,
      "original_archive_bytes_examined_in_this_execution":local is not None,
      "original_archive_zip_byte_report":local,
      "historical_binary_hashes_recorded_not_binaries_reexamined":2,
      "original_date_calls":0,"new_native_build_calls":0,
      "independent_algorithms_certified":0,"original_full_years_certified":0,
      "soak_dispatch_authorized":False,
      "scientific_soak_10000_pass":False
    }

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--manifest",type=Path,required=True)
    p.add_argument("--archive",type=Path)
    p.add_argument("--output",type=Path,required=True)
    args=p.parse_args()
    m=parse_json(args.manifest.read_bytes())
    result=audit(m,GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")),
                 args.archive.read_bytes() if args.archive else None)
    with args.output.open("xb") as f:f.write(canonical(result)+b"\n")
    print(json.dumps({"schema":REPORT,
        "historical_seer_ci_success":True,
        "identical_non_results_repo_blobs":561,
        "zip_bytes_verified_now":result["original_archive_bytes_examined_in_this_execution"],
        "reported_executable_hashes":2,
        "actual_executable_bytes_rechecked":False,
        "original_full_years_certified":0,
        "soak_dispatch_authorized":False},sort_keys=True))
if __name__=="__main__":
    main()
