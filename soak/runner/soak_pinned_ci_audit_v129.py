#!/usr/bin/env python3
"""Pure read-only GitHub Actions run/job attestation *status* lookup.

Verifies a historical job completed successfully on the *exact* original
locked commit. Does not verify what native executable ran, native stdout,
algorithmic independence, or whole-year Soak. No F(c,t) calls.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any

from soak_source_census_v129 import (
    GitHubReadOnly, APIProblem, safe_repo, sha40,
)
from soak_scope_coverage_v127 import canonical, digest, parse_json

INDEX_SCHEMA="PASTAFARI_SOAK_PINNED_SOURCE_CI_JOB_INDEX_V129/1"
REPORT_SCHEMA="PASTAFARI_SOAK_PINNED_CI_JOB_OBSERVATIONS_V129/1"
CLAIM_SCOPE="PINNED_CI_JOB_STATUS_NOT_NATIVE_EXECUTION"


def validate_index(index: dict, locks: dict) -> list[dict]:
    if type(index) is not dict or set(index) != {
        "schema", "frozen_source_locks_path", "interpretation", "claims",
        "full_year_verified", "native_execution_attested",
        "independent_algorithms_certified"
    } or index["schema"] != INDEX_SCHEMA:
        raise ValueError("invalid historical pinned CI index")
    if any(index[key] is not False for key in (
            "full_year_verified","native_execution_attested",
            "independent_algorithms_certified")):
        raise ValueError("CI index attempted to self-authorize scientific success")
    if index["frozen_source_locks_path"] != (
            "soak/control/pilot_two_engine_source_locks_v001.json"):
        raise ValueError("pinned lock source path differs")
    if type(index["claims"]) is not list or not index["claims"]:
        raise ValueError("CI evidence index has no claims")
    locked = {item["id"]: item for item in locks["engines"]}
    found = set()
    for row in index["claims"]:
        if type(row) is not dict or set(row) != {
            "record_id", "repository", "source_commit", "run_id", "job_id",
            "required_successful_steps", "claim_scope"
        }:
            raise ValueError("wrong pinned job assertion schema")
        rid = row["record_id"]
        if rid in found or rid not in locked:
            raise ValueError("duplicate or unpinned source CI evidence ID")
        found.add(rid)
        pin = locked[rid]
        if (safe_repo(row["repository"]) != pin["repository"]
            or sha40(row["source_commit"]) != pin["commit"]):
            raise ValueError("CI evidence source not locked to original commit")
        if row["claim_scope"] != CLAIM_SCOPE:
            raise ValueError("CI status cannot claim native date correctness")
        for key in ("run_id","job_id"):
            if type(row[key]) is not int or row[key] <= 0:
                raise ValueError("invalid GitHub Actions integer ID")
        steps = row["required_successful_steps"]
        if (type(steps) is not list or not steps or
                any(type(s) is not str or not s.strip() for s in steps)
                or len(set(steps)) != len(steps)):
            raise ValueError("missing or duplicate required CI step labels")
    return index["claims"]


def check_pinned_ci_run(gh, claim: dict) -> dict:
    repo, run_id, job_id = claim["repository"], claim["run_id"], claim["job_id"]
    out = {"record_id":claim["record_id"],"repository":repo,
           "source_commit":claim["source_commit"],"run_id":run_id,"job_id":job_id,
           "ci_status":"CI_JOB_NOT_VERIFIED",
           "workflow_run_status":None,"job_status":None,
           "matching_step_count":0,
           "native_full_date_execution_proven":False,
           "original_stdout_attested":False,
           "original_full_years_certified":0,
           "eligible_for_soak":False}
    try:
        run = gh.get("/repos/" + repo + "/actions/runs/" + str(run_id))
        if not isinstance(run, dict):
            raise APIProblem("INVALID_RUN_RESPONSE")
        out["workflow_run_status"]=str(run.get("status"))+"/"+str(run.get("conclusion"))
        if (run.get("id") != run_id or run.get("head_sha") != claim["source_commit"]
            or run.get("repository",{}).get("full_name") != repo
            or run.get("event") != "push"
            or run.get("status") != "completed" or run.get("conclusion") != "success"):
            out["ci_status"]="RUN_METADATA_DOES_NOT_MATCH_SOURCE_LOCK"
            return out
        # Use immutable run ID; do not infer the job from its human label.
        jobs = gh.get("/repos/" + repo + "/actions/runs/" + str(run_id)
                      + "/jobs?per_page=100")
        if not isinstance(jobs,dict) or type(jobs.get("total_count")) is not int:
            raise APIProblem("INVALID_JOB_LIST")
        if jobs["total_count"] > 100 or type(jobs.get("jobs")) is not list:
            raise APIProblem("JOB_PAGINATION_REQUIRED")
        matches=[j for j in jobs["jobs"] if j.get("id")==job_id]
        if len(matches)!=1:
            out["ci_status"]="PINNED_JOB_NOT_PRESENT_IN_RUN"
            return out
        job=matches[0]
        out["job_status"]=str(job.get("status"))+"/"+str(job.get("conclusion"))
        if (job.get("run_id") != run_id or
            job.get("status") != "completed" or
            job.get("conclusion") != "success"):
            out["ci_status"]="JOB_NOT_COMPLETED_SUCCESSFULLY"
            return out
        steps=job.get("steps")
        if not isinstance(steps,list):
            out["ci_status"]="JOB_STEPS_NOT_AVAILABLE"
            return out
        step_map={}
        for step in steps:
            name=step.get("name")
            if type(name) is not str or name in step_map:
                out["ci_status"]="AMBIGUOUS_JOB_STEPS"
                return out
            step_map[name]=step
        matched=sum(step_map.get(step,{}).get("status")=="completed"
                    and step_map[step].get("conclusion")=="success"
                    for step in claim["required_successful_steps"])
        out["matching_step_count"]=matched
        if matched != len(claim["required_successful_steps"]):
            out["ci_status"]="REQUIRED_JOB_STEP_MISSING_OR_NOT_SUCCESS"
            return out
        out["ci_status"]="PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED"
        return out
    except APIProblem as exc:
        out["ci_status"]="CI_API_UNAVAILABLE_"+exc.code
        return out


def audit(index:dict, locks:dict, source_census:dict, gh)->dict:
    claims=validate_index(index,locks)
    if (source_census.get("schema")!="PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"
        or source_census.get("frozen_lock_sha256")!=digest(locks)
        or source_census.get("soak_dispatch_authorized") is not False
        or source_census.get("official_years_certified")!=0):
        raise ValueError("CI run index not linked to a fail-closed source census")
    observed_by_id={r["record_id"]:r for r in source_census["records"]}
    if len(observed_by_id)!=len(source_census["records"]):
        raise ValueError("duplicate source census observations")
    observations=[]
    for row in claims:
        previous=observed_by_id.get(row["record_id"])
        if previous is None or previous.get("locked_commit")!=row["source_commit"]:
            raise ValueError("CI evidence entry not linked to frozen source census")
        result=check_pinned_ci_run(gh,row)
        result["pinned_source_sha_observation"]=previous["frozen_source_lock_status"]
        result["combined_source_ci_status"]=(
            "SOURCE_LOCK_AND_HISTORICAL_CI_STATUS_OBSERVED"
            if previous["frozen_source_lock_status"]=="FROZEN_SOURCES_SHA_LOCK_PASS"
            and result["ci_status"]=="PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED"
            else "INCOMPLETE_SOURCE_OR_CI_EVIDENCE")
        observations.append(result)
    return {
        "schema":REPORT_SCHEMA,
        "source_census_sha256":digest(source_census),
        "frozen_lock_sha256":digest(locks),
        "ci_index_sha256":digest(index),
        "claims_checked":len(observations),
        "observations":observations,
        "native_date_calls":0,
        "original_full_years_certified":0,
        "independent_algorithms_certified":False,
        "soak_dispatch_authorized":False,
        "limitation":"Completed CI job steps do not attest original F(c,t) process or raw stdout."
    }


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ci-index",required=True,type=Path)
    parser.add_argument("--frozen-locks",required=True,type=Path)
    parser.add_argument("--source-census",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    args=parser.parse_args()
    index,locks,census=[parse_json(p.read_bytes()) for p in
                        (args.ci_index,args.frozen_locks,args.source_census)]
    result=audit(index,locks,census,GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with args.output.open("xb") as stream:
        stream.write(canonical(result)+b"\n")
    print(json.dumps({
        "schema":result["schema"],"claims_checked":result["claims_checked"],
        "ci_status_by_record":{o["record_id"]:o["combined_source_ci_status"]
                               for o in result["observations"]},
        "original_full_years_certified":0,"soak_dispatch_authorized":False
    },sort_keys=True))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
