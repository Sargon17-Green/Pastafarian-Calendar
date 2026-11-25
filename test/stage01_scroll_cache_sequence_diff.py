#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
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

PREFIX = "STAGE01_SCROLL_SEQUENCE_RESULT="


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
    return checks


def run_sequence_process(executable: Path, calls, timeout_seconds: int):
    input_lines = [str(len(calls))]
    input_lines.extend(
        f"{calculation_offset} {target_offset} {reset_before}"
        for _, _, _, calculation_offset, target_offset, reset_before in calls
    )
    try:
        process = subprocess.run(
            [str(executable.resolve())],
            input="\n".join(input_lines) + "\n",
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            check=False,
            preexec_fn=memory_limiter(1024),
        )
    except subprocess.TimeoutExpired as exc:
        def tail(value):
            if value is None:
                return ""
            if isinstance(value, bytes):
                value = value.decode("utf-8", "replace")
            return str(value)[-2000:]
        partial = tail(exc.stdout)
        partial_records = sum(line.startswith(PREFIX) for line in partial.splitlines())
        raise TimeoutError(
            f"Fortran {calls[0][0]} sequence timed out after {timeout_seconds}s; "
            f"partial_records_in_tail={partial_records}/{len(calls)}; "
            f"stdout_tail={partial}; stderr_tail={tail(exc.stderr)}"
        ) from exc
    if process.returncode != 0:
        raise RuntimeError(
            f"Fortran {calls[0][0]} sequence exit={process.returncode}; "
            f"stdout={process.stdout[-2000:]}; stderr={process.stderr[-2000:]}"
        )
    records = [
        line[len(PREFIX):]
        for line in process.stdout.splitlines()
        if line.startswith(PREFIX)
    ]
    if len(records) != len(calls):
        raise ValueError(
            f"{calls[0][0]} sequence expected {len(calls)} records, got {len(records)}; "
            f"stdout={process.stdout[-2000:]}; stderr={process.stderr[-2000:]}"
        )
    count_lines = [
        line for line in process.stdout.splitlines()
        if line.startswith("STAGE01_SCROLL_SEQUENCE_COUNT=")
    ]
    if count_lines != [f"STAGE01_SCROLL_SEQUENCE_COUNT={len(calls)}"]:
        raise ValueError(f"{calls[0][0]} sequence count footer missing or incorrect")
    parsed = []
    for local_index, record in enumerate(records, start=1):
        parts = record.split(",")
        if len(parts) != 8:
            raise ValueError("malformed Fortran sequence record: " + record)
        if int(parts[0]) != local_index:
            raise ValueError(
                f"{calls[0][0]} process record index {parts[0]} != {local_index}"
            )
        parsed.append(tuple(parts))
    return parsed, process.stdout, process.stderr


def run_sequence(executable: Path, calls, timeout_seconds: int):
    parsed_all = []
    stdout_parts = []
    stderr_parts = []
    for mode in ("warm", "reset-each"):
        mode_calls = [call for call in calls if call[0] == mode]
        if len(mode_calls) != 24:
            raise ValueError(f"expected 24 {mode} calls, got {len(mode_calls)}")
        parsed, stdout, stderr = run_sequence_process(
            executable, mode_calls, timeout_seconds
        )
        stdout_parts.append(f"STAGE01_CACHE_PROCESS_MODE={mode}\n{stdout}")
        if stderr:
            stderr_parts.append(f"STAGE01_CACHE_PROCESS_MODE={mode}\n{stderr}")
        for record in parsed:
            parts = list(record)
            parts[0] = str(len(parsed_all) + 1)
            parsed_all.append(tuple(parts))
    if len(parsed_all) != len(calls):
        raise ValueError(f"combined cache process count mismatch: {len(parsed_all)}/{len(calls)}")
    return parsed_all, "\n".join(stdout_parts), "\n".join(stderr_parts)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--sequence-exe", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--max-seconds", type=float, default=180)
    parser.add_argument("--max-states", type=int, default=150000)
    parser.add_argument("--fortran-timeout", type=int, default=800)
    args = parser.parse_args()

    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)

    if args.self_test:
        checks = self_test()
        print(f"STAGE01_SCROLL_CACHE_SEQUENCE_SELFTEST={checks}/{checks}")

    if args.sequence_exe is None:
        return 0

    calls = make_calls()
    expected_cache = {}
    for _, _, case_id, calculation_offset, target_offset, _ in calls:
        key = (calculation_offset, target_offset)
        if key not in expected_cache:
            expected_cache[key] = full_date(
                calculation_offset,
                target_offset,
                args.max_seconds,
                args.max_states,
            )["fields"]

    parsed, stdout, stderr = run_sequence(args.sequence_exe, calls, args.fortran_timeout)
    mode_summary = {
        "warm": {"calls": 0, "matched_calls": 0, "matched_fields": 0, "mismatches": []},
        "reset-each": {"calls": 0, "matched_calls": 0, "matched_fields": 0, "mismatches": []},
    }
    detailed = []
    for index, (call, record) in enumerate(zip(calls, parsed), start=1):
        mode, group_name, case_id, calculation_offset, target_offset, reset_before = call
        record_index, record_calc, record_target = map(int, record[:3])
        actual = tuple(map(int, record[3:]))
        expected = tuple(map(int, expected_cache[(calculation_offset, target_offset)]))
        if (record_index, record_calc, record_target) != (index, calculation_offset, target_offset):
            raise ValueError(f"sequence input echo mismatch at call {index}: {record}")
        matched = actual == expected
        bucket = mode_summary[mode]
        bucket["calls"] += 1
        if matched:
            bucket["matched_calls"] += 1
            bucket["matched_fields"] += 5
        else:
            bucket["mismatches"].append({
                "call": index, "group": group_name, "case_id": case_id,
                "calculation_offset": calculation_offset, "target_offset": target_offset,
                "expected": expected, "actual": actual,
            })
        detailed.append({
            "call": index, "mode": mode, "group": group_name, "case_id": case_id,
            "calculation_offset": calculation_offset, "target_offset": target_offset,
            "reset_before": bool(reset_before), "expected": expected, "actual": actual,
            "matched": matched,
        })

    total_calls = sum(item["calls"] for item in mode_summary.values())
    matched_calls = sum(item["matched_calls"] for item in mode_summary.values())
    matched_fields = sum(item["matched_fields"] for item in mode_summary.values())
    report = {
        "project": "PC-BRANCH-FORTRAN-ENGLISH",
        "source_sha256": SOURCE_SHA256,
        "scope": "same-process cache reuse and reset differential against the independent Hebrew Scroll full-date oracle",
        "sequence_case_count": len(CASE_BY_ID),
        "sequence_groups": [{"name": name, "case_ids": ids} for name, ids in SEQUENCES],
        "modes": mode_summary,
        "total_calls": total_calls,
        "matched_calls": matched_calls,
        "matched_fields": matched_fields,
        "records": detailed,
        "qa_only_not_full_stage1_acceptance": True,
    }
    output = args.output or Path("build/stage01-scroll-cache-sequences.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    for mode, result in mode_summary.items():
        print(
            f"STAGE01_SCROLL_CACHE_SEQUENCE_MODE={mode} "
            f"MATCHED_CALLS={result['matched_calls']}/{result['calls']} "
            f"MATCHED_FIELDS={result['matched_fields']}/{result['calls'] * 5}"
        )
    print(
        f"STAGE01_SCROLL_CACHE_SEQUENCE_DIFFERENTIAL="
        f"{sum(1 for v in mode_summary.values() if not v['mismatches'])}/2 MODES; "
        f"{matched_calls}/{total_calls} CALLS; {matched_fields}/{total_calls * 5} EXACT FIELDS"
    )
    print("STAGE01_SCROLL_CACHE_SEQUENCE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    return 0 if matched_calls == total_calls and matched_fields == total_calls * 5 else 2


if __name__ == "__main__":
    raise SystemExit(main())
