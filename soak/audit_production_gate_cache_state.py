#!/usr/bin/env python3
"""Independent unseeded signed-gate oracle for Kotlin cache-order/inverse QA."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from audit_production_adjacent_year_navigation import AuditError, FOUNDATION, number
from independent_year_geometry_oracle import GateLedger
from independent_sauce_oracle import evaluate, gap_from_witness

PROJECT = "PC-BRANCH-KOTLIN-CYMRAEG"
PASS = "PASS_BOUNDED_SIGNED_GATE_CACHE_INVERSE_NOT_CERTIFIED"
FAIL = "FAIL_BOUNDED_SIGNED_GATE_CACHE_INVERSE"
INDICES = (-280, -279, -40, -19, -12, -5, -4, -1, 0, 1,
           3, 4, 5, 14, 22, 23, 40, 279, 280)
ORDERS = {"FRESH": (), "NEGATIVE_FIRST": INDICES,
          "POSITIVE_FIRST": tuple(reversed(INDICES))}
GAP_INDICES = tuple(range(-1, -281, -1)) + tuple(range(1, 282))
GAPS, GATES, ROUNDS, MIDS, WARMS, ROWS, LIMIT = 561, 562, 57, 57, 38, 155, 8192
ARTIFACT = "kotlin-cymraeg-signed-gate-cache-inverse"


def parse_transcript(raw: str):
    if not isinstance(raw, str) or not raw.endswith("\n") or "\r" in raw:
        raise AuditError("E_CACHE_FORMAT")
    lines = raw.splitlines()
    if len(lines) != ROWS:
        raise AuditError("E_CACHE_ROWS")
    cursor, sessions = 0, {}
    for name, warming in ORDERS.items():
        samples = {"warm": [], "round": [], "mid": []}
        for label, key, indices, columns in (
            ("WARM", "warm", warming, 5),
            ("ROUND", "round", INDICES, 6),
            ("MID", "mid", INDICES, 6),
        ):
            for position, index in enumerate(indices):
                fields = lines[cursor].split("\t")
                cursor += 1
                if (len(fields) != columns or fields[:2] != [label, name] or
                        number(fields[2]) != position or number(fields[3]) != index):
                    raise AuditError(f"E_CACHE_PROTOCOL_{label}")
                day = number(fields[4])
                if label == "ROUND" and number(fields[5]) != index:
                    raise AuditError("E_CACHE_ROUNDTRIP")
                if label == "MID" and fields[5] != "NONE":
                    raise AuditError("E_CACHE_FALSE_POSITIVE")
                samples[key].append((index, day))
        fields = lines[cursor].split("\t")
        cursor += 1
        if len(fields) != 3 or fields[:2] != ["SESSION", name]:
            raise AuditError("E_CACHE_SESSION")
        gate_count = number(fields[2])
        if not 1 <= gate_count <= LIMIT:
            raise AuditError("E_CACHE_GATE_BUDGET")
        samples["gate_count"] = gate_count
        sessions[name] = samples
    if cursor != ROWS:
        raise AuditError("E_CACHE_CURSOR")
    return sessions


def check_gap_sequence(indices, count):
    if tuple(indices) != GAP_INDICES or count != GAPS:
        raise AuditError("E_CACHE_ORACLE_QUESTION_ORDER")


def compare(parsed, ledger):
    if set(parsed) != set(ORDERS):
        raise AuditError("E_CACHE_SESSION_SET")
    for name, session in parsed.items():
        if (len(session["warm"]) != len(ORDERS[name]) or
                len(session["round"]) != 19 or len(session["mid"]) != 19):
            raise AuditError("E_CACHE_COUNTS")
        for index, day in session["warm"]:
            if day != ledger.day(index):
                raise AuditError(f"E_CACHE_STALE_WARM_{name}_{index}")
        for index, day in session["round"]:
            if day != ledger.day(index):
                raise AuditError(f"E_CACHE_GATE_MISMATCH_{name}_{index}")
        for index, middle in session["mid"]:
            left, right = ledger.day(index), ledger.day(index + 1)
            if right - left < 2:
                raise AuditError("E_CACHE_ORACLE_NO_INTERIOR")
            if middle != left + (right - left) // 2 or ledger.gate_index(middle) is not None:
                raise AuditError(f"E_CACHE_NONGATE_MISMATCH_{name}_{index}")
    if (sum(len(s["warm"]) for s in parsed.values()) != WARMS or
            sum(len(s["round"]) for s in parsed.values()) != ROUNDS or
            sum(len(s["mid"]) for s in parsed.values()) != MIDS):
        raise AuditError("E_CACHE_TOTALS")
    return {"roundtrips": ROUNDS, "nongate_probes": MIDS, "warming_rows": WARMS,
            "sessions": 3, "mismatches": 0,
            "session_gate_counts": {k: v["gate_count"] for k, v in parsed.items()}}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_report(path: Path, report: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = (json.dumps(report, sort_keys=True, indent=2, ensure_ascii=False) + "\n").encode()
    temporary = path.with_suffix(".partial")
    temporary.write_bytes(payload)
    temporary.replace(path)
    if path.read_bytes() != payload or json.loads(payload) != report:
        raise AuditError("E_CACHE_REPORT_READBACK")
    sha = digest(payload)
    path.with_suffix(".json.sha256").write_text(sha + "  " + path.name + "\n",
                                                encoding="ascii")
    return sha


def validate_success(report: dict):
    for name in ("source_sha", "production_jar_sha256", "transcript_sha256",
                 "gap_trace_sha256", "oracle_code_sha256"):
        value = report.get(name)
        width = 40 if name == "source_sha" else 64
        if not isinstance(value, str) or len(value) != width or any(
                c not in "0123456789abcdef" for c in value):
            raise AuditError("E_CACHE_PROVENANCE")
    if (report.get("status") != PASS or report.get("production_exit_code") != 0 or
            report.get("independent_gap_questions") != GAPS or
            report.get("independent_gate_days") != GATES or
            report.get("roundtrips") != ROUNDS or report.get("nongate_probes") != MIDS or
            report.get("warming_rows") != WARMS or report.get("mismatches") != 0 or
            report.get("max_year_transitions_configured") != 8 or
            report.get("year_transitions_exercised") is not False or
            set(report.get("session_gate_counts", {})) != set(ORDERS) or
            any(not 1 <= x <= LIMIT for x in report["session_gate_counts"].values())):
        raise AuditError("E_CACHE_REPORT_COUNTS")


def run(jar: Path, evidence: Path, timeout: int):
    started = time.monotonic()
    source, run_id = os.getenv("GITHUB_SHA", ""), os.getenv("GITHUB_RUN_ID", "")
    repository = os.getenv("GITHUB_REPOSITORY", "Sargon17-Green/Pastafarian-Calendar")
    report = {
        "status": FAIL, "schema": "post55-gate-cache-inverse-v1", "project_id": PROJECT,
        "source_sha": source or "UNVERIFIED_LOCAL", "run_id": run_id or "UNVERIFIED_LOCAL",
        "run_url": f"https://github.com/{repository}/actions/runs/{run_id}" if run_id else "UNVERIFIED_LOCAL",
        "artifact_name": ARTIFACT, "production_class": "pastafari.Post55ProductionGateCacheStateProbe",
        "jdk_required": "21", "kotlin_compiler_required": "1.9.0", "gate_limit": LIMIT,
        "max_year_transitions_configured": 8, "year_transitions_exercised": False,
        "tablets_certified": False, "full_date_certified": False,
        "global_independence_certified": False, "unseeded_signed_gap_oracle": True,
    }
    try:
        if timeout != 900:
            raise AuditError("E_CACHE_TIMEOUT")
        if os.getenv("GITHUB_ACTIONS") == "true" and (len(source) != 40 or not run_id):
            raise AuditError("E_CACHE_GITHUB_PROVENANCE")
        if not jar.is_file():
            raise AuditError("E_CACHE_JAR_MISSING")
        report["production_jar_sha256"] = digest(jar.read_bytes())
        root = Path(__file__).resolve().parent
        oracle_code = (root / "independent_sauce_oracle.py").read_bytes() + b"\0" + (
            root / "independent_year_geometry_oracle.py").read_bytes()
        report["oracle_code_sha256"] = digest(oracle_code)
        deadline = started + timeout
        process = subprocess.run(
            ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar),
             "pastafari.Post55ProductionGateCacheStateProbe"],
            input="", text=True, capture_output=True, check=False,
            timeout=min(600, max(1, deadline - time.monotonic())))
        evidence.parent.mkdir(parents=True, exist_ok=True)
        evidence.with_suffix(".transcript.tsv").write_text(process.stdout, encoding="utf-8")
        evidence.with_suffix(".stderr.txt").write_text(process.stderr, encoding="utf-8")
        report["transcript_sha256"] = digest(process.stdout.encode())
        report["production_exit_code"] = process.returncode
        if process.returncode:
            raise AuditError("E_CACHE_KOTLIN_EXIT:" + process.stderr[-400:])
        parsed = parse_transcript(process.stdout)
        calls = []
        def gap(index):
            if time.monotonic() >= deadline:
                raise AuditError("E_CACHE_ORACLE_DEADLINE")
            calls.append(index)
            return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index,
                                             deadline=deadline))
        ledger = GateLedger(FOUNDATION, -280, 281, gap,
                            max_questions=GAPS, segment_limit=281, deadline=deadline)
        check_gap_sequence(calls, ledger.question_count)
        trace = "".join(f"{i}\t{ledger.day(i)}\n" for i in range(-280, 282))
        evidence.with_suffix(".gap-trace.tsv").write_text(trace, encoding="ascii")
        report["gap_trace_sha256"] = digest(trace.encode("ascii"))
        report.update(compare(parsed, ledger))
        report["independent_gap_questions"] = len(calls)
        report["independent_gate_days"] = GATES
        report["status"] = PASS
        validate_success(report)
    except Exception as exc:
        report["status"] = FAIL
        report["error_type"] = type(exc).__name__
        report["error"] = str(exc)[-500:]
    finally:
        report["elapsed_seconds"] = round(time.monotonic() - started, 3)
        sha = write_report(evidence, report)
        print(json.dumps({"status": report["status"], "json_sha256": sha,
                          "source_sha": report["source_sha"],
                          "error": report.get("error")}, sort_keys=True))
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
