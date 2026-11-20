#!/usr/bin/env python3
"""Fail-closed source-path triage for unmapped v129 converter records.

READ-ONLY GitHub git/tree and blob verification. This does not certify which
file is the real native F(c,t) entrypoint, source dependency closure,
buildability, execution or algorithmic independence. No converter execution.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
import os
from pathlib import Path

from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import (
    GitHubReadOnly, APIProblem, safe_repo, safe_path, sha40
)

SCHEMA="PASTAFARI_SOAK_TRIAGE_SOURCE_PATH_CANDIDATES_V130/1"
REPORT="PASTAFARI_SOAK_TRIAGE_PATH_AUDIT_V130/1"
CLASSES={"CODE_BOOTSTRAP_ONLY", "PROJECT_MANIFEST_ONLY_NO_VI_SOURCE",
         "SOURCE_ENTRYPOINT_CANDIDATE_NOT_REVIEWED"}


def validate(manifest:dict, provenance:dict, census:dict):
    if type(manifest) is not dict or set(manifest)!={
        "schema","source_roster","source_provenance","source_census_contract",
        "observation_type","entries","safe_to_promote_into_v127_scope",
        "all_source_lineage_unassessed","native_soak_dispatch_authorized"
    } or manifest["schema"]!=SCHEMA:
        raise ValueError("invalid v130 manifest schema")
    if (manifest["source_roster"]!="soak/control/source_roster_archived_v21_v127.json"
        or manifest["source_provenance"]!="soak/control/source_roster_archived_v21_v127_provenance.json"
        or manifest["source_census_contract"]!="PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"
        or manifest["observation_type"]!="HISTORICAL_COMMIT_PATH_CANDIDATE_NOT_NATIVE_ENTRYPOINT_CERTIFICATION"
        or manifest["safe_to_promote_into_v127_scope"] is not False
        or manifest["all_source_lineage_unassessed"] is not True
        or manifest["native_soak_dispatch_authorized"] is not False):
        raise ValueError("v130 candidate manifest tried to claim readiness")
    if (census.get("schema")!="PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"
        or census.get("provenance_sha256")!=digest(provenance)
        or census.get("record_count")!=91
        or census.get("native_date_calls")!=0
        or census.get("soak_dispatch_authorized") is not False):
        raise ValueError("v130 source census is not the pinned 91-row no-dispatch observation")
    seen={}
    if type(provenance.get("records")) is not list:
        raise ValueError("invalid provenance records")
    for item in provenance["records"]:
        if item["record_id"] in seen:
            raise ValueError("duplicate provenance record")
        seen[item["record_id"]]=item
    unmapped={k for k,v in seen.items() if v["source_path"] is None}
    observed={}
    for item in census["records"]:
        if item["record_id"] in observed:
            raise ValueError("duplicate v129 source observation")
        observed[item["record_id"]]=item
    if set(observed)!=set(seen):
        raise ValueError("v129 source census dropped/added records")
    if type(manifest["entries"]) is not list or len(manifest["entries"])!=len(unmapped):
        raise ValueError("v130 must address every unmapped source record")
    candidates={}
    for row in manifest["entries"]:
        if type(row) is not dict or set(row)!={
            "record_id","source_commit","candidate_path","candidate_class",
            "candidate_explicitly_not_certified_as_Fct",
            "source_identity_audit_required","full_date_native_execution_verified",
            "immutable_source_dependency_manifest_verified"
        }:
            raise ValueError("wrong candidate record schema")
        rid=row["record_id"]
        if type(rid) is not str or rid not in unmapped or rid in candidates:
            raise ValueError("duplicate/unmapped/unknown triage candidate")
        if (row["candidate_explicitly_not_certified_as_Fct"] is not True
            or row["source_identity_audit_required"] is not True
            or row["full_date_native_execution_verified"] is not False
            or row["immutable_source_dependency_manifest_verified"] is not False
            or row["candidate_class"] not in CLASSES):
            raise ValueError("v130 candidate illegally promotes source to ready")
        sha40(row["source_commit"])
        safe_path(row["candidate_path"])
        origin=seen[rid]
        safe_repo(origin["repository"])
        upstream=observed[rid]
        if (upstream["repository"]!=origin["repository"]
            or upstream["branch"]!=origin["branch"]
            or upstream["archived_source_path"] is not None
            or upstream["observed_head_commit"]!=row["source_commit"]
            or upstream["source_observation"]!="SOURCE_PATH_NOT_DECLARED"):
            raise ValueError("triage candidate not linked to exact historical v129 head")
        candidates[rid]=(row,origin)
    if set(candidates)!=unmapped:
        raise ValueError("some unmapped records lack a candidate")
    return candidates


def run(manifest:dict, provenance:dict, census:dict, gh:GitHubReadOnly)->dict:
    candidates=validate(manifest,provenance,census)
    observations=[]
    statuses=Counter()
    for rid,(item,origin) in candidates.items():
        repo=origin["repository"]
        commit=item["source_commit"]
        path=item["candidate_path"]
        status="UNASSESSED"
        info=None
        branch_now=None
        same_as_v129=None
        tree_count=None
        try:
            tree=gh.get("/repos/"+repo+"/git/trees/"+commit+"?recursive=1")
            if (type(tree) is not dict or tree.get("truncated") is not False
                or type(tree.get("tree")) is not list):
                raise APIProblem("TREE_INCOMPLETE_OR_INVALID")
            tree_count=len(tree["tree"])
            matching=[f for f in tree["tree"] if isinstance(f,dict)
                      and f.get("type")=="blob" and f.get("path")==path]
            if len(matching)!=1:
                status="CANDIDATE_PATH_NOT_IN_FROZEN_GIT_TREE"
            else:
                declared=matching[0]
                actual=gh.source(repo,commit,path)
                if actual["git_blob_sha1"]!=declared.get("sha"):
                    status="GIT_TREE_AND_BLOB_SHA_DISAGREE"
                elif declared.get("size") is not None and actual["bytes"]!=declared["size"]:
                    status="TREE_AND_BLOB_BYTE_COUNT_DISAGREE"
                else:
                    info=actual
                    status="CANDIDATE_BYTES_VERIFIED_NOT_EXECUTABLE_CERTIFIED"
        except APIProblem as err:
            status="SOURCE_LOOKUP_UNAVAILABLE_"+err.code
        # Head movement is reported, not treated as disappearance of frozen bytes.
        try:
            now=gh.get("/repos/"+repo+"/branches/"+__import__("urllib.parse",fromlist=["quote"]).quote(origin["branch"],safe=""))
            head=now.get("commit",{}).get("sha") if isinstance(now,dict) else None
            if type(head) is str:
                sha40(head)
                branch_now=head
                same_as_v129=head==commit
        except (APIProblem,ValueError):
            pass
        same_branch=[x["record_id"] for x in provenance["records"]
                     if x["record_id"]!=rid and x["repository"]==repo
                     and x["branch"]==origin["branch"]]
        statuses[status]+=1
        observations.append({
            "record_id":rid,"repository":repo,"branch":origin["branch"],
            "v129_observed_commit":commit,"current_branch_head":branch_now,
            "current_head_matches_v129":same_as_v129,
            "candidate_path":path,"candidate_class":item["candidate_class"],
            "source_bytes_status":status,"source":info,
            "source_tree_blob_count":tree_count,
            "other_inventory_records_on_same_branch":same_branch,
            "candidate_is_verified_original_Fct":False,
            "independent_algorithm_certified":False,
            "eligible_for_soak":False
        })
    return {
        "schema":REPORT,
        "candidate_manifest_sha256":digest(manifest),
        "archived_provenance_sha256":digest(provenance),
        "v129_census_sha256":digest(census),
        "candidate_count":len(observations),
        "observation_counts":dict(sorted(statuses.items())),
        "records":observations,
        "unresolved_native_entrypoints":len(observations),
        "native_date_calls":0,
        "original_full_years_certified":0,
        "native_dispatch_authorized":False,
        "scientific_soak_10000_pass":False
    }


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ("candidates","provenance","census","output"):
        ap.add_argument("--"+k,required=True,type=Path)
    a=ap.parse_args()
    m,p,c=(parse_json(getattr(a,k).read_bytes())
           for k in ("candidates","provenance","census"))
    report=run(m,p,c,GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with a.output.open("xb") as stream:
        stream.write(canonical(report)+b"\n")
    print(json.dumps({
        "schema":REPORT, "candidate_count":report["candidate_count"],
        "observation_counts":report["observation_counts"],
        "unresolved_native_entrypoints":report["unresolved_native_entrypoints"],
        "native_date_calls":0,"native_dispatch_authorized":False
    },sort_keys=True))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
