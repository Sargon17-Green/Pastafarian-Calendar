#!/usr/bin/env python3
"""Exact day-by-day witness: derived Kotlin annual TSV vs pinned Python annual JSONL.

These are two annual *derivatives* of original sources, not 4244 independent
native F(c,t) calls. The receipt deliberately cannot signal an accepted
original-source full-year soak comparison.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path
import re
import sys

YEAR_DAYS = 4244
CALC = "-15055671"
FIRST = -15057702
LAST = -15053459
PINNED_PYTHON_ANNUAL_SHA = "74742f95e5f11d225d61de9f19406312201a901bebac87f112e704046b96a3e8"
INT = re.compile(r"^(?:0|-?[1-9][0-9]*)$")
FIELDS = frozenset(("calculation_day", "target_day", "native_structure_derived_fields"))


def strict_json(data: bytes):
    def no_dupes(pairs):
        row = {}
        for key, val in pairs:
            if key in row:
                raise ValueError("duplicate JSON field: " + key)
            row[key] = val
        return row
    return json.loads(data.decode("utf-8"), object_pairs_hook=no_dupes)


def integer_string(s: str):
    if not isinstance(s, str) or not INT.fullmatch(s):
        raise ValueError("noncanonical decimal value")
    return int(s)


def sha_file(file: Path) -> str:
    h = hashlib.sha256()
    with file.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def compare(annual_python: Path, annual_kotlin: Path,
            sample_record: Path) -> dict:
    samples = strict_json(sample_record.read_bytes())
    if (samples.get("schema") != "PASTAFARI_ANNUAL_REUSE_CROSS_NATIVE_SAMPLE_EVIDENCE/1"
            or samples.get("status") != "CROSS_ORIGINAL_KOTLIN_VS_DERIVED_PY_14_SAMPLE_MATCH_NOT_YEAR"
            or samples.get("original_python_annual_derived_stream_sha256") != PINNED_PYTHON_ANNUAL_SHA
            or samples.get("original_kotlin_sample_matches") != 14
            or samples.get("original_python_sample_matches") != 14
            or samples.get("entire_year_cross_engine_compared") is not False
            or samples.get("verified_full_year_comparisons") != 0):
        raise ValueError("unrecognized or overcertified independent sample witness")

    py_sha = sha_file(annual_python)
    if py_sha != PINNED_PYTHON_ANNUAL_SHA:
        raise ValueError("Python annual transcript source SHA-256 mismatch")

    verdict = {
        "schema": "PASTAFARI_DERIVED_TWO_SOURCE_4244_ROW_AGREEMENT_V028/1",
        "status": "DERIVED_WHOLE_YEAR_NOT_COMPARED",
        "calculation_day": CALC,
        "target_first": str(FIRST),
        "target_last": str(LAST),
        "expected_rows": YEAR_DAYS,
        "rows_exactly_compared": 0,
        "first_mismatch": None,
        "python_derived_annual_sha256": py_sha,
        "kotlin_derived_annual_sha256": sha_file(annual_kotlin),
        "original_kotlin_native_sample_matches": 14,
        "original_python_native_sample_matches": 14,
        "original_kotlin_production_commit": samples["original_kotlin_production_commit"],
        "original_python_source_commit": samples["original_python_source_commit"],
        "original_native_all_4244_calls_executed": False,
        "two_independent_original_full_year_transcripts_compared": False,
        "algorithmic_independence_certified": False,
        "canonical_oracle_certified": False,
        "verified_full_year_soak_comparisons": 0,
        "soak_started": False,
    }
    with annual_python.open("rb") as py, annual_kotlin.open("rb") as kt:
        for offset, pair in enumerate(itertools.zip_longest(py, kt, fillvalue=None)):
            raw_py, raw_kt = pair
            if raw_py is None or raw_kt is None:
                verdict["status"] = "FIRST_MISMATCH_STREAM_LENGTH_STOP"
                verdict["first_mismatch"] = {"offset0": offset, "reason": "missing_or_extra_line"}
                break
            if offset >= YEAR_DAYS:
                verdict["status"] = "FIRST_MISMATCH_EXTRA_ROWS_STOP"
                verdict["first_mismatch"] = {"offset0": offset, "reason": "extra_rows"}
                break
            if (not raw_py.endswith(b"\n") or raw_py.count(b"\n") != 1
                    or not raw_kt.endswith(b"\n") or raw_kt.count(b"\n") != 1):
                verdict["status"] = "FIRST_MISMATCH_JSONL_OR_TSV_FRAME_STOP"
                verdict["first_mismatch"] = {"offset0": offset, "reason": "line_ending"}
                break
            row = strict_json(raw_py)
            if not isinstance(row, dict) or set(row) != FIELDS:
                raise ValueError("derived Python annual shape mismatch")
            target = str(FIRST + offset)
            values = row["native_structure_derived_fields"]
            if (row["calculation_day"] != CALC or row["target_day"] != target
                    or not isinstance(values, list) or len(values) != 5
                    or any(integer_string(x) <= 0 for x in values)
                    or values[0] != "5000"):
                raise ValueError("invalid or discontinuous Python source annual day")
            try:
                native = raw_kt[:-1].decode("utf-8").split("\t")
            except UnicodeError as ex:
                raise ValueError("non-UTF8 Kotlin native output") from ex
            if len(native) != 7 or any(not INT.fullmatch(x) for x in native):
                raise ValueError("malformed Kotlin derived seven-column output")
            expected = [CALC, target] + values
            if native != expected:
                verdict["status"] = "FIRST_MISMATCH_DATE_FIELDS_STOP"
                col = next(i for i in range(7) if native[i] != expected[i])
                verdict["first_mismatch"] = {
                    "target": target,
                    "row_index1": offset + 1,
                    "first_difference_column0": col,
                    "python_derived_fields": expected,
                    "kotlin_derived_fields": native,
                }
                break
            verdict["rows_exactly_compared"] += 1
            if verdict["rows_exactly_compared"] % 512 == 0:
                print(
                    "DERIVED_ANNUAL_CROSS_ROWS_MATCH="
                    + str(verdict["rows_exactly_compared"]),
                    flush=True,
                )
    if verdict["first_mismatch"] is None:
        if verdict["rows_exactly_compared"] != YEAR_DAYS:
            verdict["status"] = "FIRST_MISMATCH_STREAM_INCOMPLETE_STOP"
            verdict["first_mismatch"] = {"reason": "too_few_rows"}
        else:
            verdict["status"] = "TWO_DERIVED_4244_ROW_TRANSCRIPTS_MATCH_NOT_NATIVE_YEAR_CERTIFIED"
    return verdict


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--python-annual", type=Path, required=True)
    parser.add_argument("--kotlin-annual", type=Path, required=True)
    parser.add_argument("--original-sample-evidence", type=Path, required=True)
    parser.add_argument("--verdict", type=Path, required=True)
    args = parser.parse_args()
    result = compare(args.python_annual, args.kotlin_annual, args.original_sample_evidence)
    with args.verdict.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(result, f, ensure_ascii=False, sort_keys=True, indent=2)
        f.write("\n")
    print("DERIVED_ANNUAL_CROSS_RESULT=" + json.dumps(result, sort_keys=True), flush=True)
    if result["status"] != "TWO_DERIVED_4244_ROW_TRANSCRIPTS_MATCH_NOT_NATIVE_YEAR_CERTIFIED":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
