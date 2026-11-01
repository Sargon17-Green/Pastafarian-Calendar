#!/usr/bin/env python3
"""Pinned, bounded Python↔Rust Stage04 differential (no copied legacy implementation)."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path

FOUNDATION = -15_055_671
ARCHIVED_SOURCE_BLOB = "405f461b2e2cdd170ded010e6f8046b78d6b4ab6"
EXPECTED_COLUMNS = ["index", "day", "oracle", "candidate"]


def offsets() -> list[int]:
    result = list(range(-3, 4))
    for bits in (127, 1025, 4096, 8192):
        result.extend((-(1 << bits), 1 << bits))
    assert len(result) == 15 and len(set(result)) == 15
    return result


def load_archived_source(path: Path) -> tuple[dict, str]:
    data = path.read_bytes()
    git_blob = hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()
    if git_blob != ARCHIVED_SOURCE_BLOB:
        raise ValueError(f"archived source blob mismatch: {git_blob}")
    scope: dict = {"__name__": "pinned_archived_day_counts"}
    exec(compile(data.decode("utf-8"), str(path), "exec"), scope, scope)
    if not callable(scope.get("oldDayTag")) or not callable(scope.get("dayTagWithFoundationScar")):
        raise ValueError("required archived functions are missing")
    if scope.get("FOUNDATION_DAY_OLD") != FOUNDATION:
        raise ValueError("archived foundation day mismatch")
    return scope, git_blob


def load_rust_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream, delimiter="\t")
        if reader.fieldnames != EXPECTED_COLUMNS:
            raise ValueError(f"unexpected Rust TSV fields: {reader.fieldnames}")
        rows = list(reader)
    if len(rows) != 15 or any(value is None for row in rows for value in row.values()):
        raise ValueError(f"expected exactly 15 complete Rust rows; got {len(rows)}")
    return rows


def run(source: Path, rust_tsv: Path, report_path: Path) -> bool:
    archived, blob = load_archived_source(source)
    rows = load_rust_rows(rust_tsv)
    results = []
    red = control = unexpected = patch_ok = candidate_ok = 0

    for index, (delta, row) in enumerate(zip(offsets(), rows)):
        day = FOUNDATION + delta
        if int(row["index"]) != index or int(row["day"]) != day:
            raise ValueError(f"Rust row index/day mismatch at {index}")
        oracle = int(row["oracle"])
        candidate = int(row["candidate"])
        capture: list[int] = []
        legacy = archived["oldDayTag"](day)
        patched = archived["dayTagWithFoundationScar"](day, capture)
        expected_red = delta >= 0
        expected_legacy_match = not expected_red
        legacy_matches = legacy == oracle
        observed_delta = oracle - legacy
        witness_ok = (legacy_matches == expected_legacy_match) and (observed_delta == (1 if expected_red else 0))
        capture_ok = capture == [legacy]
        patched_matches = patched == oracle
        candidate_matches = candidate == oracle
        oracle_positive = oracle > 0

        if witness_ok and capture_ok and patched_matches and candidate_matches and oracle_positive:
            if expected_red:
                red += 1
            else:
                control += 1
        else:
            unexpected += 1
        patch_ok += int(patched_matches and capture_ok)
        candidate_ok += int(candidate_matches)
        results.append({
            "index": index,
            "offset": str(delta),
            "day": str(day),
            "legacy": str(legacy),
            "oracle": str(oracle),
            "patched": str(patched),
            "candidate": str(candidate),
            "classification": "RED" if expected_red else "CONTROL",
            "pass": witness_ok and capture_ok and patched_matches and candidate_matches and oracle_positive,
        })

    passed = (red, control, unexpected, patch_ok, candidate_ok) == (8, 7, 0, 15, 15)
    report = {
        "project_id": "PC-BRANCH-RUST-AZERBAIJANI",
        "stage": "04/DISCOVERY02",
        "archived_release_commit": "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        "archived_source_blob_sha1": blob,
        "rust_rows": len(rows),
        "red": red,
        "control": control,
        "unexpected": unexpected,
        "patch_ok": patch_ok,
        "candidate_ok": candidate_ok,
        "status": "PASS" if passed else "FAIL",
        "stage_closure": "NOT_CLAIMED",
        "cases": results,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"STAGE04_CROSS_RUNTIME_RED={red} CONTROL={control} UNEXPECTED={unexpected}")
    print(f"STAGE04_CROSS_RUNTIME_PATCH_OK={patch_ok} CANDIDATE_OK={candidate_ok}")
    print(f"STAGE04_CROSS_RUNTIME_RESULT={report['status']} STAGE04_CLOSURE=NOT_CLAIMED")
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--rust-tsv", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    try:
        return 0 if run(args.source, args.rust_tsv, args.report) else 1
    except (OSError, ValueError, SyntaxError) as exc:
        parser.exit(2, f"Stage04 direct-runtime differential setup failed: {exc}\n")


if __name__ == "__main__":
    raise SystemExit(main())

