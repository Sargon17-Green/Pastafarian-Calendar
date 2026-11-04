#!/usr/bin/env python3
"""Bounded real signed TABLETS gate-to-five-field diagnostic, not certification.

Independent structural sauce supplies every gate width. The pinned historical
source is used only to check widths, never as a checkpoint or date oracle.
A separate pinned full-date differential and cache-isolation proof are pending.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
from time import monotonic

from audit_independent_tablets_brackets import audit_tablets
from independent_year_geometry_oracle import FOUNDATION, MAX_YEAR, GateLedger
from independent_five_field_date import date_from_ledger, independent_rank, independent_signed_gap
from tablets_five_field_contract import TARGETS
from verify_pinned_gate_checkpoints import PINNED_SHA, pinned_source

MAX_QUESTIONS = 32768
STATUS = "PASS_REAL_UNSEEDED_FIVE_FIELDS_PINNED_DATE_NOT_COMPARED_NOT_CERTIFIED"

class RealProbeError(ValueError):
    pass

def compute(independent_gap, reference_gap, rank, *, deadline, segment_limit=4096):
    if (not callable(independent_gap) or not callable(reference_gap)
            or independent_gap is reference_gap or not callable(rank)
            or type(deadline) not in (int, float) or deadline <= monotonic()
            or type(segment_limit) is not int or not 1 <= segment_limit <= 8192):
        raise RealProbeError("E_REAL_PROBE_INPUT")
    widths = {}
    def independent(index):
        if index in widths or monotonic() >= deadline:
            raise RealProbeError("E_REAL_PROBE_DUPLICATE_OR_TIMEOUT")
        value = independent_gap(index)
        if type(value) is not int or not 42 <= value <= 963:
            raise RealProbeError("E_REAL_PROBE_INDEPENDENT_RANGE")
        widths[index] = value
        return value
    def reference(index):
        value = reference_gap(index)
        if type(value) is not int or not 42 <= value <= 963:
            raise RealProbeError("E_REAL_PROBE_REFERENCE_RANGE")
        return value
    receipt = audit_tablets(independent, reference, max_questions=32256,
                            segment_limit=segment_limit, deadline=deadline)
    last_positive = receipt["questions"]
    positive_day = receipt["brackets"][-1]["bracket_high"]
    if set(widths) != set(range(1, last_positive+1)):
        raise RealProbeError("E_REAL_PROBE_PREFIX")
    def extension(index):
        a = independent(index)
        b = reference(index)
        if a != b:
            raise RealProbeError(f"E_REAL_PROBE_MISMATCH_{index}")
        return a
    # The negative Year-5000 candidate window is also reconstructed unseeded.
    negative_day = FOUNDATION
    negative_count = 0
    while negative_day > FOUNDATION - MAX_YEAR:
        negative_count += 1
        if negative_count + last_positive >= MAX_QUESTIONS:
            raise RealProbeError("E_REAL_PROBE_NEGATIVE_BUDGET")
        negative_day -= extension(-negative_count)
    # A year ending at the last target still needs a complete future candidate
    # window. Two full-year maxima and a maximum gap provide the lookahead.
    target_coverage = TARGETS[-1] + 2*MAX_YEAR + 963
    while positive_day < target_coverage:
        last_positive += 1
        if last_positive + negative_count > MAX_QUESTIONS:
            raise RealProbeError("E_REAL_PROBE_FORWARD_BUDGET")
        positive_day += extension(last_positive)
    if len(widths) != last_positive + negative_count:
        raise RealProbeError("E_REAL_PROBE_MISSING_INDEX")
    ledger = GateLedger(FOUNDATION, -negative_count, last_positive,
                        lambda index: widths[index], max_questions=MAX_QUESTIONS,
                        segment_limit=segment_limit, deadline=deadline)
    for bracket in receipt["brackets"]:
        i = bracket["gate_index"]
        if ledger.day(i-1) != bracket["bracket_low"] or ledger.day(i) != bracket["bracket_high"]:
            raise RealProbeError("E_REAL_PROBE_BRACKET")
    if ledger.day(-negative_count) > FOUNDATION-MAX_YEAR or ledger.day(last_positive) < target_coverage:
        raise RealProbeError("E_REAL_PROBE_COVERAGE")
    rows = []
    for target in TARGETS:
        if monotonic() >= deadline:
            raise RealProbeError("E_REAL_PROBE_DATE_DEADLINE")
        values = date_from_ledger(ledger, FOUNDATION, target, rank, deadline=deadline)
        rows.append({"day": target, "five_fields": list(values)})
    transcript = "SIGNED_UNSEEDED_GATE_V1\n" + "".join(
        f"{i}:{widths[i]}\n" for i in range(-negative_count,0)
    ) + "".join(f"{i}:{widths[i]}\n" for i in range(1,last_positive+1))
    return {
        "status": STATUS, "rows": rows, "targets": list(TARGETS), "cases": 3,
        "fields_per_case": 5, "positive_prefix_questions": receipt["questions"],
        "negative_questions": negative_count,
        "forward_extension_questions": last_positive-receipt["questions"],
        "total_unique_gap_questions": len(widths),
        "signed_transcript_sha256": hashlib.sha256(transcript.encode("ascii")).hexdigest(),
        "positive_audit_trace_sha256": receipt["trace_sha256"],
        "segment_limit": segment_limit, "checkpoint_seed_used": False,
        "pinned_date_comparison_performed": False,
        "external_cache_independence_certified": False,
        "full_date_certified": False, "certifiable": False,
        "production_gate_limit_unchanged": 8192,
    }

def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--pinned-root", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=540)
    args = parser.parse_args(argv)
    started = monotonic()
    report = {"status": "FAIL_REAL_UNSEEDED_FIVE_FIELDS",
              "full_date_certified": False, "certifiable": False,
              "checkpoint_seed_used": False}
    try:
        if not 1 <= args.timeout_seconds <= 600:
            raise RealProbeError("E_REAL_PROBE_TIME_BUDGET")
        root = Path(__file__).resolve().parent.parent
        def sha(path):
            return subprocess.check_output(["git","-C",str(path),"rev-parse","HEAD"],
                                           text=True, timeout=12).strip()
        branch_sha = os.environ.get("GITHUB_SHA")
        if (branch_sha is None or len(branch_sha) != 40
                or sha(root) != branch_sha
                or os.environ.get("GITHUB_REF_NAME") != "Kotlin+Cymraeg"):
            raise RealProbeError("E_REAL_PROBE_BRANCH_SOURCE")
        if sha(args.pinned_root.parent) != PINNED_SHA:
            raise RealProbeError("E_REAL_PROBE_PINNED_SOURCE")
        gap, checkpoints, source_sha256, ctx = pinned_source(args.pinned_root, PINNED_SHA)
        if checkpoints.get(0) != FOUNDATION:
            raise RealProbeError("E_REAL_PROBE_FOUNDATION")
        deadline = started + args.timeout_seconds
        report = compute(lambda i: independent_signed_gap(i, deadline=deadline),
                         gap, independent_rank(FOUNDATION, deadline=deadline),
                         deadline=deadline)
        if report["total_unique_gap_questions"] != ctx.integration_gate_questions:
            raise RealProbeError("E_REAL_PROBE_SOURCE_QUESTION_ACCOUNTING")
        report.update({"independent_commit": branch_sha, "pinned_commit": PINNED_SHA,
                       "pinned_module_sha256": source_sha256})
    except Exception as exc:
        report = {"status": "FAIL_REAL_UNSEEDED_FIVE_FIELDS",
                  "error_type": type(exc).__name__, "error": str(exc)[:500],
                  "full_date_certified": False, "certifiable": False,
                  "checkpoint_seed_used": False}
    report["elapsed_seconds"] = round(monotonic()-started,3)
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k != "rows"},sort_keys=True))
    return 0 if report["status"] == STATUS else 2

if __name__ == "__main__":
    raise SystemExit(main())
