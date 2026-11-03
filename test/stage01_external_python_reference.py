#!/usr/bin/env python3
"""Bounded *external* Stage 1 comparison, not a normative-stage acceptance gate.

Reads an immutable Python+Turkce normative reference as data from its pinned
commit. Never imports the Fortran candidate or reimplements the date algorithm.
The expected tuples were transcribed from native-compile job 126102276850 of
run 41689001869 on Fortran commit 58f21c0bcd5c57496c3fb7ceb0aaee3419cf2f2b.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import faulthandler
import hashlib
import importlib.util
import json
import resource
import subprocess
import sys
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
FORTRAN_COMMIT = "58f21c0bcd5c57496c3fb7ceb0aaee3419cf2f2b"
FORTRAN_RUN = 41689001869
PYTHON_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PYTHON_BLOB = "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
REFERENCE_URL = (
    "https://raw.githubusercontent.com/Sargon17-Green/"
    "Pastafarian-Calendar/" + PYTHON_COMMIT + "/tests/normative_reference.py"
)
CALCULATION_DAY = -15055671
FIELD_NAMES = ("year_number", "cutlet_name_index", "day_in_cutlet",
               "month_name_index", "day_in_month")
CASES = (
    (-15057703, (4999, 15, 433, 32, 121)),
    (-15057702, (5000, 15, 1, 18, 1)),
    (-15055672, (5000, 10, 502, 32, 21)),
    (-15055671, (5000, 10, 503, 20, 56)),
    (-15055670, (5000, 14, 1, 29, 38)),
    (-15053459, (5000, 13, 218, 26, 105)),
    (-15053458, (5001, 9, 1, 41, 1)),
)
CASE_TIMEOUT_SECONDS = 60
WORKERS = 2

def verify_reference(path: Path) -> None:
    payload = path.read_bytes()
    git_blob = hashlib.sha1(
        ("blob " + str(len(payload)) + "\0").encode("ascii") + payload
    ).hexdigest()
    if git_blob != PYTHON_BLOB:
        raise ValueError("Pinned reference blob SHA mismatch: " + git_blob)

def judge(expected: tuple[int, ...], actual: tuple[int, ...]) -> dict:
    if len(actual) != len(FIELD_NAMES):
        raise ValueError("Reference result does not contain exactly five fields")
    differences = [
        {"field": name, "expected_fortran": a, "actual_python": b}
        for name, a, b in zip(FIELD_NAMES, expected, actual) if a != b
    ]
    return {"status": "match" if not differences else "mismatch",
            "differences": differences, "matched_fields": 5 - len(differences)}

def worker(case_index: int, reference: Path) -> int:
    resource.setrlimit(resource.RLIMIT_AS,
                       (1500 * 1024 * 1024, 1500 * 1024 * 1024))
    faulthandler.enable()
    faulthandler.dump_traceback_later(50, repeat=False)
    verify_reference(reference)
    spec = importlib.util.spec_from_file_location(
        "pinned_python_normative_stage01", reference
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load pinned independent reference")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    calendar = module.NormativeCalendar()
    target, _expected = CASES[case_index]
    print(f"PYTHON_REFERENCE_CASE_BEGIN={case_index + 1} target={target}", flush=True)
    ids = calendar.calendar_date_ids(CALCULATION_DAY, target)
    actual = [int(getattr(ids, field)) for field in FIELD_NAMES]
    print("REFERENCE_RESULT_JSON=" + json.dumps(actual), flush=True)
    faulthandler.cancel_dump_traceback_later()
    return 0

def invoke(case_index: int, reference: Path) -> dict:
    target, expected = CASES[case_index]
    command = [sys.executable, "-u", str(Path(__file__).resolve()),
               "--worker", str(case_index), "--reference", str(reference)]
    row = {"case": case_index + 1, "calculation_day": CALCULATION_DAY,
           "target_day": target, "fortran_expected": dict(zip(FIELD_NAMES, expected)),
           "status": "error", "matched_fields": 0, "differences": []}
    try:
        proc = subprocess.run(command, capture_output=True, text=True,
                              timeout=CASE_TIMEOUT_SECONDS, check=False)
        row["exit_code"] = proc.returncode
        row["stderr_tail"] = proc.stderr[-4000:]
        row["stdout_tail"] = proc.stdout[-1000:]
        if proc.returncode != 0:
            return row
        records = [line.partition("=")[2] for line in proc.stdout.splitlines()
                   if line.startswith("REFERENCE_RESULT_JSON=")]
        if len(records) != 1:
            row["status"] = "malformed_result"
            return row
        actual = tuple(json.loads(records[0]))
        row["python_actual"] = dict(zip(FIELD_NAMES, actual))
        row.update(judge(expected, actual))
        return row
    except subprocess.TimeoutExpired as err:
        row["status"] = "timeout"
        row["timeout_seconds"] = CASE_TIMEOUT_SECONDS
        stderr = err.stderr or b""
        stdout = err.stdout or b""
        row["stderr_tail"] = (stderr.decode("utf-8", "replace")
                              if isinstance(stderr, bytes) else stderr)[-4000:]
        row["stdout_tail"] = (stdout.decode("utf-8", "replace")
                              if isinstance(stdout, bytes) else stdout)[-1000:]
        return row
    except Exception as err:
        row["exception"] = repr(err)
        return row

def self_test() -> None:
    expected = (5000, 10, 503, 20, 56)
    assert judge(expected, expected)["matched_fields"] == 5
    assert judge(expected, (5000, 11, 503, 20, 57))["matched_fields"] == 3
    assert [x["field"] for x in judge(
        expected, (5000, 11, 503, 20, 57))["differences"]
    ] == ["cutlet_name_index", "day_in_month"]
    print("STAGE01_EXTERNAL_HARNESS_UNIT_ASSERTIONS=3/3")

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--worker", type=int)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if args.reference is None:
        parser.error("--reference is required")
    verify_reference(args.reference)
    if args.worker is not None:
        if not 0 <= args.worker < len(CASES):
            parser.error("worker index outside seven pinned cases")
        return worker(args.worker, args.reference)
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = [pool.submit(invoke, i, args.reference)
                   for i in range(len(CASES))]
        rows = sorted((task.result() for task in futures), key=lambda r: r["case"])
    matches = sum(row["matched_fields"] for row in rows)
    exact = sum(row["status"] == "match" for row in rows)
    report = {
        "project_id": PROJECT_ID,
        "fortran_commit": FORTRAN_COMMIT,
        "fortran_run": FORTRAN_RUN,
        "python_reference_commit": PYTHON_COMMIT,
        "python_reference_blob_sha1": PYTHON_BLOB,
        "python_reference_url": REFERENCE_URL,
        "reference_api": "NormativeCalendar.calendar_date_ids",
        "candidate_only": True,
        "case_timeout_seconds": CASE_TIMEOUT_SECONDS,
        "parallel_workers": WORKERS,
        "matched_cases": exact,
        "matched_fields": matches,
        "total_cases": len(CASES),
        "total_fields": 5 * len(CASES),
        "full_stage1_accepted": False,
        "results": rows,
    }
    Path("stage01_external_diff_report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"STAGE01_EXTERNAL_COMPARISON={exact}/7 cases; {matches}/35 exact fields")
    for row in rows:
        print(f"STAGE01_EXTERNAL_CASE={row['case']} TARGET={row['target_day']} "
              f"STATUS={row['status']} MATCHED_FIELDS={row['matched_fields']}/5")
        for diff in row["differences"]:
            print("STAGE01_EXTERNAL_DIFF=" + json.dumps(
                {"case": row["case"], **diff}, ensure_ascii=False))
    if exact == len(CASES):
        print("STAGE01_EXTERNAL_CANDIDATE_DIFF_PASS_ONLY; NOT FULL STAGE1")
        return 0
    print("STAGE01_EXTERNAL_CANDIDATE_DIFF_NOT_ACCEPTED; see report")
    return 1

if __name__ == "__main__":
    sys.exit(main())
