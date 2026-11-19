#!/usr/bin/env python3
"""Independent Stage 1 date differential across varied calculation-day contexts.

The Fortran executable is the original normative_calendar_date entry point.
Expected values come only from the SHA-pinned Python+Turkce normative reference.
This is bounded QA and is not, by itself, full Stage 1 acceptance.
"""
from __future__ import annotations

import argparse
import faulthandler
import hashlib
import importlib.util
import json
import resource
import subprocess
import sys
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
FOUNDATION_DAY = -15055671
PYTHON_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PYTHON_BLOB = "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
REFERENCE_URL = (
    "https://raw.githubusercontent.com/Sargon17-Green/"
    "Pastafarian-Calendar/" + PYTHON_COMMIT + "/tests/normative_reference.py"
)
FIELD_NAMES = (
    "year_number",
    "cutlet_name_index",
    "day_in_cutlet",
    "month_name_index",
    "day_in_month",
)
CASES = (
    {"label": "target-5000-after-calculation", "calculation_offset": -8192, "target_offset": -3192},
    {"label": "target-5000-before-calculation", "calculation_offset": 8192, "target_offset": 3192},
    {"label": "target-equals-calculation-day", "calculation_offset": 137, "target_offset": 137},
    # Hold the target fixed at Foundation while varying only calculation_day.
    {"label": "fixed-foundation-target-before", "calculation_offset": -1, "target_offset": 0},
    {"label": "fixed-foundation-target-equal", "calculation_offset": 0, "target_offset": 0},
    {"label": "fixed-foundation-target-after", "calculation_offset": 1, "target_offset": 0},
)
REFERENCE_TIMEOUT_SECONDS = 75
FORTRAN_TIMEOUT_SECONDS = 75

def case_days(case_index: int) -> tuple[int, int]:
    if not 1 <= case_index <= len(CASES):
        raise ValueError(f"calculation-context case must be 1..{len(CASES)}")
    case = CASES[case_index - 1]
    return (
        FOUNDATION_DAY + case["calculation_offset"],
        FOUNDATION_DAY + case["target_offset"],
    )

def verify_reference(path: Path) -> None:
    payload = path.read_bytes()
    git_blob = hashlib.sha1(
        ("blob " + str(len(payload)) + "\0").encode("ascii") + payload
    ).hexdigest()
    if git_blob != PYTHON_BLOB:
        raise ValueError("Pinned Python reference blob SHA mismatch: " + git_blob)

def load_reference(path: Path):
    verify_reference(path)
    spec = importlib.util.spec_from_file_location("pinned_stage01_context_reference", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load pinned independent Python reference")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    if int(module.FOUNDATION_DAY) != FOUNDATION_DAY:
        raise ValueError("Pinned Python FOUNDATION_DAY differs from the Fortran lock")
    return module

def extract_one(text: str, prefix: str) -> str:
    values = [line[len(prefix):] for line in text.splitlines() if line.startswith(prefix)]
    if len(values) != 1:
        raise ValueError("Missing or duplicate output record: " + prefix)
    return values[0]

def extract_five(text: str, prefix: str) -> tuple[int, ...]:
    raw = extract_one(text, prefix)
    fields = raw.split(",")
    if len(fields) != 5:
        raise ValueError("Expected exactly five numeric fields")
    return tuple(int(value) for value in fields)

def memory_limiter(memory_mib: int):
    def apply_limit() -> None:
        size = memory_mib * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (size, size))
    return apply_limit

def python_worker(case_index: int, reference: Path) -> int:
    size = 1536 * 1024 * 1024
    resource.setrlimit(resource.RLIMIT_AS, (size, size))
    faulthandler.enable()
    faulthandler.dump_traceback_later(65, repeat=False)
    module = load_reference(reference)
    calculation_day, target_day = case_days(case_index)
    result = module.NormativeCalendar().calendar_date_ids(calculation_day, target_day)
    values = [int(getattr(result, name)) for name in FIELD_NAMES]
    print(
        f"STAGE01_CONTEXT_ORACLE_INPUT={case_index} "
        f"CALC={calculation_day} TARGET={target_day}",
        flush=True,
    )
    print("STAGE01_CONTEXT_ORACLE_FIELDS=" + ",".join(map(str, values)), flush=True)
    faulthandler.cancel_dump_traceback_later()
    return 0

def run_python_reference(case_index: int, reference: Path) -> tuple[int, ...]:
    command = [
        sys.executable, "-u", str(Path(__file__).resolve()),
        "--worker", str(case_index), "--reference", str(reference),
    ]
    process = subprocess.run(
        command, capture_output=True, text=True,
        timeout=REFERENCE_TIMEOUT_SECONDS, check=False,
        preexec_fn=memory_limiter(1536),
    )
    if process.returncode != 0:
        raise RuntimeError(
            f"Python reference exit={process.returncode}; "
            f"stdout={process.stdout[-1200:]}; stderr={process.stderr[-1200:]}"
        )
    calculation_day, target_day = case_days(case_index)
    input_line = (
        f"STAGE01_CONTEXT_ORACLE_INPUT={case_index} "
        f"CALC={calculation_day} TARGET={target_day}"
    )
    if process.stdout.splitlines().count(input_line) != 1:
        raise ValueError("Python oracle did not confirm the exact case inputs")
    return extract_five(process.stdout, "STAGE01_CONTEXT_ORACLE_FIELDS=")

def run_fortran(case_index: int, executable: Path) -> tuple[tuple[int, ...], str]:
    process = subprocess.run(
        [str(executable.resolve()), str(case_index)],
        capture_output=True, text=True,
        timeout=FORTRAN_TIMEOUT_SECONDS, check=False,
        preexec_fn=memory_limiter(1024),
    )
    if process.returncode != 0:
        raise RuntimeError(
            f"Fortran exit={process.returncode}; "
            f"stdout={process.stdout[-1200:]}; stderr={process.stderr[-1200:]}"
        )
    calculation_day, target_day = case_days(case_index)
    if int(extract_one(process.stdout, "STAGE01_CONTEXT_CASE=")) != case_index:
        raise ValueError("Fortran probe returned the wrong case index")
    if int(extract_one(process.stdout, "STAGE01_CONTEXT_CALCULATION_DAY=")) != calculation_day:
        raise ValueError("Fortran probe calculation-day input mismatch")
    if int(extract_one(process.stdout, "STAGE01_CONTEXT_TARGET_DAY=")) != target_day:
        raise ValueError("Fortran probe target-day input mismatch")
    return extract_five(process.stdout, "STAGE01_CONTEXT_FIELDS="), process.stdout

def self_test() -> None:
    assert len(CASES) == 6
    assert len({case["calculation_offset"] for case in CASES}) == 6
    assert CASES[0]["target_offset"] - CASES[0]["calculation_offset"] == 5000
    assert CASES[1]["target_offset"] - CASES[1]["calculation_offset"] == -5000
    assert CASES[2]["target_offset"] == CASES[2]["calculation_offset"]
    assert tuple(c["calculation_offset"] for c in CASES[3:]) == (-1, 0, 1)
    assert all(c["target_offset"] == 0 for c in CASES[3:])
    assert case_days(4) == (FOUNDATION_DAY - 1, FOUNDATION_DAY)
    assert case_days(6) == (FOUNDATION_DAY + 1, FOUNDATION_DAY)
    assert extract_five(
        "STAGE01_CONTEXT_FIELDS=5000,15,1,18,1",
        "STAGE01_CONTEXT_FIELDS=",
    ) == (5000, 15, 1, 18, 1)
    try:
        extract_five("STAGE01_CONTEXT_FIELDS=1,2,3,4", "STAGE01_CONTEXT_FIELDS=")
    except ValueError:
        pass
    else:
        raise AssertionError("Malformed four-field result was accepted")
    print("STAGE01_CALC_CONTEXT_HARNESS_UNIT_ASSERTIONS=11/11")

def compare(reference: Path, executable: Path, commit: str, branch: str, run_id: int) -> int:
    if len(commit) != 40 or any(ch not in "0123456789abcdef" for ch in commit.lower()):
        raise ValueError("Fortran commit must be a full 40-character SHA")
    if not branch or run_id <= 0:
        raise ValueError("Fortran branch and positive workflow run ID are required")
    verify_reference(reference)
    rows = []
    for case_index, case in enumerate(CASES, 1):
        calculation_day, target_day = case_days(case_index)
        row = {
            "case": case_index,
            "label": case["label"],
            "calculation_offset_from_foundation": case["calculation_offset"],
            "target_offset_from_foundation": case["target_offset"],
            "calculation_day": calculation_day,
            "target_day": target_day,
            "status": "error",
            "matched_fields": 0,
        }
        try:
            expected = run_python_reference(case_index, reference)
            actual, fortran_stdout = run_fortran(case_index, executable)
            differences = [
                {"field": name, "python": py, "fortran": ft}
                for name, py, ft in zip(FIELD_NAMES, expected, actual)
                if py != ft
            ]
            row.update(
                python=dict(zip(FIELD_NAMES, expected)),
                fortran=dict(zip(FIELD_NAMES, actual)),
                differences=differences,
                matched_fields=5 - len(differences),
                status="match" if not differences else "mismatch",
                fortran_stdout_tail=fortran_stdout[-1600:],
            )
        except subprocess.TimeoutExpired as err:
            row["status"] = "timeout"
            row["error"] = f"timeout after {err.timeout} seconds"
        except Exception as err:
            row["error"] = repr(err)
        rows.append(row)
        print(
            f"STAGE01_CALC_CONTEXT_CASE={case_index} "
            f"CALC={calculation_day} TARGET={target_day} "
            f"STATUS={row['status']} MATCHED_FIELDS={row['matched_fields']}/5",
            flush=True,
        )
        for difference in row.get("differences", []):
            print(
                "STAGE01_CALC_CONTEXT_FIELD_DIFF="
                + json.dumps({"case": case_index, **difference}, ensure_ascii=False),
                flush=True,
            )

    matched_cases = sum(row["status"] == "match" for row in rows)
    matched_fields = sum(row["matched_fields"] for row in rows)
    report = {
        "project_id": PROJECT_ID,
        "fortran_commit": commit.lower(),
        "fortran_branch": branch,
        "workflow_run": run_id,
        "python_reference_commit": PYTHON_COMMIT,
        "python_reference_blob_sha1": PYTHON_BLOB,
        "python_reference_url": REFERENCE_URL,
        "reference_api": "NormativeCalendar.calendar_date_ids",
        "foundation_day": FOUNDATION_DAY,
        "case_count": len(CASES),
        "matched_cases": matched_cases,
        "matched_fields": matched_fields,
        "total_fields": 5 * len(CASES),
        "reference_timeout_seconds": REFERENCE_TIMEOUT_SECONDS,
        "fortran_timeout_seconds": FORTRAN_TIMEOUT_SECONDS,
        "full_stage1_accepted": False,
        "results": rows,
    }
    Path("stage01_calculation_context_diff.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        f"STAGE01_CALC_CONTEXT_DIFFERENTIAL={matched_cases}/{len(CASES)} CASES; "
        f"{matched_fields}/{5 * len(CASES)} EXACT FIELDS"
    )
    if matched_cases == len(CASES) and matched_fields == 5 * len(CASES):
        print("STAGE01_CALC_CONTEXT_PASS_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
        return 0
    print("STAGE01_CALC_CONTEXT_NOT_ACCEPTED; see stage01_calculation_context_diff.json")
    return 1

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--fortran-exe", type=Path)
    parser.add_argument("--fortran-commit")
    parser.add_argument("--fortran-branch")
    parser.add_argument("--workflow-run", type=int)
    parser.add_argument("--worker", type=int)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return 0
    if args.reference is None:
        parser.error("--reference is required")
    if args.worker is not None:
        return python_worker(args.worker, args.reference)
    if args.fortran_exe is None or args.fortran_commit is None:
        parser.error("--fortran-exe and --fortran-commit are required")
    if args.fortran_branch is None or args.workflow_run is None:
        parser.error("--fortran-branch and --workflow-run are required")
    return compare(
        args.reference, args.fortran_exe,
        args.fortran_commit, args.fortran_branch, args.workflow_run,
    )

if __name__ == "__main__":
    sys.exit(main())
