#!/usr/bin/env python3
"""Read-only historical GitHub CI metadata and artifact-retention audit.

A successful build step is evidence of historical build completion, not a
reproducible binary with stable SHA. An artifact upload *log* is not a
currently downloadable artifact. This script NEVER compiles, links, invokes
original date converters, or credits any portion of the 10,000-year Soak.
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
import os
from pathlib import Path
import re
from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly,APIProblem
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_HISTORICAL_BINARY_RECEIPTS_INDEX_V134/1"
REPORT="PASTAFARI_SOAK_HISTORICAL_BINARY_RECEIPTS_V134/1"
REPO="Sargon17-Green/Pastafarian-Calendar"
SHA="1a1ea6a89f1f7a2cde9cba1f91aa1625a9284334"
SEER="Sargon-17-Green/Pastafarian-Calendar-Seer"
SEER_SHA="866e9bbff59399310416ae25de1b664f9b6c3124"
EXPECTED={
35640916185:{
 "job":106469736387,"path":".github/workflows/assembly-sahidic-stage56-final-audit.yml",
 "git_blob_sha1":"dcad15b59c95c7bfb1a042911cd231bcaf22b0aa",
 "artifact_name":"assembly-sahidic-stage56-audit-evidence","artifact_id":10659901058,
 "digest":"sha256:175b1ce82085340a73852d2b93123fd9639a9db576a230fb7b362336d2b4fea4",
 "steps":["Ⲡbuild ⲙⲡmonster","Ⲡsemantic/runtime audit ⲙⲡⲃⲁⲑⲙⲟⲥ 56","Ⲡstatic/scar audit"]},
35640916171:{
 "job":106469736990,"path":".github/workflows/assembly-sahidic-stage56-final-audit-closure.yml",
 "git_blob_sha1":"35a2cfcb5d8653ff2255edb083b0fe41157e0d76",
 "artifact_name":"assembly-sahidic-stage56-audit-closure-evidence",
 "artifact_id":10659366977,
 "digest":"sha256:e09c09a687e5335d0773779b70be27c7caf3beb9b851cd35f2cc9209d13da706",
 "steps":["Build","Stage56 semantic runtime audit","Static runtime audit"]}
}

def need(cond,msg):
    if not cond:raise ValueError(msg)

def validate(index,prior):
    need(type(index) is dict and set(index)=={
        "schema","parent_stage","source_commit_coptic","source_commit_seer",
        "evidence_scope","coptic","seer","no_native_build",
        "no_original_date_dispatch","auto_binary_attestation",
        "auto_independence_promotion","soak_dispatch_authorized"},
        "unexpected binary receipt index keys")
    need(index["schema"]==SCHEMA
         and index["parent_stage"]=="PASTAFARI_SOAK_STATIC_BUILD_GRAPH_REPORT_V133/1"
         and index["source_commit_coptic"]==SHA
         and index["source_commit_seer"]==SEER_SHA
         and index["evidence_scope"]==
         "HISTORICAL_GITHUB_RUN_JOB_AND_ARTIFACT_METADATA_ONLY_NO_BINARY_PROVENANCE",
         "historical source identity or evidence scope changed")
    need(index["no_native_build"] is True and
         index["no_original_date_dispatch"] is True and
         index["auto_binary_attestation"] is False and
         index["auto_independence_promotion"] is False and
         index["soak_dispatch_authorized"] is False,
         "forbidden escalation of native Soak")
    need(index["coptic"]["repository"]==REPO and
         type(index["coptic"]["workflows"]) is list and
         len(index["coptic"]["workflows"])==2,"invalid coptic run index")
    seen=set()
    for claim in index["coptic"]["workflows"]:
        rid=claim["run_id"]
        need(type(rid) is int and rid in EXPECTED and rid not in seen,
             "unexpected or duplicate historical run")
        seen.add(rid)
        c=EXPECTED[rid]
        need(claim["job_id"]==c["job"] and
             claim["workflow_path"]==c["path"] and
             claim["historical_upload_name"]==c["artifact_name"] and
             claim["historical_upload_artifact_id"]==c["artifact_id"] and
             claim["historical_zip_digest_from_job_log"]==c["digest"] and
             claim["expected_successful_steps"]==c["steps"],
             "historical run evidence lock changed")
    need(seen==set(EXPECTED),"missing pinned historical CI run")
    need(index["seer"]=={
        "repository":SEER,
        "research_branch":"research/seer-next-first-principles-2026-11-06",
        "workflow_path":".github/workflows/seer-next-experiment.yml",
        "observation":"NO_RUN_AT_EXACT_FROZEN_HEAD_SHA_IN_GITHUB_ACTIONS_SEARCH",
        "other_revision_ci_runs_do_not_attest_frozen_commit":True},
        "Seer frozen-run evidence scope changed")
    need(type(prior) is dict
         and prior.get("schema")=="PASTAFARI_SOAK_STATIC_BUILD_GRAPH_REPORT_V133/1"
         and prior.get("native_builds_executed")==0
         and prior.get("native_date_calls")==0
         and prior.get("original_full_years_certified")==0
         and prior.get("independent_algorithms_certified")==0
         and prior.get("soak_dispatch_authorized") is False
         and len(prior.get("assembly",{}).get("object_sources",[]))==8
         and len(prior.get("assembly",{}).get("extern_symbols",[]))==36
         and len(prior.get("seer",{}).get("services",[]))==2,
         "v133 source graph prerequisite not frozen")
    return True

def check_historical(index,prior,gh):
    validate(index,prior)
    observed=[]
    for claim in index["coptic"]["workflows"]:
        rid=claim["run_id"]
        spec=EXPECTED[rid]
        run=gh.get("/repos/"+REPO+"/actions/runs/"+str(rid))
        need(type(run) is dict and run.get("id")==rid
             and run.get("head_sha")==SHA
             and run.get("status")=="completed"
             and run.get("conclusion")=="success"
             and run.get("event")=="push",
             "historical run is not a completed success at frozen SHA")
        jobs=gh.get("/repos/"+REPO+"/actions/runs/"+str(rid)+"/jobs?per_page=100")
        need(type(jobs) is dict and type(jobs.get("total_count")) is int
             and 0<jobs["total_count"]<=100 and
             type(jobs.get("jobs")) is list,"historical job list unavailable")
        hits=[j for j in jobs["jobs"] if j.get("id")==spec["job"]]
        need(len(hits)==1,"historical pinned job not in run")
        job=hits[0]
        need(job.get("status")=="completed"
             and job.get("conclusion")=="success"
             and type(job.get("steps")) is list,
             "historical build job not completed/success")
        statuses={s["name"]:s.get("conclusion") for s in job["steps"]}
        need(all(statuses.get(n)=="success" for n in spec["steps"]),
             "historical required build/audit steps not all successful")
        src,hashes=checked_blob(gh,REPO,SHA,spec["path"])
        need(hashes["git_blob_sha1"]==spec["git_blob_sha1"],
             "original workflow bytes differ from pinned Git blob")
        text=src.decode("utf-8")
        need("uses: actions/upload-artifact@v4" in text
             and "name: "+spec["artifact_name"] in text
             and "path: audit_evidence/" in text
             and "retention-days: 30" in text,
             "workflow does not define historic evidence upload")
        artifacts=gh.get("/repos/"+REPO+"/actions/runs/"+str(rid)+"/artifacts?per_page=100")
        need(type(artifacts) is dict
             and type(artifacts.get("total_count")) is int
             and 0<=artifacts["total_count"]<=100
             and type(artifacts.get("artifacts")) is list,
             "historical artifact metadata missing/incomplete pagination")
        current=[a for a in artifacts["artifacts"]
                 if a.get("id")==spec["artifact_id"]
                 and a.get("name")==spec["artifact_name"]]
        status=("NO_CURRENT_ARTIFACT_RETURNED"
                if artifacts["total_count"]==0 else
                "ARTIFACT_METADATA_VISIBLE_NO_BINARY_ATTESTATION")
        observed.append({
            "run_id":rid,"job_id":spec["job"],
            "source_commit":SHA,"workflow_sha256":hashes["source_sha256"],
            "workflow_git_blob_sha1":hashes["git_blob_sha1"],
            "run_status":"completed/success",
            "job_status":"completed/success",
            "required_successful_steps":spec["steps"],
            "historical_upload_name_from_source":spec["artifact_name"],
            "historical_uploaded_artifact_id_from_prior_job_log":spec["artifact_id"],
            "historical_zip_sha256_from_prior_job_log":spec["digest"],
            "current_artifact_api_total":artifacts["total_count"],
            "pinned_artifact_metadata_currently_returned":len(current)==1,
            "current_artifact_status":status,
            "historical_job_log_bytes_in_current_report":False,
            "historical_binary_files_in_artifact_upload_path_verified":False,
            "binary_file_sha256_obtained":False,
            "nm_symbol_table_obtained":False,
            "linked_binary_identified":False,
            "original_full_date_Fct_stdout_verified":False
        })
    seer=gh.get("/repos/"+SEER+"/actions/runs?head_sha="+SEER_SHA+"&per_page=100")
    need(type(seer) is dict and type(seer.get("total_count")) is int
         and type(seer.get("workflow_runs")) is list,
         "Seer exact-commit action search unavailable")
    need(seer["total_count"]<=100,"Seer exact-commit pagination required")
    matches=[r for r in seer["workflow_runs"] if r.get("head_sha")==SEER_SHA]
    status=("NO_EXACT_COMMIT_CI_RUN_RETURNED" if not matches
            else "EXACT_COMMIT_RUN_METADATA_PRESENT_NOT_BINARY_ATTESTED")
    return {
      "schema":REPORT,
      "v133_graph_sha256":digest(prior),
      "index_sha256":digest(index),
      "coptic":{
        "source_commit":SHA,"historical_completed_success_run_count":len(observed),
        "historical_successful_build_job_receipts":observed,
        "current_retrievable_binary_digest_receipts":0,
        "source_workflow_upload_scope":"audit_evidence/ NOT build/",
        "historical_GitHub_uploaded_archives_are_not_native_binary_identity":True
      },
      "seer":{
        "source_commit":SEER_SHA,
        "github_exact_sha_run_search_count":seer["total_count"],
        "matching_run_ids":[x["id"] for x in matches],
        "classification":status,
        "other_commit_CI_is_not_frozen_source_execution_evidence":True,
        "frozen_commit_binary_sha256_attested":False
      },
      "native_date_calls":0,
      "new_native_builds_or_linker_calls":0,
      "binary_identity_for_scientific_soak_certified":0,
      "independent_algorithms_certified":0,
      "original_full_years_certified":0,
      "soak_dispatch_authorized":False,
      "scientific_soak_10000_pass":False,
      "caveat":"Historical completed build jobs are not exact executable binary SHA/ABI, original Fct stdout or a completed full year. Old artifact upload in logs does not prove present retrievability."
    }

def main():
    p=argparse.ArgumentParser()
    for k in ("index","v133-report","output"):p.add_argument("--"+k,required=True,type=Path)
    a=p.parse_args()
    x=check_historical(parse_json(a.index.read_bytes()),
                       parse_json(a.v133_report.read_bytes()),
                       GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with a.output.open("xb") as f:f.write(canonical(x)+b"\n")
    print(json.dumps({"schema":REPORT,
        "assembly_completed_success_runs":x["coptic"]["historical_completed_success_run_count"],
        "assembly_artifact_availability":[r["current_artifact_status"] for r in x["coptic"]["historical_successful_build_job_receipts"]],
        "seer_exact_sha_run_count":x["seer"]["github_exact_sha_run_search_count"],
        "binary_identity_for_scientific_soak_certified":0,
        "original_full_years_certified":0,
        "soak_dispatch_authorized":False},sort_keys=True))

if __name__=="__main__":
    main()
