#!/usr/bin/env python3
"""Fail-closed unseeded independent audit of Kotlin production boundaries."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from audit_production_adjacent_year_navigation import AuditError, FOUNDATION, number, as_tuple
from independent_year_geometry_oracle import (
    GateLedger, IndependentYearGeometry, independent_sauce_selector
)
from independent_sauce_oracle import evaluate, gap_from_witness

PROJECT = "PC-BRANCH-KOTLIN-CYMRAEG"
PASS = "PASS_BOUNDED_REAL_PRODUCTION_BOUNDARY_STATE_ORDER_NOT_CERTIFIED"
FAIL = "FAIL_BOUNDED_REAL_PRODUCTION_BOUNDARY_STATE_ORDER"
HALF = 280
GATES = 561
GAPS = 560
CALLS = 108
LINES = 673
LIMIT = 8192
ORDERS = {
    "NATURAL": tuple(range(18)),
    "REVERSED": tuple(range(17, -1, -1)),
    "STRIDE5": tuple(5 * i % 18 for i in range(18)),
}
GAP_INDICES = tuple(range(-1, -281, -1)) + tuple(range(1, 281))
ARTIFACT = "kotlin-cymraeg-production-boundary-state"


def cases_for(years, geometry, selector):
    if [x.number for x in years] != list(range(4998, 5003)):
        raise AuditError("E_BOUNDARY_YEAR_SET")
    for a, b in zip(years, years[1:]):
        if (a.close_index, a.close_day) != (b.open_index, b.open_day):
            raise AuditError("E_BOUNDARY_CONTIGUITY")
    proposed = ([(x.open_day + 1, x.number) for x in years] +
                [(x.close_day, x.number) for x in years] +
                [(years[i].open_day, years[i-1].number) for i in range(1, 5)] +
                [(years[i].close_day + 1, years[i+1].number) for i in range(4)])
    if len(proposed) != 18 or len(set(x[0] for x in proposed)) != 10:
        raise AuditError("E_BOUNDARY_DISTINCT_TARGETS")
    for i in range(4):
        if proposed[10+i][0] != proposed[5+i][0] or proposed[14+i][0] != proposed[1+i][0]:
            raise AuditError("E_BOUNDARY_ALIASES")
    result, max_transitions = [], 0
    for idx, (target, owner) in enumerate(proposed):
        year, transitions = geometry.find(FOUNDATION, target, selector)
        if (year.number != owner or not year.open_day < target <= year.close_day
                or type(transitions) is not int or not 0 <= transitions <= 8):
            raise AuditError(f"E_BOUNDARY_INDEPENDENT_OWNER_{idx}")
        max_transitions = max(max_transitions, transitions)
        result.append((target, as_tuple(year)))
    return tuple(result), max_transitions


def parse_transcript(raw):
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_BOUNDARY_FORMAT")
    rows = raw.splitlines()
    if len(rows) != LINES:
        raise AuditError("E_BOUNDARY_ROW_COUNT")
    cursor, seen = 0, {}
    for session, order in ORDERS.items():
        phases = {}
        for phase in (1, 2):
            values = {}
            permutation = order if phase == 1 else tuple(reversed(order))
            for pos, expected_id in enumerate(permutation):
                fields = rows[cursor].split("\t")
                cursor += 1
                if len(fields) != 11 or fields[:2] != ["CASE", session]:
                    raise AuditError("E_BOUNDARY_CASE_SCHEMA")
                a = tuple(number(s) for s in fields[2:])
                if a[:3] != (phase, pos, expected_id) or expected_id in values:
                    raise AuditError("E_BOUNDARY_CASE_ORDER")
                values[expected_id] = (a[3], a[4:])
            phases[phase] = values
        seen[session] = phases
    session_counts = {}
    for session in ORDERS:
        fields = rows[cursor].split("\t")
        cursor += 1
        if len(fields) != 3 or fields[:2] != ["SESSION_GATES", session]:
            raise AuditError("E_BOUNDARY_SESSION_ID")
        value = number(fields[2])
        if not 1 <= value <= LIMIT:
            raise AuditError("E_BOUNDARY_GATE_BUDGET")
        session_counts[session] = value
    gate_days = {}
    for idx in range(-HALF, HALF + 1):
        fields = rows[cursor].split("\t")
        cursor += 1
        if len(fields) != 3 or fields[0] != "GATE":
            raise AuditError("E_BOUNDARY_GATE_ROW")
        actual_index, day = map(number, fields[1:])
        if actual_index != idx or actual_index in gate_days:
            raise AuditError("E_BOUNDARY_GATE_SEQUENCE")
        gate_days[idx] = day
    last = rows[cursor].split("\t")
    if len(last) != 2 or last[0] != "SEED_GATES" or number(last[1]) != GATES:
        raise AuditError("E_BOUNDARY_SEED_GATE_COUNT")
    return {"cases": seen, "session_counts": session_counts, "gates": gate_days}


def check_gap_sequence(calls, count):
    if tuple(calls) != GAP_INDICES or count != GAPS:
        raise AuditError("E_BOUNDARY_GAP_QUESTION_SEQUENCE")


def compare(parsed, ledger, geometry, selector):
    if set(parsed["cases"]) != set(ORDERS) or set(parsed["session_counts"]) != set(ORDERS):
        raise AuditError("E_BOUNDARY_SESSION_SET")
    if set(parsed["gates"]) != set(range(-HALF, HALF + 1)):
        raise AuditError("E_BOUNDARY_GATE_SET")
    for i in range(-HALF, HALF + 1):
        if parsed["gates"][i] != ledger.day(i):
            raise AuditError(f"E_BOUNDARY_INDEPENDENT_GATE_{i}")
    center = geometry.year5000(FOUNDATION, selector)
    before, after = geometry.previous(center, selector), geometry.next(center, selector)
    years = [geometry.previous(before, selector), before, center, after,
             geometry.next(after, selector)]
    expected, max_transitions = cases_for(years, geometry, selector)
    comparisons = 0
    for session, phases in parsed["cases"].items():
        if set(phases) != {1, 2}:
            raise AuditError("E_BOUNDARY_PHASES")
        for phase, samples in phases.items():
            if set(samples) != set(range(18)):
                raise AuditError("E_BOUNDARY_CASE_SET")
            for idx, value in samples.items():
                if value != expected[idx]:
                    raise AuditError(f"E_BOUNDARY_REAL_MISMATCH_{session}_{phase}_{idx}")
                comparisons += 1
    if comparisons != CALLS:
        raise AuditError("E_BOUNDARY_COMPARISON_COUNT")
    return {
        "real_production_calls": comparisons, "ownership_cases": 18,
        "distinct_days": 10, "reuse_phases_per_session": 2,
        "session_gate_counts": parsed["session_counts"],
        "gate_trace_comparisons": GATES, "max_independent_transitions": max_transitions,
        "max_production_transitions_setting": 8, "mismatches": 0,
    }


def validate_success(report):
    required = {"status", "project_id", "source_sha", "production_jar_sha256",
                "transcript_sha256", "gap_trace_sha256", "production_exit_code",
                "real_production_calls", "ownership_cases", "independent_gap_questions",
                "gate_trace_comparisons", "mismatches", "session_gate_counts",
                "artifact_name", "run_url"}
    if not required <= report.keys() or report["status"] != PASS:
        raise AuditError("E_BOUNDARY_REPORT_MISSING")
    if (report["production_exit_code"] != 0 or report["real_production_calls"] != CALLS or
        report["ownership_cases"] != 18 or report["independent_gap_questions"] != GAPS or
        report["gate_trace_comparisons"] != GATES or report["mismatches"] != 0 or
        set(report["session_gate_counts"]) != set(ORDERS) or
        any(not 1 <= v <= LIMIT for v in report["session_gate_counts"].values())):
        raise AuditError("E_BOUNDARY_REPORT_COUNTS")
    for field in ("production_jar_sha256", "transcript_sha256", "gap_trace_sha256"):
        digest = report[field]
        if (not isinstance(digest, str) or len(digest) != 64 or
            any(c not in "0123456789abcdef" for c in digest)):
            raise AuditError("E_BOUNDARY_BAD_DIGEST")
    if not report["source_sha"] or not report["run_url"]:
        raise AuditError("E_BOUNDARY_PROVENANCE")


def save(path, report):
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = (json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n").encode()
    temp = path.with_suffix(".partial")
    temp.write_bytes(payload)
    temp.replace(path)
    if path.read_bytes() != payload or json.loads(payload) != report:
        raise AuditError("E_BOUNDARY_REPORT_READBACK")
    digest = hashlib.sha256(payload).hexdigest()
    path.with_suffix(".json.sha256").write_text(
        digest + "  " + path.name + "\n", encoding="ascii")
    return digest


def run(jar: Path, evidence: Path, timeout: int):
    started = time.monotonic()
    runid = os.environ.get("GITHUB_RUN_ID", "")
    sha = os.environ.get("GITHUB_SHA", "")
    repository = os.environ.get("GITHUB_REPOSITORY", "Sargon17-Green/Pastafarian-Calendar")
    report = {
        "status": FAIL, "schema": "post55-boundary-state-v1", "project_id": PROJECT,
        "source_sha": sha or "UNVERIFIED_LOCAL", "run_id": runid or "UNVERIFIED_LOCAL",
        "run_url": f"https://github.com/{repository}/actions/runs/{runid}" if runid else "UNVERIFIED_LOCAL",
        "artifact_name": ARTIFACT, "artifact_uploaded_verified": False,
        "production_class": "pastafari.Post55ProductionBoundaryStateProbe",
        "kotlin_compiler_required": "1.9.0", "jdk_required": "21",
        "expected_real_calls": CALLS, "expected_ownership_cases": 18,
        "expected_gap_questions": GAPS, "expected_gate_comparisons": GATES,
        "gate_budget": LIMIT, "max_year_transitions": 8,
        "seeded_reference_used": False, "tablets_certified": False,
        "full_date_certified": False, "global_independence_certified": False,
    }
    try:
        if type(timeout) is not int or timeout != 900:
            raise AuditError("E_BOUNDARY_TIMEOUT")
        if os.environ.get("GITHUB_ACTIONS") == "true" and (
                len(sha) != 40 or not runid):
            raise AuditError("E_BOUNDARY_SHA_ENV")
        if not jar.is_file():
            raise AuditError("E_BOUNDARY_JAR_MISSING")
        report["production_jar_sha256"] = hashlib.sha256(jar.read_bytes()).hexdigest()
        deadline = started + timeout
        process = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionBoundaryStateProbe"],
            input="", text=True, capture_output=True, check=False,
            timeout=min(600, max(1, deadline - time.monotonic())))
        report["production_exit_code"] = process.returncode
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.with_suffix(".transcript.tsv").write_text(process.stdout, encoding="utf-8")
        evidence.with_suffix(".stderr.txt").write_text(process.stderr, encoding="utf-8")
        report["transcript_sha256"] = hashlib.sha256(process.stdout.encode()).hexdigest()
        if process.returncode:
            raise AuditError("E_BOUNDARY_KOTLIN_EXIT:" + process.stderr[-400:])
        parsed = parse_transcript(process.stdout)
        calls = []
        def gap(index):
            if time.monotonic() >= deadline:
                raise AuditError("E_BOUNDARY_ORACLE_DEADLINE")
            calls.append(index)
            return gap_from_witness(evaluate(
                FOUNDATION, FOUNDATION + index, deadline=deadline))
        ledger = GateLedger(FOUNDATION, -HALF, HALF, gap,
                            max_questions=GAPS, segment_limit=HALF,
                            deadline=deadline)
        check_gap_sequence(calls, ledger.question_count)
        trace = "".join(f"{i}:{ledger.day(i)}\n" for i in GAP_INDICES)
        evidence.with_suffix(".gap-trace.txt").write_text(trace, encoding="ascii")
        report["gap_trace_sha256"] = hashlib.sha256(trace.encode("ascii")).hexdigest()
        geometry = IndependentYearGeometry(ledger, max_transitions=8)
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
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        digest = save(evidence, report)
        print(json.dumps({"status": report["status"], "source_sha": report["source_sha"],
                          "json_sha256": digest, "error": report.get("error")},
                         sort_keys=True))
    return 0 if report["status"] == PASS else 2


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--timeout-seconds", type=int, default=900)
    args = parser.parse_args(argv)
    return run(args.jar, args.evidence, args.timeout_seconds)


if __name__ == "__main__":
    sys.exit(main())
