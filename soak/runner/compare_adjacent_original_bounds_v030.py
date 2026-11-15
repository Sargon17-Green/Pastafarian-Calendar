#!/usr/bin/env python3
"""Fail-closed cross-original-source adjacent-year boundary comparison v030.

Only 3 original Native year navigation outputs are compared, not F(c,t) date
outputs; this never authorizes a full-year soak or independent canonical status.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

HEADERS = ("calculation_day", "year", "open_gate_index", "close_gate_index",
           "open_gate_day", "close_gate_day", "first_target_day",
           "last_target_day", "length_days")
DECIMAL = re.compile(r"^(?:0|-?[1-9][0-9]*)$")


def strict_json(data):
    def no_dupes(pairs):
        result = {}
        for k, v in pairs:
            if k in result:
                raise ValueError("duplicate JSON key: " + k)
            result[k] = v
        return result
    return json.loads(data, object_pairs_hook=no_dupes)


def candidate(py_file: Path, kt_file: Path):
    raw_python = py_file.read_bytes()
    raw_kotlin = kt_file.read_bytes()
    python = strict_json(raw_python)
    if not isinstance(python, list) or len(python) != 3:
        raise ValueError("Python original must provide exactly 3 native year rows")
    if not raw_kotlin.endswith(b"\n"):
        raise ValueError("Kotlin raw output must end with newline")
    kotlin_lines = raw_kotlin.decode("utf8").splitlines()
    if len(kotlin_lines) != 3:
        raise ValueError("Kotlin original must provide exactly 3 native year rows")
    kt_rows = []
    for line in kotlin_lines:
        f = line.split("\t")
        if len(f) != 9:
            raise ValueError("wrong Kotlin native boundary column count")
        kt_rows.append(dict(zip(HEADERS, f)))
    for i in range(3):
        r, k = python[i], kt_rows[i]
        if not isinstance(r, dict) or set(r) != set(HEADERS):
            raise ValueError("wrong Python native boundary fields")
        for col in HEADERS:
            for row in (r, k):
                if not isinstance(row[col], str) or not DECIMAL.fullmatch(row[col]):
                    raise ValueError("noncanonical native boundary decimal")
        assert r["calculation_day"] == k["calculation_day"] == "-15055671"
        assert r["year"] == str(4999 + i)
        assert k["year"] == str(4999 + i)
        for row in (r, k):
            o, cl = int(row["open_gate_day"]), int(row["close_gate_day"])
            oi, ci = int(row["open_gate_index"]), int(row["close_gate_index"])
            if not (oi < ci and ci - oi >= 6 and 252 <= cl-o <= 5778
                    and int(row["first_target_day"]) == o+1
                    and int(row["last_target_day"]) == cl
                    and int(row["length_days"]) == cl-o):
                raise ValueError("invalid original native geometry")
        if i:
            for arr in (python, kt_rows):
                if (arr[i-1]["close_gate_index"] != arr[i]["open_gate_index"]
                        or arr[i-1]["close_gate_day"] != arr[i]["open_gate_day"]):
                    raise ValueError("noncontiguous original adjacent year boundaries")
    first_mismatch = next(
        ((i, col, python[i][col], kt_rows[i][col]) for i in range(3)
         for col in HEADERS if python[i][col] != kt_rows[i][col]), None
    )
    return {
        "schema": "PASTAFARI_NATIVE_ADJACENT_YEAR_BOUNDARY_V030/1",
        "status": "THREE_ORIGINAL_NATIVE_YEAR_BOUNDARIES_AGREE_NOT_CANONICAL_CERTIFIED"
                  if first_mismatch is None else "FIRST_NATIVE_ADJACENT_YEAR_BOUNDARY_MISMATCH_STOP",
        "calculation_day": "-15055671",
        "original_python_commit": "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        "original_kotlin_commit": "0c703446d8a3b7435698bd16402ac5fa30e461c9",
        "years": [str(4999 + i) for i in range(3)],
        "python_boundaries": python,
        "kotlin_boundaries": kt_rows,
        "boundary_fields_compared": 27 if first_mismatch is None else None,
        "first_mismatch": first_mismatch,
        "python_source_stream_sha256": hashlib.sha256(raw_python).hexdigest(),
        "kotlin_source_stream_sha256": hashlib.sha256(raw_kotlin).hexdigest(),
        "original_native_full_date_calls": 0,
        "derived_annual_transcript_comparisons": 0,
        "original_full_year_date_comparisons": 0,
        "algorithmic_independence_certified": False,
        "canonical_oracle_certified": False,
        "soak_started": False,
        "main_modified": False,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--python", type=Path, required=True)
    p.add_argument("--kotlin", type=Path, required=True)
    p.add_argument("--verdict", type=Path, required=True)
    a = p.parse_args()
    result = candidate(a.python, a.kotlin)
    with a.verdict.open("x", encoding="utf8", newline="\n") as f:
        json.dump(result, f, sort_keys=True, indent=2, ensure_ascii=False)
        f.write("\n")
    print("ADJACENT_NATIVE_YEAR_BOUNDARY_V030=" + json.dumps(result, sort_keys=True), flush=True)
    if result["status"] != "THREE_ORIGINAL_NATIVE_YEAR_BOUNDARIES_AGREE_NOT_CANONICAL_CERTIFIED":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
