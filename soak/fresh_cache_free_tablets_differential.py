#!/usr/bin/env python3
"""Fresh bounded cache-free TABLETS 3x5 signed diagnostic, never certification.

The candidate worker has no reference import, checkpoint seed, or production read.
The pinned reference runs in three different cold processes solely for comparison.
"""
from __future__ import annotations
from bisect import bisect_left
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from time import monotonic

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
sys.path.insert(0, str(HERE))
from tablets_unseeded_closure_contract import audit_sources
from independent_year_geometry_oracle import FOUNDATION, MAX_YEAR, MAX_GAP, GateLedger
from independent_five_field_date import independent_signed_gap, independent_rank, date_from_ledger
import independent_date_combinatorics as combinatorics
from tablets_pinned_five_field_differential import (
    PINNED_SHA, PINNED_MODULE_SHA256, verify_git_roots, run_worker
)

TARGETS = (-278523, -278522, -278521)
CLOSURE = "81aea10577986a9ed46dcbf7b79c38954f24fa4de01323a756cd4d43f76ebef5"
TRACE = "caaf71076bf738981db4b75af441ae82a8e4341970d24606ffc59bd208f64193"
QUESTIONS = 29523
LIMIT = 32768
PASS = "PASS_FRESH_CACHE_FREE_TABLETS_3X5_DIAGNOSTIC_NOT_CERTIFIED"

class DiagnosticError(ValueError):
    pass

def check(condition, code):
    if not condition:
        raise DiagnosticError(code)

def strict_rows(rows):
    check(type(rows) is list and len(rows) == 3, "E_ROWS_COUNT")
    for day, row in zip(TARGETS, rows):
        check(type(row) is dict and type(row.get("day")) is int
              and row["day"] == day, "E_ROWS_DAY")
        v = row.get("five_fields")
        check(type(v) is list and len(v) == 5
              and all(type(x) is int and x >= 1 for x in v)
              and 1 <= v[1] <= 17 and 1 <= v[3] <= 47
              and 1 <= v[4] <= 123, "E_ROWS_FIELDS")
    return rows

def validate_candidate(doc):
    check(type(doc) is dict
          and doc.get("isolated") is True
          and doc.get("cache_free") is True
          and doc.get("cache_empty_at_import") is True
          and doc.get("source_only_unseeded") is True
          and doc.get("checkpoint_seed_used") is False
          and doc.get("pinned_date_compared") is False
          and doc.get("full_date_certified") is False
          and doc.get("source_closure_sha256") == CLOSURE
          and type(doc.get("signed_gate_questions")) is int
          and doc["signed_gate_questions"] == QUESTIONS
          and doc.get("signed_transcript_sha256") == TRACE
          and doc.get("targets") == list(TARGETS)
          and doc.get("production_limit_unchanged") == 8192,
          "E_CANDIDATE_PROVENANCE")
    brackets = doc.get("brackets")
    check(type(brackets) is list and len(brackets) == 3, "E_BRACKETS")
    for day, b in zip(TARGETS, brackets):
        check(type(b) is dict and type(b.get("index")) is int
              and type(b.get("low")) is int and type(b.get("high")) is int
              and b["low"] < day <= b["high"], "E_BRACKET_COVERAGE")
    strict_rows(doc.get("rows"))
    return doc

def compare_rows(candidate, pinned):
    a, b = strict_rows(candidate), strict_rows(pinned)
    matches = sum(x == y for left, right in zip(a, b)
                  for x, y in zip(left["five_fields"], right["five_fields"]))
    check(matches == 15, "E_PINNED_3X5_MISMATCH")
    return matches

def worker(seconds):
    check(sys.flags.isolated == 1 and type(seconds) is int
          and 60 <= seconds <= 660, "E_WORKER_ISOLATION")
    closure = audit_sources(ROOT)
    check(closure["closure_sha256"] == CLOSURE
          and not closure["imported_checkpoint_seeds"], "E_SOURCE_CLOSURE")
    cached = combinatorics._count_bounded_compositions
    check(hasattr(cached, "cache_info") and cached.cache_info().currsize == 0,
          "E_WARM_CACHE")
    combinatorics._count_bounded_compositions = cached.__wrapped__
    check(not hasattr(combinatorics._count_bounded_compositions, "cache_info"),
          "E_DISABLE_CACHE")
    deadline = monotonic() + seconds
    widths = {}
    positive, negative, high, low = 0, 0, FOUNDATION, FOUNDATION
    # Read signed real gates, never previous checkpoints or an evidence ledger.
    while high < TARGETS[-1] + 2 * MAX_YEAR + MAX_GAP:
        check(monotonic() < deadline and len(widths) < LIMIT, "E_FORWARD_BUDGET")
        positive += 1
        gap = independent_signed_gap(positive, deadline=deadline)
        check(type(gap) is int and 42 <= gap <= MAX_GAP, "E_FORWARD_GAP")
        widths[positive] = gap
        high += gap
    while low > FOUNDATION - MAX_YEAR:
        check(monotonic() < deadline and len(widths) < LIMIT, "E_BACKWARD_BUDGET")
        negative += 1
        gap = independent_signed_gap(-negative, deadline=deadline)
        check(type(gap) is int and 42 <= gap <= MAX_GAP, "E_BACKWARD_GAP")
        widths[-negative] = gap
        low -= gap
    check(len(widths) == positive + negative, "E_COUNT")
    ledger = GateLedger(FOUNDATION, -negative, positive, lambda i: widths[i],
                        max_questions=LIMIT, segment_limit=4096, deadline=deadline)
    check(ledger.question_count == len(widths)
          and ledger.day(-negative) == low and ledger.day(positive) == high,
          "E_LEDGER")
    transcript = "SIGNED_UNSEEDED_GATE_V1\n" + "".join(
        f"{i}:{widths[i]}\n" for i in range(-negative, 0)
    ) + "".join(f"{i}:{widths[i]}\n" for i in range(1, positive + 1))
    signature = hashlib.sha256(transcript.encode("ascii")).hexdigest()
    days = [ledger.day(i) for i in range(-negative, positive + 1)]
    brackets = []
    for target in TARGETS:
        j = bisect_left(days, target)
        check(0 < j < len(days), "E_LEDGER_TARGET")
        brackets.append({"day": target, "index": j-negative,
                         "low": days[j-1], "high": days[j]})
    rank = independent_rank(FOUNDATION, deadline=deadline)
    rows = [{"day": d, "five_fields": list(date_from_ledger(
        ledger, FOUNDATION, d, rank, deadline=deadline))} for d in TARGETS]
    check(cached.cache_info().currsize == 0, "E_CACHE_REENTERED")
    return {"isolated": True, "cache_free": True,
            "cache_empty_at_import": True, "source_only_unseeded": True,
            "checkpoint_seed_used": False, "pinned_date_compared": False,
            "source_closure_sha256": closure["closure_sha256"],
            "signed_gate_questions": len(widths), "signed_transcript_sha256": signature,
            "brackets": brackets, "rows": rows, "targets": list(TARGETS),
            "production_limit_unchanged": 8192,
            "full_date_certified": False, "certifiable": False}

def parent(pinned_root, worker_seconds, total_seconds):
    check(type(worker_seconds) is int and 60 <= worker_seconds <= 660
          and type(total_seconds) is int and
          worker_seconds <= total_seconds <= 1000, "E_TIME_BOUNDS")
    start = monotonic()
    head = verify_git_roots(ROOT, pinned_root)
    check(audit_sources(ROOT)["closure_sha256"] == CLOSURE, "E_PARENT_CLOSURE")
    with tempfile.TemporaryDirectory(prefix="cache-free-tablets-") as home:
        env = {"HOME": home, "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
               "PYTHONNOUSERSITE": "1", "PYTHONDONTWRITEBYTECODE": "1",
               "PYTHONHASHSEED": "0"}
        proc = subprocess.run(
            [sys.executable, "-I", str(Path(__file__).resolve()), "--worker",
             "--worker-seconds", str(worker_seconds)],
            text=True, capture_output=True, timeout=worker_seconds+20,
            cwd=home, env=env, check=False)
    check(proc.returncode == 0 and len(proc.stdout) < 16000,
          "E_FRESH_WORKER_" + str(proc.returncode) + "_" + proc.stderr[-350:])
    candidate = validate_candidate(json.loads(proc.stdout))
    references = []
    for day in TARGETS:
        remain = int(total_seconds - (monotonic() - start))
        check(remain > 0, "E_TOTAL_TIMEOUT")
        references.append(run_worker(ROOT/"soak"/"pinned_five_field_worker.py",
                                     pinned_root, day, seconds=min(180, remain)))
    matched = compare_rows(candidate["rows"], references)
    return {"status": PASS, "independent_commit": head,
            "pinned_commit": PINNED_SHA, "pinned_module_sha256": PINNED_MODULE_SHA256,
            "source_closure_sha256": CLOSURE,
            "signed_gate_questions": candidate["signed_gate_questions"],
            "signed_transcript_sha256": candidate["signed_transcript_sha256"],
            "structural_brackets": candidate["brackets"],
            "candidate_rows": candidate["rows"], "pinned_rows": references,
            "five_field_comparisons": matched, "cache_free": True,
            "candidate_cold_isolated": True, "pinned_cold_processes": 3,
            "distinct_git_roots": True,
            "pinned_reference_used_only_for_comparison": True,
            "pinned_static_checkpoints_may_be_used": True,
            "checkpoint_seed_used": False, "production_limit_unchanged": 8192,
            "full_date_certified": False, "certifiable": False,
            "elapsed_seconds": round(monotonic()-start, 3)}

def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--worker", action="store_true")
    parser.add_argument("--worker-seconds", type=int, default=620)
    parser.add_argument("--total-seconds", type=int, default=960)
    parser.add_argument("--pinned-root", type=Path)
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args(argv)
    if args.worker:
        print(json.dumps(worker(args.worker_seconds), sort_keys=True))
        return 0
    parser.error("--pinned-root and --evidence required") if (
        args.pinned_root is None or args.evidence is None) else None
    try:
        report = parent(args.pinned_root, args.worker_seconds, args.total_seconds)
    except Exception as exc:
        report = {"status": "FAIL_FRESH_CACHE_FREE_TABLETS",
                  "error_type": type(exc).__name__, "error": str(exc)[-600:],
                  "full_date_certified": False, "certifiable": False}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report, sort_keys=True, indent=2)+"\n",
                             encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == PASS else 2

if __name__ == "__main__":
    raise SystemExit(main())
