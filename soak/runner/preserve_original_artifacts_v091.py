#!/usr/bin/env python3
"""v091: release-archive admission and exact source ZIP verification.

A push that adds ONE preapproved, canonical JSON archive request may preserve
previously completed original F(c,t) ZIPs in a DRAFT GitHub Release. No original
converter is executed, and no original full-year certification is issued.

This module NEVER calls gh or mutates a release itself: it validates an offline
release plan and independently audits downloaded artifact bytes before a separate
protected GitHub Actions step receives write permission.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

from pinned_original_prefix_v089 import collect, verify_new_request
from original_generic_source_chunk_ledger_v073 import manifest_for, offline_original_chunk
from original_chunk_artifact_gate_v072 import audit_pinned_original_chunk

REQUEST_REL = "soak/control/original_archive_requests/source-1015-1021-v091.json"
TAG = "soak-original-fct-source-1015-1021-v091"
SCHEMA = "PASTAFARI_SOURCE_ARCHIVE_REQUEST_V091/1"
MANIFEST_SCHEMA = "PASTAFARI_ORIGINAL_SOURCE_DRAFT_RELEASE_ASSETS_V091/1"
BRANCH = "qa/soak-readiness-20261114"
COMMIT = re.compile(r"[0-9a-f]{40}\Z")
DIGEST = re.compile(r"[0-9a-f]{64}\Z")
FIRST = 1015
LAST = 1021


def unique_pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key in source archive request")
        result[key] = value
    return result


def canonical_bytes(obj):
    return (json.dumps(obj, sort_keys=True, ensure_ascii=False,
                       separators=(",", ":")) + "\n").encode("utf-8")


def request_data(path: Path):
    if path.is_symlink() or not path.is_file() or path.stat().st_size > 32768:
        raise ValueError("missing, symlinked, or oversized archive request")
    raw = path.read_bytes()
    request = json.loads(raw.decode("utf-8"), object_pairs_hook=unique_pairs)
    if type(request) is not dict or raw != canonical_bytes(request):
        raise ValueError("archive request is not a canonical JSON object")
    return request


def source_index(root: Path):
    index = collect(root)
    entries = index["artifacts"]
    if (index["last_ordinal"] != LAST or len(entries) != LAST - FIRST + 1 or
        [row["ordinal"] for row in entries] != list(range(FIRST, LAST + 1)) or
        index["committed_full_original_years"] != 0):
        raise ValueError("archive prefix differs from seven sealed original chunks")
    result = []
    for row in entries:
        ordinal = row["ordinal"]
        result.append({
            "ordinal": ordinal, "artifact_id": row["artifact_id"],
            "run_id": row["run_id"], "sha256": row["sha256"],
            "filename": f"source-{ordinal}.zip",
        })
    if len({row["sha256"] for row in result}) != len(result):
        raise ValueError("duplicate frozen original ZIP digest")
    return result


def validate_request(request, entries, before):
    if not COMMIT.fullmatch(before or ""):
        raise ValueError("invalid approved source archive parent commit")
    exact_keys = {
        "schema", "release_tag", "approved_parent_sha",
        "source_branch", "original_year", "calculation_day",
        "assets", "whole_original_years_certified", "independence_certified",
    }
    if set(request) != exact_keys:
        raise ValueError("unknown/missing archive request fields")
    if (request["schema"] != SCHEMA or request["release_tag"] != TAG or
        request["source_branch"] != BRANCH or
        request["approved_parent_sha"] != before or
        request["original_year"] != "5000" or
        request["calculation_day"] != "-15055671" or
        request["whole_original_years_certified"] != 0 or
        request["independence_certified"] is not False or
        request["assets"] != entries):
        raise ValueError("source archive request differs from frozen exact ZIP inventory")
    return True


def git_push_single_added_request(root: Path, before: str, after: str):
    if (not COMMIT.fullmatch(before or "") or
        not COMMIT.fullmatch(after or "") or before == after or
        before == "0" * 40 or after == "0" * 40):
        raise ValueError("nonempty same-repository push refs required")
    def git(*args):
        return subprocess.run(
            ["git", "-C", str(root), *args], check=True, text=True,
            capture_output=True,
        ).stdout.strip()
    if git("rev-parse", "HEAD") != after:
        raise ValueError("archive request runner HEAD differs from pushed commit")
    git("merge-base", "--is-ancestor", before, after)
    changed = git("diff", "--name-status", "--no-renames", before, after)
    if changed != "A\t" + REQUEST_REL:
        raise ValueError("archive release requires exactly ONE newly added request file")


def plan(root: Path, before: str, after: str):
    git_push_single_added_request(root, before, after)
    entries = source_index(root)
    request = request_data(root / REQUEST_REL)
    validate_request(request, entries, before)
    return {
        "schema": MANIFEST_SCHEMA,
        "release_tag": TAG,
        "source_branch": BRANCH,
        "source_commit_sha": after,
        "source_request_sha256": hashlib.sha256((root / REQUEST_REL).read_bytes()).hexdigest(),
        "original_year": "5000",
        "calculation_day": "-15055671",
        "assets": entries,
        "whole_original_years_certified": 0,
        "independence_certified": False,
        "canonical_oracle_certified": False,
        "windows_run_started": False,
    }


def verify_archives(root: Path, manifest: dict, workspace: Path,
                    python_root: Path, kotlin_root: Path):
    """Perform raw ZIP SHA/CRC checks and independent source audit before release upload."""
    entries = source_index(root)
    if (manifest.get("schema") != MANIFEST_SCHEMA or
        manifest.get("release_tag") != TAG or
        manifest.get("assets") != entries or
        manifest.get("whole_original_years_certified") != 0):
        raise ValueError("release manifest not equal to immutable code-source inventory")
    for row in entries:
        ordinal = row["ordinal"]
        path = workspace / row["filename"]
        if path.is_symlink() or not path.is_file() or path.stat().st_size > 12_000_000:
            raise ValueError(f"missing, symlinked or oversized native ZIP ordinal {ordinal}")
        contents = path.read_bytes()
        if hashlib.sha256(contents).hexdigest() != row["sha256"]:
            raise ValueError(f"native original ZIP SHA differs, ordinal {ordinal}")
        with zipfile.ZipFile(path) as z:
            names = z.namelist()
            if len(names) != len(set(names)) or z.testzip() is not None:
                raise ValueError(f"native original ZIP duplicate/invalid CRC ordinal {ordinal}")
        if ordinal >= 1017:
            pin, _ = manifest_for(ordinal)
            result = audit_pinned_original_chunk(
                contents, python_root, kotlin_root, manifest=pin)
            replay = offline_original_chunk(contents, pin)
            if (result["status"] != "PINNED_ORIGINAL_ORDINAL_TWO_DAYS_MATCH_NOT_YEAR"
                or result["ordinal"] != ordinal or result["original_source_pairs"] != 2
                or result["original_years_soak_certified"] != 0
                or replay["original_native_date_pairs"] != 2
                or replay["original_full_years_certified"] != 0):
                raise ValueError(f"native original Fct source audit failed ordinal {ordinal}")
            if ordinal >= 1020:
                proof = verify_new_request(contents, pin)
                if proof["status"] != "V085_NATIVE_DISPATCH_REQUEST_PINNED_NOT_A_YEAR":
                    raise ValueError("original source dispatch request not bound to native ZIP")
    return len(entries)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--before")
    parser.add_argument("--after")
    parser.add_argument("--archive-dir", type=Path)
    parser.add_argument("--python-root", type=Path)
    parser.add_argument("--kotlin-root", type=Path)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    root = args.repo_root.resolve(strict=True)
    if args.verify_only:
        if args.archive_dir is None or args.python_root is None or args.kotlin_root is None:
            parser.error("--verify-only needs archive-dir and two original source trees")
        manifest = json.loads(args.manifest.read_bytes(), object_pairs_hook=unique_pairs)
        count = verify_archives(root, manifest, args.archive_dir,
                                args.python_root, args.kotlin_root)
        print("V091_ORIGINAL_ZIP_BYTES_AUDITED_NOT_A_YEAR=" + str(count))
    else:
        if args.before is None or args.after is None:
            parser.error("planning needs exact push before/after commits")
        manifest = plan(root, args.before, args.after)
        args.manifest.write_bytes(canonical_bytes(manifest))
        print("V091_ARCHIVE_REQUEST_AUTHORIZED_NO_NATIVE_CALLS=" + str(len(manifest["assets"])))


if __name__ == "__main__":
    main()
