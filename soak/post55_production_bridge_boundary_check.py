#!/usr/bin/env python3
"""Bounded checks against the actual Kotlin production date bridge.

Evidence-only gate. A successful exit is NOT a full-date or cross-engine
certification. TABLETS is currently provably outside the gate geometry cap.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

FOUNDATION = -15055671
TABLETS = -278522
MAX_GATE_INDEX = 8192
MAX_GATE_GAP = 963
CANDIDATE_WINDOW = 5778
MAIN = "pastafari.Post55ProductionDateBridge"


def invoke(jar, stdin, timeout=360):
    return subprocess.run(
        ["java", "-Xmx1200m", "-Xss8m", "-cp", str(jar), MAIN],
        input=stdin, text=True, capture_output=True,
        timeout=timeout, check=False,
    )


def check(jar, evidence):
    report = {
        "schema": "post55-production-date-boundary-v1",
        "head_sha": os.environ.get("GITHUB_SHA", "unverified-local"),
        "jar_sha256": hashlib.sha256(jar.read_bytes()).hexdigest(),
        "full_date_certified": False,
        "python_turkce_differential_certified": False,
        "tablets_gate_index_lower_bound": (
            abs(TABLETS - FOUNDATION) + MAX_GATE_GAP - 1
        ) // MAX_GATE_GAP,
        "production_gate_index_budget": MAX_GATE_INDEX,
        "tests": [],
    }
    errors = []

    def record(name, ok, details=None):
        report["tests"].append({"name": name, "passed": bool(ok), "details": details or ""})
        if not ok:
            errors.append(name)

    # Three independent calculation days, spanning FOUNDATION±1, and
    # two additional target-day boundary crossings. Run them sequentially
    # with individual time bounds to preserve per-case failure evidence.
    valid = [
        (FOUNDATION - 1, FOUNDATION - 1),
        (FOUNDATION, FOUNDATION),
        (FOUNDATION + 1, FOUNDATION + 1),
        (FOUNDATION, FOUNDATION - 1),
        (FOUNDATION, FOUNDATION + 1),
    ]
    start = time.monotonic()
    # Isolate each boundary conversion: a fail-closed exception for one input
    # must not erase the evidence for other independent boundary inputs.
    for index, (c, t) in enumerate(valid):
        try:
            process = invoke(jar, f"{c}\\t{t}\\n", timeout=60)
            rows = process.stdout.splitlines()
            process_ok = process.returncode == 0 and len(rows) == 1
            record(f"foundation_process_{index}", process_ok,
                   f"exit={process.returncode}, rows={len(rows)}, stderr_tail={process.stderr[-500:]}")
            columns = rows[0].split("\\t") if len(rows) == 1 else []
            fields_ok = (len(columns) == 7 and
                         all(s.lstrip("-").isdigit() for s in columns) and
                         columns[:2] == [str(c), str(t)] and
                         1 <= int(columns[3]) <= 17 and int(columns[4]) >= 1 and
                         1 <= int(columns[5]) <= 47 and int(columns[6]) >= 1
                         ) if len(columns) == 7 else False
            record(f"foundation_7_fields_{index}", process_ok and fields_ok, columns)
        except subprocess.TimeoutExpired:
            record(f"foundation_process_{index}", False, "60-second timeout")
            record(f"foundation_7_fields_{index}", False, "process timed out")

    # Each malformed input must be rejected without a single data row.
    malformed = [
        "1\n", "1\t\n", "1\t2\t3\n",
        "01\t2\n", "-0\t1\n", "1\t+2\n", "hello\t1\n",
        "-00\t1\n", "-01\t1\n", "1\t02\n",
        "1\t--2\n", "1\t2 \n", "1 \t2\n",
        "\t2\n", "1\t2\t\n",
    ]
    for index, value in enumerate(malformed):
        try:
            process = invoke(jar, value, timeout=20)
            record(f"reject_malformed_{index}",
                   process.returncode != 0 and not process.stdout and
                   "E_POST55_BRIDGE_INPUT" in process.stderr,
                   f"exit={process.returncode}, stdout={process.stdout[:100]}")
        except subprocess.TimeoutExpired:
            record(f"reject_malformed_{index}", False, "20-second timeout")

    # Mathematical impossibility: 8192 * 963 < abs(TABLETS-FOUNDATION).
    # Fail-closed behavior is required, NOT a fictitious seven-field PASS.
    proof = abs(TABLETS - FOUNDATION) > MAX_GATE_INDEX * MAX_GATE_GAP
    record("tablets_geometric_impossibility_proved", proof,
           {"distance": abs(TABLETS - FOUNDATION),
            "max_reach": MAX_GATE_INDEX * MAX_GATE_GAP})
    for offset in (-1, 0, 1):
        day = TABLETS + offset
        try:
            process = invoke(jar, f"{day}\t{day}\n", timeout=20)
            record(f"tablets_{offset}_rejected_without_stdout",
                   process.returncode != 0 and not process.stdout and
                   "E_POST55_GATE_GEOMETRIC_LIMIT" in process.stderr,
                   f"exit={process.returncode}, stderr_tail={process.stderr[-300:]}")
        except subprocess.TimeoutExpired:
            record(f"tablets_{offset}_rejected_without_stdout", False, "20-second timeout")

    report["duration_seconds"] = round(time.monotonic() - start, 3)
    report["status"] = "BOUNDED_PARTIAL_CHECKS_GREEN_NOT_CERTIFIED" if not errors else "RED"
    report["failed_checks"] = errors
    evidence.parent.mkdir(parents=True, exist_ok=True)
    evidence.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"POST55_PRODUCTION_BRIDGE_{report['status']}: {len(report['tests'])} checks")
    print(f"JSON_EVIDENCE={evidence}")
    return 0 if not errors else 1


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--jar", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    sys.exit(check(args.jar, args.evidence))
