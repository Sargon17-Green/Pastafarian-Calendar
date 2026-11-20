#!/usr/bin/env python3
"""Fail-closed real Kotlin findTargetYear query-order diagnostic, not certification."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from audit_production_adjacent_year_navigation import (
    AuditError, FOUNDATION, number, as_tuple, independent_interior_targets,
)
from independent_year_geometry_oracle import (
    GateLedger, IndependentYearGeometry, YearGeometryError,
    independent_sauce_selector,
)
from independent_sauce_oracle import SauceOracleError, evaluate, gap_from_witness
from independent_date_combinatorics import DateCombinatoricsError

HALF_WIDTH = 280
GATE_COUNT = HALF_WIDTH * 2 + 1
PRODUCTION_LIMIT = 8192
ORDERS = {
    "NATURAL": tuple(range(15)),
    "REVERSED": tuple(reversed(range(15))),
    "PERMUTED": tuple((i * 7) % 15 for i in range(15)),
}
EXPECTED_LINES = 3 * (15 + 1) + GATE_COUNT + 1
PASS = "PASS_BOUNDED_REAL_PRODUCTION_ORDER_INVARIANCE_NOT_CERTIFIED"


def parse_transcript(text: str) -> dict:
    if not isinstance(text, str) or not text.endswith("\n") or "\r" in text:
        raise AuditError("E_ORDER_TRANSCRIPT_FORMAT")
    rows = text.splitlines()
    if len(rows) != EXPECTED_LINES:
        raise AuditError("E_ORDER_ROW_COUNT")
    cursor = 0
    observations = {}
    gate_counts = {}
    for name, permutation in ORDERS.items():
        case_map = {}
        for expected_index in permutation:
            fields = rows[cursor].split("\t")
            cursor += 1
            if len(fields) != 11 or fields[0:2] != ["ORDER", name]:
                raise AuditError("E_ORDER_ROW_SHAPE")
            index, source_year, ordinal, target = map(number, fields[2:6])
            actual = tuple(map(number, fields[6:11]))
            if index != expected_index or index in case_map:
                raise AuditError("E_ORDER_PERMUTATION")
            case_map[index] = (source_year, ordinal, target, actual)
        fields = rows[cursor].split("\t")
        cursor += 1
        if len(fields) != 3 or fields[:2] != ["ORDER_GATES", name]:
            raise AuditError("E_ORDER_BUDGET_ROW")
        expanded = number(fields[2])
        if not 1 <= expanded <= PRODUCTION_LIMIT:
            raise AuditError("E_ORDER_GATE_BUDGET")
        observations[name] = case_map
        gate_counts[name] = expanded

    gates = {}
    for expected_index in range(-HALF_WIDTH, HALF_WIDTH + 1):
        fields = rows[cursor].split("\t")
        cursor += 1
        if len(fields) != 3 or fields[0] != "GATE":
            raise AuditError("E_ORDER_GATE_ROW")
        index, day = map(number, fields[1:])
        if index != expected_index:
            raise AuditError("E_ORDER_GATE_INDEX")
        gates[index] = day
    fields = rows[cursor].split("\t")
    if fields[:1] != ["SEED_GATES"] or len(fields) != 2:
        raise AuditError("E_ORDER_SEED_ROW")
    if number(fields[1]) != GATE_COUNT:
        raise AuditError("E_ORDER_SEED_BUDGET")
    return {"orders": observations, "gate_counts": gate_counts, "gates": gates}


def compare(parsed: dict, ledger, geometry, selector) -> dict:
    if set(parsed["orders"]) != set(ORDERS):
        raise AuditError("E_ORDER_NAMES")
    if set(parsed["gates"]) != set(range(-HALF_WIDTH, HALF_WIDTH + 1)):
        raise AuditError("E_ORDER_GATE_SET")
    for i in range(-HALF_WIDTH, HALF_WIDTH + 1):
        if parsed["gates"][i] != ledger.day(i):
            raise AuditError("E_ORDER_INDEPENDENT_GATE_MISMATCH")
    center = geometry.year5000(FOUNDATION, selector)
    before = geometry.previous(center, selector)
    after = geometry.next(center, selector)
    years = [geometry.previous(before, selector), before, center, after,
             geometry.next(after, selector)]
    if [y.number for y in years] != list(range(4998, 5003)):
        raise AuditError("E_ORDER_INDEPENDENT_YEAR_SET")
    for left, right in zip(years, years[1:]):
        if (left.close_index != right.open_index or
                left.close_day != right.open_day):
            raise AuditError("E_ORDER_INDEPENDENT_CONTIGUITY")
    cases = []
    for year in years:
        for ordinal, target in enumerate(independent_interior_targets(year), 1):
            if not year.open_day < target < year.close_day:
                raise AuditError("E_ORDER_NOT_STRICT_INTERIOR")
            independently_found, transitions = geometry.find(
                FOUNDATION, target, selector
            )
            if independently_found != year or transitions > 8:
                raise AuditError("E_ORDER_INDEPENDENT_FIND")
            cases.append((year.number, ordinal, target, as_tuple(year)))
    if len(cases) != 15:
        raise AuditError("E_ORDER_ORACLE_CASE_COUNT")
    for name in ORDERS:
        if set(parsed["orders"][name]) != set(range(15)):
            raise AuditError("E_ORDER_CASE_SET")
        for index, actual in parsed["orders"][name].items():
            if actual != cases[index]:
                raise AuditError(f"E_ORDER_REAL_MISMATCH_{name}_{index}")
    return {
        "real_production_ordered_queries": 45,
        "unique_strict_interior_targets": len(cases),
        "verified_fresh_navigator_instances": 3,
        "independent_years": [y.number for y in years],
        "production_gate_trace_compared": GATE_COUNT,
        "production_order_gate_counts": parsed["gate_counts"],
        "max_independent_year_transitions": 2,
        "max_production_year_transition_setting": 8,
    }


def write_evidence(path: Path, report: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".partial")
    temporary.write_text(json.dumps(report, ensure_ascii=False, sort_keys=True,
                                    indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def run(jar: Path, evidence: Path, timeout: int) -> int:
    started = time.monotonic()
    report = {
        "schema": "post55-production-order-invariance-v1",
        "status": "FAIL_BOUNDED_REAL_PRODUCTION_ORDER_INVARIANCE",
        "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "github_sha": os.environ.get("GITHUB_SHA", "UNVERIFIED_LOCAL"),
        "production_class": "pastafari.Post55ProductionOrderInvariantProbe",
        "oracle": "independently recomputed unseeded Python year and sauce geometry",
        "seeded_reference_cache_used": False,
        "source_checkpoint_seed_used": False,
        "full_date_verified": False,
        "tablets_production_verified": False,
        "algorithmic_independence_certified": False,
        "certifiable": False,
        "production_gate_limit": PRODUCTION_LIMIT,
        "expected_unseeded_signed_gap_questions": HALF_WIDTH * 2,
        "expected_distinct_targets": 15,
        "expected_production_order_queries": 45,
    }
    try:
        if type(timeout) is not int or not 60 <= timeout <= 900:
            raise AuditError("E_ORDER_TIMEOUT")
        if not jar.is_file():
            raise AuditError("E_ORDER_MISSING_JAR")
        report["production_jar_sha256"] = hashlib.sha256(jar.read_bytes()).hexdigest()
        process = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionOrderInvariantProbe"],
            input="", capture_output=True, text=True, check=False,
            timeout=min(600, timeout - 60),
        )
        report["production_exit_code"] = process.returncode
        if process.returncode != 0:
            raise AuditError("E_ORDER_PRODUCTION_NONZERO:" + process.stderr[-500:])
        parsed = parse_transcript(process.stdout)
        report["production_transcript_sha256"] = hashlib.sha256(
            process.stdout.encode("utf-8")
        ).hexdigest()
        deadline = started + timeout
        calls = []

        def independent_gap(index: int) -> int:
            if time.monotonic() >= deadline:
                raise AuditError("E_ORDER_ORACLE_DEADLINE")
            calls.append(index)
            return gap_from_witness(evaluate(
                FOUNDATION, FOUNDATION + index, deadline=deadline
            ))

        ledger = GateLedger(
            FOUNDATION, -HALF_WIDTH, HALF_WIDTH,
            independent_gap, max_questions=HALF_WIDTH * 2,
            segment_limit=HALF_WIDTH, deadline=deadline,
        )
        expected_calls = list(range(-1, -HALF_WIDTH - 1, -1)) + list(
            range(1, HALF_WIDTH + 1)
        )
        if calls != expected_calls or ledger.question_count != len(calls):
            raise AuditError("E_ORDER_UNSEEDED_QUERY_SEQUENCE")
        geometry = IndependentYearGeometry(ledger, max_transitions=8)
        selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
        report.update(compare(parsed, ledger, geometry, selector))
        report["actual_unseeded_signed_gap_questions"] = len(calls)
        report["signed_gap_trace_sha256"] = hashlib.sha256("".join(
            f"{i}:{ledger.day(i)}\n" for i in expected_calls
        ).encode("ascii")).hexdigest()
        report["status"] = PASS
    except (AuditError, YearGeometryError, SauceOracleError,
            DateCombinatoricsError, RuntimeError, ValueError, OSError,
            ImportError, subprocess.TimeoutExpired, AssertionError) as exc:
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-500:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        write_evidence(evidence, report)
        print(json.dumps({k: v for k, v in report.items()
                          if not k.endswith("sha256")}, sort_keys=True))
    return 0 if report["status"] == PASS else 2


def main(argv=None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=900)
    args = parser.parse_args(argv)
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
