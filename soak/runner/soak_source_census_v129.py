#!/usr/bin/env python3
"""Read-only GitHub source census for archived Pastafarian converter roster.

Fetches immutable branch-head source blobs; validates Git blob IDs and bytes.
Checks frozen v001 source locks separately, including dependencies. NEVER
executes date conversion, attests native processes, or authorizes Soak.
"""
from __future__ import annotations

import argparse
import base64
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from soak_scope_coverage_v127 import (
    canonical, digest, parse_json, validate_inventory,
)

ROSTER_SCHEMA = "PASTAFARI_SOAK_SOURCE_ROSTER_V127/1"
ARCHIVE_SCHEMA = "PASTAFARI_SOAK_ARCHIVED_ROSTER_PROVENANCE_V127/1"
CENSUS_SCHEMA = "PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"
HEX40 = re.compile(r"[a-f0-9]{40}\Z")
HEX64 = re.compile(r"[a-f0-9]{64}\Z")
REPO = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\Z")
MAX_SOURCE_BYTES = 2 * 1024 * 1024


class APIProblem(Exception):
    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") +
                        b"\x00" + data).hexdigest()


def safe_repo(value):
    if type(value) is not str or not REPO.fullmatch(value):
        raise ValueError("invalid source repository")
    return value


def safe_path(value):
    if type(value) is not str or not value or value.startswith("/") or "\\" in value:
        raise ValueError("unsafe source file path")
    if any(piece in ("", ".", "..") for piece in value.split("/")) or "\x00" in value:
        raise ValueError("unsafe source file path")
    return value


def sha40(value):
    if type(value) is not str or not HEX40.fullmatch(value):
        raise ValueError("invalid 40-byte Git hex ID")
    return value


def fail_if_invalid_inputs(roster: dict, provenance: dict, locks: dict) -> dict:
    records = validate_inventory(roster)
    if set(provenance) != {
        "schema", "source_file", "source_internal_schema",
        "source_created_utc_date", "source_scope", "source_counts",
        "records", "caveats"
    } or provenance["schema"] != ARCHIVE_SCHEMA:
        raise ValueError("archived provenance contract changed")
    origin = provenance["records"]
    if type(origin) is not list or len(origin) != len(records):
        raise ValueError("roster/provenance count differs")
    seen = {}
    for row in origin:
        if type(row) is not dict or set(row) != {
            "record_id", "branch", "repository", "source_path",
            "source_status_as_of_2026_11_14", "source_url"
        }:
            raise ValueError("invalid archived provenance record")
        rid = row["record_id"]
        if type(rid) is not str or rid not in records or rid in seen:
            raise ValueError("missing/duplicate archived source identity")
        safe_repo(row["repository"])
        if type(row["branch"]) is not str or not row["branch"].strip() or "\x00" in row["branch"]:
            raise ValueError("invalid archived source branch")
        if row["source_path"] is not None:
            safe_path(row["source_path"])
        seen[rid] = row
    if set(seen) != set(records):
        raise ValueError("some archived source records are missing")
    if locks.get("schema") != "PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1" or locks.get("main_changes_permitted") is not False:
        raise ValueError("frozen source lock contract changed")
    locked_ids = set()
    for item in locks.get("engines", []):
        rid = item["id"]
        if rid in locked_ids or rid not in records:
            raise ValueError("unknown/duplicate immutable engine lock")
        locked_ids.add(rid)
        if (item["repository"] != seen[rid]["repository"] or
            item["branch"] != seen[rid]["branch"] or
            not any(x["path"] == seen[rid]["source_path"] for x in item["sources"])):
            raise ValueError("immutable lock disagrees with roster provenance")
        sha40(item["commit"])
        for src in item["sources"]:
            safe_path(src["path"])
            sha40(src["git_blob_sha1"])
            if not HEX64.fullmatch(src["sha256"]) or type(src["bytes"]) is not int or src["bytes"] < 0:
                raise ValueError("malformed frozen source digest/size")
    return seen


class GitHubReadOnly:
    def __init__(self, token="", base_url="https://api.github.com"):
        self.token = token
        self.base_url = base_url.rstrip("/")

    def get(self, path):
        req = Request(self.base_url + path, headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "pastafari-soak-readonly-census-v129",
            **({"Authorization": "Bearer " + self.token} if self.token else {})
        })
        try:
            with urlopen(req, timeout=25) as response:
                raw = response.read(4 * 1024 * 1024)
                if response.read(1):
                    raise APIProblem("API_RESPONSE_TOO_LARGE")
                return json.loads(raw.decode("utf-8"))
        except HTTPError as exc:
            if exc.code == 404:
                raise APIProblem("NOT_FOUND_OR_NOT_AUTHORIZED") from exc
            if exc.code in (401, 403, 429):
                raise APIProblem("AUTH_OR_RATE_LIMITED") from exc
            raise APIProblem("HTTP_ERROR_" + str(exc.code)) from exc
        except (URLError, TimeoutError, UnicodeError, ValueError) as exc:
            raise APIProblem("NETWORK_OR_INVALID_API_RESPONSE") from exc

    def branch_heads(self, repo):
        """Enumerate branch heads on each repo once; never infer 404 == absent."""
        rows = {}
        for page in range(1, 31):
            fetched = self.get("/repos/" + repo + "/branches?per_page=100&page=" + str(page))
            if not isinstance(fetched, list):
                raise APIProblem("INVALID_BRANCH_LIST")
            for item in fetched:
                if (not isinstance(item, dict) or type(item.get("name")) is not str
                    or not HEX40.fullmatch(str(item.get("commit", {}).get("sha", "")))):
                    raise APIProblem("INVALID_BRANCH_SNAPSHOT")
                if item["name"] in rows:
                    raise APIProblem("DUPLICATE_BRANCH_IN_API")
                rows[item["name"]] = item["commit"]["sha"]
            if len(fetched) < 100:
                return rows
        raise APIProblem("BRANCH_PAGINATION_LIMIT_REACHED")

    def source(self, repo, commit, path):
        sha40(commit)
        safe_path(path)
        response = self.get("/repos/" + repo + "/contents/" +
                            quote(path, safe="/") + "?ref=" + commit)
        if not isinstance(response, dict) or response.get("type") != "file":
            raise APIProblem("NOT_A_SOURCE_FILE")
        if response.get("encoding") != "base64" or not response.get("content"):
            raise APIProblem("SOURCE_BYTES_NOT_AVAILABLE")
        size = response.get("size")
        if type(size) is not int or size < 0 or size > MAX_SOURCE_BYTES:
            raise APIProblem("FILE_SIZE_OUTSIDE_LIMIT")
        try:
            raw = base64.b64decode(response["content"].replace("\n", ""), validate=True)
        except (ValueError, TypeError) as exc:
            raise APIProblem("INVALID_BASE64_SOURCE") from exc
        if len(raw) != size or git_blob_sha1(raw) != response.get("sha"):
            raise APIProblem("GITHUB_BLOB_INTEGRITY_MISMATCH")
        return {
            "source_sha256": hashlib.sha256(raw).hexdigest(),
            "git_blob_sha1": response["sha"],
            "bytes": len(raw),
        }


def census(roster: dict, provenance: dict, locks: dict, gh: GitHubReadOnly) -> dict:
    originals = fail_if_invalid_inputs(roster, provenance, locks)
    source_locks = {x["id"]: x for x in locks["engines"]}
    repositories = sorted({r["repository"] for r in originals.values()})
    heads = {}
    unavailable = {}
    for repo in repositories:
        try:
            heads[repo] = gh.branch_heads(repo)
        except APIProblem as exc:
            unavailable[repo] = exc.code
    cache = {}
    rows = []
    for rid, source in originals.items():
        repo, branch, path = source["repository"], source["branch"], source["source_path"]
        observed_head = heads.get(repo, {}).get(branch)
        if repo in unavailable:
            status = "REPOSITORY_UNAVAILABLE_OR_NO_ACCESS"
        elif observed_head is None:
            status = "BRANCH_ABSENT_FROM_ACCESSIBLE_LIST"
        elif path is None:
            status = "SOURCE_PATH_NOT_DECLARED"
        else:
            key = (repo, observed_head, path)
            if key not in cache:
                try:
                    cache[key] = ("SOURCE_BYTES_VERIFIED_AT_HEAD",
                                  gh.source(repo, observed_head, path))
                except APIProblem as exc:
                    cache[key] = (exc.code, None)
            status, _ = cache[key]
        observation = {
            "record_id": rid, "repository": repo, "branch": branch,
            "archived_source_path": path,
            "observed_head_commit": observed_head,
            "source_observation": status,
            "observed_source": (cache.get((repo, observed_head, path), (None, None))[1]
                                if path is not None and observed_head is not None else None),
            "frozen_source_lock_status": "NO_FROZEN_SOURCE_LOCK",
            "locked_commit": None,
            "locked_sources": [],
            "live_head_equals_locked_commit": None,
            "native_build_success_verified_by_census": False,
            "native_full_date_execution_verified_by_census": False,
            "independent_algorithm_certified_by_census": False,
            "eligible_for_soak": False,
        }
        if rid in source_locks:
            lock = source_locks[rid]
            observation["locked_commit"] = lock["commit"]
            observation["live_head_equals_locked_commit"] = (
                observed_head == lock["commit"] if observed_head else None)
            locked_status = "FROZEN_SOURCES_SHA_LOCK_PASS"
            for src in lock["sources"]:
                key = (repo, lock["commit"], src["path"])
                if key not in cache:
                    try:
                        cache[key] = ("SOURCE_BYTES_VERIFIED_AT_HEAD",
                                      gh.source(*key))
                    except APIProblem as exc:
                        cache[key] = (exc.code, None)
                check, obs = cache[key]
                match = check == "SOURCE_BYTES_VERIFIED_AT_HEAD" and obs == {
                    "source_sha256": src["sha256"],
                    "git_blob_sha1": src["git_blob_sha1"],
                    "bytes": src["bytes"],
                }
                observation["locked_sources"].append({
                    "path": src["path"], "integrity_matches_archived_lock": match,
                    "observation_status": check,
                    "observed_source": obs,
                })
                if not match:
                    locked_status = ("FROZEN_SOURCE_LOCK_MISMATCH" if obs is not None
                                     else "FROZEN_SOURCE_UNAVAILABLE")
            observation["frozen_source_lock_status"] = locked_status
        rows.append(observation)
    counts = Counter(row["source_observation"] for row in rows)
    lock_counts = Counter(row["frozen_source_lock_status"] for row in rows)
    return {
        "schema": CENSUS_SCHEMA,
        "roster_sha256": digest(roster),
        "provenance_sha256": digest(provenance),
        "frozen_lock_sha256": digest(locks),
        "record_count": len(rows),
        "accessible_repository_branch_counts": {
            repo: len(heads.get(repo, {})) for repo in repositories
        },
        "repository_access_failures": unavailable,
        "source_observation_counts": dict(sorted(counts.items())),
        "frozen_lock_observation_counts": dict(sorted(lock_counts.items())),
        "records": rows,
        "independent_execution_attested": False,
        "native_date_calls": 0,
        "official_years_certified": 0,
        "soak_dispatch_authorized": False,
        "claim": "SOURCE_PROVENANCE_OBSERVATION_ONLY_NOT_SOAK_READINESS",
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--roster", required=True, type=Path)
    ap.add_argument("--archived-provenance", required=True, type=Path)
    ap.add_argument("--frozen-locks", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    inputs = [parse_json(p.read_bytes()) for p in
              (args.roster, args.archived_provenance, args.frozen_locks)]
    report = census(*inputs, GitHubReadOnly(os.environ.get("GITHUB_TOKEN", "")))
    # Prevent silent replacement of earlier source evidence.
    with args.output.open("xb") as out:
        out.write(canonical(report) + b"\n")
    summary = {key: report[key] for key in (
        "schema", "record_count", "source_observation_counts",
        "frozen_lock_observation_counts", "repository_access_failures",
        "official_years_certified", "soak_dispatch_authorized"
    )}
    print(json.dumps(summary, ensure_ascii=False, sort_keys=True))
    return 0 if report["record_count"] == 91 else 2


if __name__ == "__main__":
    raise SystemExit(main())
