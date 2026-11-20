#!/usr/bin/env python3
"""Independent bounded inverse differential for Kotlin gateDay/exactGateIndex.

No production-source imports or checkpoint-seeded oracle. Five years 4998..5002
and four shared boundaries. No TABLETS, full-date, or algorithmic certification.
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

FOUNDATION = -15055671  # Protocol sentinel; checked against the independent oracle at run time.

HALF_WIDTH = 280
GATE_COUNT = 2 * HALF_WIDTH + 1
MAX_GATE_ABS_INDEX = 8192
SHARED_COUNT = 4
NEAR_COUNT = 8
INTERIOR_INDICES = (-271, -231, -191, -151, -111, -71, -31, -1,
                    0, 29, 69, 109, 149, 189, 229, 269)
INTERIOR_COUNT = 3 * len(INTERIOR_INDICES)
TOTAL_ROWS = 2 * GATE_COUNT + SHARED_COUNT + NEAR_COUNT + INTERIOR_COUNT + 2
EXPECTED_CHECKS = TOTAL_ROWS
PASS = "PASS_BOUNDED_REAL_PRODUCTION_GATE_INVERSE_INTERIOR_NOT_CERTIFIED"
CANONICAL = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")


class InverseAuditError(ValueError):
    pass


def integer(raw):
    if not isinstance(raw, str) or not CANONICAL.fullmatch(raw):
        raise InverseAuditError("E_NONCANONICAL_INTEGER")
    return int(raw)


def parse_transcript(raw):
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise InverseAuditError("E_FORMAT")
    rows = raw.splitlines()
    if len(rows) != TOTAL_ROWS:
        raise InverseAuditError("E_ROW_COUNT")
    gates, inverses, nearby, interiors, shared = {}, {}, {}, {}, []
    limit, expanded = None, None
    for line in rows:
        columns = line.split("\t")
        tag = columns[0]
        if tag == "GATE" and len(columns) == 3:
            index, day = map(integer, columns[1:])
            if index in gates:
                raise InverseAuditError("E_DUPLICATE_GATE")
            gates[index] = day
        elif tag == "INVERSE" and len(columns) == 3:
            day, index = map(integer, columns[1:])
            if day in inverses:
                raise InverseAuditError("E_DUPLICATE_INVERSE")
            inverses[day] = index
        elif tag == "SHARED" and len(columns) == 2:
            shared.append(integer(columns[1]))
        elif tag == "NEAR" and len(columns) == 5:
            index, offset, day = map(integer, columns[1:4])
            outcome = columns[4]
            if outcome != "NONE":
                # A forged non-null result must be detected, never ignored.
                integer(outcome)
            key = (index, offset)
            if key in nearby:
                raise InverseAuditError("E_DUPLICATE_NEAR")
            nearby[key] = (day, outcome)
        elif tag == "INTERIOR" and len(columns) == 5:
            index, ordinal, day = map(integer, columns[1:4])
            outcome = columns[4]
            if outcome != "NONE":
                integer(outcome)
            key = (index, ordinal)
            if key in interiors:
                raise InverseAuditError("E_DUPLICATE_INTERIOR")
            interiors[key] = (day, outcome)
        elif tag == "PRODUCTION_GATE_LIMIT" and len(columns) == 2:
            if limit is not None:
                raise InverseAuditError("E_DUPLICATE_LIMIT")
            limit = integer(columns[1])
        elif tag == "PRODUCTION_EXPANDED_GATES" and len(columns) == 2:
            if expanded is not None:
                raise InverseAuditError("E_DUPLICATE_EXPANDED")
            expanded = integer(columns[1])
        else:
            raise InverseAuditError("E_UNKNOWN_ROW")
    expected = set(range(-HALF_WIDTH, HALF_WIDTH + 1))
    if set(gates) != expected:
        raise InverseAuditError("E_GATE_SET")
    if len(inverses) != GATE_COUNT:
        raise InverseAuditError("E_INVERSE_COUNT")
    if len(shared) != SHARED_COUNT or len(set(shared)) != SHARED_COUNT:
        raise InverseAuditError("E_SHARED_SHAPE")
    if set(nearby) != {(index, delta) for index in shared for delta in (-1, 1)}:
        raise InverseAuditError("E_NEAR_SET")
    if set(interiors) != {(index, ordinal) for index in INTERIOR_INDICES
                         for ordinal in (1, 2, 3)}:
        raise InverseAuditError("E_INTERIOR_SET")
    if limit != MAX_GATE_ABS_INDEX:
        raise InverseAuditError("E_PRODUCTION_LIMIT")
    if expanded != GATE_COUNT or expanded > limit:
        raise InverseAuditError("E_PRODUCTION_EXPANDED")
    return {"gates": gates, "inverses": inverses,
            "shared": tuple(shared), "near": nearby, "interior": interiors,
            "limit": limit, "expanded": expanded}


def compare(parsed, ledger, independent_shared):
    if tuple(parsed["shared"]) != tuple(independent_shared):
        raise InverseAuditError("E_SHARED_INDEPENDENT_MISMATCH")
    if len(independent_shared) != SHARED_COUNT or any(
            not -HALF_WIDTH < index < HALF_WIDTH for index in independent_shared):
        raise InverseAuditError("E_SHARED_BUDGET")
    gates = parsed["gates"]
    for index in range(-HALF_WIDTH, HALF_WIDTH + 1):
        expected_day = ledger.day(index)
        if gates[index] != expected_day:
            raise InverseAuditError(f"E_GATE_DAY_MISMATCH_{index}")
        if parsed["inverses"].get(expected_day) != index:
            raise InverseAuditError(f"E_EXACT_INVERSE_MISMATCH_{index}")
        if ledger.gate_index(expected_day) != index:
            raise InverseAuditError(f"E_INDEPENDENT_INVERSE_MISMATCH_{index}")
    if set(parsed["inverses"]) != set(gates.values()):
        raise InverseAuditError("E_UNEXPECTED_INVERSE_DAYS")
    for index in independent_shared:
        for delta in (-1, 1):
            expected_day = ledger.day(index) + delta
            got_day, result = parsed["near"][(index, delta)]
            if got_day != expected_day:
                raise InverseAuditError(f"E_NEAR_TARGET_MISMATCH_{index}_{delta}")
            if ledger.gate_index(expected_day) is not None:
                raise InverseAuditError(f"E_INDEPENDENT_NEAR_GATE_{index}_{delta}")
            if result != "NONE":
                raise InverseAuditError(f"E_FALSE_POSITIVE_INVERSE_{index}_{delta}")
    for index in INTERIOR_INDICES:
        left, right = ledger.day(index), ledger.day(index + 1)
        gap = right - left
        targets = (left + gap // 4, left + gap // 2, right - gap // 4)
        if not (left < targets[0] < targets[1] < targets[2] < right):
            raise InverseAuditError(f"E_ORACLE_INTERIOR_GEOMETRY_{index}")
        for ordinal, target in enumerate(targets, 1):
            observed_day, outcome = parsed["interior"][(index, ordinal)]
            if observed_day != target:
                raise InverseAuditError(f"E_INTERIOR_TARGET_MISMATCH_{index}_{ordinal}")
            if ledger.gate_index(target) is not None:
                raise InverseAuditError(f"E_ORACLE_INTERIOR_GATE_{index}_{ordinal}")
            if outcome != "NONE":
                raise InverseAuditError(f"E_INTERIOR_FALSE_POSITIVE_{index}_{ordinal}")
    return {
        "gate_day_comparisons": GATE_COUNT,
        "exact_inverse_comparisons": GATE_COUNT,
        "shared_boundary_comparisons": SHARED_COUNT,
        "non_gate_neighbor_comparisons": NEAR_COUNT,
        "non_gate_interior_comparisons": INTERIOR_COUNT,
        "interior_sampled_intervals": len(INTERIOR_INDICES),
        "production_gate_limit_checks": 1,
        "production_expanded_gate_count_checks": 1,
        "typed_comparisons": EXPECTED_CHECKS,
    }


def write_report(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")


def run(jar, evidence, timeout):
    start = time.monotonic()
    report = {
        "schema": "post55-production-gate-inverse-unseeded-interior-v2",
        "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "github_sha": os.environ.get("GITHUB_SHA", "UNVERIFIED_LOCAL"),
        "status": "FAIL_BOUNDED_GATE_INVERSE",
        "certifiable": False, "full_date_verified": False,
        "tablets_production_verified": False,
        "algorithmic_independence_certified": False,
        "production_gate_limit": MAX_GATE_ABS_INDEX,
        "oracle_unseeded_questions_expected": GATE_COUNT - 1,
        "typed_comparisons_expected": EXPECTED_CHECKS,
    }
    try:
        from independent_year_geometry_oracle import (
            FOUNDATION as ORACLE_FOUNDATION, GateLedger, IndependentYearGeometry,
            independent_sauce_selector,
        )
        from independent_sauce_oracle import evaluate, gap_from_witness
        if ORACLE_FOUNDATION != FOUNDATION:
            raise InverseAuditError("E_FOUNDATION_ORACLE_DRIFT")
        if type(timeout) is not int or not 60 <= timeout <= 900:
            raise InverseAuditError("E_TIMEOUT_BUDGET")
        if not jar.is_file():
            raise InverseAuditError("E_NO_PRODUCTION_JAR")
        report["production_jar_sha256"] = hashlib.sha256(jar.read_bytes()).hexdigest()
        result = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionGateInverseProbe"],
            input="", text=True, capture_output=True,
            timeout=min(360, timeout), check=False,
        )
        if result.returncode != 0:
            raise InverseAuditError("E_JVM_EXIT:" + result.stderr[-500:])
        parsed = parse_transcript(result.stdout)
        report["production_transcript_sha256"] = hashlib.sha256(result.stdout.encode()).hexdigest()
        deadline = start + timeout
        calls = []

        def independent_gap(index):
            if time.monotonic() > deadline:
                raise InverseAuditError("E_ORACLE_TIMEOUT")
            calls.append(index)
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index, deadline=deadline))

        ledger = GateLedger(
            FOUNDATION, -HALF_WIDTH, HALF_WIDTH, independent_gap,
            max_questions=GATE_COUNT - 1, segment_limit=HALF_WIDTH,
            deadline=deadline,
        )
        expected_calls = (list(range(-1, -HALF_WIDTH - 1, -1)) +
                          list(range(1, HALF_WIDTH + 1)))
        if calls != expected_calls or ledger.question_count != GATE_COUNT - 1:
            raise InverseAuditError("E_ORACLE_UNSEEDED_SEQUENCE")
        independent = IndependentYearGeometry(ledger, max_transitions=8)
        selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
        base = independent.year5000(FOUNDATION, selector)
        prev = independent.previous(base, selector)
        prev2 = independent.previous(prev, selector)
        nxt = independent.next(base, selector)
        nxt2 = independent.next(nxt, selector)
        five = (prev2, prev, base, nxt, nxt2)
        for left, right in zip(five, five[1:]):
            if (left.close_index != right.open_index or left.close_day != right.open_day):
                raise InverseAuditError("E_INDEPENDENT_YEAR_DISCONTIGUITY")
        shared = tuple(year.close_index for year in five[:-1])
        report.update(compare(parsed, ledger, shared))
        report["oracle_unseeded_questions_actual"] = len(calls)
        report["independent_shared_indices"] = shared
        report["production_expanded_gate_count"] = parsed["expanded"]
        report["signed_oracle_ledger_sha256"] = hashlib.sha256("".join(
            f"{i}:{ledger.day(i)}\n" for i in range(-HALF_WIDTH, HALF_WIDTH + 1)
        ).encode("ascii")).hexdigest()
        report["status"] = PASS
    except Exception as exc:  # Fail closed and persist an error report, including missing runtime imports.
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-500:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - start, 3)
        write_report(evidence, report)
        print(json.dumps({k:v for k,v in report.items() if "sha256" not in k}, sort_keys=True))
    return 0 if report["status"] == PASS else 2


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=780)
    args = parser.parse_args(argv)
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
