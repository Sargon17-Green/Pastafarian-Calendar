#!/usr/bin/env python3
"""Fail-closed original Python/Kotlin year5000 boundary comparison for changed c.

This checks only year navigation, and never awards full-date, source-independence
or whole-year soak credit. Values are computed from each immutable source.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

CASES = ("-15055672", "-15055670", "-15054671")
FIELDS = ("calculation_day", "year", "open_gate_index", "close_gate_index",
          "open_gate_day", "close_gate_day", "first_target_day",
          "last_target_day", "length_days")
INTEGER = re.compile(r"^(?:0|-?[1-9][0-9]*)$")


def load_json(data: bytes):
    def unique(pairs):
        z = {}
        for k, v in pairs:
            if k in z:
                raise ValueError("duplicate evidence key " + k)
            z[k] = v
        return z
    return json.loads(data.decode("utf8"), object_pairs_hook=unique)


def checked_row(row, c):
    if not isinstance(row, dict) or set(row) != set(FIELDS):
        raise ValueError("non-native or unexpected year boundary record")
    if any(not isinstance(row[k], str) or not INTEGER.fullmatch(row[k]) for k in FIELDS):
        raise ValueError("non-canonical decimal native year record")
    open_day, close_day = int(row["open_gate_day"]), int(row["close_gate_day"])
    oi, ci = int(row["open_gate_index"]), int(row["close_gate_index"])
    if (row["calculation_day"] != c or row["year"] != "5000"
            or not open_day < int(c) <= close_day
            or not 252 <= close_day-open_day <= 5778
            or ci-oi < 6 or row["first_target_day"] != str(open_day+1)
            or row["last_target_day"] != str(close_day)
            or row["length_days"] != str(close_day-open_day)):
        raise ValueError("invalid native year5000 geometry")


def compare(py_file: Path, kotlin_file: Path):
    raw_py, raw_kotlin = py_file.read_bytes(), kotlin_file.read_bytes()
    py = load_json(raw_py)
    if not isinstance(py, list) or len(py) != len(CASES):
        raise ValueError("Python original witness has wrong count")
    if not raw_kotlin.endswith(b"\n"):
        raise ValueError("Kotlin output missing final newline")
    lines = raw_kotlin.decode("utf8").splitlines()
    if len(lines) != len(CASES):
        raise ValueError("Kotlin original witness has wrong count")
    kt = []
    for line in lines:
        split = line.split("\t")
        if len(split) != len(FIELDS):
            raise ValueError("Kotlin original native column count")
        kt.append(dict(zip(FIELDS, split)))
    for index, c in enumerate(CASES):
        checked_row(py[index], c)
        checked_row(kt[index], c)
    first_diff = next((
        {"calculation_day":c, "column":column,
         "python":py[i][column], "kotlin":kt[i][column]}
        for i,c in enumerate(CASES)
        for column in FIELDS if py[i][column] != kt[i][column]), None)
    distinct = len({
        (r["open_gate_index"],r["close_gate_index"],
         r["open_gate_day"],r["close_gate_day"]) for r in py
    })
    return {
        "schema":"PASTAFARI_ALTERNATE_CALCULATION_ORIGINAL_YEAR5000_V033/1",
        "status":("THREE_CALCULATION_NATIVE_YEAR_BOUNDS_MATCH_NOT_CERTIFIED"
                  if first_diff is None else "FIRST_NATIVE_CALCULATION_YEAR_BOUNDARY_MISMATCH_STOP"),
        "original_python_source_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        "original_kotlin_source_commit":"0c703446d8a3b7435698bd16402ac5fa30e461c9",
        "calculation_days":list(CASES),
        "python_native_year_bounds":py,
        "kotlin_native_year_bounds":kt,
        "distinct_year5000_geometries":distinct,
        "boundary_fields_exactly_compared":27 if first_diff is None else 0,
        "first_mismatch":first_diff,
        "original_python_witness_sha256":hashlib.sha256(raw_py).hexdigest(),
        "original_kotlin_witness_sha256":hashlib.sha256(raw_kotlin).hexdigest(),
        "full_date_native_calls":0,
        "derived_year_rows_compared":0,
        "original_full_year_soak_passes":0,
        "independent_oracle_certified":False,
        "algorithmic_independence_certified":False,
        "soak_started":False,
        "main_modified":False,
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--python",type=Path,required=True)
    p.add_argument("--kotlin",type=Path,required=True)
    p.add_argument("--verdict",type=Path,required=True)
    args = p.parse_args()
    verdict=compare(args.python,args.kotlin)
    with args.verdict.open("x",encoding="utf8",newline="\n") as f:
        json.dump(verdict,f,indent=2,sort_keys=True)
        f.write("\n")
    print("NATIVE_ALTERNATE_C_YEAR_BOUNDS_V033="+json.dumps(verdict,sort_keys=True),flush=True)
    if verdict["status"]!="THREE_CALCULATION_NATIVE_YEAR_BOUNDS_MATCH_NOT_CERTIFIED":
        raise SystemExit(1)


if __name__=="__main__":
    main()
