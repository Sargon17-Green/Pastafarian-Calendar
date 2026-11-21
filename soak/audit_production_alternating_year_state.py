#!/usr/bin/env python3
"""Exact-SHA, unseeded differential for mixed-sign same-instance Kotlin year navigation.

QA-only. No TABLETS, full-date, seven-field or global independence certification.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from audit_production_adjacent_year_navigation import AuditError, number, as_tuple
from independent_year_geometry_oracle import (
    FOUNDATION, GateLedger, IndependentYearGeometry, YearGeometryError,
    independent_sauce_selector,
)
from independent_sauce_oracle import evaluate, gap_from_witness

PROJECT = "PC-BRANCH-KOTLIN-CYMRAEG"
PASS = "PASS_BOUNDED_ALTERNATING_INSTANCE_STATE_NOT_CERTIFIED"
FAIL = "FAIL_BOUNDED_ALTERNATING_INSTANCE_STATE"
ARTIFACT = "kotlin-cymraeg-alternating-instance-state"
LIMIT, HALF, GATES, GAPS, PER_SERIES = 8192, 280, 561, 560, 17

# The expected sequence is independently specified, rather than derived from
# any Kotlin transcript/fixtures. Kinds identify independent year endpoints.
PLAN_A = (
    ("BASE_FIRST", "y0", "first", "y0"),
    ("PLUS_TWO_FIRST", "p2", "first", "p2"),
    ("MINUS_TWO_AFTER_PLUS", "m2", "first", "m2"),
    ("BASE_AFTER_BOTH", "y0", "first", "y0"),
    ("MINUS_TWO_AT_CLOSE", "m2", "close", "m2"),
    ("PLUS_TWO_AT_CLOSE", "p2", "close", "p2"),
    ("PLUS_TWO_AT_OPEN", "p2", "open", "p1"),
    ("MINUS_ONE_AT_OPEN", "m1", "open", "m2"),
    ("BASE_AT_OPEN", "y0", "open", "m1"),
    ("BASE_AT_CLOSE", "y0", "close", "y0"),
    ("BASE_AFTER_CLOSE", "y0", "after_close", "p1"),
    ("PLUS_TWO_REPEAT", "p2", "first", "p2"),
    ("FORWARD3_REJECT", "p2", "after_close", "FWD_REJECT"),
    ("MINUS_TWO_RECOVER", "m2", "first", "m2"),
    ("BACKWARD3_REJECT", "m2", "open", "BWD_REJECT"),
    ("PLUS_TWO_RECOVER", "p2", "first", "p2"),
    ("BASE_FINAL", "y0", "first", "y0"),
)
PLAN_B = (
    ("BASE_FIRST", "y0", "first", "y0"),
    ("MINUS_TWO_FIRST", "m2", "first", "m2"),
    ("PLUS_TWO_AFTER_MINUS", "p2", "first", "p2"),
    ("BASE_AFTER_BOTH", "y0", "first", "y0"),
    ("PLUS_TWO_AT_CLOSE", "p2", "close", "p2"),
    ("MINUS_TWO_AT_CLOSE", "m2", "close", "m2"),
    ("MINUS_ONE_AT_OPEN", "m1", "open", "m2"),
    ("PLUS_TWO_AT_OPEN", "p2", "open", "p1"),
    ("BASE_AFTER_CLOSE", "y0", "after_close", "p1"),
    ("BASE_AT_OPEN", "y0", "open", "m1"),
    ("BASE_FIRST_REPEAT", "y0", "first", "y0"),
    ("MINUS_TWO_REPEAT", "m2", "first", "m2"),
    ("BACKWARD3_REJECT", "m2", "open", "BWD_REJECT"),
    ("PLUS_TWO_RECOVER", "p2", "first", "p2"),
    ("FORWARD3_REJECT", "p2", "after_close", "FWD_REJECT"),
    ("MINUS_TWO_RECOVER", "m2", "first", "m2"),
    ("BASE_FINAL", "y0", "first", "y0"),
)
PLANS = {"A": PLAN_A, "B": PLAN_B}
ERRORS = {"FWD_REJECT": "E_POST55_YEAR_FORWARD_BUDGET",
          "BWD_REJECT": "E_POST55_YEAR_BACKWARD_BUDGET"}


def parse_transcript(raw: str):
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_ALT_FORMAT")
    lines = raw.splitlines()
    expected = 2 * PER_SERIES + GATES + 1
    if len(lines) != expected:
        raise AuditError("E_ALT_ROW_COUNT")
    cases = []
    for series in ("A", "B"):
        previous = 0
        for step, (label, _, _, outcome) in enumerate(PLANS[series]):
            parts = lines[len(cases)].split("\t")
            if len(parts) < 7 or parts[:4] != ["QUERY", series, str(step), label]:
                raise AuditError("E_ALT_QUERY_ORDER")
            status = parts[4]
            if outcome in ERRORS:
                if len(parts) != 7 or status != ERRORS[outcome]:
                    raise AuditError("E_ALT_REJECT_SHAPE")
                interval = None
            else:
                if len(parts) != 12 or status != "OK":
                    raise AuditError("E_ALT_ACCEPT_SHAPE")
                interval = tuple(number(v) for v in parts[6:11])
            target, count = number(parts[5]), number(parts[-1])
            if not 1 <= count <= LIMIT:
                raise AuditError("E_ALT_CACHE_LIMIT")
            if count < previous:
                raise AuditError("E_ALT_CACHE_REGRESSION")
            previous = count
            cases.append((series, step, label, status, target, interval, count))
    gates = {}
    for i, line in enumerate(lines[2 * PER_SERIES:-1]):
        parts = line.split("\t")
        if len(parts) != 3 or parts[0] != "GATE" or number(parts[1]) != i - HALF:
            raise AuditError("E_ALT_GATE_ORDER")
        gates[i - HALF] = number(parts[2])
    if lines[-1] != "TRACE_GATES\t561":
        raise AuditError("E_ALT_GATE_COUNT")
    return cases, gates


def endpoint(year, mode):
    if mode == "first":
        return year.open_day + 1
    if mode == "open":
        return year.open_day
    if mode == "close":
        return year.close_day
    if mode == "after_close":
        return year.close_day + 1
    raise AuditError("E_ALT_MODE")


def compare(cases, gates, ledger, deadline):
    if set(gates) != set(range(-HALF, HALF + 1)):
        raise AuditError("E_ALT_GATE_SET")
    for index in range(-HALF, HALF + 1):
        if gates[index] != ledger.day(index):
            raise AuditError("E_ALT_REAL_GATE_" + str(index))
    base_geometry = IndependentYearGeometry(ledger, max_transitions=2)
    base_selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
    y0 = base_geometry.year5000(FOUNDATION, base_selector)
    p1, m1 = base_geometry.next(y0, base_selector), base_geometry.previous(y0, base_selector)
    p2, m2 = base_geometry.next(p1, base_selector), base_geometry.previous(m1, base_selector)
    years = {"y0": y0, "p1": p1, "p2": p2, "m1": m1, "m2": m2}
    if sorted(y.number for y in years.values()) != list(range(4998, 5003)):
        raise AuditError("E_ALT_YEAR_SEQUENCE")
    accepted = rejected = 0
    for series, step, _, observed_status, target, interval, _ in cases:
        _, year_key, kind, outcome = PLANS[series][step]
        wanted_target = endpoint(years[year_key], kind)
        if target != wanted_target:
            raise AuditError("E_ALT_TARGET_" + series + "_" + str(step))
        # Every query uses a NEW geometry instance and NEW selector. Only the
        # immutable, independently evaluated 560-question gate ledger is shared.
        fresh = IndependentYearGeometry(ledger, max_transitions=2)
        selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
        if outcome in ERRORS:
            if observed_status != ERRORS[outcome]:
                raise AuditError("E_ALT_ERROR_" + series + "_" + str(step))
            if (outcome == "FWD_REJECT" and target <= p2.close_day or
                outcome == "BWD_REJECT" and target > m2.open_day):
                raise AuditError("E_ALT_DIRECTION")
            try:
                fresh.find(FOUNDATION, target, selector, deadline=deadline)
            except YearGeometryError as error:
                if str(error) != "E_YEAR_TRANSITION_BUDGET":
                    raise AuditError("E_ALT_ORACLE_REJECTION_TYPE") from error
            else:
                raise AuditError("E_ALT_ORACLE_FAILED_TO_REJECT")
            rejected += 1
        else:
            oracle, steps = fresh.find(FOUNDATION, target, selector, deadline=deadline)
            if oracle != years[outcome] or interval != as_tuple(oracle):
                raise AuditError("E_ALT_FIVE_FIELDS_" + series + "_" + str(step))
            if not oracle.open_day < target <= oracle.close_day or steps != abs(oracle.number - 5000):
                raise AuditError("E_ALT_INTERVAL_SEMANTICS")
            accepted += 1
    if (accepted, rejected) != (30, 4):
        raise AuditError("E_ALT_COUNTS")
    return {"accepted_queries": accepted, "budget_rejections": rejected,
            "five_field_comparisons": accepted, "gate_comparisons": GATES,
            "same_instance_series": 2, "cache_observations": len(cases),
            "mismatches": 0}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def save(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    content = (json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    temp = path.with_suffix(".partial")
    temp.write_bytes(content)
    temp.replace(path)
    if path.read_bytes() != content or json.loads(content) != data:
        raise AuditError("E_ALT_REPORT_READBACK")
    key = digest(content)
    path.with_suffix(".json.sha256").write_text(key + "  " + path.name + "\n", encoding="ascii")
    return key


def run(jar: Path, output: Path, timeout: int):
    began = time.monotonic()
    source = os.getenv("GITHUB_SHA", "")
    run_id = os.getenv("GITHUB_RUN_ID", "")
    report = {
        "project_id": PROJECT, "schema": "post55-alternating-state-v1",
        "status": FAIL, "source_sha": source or "UNVERIFIED_LOCAL",
        "github_run_id": run_id or "UNVERIFIED_LOCAL", "artifact_name": ARTIFACT,
        "max_gate_abs_index": LIMIT, "max_year_transitions": 2,
        "time_limit_seconds": 900, "tablets_certified": False,
        "full_date_certified": False, "seven_field_certified": False,
        "global_algorithmic_independence_certified": False,
        "independent_oracle_unseeded": True,
    }
    try:
        if timeout != 900:
            raise AuditError("E_ALT_TIMEOUT_POLICY")
        if os.getenv("GITHUB_ACTIONS") == "true" and (len(source) != 40 or not run_id):
            raise AuditError("E_ALT_CI_PROVENANCE")
        if not jar.is_file():
            raise AuditError("E_ALT_JAR_MISSING")
        report["jar_sha256"] = digest(jar.read_bytes())
        here = Path(__file__).resolve().parent
        report["oracle_sha256"] = digest(
            (here / "independent_sauce_oracle.py").read_bytes() + b"\0" +
            (here / "independent_year_geometry_oracle.py").read_bytes() + b"\0" +
            (here / "independent_date_combinatorics.py").read_bytes())
        deadline = began + timeout
        proc = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55AlternatingYearStateProbe"],
            input="", text=True, capture_output=True, check=False,
            timeout=min(600, max(1, deadline - time.monotonic())))
        output.parent.mkdir(parents=True, exist_ok=True)
        output.with_suffix(".transcript.tsv").write_text(proc.stdout, encoding="utf-8")
        output.with_suffix(".stderr.txt").write_text(proc.stderr, encoding="utf-8")
        report["production_exit_code"] = proc.returncode
        report["transcript_sha256"] = digest(proc.stdout.encode())
        if proc.returncode:
            raise AuditError("E_ALT_PRODUCTION_EXIT:" + proc.stderr[-500:])
        cases, gates = parse_transcript(proc.stdout)
        calls = []
        def gap(index):
            if time.monotonic() >= deadline:
                raise AuditError("E_ALT_ORACLE_DEADLINE")
            calls.append(index)
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index, deadline=deadline))
        ledger = GateLedger(FOUNDATION, -HALF, HALF, gap,
                            max_questions=GAPS, segment_limit=HALF, deadline=deadline)
        expected_sequence = list(range(-1, -HALF - 1, -1)) + list(range(1, HALF + 1))
        if calls != expected_sequence or ledger.question_count != GAPS:
            raise AuditError("E_ALT_ORACLE_PROVENANCE")
        trace = "".join(f"{index}\t{ledger.day(index)}\n" for index in range(-HALF, HALF + 1))
        output.with_suffix(".gap-trace.tsv").write_text(trace, encoding="ascii")
        report["gap_trace_sha256"] = digest(trace.encode())
        report.update(compare(cases, gates, ledger, deadline))
        report["independent_gap_questions"] = len(calls)
        report["status"] = PASS
    except Exception as error:
        report["error_type"] = type(error).__name__
        report["error"] = str(error)[-700:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - began, 3)
        sha = save(output, report)
        print(json.dumps({"status": report["status"], "source_sha": report["source_sha"],
                          "report_sha256": sha, "error": report.get("error")}, sort_keys=True))
    return 0 if report["status"] == PASS else 2


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=900)
    args = parser.parse_args()
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
