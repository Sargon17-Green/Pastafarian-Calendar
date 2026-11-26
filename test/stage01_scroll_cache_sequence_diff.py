#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

from stage01_scroll_full_date_diff import (
    SOURCE_SHA256,
    full_date,
    memory_limiter,
)

CASE_BY_ID = {
    1: (-8192, -3192),
    2: (8192, 3192),
    3: (137, 137),
    4: (-1, 0),
    5: (0, 0),
    6: (1, 0),
    7: (-2048, 0),
    8: (2048, 0),
    9: (0, -1),
    10: (0, 1),
    11: (1, -2032),
    12: (-1, 2213),
    13: (-1, -2032),
    14: (1, 2213),
}

SEQUENCES = (
    ("mixed-year-forward", (11, 13, 12, 14, 11, 13, 12, 14)),
    ("mixed-year-reverse", (14, 12, 13, 11, 14, 12, 13, 11)),
    ("foundation-context", (7, 8, 5, 4, 6, 7, 8, 5)),
)

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
PREFIX = "STAGE01_SCROLL_SEQUENCE_RESULT="
# Three repeated groups exercise exactly these nine of the fourteen catalogued pairs.
SEQUENCE_CASE_IDS = frozenset((4, 5, 6, 7, 8, 11, 12, 13, 14))
EXPECTED_SEQUENCE_PAIRS = 9


def make_calls():
    calls = []
    for mode in ("warm", "reset-each"):
        for group_name, case_ids in SEQUENCES:
            for position, case_id in enumerate(case_ids):
                calculation_offset, target_offset = CASE_BY_ID[case_id]
                reset_before = 1 if mode == "reset-each" or position == 0 else 0
                calls.append(
                    (mode, group_name, case_id, calculation_offset, target_offset, reset_before)
                )
    return calls


def expected_from_documents(documents, calls):
    expected = {}
    for document in documents:
        if document.get("project_id") != PROJECT_ID:
            raise ValueError("oracle artifact project ID mismatch")
        if document.get("source_sha256") != SOURCE_SHA256:
            raise ValueError("oracle artifact Hebrew Scroll source SHA mismatch")
        if document.get("status") != "PASS_BOUNDED_INDEPENDENT_SCROLL_DIFFERENTIAL":
            raise ValueError("oracle artifact is not a completed passing differential")
        if document.get("full_stage1_accepted") is not False:
            raise ValueError("oracle artifact has an invalid full-stage acceptance marker")
        total = int(document.get("total_cases", -1))
        if total < 1 or int(document.get("matched_cases", -1)) != total:
            raise ValueError("oracle artifact case counts are incomplete")
        if int(document.get("matched_fields", -1)) != total * 5:
            raise ValueError("oracle artifact field counts are incomplete")
        cases = document.get("cases")
        if not isinstance(cases, list) or len(cases) != total:
            raise ValueError("oracle artifact case list does not match its declared count")
        for case in cases:
            key = (int(case["calculation_offset"]), int(case["target_offset"]))
            expected_fields = tuple(int(value) for value in case.get("expected_fields", []))
            fortran_fields = tuple(int(value) for value in case.get("fortran_fields", []))
            if len(expected_fields) != 5 or fortran_fields != expected_fields:
                raise ValueError(f"oracle artifact contains a non-matching case: {key}")
            if int(case.get("matched_fields", -1)) != 5:
                raise ValueError(f"oracle artifact case is not a five-field PASS: {key}")
            if key in expected and expected[key] != expected_fields:
                raise ValueError(f"conflicting independent oracle values for {key}")
            expected[key] = expected_fields

    required = {(call[3], call[4]) for call in calls}
    missing = required.difference(expected)
    if missing:
        raise ValueError("oracle artifacts do not cover required sequence pairs: " + repr(sorted(missing)))
    return {key: expected[key] for key in required}


def load_expected_artifacts(paths, calls):
    if len(paths) != 3:
        raise ValueError("expected exactly three same-run full-date oracle JSON artifacts")
    documents = []
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(f"missing full-date oracle artifact: {path}")
        documents.append(json.loads(path.read_text(encoding="utf-8")))
    suites = {document.get("suite") for document in documents}
    if suites != {"wide", "boundary", "legacy-offset-zero"}:
        raise ValueError("full-date oracle artifact suite set is incomplete or unexpected: " + repr(suites))
    return expected_from_documents(documents, calls)


def parse_sequence_records(stdout, calls, allow_partial):
    lines = stdout.splitlines()
    if stdout and not stdout.endswith("\n") and lines and lines[-1].startswith(PREFIX):
        lines = lines[:-1]
    records = [line[len(PREFIX):] for line in lines if line.startswith(PREFIX)]
    if len(records) > len(calls):
        raise ValueError(f"Fortran sequence emitted too many records: {len(records)}/{len(calls)}")

    parsed = []
    for local_index, record in enumerate(records, start=1):
        parts = record.split(",")
        if len(parts) != 8:
            raise ValueError("malformed Fortran sequence record: " + record)
        numeric = tuple(int(value) for value in parts)
        call = calls[local_index - 1]
        if numeric[:3] != (local_index, call[3], call[4]):
            raise ValueError(
                f"Fortran sequence input echo mismatch at local call {local_index}: {record}"
            )
        parsed.append(tuple(parts))

    if not allow_partial:
        if len(parsed) != len(calls):
            raise ValueError(f"sequence expected {len(calls)} records, got {len(parsed)}")
        count_lines = [
            line for line in lines
            if line.startswith("STAGE01_SCROLL_SEQUENCE_COUNT=")
        ]
        if count_lines != [f"STAGE01_SCROLL_SEQUENCE_COUNT={len(calls)}"]:
            raise ValueError("sequence count footer missing or incorrect")
    return parsed


def run_sequence_process(executable: Path, calls, timeout_seconds: int, log_path: Path):
    input_lines = [str(len(calls))]
    input_lines.extend(
        f"{calculation_offset} {target_offset} {reset_before}"
        for _, _, _, calculation_offset, target_offset, reset_before in calls
    )
    log_path.parent.mkdir(parents=True, exist_ok=True)
    timeout_error = None
    try:
        with log_path.open("w", encoding="utf-8") as log:
            process = subprocess.run(
                [str(executable.resolve())],
                input="\n".join(input_lines) + "\n",
                stdout=log,
                stderr=subprocess.STDOUT,
                text=True,
                timeout=timeout_seconds,
                check=False,
                preexec_fn=memory_limiter(1024),
            )
    except subprocess.TimeoutExpired as exc:
        timeout_error = exc

    stdout = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
    parsed = parse_sequence_records(stdout, calls, allow_partial=True)
    if timeout_error is not None:
        raise TimeoutError(
            f"Fortran {calls[0][0]} sequence timed out after {timeout_seconds}s; "
            f"completed_records={len(parsed)}/{len(calls)}; log={log_path}"
        ) from timeout_error
    if process.returncode != 0:
        raise RuntimeError(
            f"Fortran {calls[0][0]} sequence exit={process.returncode}; "
            f"completed_records={len(parsed)}/{len(calls)}; log={log_path}"
        )
    parse_sequence_records(stdout, calls, allow_partial=False)
    return parsed


def evaluate_logs(calls, expected_cache, log_dir):
    mode_summary = {}
    detailed = []
    warm_count = sum(1 for call in calls if call[0] == "warm")
    for mode in ("warm", "reset-each"):
        mode_calls = [call for call in calls if call[0] == mode]
        log_path = log_dir / f"stage01-scroll-cache-sequence-{mode}.log"
        stdout = log_path.read_text(encoding="utf-8", errors="replace") if log_path.exists() else ""
        parsed = parse_sequence_records(stdout, mode_calls, allow_partial=True)
        bucket = {
            "calls": len(mode_calls),
            "completed_calls": len(parsed),
            "matched_calls": 0,
            "matched_fields": 0,
            "mismatches": [],
        }
        global_offset = 0 if mode == "warm" else warm_count
        for local_index, record in enumerate(parsed, start=1):
            call = mode_calls[local_index - 1]
            _, group_name, case_id, calculation_offset, target_offset, reset_before = call
            actual = tuple(int(value) for value in record[3:])
            expected = tuple(expected_cache[(calculation_offset, target_offset)])
            field_matches = sum(actual_value == expected_value for actual_value, expected_value in zip(actual, expected))
            matched = actual == expected
            bucket["matched_fields"] += field_matches
            if matched:
                bucket["matched_calls"] += 1
            else:
                bucket["mismatches"].append({
                    "call": global_offset + local_index,
                    "group": group_name,
                    "case_id": case_id,
                    "calculation_offset": calculation_offset,
                    "target_offset": target_offset,
                    "expected": list(expected),
                    "actual": list(actual),
                    "matched_fields": field_matches,
                })
            detailed.append({
                "call": global_offset + local_index,
                "mode": mode,
                "group": group_name,
                "case_id": case_id,
                "calculation_offset": calculation_offset,
                "target_offset": target_offset,
                "reset_before": bool(reset_before),
                "expected": list(expected),
                "actual": list(actual),
                "matched": matched,
                "matched_fields": field_matches,
            })
        mode_summary[mode] = bucket
    return mode_summary, detailed


def make_report(calls, expected_cache, log_dir, status, error, source_commit, oracle_paths):
    mode_summary, detailed = evaluate_logs(calls, expected_cache, log_dir)
    total_calls = sum(item["calls"] for item in mode_summary.values())
    completed_calls = sum(item["completed_calls"] for item in mode_summary.values())
    matched_calls = sum(item["matched_calls"] for item in mode_summary.values())
    matched_fields = sum(item["matched_fields"] for item in mode_summary.values())
    return {
        "project_id": PROJECT_ID,
        "source_commit": source_commit,
        "source_sha256": SOURCE_SHA256,
        "scope": "same-process cache reuse and reset differential against same-run independent Hebrew Scroll full-date oracle artifacts",
        "sequence_case_count": len(CASE_BY_ID),
        "sequence_groups": [{"name": name, "case_ids": ids} for name, ids in SEQUENCES],
        "oracle_artifacts": [str(path) for path in oracle_paths],
        "oracle_expected_pairs": [
            {
                "calculation_offset": key[0],
                "target_offset": key[1],
                "fields": list(expected_cache[key]),
            }
            for key in sorted(expected_cache)
        ],
        "status": status,
        "error": error,
        "modes": mode_summary,
        "total_calls": total_calls,
        "completed_calls": completed_calls,
        "matched_calls": matched_calls,
        "matched_fields": matched_fields,
        "records": detailed,
        "qa_only_not_full_stage1_acceptance": True,
    }


def persist_report(output, calls, expected_cache, log_dir, status, error, source_commit, oracle_paths):
    report = make_report(calls, expected_cache, log_dir, status, error, source_commit, oracle_paths)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def print_progress(report):
    for mode, result in report["modes"].items():
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_MODE={mode} "
            f"COMPLETED={result['completed_calls']}/{result['calls']} "
            f"MATCHED_CALLS={result['matched_calls']}/{result['calls']} "
            f"MATCHED_FIELDS={result['matched_fields']}/{result['calls'] * 5}",
            flush=True,
        )
    print(
        f"STAGE01_SCROLL_CACHE_SEQUENCE_PROGRESS="
        f"{report['completed_calls']}/{report['total_calls']} RECORDS",
        flush=True,
    )


def self_test():
    checks = 0
    assert len(CASE_BY_ID) == 14
    checks += 1
    assert len(SEQUENCES) == 3 and all(len(ids) == 8 for _, ids in SEQUENCES)
    checks += 1
    assert all(1 <= case_id <= 14 for _, ids in SEQUENCES for case_id in ids)
    checks += 1
    calls = make_calls()
    assert len(calls) == 48
    checks += 1
    warm = [call for call in calls if call[0] == "warm"]
    cold = [call for call in calls if call[0] == "reset-each"]
    assert len(warm) == 24 and sum(call[5] for call in warm) == 3
    checks += 1
    assert len(cold) == 24 and sum(call[5] for call in cold) == 24
    checks += 1

    required_pairs = sorted({(call[3], call[4]) for call in calls})
    assert {call[2] for call in calls} == SEQUENCE_CASE_IDS
    assert len(required_pairs) == EXPECTED_SEQUENCE_PAIRS
    checks += 1
    synthetic_cases = [
        {
            "calculation_offset": calculation_offset,
            "target_offset": target_offset,
            "expected_fields": [1, 2, 3, 4, 5],
            "fortran_fields": [1, 2, 3, 4, 5],
            "matched_fields": 5,
        }
        for calculation_offset, target_offset in required_pairs
    ]
    synthetic_document = {
        "project_id": PROJECT_ID,
        "source_sha256": SOURCE_SHA256,
        "status": "PASS_BOUNDED_INDEPENDENT_SCROLL_DIFFERENTIAL",
        "full_stage1_accepted": False,
        "total_cases": len(synthetic_cases),
        "matched_cases": len(synthetic_cases),
        "matched_fields": len(synthetic_cases) * 5,
        "cases": synthetic_cases,
    }
    assert len(expected_from_documents([synthetic_document], calls)) == EXPECTED_SEQUENCE_PAIRS
    checks += 1
    bad_document = dict(synthetic_document)
    bad_document["source_sha256"] = "0" * 64
    try:
        expected_from_documents([bad_document], calls)
        rejected_bad_source = False
    except ValueError:
        rejected_bad_source = True
    assert rejected_bad_source
    checks += 1
    sample_calls = calls[:2]
    sample_text = "\n".join(
        f"{PREFIX}{index},{call[3]},{call[4]},1,2,3,4,5"
        for index, call in enumerate(sample_calls, start=1)
    ) + "\n"
    assert len(parse_sequence_records(sample_text, sample_calls, allow_partial=True)) == 2
    truncated_text = sample_text + f"{PREFIX}3,unfinished"
    assert len(parse_sequence_records(truncated_text, sample_calls, allow_partial=True)) == 2
    checks += 1
    return checks


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--sequence-exe", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--log-dir", type=Path)
    parser.add_argument("--oracle-json", type=Path, action="append", default=[])
    parser.add_argument("--source-commit", default=os.environ.get("GITHUB_SHA", ""))
    parser.add_argument("--max-seconds", type=float, default=180)
    parser.add_argument("--max-states", type=int, default=150000)
    parser.add_argument("--fortran-timeout", type=int, default=800)
    args = parser.parse_args()

    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)

    if args.self_test:
        checks = self_test()
        print(f"STAGE01_SCROLL_CACHE_SEQUENCE_SELFTEST={checks}/{checks}", flush=True)

    if args.sequence_exe is None:
        return 0

    calls = make_calls()
    output = args.output or Path("build/stage01-scroll-cache-sequences.json")
    log_dir = args.log_dir or output.parent
    log_dir.mkdir(parents=True, exist_ok=True)
    try:
        if args.oracle_json:
            expected_cache = load_expected_artifacts(args.oracle_json, calls)
            print(
                f"STAGE01_SCROLL_CACHE_SEQUENCE_ORACLE_ARTIFACTS={len(args.oracle_json)} "
                f"EXPECTED_PAIRS={len(expected_cache)}/{EXPECTED_SEQUENCE_PAIRS}",
                flush=True,
            )
        else:
            expected_cache = {}
            required_pairs = sorted({(call[3], call[4]) for call in calls})
            for calculation_offset, target_offset in required_pairs:
                print(
                    f"STAGE01_SCROLL_CACHE_SEQUENCE_ORACLE_START="
                    f"{calculation_offset},{target_offset}",
                    flush=True,
                )
                expected_cache[(calculation_offset, target_offset)] = full_date(
                    calculation_offset,
                    target_offset,
                    args.max_seconds,
                    args.max_states,
                )["fields"]
                print(
                    f"STAGE01_SCROLL_CACHE_SEQUENCE_ORACLE_COMPLETE="
                    f"{calculation_offset},{target_offset}",
                    flush=True,
                )
    except Exception as exc:
        print(f"STAGE01_SCROLL_CACHE_SEQUENCE_ORACLE_ERROR={exc}", file=sys.stderr, flush=True)
        return 2

    if len(expected_cache) != EXPECTED_SEQUENCE_PAIRS:
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_EXPECTED_PAIRS={len(expected_cache)}/{EXPECTED_SEQUENCE_PAIRS}",
            file=sys.stderr,
            flush=True,
        )
        return 2

    for mode in ("warm", "reset-each"):
        mode_calls = [call for call in calls if call[0] == mode]
        log_path = log_dir / f"stage01-scroll-cache-sequence-{mode}.log"
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_MODE_START={mode} "
            f"CALLS={len(mode_calls)} TIMEOUT={args.fortran_timeout}s",
            flush=True,
        )
        try:
            run_sequence_process(args.sequence_exe, mode_calls, args.fortran_timeout, log_path)
        except TimeoutError as exc:
            report = persist_report(
                output, calls, expected_cache, log_dir, "TIMEOUT", str(exc),
                args.source_commit, args.oracle_json,
            )
            print_progress(report)
            print(f"STAGE01_SCROLL_CACHE_SEQUENCE_TIMEOUT={mode}", flush=True)
            print("STAGE01_SCROLL_CACHE_SEQUENCE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE", flush=True)
            return 124
        except Exception as exc:
            report = persist_report(
                output, calls, expected_cache, log_dir, "FAIL", str(exc),
                args.source_commit, args.oracle_json,
            )
            print_progress(report)
            print(f"STAGE01_SCROLL_CACHE_SEQUENCE_FAILURE={mode}: {exc}", flush=True)
            print("STAGE01_SCROLL_CACHE_SEQUENCE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE", flush=True)
            return 2
        persist_report(
            output, calls, expected_cache, log_dir, "IN_PROGRESS", None,
            args.source_commit, args.oracle_json,
        )
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_MODE_COMPLETE={mode} "
            f"RECORDS={len(mode_calls)}/{len(mode_calls)}",
            flush=True,
        )

    report = persist_report(
        output, calls, expected_cache, log_dir, "COMPLETE", None,
        args.source_commit, args.oracle_json,
    )
    print_progress(report)
    passed = (
        report["completed_calls"] == 48
        and report["matched_calls"] == 48
        and report["matched_fields"] == 240
    )
    if passed:
        report = persist_report(
            output, calls, expected_cache, log_dir, "PASS", None,
            args.source_commit, args.oracle_json,
        )
        print(
            "STAGE01_SCROLL_CACHE_SEQUENCE_DIFFERENTIAL="
            "2/2 MODES; 48/48 CALLS; 240/240 EXACT FIELDS",
            flush=True,
        )
    else:
        report = persist_report(
            output, calls, expected_cache, log_dir, "FAIL", "one or more sequence fields did not match",
            args.source_commit, args.oracle_json,
        )
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_NOT_ACCEPTED="
            f"{report['matched_calls']}/48 CALLS; {report['matched_fields']}/240 EXACT FIELDS",
            flush=True,
        )
    print("STAGE01_SCROLL_CACHE_SEQUENCE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE", flush=True)
    return 0 if passed else 2

if __name__ == "__main__":
    raise SystemExit(main())
