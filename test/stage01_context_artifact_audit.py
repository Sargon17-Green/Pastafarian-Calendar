#!/usr/bin/env python3
"""Independent structural audit of the Fortran Stage1 context differential artifact.

This checks provenance, exact case coordinates, comparison accounting, ordered
same-process cache traces and hostile evidence mutations. It does NOT recompute
the Python normative calendar, prove the Fortran algorithm, or accept Stage1.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import zipfile
from pathlib import Path

PROJECT = "PC-BRANCH-FORTRAN-ENGLISH"
BRANCH = "Fortran+English"
FOUNDATION = -15055671
PYTHON_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PYTHON_BLOB = "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
FIELDS = ("year_number", "cutlet_name_index", "day_in_cutlet", "month_name_index", "day_in_month")
OFFSETS = (
    (-8192, -3192), (8192, 3192), (137, 137), (-1, 0), (0, 0),
    (1, 0), (-2048, 0), (2048, 0), (0, -1), (0, 1),
    (1, -2032), (-1, 2213), (-1, -2032), (1, 2213),
)
SEQUENCES = {
    "same_process_context_sequence": (11, 13, 12, 14, 11, 13, 12, 14),
    "same_process_reverse_context_sequence": (14, 12, 13, 11, 14, 12, 13, 11),
    "same_process_foundation_context_sequence": (7, 8, 5, 4, 6, 7, 8, 5),
}


class EvidenceError(ValueError):
    pass


def require(condition: bool, description: str) -> None:
    if not condition:
        raise EvidenceError(description)


def integer(value: object) -> bool:
    return type(value) is int


def fields(value: object, label: str) -> dict:
    require(isinstance(value, dict) and set(value) == set(FIELDS), f"{label}: five fields required")
    require(all(integer(value[name]) for name in FIELDS), f"{label}: integer types required")
    require(1 <= value["cutlet_name_index"] <= 17, f"{label}: cutlet index bounds")
    require(1 <= value["month_name_index"] <= 47, f"{label}: month index bounds")
    require(value["day_in_cutlet"] >= 1 and value["day_in_month"] >= 1, f"{label}: day bounds")
    return value


def audit(data: dict, sha: str, run: int) -> int:
    require(isinstance(data, dict), "root object")
    require(data.get("project_id") == PROJECT and data.get("fortran_branch") == BRANCH, "project or branch")
    require(data.get("fortran_commit") == sha and len(sha) == 40, "commit binding")
    require(data.get("workflow_run") == run and run > 0, "run binding")
    require(data.get("python_reference_commit") == PYTHON_COMMIT, "reference commit")
    require(data.get("python_reference_blob_sha1") == PYTHON_BLOB, "reference blob")
    require(data.get("reference_api") == "NormativeCalendar.calendar_date_ids", "reference API")
    require(data.get("foundation_day") == FOUNDATION, "foundation day")
    require(data.get("full_stage1_accepted") is False, "Stage1 acceptance must remain false")
    require(data.get("case_count") == len(OFFSETS), "case count")
    require(data.get("matched_cases") == 14 and data.get("matched_fields") == 70 and data.get("total_fields") == 70, "standalone totals")
    require(data.get("boundary_context_sensitive_pairs") == 2, "boundary sensitivity total")
    require(data.get("foundation_context_sensitive_pairs") == 3, "Foundation sensitivity total")
    require(data.get("boundary_context_expected_pairs") == 2, "boundary expected total")
    rows = data.get("results")
    require(isinstance(rows, list) and len(rows) == 14, "standalone rows")
    for index, ((calc, target), row) in enumerate(zip(OFFSETS, rows), 1):
        require(row.get("case") == index, f"case {index}: order")
        require(row.get("calculation_offset_from_foundation") == calc, f"case {index}: calc offset")
        require(row.get("target_offset_from_foundation") == target, f"case {index}: target offset")
        require(row.get("calculation_day") == FOUNDATION + calc, f"case {index}: calc day")
        require(row.get("target_day") == FOUNDATION + target, f"case {index}: target day")
        expected = fields(row.get("python"), f"case {index} python")
        actual = fields(row.get("fortran"), f"case {index} Fortran")
        require(expected == actual and row.get("differences") == [], f"case {index}: numeric comparison")
        require(row.get("matched_fields") == 5 and row.get("status") == "match", f"case {index}: status/accounting")

    for pair, label in [((11, 13), "4999-boundary"), ((12, 14), "5001-boundary"),
                        ((7, 8), "Foundation distant"), ((4, 6), "Foundation adjacent"),
                        ((5, 7), "Foundation revisit")]:
        a, b = (rows[i - 1] for i in pair)
        require(a["target_day"] == b["target_day"] and a["calculation_day"] != b["calculation_day"], label + " coordinates")
        require(a["python"] != b["python"] and a["fortran"] != b["fortran"], label + " sensitivity")

    observations = 0
    for key, order in SEQUENCES.items():
        seq = data.get(key)
        require(isinstance(seq, dict), key + " object")
        require(seq.get("order") == list(order), key + " order")
        require(seq.get("reset_between_calls") is False, key + " unexpected reset")
        require(seq.get("status") == "match", key + " status")
        require(seq.get("matched_calls") == 8 and seq.get("matched_fields") == 40 and seq.get("total_fields") == 40, key + " totals")
        calls = seq.get("results")
        require(isinstance(calls, list) and len(calls) == 8, key + " call count")
        for step, (index, call) in enumerate(zip(order, calls), 1):
            row = rows[index - 1]
            require(call.get("step") == step and call.get("case") == index, key + " step/case")
            require(call.get("calculation_day") == row["calculation_day"] and call.get("target_day") == row["target_day"], key + " inputs")
            require(fields(call.get("expected_python"), key + " expected") == row["python"], key + " oracle carry-over")
            require(fields(call.get("actual_fortran"), key + " actual") == row["fortran"], key + " observed value")
            require(call.get("matched_fields") == 5, key + " field total")
            observations += 5
    require(observations == 120, "sequence field observations")
    return 70 + observations


def mutation_audit(data: dict, sha: str, run: int) -> int:
    # Each corrupt artifact must be rejected independently, with digest checks disabled.
    tests = (
        ("project", lambda a: a.update(project_id="other")),
        ("commit", lambda a: a.update(fortran_commit="0" * 40)),
        ("run", lambda a: a.update(workflow_run=run + 1)),
        ("reference", lambda a: a.update(python_reference_blob_sha1="0" * 40)),
        ("Stage1", lambda a: a.update(full_stage1_accepted=True)),
        ("case-order", lambda a: a["results"][0].update(case=2)),
        ("target", lambda a: a["results"][0].update(target_day=0)),
        ("oracle-field", lambda a: a["results"][0]["python"].update(year_number=1)),
        ("fortran-field", lambda a: a["results"][0]["fortran"].update(day_in_month=99)),
        ("field-type", lambda a: a["results"][0]["python"].update(year_number=True)),
        ("reset", lambda a: a["same_process_foundation_context_sequence"].update(reset_between_calls=True)),
        ("sequence-order", lambda a: a["same_process_context_sequence"]["results"][0].update(step=2)),
        ("sequence-short", lambda a: a["same_process_reverse_context_sequence"]["results"].pop()),
        ("warm-field", lambda a: a["same_process_foundation_context_sequence"]["results"][5]["actual_fortran"].update(year_number=1)),
        ("sensitivity", lambda a: a["results"][6].update(python=a["results"][7]["python"], fortran=a["results"][7]["fortran"])),
    )
    for name, mutate in tests:
        changed = copy.deepcopy(data)
        mutate(changed)
        try:
            audit(changed, sha, run)
        except EvidenceError:
            continue
        raise EvidenceError(f"Mutation unexpectedly accepted: {name}")
    return len(tests)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument("--json", type=Path)
    src.add_argument("--zip", type=Path)
    parser.add_argument("--expected-commit", required=True)
    parser.add_argument("--run-id", type=int, required=True)
    parser.add_argument("--zip-sha256")
    parser.add_argument("--json-sha256")
    parser.add_argument("--mutations", action="store_true")
    args = parser.parse_args()
    require(not args.zip_sha256 or args.zip, "zip digest requires --zip")
    if args.zip:
        data_bytes = args.zip.read_bytes()
        if args.zip_sha256:
            require(hashlib.sha256(data_bytes).hexdigest() == args.zip_sha256, "ZIP SHA-256 mismatch")
        with zipfile.ZipFile(args.zip) as archive:
            require(archive.testzip() is None, "archive CRC failure")
            names = set(archive.namelist())
            require(names == {"stage01_calculation_context_diff.json",
                              "build/stage01-calculation-context-diff.log",
                              "build/stage01-calculation-context-selftest.log"}, "artifact members")
            content = archive.read("stage01_calculation_context_diff.json")
    else:
        content = args.json.read_bytes()
    if args.json_sha256:
        require(hashlib.sha256(content).hexdigest() == args.json_sha256, "JSON SHA-256 mismatch")
    data = json.loads(content)
    count = audit(data, args.expected_commit, args.run_id)
    print(f"STAGE01_CONTEXT_ARTIFACT_AUDIT_PASS={count}/{count} EXACT FIELDS")
    if args.mutations:
        tested = mutation_audit(data, args.expected_commit, args.run_id)
        print(f"STAGE01_CONTEXT_ARTIFACT_MUTATIONS_REJECTED={tested}/{tested}")
    print("STAGE01_CONTEXT_ARTIFACT_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")


if __name__ == "__main__":
    main()
