#!/usr/bin/env python3
"""Compare live Kotlin production year/gates to unseeded independent Python geometry.

No pinned checkpoints or module sharing. This is a bounded structural diagnostic,
NOT a TABLETS production date, full-date, or algorithmic certification.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

FOUNDATION = -15055671
TABLETS = -278522
MAX_GATE_GAP = 963
MAX_PRODUCTION_GATE_INDEX = 8192
ORACLE_HALF_WIDTH = 190
EXPECTED_CHECKS = 15
PASS = "PASS_BOUNDED_REAL_PRODUCTION_YEAR_GATE_UNSEEDED_NOT_CERTIFIED"
CANONICAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")

class AuditError(ValueError):
    pass

def number(value: str) -> int:
    if not isinstance(value, str) or not CANONICAL.fullmatch(value):
        raise AuditError("E_NONCANONICAL_INTEGER")
    return int(value)

def parse_transcript(raw: str) -> dict:
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_TRANSCRIPT_FORMAT")
    lines = raw.splitlines()
    if len(lines) != EXPECTED_CHECKS:
        raise AuditError("E_TRANSCRIPT_ROW_COUNT")
    observed: dict[str, object] = {"GATE": {}, "FIND": {}, "EXACT": {}}
    singleton = set()
    for line in lines:
        columns = line.split("\t")
        kind = columns[0]
        if kind == "GATE" and len(columns) == 3:
            i, day = map(number, columns[1:])
            if i not in range(-2, 3) or i in observed[kind]:
                raise AuditError("E_DUPLICATE_OR_INVALID_GATE")
            observed[kind][i] = day
        elif kind == "YEAR" and len(columns) == 6:
            if kind in singleton:
                raise AuditError("E_DUPLICATE_YEAR")
            singleton.add(kind)
            observed[kind] = tuple(map(number, columns[1:]))
        elif kind == "FIND" and len(columns) == 7:
            target = number(columns[1])
            if target in observed[kind]:
                raise AuditError("E_DUPLICATE_FIND")
            observed[kind][target] = tuple(map(number, columns[2:]))
        elif kind == "EXACT" and len(columns) == 3:
            day = number(columns[1])
            if day in observed[kind]:
                raise AuditError("E_DUPLICATE_EXACT")
            observed[kind][day] = None if columns[2] == "NONE" else number(columns[2])
        elif kind == "PRODUCTION_GATE_LIMIT" and len(columns) == 2:
            if kind in singleton:
                raise AuditError("E_DUPLICATE_LIMIT")
            singleton.add(kind)
            observed[kind] = number(columns[1])
        else:
            raise AuditError("E_UNKNOWN_TRANSCRIPT_ROW")
    if (len(observed["GATE"]) != 5 or len(observed["FIND"]) != 3 or
            len(observed["EXACT"]) != 5 or singleton != {"YEAR", "PRODUCTION_GATE_LIMIT"}):
        raise AuditError("E_TRANSCRIPT_SHAPE")
    if observed["PRODUCTION_GATE_LIMIT"] != MAX_PRODUCTION_GATE_INDEX:
        raise AuditError("E_PRODUCTION_LIMIT_DRIFT")
    return observed

def as_tuple(year) -> tuple[int, int, int, int, int]:
    return (year.number, year.open_index, year.close_index,
            year.open_day, year.close_day)

def compare(parsed: dict, ledger, geometry, selector) -> dict:
    for i in range(-2, 3):
        if parsed["GATE"][i] != ledger.day(i):
            raise AuditError(f"E_REAL_GATE_MISMATCH_{i}")
    base = geometry.year5000(FOUNDATION, selector)
    if parsed["YEAR"] != as_tuple(base):
        raise AuditError("E_REAL_YEAR5000_MISMATCH")
    targets = (base.open_day + 1, FOUNDATION, base.close_day)
    if len(set(targets)) != 3 or set(parsed["FIND"]) != set(targets):
        raise AuditError("E_FIND_TARGET_SET")
    for target in targets:
        year, transitions = geometry.find(FOUNDATION, target, selector)
        if transitions != 0 or parsed["FIND"][target] != as_tuple(year):
            raise AuditError(f"E_REAL_FIND_MISMATCH_{target}")
    days = (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1,
            base.open_day, base.close_day)
    if len(set(days)) != 5 or set(parsed["EXACT"]) != set(days):
        raise AuditError("E_EXACT_TARGET_SET")
    for day in days:
        if parsed["EXACT"][day] != ledger.gate_index(day):
            raise AuditError(f"E_REAL_EXACT_GATE_MISMATCH_{day}")
    bound = (abs(TABLETS - FOUNDATION) + MAX_GATE_GAP - 1) // MAX_GATE_GAP
    if bound <= MAX_PRODUCTION_GATE_INDEX:
        raise AuditError("E_TABLETS_GEOMETRY_PRECONDITION")
    return {"gate_day_comparisons": 5, "year5000_comparisons": 1,
            "find_target_comparisons": 3, "exact_gate_index_comparisons": 5,
            "production_gate_limit_check": 1,
            "tablets_beyond_production_gate_budget": True,
            "tablets_minimum_gate_index": bound}

def run(jar: Path, evidence: Path, timeout: int) -> int:
    start = time.monotonic()
    report = {
        "schema": "post55-production-year-gate-unseeded-v1",
        "status": "FAIL_BOUNDED_REAL_PRODUCTION_YEAR_GATE_UNSEEDED",
        "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "github_sha": os.environ.get("GITHUB_SHA", "UNVERIFIED_LOCAL"),
        "probe_class": "pastafari.Post55ProductionYearGateProbe",
        "oracle_provenance": "Python structural sauce witness and independent year enumeration",
        "comparison_provenance": "live production Kotlin JVM stdout; no checkpoint seed",
        "source_checkpoint_seed_used": False,
        "full_date_verified": False,
        "tablets_production_verified": False,
        "algorithmic_independence_certified": False,
        "certifiable": False,
        "production_gate_limit_unchanged": 8192,
        "real_oracle_gate_queries_expected": ORACLE_HALF_WIDTH * 2,
    }
    try:
        if type(timeout) is not int or not 60 <= timeout <= 900:
            raise AuditError("E_TIME_BUDGET")
        if not jar.is_file():
            raise AuditError("E_MISSING_PRODUCTION_JAR")
        report["production_jar_sha256"] = hashlib.sha256(jar.read_bytes()).hexdigest()
        started_prod = time.monotonic()
        proc = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionYearGateProbe"],
            input="", text=True, capture_output=True,
            timeout=min(360, timeout), check=False)
        report["production_elapsed_seconds"] = round(time.monotonic() - started_prod, 3)
        if proc.returncode != 0:
            raise AuditError("E_PRODUCTION_NONZERO:" + proc.stderr[-280:])
        parsed = parse_transcript(proc.stdout)
        report["production_transcript_sha256"] = hashlib.sha256(proc.stdout.encode("utf-8")).hexdigest()
        from independent_year_geometry_oracle import GateLedger, IndependentYearGeometry, independent_sauce_selector
        from independent_sauce_oracle import evaluate, gap_from_witness
        deadline = start + timeout
        if time.monotonic() >= deadline:
            raise AuditError("E_ORACLE_TIME_BUDGET")
        calls = []
        def independent_gap(i: int) -> int:
            if time.monotonic() >= deadline:
                raise AuditError("E_ORACLE_DEADLINE")
            calls.append(i)
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + i, deadline=deadline))
        ledger = GateLedger(FOUNDATION, -ORACLE_HALF_WIDTH, ORACLE_HALF_WIDTH,
                            independent_gap, max_questions=ORACLE_HALF_WIDTH * 2,
                            segment_limit=190, deadline=deadline)
        expected_calls = (list(range(-1, -ORACLE_HALF_WIDTH - 1, -1)) +
                          list(range(1, ORACLE_HALF_WIDTH + 1)))
        if calls != expected_calls or ledger.question_count != len(calls):
            raise AuditError("E_UNSEEDED_QUERY_SEQUENCE")
        geometry = IndependentYearGeometry(ledger, max_transitions=8)
        report.update(compare(parsed, ledger, geometry,
                              independent_sauce_selector(FOUNDATION, deadline=deadline)))
        report["real_oracle_gate_queries_actual"] = len(calls)
        report["signed_gate_trace_sha256"] = hashlib.sha256(
            "".join(f"{i}:{ledger.day(i)}\n" for i in calls).encode("ascii")).hexdigest()
        report["status"] = PASS
    except (AuditError, RuntimeError, ValueError, OSError, ImportError,
            subprocess.TimeoutExpired, AssertionError) as exc:
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-320:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - start, 3)
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.write_text(json.dumps(report, ensure_ascii=False,
                                       sort_keys=True, indent=2) + "\n", encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items() if "sha256" not in k},
                         sort_keys=True))
    return 0 if report["status"] == PASS else 2

def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=780)
    args = parser.parse_args(argv)
    return run(args.jar, args.evidence, args.timeout_seconds)

if __name__ == "__main__":
    sys.exit(main())
