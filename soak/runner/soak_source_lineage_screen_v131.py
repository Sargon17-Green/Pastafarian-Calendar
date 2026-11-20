#!/usr/bin/env python3
"""Offline, deterministic cross-source lineage screening; no native F(c,t).

Consumes pinned v129/v130 GitHub Actions evidence. Identical one-file SHA-256,
co-located branch heads and identical source paths are *review signals*, never
proof of independent algorithms, common algorithms or complete dependencies.
No network, OS launches, date arithmetic, DB writes, or dispatch.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
from typing import Any

from soak_scope_coverage_v127 import canonical, digest, parse_json, validate_inventory

SCHEMA = "PASTAFARI_SOAK_SOURCE_LINEAGE_SCREEN_V131/1"
CENSUS_SCHEMA = "PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"
TRIAGE_SCHEMA = "PASTAFARI_SOAK_TRIAGE_PATH_AUDIT_V130/1"
CI_SCHEMA = "PASTAFARI_SOAK_PINNED_CI_JOB_OBSERVATIONS_V129/1"
INDEX_SCHEMA = "PASTAFARI_SOAK_PINNED_SOURCE_CI_JOB_INDEX_V129/1"
MANIFEST_SCHEMA = "PASTAFARI_SOAK_TRIAGE_SOURCE_PATH_CANDIDATES_V130/1"
HEX40 = re.compile(r"[0-9a-f]{40}\Z")
HEX64 = re.compile(r"[0-9a-f]{64}\Z")
VERIFIED_SOURCE = "SOURCE_BYTES_VERIFIED_AT_HEAD"
VERIFIED_TRIAGE = "CANDIDATE_BYTES_VERIFIED_NOT_EXECUTABLE_CERTIFIED"
PINNED_CI = "SOURCE_LOCK_AND_HISTORICAL_CI_STATUS_OBSERVED"
PINNED_CI_JOB = "PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED"


def need(cond: bool, why: str) -> None:
    if not cond:
        raise ValueError(why)


def exact_keys(obj: Any, expected: set[str], context: str) -> None:
    need(type(obj) is dict and set(obj) == expected, "unexpected " + context + " fields")


def hexval(value: Any, length: int, context: str) -> str:
    pattern = HEX40 if length == 40 else HEX64
    need(type(value) is str and pattern.fullmatch(value) is not None,
         "malformed " + context + " SHA")
    return value


def unique_id_rows(rows: Any, expected: set[str], name: str) -> dict:
    need(type(rows) is list and len(rows) == len(expected),
         name + " must contain the exact roster population")
    by_id = {}
    for row in rows:
        need(type(row) is dict and type(row.get("record_id")) is str,
             "invalid " + name + " row")
        key = row["record_id"]
        need(key in expected and key not in by_id,
             "unknown or repeated " + name + " record")
        by_id[key] = row
    return by_id


def require_file_evidence(source: Any, context: str) -> dict:
    exact_keys(source, {"source_sha256", "git_blob_sha1", "bytes"}, context)
    hexval(source["source_sha256"], 64, context + " source")
    hexval(source["git_blob_sha1"], 40, context + " Git blob")
    need(type(source["bytes"]) is int and 0 < source["bytes"] <= 2 * 1024 * 1024,
         context + " source bytes not credible")
    return source


def collision_groups(rows: list[dict], attributes: tuple[str, ...]) -> list[dict]:
    groups = defaultdict(list)
    for row in rows:
        groups[tuple(row[key] for key in attributes)].append(row["record_id"])
    result = []
    for key, members in groups.items():
        if len(members) > 1:
            result.append({
                "field_names": list(attributes),
                "same_values": list(key),
                "record_ids": sorted(members),
                "record_count": len(members),
            })
    return sorted(result, key=lambda g: (-g["record_count"],g["record_ids"]))


def screen(roster: dict, provenance: dict, census: dict,
           candidates: dict, triage: dict, ci_index: dict,
           ci_evidence: dict, frozen_locks: dict) -> dict:
    original = validate_inventory(roster)
    need(len(original) == 91, "historical roster must have exactly 91 records")
    provenance_by_id = unique_id_rows(provenance.get("records"),
                                      set(original), "archived provenance")
    for key in original:
        need(original[key]["algorithm_id"] == "UNASSESSED",
             "archived algorithm lineage was promoted without review")
    need(census.get("schema") == CENSUS_SCHEMA and
         census.get("roster_sha256") == digest(roster) and
         census.get("provenance_sha256") == digest(provenance) and
         census.get("frozen_lock_sha256") == digest(frozen_locks) and
         census.get("record_count") == 91 and
         census.get("native_date_calls") == 0 and
         census.get("official_years_certified") == 0 and
         census.get("soak_dispatch_authorized") is False and
         census.get("independent_execution_attested") is False,
         "v129 census not pinned to the full no-dispatch roster")
    census_rows = unique_id_rows(census.get("records"),set(original),"v129 source census")
    need(candidates.get("schema") == MANIFEST_SCHEMA and
         candidates.get("source_provenance") ==
             "soak/control/source_roster_archived_v21_v127_provenance.json" and
         candidates.get("safe_to_promote_into_v127_scope") is False and
         candidates.get("native_soak_dispatch_authorized") is False and
         candidates.get("all_source_lineage_unassessed") is True,
         "v130 candidate manifest attempted to promote a source")
    need(triage.get("schema") == TRIAGE_SCHEMA and
         triage.get("candidate_manifest_sha256") == digest(candidates) and
         triage.get("v129_census_sha256") == digest(census) and
         triage.get("archived_provenance_sha256") == digest(provenance) and
         triage.get("candidate_count") == 10 and
         triage.get("unresolved_native_entrypoints") == 10 and
         triage.get("native_date_calls") == 0 and
         triage.get("original_full_years_certified") == 0 and
         triage.get("native_dispatch_authorized") is False and
         triage.get("scientific_soak_10000_pass") is False,
         "v130 Git-tree candidate evidence not pinned to v129")
    missing_ids = {rid for rid,r in provenance_by_id.items()
                   if r["source_path"] is None}
    need(len(missing_ids) == 10, "unexpected number of unmapped historical sources")
    cands_by_id = unique_id_rows(candidates.get("entries"),missing_ids,
                                 "v130 triage candidate manifest")
    triage_by_id = unique_id_rows(triage.get("records"),missing_ids,
                                  "v130 Git-tree observations")

    need(ci_index.get("schema") == INDEX_SCHEMA and
         ci_index.get("full_year_verified") is False and
         ci_index.get("native_execution_attested") is False and
         ci_index.get("independent_algorithms_certified") is False,
         "CI index claimed native source certification")
    need(ci_evidence.get("schema") == CI_SCHEMA and
         ci_evidence.get("source_census_sha256") == digest(census) and
         ci_evidence.get("ci_index_sha256") == digest(ci_index) and
         ci_evidence.get("frozen_lock_sha256") == digest(frozen_locks) and
         ci_evidence.get("claims_checked") == 2 and
         ci_evidence.get("native_date_calls") == 0 and
         ci_evidence.get("original_full_years_certified") == 0 and
         ci_evidence.get("independent_algorithms_certified") is False and
         ci_evidence.get("soak_dispatch_authorized") is False,
         "historical pinned CI evidence is missing or inconsistent")
    lock_map = {item["id"]:item for item in frozen_locks["engines"]}
    need(set(lock_map) == {"REF-24","REF-41"} and
         set(x["record_id"] for x in ci_index.get("claims",[])) == set(lock_map),
         "CI status must refer only to two frozen originals")
    ci_by_id = unique_id_rows(ci_evidence.get("observations"),
                              set(lock_map),"historical CI evidence")

    normalized = []
    for rid in sorted(original):
        origin = provenance_by_id[rid]
        upstream = census_rows[rid]
        need(origin["record_id"] == rid and
             upstream.get("repository") == origin["repository"] and
             upstream.get("branch") == origin["branch"] and
             upstream.get("archived_source_path") == origin["source_path"] and
             upstream.get("record_id") == rid and
             upstream.get("native_build_success_verified_by_census") is False and
             upstream.get("native_full_date_execution_verified_by_census") is False and
             upstream.get("independent_algorithm_certified_by_census") is False and
             upstream.get("eligible_for_soak") is False,
             rid + ": inconsistent or self-certified historical source")
        repo,branch=origin["repository"],origin["branch"]
        head=hexval(upstream.get("observed_head_commit"),40,rid+" head")
        evidence_class = "ARCHIVED_PATH_VERIFIED"
        source_path = origin["source_path"]
        if rid not in missing_ids:
            need(upstream.get("source_observation")==VERIFIED_SOURCE and
                 source_path is not None,
                 rid+": source path not verified in v129")
            src = require_file_evidence(upstream.get("observed_source"),rid)
        else:
            c=cands_by_id[rid]
            t=triage_by_id[rid]
            need(upstream.get("source_observation")=="SOURCE_PATH_NOT_DECLARED" and
                 upstream.get("observed_source") is None and
                 c["source_commit"]==head and
                 c["candidate_path"]==t["candidate_path"] and
                 t["repository"]==repo and t["branch"]==branch and
                 t["v129_observed_commit"]==head and
                 t["source_bytes_status"]==VERIFIED_TRIAGE and
                 t["candidate_is_verified_original_Fct"] is False and
                 t["independent_algorithm_certified"] is False and
                 t["eligible_for_soak"] is False and
                 c["candidate_explicitly_not_certified_as_Fct"] is True and
                 c["source_identity_audit_required"] is True and
                 c["full_date_native_execution_verified"] is False and
                 c["immutable_source_dependency_manifest_verified"] is False,
                 rid+": triage path or unsafe native promotion")
            source_path = c["candidate_path"]
            src = require_file_evidence(t.get("source"),rid)
            evidence_class="UNREVIEWED_SOURCE_CANDIDATE"
        need(type(source_path) is str and bool(source_path),
             rid+": source location is absent")
        pinned_ci_status="NO_COMPLETED_PINNED_CI_OBSERVATION"
        if rid in lock_map:
            lock = lock_map[rid]
            row = ci_by_id[rid]
            need(upstream.get("frozen_source_lock_status")==
                     "FROZEN_SOURCES_SHA_LOCK_PASS" and
                 upstream.get("locked_commit")==lock["commit"] and
                 row.get("source_commit")==lock["commit"] and
                 row.get("ci_status")==PINNED_CI_JOB and
                 row.get("combined_source_ci_status")==PINNED_CI and
                 row.get("pinned_source_sha_observation")==
                     "FROZEN_SOURCES_SHA_LOCK_PASS" and
                 row.get("eligible_for_soak") is False and
                 row.get("native_full_date_execution_proven") is False and
                 row.get("original_full_years_certified")==0,
                 rid+": frozen source or completed CI evidence not verified")
            pinned_ci_status="SOURCE_SHA_AND_HISTORICAL_CI_STEPS_ONLY"
        normalized.append({
            "record_id":rid,"source_kind":original[rid]["source_kind"],
            "declared_algorithm_id":original[rid]["algorithm_id"],
            "repository":repo,"branch":branch,
            "historical_head_commit":head,"observed_source_path":source_path,
            "source_sha256":src["source_sha256"],
            "git_blob_sha1":src["git_blob_sha1"],
            "source_bytes":src["bytes"],
            "evidence_class":evidence_class,
            "ci_evidence_class":pinned_ci_status,
            "native_entrypoint_verified":False,
            "full_dependency_closure_verified":False,
            "original_stdout_execution_attested":False,
            "algorithmic_independence_certified":False,
            "eligible_for_soak":False
        })
    same_tree = collision_groups(
        normalized,("repository","branch","historical_head_commit"))
    same_location = collision_groups(
        normalized,("repository","historical_head_commit","observed_source_path"))
    same_content = collision_groups(normalized,("source_sha256",))
    tree_members = {rid for group in same_tree for rid in group["record_ids"]}
    location_members = {rid for group in same_location for rid in group["record_ids"]}
    content_members = {rid for group in same_content for rid in group["record_ids"]}
    for row in normalized:
        rid=row["record_id"]
        row["shares_historical_source_tree_with_other_record"] = rid in tree_members
        row["shares_exact_source_location_with_other_record"] = rid in location_members
        row["shares_exact_single_file_SHA256_with_other_record"] = rid in content_members
    return {
        "schema":SCHEMA,
        "roster_sha256":digest(roster),
        "provenance_sha256":digest(provenance),
        "v129_census_sha256":digest(census),
        "v130_candidate_manifest_sha256":digest(candidates),
        "v130_triage_sha256":digest(triage),
        "v129_ci_index_sha256":digest(ci_index),
        "v129_ci_evidence_sha256":digest(ci_evidence),
        "frozen_source_lock_sha256":digest(frozen_locks),
        "total_historical_records":len(normalized),
        "source_rows_bound_to_git_sha256":len(normalized),
        "archived_source_paths_verified":len(normalized)-len(missing_ids),
        "additional_triage_paths_verified_without_native_certification":len(missing_ids),
        "distinct_repository_branch_pairs":len(set(
            (r["repository"],r["branch"]) for r in normalized)),
        "distinct_historical_source_trees":len(set(
            (r["repository"],r["branch"],r["historical_head_commit"])
            for r in normalized)),
        "distinct_single_file_sha256":len(set(
            r["source_sha256"] for r in normalized)),
        "same_tree_groups":same_tree,
        "exact_source_location_groups":same_location,
        "identical_file_content_groups":same_content,
        "record_ids_sharing_historical_source_tree":sorted(tree_members),
        "record_ids_sharing_exact_source_location":sorted(location_members),
        "record_ids_sharing_exact_single_file_sha256":sorted(content_members),
        "pinned_source_and_historical_ci_record_ids":sorted(ci_by_id),
        "records":normalized,
        "independent_algorithm_count_certified":0,
        "native_original_full_date_engines_certified":0,
        "official_10000_year_soak_credit":0,
        "native_date_calls":0,
        "source_independence_audit_status":"NOT_PERFORMED_BY_THIS_GATE",
        "soak_dispatch_authorized":False,
        "scientific_soak_10000_pass":False,
        "caveat":"Same tree, path or one file does not prove algorithms identical; distinct sources do not prove independent algorithms."
    }


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for name in ("roster","provenance","v129-census","v130-candidates",
                 "v130-triage","v129-ci-index","v129-ci-evidence",
                 "source-locks","output"):
        ap.add_argument("--"+name,required=True,type=Path)
    a=ap.parse_args()
    paths=("roster","provenance","v129_census","v130_candidates","v130_triage",
           "v129_ci_index","v129_ci_evidence","source_locks")
    docs=[parse_json(getattr(a,x).read_bytes()) for x in paths]
    result=screen(*docs)
    with a.output.open("xb") as stream:
        stream.write(canonical(result)+b"\n")
    summary={key:result[key] for key in (
        "schema","total_historical_records","archived_source_paths_verified",
        "additional_triage_paths_verified_without_native_certification",
        "distinct_repository_branch_pairs","distinct_single_file_sha256",
        "independent_algorithm_count_certified","native_date_calls",
        "soak_dispatch_authorized","official_10000_year_soak_credit"
    )}
    summary.update({
        "same_tree_group_count":len(result["same_tree_groups"]),
        "same_source_location_group_count":len(result["exact_source_location_groups"]),
        "identical_single_file_sha256_group_count":len(result["identical_file_content_groups"])
    })
    print(json.dumps(summary,ensure_ascii=False,sort_keys=True))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
