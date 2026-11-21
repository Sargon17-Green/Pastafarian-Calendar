#!/usr/bin/env python3
"""v149 read-only raw-bound two-engine whole-year technical comparison.

Unlike compare_years(), this gate requires both original stdout byte streams
and their v038 per-chunk native receipts, not only normalized JSONL.
Technical agreement is NOT source identity, algorithmic independence, trusted
execution, calendar correctness or official Soak certification.
Never imports, builds, launches or modifies any converter.
"""
from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import os
from pathlib import Path
import re
import stat
from typing import Any

from native_execution_receipt_v038 import canonical, verify_receipt
from recovery_store import validate_plan
from soak_scope_coverage_v127 import parse_json
from source_identity_gate_v036 import PROVENANCE_CONTRACT
from year_validator import YearCase, parse_line

SCHEMA = "PASTAFARI_SOAK_RAW_BOUND_WHOLE_YEAR_DIFF_V149/1"
MAX_CHUNK_BYTES = 64 * 1024 * 1024
MAX_YEAR_BYTES_PER_ENGINE = 128 * 1024 * 1024
MAX_RECEIPT_BYTES = 256 * 1024
SIGNED = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
FIELDS = ("year", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month")


def require(value: bool, message: str) -> None:
    if not value:
        raise ValueError(message)


def file_bytes(name: str, limit: int, visited: set[tuple[int, int]]) -> bytes:
    """Read once from an open regular-file handle; disallow cross-file aliases."""
    require(type(name) is str and bool(name), "evidence file path missing")
    with Path(name).open("rb") as handle:
        first = os.fstat(handle.fileno())
        require(stat.S_ISREG(first.st_mode), "evidence source is not a regular file")
        require(first.st_ino > 0, "physical file identity is unavailable")
        key = (first.st_dev, first.st_ino)
        require(key not in visited, "same physical evidence file reused")
        require(first.st_size <= limit, "evidence file exceeds size limit")
        payload = handle.read(limit + 1)
        last = os.fstat(handle.fileno())
        require(len(payload) <= limit and len(payload) == first.st_size,
                "evidence read truncated or changed size")
        require((first.st_dev, first.st_ino, first.st_size, first.st_mtime_ns)
                == (last.st_dev, last.st_ino, last.st_size, last.st_mtime_ns),
                "evidence file mutated during read")
        visited.add(key)
        return payload


def check_engine(plan: dict, plan_sha: str, case: YearCase, engine: str,
                 bundles: list[dict], visited: set[tuple[int, int]]) -> tuple[list, dict]:
    require(type(bundles) is list and len(bundles) > 0,
            "no raw and normalized receipt bundles for engine: " + engine)
    next_day = int(case.first_target_day)
    final_day = int(case.last_target_day)
    days = []
    total_bytes = 0
    receipts = []
    for i, bundle in enumerate(bundles):
        require(type(bundle) is dict and set(bundle) ==
                {"ordinal", "raw_path", "normalized_path", "receipt_path"},
                "malformed chunk evidence descriptor")
        require(type(bundle["ordinal"]) is int and bundle["ordinal"] == i,
                "missing, duplicate or out-of-order chunk ordinal")
        raw = file_bytes(bundle["raw_path"], MAX_CHUNK_BYTES, visited)
        normalized = file_bytes(bundle["normalized_path"], MAX_CHUNK_BYTES, visited)
        receipt_bytes = file_bytes(bundle["receipt_path"], MAX_RECEIPT_BYTES, visited)
        total_bytes += len(raw) + len(normalized) + len(receipt_bytes)
        require(total_bytes <= MAX_YEAR_BYTES_PER_ENGINE,
                "year evidence exceeds bounded in-memory audit budget")
        receipt = parse_json(receipt_bytes)
        require(receipt.get("engine_id") == engine,
                "receipt claims a different engine identity")
        require(receipt.get("year") == case.year,
                "receipt claims a different year")
        require(receipt.get("chunk_ordinal") == i,
                "receipt chunk ordinal differs from input bundle")
        require(receipt.get("first_target_day") == str(next_day),
                "chunk sequence has gap, overlap or noncanonical first day")
        end_text = receipt.get("last_target_day")
        require(type(end_text) is str and SIGNED.fullmatch(end_text) is not None,
                "receipt last target is not canonical signed decimal")
        end = int(end_text)
        require(next_day <= end <= final_day,
                "chunk end exceeds year or precedes chunk start")
        require(end - next_day + 1 <= plan["chunk_days"],
                "chunk exceeds pinned chunk size")
        verified = verify_receipt(
            plan, plan_sha, engine, case.year, str(next_day), end_text, i,
            normalized, raw, receipt
        )
        require(verified["official_soak_authorized"] is False
                and verified["trusted_execution_attested"] is False
                and verified["independent_algorithm_attested"] is False,
                "receipt claims unauthorized independent execution")
        lines = normalized.splitlines(keepends=True)
        require(len(lines) == end - next_day + 1,
                "normalized line count not equal to pinned chunk range")
        for offset, line in enumerate(lines):
            target = next_day + offset
            day = parse_line(line.decode("utf-8"), len(days) + 1, case, target)
            days.append(day)
        receipts.append({
            "ordinal": i,
            "first_target_day": str(next_day),
            "last_target_day": end_text,
            "raw_stdout_sha256": hashlib.sha256(raw).hexdigest(),
            "normalized_chunk_sha256": hashlib.sha256(normalized).hexdigest(),
            "receipt_sha256": hashlib.sha256(receipt_bytes).hexdigest(),
            "source_commit": receipt["source_commit"],
            "binary_sha256": receipt["binary_sha256"],
        })
        next_day = end + 1
    require(next_day == final_day + 1,
            "incomplete original year: chunk receipts do not cover final day")
    require(len(days) == final_day - int(case.first_target_day) + 1,
            "incomplete original year: normalized row count differs")
    return days, {"engine_id": engine, "chunks": receipts,
                  "raw_bound_rows": len(days), "receipt_count": len(receipts)}


def audit(plan: dict, manifest: dict) -> dict:
    """Full synthetic/technical audit; never emits a certification PASS."""
    fixed = {
        "schema": SCHEMA, "halt_new_native_soak_dispatch": True,
        "original_converters_executed": 0,
        "original_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "trusted_execution_attested": False,
        "source_name_semantics_verified": False,
        "source_lineage_independence_verified": False,
        "official_soak_10000_pass": False,
    }
    try:
        require(type(plan) is dict and plan.get("contract") == PROVENANCE_CONTRACT,
                "raw-bound v149 requires strict source-identity v2 plan")
        validate_plan(plan)
        require(type(manifest) is dict and set(manifest) ==
                {"schema", "year", "engine_a", "engine_b", "bundles"}
                and manifest["schema"] == SCHEMA, "invalid v149 manifest")
        a, b = manifest["engine_a"], manifest["engine_b"]
        require(type(a) is str and type(b) is str and a != b and a and b,
                "two distinct engine IDs required")
        listed = [e["id"] for e in plan["engines"]]
        require(a in listed and b in listed, "engine not present in immutable plan")
        require(type(manifest["year"]) is str,
                "year must be canonical signed decimal string")
        year_list = [x for x in plan["years"] if x["year"] == manifest["year"]]
        require(len(year_list) == 1, "year absent/duplicated in plan")
        target = year_list[0]
        case = YearCase(plan["calculation_day"], manifest["year"],
                        target["first_target_day"], target["last_target_day"],
                        target["boundary_evidence_sha256"])
        case.validate()
        require(1 <= int(case.last_target_day) - int(case.first_target_day) + 1 <= 5778,
                "full original year extent invalid")
        bundles = manifest["bundles"]
        require(type(bundles) is dict and set(bundles) == {a, b},
                "both engines' bundles must be supplied exactly")
        plan_sha = hashlib.sha256(canonical(plan)).hexdigest()
        visited: set[tuple[int, int]] = set()
        left, left_receipts = check_engine(plan, plan_sha, case, a, bundles[a], visited)
        right, right_receipts = check_engine(plan, plan_sha, case, b, bundles[b], visited)
        report = {**fixed, "plan_sha256": plan_sha,
                  "year": case.year, "calculation_day": case.calculation_day,
                  "engine_a": a, "engine_b": b,
                  "raw_evidence_receipts": [left_receipts, right_receipts],
                  "total_day_pairs": len(left)}
        digest = hashlib.sha256()
        for i, (one, two) in enumerate(zip(left, right)):
            if one.t != two.t or one.normalized != two.normalized:
                differences = [
                    {"field": key, "field_index_one_based": j + 1,
                     "engine_a_value": one.normalized[j],
                     "engine_b_value": two.normalized[j]}
                    for j, key in enumerate(FIELDS)
                    if one.normalized[j] != two.normalized[j]
                ]
                return {**report, "status": "FIRST_NUMERIC_DIFFERENCE",
                        "fully_matched_days": i,
                        "first_mismatch_target_day": one.t,
                        "first_numeric_field_difference": differences[0] if differences else None,
                        "all_numeric_field_differences": differences,
                        "native_a": dataclasses.asdict(one),
                        "native_b": dataclasses.asdict(two),
                        "technically_equal_complete_year": False}
            digest.update(
                (one.t + ":" + json.dumps(one.normalized, ensure_ascii=False,
                                          separators=(",", ":")) + "\n").encode("utf-8")
            )
        return {**report, "status": "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED",
                "fully_matched_days": len(left),
                "canonical_daystream_sha256": digest.hexdigest(),
                "technically_equal_complete_year": True}
    except (ValueError, OSError, UnicodeError, KeyError, TypeError) as exc:
        return {**fixed, "status": "INVALID_EVIDENCE",
                "error": str(exc), "technically_equal_complete_year": False,
                "fully_matched_days": 0}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--plan", type=Path, required=True)
    p.add_argument("--evidence-manifest", type=Path, required=True)
    p.add_argument("--report", type=Path, required=True)
    args = p.parse_args()
    try:
        plan = parse_json(args.plan.read_bytes())
        manifest = parse_json(args.evidence_manifest.read_bytes())
        result = audit(plan, manifest)
    except (ValueError, OSError, UnicodeError) as exc:
        result = {"schema": SCHEMA, "status": "INVALID_EVIDENCE",
                  "error": str(exc), "halt_new_native_soak_dispatch": True,
                  "original_converters_executed": 0,
                  "original_years_certified": 0,
                  "official_soak_10000_pass": False}
    data = canonical(result) + b"\n"
    with args.report.open("xb") as stream:
        stream.write(data)
    print(data.decode("utf-8"), end="")
    # An informational technical match is not a scientific Soak PASS. Exit
    # code 0 means the evidence is structurally usable for human triage only.
    return 0 if result["status"] == "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
