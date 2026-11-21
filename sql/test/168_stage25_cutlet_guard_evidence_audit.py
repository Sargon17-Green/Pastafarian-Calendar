#!/usr/bin/env python3
"""SQL+Tamil Slice25: audit exact original candidate and Stage1 Actions ZIPs.

This script inspects existing immutable run evidence. It never runs PostgreSQL,
recalculates calendar goldens, or changes production files.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import zipfile
from pathlib import Path

PROJECT = "PC-BRANCH-SQL-TAMIL"
HEAD = "dca2b8e5594c2c80e24d68604d79bf45f140a00a"
EXPECTED = {
    "anchor": "1a90dd0fe7fedb5114de0b90039b7d741e684e08e1a8626e56c3b3aba69d76c9",
    "failed": "5b972d19d81e14b6e885a0d43d4647159b78ac693780bd7ad100939efac26873",
    "stage1": "27ad991c1363ccc9112712ba95fefbe3e3cb1348abb7c1fd82b3a7704bc62c85",
}
FIELDS = ("year_number", "cutlet_name", "day_in_cutlet", "month_name", "day_in_month")


def require(ok: bool, message: str) -> None:
    if not ok:
        raise AssertionError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def extract(path: Path, expected: str) -> dict[str, bytes]:
    data = path.read_bytes()
    require(sha256(data) == expected, f"{path}: original ZIP SHA256 mismatch")
    with zipfile.ZipFile(path) as archive:
        require(archive.testzip() is None, f"{path}: ZIP CRC failure")
        names = archive.namelist()
        require(len(names) == len(set(names)), f"{path}: duplicate ZIP members")
        require(all(not n.startswith("/") and ".." not in Path(n).parts for n in names),
                f"{path}: unsafe ZIP member")
        return {n: archive.read(n) for n in names}


def utf(files: dict[str, bytes], name: str) -> str:
    require(name in files, f"missing original ZIP member: {name}")
    return files[name].decode("utf-8")


def candidate(files: dict[str, bytes], case: str, success: bool) -> str:
    versions = utf(files, "versions.txt")
    for line in (f"PROJECT_ID={PROJECT}", f"GITHUB_SHA={HEAD}",
                 "GITHUB_REF_NAME=SQL+தமிழ்", f"CASE={case}",
                 "PRODUCTION_SOURCE_BLOB=42acfb80e9eabfd9d091176643763ee7d7bca9ee",
                 "postgres (PostgreSQL) 17.12"):
        require(line in versions, f"{case}: missing version/source lock {line}")
    declared = {}
    for line in utf(files, "source-sha256.txt").splitlines():
        m = re.fullmatch(r"([0-9a-f]{64})\s+(.+)", line)
        require(m is not None, f"{case}: invalid SHA256 manifest line")
        declared[m.group(2)] = m.group(1)
    for item in ("20_candidate.sql", "test.sql"):
        require(sha256(files[item]) == declared[f"slice25-gate-guard-evidence/{item}"],
                f"{case}: generated source/test SQL SHA256 mismatch")
    result = utf(files, "postgres-results.txt")
    fields = re.findall(r"SLICE25_NATIVE_FIELD_PASS=" + re.escape(case) +
                        r"\.([a-z_]+)", result)
    if success:
        require(len(fields) == 5 and set(fields) == set(FIELDS),
                f"{case}: five-field golden evidence incomplete")
        require(f"SLICE25_MATRIX_GREEN=native:{case}" in result,
                f"{case}: no PostgreSQL green marker")
        require(re.search(r"SLICE25_CASE_ELAPSED_MS=" + re.escape(case) +
                          r":\d+\.\d+", result) is not None,
                f"{case}: missing actual PG timing")
        require(f"SLICE25_CUTLET_GATE_GUARD_GREEN=native:{case}" ==
                utf(files, "completion.txt").strip(), f"{case}: completion mismatch")
    else:
        require(not fields and "SLICE25_MATRIX_GREEN=" not in result,
                f"{case}: unexpected PASS notice in failure")
        for phrase in ("canceling statement due to statement timeout",
                       'SQL function "sauce" statement 1',
                       "build_year_structure(numeric,pastafari_sql_tamil.year_rec) line 12"):
            require(phrase in result, f"{case}: missing diagnostic stack {phrase}")
        require("choose_cutlet_partition(" not in result,
                f"{case}: timeout stack unexpectedly shows cutlet-partition")
        require("completion.txt" not in files, f"{case}: failed job has completion")
    for name in ("math-selftest.txt", "corpus-audit.txt", "static-contract.txt"):
        require(name in files, f"{case}: static evidence missing: {name}")
    print(f"{case}: original ZIP SHA256/CRC/versions/source/test locks PASS; "
          f"PG17 {'5/5 native fields PASS' if success else 'sauce timeout, no 5-field PASS'}")
    return sha256(files["20_candidate.sql"])


def stage1(files: dict[str, bytes]) -> None:
    versions = utf(files, "versions.txt")
    require(f"Git SHA: {HEAD}" in versions, "Stage1 exact-SHA mismatch")
    ref = utf(files, "reference.txt")
    iso = utf(files, "isolation.txt")
    for token in ("ordinary_52_of_52", "saved_sum_7_of_7"):
        require(token in ref, f"Stage1 missing native gate: {token}")
    require("isolation_4_of_4" in iso, "Stage1 missing production isolation")
    print("Stage1: original ZIP SHA256/CRC PASS; 52+7+4 native gate markers PRESENT")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--anchor", required=True, type=Path)
    ap.add_argument("--failed", required=True, type=Path)
    ap.add_argument("--stage1", required=True, type=Path)
    args = ap.parse_args()
    anchor = candidate(extract(args.anchor, EXPECTED["anchor"]),
                       "anchor_cutlet_boundary", True)
    failed = candidate(extract(args.failed, EXPECTED["failed"]),
                       "prev_3_prev_middle", False)
    require(anchor == failed, "Two jobs used different generated cutlet candidates")
    stage1(extract(args.stage1, EXPECTED["stage1"]))
    print("TWO_JOB_SAME_CANDIDATE_SHA256=" + anchor)
    print("SQL_TAMIL_SLICE25_GUARD_PILOT=NOT_ACCEPTED")
    print("NEXT=Isolate sauce/bowl_round before cutlet-partition; no blind retry")


if __name__ == "__main__":
    main()
