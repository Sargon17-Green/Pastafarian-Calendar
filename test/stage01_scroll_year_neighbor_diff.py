#!/usr/bin/env python3
"""QA-only: immediate days outside independently reconstructed Foundation year."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from stage01_scroll_full_date_diff import (
    PROJECT_ID, SOURCE_SHA256, gate_data, find_year, full_date,
    memory_limiter, parse_one, BOUNDARY_CASES, WIDE_CONTEXT_CASES,
    LEGACY_OFFSET_ZERO_CASES, ACTUAL_WEAVE_OFFSET_ZERO_CASES,
)
from stage01_scroll_month_endpoint_diff import LOCKED_OFFSETS, require


def select_neighbors(year):
    require(year["number"] == 5000, "wrong anchor year")
    require(year["close_day"] - year["open_day"] == year["days"], "year span mismatch")
    return (year["open_day"], year["close_day"] + 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fortran-exe", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)
    sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    report = {"project_id": PROJECT_ID, "source_commit": sha,
              "source_sha256": SOURCE_SHA256, "source_bytes_verified": False,
              "full_stage1_accepted": False, "comparison_pass": False,
              "calculation_offset": 0, "cases": []}

    def save():
        (out / "report.json").write_text(json.dumps(report, indent=2, sort_keys=True) + "\n",
                                        encoding="utf-8")

    save()
    try:
        require(sha == os.environ.get("GITHUB_SHA", sha), "checkout SHA mismatch")
        require(select_neighbors({"number": 5000, "open_day": -3, "close_day": 7, "days": 10})
                == (-3, 8), "synthetic inclusive year boundary")
        print("YEAR_NEIGHBOR_SELECTION_SELFTEST=1/1", flush=True)
        pairs, _, _ = gate_data(4022 + 2 * 5778 + 963)
        anchor = find_year(0, 0, pairs)
        require((anchor["open_day"], anchor["close_day"], anchor["days"]) ==
                (-4022, 377, 4399), "Foundation year identity changed")
        targets = select_neighbors(anchor)
        require(targets == (-4022, 378), "canonical neighbor offsets changed")
        old = {(c, t) for _, c, t in BOUNDARY_CASES + WIDE_CONTEXT_CASES +
               LEGACY_OFFSET_ZERO_CASES + ACTUAL_WEAVE_OFFSET_ZERO_CASES}
        old.update((0, t) for t in LOCKED_OFFSETS)
        require(not any((0, t) in old for t in targets), "previously covered direct pair")
        report["anchor_year"] = anchor
        # Generate expected values independently before starting any Fortran process.
        for target, year_number in zip(targets, (4999, 5001)):
            expected = full_date(0, target, 180, 150000)
            year = expected["year"]
            fields = expected["fields"]
            require(len(fields) == 5 and fields[0] == year_number and year["number"] == year_number,
                    "adjacent year identity")
            if year_number == 4999:
                require(year["close_day_offset"] == target == anchor["open_day"],
                        "previous closing day mismatch")
            else:
                require(year["open_day_offset"] == anchor["close_day"] == target - 1,
                        "next opening day mismatch")
            report["cases"].append({"target_offset": target, "expected": fields,
                                    "oracle_year": year, "oracle_structure": expected["structure"]})
        save()
        for i, case in enumerate(report["cases"], 1):
            target = case["target_offset"]
            start = time.monotonic()
            stdout_path = out / f"case-{i:02d}.stdout"
            stderr_path = out / f"case-{i:02d}.stderr"
            case["attempted"] = True
            try:
                proc = subprocess.run([str(args.fortran_exe.resolve()), "0", str(target)],
                                      capture_output=True, timeout=120, check=False,
                                      preexec_fn=memory_limiter(1024))
                stdout_path.write_bytes(proc.stdout)
                stderr_path.write_bytes(proc.stderr)
                case["exit_code"] = proc.returncode
                require(proc.returncode == 0 and not proc.stderr, "candidate exit or stderr")
                output = proc.stdout.decode("utf-8", errors="strict")
                require(int(parse_one(output, "STAGE01_SCROLL_DATE_CALC_OFFSET=")) == 0,
                        "calculation offset framing")
                require(int(parse_one(output, "STAGE01_SCROLL_DATE_TARGET_OFFSET=")) == target,
                        "target offset framing")
                actual = tuple(map(int, parse_one(output, "STAGE01_SCROLL_DATE_FIELDS=").split(",")))
                require(len(actual) == 5, "candidate field width")
                case["actual"] = actual
                case["fields_matched"] = sum(a == b for a, b in zip(actual, case["expected"]))
                case["match"] = case["fields_matched"] == 5
            except subprocess.TimeoutExpired as exc:
                stdout_path.write_bytes(exc.stdout or b"")
                stderr_path.write_bytes(exc.stderr or b"")
                case.update(timeout=True, match=False, error=str(exc))
            except Exception as exc:
                case.update(match=False, error=str(exc))
            finally:
                case["elapsed_seconds"] = round(time.monotonic() - start, 3)
                for label, path in (("stdout", stdout_path), ("stderr", stderr_path)):
                    if path.exists():
                        case[label + "_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
                save()
                print("YEAR_NEIGHBOR_CASE", i, target, case.get("match", False), flush=True)
        calls = sum(c.get("match", False) for c in report["cases"])
        fields = sum(c.get("fields_matched", 0) for c in report["cases"])
        report.update(cases_matched=calls, fields_matched=fields,
                      comparison_pass=(calls == 2 and fields == 10))
        print(f"CANONICAL_YEAR_NEIGHBOR_DIRECT={calls}/2 CASES; {fields}/10 EXACT FIELDS", flush=True)
        print("CANONICAL_YEAR_NEIGHBOR_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE", flush=True)
        require(report["comparison_pass"], "year neighbor differential failed")
    except Exception as exc:
        report["error"] = str(exc)
        raise
    finally:
        save()


if __name__ == "__main__":
    main()
