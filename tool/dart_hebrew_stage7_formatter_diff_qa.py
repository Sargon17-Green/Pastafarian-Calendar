#!/usr/bin/env python3
"""Stage7 QA-only: capture exact Dart 3.13.2 formatter deltas, without touching source locks."""
from __future__ import annotations

import difflib
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

PROJECT_ID = "PC-BRANCH-DART-HEBREW"
SOURCE_A = "1d98a83db7446ceb4548c39e0eaf9b4441b72b9a"
BLOB_A = "3553a7f2e3899c958d56620c5449daa35b0731e2"
BLOB_B = "d736ca8afe3409a10474b8514284aceb154a46a9"
PLANNER = "lib/src/monster_month_weave_planner.dart"
ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "out" / "dart-hebrew-stage7-format-drift"


def command(*args: str, cwd: Path = ROOT) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=True, timeout=180)


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def hex256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def without_whitespace(data: bytes) -> str:
    # Compare all non-whitespace Unicode characters independently of formatting.
    return "".join(char for char in data.decode("utf-8") if not char.isspace())


def normalized_known_dart_call(data: bytes) -> tuple[str, int]:
    """Remove only the syntactically optional trailing comma at one locked call.

    This is a comparison projection, not a source rewrite. Any other
    non-whitespace difference still fails the QA oracle.
    """
    source = data.decode("utf-8")
    call = re.compile(
        r"(final\\s+work\\s*=\\s*const\\s+MonsterWorkCounter\\s*\\(\\s*\\)"
        r"\\s*\\.\\s*calculate\\s*\\(\\s*calculationDay\\s*,\\s*firstDay)"
        r"\\s*,(\\s*\\)\\s*;)"
    )
    projected, removed = call.subn(r"\\1\\2", source)
    assert removed <= 1, "Ambiguous trailing-comma allowlist match"
    return "".join(ch for ch in projected if not ch.isspace()), removed


def diff_content_hunks(unified: str) -> str:
    # Discard file labels and hunk-coordinate headers, not content or context.
    return "".join(line for line in unified.splitlines(keepends=True)
                   if not line.startswith(("--- ", "+++ ", "@@ ")))


def output_json(record: dict) -> None:
    (OUTPUT / "results.json").write_text(
        json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    assert os.environ.get("GITHUB_REF") == "refs/heads/Dart+עברית", "Unauthorized branch"
    head = command("git", "rev-parse", "HEAD").stdout.decode().strip()
    raw_b = command("git", "show", "HEAD:" + PLANNER).stdout
    raw_a = command("git", "show", SOURCE_A + ":" + PLANNER).stdout
    assert git_blob(raw_b) == BLOB_B, "Branch planner B blob changed"
    assert git_blob(raw_a) == BLOB_A, "Historical planner A blob changed"
    pubspec = (ROOT / "pubspec.yaml").read_bytes()
    sdk = command("dart", "--version")
    sdk_version = (sdk.stdout + sdk.stderr).decode("utf-8", "replace").strip()
    assert re.search(r"\b3\.13\.2\b", sdk_version), sdk_version

    result = {
        "project_id": PROJECT_ID,
        "scope": "Stage7 disposable-copy equivalence and idempotence QA; NOT formatter-clean acceptance",
        "source_head": head,
        "historical_a_commit": SOURCE_A,
        "sdk_version": sdk_version,
        "expected_blobs": {"B": BLOB_B, "A": BLOB_A},
        "variants": {},
    }
    try:
        with tempfile.TemporaryDirectory(prefix="dart_stage7_format_") as tmp:
            for label, original, expected in (
                ("B", raw_b, BLOB_B),
                ("A", raw_a, BLOB_A),
            ):
                isolated = Path(tmp) / label
                target = isolated / PLANNER
                target.parent.mkdir(parents=True)
                target.write_bytes(original)
                (isolated / "pubspec.yaml").write_bytes(pubspec)
                assert git_blob(target.read_bytes()) == expected
                # Only the disposable copy is formatted. The locked Git blobs
                # and tracked source file are not passed to the formatter.
                process = command("dart", "format", "--output=write",
                                  PLANNER, cwd=isolated)
                formatted = target.read_bytes()
                assert formatted.endswith(b"\n"), "Unexpected formatter output"
                # A second formatter invocation on the SAME disposable copy
                # must not change any bytes (idempotence).
                second = command("dart", "format", "--output=write",
                                 PLANNER, cwd=isolated)
                formatted_twice = target.read_bytes()
                nonwhitespace_equal = (
                    without_whitespace(original) == without_whitespace(formatted)
                )
                formatter_idempotent = formatted_twice == formatted
                source_projection, source_commas = normalized_known_dart_call(original)
                formatted_projection, formatted_commas = normalized_known_dart_call(formatted)
                allowlisted_comma_removed = (source_commas == 1 and formatted_commas == 0)
                allowlisted_nonwhitespace_equal = (
                    allowlisted_comma_removed and source_projection == formatted_projection
                )
                # Independently compare the exact bytes and preserve a full unified diff.
                before = original.decode("utf-8").splitlines(keepends=True)
                after = formatted.decode("utf-8").splitlines(keepends=True)
                diff = "".join(difflib.unified_diff(
                    before, after,
                    fromfile=f"{label}:source-locked:{expected}",
                    tofile=f"{label}:dart-3.13.2-formatted-copy",
                    n=5,
                ))
                (OUTPUT / (label + ".unified.diff")).write_text(
                    diff, encoding="utf-8"
                )
                summary = (process.stdout + process.stderr).decode(
                    "utf-8", "replace"
                ).strip()
                changed = original != formatted
                result["variants"][label] = {
                    "source_git_blob": expected,
                    "source_sha256": hex256(original),
                    "formatted_copy_git_blob": git_blob(formatted),
                    "formatted_copy_sha256": hex256(formatted),
                    "format_summary": summary,
                    "changed": changed,
                    "diff_sha256": hex256(diff.encode("utf-8")),
                    "diff_lines": len(diff.splitlines()),
                    "diff_hunk_count": sum(1 for line in diff.splitlines()
                                           if line.startswith("@@ ")),
                    "nonwhitespace_equal": nonwhitespace_equal,
                    "strict_nonwhitespace_gate_satisfied": nonwhitespace_equal,
                    "allowlisted_trailing_comma_removed": allowlisted_comma_removed,
                    "allowlisted_nonwhitespace_equal": allowlisted_nonwhitespace_equal,
                    "source_known_call_trailing_commas": source_commas,
                    "formatted_known_call_trailing_commas": formatted_commas,
                    "source_allowlisted_sha256": hex256(source_projection.encode("utf-8")),
                    "formatted_allowlisted_sha256": hex256(formatted_projection.encode("utf-8")),
                    "original_nonwhitespace_sha256": hex256(
                        without_whitespace(original).encode("utf-8")),
                    "formatted_nonwhitespace_sha256": hex256(
                        without_whitespace(formatted).encode("utf-8")),
                    "formatter_idempotent": formatter_idempotent,
                    "second_pass_sha256": hex256(formatted_twice),
                    "second_pass_summary": (second.stdout + second.stderr).decode(
                        "utf-8", "replace").strip(),
                }
                output_json(result)
                assert allowlisted_nonwhitespace_equal, (
                    label + ": nonwhitespace change exceeds one verified trailing call comma"
                )
                assert formatter_idempotent, label + ": second formatter pass changed bytes"
        # Preserve and compare every diff content/context line, ignoring only
        # the expected A/B line-coordinate and file-label differences.
        a_diff = (OUTPUT / "A.unified.diff").read_text(encoding="utf-8")
        b_diff = (OUTPUT / "B.unified.diff").read_text(encoding="utf-8")
        result["same_two_formatter_hunks"] = (
            result["variants"]["A"]["diff_hunk_count"] == 2
            and result["variants"]["B"]["diff_hunk_count"] == 2
            and diff_content_hunks(a_diff) == diff_content_hunks(b_diff)
        )
        output_json(result)
        assert result["same_two_formatter_hunks"], "Unexpected A/B hunk mismatch"
        # Postcondition: the authoritative branch and both locked blobs are intact.
        assert command("git", "rev-parse", "HEAD").stdout.decode().strip() == head
        assert command("git", "show", "HEAD:" + PLANNER).stdout == raw_b
        assert command("git", "show", SOURCE_A + ":" + PLANNER).stdout == raw_a
        assert (ROOT / PLANNER).read_bytes() == raw_b
        result["source_locks_preserved"] = True
        result["status"] = "FORMAT_DIFF_CAPTURED_WITH_DRIFT" if any(
            v["changed"] for v in result["variants"].values()
        ) else "FORMAT_DIFF_CAPTURED_CLEAN"
        output_json(result)
        result["strict_nonwhitespace_gate_satisfied"] = all(
            v["nonwhitespace_equal"] for v in result["variants"].values()
        )
        result["allowlisted_copy_only_gate_pass"] = True
        output_json(result)
        print("STAGE7_FORMAT_COPY_ONLY_ALLOWLISTED_QA_PASS", result["status"],
              "A_changed=", result["variants"]["A"]["changed"],
              "B_changed=", result["variants"]["B"]["changed"],
              "source_locks_preserved=True", "head=" + head)
    except Exception as error:
        result["status"] = "INCOMPLETE"
        result["error"] = repr(error)
        output_json(result)
        raise


if __name__ == "__main__":
    main()
