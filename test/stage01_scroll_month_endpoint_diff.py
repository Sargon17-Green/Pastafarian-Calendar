#!/usr/bin/env python3
"""QA-only direct-entry endpoint differential for canonical Foundation year."""
import argparse
import collections
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from stage01_scroll_full_date_diff import (
    PROJECT_ID, SOURCE_SHA256, gate_data, find_year, build_year_structure,
    full_date, memory_limiter, parse_one, BOUNDARY_CASES, WIDE_CONTEXT_CASES,
    LEGACY_OFFSET_ZERO_CASES, ACTUAL_WEAVE_OFFSET_ZERO_CASES,
)
from stage01_scroll_weaving_reverse_endpoint import word_invariants

MONTHS = (1, 15, 30, 44)
LOCKED_OFFSETS = (-4021, -50, -4005, 335, -3974, 359, -3852, 377)

def require(condition, message):
    if not condition:
        raise ValueError(message)

def endpoints(word, lengths, first, months):
    require(len(set(months)) == len(months), "duplicate selected month")
    require(collections.Counter(word) == collections.Counter(
        {i: n for i, n in enumerate(lengths, 1)}), "month frequencies")
    selected = []
    for mid in months:
        require(1 <= mid <= len(lengths), "month ID out of bounds")
        positions = [i for i, x in enumerate(word) if x == mid]
        require(len(positions) >= 2, "distinct endpoints required")
        selected.extend([(mid, "first", first + positions[0], 1),
                         (mid, "last", first + positions[-1], lengths[mid-1])])
    require(len({r[2] for r in selected}) == len(selected), "duplicate targets")
    return selected

def selftest():
    require(endpoints((1,2,1,2), (2,2), -3, (1,2)) ==
            [(1,"first",-3,1),(1,"last",-1,2),
             (2,"first",-2,1),(2,"last",0,2)], "synthetic endpoints")
    for word, lengths, months in [
        ((1,2,2,2),(2,2),(1,2)),
        ((1,2,1,2),(2,2),(1,1)),
        ((1,2,1,2),(2,2),(3,)),
        ((1,2,2),(1,2),(1,)),
    ]:
        try:
            endpoints(word,lengths,0,months)
        except ValueError:
            continue
        raise ValueError("invalid synthetic input accepted")
    print("ENDPOINT_SELECTION_SELFTEST=5/5", flush=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fortran-exe", type=Path, required=True)
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    out = args.out_dir
    out.mkdir(parents=True, exist_ok=True)
    sha = subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip()
    report = {"project_id": PROJECT_ID, "source_commit": sha,
              "source_sha256": SOURCE_SHA256, "source_bytes_verified": False,
              "full_stage1_accepted": False, "comparison_pass": False,
              "calculation_offset": 0, "cases": []}
    def save():
        (out/"report.json").write_text(json.dumps(report, indent=2, sort_keys=True)+"\n", encoding="utf-8")
    save()
    try:
        require(sha == os.environ.get("GITHUB_SHA", sha), "checkout SHA mismatch")
        selftest()
        pairs, by_index, by_day = gate_data(max(map(abs,LOCKED_OFFSETS))+2*5778+963)
        year = find_year(0, 0, pairs)
        structure = build_year_structure(0, year, by_index, by_day, 180, 150000)
        word, lengths = structure["weaving"], structure["month_lengths"]
        first = structure["first_day"]
        require((year["number"], first, year["days"], structure["month_count"]) ==
                (5000,-4021,4399,44), "canonical year identity")
        word_invariants(lengths, word)
        selected = endpoints(word, lengths, first, MONTHS)
        require(tuple(r[2] for r in selected) == LOCKED_OFFSETS, "canonical endpoint offsets changed")
        old = {(c,t) for _,c,t in BOUNDARY_CASES+WIDE_CONTEXT_CASES+
               LEGACY_OFFSET_ZERO_CASES+ACTUAL_WEAVE_OFFSET_ZERO_CASES}
        require(not any((0,r[2]) in old for r in selected), "previously tested pair")
        report.update(month_lengths=lengths, year_first_offset=first,
                      year_days=len(word), month_count=len(lengths),
                      weaving_sha256=hashlib.sha256(",".join(map(str,word)).encode("ascii")).hexdigest())
        # Compute all expected values before launching any candidate process.
        for mid, edge, target, ordinal in selected:
            expected = full_date(0,target,180,150000)
            fields = expected["fields"]
            require(fields[0] == 5000 and fields[3] == structure["month_name_indices"][mid-1]
                    and fields[4] == ordinal, "independent endpoint projection mismatch")
            require(expected["structure"]["weaving_sha256"] == report["weaving_sha256"],
                    "independent year weaving mismatch")
            report["cases"].append({"month_id":mid,"edge":edge,"target_offset":target,
                                   "expected":fields,"expected_month_ordinal":ordinal})
        save()
        for i, case in enumerate(report["cases"],1):
            target = case["target_offset"]
            start = time.monotonic()
            stdout_path = out/f"case-{i:02d}.stdout"
            stderr_path = out/f"case-{i:02d}.stderr"
            case["attempted"] = True
            try:
                proc = subprocess.run([str(args.fortran_exe.resolve()),"0",str(target)],
                                      capture_output=True, timeout=120, check=False,
                                      preexec_fn=memory_limiter(1024))
                stdout_path.write_bytes(proc.stdout)
                stderr_path.write_bytes(proc.stderr)
                case["exit_code"] = proc.returncode
                require(proc.returncode == 0, f"candidate exit {proc.returncode}")
                output = proc.stdout.decode("utf-8", errors="strict")
                require(int(parse_one(output,"STAGE01_SCROLL_DATE_CALC_OFFSET=")) == 0,
                        "calculation offset framing")
                require(int(parse_one(output,"STAGE01_SCROLL_DATE_TARGET_OFFSET=")) == target,
                        "target offset framing")
                actual = tuple(map(int,parse_one(output,"STAGE01_SCROLL_DATE_FIELDS=").split(",")))
                require(len(actual)==5,"candidate field width")
                case["actual"] = actual
                case["fields_matched"] = sum(a==b for a,b in zip(actual,case["expected"]))
                case["match"] = case["fields_matched"] == 5
            except subprocess.TimeoutExpired as exc:
                stdout_path.write_bytes(exc.stdout or b"")
                stderr_path.write_bytes(exc.stderr or b"")
                case["timeout"] = True
                case["match"] = False
                case["error"] = str(exc)
            except Exception as exc:
                case["match"] = False
                case["error"] = str(exc)
            finally:
                case["elapsed_seconds"] = round(time.monotonic()-start,3)
                for label, path in (("stdout",stdout_path),("stderr",stderr_path)):
                    if path.exists():
                        case[label+"_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
                save()
                print("ENDPOINT_CASE",i,target,case.get("match",False),flush=True)
        calls = sum(c.get("match",False) for c in report["cases"])
        fields = sum(c.get("fields_matched",0) for c in report["cases"])
        report.update(cases_matched=calls,fields_matched=fields,comparison_pass=(calls==8 and fields==40))
        print(f"CANONICAL_ENDPOINT_DIRECT={calls}/8 CASES; {fields}/40 EXACT FIELDS",flush=True)
        print("CANONICAL_ENDPOINT_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE",flush=True)
        require(report["comparison_pass"],"endpoint differential failed")
    except Exception as exc:
        report["error"]=str(exc)
        raise
    finally:
        save()

if __name__ == "__main__":
    main()
