#!/usr/bin/env python3
"""Verify pinned C++/Latina source provenance for an external soak scheduler.

Checks the actual Git tree and protected worktree files, not the binary or
calendar output. The caller MUST provide a trusted --expected-engine-commit;
a manifest's self-declared SHA is never sufficient proof.
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

CONTRACT = "PASTAFARI_SOAK_SOURCE_PROVENANCE_V1"
PROTECTED = (
    "src",
    "include",
    "tools/soak_vector_adapter.cpp",
    "tools/validate_soak_index_modes.py",
)
REQUIRED = (
    "src/monster.cpp",
    "include/pastafari/monster.hpp",
    "include/pastafari/source_language_catalog.hpp",
    "tools/soak_vector_adapter.cpp",
    "tools/validate_soak_index_modes.py",
)
SHA = re.compile(r"[0-9a-f]{40}\Z")


def require(ok, message):
    if not ok:
        raise ValueError(message)


def git(root, *args):
    try:
        result = subprocess.run(
            ["git", "-C", str(root), *args],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30, check=False, text=True,
        )
    except subprocess.TimeoutExpired as exc:
        raise ValueError("git provenance command timed out") from exc
    require(result.returncode == 0, "git provenance command failed: " +
            " ".join(args[:3]) + ": " + result.stderr.strip()[:250])
    return result.stdout.strip()


def git_bytes(root, *args):
    """Read raw Git output without text conversion or silent decode loss."""
    try:
        result = subprocess.run(
            ["git", "-C", str(root), *args],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30, check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ValueError("git source-byte command timed out") from exc
    require(result.returncode == 0, "git source-byte command failed: " +
            " ".join(args[:3]) + ": " +
            result.stderr.decode("utf-8", "replace")[:250])
    return result.stdout


def inspect(manifest_path, root, trusted_base, expected_head):
    require(SHA.fullmatch(trusted_base) is not None,
            "trusted baseline must be an exact 40-character Git SHA")
    require(SHA.fullmatch(expected_head) is not None,
            "expected HEAD must be an exact 40-character Git SHA")
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
    require(isinstance(manifest, dict), "manifest root is not an object")
    require(manifest.get("repository") == "Sargon17-Green/Pastafarian-Calendar",
            "unexpected source repository")
    require(manifest.get("branch") == "C++&Latina", "unexpected source branch")
    require(manifest.get("implementation_id") ==
            "pastafarian-calendar-cpp-latina", "unexpected implementation ID")
    require(manifest.get("engine_verified_commit") == trusted_base,
            "manifest baseline does not match trusted pinned commit")
    actual_head = git(root, "rev-parse", "--verify", "HEAD")
    require(actual_head == expected_head, "checkout HEAD does not match expected SHA")
    baseline = git(root, "rev-parse", "--verify", trusted_base + "^{commit}")
    require(baseline == trusted_base, "pinned baseline commit cannot be resolved")
    for path in REQUIRED:
        require(git(root, "ls-files", "--error-unmatch", "--", path) == path,
                "required engine or protocol source missing: " + path)
    changed = git(root, "diff", "--name-only",
                  trusted_base, expected_head, "--", *PROTECTED)
    require(not changed, "protected source changed since certified engine: " +
            changed[:400])
    unstaged = git(root, "diff", "--name-only", "--", *PROTECTED)
    staged = git(root, "diff", "--cached", "--name-only", "--", *PROTECTED)
    # Deliberately omit --exclude-standard: ignored source files can still
    # affect a compiler via local include paths or source discovery.
    untracked = git(root, "ls-files", "--others", "--", *PROTECTED)
    require(not unstaged, "uncommitted protected source changes: " + unstaged[:400])
    require(not staged, "staged protected source changes: " + staged[:400])
    require(not untracked, "untracked or ignored protected source files: " +
            untracked[:400])
    # Git diff trusts index flags such as assume-unchanged/skip-worktree.
    # Compare raw worktree bytes with the committed blobs, never index stat
    # information. This also rejects symlinks and missing source files.
    paths = [
        os.fsdecode(item)
        for item in git_bytes(root, "ls-files", "-z", "--", *PROTECTED).split(b"\x00")
        if item
    ]
    require(bool(paths), "no tracked protected sources found")
    for relative in paths:
        disk_file = root / relative
        require(disk_file.is_file() and not disk_file.is_symlink(),
                "protected source missing or symlinked: " + relative)
        committed = git_bytes(root, "show", "HEAD:" + relative)
        require(disk_file.read_bytes() == committed,
                "protected source bytes differ from HEAD: " + relative)
    return {
        "contract": CONTRACT,
        "source_verified": True,
        "implementation_id": manifest["implementation_id"],
        "trusted_engine_commit": trusted_base,
        "head_commit": expected_head,
        "protected_source_paths": list(PROTECTED),
        "binary_attested": False,
        "global_soak_executed": False,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--expected-engine-commit", required=True)
    parser.add_argument("--expected-head", required=True)
    args = parser.parse_args()
    try:
        response = inspect(args.manifest, Path(args.repository).resolve(),
                           args.expected_engine_commit, args.expected_head)
    except (OSError, ValueError, TypeError, UnicodeError,
            subprocess.SubprocessError, json.JSONDecodeError) as exc:
        response = {
            "contract": CONTRACT,
            "source_verified": False,
            "reason": str(exc),
            "binary_attested": False,
            "global_soak_executed": False,
        }
    print(json.dumps(response, ensure_ascii=True, sort_keys=True,
                     separators=(",", ":")))
    return 0 if response["source_verified"] else 1


if __name__ == "__main__":
    sys.exit(main())
