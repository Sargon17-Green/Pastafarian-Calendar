#!/usr/bin/env python3
"""v085: fail-closed, one-new-file GitHub push authorization for original F(c,t).

This module NEVER runs a converter. Source engines remain byte-for-byte pinned.
A new request is admissible only as the sole change in the push range and only
for the ordinal immediately after all locally pinned previous native chunks.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

SCHEMA = "PASTAFARI_ORIGINAL_SOURCE_ORDINAL_REQUEST_V085/1"
PIN_SCHEMA = "PASTAFARI_GENERIC_ORIGINAL_CHUNK_ARTIFACT_PIN_V071/1"
YEAR = "5000"
C = "-15055671"
FIRST_DAY = -15057702
LAST_DAY = -15053459
BOUNDARY = "ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78"
SOURCE_COMMITS = {
    "REF-41": "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
    "PROD-KT-CY": "0c703446d8a3b7435698bd16402ac5fa30e461c9",
}
REQUEST_DIR = "soak/control/original_source_dispatch_requests"
REQUEST_RE = re.compile(r"soak/control/original_source_dispatch_requests/ordinal-([0-9]+)\.json\Z")
PIN_RE = re.compile(r"original_native_chunk([0-9]+)_pin_v([0-9]+)\.json\Z")
COMMIT_RE = re.compile(r"[0-9a-f]{40}\Z")
FIRST_NEW = 1020
LAST_NEW = (LAST_DAY - FIRST_DAY + 1)//2 - 1


def _pairs_unique(pairs):
    found = {}
    for k, v in pairs:
        if k in found:
            raise ValueError("duplicate JSON key in immutable source request or pin")
        found[k] = v
    return found


def _read_json_canonical(path: Path, *, require_canonical: bool = True) -> dict:
    if not path.is_file() or path.is_symlink():
        raise ValueError("source request/pin missing or symlinked")
    raw = path.read_bytes()
    if len(raw) > 32768 or not raw:
        raise ValueError("source request/pin length invalid")
    data = json.loads(raw.decode("utf-8"), object_pairs_hook=_pairs_unique)
    if type(data) is not dict:
        raise ValueError("source request/pin must be JSON object")
    expected = (json.dumps(data, sort_keys=True, separators=(",", ":"),
                           ensure_ascii=False) + "\n").encode("utf-8")
    if require_canonical and raw != expected:
        raise ValueError("new source request must use canonical JSON with newline")
    return data


def pinned_prefix(root: Path) -> int:
    control = root/"soak/control"
    matches = list(control.glob("original_native_chunk*_pin_v*.json"))
    found = set()
    if not matches:
        raise ValueError("frozen original source prefix missing")
    for path in matches:
        match = PIN_RE.fullmatch(path.name)
        if match is None:
            raise ValueError("unrecognized source manifest filename")
        ordinal = int(match.group(1))
        if ordinal in found or not 1017 <= ordinal <= LAST_NEW:
            raise ValueError("duplicate or out-of-range original source pin")
        pin = _read_json_canonical(path, require_canonical=False)
        if (pin.get("schema") != PIN_SCHEMA or
                pin.get("original_source_year", {}).get("ordinal") != ordinal or
                pin.get("original_source_year", {}).get("calculation_day") != C or
                pin.get("original_source_year", {}).get("boundary_evidence_sha256") != BOUNDARY or
                pin.get("original_source_commits") != SOURCE_COMMITS or
                type(pin.get("artifact_sha256")) is not str or
                re.fullmatch(r"[0-9a-f]{64}", pin["artifact_sha256"]) is None or
                pin.get("comparison", {}).get("first_mismatch", "ABSENT") is not None or
                pin.get("comparison", {}).get("original_year_soak_passes_certified") != 0):
            raise ValueError("prior native source manifest insufficiently pinned")
        found.add(ordinal)
    last = max(found)
    if found != set(range(1017, last+1)):
        raise ValueError("gap in previously pinned source chunks")
    return last


def validate_request(root: Path, changed: list[tuple[str, str]]) -> dict:
    """Authorize precisely one brand-new canonical request in this push."""
    if len(changed) != 1 or changed[0][0] != "A":
        raise ValueError("only one ADDED source-ordinal request allowed per push")
    rel = changed[0][1]
    m = REQUEST_RE.fullmatch(rel)
    if m is None:
        raise ValueError("changed file is not an original ordinal dispatch request")
    ordinal = int(m.group(1))
    if not FIRST_NEW <= ordinal <= LAST_NEW:
        raise ValueError("original ordinal previously run or outside source year")
    last_pinned = pinned_prefix(root)
    if ordinal != last_pinned+1:
        raise ValueError("request is not exactly next contiguous pinned original ordinal")
    request = _read_json_canonical(root/rel)
    expected_keys = {
        "schema", "ordinal", "year", "calculation_day",
        "first_target_day", "last_target_day",
        "boundary_evidence_sha256", "original_source_commits",
    }
    if set(request) != expected_keys:
        raise ValueError("request has missing/unknown fields")
    if type(request["ordinal"]) is not int or request["ordinal"] != ordinal:
        raise ValueError("ordinal type/value disagrees with file name")
    first = FIRST_DAY + ordinal*2
    last = first+1
    if (request["schema"] != SCHEMA or request["year"] != YEAR or
            request["calculation_day"] != C or
            request["first_target_day"] != str(first) or
            request["last_target_day"] != str(last) or last > LAST_DAY or
            request["boundary_evidence_sha256"] != BOUNDARY or
            request["original_source_commits"] != SOURCE_COMMITS):
        raise ValueError("request dates/source identity differ from frozen originals")
    raw = (root/rel).read_bytes()
    return {
        "status": "AUTHORIZED_NEXT_ORIGINAL_TWO_DAY_SOURCE_ONLY_NOT_A_YEAR",
        "ordinal": ordinal, "year": YEAR, "calculation_day": C,
        "first_target_day": str(first), "last_target_day": str(last),
        "previous_pinned_ordinal": last_pinned, "request_path": rel,
        "request_sha256": hashlib.sha256(raw).hexdigest(),
        "full_years_certified": 0,
    }


def verify_git_push(root: Path, before: str, after: str) -> dict:
    if (COMMIT_RE.fullmatch(before or "") is None or
            COMMIT_RE.fullmatch(after or "") is None or
            before == "0"*40 or after == "0"*40 or before == after):
        raise ValueError("strict nonempty Git push ancestry required")
    def git(*args):
        return subprocess.run(["git", "-C", str(root), *args],
                              check=True, text=True, capture_output=True).stdout.strip()
    if git("rev-parse", "HEAD") != after:
        raise ValueError("checked out HEAD differs from triggering push")
    git("merge-base", "--is-ancestor", before, after)
    raw = git("diff", "--name-status", "--no-renames", before, after)
    parts = []
    for line in raw.splitlines():
        fields = line.split("\t")
        if len(fields) != 2:
            raise ValueError("unrecognized Git path status or rename")
        parts.append((fields[0], fields[1]))
    return validate_request(root, parts)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--before", required=True)
    parser.add_argument("--after", required=True)
    parser.add_argument("--github-output", type=Path, required=True)
    args = parser.parse_args()
    verdict = verify_git_push(args.repo_root.resolve(strict=True),
                              args.before, args.after)
    with args.github_output.open("a", encoding="utf-8") as f:
        for key in ("ordinal", "first_target_day", "last_target_day",
                    "request_path", "request_sha256"):
            f.write(f"{key}={verdict[key]}\n")
    print("V085_ORIGINAL_SOURCE_DISPATCH=" + json.dumps(verdict, sort_keys=True))


if __name__ == "__main__":
    main()
