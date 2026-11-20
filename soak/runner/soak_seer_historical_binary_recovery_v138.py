#!/usr/bin/env python3
"""Historical Seer build provenance and absent-original-binary receipt (v138).

All operations are static source/API reads, optionally one historical job log
read; never launch a native process or a date engine. A recorded hash, a
source SHA, and a build-completed job do not form executable-byte provenance.
"""
from __future__ import annotations

import argparse
import json
import os
import re
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

SCHEMA="PASTAFARI_SOAK_SEER_HISTORICAL_BINARY_RECOVERY_CONTRACT_V138/1"
REPORT="PASTAFARI_SOAK_SEER_HISTORICAL_BINARY_RECOVERY_REPORT_V138/1"
REPO="Sargon-17-Green/Pastafarian-Calendar-Seer"
CI_SHA="4716594fc98fa882a9401455ae56f30895518e8c"
FROZEN="866e9bbff59399310416ae25de1b664f9b6c3124"
RUN_ID=42423259653
JOB_ID=128556040187
SHA_STARTING="7f1b3098332d891a9ea6cf8e31383d4fd39141cf"
SHA_BASELINE="8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b"
SHA_CANDIDATE="46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8"
SHA_ARTIFACT="ed4757a6f9dde8b5302a73413102cba88fef8f02ac70875b309c2ebea9a56bab"
SOURCE={
 ".github/workflows/seer-next-experiment.yml":"72c60f4f2c85af5c89ff4c89c48bfe32ddbae0d1",
 ".github/actions/native-deps/action.yml":"a34a67ffdb697bf887f1085b55912f31f1ad9663",
 ".github/actions/node-setup/action.yml":"5008f501d9e5e84d622ee41b60731db9962fc704",
 "prototype/scripts/build_engine_service.sh":"eb6386c8018360858d74140512d2cf55fd3576f7",
 "research/seer-next/scripts/build_candidate.sh":"2e238c6406097d04efc20c274e9bb4e91d5bfa3b",
 "research/seer-next/scripts/build_hybrid.sh":"399219bf6f8abf21db39efc3b5ae59761a1033ee",
 "research/seer-next/scripts/compare_candidate.mjs":"d0b3a9e139c5e41b057eafb2e332914a72a189b1",
}
STEPS=[
 "Build unchanged baseline",
 "Build isolated experimental candidate",
 "Build isolated hybrid day-plus-year cache candidate",
 "Verify hybrid and original against independent canonical oracle"
]
LOG_TOKENS=(
 "Image: ubuntu-24.04",
 "Version: 20261101.360.1",
 "g++ is already the newest version (4:13.2.0-7ubuntu1).",
 "libgmp-dev is already the newest version (2:6.3.0+dfsg-2ubuntu6.1).",
 "libboost-dev:amd64 (1.83.0.1ubuntu2)",
 "libboost1.83-dev:amd64 (1.83.0-2.1ubuntu3.2)",
 "Found in cache @ /opt/hostedtoolcache/node/24.22.2/x64",
 "Built isolated Seer Next candidate (avx2 / x86-64)",
 "Built isolated Seer Next HYBRID candidate (avx2 / x86-64)",
 '"baselineBinarySHA256": "'+SHA_BASELINE+'"',
 '"candidateBinarySHA256": "'+SHA_CANDIDATE+'"',
)
OUTPUTS={
 "baseline":"prototype/build/seer_engine_service",
 "candidate":"research/seer-next/build/seer_next_engine_service",
 "hybrid":"research/seer-next/build/seer_next_hybrid_engine_service"
}

def need(cond,message):
    if not cond:raise ValueError(message)

def validate(m):
    need(type(m) is dict and m.get("schema")==SCHEMA
         and m.get("evidence_scope")==
         "HISTORICAL_SOURCE_TOOLCHAIN_UPLOAD_SCOPE_AND_MISSING_BYTES_NO_NATIVE_REBUILD"
         and m.get("source_repo")==REPO
         and m.get("historical_run_id")==RUN_ID
         and m.get("historical_job_id")==JOB_ID
         and m.get("historical_ci_head")==CI_SHA
         and m.get("frozen_source_head")==FROZEN
         and m.get("historical_run_state")=="completed/success"
         and m.get("required_successful_steps")==STEPS,
         "v138 frozen historic run/source identity changed")
    records=m.get("source_files")
    need(type(records) is list and len(records)==len(SOURCE)
         and {x.get("path"):x.get("git_blob_sha1") for x in records}==SOURCE,
         "v138 source Git blob SHA inventory changed")
    outputs=m.get("three_build_outputs")
    need(type(outputs) is list and len(outputs)==3
         and {x.get("role"):x.get("path") for x in outputs}==OUTPUTS
         and outputs[0].get("reported_sha256")==SHA_BASELINE
         and outputs[1].get("reported_sha256")==SHA_CANDIDATE
         and outputs[2].get("reported_sha256") is None
         and all(x.get("original_executable_bytes_available") is False for x in outputs),
         "original Seer Next build targets or hash claims changed")
    tool=m.get("historic_log_observation",{})
    need(tool.get("log_review_source")==
         "github_actions_job_log_128556040187_observed_not_CI_byte_pinned"
         and tool.get("runner_image")=="ubuntu-24.04"
         and tool.get("runner_image_version")=="20261101.360.1"
         and tool.get("hosted_agent_version")=="20261028.624"
         and tool.get("gxx_ubuntu_package")=="4:13.2.0-7ubuntu1"
         and tool.get("libgmp_dev_ubuntu_package")=="2:6.3.0+dfsg-2ubuntu6.1"
         and tool.get("libboost_dev_ubuntu_package")=="1.83.0.1ubuntu2"
         and tool.get("libboost183_dev_ubuntu_package")=="1.83.0-2.1ubuntu3.2"
         and tool.get("node_runtime_observed")=="24.22.2"
         and tool.get("backend")=="avx2"
         and tool.get("march")=="x86-64"
         and tool.get("historical_cli_flags")==[
            "-O3","-DNDEBUG","-std=c++20","-fopenmp","-pthread",
            "-march=x86-64","-mavx2"]
         and tool.get("not_all_toolchain_dependency_file_hashes_known") is True
         and tool.get("original_binary_SHA_recomputation_permitted_by_existing_archives") is False,
         "toolchain provenance facts or scientific confidence changed")
    hardcoded=m.get("reporter_static_field",{})
    need(hardcoded=={
        "field":"startingCommit","hardcoded_value":SHA_STARTING,
        "github_actions_actual_head":CI_SHA,
        "must_not_infer_binary_git_source_from_hardcoded_field":True},
        "hardcoded startingCommit incorrectly promoted to Git evidence")
    archive=m.get("original_results_artifact",{})
    need(archive=={
        "id":13595506317,"name":"seer-next-native-ab-linux-avx2",
        "sha256_zip":SHA_ARTIFACT,"file_count":34,
        "upload_scope":"only_explicit_34_JSON_result_paths",
        "contains_binary_files":False,"retention_currently_valid":True},
        "original experiment artifact scope changed")
    need(m.get("github_actions_cache_api_contents_read") is False
         and m.get("github_actions_cache_presence_or_absence_asserted") is False
         and m.get("externally_reproducible_byte_identical_binary_proven") is False
         and m.get("run_native_compilers_permitted") is False
         and m.get("run_original_Fct_permitted") is False
         and m.get("certified_10000_soak_years")==0
         and m.get("certified_independent_algorithms")==0
         and m.get("soak_dispatch_authorized") is False,
         "not permitted to promote recipe metadata to binary/Soak")

def extract_json_only_artifact_paths(workflow):
    sentinel="name: seer-next-native-ab-linux-avx2"
    need(workflow.count(sentinel)==1,"original artifact name absent/ambiguous")
    block=workflow.split(sentinel,1)[1]
    need("path: |" in block and "if-no-files-found: error" in block,
         "original artifact upload path block incomplete")
    block=block.split("path: |",1)[1].split("if-no-files-found: error",1)[0]
    paths=[x.strip() for x in block.splitlines() if x.strip()]
    need(len(paths)==34 and len(set(paths))==34
         and all(p.startswith("research/seer-next/results/working/")
                 and p.endswith(".json")
                 and re.fullmatch(r"[A-Za-z0-9_./-]+",p)
                 for p in paths),
         "experiment artifact did not list exactly 34 JSON-only files")
    return paths

def verify_sources(m,gh):
    validate(m)
    source={}
    for path,sha in SOURCE.items():
        blob,proof=checked_blob(gh,REPO,CI_SHA,path)
        need(proof["git_blob_sha1"]==sha,
             "source Git blob does not match pinned build recipe: "+path)
        source[path]=blob.decode("utf-8")
    flow=source[".github/workflows/seer-next-experiment.yml"]
    paths=extract_json_only_artifact_paths(flow)
    need("runs-on: ubuntu-24.04" in flow
         and "profile: standard-minimal" in flow
         and "package-manager-cache: false" in flow
         and "node-version: '24'" in flow
         and flow.count("SEER_RNS_BACKEND: avx2")>=3
         and flow.count("SEER_MARCH: x86-64")>=3
         and "bash prototype/scripts/build_engine_service.sh" in flow
         and "bash research/seer-next/scripts/build_candidate.sh" in flow
         and "bash research/seer-next/scripts/build_hybrid.sh" in flow,
         "CI build invocation flags or baseline/candidate/hybrid steps changed")
    deps=source[".github/actions/native-deps/action.yml"]
    need("standard-minimal) packages=(g++ libgmp-dev libboost-dev); minimal=1" in deps,
         "historical native dependency profile changed")
    baseline=source["prototype/scripts/build_engine_service.sh"]
    candidate=source["research/seer-next/scripts/build_candidate.sh"]
    hybrid=source["research/seer-next/scripts/build_hybrid.sh"]
    for code in (baseline,candidate,hybrid):
        need("CXX=" in code
             and all(flag in code for flag in ["-O3","-DNDEBUG","-std=c++20","-fopenmp","-pthread"])
             and "-march=" in code
             and "-mavx2" in code
             and "-lgmp" in code,
             "historical C++ recipe flags or native external libraries changed")
    need('-o "$ROOT/build/seer_engine_service"' in baseline
         and '-o "$ROOT/research/seer-next/build/seer_next_engine_service"' in candidate
         and '-o "$ROOT/research/seer-next/build/seer_next_hybrid_engine_service"' in hybrid,
         "original target output names no longer match frozen index")
    reporter=source["research/seer-next/scripts/compare_candidate.mjs"]
    need("startingCommit:'"+SHA_STARTING+"'" in reporter
         and "baselineBinarySHA256:await sha256(src)" in reporter
         and "candidateBinarySHA256:await sha256(candidate)" in reporter
         and "createReadStream(file)" in reporter
         and "createHash('sha256')" in reporter,
         "historic hash reporter and hardcoded startingCommit provenance changed")
    return {"frozen_source_blobs_verified":len(source),
            "exact_original_artifact_json_paths":len(paths),
            "original_result_artifact_includes_build_or_binary_path":False,
            "historical_workflow_backend":"avx2",
            "historical_workflow_march":"x86-64",
            "three_build_recipe_outputs":OUTPUTS,
            "github_workflow_source_commit":CI_SHA,
            "startingCommit_field_value":SHA_STARTING,
            "startingCommit_field_derived_from_live_git":False,
            "source_provenance_not_executable_byte_identity":True}

def verify_ci(m,gh):
    validate(m)
    run=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID))
    need(type(run) is dict and
         run.get("id")==RUN_ID and run.get("head_sha")==CI_SHA
         and run.get("status")=="completed" and run.get("conclusion")=="success",
         "pinned native build run is not completed/success at CI source SHA")
    jobs=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID)+"/jobs?per_page=100")
    need(type(jobs) is dict and type(jobs.get("total_count")) is int
         and 0<jobs["total_count"]<=100 and type(jobs.get("jobs")) is list,
         "cannot exhaust original CI job list")
    found=[v for v in jobs["jobs"] if v.get("id")==JOB_ID]
    need(len(found)==1 and found[0].get("status")=="completed"
         and found[0].get("conclusion")=="success",
         "pinned C++ build job failed/missing")
    steps={s.get("name"):s.get("conclusion") for s in found[0].get("steps",[])}
    need(all(steps.get(name)=="success" for name in STEPS),
         "pinned individual baseline/candidate/hybrid build step not all successful")
    art=gh.get("/repos/"+REPO+"/actions/runs/"+str(RUN_ID)+"/artifacts?per_page=100")
    need(type(art) is dict and type(art.get("total_count")) is int
         and art["total_count"]<=100 and type(art.get("artifacts")) is list,
         "original historical artifact listing ambiguous")
    a=[x for x in art["artifacts"] if x.get("id")==13595506317]
    need(len(a)==1 and a[0].get("name")=="seer-next-native-ab-linux-avx2"
         and a[0].get("digest")=="sha256:"+SHA_ARTIFACT
         and a[0].get("expired") is False,
         "original JSON-only archive no longer accessible/metadata mismatch")
    return {"run_id":RUN_ID,"head_sha":CI_SHA,"run_status":"completed/success",
            "job_id":JOB_ID,"required_successful_build_steps":STEPS,
            "historical_json_artifact_id":13595506317,
            "binary_bytes_in_the_original_archived_artifact":False}

def verify_historical_log_text(log):
    need(type(log) is str and len(log)<1000000,
         "historical job log size or type invalid")
    missing=[s for s in LOG_TOKENS if s not in log]
    if missing:
        raise ValueError("missing historic toolchain/log evidence token: "+missing[0])
    return {"state":"AVAILABLE_VERIFIED_FROM_HISTORIC_JOB_LOG",
            "observed_package_versions_and_build_success":True,
            "original_binary_hashes_recorded_in_job_log":2,
            "all_transitive_toolchain_file_digests_known":False,
            "binary_bytes_available_from_log":False}

def fetch_historical_job_log(token):
    """Best-effort raw readonly historical log retrieval; a failure != a negative claim."""
    url="https://api.github.com/repos/"+REPO+"/actions/jobs/"+str(JOB_ID)+"/logs"
    req=Request(url,headers={
      "Accept":"application/vnd.github+json",
      "X-GitHub-Api-Version":"2022-11-28",
      "User-Agent":"pastafari-soak-v138-historic-log-readonly",
      **({"Authorization":"Bearer "+token} if token else {})})
    try:
        with urlopen(req,timeout=30) as f:
            raw=f.read(1000001)
            if len(raw)>1000000:
                return {"state":"UNAVAILABLE_OR_UNVERIFIED","reason":"LOG_OVER_SIZE_LIMIT"}
        return verify_historical_log_text(raw.decode("utf-8-sig"))
    except (HTTPError,URLError,UnicodeError,ValueError) as exc:
        return {"state":"UNAVAILABLE_OR_UNVERIFIED",
                "reason":type(exc).__name__,
                "reported_historic_toolchain_as_unverified_in_this_run":True}

def audit(m,gh,logs=None):
    validate(m)
    source=verify_sources(m,gh)
    ci=verify_ci(m,gh)
    result=None if logs is None else verify_historical_log_text(logs)
    return {"schema":REPORT,"manifest_sha256":digest(m),
            "static_historical_recipe":source,
            "completed_ci_run_job_and_archived_results":ci,
            "historical_job_log_reverified_in_this_execution":result is not None,
            "historical_log_verification":result,
            "original_candidate_or_baseline_executable_bytes_found":False,
            "binary_hashes_recorded_but_not_recomputed_from_executable_bytes":2,
            "GHA_cache_inventory_examined":False,
            "GHA_cache_absence_proven":False,
            "reproducible_bit_identical_binary_proven":False,
            "new_compiler_or_linker_calls":0,
            "new_original_date_Fct_calls":0,
            "scientific_original_10000_years_certified":0,
            "independent_algorithms_certified":0,
            "soak_dispatch_authorized":False}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--index",required=True,type=Path)
    p.add_argument("--output",required=True,type=Path)
    p.add_argument("--fetch-historical-log",action="store_true")
    a=p.parse_args()
    m=parse_json(a.index.read_bytes())
    token=os.environ.get("GITHUB_TOKEN","")
    report=audit(m,GitHubReadOnly(token))
    if a.fetch_historical_log:
        log=fetch_historical_job_log(token)
        report["historical_log_verification"]=log
        report["historical_job_log_reverified_in_this_execution"]=(
            log["state"]=="AVAILABLE_VERIFIED_FROM_HISTORIC_JOB_LOG")
    with a.output.open("xb") as f:f.write(canonical(report)+b"\n")
    print(json.dumps({"source_files":report["static_historical_recipe"]["frozen_source_blobs_verified"],
      "uploaded_original_json_files":report["static_historical_recipe"]["exact_original_artifact_json_paths"],
      "historic_build_steps":len(STEPS),
      "historical_log_reverified":report["historical_job_log_reverified_in_this_execution"],
      "original_executable_bytes_found":False,
      "soak_years_certified":0,
      "soak_dispatch_authorized":False},sort_keys=True))

if __name__=="__main__":
    main()
