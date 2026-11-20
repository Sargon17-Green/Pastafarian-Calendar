#!/usr/bin/env python3
"""v136 read-only GitHub Actions artifact census and optional ZIP binary hashing.

No subprocess, compiler, linker, original F(c,t), dynamic execution or
scientific Soak promotion. A native prebuilt package from a differing source
commit is NOT the Seer Next experimental baseline/candidate binary.
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

SCHEMA="PASTAFARI_SOAK_SEER_BINARY_CANDIDATE_CENSUS_V136/1"
REPORT="PASTAFARI_SOAK_SEER_BINARY_CANDIDATE_CENSUS_REPORT_V136/1"
REPO="Sargon-17-Green/Pastafarian-Calendar-Seer"
HEAD="4716594fc98fa882a9401455ae56f30895518e8c"
FROZEN="866e9bbff59399310416ae25de1b664f9b6c3124"
RUN_IDS=(42423264458,42423264025,42423263936,42423263979,
         42423263866,42423263952,42423264010,42423263869,
         42423263856,42423263953,42423259653)
EXPECTED_ARTIFACTS={
 42423263979:(13593748655,),
 42423263952:(13595475137,13594347792,13594263914),
 42423264010:(13594935213,13594610534),
 42423263856:(13595090031,13594237378,13594209238,13593793721),
 42423263953:(13594516120,13594224485),
 42423259653:(13595506317,13595075588)}
PREBUILT_RUN=42423263952
PREBUILT_ID=13594347792
PREBUILT_NAME="native-linux-x64-29d18adba6844728c6be8331be181ea00b669eb5"
PREBUILT_SHA="ed3c380c3790e22e86e269dc3afc5afb95f2ef8c6b66631834e113557fbc1770"
INTERNAL_SOURCE="29d18adba6844728c6be8331be181ea00b669eb5"
EXPERIMENT_RUN=42423259653
EXPERIMENT_ID=13595506317
EXPERIMENT_SHA="ed4757a6f9dde8b5302a73413102cba88fef8f02ac70875b309c2ebea9a56bab"
EXPERIMENT_NAME="seer-next-native-ab-linux-avx2"
ORIGINAL_HASHES={
 "baseline":"8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b",
 "candidate":"46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8",
}
BINARIES={
 "bin/seer_engine_service":"e8b2db999880ca1112e87cd09337b4a6e8fa6eace2aa88ca1511fb9581d5a8db",
 "bin/seer_year_batch":"c4e01a23ac57410165e735353458689fb6cbfd94460f235d5a06f5c563ba9ff5",
 "bin/seer_year_locator":"578cb40495778e8a5f1287786cbbc471d7564faf9c00bed7eca626d312812321",
 "bin/seer_year_structure":"b121b83251dc6580540ba6d712f70ab829b4803e05fc2e2a92095f6545726819",
}

def need(cond,message):
    if not cond: raise ValueError(message)

def validate(manifest):
    need(type(manifest) is dict and manifest.get("schema")==SCHEMA
         and manifest.get("repo")==REPO
         and manifest.get("exact_ci_head")==HEAD
         and manifest.get("frozen_seer_head")==FROZEN
         and manifest.get("claim_scope")==
         "EXACT_CI_RUN_ARTIFACT_METADATA_AND_ONE_DOWNLOADED_PREBUILT_BINARY_ZIP_NOT_ORIGINAL_SEER_NEXT_BINARY",
         "v136 source and evidence scope changed")
    need(manifest.get("ci_run_ids")==list(RUN_IDS),
         "v136 exact CI run IDs changed")
    need(manifest.get("expected_artifacts")=={
      str(k):list(v) for k,v in EXPECTED_ARTIFACTS.items()},
      "v136 known historical artifact IDs changed")
    need(manifest.get("native_linux_artifact")=={
      "run_id":PREBUILT_RUN,"id":PREBUILT_ID,"name":PREBUILT_NAME,
      "zip_bytes":4900691,"zip_sha256":PREBUILT_SHA,
      "package":"pastafarian-calendar-seer-linux-x64",
      "version":"0.2.5","embedded_source_commit":INTERNAL_SOURCE,
      "backend":"portable","binary_files":BINARIES},
      "native prebuilt identity/manifest was substituted")
    need(manifest.get("historical_trial")=={
      "run_id":EXPERIMENT_RUN,"id":EXPERIMENT_ID,"name":EXPERIMENT_NAME,
      "zip_sha256":EXPERIMENT_SHA,
      "reported_binary_hashes":ORIGINAL_HASHES},
      "Seer Next experimental archived SHA lock changed")
    need(all(manifest.get(k) is True for k in (
      "full_exact_commit_artifact_inventory_may_be_incomplete_if_artifacts_expire",
      "no_original_date_calls","no_new_compiler_or_linker",
      "no_binary_bytes_from_original_Seer_Next_experiment_verified"))
      and manifest.get("independent_algorithms_certified")==0
      and manifest.get("original_full_years_certified")==0
      and manifest.get("soak_dispatch_authorized") is False,
      "v136 native dispatch or Soak promotion forbidden")

def audit_online(gh,manifest):
    validate(manifest)
    # Search at exact Git commit: no transfer of status from neighboring runs.
    resp=gh.get("/repos/"+REPO+"/actions/runs?head_sha="+HEAD+"&per_page=100")
    need(type(resp) is dict and type(resp.get("total_count")) is int
         and resp["total_count"]<=100 and type(resp.get("workflow_runs")) is list,
         "run search pagination or response incomplete")
    runs={item["id"]:item for item in resp["workflow_runs"]}
    need(set(RUN_IDS).issubset(runs),"one or more frozen CI runs missing")
    run_statuses={}
    artifact_rows=[]
    for rid in RUN_IDS:
        run=runs[rid]
        need(run.get("head_sha")==HEAD
             and run.get("status")=="completed"
             and run.get("conclusion")=="success",
             "run completion or exact commit mismatch")
        run_statuses[str(rid)]={"status":"completed/success","name":run.get("name")}
        response=gh.get("/repos/"+REPO+"/actions/runs/"+str(rid)+"/artifacts?per_page=100")
        need(type(response) is dict and
             type(response.get("total_count")) is int and
             response["total_count"]<=100 and
             type(response.get("artifacts")) is list,
             "artifact inventory not complete/paginated")
        observed={x["id"]:x for x in response["artifacts"]}
        need(len(observed)==len(response["artifacts"]),
             "duplicate artifact in run inventory")
        for aid in EXPECTED_ARTIFACTS.get(rid,()):
            if aid not in observed:
                artifact_rows.append({
                    "run_id":rid,"artifact_id":aid,"status":"NO_LONGER_RETURNED",
                    "executables_examined":False})
                continue
            a=observed[aid]
            artifact_rows.append({
               "run_id":rid,"artifact_id":aid,
               "name":a.get("name"),"digest":a.get("digest"),
               "zip_bytes":a.get("size_in_bytes"),
               "expired":a.get("expired"),
               "status":"VISIBLE_METADATA_ONLY",
               "executables_examined":False
            })
    byid={v["artifact_id"]:v for v in artifact_rows}
    for aid,name,expectedhash,expectedrun,expectedbytes in (
       (PREBUILT_ID,PREBUILT_NAME,PREBUILT_SHA,PREBUILT_RUN,4900691),
       (EXPERIMENT_ID,EXPERIMENT_NAME,EXPERIMENT_SHA,EXPERIMENT_RUN,206012)):
        e=byid.get(aid)
        need(e and e.get("run_id")==expectedrun
             and e.get("status")=="VISIBLE_METADATA_ONLY"
             and e.get("name")==name
             and e.get("digest")=="sha256:"+expectedhash
             and e.get("zip_bytes")==expectedbytes
             and e.get("expired") is False,
             "target artifact unavailable or hash/identity changed")
    return {
       "run_count_at_exact_head":len(RUN_IDS),
       "all_original_run_metadata_completed_success":True,
       "listed_artifact_ids":len(artifact_rows),
       "visible_artifact_ids":sum(v["status"]=="VISIBLE_METADATA_ONLY" for v in artifact_rows),
       "run_statuses":run_statuses,
       "artifacts":artifact_rows,
       "prebuilt_artifact_from_different_internal_source_commit":True,
       "experimental_archive_not_claimed_to_include_executable":True,
       "binary_bytes_downloaded_by_this_remote_metadata_scan":False
    }

def scan_zip(manifest,data):
    validate(manifest)
    need(type(data) is bytes and len(data)==4900691
         and hashlib.sha256(data).hexdigest()==PREBUILT_SHA,
         "prebuilt ZIP bytes do not match immutable expected SHA")
    try: archive=zipfile.ZipFile(io.BytesIO(data))
    except (ValueError,zipfile.BadZipFile) as e:
        raise ValueError("prebuilt ZIP invalid") from e
    with archive:
        items=archive.infolist()
        names=[v.filename for v in items]
        need(len(items)==13 and len(set(names))==13
             and all(not p.startswith("/") and ".." not in p.split("/")
                     and "\\" not in p and p for p in names),
             "prebuilt ZIP file paths unsafe/duplicate/unexpected count")
        need(all(not z.is_dir() and z.file_size<10000000 for z in items),
             "unsupported large/directory zip member")
        need(archive.testzip() is None,"prebuilt ZIP CRC failed")
        m=json.loads(archive.read("runtime-manifest.json"))
        package=json.loads(archive.read("package.json"))
        need(m.get("sourceCommit")==INTERNAL_SOURCE
             and m.get("backend")=="portable"
             and m.get("version")=="0.2.5"
             and m.get("package")=="pastafarian-calendar-seer-linux-x64"
             and package.get("version")=="0.2.5",
             "embedded runtime provenance differs from manifest")
        need(sorted(m["binaries"])==sorted(p.split("/")[-1] for p in BINARIES),
             "runtime manifest expected executable paths differ")
        rows=[]
        for filename,expected in BINARIES.items():
            raw=archive.read(filename)
            actual=hashlib.sha256(raw).hexdigest()
            need(actual==expected and m["files"].get(filename.split("/")[-1])==actual,
                 "prebuilt executable SHA differs from its ZIP/runtime manifest")
            rows.append({
              "path":filename,
              "bytes":len(raw),
              "sha256_recomputed":actual,
              "matches_reported_seer_next_baseline":actual==ORIGINAL_HASHES["baseline"],
              "matches_reported_seer_next_candidate":actual==ORIGINAL_HASHES["candidate"],
              "runtime_source_commit":INTERNAL_SOURCE
            })
        need(not any(x["matches_reported_seer_next_baseline"]
                     or x["matches_reported_seer_next_candidate"] for x in rows),
             "prebuilt runtime unexpectedly matches an original trial hash: reclassify evidence manually")
        return {
          "original_zip_sha256_verified":PREBUILT_SHA,
          "zip_crc_verified":True,
          "zip_entry_count":13,
          "embedded_runtime_source_commit":INTERNAL_SOURCE,
          "runtime_source_commit_matches_experimental_ci_commit":False,
          "executable_files_rehashed":len(rows),
          "matched_experimental_baseline_or_candidate_count":0,
          "executables":rows,
          "any_binary_from_historical_seer_next_trial_certified":False
        }

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--manifest",required=True,type=Path)
    p.add_argument("--prebuilt-zip",type=Path)
    p.add_argument("--scan-zip-only",action="store_true")
    p.add_argument("--output",required=True,type=Path)
    a=p.parse_args()
    m=parse_json(a.manifest.read_bytes())
    need(not a.scan_zip_only or a.prebuilt_zip is not None,
         "scan-zip-only requires exact ZIP bytes")
    metadata=None if a.scan_zip_only else audit_online(
        GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")),m)
    binary=None if a.prebuilt_zip is None else scan_zip(m,a.prebuilt_zip.read_bytes())
    report={"schema":REPORT,"manifest_sha256":digest(m),
      "read_only_live_exact_CI_artifact_inventory":metadata,
      "local_prebuilt_executable_scan":binary,
      "candidate_executable_bytes_examined_here":binary is not None,
      "Seer_Next_original_executable_bytes_verified":False,
      "original_date_calls":0,"new_compiler_or_linker_calls":0,
      "independent_algorithms_certified":0,"original_full_years_certified":0,
      "soak_dispatch_authorized":False,"scientific_soak_10000_pass":False}
    with a.output.open("xb") as f:f.write(canonical(report)+b"\n")
    print(json.dumps({"ci_run_count":len(RUN_IDS) if metadata else None,
      "metadata_artifacts_visible":metadata["visible_artifact_ids"] if metadata else None,
      "prebuilt_executables_rehashed":len(binary["executables"]) if binary else None,
      "matching_experimental_hashes":0 if binary else None,
      "original_full_years_certified":0,
      "soak_dispatch_authorized":False},sort_keys=True))

if __name__=="__main__":main()
