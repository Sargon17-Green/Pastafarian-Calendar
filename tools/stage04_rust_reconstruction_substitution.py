#!/usr/bin/env python3
"""Fail-closed, separately authorized Stage04 reconstructed RED->GREEN admission.

This is NOT the unchanged historical Rust provenance verifier, nor a Native CI
result checker. The exact completed Actions evidence is pinned in the audit
decision and must be reviewed separately before Stage04 can be closed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

PROJECT = "PC-BRANCH-RUST-AZERBAIJANI"
STAGE3 = "716e5a6f335b1a15464029b446edb468f3a8482c"
STAGE4_INTRO = "2a7648c345ee63d9e5c81ca0361c6eb3060c6c4f"
RED = "108833d04786be22bfcadc987c7208b35c373451"
GREEN = "3eed23d0664ef7484649194776c0327c18280cd0"
OBSERVED_CODE = "07a8e7b4b2e90cdc42886dd88c6b754fd5ebb085"
HISTORICAL_VERIFIER_BLOB = "4969623f859827a603f88c5811d03ac9463bbd3c"
OBSERVED_SHA256 = "cf4c5f12392e04a3e39a80b209e155fb19b0e0f0795920a8bb459f1556ffcd6f"
EXPECTED_SHA256 = "9fb7051a993abe6c37980848ef912c8f5a438c51a782fb7e0d786944a45ffb80"
F = -15_055_671
DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
SHA = re.compile(r"[0-9a-f]{40}\Z")


class AdmissionError(ValueError):
    pass


def command(repo: Path, *args: str) -> str:
    try:
        p = subprocess.run(["git", "-C", str(repo), *args],
                           text=True, capture_output=True, timeout=20, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise AdmissionError("Git evidence unavailable") from exc
    if p.returncode != 0:
        raise AdmissionError("Git verification failed: " + args[0])
    return p.stdout.strip()


def ancestor(repo: Path, old: str, new: str) -> bool:
    try:
        p = subprocess.run(["git", "-C", str(repo), "merge-base",
                            "--is-ancestor", old, new],
                           capture_output=True, timeout=20, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise AdmissionError("Git ancestry unavailable") from exc
    if p.returncode not in (0, 1):
        raise AdmissionError("Git ancestry unresolved")
    return p.returncode == 0


def rows(path: Path, header: str, digest: str) -> list[list[int | str]]:
    try:
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise AdmissionError("Pinned fixture digest mismatch: " + path.name)
        lines = data.decode("utf-8").splitlines()
    except (OSError, UnicodeError) as exc:
        raise AdmissionError("Fixture unreadable: " + path.name) from exc
    if len(lines) != 129 or lines[0] != header:
        raise AdmissionError("Fixture header or row count mismatch: " + path.name)
    parsed: list[list[int | str]] = []
    for line in lines[1:]:
        fields = line.split("\t")
        if len(fields) != len(header.split("\t")):
            raise AdmissionError("Fixture column count mismatch: " + path.name)
        if not all(DECIMAL.fullmatch(s) for s in fields[:3]):
            raise AdmissionError("Noncanonical numerical field: " + path.name)
        parsed.append([int(s) for s in fields[:3]] + fields[3:])
    return parsed


def verify_numeric(expected: Path, observed: Path) -> dict[str, object]:
    a = rows(expected, "index\tday\toracle_tag\tregion\tdistance", EXPECTED_SHA256)
    b = rows(observed, "index\tday\tnative_tag", OBSERVED_SHA256)
    before = 0
    after = 0
    for i, (e, o) in enumerate(zip(a, b)):
        ix, day, oracle, region, distance_text = e
        jx, native_day, native_tag = o
        if not DECIMAL.fullmatch(str(distance_text)):
            raise AdmissionError("Invalid fixture distance")
        distance = ((i + 1) << (i % 120)) + 37 * i + 3
        target_day = F - distance if i % 2 == 0 else F + distance
        expected_tag = 2 * abs(target_day - F) + (1 if target_day >= F else 0)
        region_expected = "BEFORE" if target_day < F else "ON_OR_AFTER"
        if (ix != i or jx != i or day != target_day or native_day != target_day
                or oracle != expected_tag or native_tag != expected_tag
                or int(distance_text) != distance or region != region_expected):
            raise AdmissionError("Per-case observed/oracle mismatch at index " + str(i))
        before += target_day < F
        after += target_day >= F
    if before != 64 or after != 64:
        raise AdmissionError("Boundary coverage mismatch")
    return {"independently_verified_observed_rows": 128,
            "before_foundation": before, "on_or_after_foundation": after}


def verify(repo: Path, head: str) -> dict[str, object]:
    if not SHA.fullmatch(head):
        raise AdmissionError("Full current HEAD SHA required")
    if command(repo, "rev-parse", "HEAD") != head:
        raise AdmissionError("Current checkout does not match pinned branch HEAD")
    for commit in (STAGE3, STAGE4_INTRO, RED, GREEN, OBSERVED_CODE, head):
        if command(repo, "cat-file", "-t", commit) != "commit":
            raise AdmissionError("Evidence commit not available")
    if not (ancestor(repo, STAGE3, STAGE4_INTRO)
            and ancestor(repo, STAGE4_INTRO, head)):
        raise AdmissionError("Original branch stage ancestry invalid")
    if not (ancestor(repo, STAGE3, RED)
            and not ancestor(repo, RED, STAGE3)
            and ancestor(repo, RED, GREEN)
            and not ancestor(repo, GREEN, RED)
            and ancestor(repo, GREEN, OBSERVED_CODE)):
        raise AdmissionError("Reconstruction chronology invalid")
    historical = command(repo, "rev-parse", "HEAD:tools/stage04_rust_witness_provenance.py")
    if historical != HISTORICAL_VERIFIER_BLOB:
        raise AdmissionError("Unmodified historical witness verifier required")
    red_source = command(repo, "rev-parse", RED + ":src/discovery02_legacy_day_tag.rs")
    green_source = command(repo, "rev-parse", GREEN + ":src/discovery02_legacy_day_tag.rs")
    if red_source == green_source:
        raise AdmissionError("Distinct erroneous and corrected Rust source required")
    numeric = verify_numeric(
        repo / "audit/fixtures/rust_az_stage04_128_independent_oracle_20261122.tsv",
        repo / "audit/fixtures/rust_az_stage04_128_NATIVE_OBSERVED_20261122.tsv")
    return {"project_id": PROJECT,
            "substitution_kind": "AUTHORIZED_2026_RECONSTRUCTED_NATIVE_RED_GREEN",
            "reconstruction_substitution_static_eligible": True,
            "historical_pre_stage03_rust_red_proven": False,
            "native_ci_live_status_checked_by_this_script": False,
            "original_historical_gate_unchanged": True,
            "stage04_closure": "NOT_CLAIMED",
            **numeric}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--repo", type=Path, default=Path("."))
    p.add_argument("--branch-head", required=True)
    a = p.parse_args()
    try:
        result = verify(a.repo, a.branch_head)
        code = 0
    except AdmissionError as exc:
        result = {"project_id": PROJECT,
                  "reconstruction_substitution_static_eligible": False,
                  "historical_pre_stage03_rust_red_proven": False,
                  "stage04_closure": "NOT_CLAIMED",
                  "reason": str(exc)}
        code = 2
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return code


if __name__ == "__main__":
    raise SystemExit(main())
