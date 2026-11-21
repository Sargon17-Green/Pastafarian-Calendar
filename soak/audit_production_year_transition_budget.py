#!/usr/bin/env python3
"""Independent unseeded audit of Kotlin production year transition budgets."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from audit_production_adjacent_year_navigation import AuditError, FOUNDATION, as_tuple, number
from independent_year_geometry_oracle import (
    GateLedger, IndependentYearGeometry, independent_sauce_selector)
from independent_sauce_oracle import evaluate, gap_from_witness

PROJECT = "PC-BRANCH-KOTLIN-CYMRAEG"
PASS = "PASS_BOUNDED_YEAR_TRANSITION_BUDGET_RECOVERY_NOT_CERTIFIED"
FAIL = "FAIL_BOUNDED_YEAR_TRANSITION_BUDGET_RECOVERY"
ARTIFACT = "kotlin-cymraeg-year-transition-budget-recovery"
LIMIT, HALF, GAPS, GATES, CASES = 8192, 280, 560, 561, 12
LABELS = (
    "CTOR_ZERO", "CTOR_OVER", "F2_BUDGET1", "F1_RECOVER", "BASE_AFTER_F1",
    "B2_BUDGET1", "B1_RECOVER", "BASE_AFTER_B1", "F2_BUDGET2",
    "B2_BUDGET2", "FWD_PROFILE", "BWD_PROFILE")
GROUPS = ("FWD1", "BWD1", "FWD2", "BWD2")
GAP_INDICES = tuple(range(-1, -HALF - 1, -1)) + tuple(range(1, HALF + 1))


def parse_transcript(raw: str):
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_TRANSITION_FORMAT")
    rows = raw.splitlines()
    if len(rows) != CASES + 12 + GATES + 1:
        raise AuditError("E_TRANSITION_ROW_COUNT")
    cases = []
    for i in range(CASES):
        items = rows[i].split("\t")
        if len(items) < 4 or items[:3] != ["CASE", str(i), LABELS[i]]:
            raise AuditError("E_TRANSITION_CASE_ORDER")
        if i in (0, 1, 10, 11):
            if len(items) != 4:
                raise AuditError("E_TRANSITION_CASE_SHAPE")
            cases.append(items[3])
        elif i in (2, 5):
            if len(items) != 5:
                raise AuditError("E_TRANSITION_CASE_SHAPE")
            cases.append((number(items[3]), items[4]))
        else:
            if len(items) != 9:
                raise AuditError("E_TRANSITION_CASE_SHAPE")
            cases.append((number(items[3]), tuple(map(number, items[4:]))))
    cache = {}
    for i, line in enumerate(rows[CASES:CASES + 12]):
        parts = line.split("\t")
        group, step = GROUPS[i // 3], i % 3
        if len(parts) != 4 or parts[:3] != ["CACHE", group, str(step)]:
            raise AuditError("E_TRANSITION_CACHE_ORDER")
        count = number(parts[3])
        if not 1 <= count <= LIMIT:
            raise AuditError("E_TRANSITION_CACHE_BUDGET")
        cache.setdefault(group, []).append(count)
    for group, counts in cache.items():
        if len(counts) != 3 or sorted(counts) != counts:
            raise AuditError("E_TRANSITION_CACHE_NONMONOTONE_" + group)
    gates = {}
    for i, line in enumerate(rows[CASES + 12:-1]):
        parts = line.split("\t")
        index = i - HALF
        if len(parts) != 3 or parts[0] != "GATE" or number(parts[1]) != index:
            raise AuditError("E_TRANSITION_GATE_ORDER")
        gates[index] = number(parts[2])
    if rows[-1] != "TRACE_GATES\t561":
        raise AuditError("E_TRANSITION_TRACE_COUNT")
    return {"cases": cases, "cache": cache, "gates": gates}


def check_gap_sequence(asked, count):
    if tuple(asked) != GAP_INDICES or count != GAPS:
        raise AuditError("E_TRANSITION_GAP_SEQUENCE")


def compare(parsed, ledger, geometry, selector):
    if set(parsed["gates"]) != set(range(-HALF, HALF + 1)):
        raise AuditError("E_TRANSITION_GATE_SET")
    for index in range(-HALF, HALF + 1):
        if parsed["gates"][index] != ledger.day(index):
            raise AuditError("E_TRANSITION_GATE_MISMATCH_" + str(index))
    y0 = geometry.year5000(FOUNDATION, selector)
    yp1, ym1 = geometry.next(y0, selector), geometry.previous(y0, selector)
    yp2, ym2 = geometry.next(yp1, selector), geometry.previous(ym1, selector)
    if [y.number for y in (ym2, ym1, y0, yp1, yp2)] != list(range(4998, 5003)):
        raise AuditError("E_TRANSITION_YEAR_SET")
    tp2, tp1, t0 = yp2.open_day + 1, yp1.open_day + 1, y0.open_day + 1
    tm2, tm1 = ym2.open_day + 1, ym1.open_day + 1
    expected = (
        "E_POST55_YEAR_TRANSITION_BUDGET", "E_POST55_YEAR_TRANSITION_BUDGET",
        (tp2, "E_POST55_YEAR_FORWARD_BUDGET"),
        (tp1, as_tuple(yp1)), (t0, as_tuple(y0)),
        (tm2, "E_POST55_YEAR_BACKWARD_BUDGET"),
        (tm1, as_tuple(ym1)), (t0, as_tuple(y0)),
        (tp2, as_tuple(yp2)), (tm2, as_tuple(ym2)), "OK", "OK")
    for index, (actual, wanted) in enumerate(zip(parsed["cases"], expected)):
        if actual != wanted:
            raise AuditError("E_TRANSITION_INDEPENDENT_CASE_" + str(index))
    return {
        "cases": CASES, "expected_constructor_rejections": 2,
        "expected_directional_rejections": 2,
        "one_hop_and_base_recoveries": 4, "two_hop_exact_results": 2,
        "cache_profiles": 4, "cache_counts": parsed["cache"],
        "independent_gate_comparisons": GATES, "mismatches": 0}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def save(path: Path, report: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (json.dumps(report, indent=2, ensure_ascii=False, sort_keys=True) + "\n").encode()
    temp = path.with_suffix(".partial")
    temp.write_bytes(data)
    temp.replace(path)
    if path.read_bytes() != data or json.loads(data) != report:
        raise AuditError("E_TRANSITION_REPORT_READBACK")
    value = digest(data)
    path.with_suffix(".json.sha256").write_text(value + "  " + path.name + "\n",
                                                encoding="ascii")
    return value


def validate_success(report):
    for key, width in (("source_sha", 40), ("jar_sha256", 64),
                       ("transcript_sha256", 64), ("oracle_sha256", 64),
                       ("gap_trace_sha256", 64)):
        val = report.get(key)
        if not isinstance(val, str) or len(val) != width or any(
                c not in "0123456789abcdef" for c in val):
            raise AuditError("E_TRANSITION_PROVENANCE_" + key)
    if (report.get("status") != PASS or report.get("production_exit_code") != 0
            or report.get("cases") != CASES or report.get("mismatches") != 0
            or report.get("independent_gap_questions") != GAPS
            or report.get("independent_gate_comparisons") != GATES
            or report.get("cache_profiles") != 4 or report.get("gate_limit") != LIMIT
            or report.get("time_limit_seconds") != 900
            or report.get("tablets_certified") is not False
            or report.get("full_date_certified") is not False
            or report.get("global_independence_certified") is not False):
        raise AuditError("E_TRANSITION_REPORT_COUNTS")


def run(jar: Path, evidence: Path, timeout: int):
    start = time.monotonic()
    source = os.getenv("GITHUB_SHA", "")
    run_id = os.getenv("GITHUB_RUN_ID", "")
    repo = os.getenv("GITHUB_REPOSITORY", "Sargon17-Green/Pastafarian-Calendar")
    report = {
        "status": FAIL, "schema": "post55-transition-budget-recovery-v1",
        "project_id": PROJECT, "source_sha": source or "UNVERIFIED_LOCAL",
        "run_id": run_id or "UNVERIFIED_LOCAL",
        "run_url": "https://github.com/" + repo + "/actions/runs/" + run_id
                   if run_id else "UNVERIFIED_LOCAL",
        "artifact_name": ARTIFACT, "gate_limit": LIMIT,
        "time_limit_seconds": 900, "tablets_certified": False,
        "full_date_certified": False, "seven_field_certified": False,
        "global_independence_certified": False,
        "independent_unseeded_oracle": True,
    }
    try:
        if timeout != 900:
            raise AuditError("E_TRANSITION_TIME_BUDGET")
        if os.getenv("GITHUB_ACTIONS") == "true" and (
                len(source) != 40 or not run_id):
            raise AuditError("E_TRANSITION_CI_PROVENANCE")
        if not jar.is_file():
            raise AuditError("E_TRANSITION_JAR_MISSING")
        report["jar_sha256"] = digest(jar.read_bytes())
        root = Path(__file__).resolve().parent
        report["oracle_sha256"] = digest(
            (root / "independent_sauce_oracle.py").read_bytes() + b"\x00" +
            (root / "independent_year_geometry_oracle.py").read_bytes() + b"\x00" +
            (root / "independent_date_combinatorics.py").read_bytes())
        deadline = start + timeout
        process = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55YearTransitionBudgetProbe"],
            input="", capture_output=True, text=True, check=False,
            timeout=min(600, max(1, deadline - time.monotonic())))
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.with_suffix(".transcript.tsv").write_text(process.stdout, encoding="utf-8")
        evidence.with_suffix(".stderr.txt").write_text(process.stderr, encoding="utf-8")
        report["transcript_sha256"] = digest(process.stdout.encode())
        report["production_exit_code"] = process.returncode
        if process.returncode:
            raise AuditError("E_TRANSITION_PRODUCTION_EXIT:" + process.stderr[-500:])
        parsed = parse_transcript(process.stdout)
        calls = []
        def gap(index):
            if time.monotonic() >= deadline:
                raise AuditError("E_TRANSITION_ORACLE_DEADLINE")
            calls.append(index)
            return gap_from_witness(evaluate(
                FOUNDATION, FOUNDATION + index, deadline=deadline))
        ledger = GateLedger(FOUNDATION, -HALF, HALF, gap,
                            max_questions=GAPS, segment_limit=HALF,
                            deadline=deadline)
        check_gap_sequence(calls, ledger.question_count)
        trace = "".join(str(i) + "\t" + str(ledger.day(i)) + "\n"
                        for i in range(-HALF, HALF + 1))
        evidence.with_suffix(".gap-trace.tsv").write_text(trace, encoding="ascii")
        report["gap_trace_sha256"] = digest(trace.encode())
        geometry = IndependentYearGeometry(ledger, max_transitions=2)
        selector = independent_sauce_selector(FOUNDATION, deadline=deadline)
        report.update(compare(parsed, ledger, geometry, selector))
        report["independent_gap_questions"] = len(calls)
        report["status"] = PASS
        validate_success(report)
    except Exception as exc:
        report["status"] = FAIL
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-600:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - start, 3)
        sha = save(evidence, report)
        print(json.dumps({"status": report["status"],
                          "source_sha": report["source_sha"],
                          "report_sha256": sha,
                          "error": report.get("error")}, sort_keys=True))
    return 0 if report["status"] == PASS else 2


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--jar", type=Path, required=True)
    p.add_argument("--evidence", type=Path, required=True)
    p.add_argument("--timeout-seconds", type=int, default=900)
    args = p.parse_args()
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
