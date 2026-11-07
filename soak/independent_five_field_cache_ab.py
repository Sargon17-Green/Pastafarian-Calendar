#!/usr/bin/env python3
"""Bounded cold-process cache A/B for the independent FOUNDATION date path.

Two Python -I workers, each recomputing its own signed ledger from FOUNDATION.
Mode 'free' bypasses the bounded-composition memoizer without editing source.
An additional external iterative DP cross-check covers small compositions.
No pinned Python, production Kotlin, checkpoint table, TABLETS replay, or certify.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from time import monotonic

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))

from tablets_unseeded_closure_contract import audit_sources
from independent_year_geometry_oracle import FOUNDATION, GateLedger
import independent_date_combinatorics as combinatorics
from independent_five_field_date import (
    date_from_ledger, independent_rank, independent_signed_gap,
)

TARGETS = (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1)
MODES = ("cached", "free")
FIRST, LAST = -180, 180
SOURCE_CLOSURE_SHA = "81aea10577986a9ed46dcbf7b79c38954f24fa4de01323a756cd4d43f76ebef5"
STATUS = "PASS_BOUNDED_CACHE_FREE_FOUNDATION_DIAGNOSTIC_NOT_CERTIFIED"


class CacheAuditError(ValueError):
    pass


def require(condition: bool, code: str) -> None:
    if not condition:
        raise CacheAuditError(code)


def external_bounded_dp(total: int, slots: int, low: int, high: int) -> int:
    """Iterative coefficient convolution, NOT the source inclusion-exclusion."""
    require(all(type(x) is int for x in (total, slots, low, high))
            and 0 <= total <= 11 and 0 <= slots <= 4
            and 1 <= low <= high <= 3, "E_DP_SCOPE")
    ways = [1] + [0] * total
    for _ in range(slots):
        nxt = [0] * (total + 1)
        for subtotal, count in enumerate(ways):
            for term in range(low, high + 1):
                if subtotal + term <= total:
                    nxt[subtotal + term] += count
        ways = nxt
    return ways[total]


def small_composition_witness() -> str:
    rows = []
    for slots in range(5):
        for low in (1, 2):
            for high in range(low, 4):
                for total in range(12):
                    actual = combinatorics.count_bounded_compositions(
                        total, slots, low, high)
                    expected = external_bounded_dp(total, slots, low, high)
                    require(type(actual) is int and actual == expected,
                            "E_DP_MISMATCH")
                    rows.append([total, slots, low, high, expected])
    return hashlib.sha256(
        json.dumps(rows, separators=(",", ":")).encode("ascii")).hexdigest()


def checked_fields(row: object) -> list[int]:
    require(type(row) is list and len(row) == 5
            and all(type(x) is int and x >= 1 for x in row)
            and 1 <= row[1] <= 17 and 1 <= row[3] <= 47
            and 1 <= row[4] <= 123, "E_DATE_FIVE_FIELDS")
    return row


def validate_worker(doc: object, mode: str, digest: str) -> dict:
    require(type(doc) is dict and doc.get("mode") == mode
            and doc.get("isolated") is True
            and doc.get("cache_empty_at_import") is True
            and doc.get("cache_enabled") is (mode == "cached")
            and doc.get("source_closure_sha256") == SOURCE_CLOSURE_SHA
            and doc.get("dp_digest") == digest
            and doc.get("gate_questions") == LAST - FIRST
            and doc.get("targets") == list(TARGETS)
            and doc.get("full_date_certified") is False,
            "E_WORKER_PROVENANCE")
    rows = doc.get("rows")
    require(type(rows) is list and len(rows) == 3,
            "E_WORKER_ROWS")
    for row, target in zip(rows, TARGETS):
        require(type(row) is dict and type(row.get("day")) is int
                and row["day"] == target, "E_WORKER_TARGET")
        checked_fields(row.get("five_fields"))
    return doc


def isolated_worker(mode: str) -> dict:
    require(sys.flags.isolated == 1 and mode in MODES, "E_NOT_ISOLATED")
    closure = audit_sources(ROOT)
    require(closure["closure_sha256"] == SOURCE_CLOSURE_SHA
            and not closure["imported_checkpoint_seeds"],
            "E_CLOSURE_DRIFT")
    memoized = combinatorics._count_bounded_compositions
    require(hasattr(memoized, "cache_info")
            and memoized.cache_info().currsize == 0,
            "E_WARM_AT_IMPORT")
    if mode == "free":
        combinatorics._count_bounded_compositions = memoized.__wrapped__
    digest = small_composition_witness()
    deadline = monotonic() + 115
    queries = 0

    def gap(index: int) -> int:
        nonlocal queries
        queries += 1
        return independent_signed_gap(index, deadline=deadline)

    ledger = GateLedger(FOUNDATION, FIRST, LAST, gap,
                        max_questions=LAST - FIRST, segment_limit=180,
                        deadline=deadline)
    selector = independent_rank(FOUNDATION, deadline=deadline)
    rows = [{"day": day,
             "five_fields": list(date_from_ledger(
                 ledger, FOUNDATION, day, selector, deadline=deadline))}
            for day in TARGETS]
    require(queries == LAST - FIRST, "E_GAP_QUESTION_COUNT")
    require(mode == "free" or memoized.cache_info().currsize > 0,
            "E_CACHE_DID_NOT_EXERCISE")
    return {
        "mode": mode, "isolated": True, "cache_empty_at_import": True,
        "cache_enabled": mode == "cached",
        "source_closure_sha256": closure["closure_sha256"],
        "dp_digest": digest, "gate_questions": queries,
        "targets": list(TARGETS), "rows": rows,
        "source_only_unseeded": True,
        "full_date_certified": False, "certifiable": False,
    }


def run_parent(worker_timeout: int) -> dict:
    require(type(worker_timeout) is int and 10 <= worker_timeout <= 140,
            "E_TIMEOUT_BOUNDS")
    closure = audit_sources(ROOT)
    require(closure["closure_sha256"] == SOURCE_CLOSURE_SHA,
            "E_CLOSURE_DRIFT")
    digest = small_composition_witness()
    results = []
    for mode in MODES:
        argv = [sys.executable, "-I", "-B", str(Path(__file__).resolve()),
                "--worker", "--mode", mode]
        process = subprocess.run(argv, capture_output=True, text=True,
                                 timeout=worker_timeout, cwd=str(ROOT),
                                 check=False)
        require(process.returncode == 0
                and len(process.stdout) < 12000,
                "E_COLD_WORKER_" + mode + "_" + str(process.returncode))
        try:
            worker = json.loads(process.stdout.strip())
        except ValueError as exc:
            raise CacheAuditError("E_WORKER_JSON_" + mode) from exc
        results.append(validate_worker(worker, mode, digest))
    matches = sum(1 for left, right in zip(
        results[0]["rows"], results[1]["rows"])
        for a, b in zip(left["five_fields"], right["five_fields"])
        if a == b)
    require(matches == 15 and results[0]["rows"] == results[1]["rows"],
            "E_CACHE_AB_DATE_MISMATCH")
    return {
        "status": STATUS, "source_closure_sha256": SOURCE_CLOSURE_SHA,
        "cold_isolated_workers": 2, "cache_modes": list(MODES),
        "targets": list(TARGETS), "signed_gate_questions_per_worker": 360,
        "external_dp_digest": digest,
        "five_field_comparisons": matches, "rows": results[0]["rows"],
        "checkpoint_seed_used": False, "pinned_date_compared": False,
        "full_date_certified": False, "certifiable": False,
        "tablets_not_executed": True, "production_limit_unchanged": 8192,
    }


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--worker", action="store_true")
    p.add_argument("--mode", choices=MODES)
    p.add_argument("--worker-timeout", type=int, default=140)
    p.add_argument("--evidence", type=Path)
    args = p.parse_args(argv)
    if args.worker:
        require(args.mode in MODES, "E_WORKER_MODE")
        print(json.dumps(isolated_worker(args.mode), sort_keys=True))
        return 0
    p.error("--evidence is required") if args.evidence is None else None
    try:
        report = run_parent(args.worker_timeout)
    except Exception as exc:
        report = {"status": "FAIL_BOUNDED_CACHE_AB", "error": str(exc)[:350],
                  "error_type": type(exc).__name__,
                  "full_date_certified": False, "certifiable": False}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n",
                             encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == STATUS else 2


if __name__ == "__main__":
    raise SystemExit(main())
