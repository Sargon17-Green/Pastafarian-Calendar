#!/usr/bin/env python3
"""Stage04 historical Rust SOURCE provenance, not runtime-RED verification.

A pin is only source-eligible if its exact Rust production blob existed on this
branch at/before the Stage3 closure, before the first Stage4 commit. No source
pin by itself demonstrates a historical day-tag route or an observed mismatch.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path, PurePosixPath

_SHA = re.compile(r"[0-9a-f]{40}\Z")


class ProvenanceError(ValueError):
    """The supplied source has not met the eligibility contract."""


def git(repo: Path, *args: str, allowed: tuple[int, ...] = (0,)) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        capture_output=True, text=True, check=False, timeout=12,
    )
    if result.returncode not in allowed:
        raise ProvenanceError(f"git {args[0]} failed (exit {result.returncode})")
    return result.stdout.strip()


def checked_sha(value: str) -> str:
    if not _SHA.fullmatch(value):
        raise ProvenanceError("expected a pinned 40-character lowercase commit/blob SHA")
    return value


def checked_rust_path(value: str) -> str:
    path = PurePosixPath(value)
    if (value.startswith("/") or "\\" in value or ":" in value
            or any(part in (".", "..", "") for part in value.split("/"))
            or not value.startswith("src/") or path.suffix != ".rs"
            or len(path.parts) < 2):
        raise ProvenanceError("historical production witness must be a safe src/**/*.rs path")
    return value


def is_ancestor(repo: Path, older: str, newer: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(repo), "merge-base", "--is-ancestor", older, newer],
        capture_output=True, text=True, check=False, timeout=12,
    )
    if result.returncode not in (0, 1):
        raise ProvenanceError(f"cannot establish ancestry (exit {result.returncode})")
    return result.returncode == 0


def verify_pin(repo: Path, witness_commit: str, witness_path: str,
               witness_blob: str, stage3_closure: str,
               stage4_introduction: str, branch_head: str) -> dict[str, object]:
    pins = [checked_sha(s) for s in (
        witness_commit, witness_blob, stage3_closure, stage4_introduction, branch_head
    )]
    witness_commit, witness_blob, stage3_closure, stage4_introduction, branch_head = pins
    witness_path = checked_rust_path(witness_path)
    for rev in (witness_commit, stage3_closure, stage4_introduction, branch_head):
        if git(repo, "cat-file", "-t", rev) != "commit":
            raise ProvenanceError("revision pin is not a commit")
    if witness_commit == stage4_introduction or not is_ancestor(repo, witness_commit, stage3_closure):
        raise ProvenanceError("source commit is not in the pre-Stage4 Rust ancestry")
    if not is_ancestor(repo, stage3_closure, stage4_introduction):
        raise ProvenanceError("Stage3 closure is not an ancestor of Stage4 introduction")
    if not is_ancestor(repo, stage4_introduction, branch_head):
        raise ProvenanceError("Stage4 introduction is not an ancestor of current branch HEAD")
    try:
        actual_blob = git(repo, "rev-parse", f"{witness_commit}:{witness_path}")
    except ProvenanceError as exc:
        raise ProvenanceError("pinned path did not exist in the proposed revision") from exc
    if actual_blob != witness_blob or git(repo, "cat-file", "-t", actual_blob) != "blob":
        raise ProvenanceError("source blob SHA differs from pinned Git object")
    return {
        "project_id": "PC-BRANCH-RUST-AZERBAIJANI",
        "source_pin_eligible": True,
        "witness_commit": witness_commit,
        "witness_path": witness_path,
        "witness_blob": witness_blob,
        "historical_day_tag_route_proven": False,
        "observed_runtime_red": False,
        "stage04_closure": "NOT_CLAIMED",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path("."))
    parser.add_argument("--witness-commit", required=True)
    parser.add_argument("--witness-path", required=True)
    parser.add_argument("--witness-blob", required=True)
    parser.add_argument("--stage3-closure", required=True)
    parser.add_argument("--stage4-introduction", required=True)
    parser.add_argument("--branch-head", required=True)
    args = parser.parse_args()
    try:
        output = verify_pin(args.repo, args.witness_commit, args.witness_path,
                            args.witness_blob, args.stage3_closure,
                            args.stage4_introduction, args.branch_head)
    except (ProvenanceError, subprocess.TimeoutExpired, OSError) as exc:
        print(json.dumps({"source_pin_eligible": False,
                          "historical_day_tag_route_proven": False,
                          "observed_runtime_red": False,
                          "stage04_closure": "NOT_CLAIMED",
                          "reason": str(exc)}, sort_keys=True))
        return 2
    print(json.dumps(output, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
