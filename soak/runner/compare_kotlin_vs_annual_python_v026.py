#!/usr/bin/env python3
"""Fail-closed comparison of pinned derived Python year transcript vs original Kotlin.

Only compares the 14 days whose derived output was already checked against
the *original, unchanged* Python entrypoint. It does NOT compare a complete
year, does NOT certify independent source lineage, and does not add a second
derived engine. Input files must have fixed hashes and exact native shapes.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

COMMIT_PY = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
COMMIT_KT = "0c703446d8a3b7435698bd16402ac5fa30e461c9"
ANNUAL_DIGEST = "74742f95e5f11d225d61de9f19406312201a901bebac87f112e704046b96a3e8"
INT = re.compile(r"^(?:0|-?[1-9][0-9]*)$")


def parse_json(data: bytes):
    def duplicate_guard(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("duplicate JSON key " + key)
            result[key] = value
        return result
    return json.loads(data.decode("utf-8"), object_pairs_hook=duplicate_guard)


def decimal(v):
    if not isinstance(v, str) or not INT.fullmatch(v):
        raise ValueError("noncanonical or non-string decimal")
    return int(v)


def load_annual(folder: Path):
    receipt = parse_json((folder / "derivation_receipt.json").read_bytes())
    if (receipt.get("schema") != "PASTAFARI_DERIVED_ANNUAL_PYTHON_NATIVE_STRUCTURE_V025/1"
            or receipt.get("status") != "DERIVED_YEAR_TRANSCRIPT_SAMPLED_NATIVE_MATCH_NOT_CERTIFIED"
            or receipt.get("original_source_commit") != COMMIT_PY
            or receipt.get("derived_stream_sha256") != ANNUAL_DIGEST
            or receipt.get("native_original_sample_count") != 14
            or receipt.get("first_sample_mismatch") is not None
            or receipt.get("independent_calendar_oracle_certified") is not False
            or receipt.get("all_year_days_compared_to_original") is not False
            or receipt.get("verified_full_year_comparisons") != 0
            or receipt.get("soak_started") is not False):
        raise ValueError("annual source receipt incomplete or falsely certified")
    samples = receipt.get("native_original_compared_targets")
    if (not isinstance(samples, list) or len(samples) != 14
            or any(not isinstance(x, str) or not INT.fullmatch(x) for x in samples)
            or len(set(samples)) != 14):
        raise ValueError("invalid original-native sample target list")
    raw_bytes = (folder / "derived_python_year5000_all_days.jsonl").read_bytes()
    if (hashlib.sha256(raw_bytes).hexdigest() != ANNUAL_DIGEST
            or not raw_bytes.endswith(b"\n")):
        raise ValueError("derived-year raw stream hash incomplete")
    raw_lines = raw_bytes.splitlines(keepends=True)
    if len(raw_lines) != 4244 or receipt.get("derived_rows") != 4244:
        raise ValueError("derived year not exactly 4244 days")
    first = decimal(receipt.get("first_target_day"))
    last = decimal(receipt.get("last_target_day"))
    c = decimal(receipt.get("calculation_day"))
    if (first, last, c) != (-15057702, -15053459, -15055671):
        raise ValueError("unrecognized foundation-year interval")
    observed = {}
    for i, raw in enumerate(raw_lines):
        if not raw.endswith(b"\n") or raw.count(b"\n") != 1:
            raise ValueError("invalid JSONL record framing")
        row = parse_json(raw)
        if not isinstance(row, dict) or set(row) != {
            "calculation_day", "target_day", "native_structure_derived_fields",
        }:
            raise ValueError("unexpected derived row schema")
        if row["calculation_day"] != str(c) or row["target_day"] != str(first + i):
            raise ValueError("noncontiguous day / changed calculation day")
        fields = row["native_structure_derived_fields"]
        if not isinstance(fields, list) or len(fields) != 5:
            raise ValueError("not 5 derived fields")
        if any(decimal(x) <= 0 for x in fields):
            raise ValueError("invalid nonpositive date ordinal")
        observed[row["target_day"]] = [str(c), row["target_day"]] + fields
    if any(x not in observed for x in samples):
        raise ValueError("sample day outside derived transcript")
    return receipt, samples, observed


def compare(folder: Path, kotlin_tsv: Path):
    receipt, samples, observed = load_annual(folder)
    data = kotlin_tsv.read_bytes()
    lines = data.decode("utf-8").splitlines()
    if not data.endswith(b"\n") or len(lines) != len(samples):
        raise ValueError("Kotlin source rows incomplete or excessive")
    seen = set()
    matched = 0
    first_mismatch = None
    for line_number, line in enumerate(lines, start=1):
        fields = line.split("\t")
        if len(fields) != 7 or any(not INT.fullmatch(x) for x in fields):
            raise ValueError("malformed native Kotlin 7-column output")
        if fields[0] != receipt["calculation_day"]:
            raise ValueError("Kotlin calculation coordinate changed")
        target = fields[1]
        if target not in samples or target in seen:
            raise ValueError("unexpected or duplicate Kotlin target")
        seen.add(target)
        expected = observed[target]
        if fields != expected:
            first_mismatch = {
                "target_day": target,
                "kotlin_native_fields": fields,
                "derived_python_fields": expected,
                "first_difference_column": next(i for i, (a, b) in enumerate(zip(fields, expected)) if a != b),
            }
            break
        matched += 1
    status = ("CROSS_ORIGINAL_KOTLIN_VS_DERIVED_PY_14_SAMPLE_MATCH_NOT_YEAR"
              if matched == 14 and first_mismatch is None
              else "FIRST_NATIVE_KOTLIN_SAMPLE_MISMATCH_STOP")
    return {
        "schema": "PASTAFARI_CROSS_SOURCE_ANNUAL_SAMPLE_V026/1",
        "status": status,
        "original_kotlin_production_commit": COMMIT_KT,
        "original_python_reference_commit": COMMIT_PY,
        "derived_year_source_sha256": ANNUAL_DIGEST,
        "kotlin_native_tsv_sha256": hashlib.sha256(data).hexdigest(),
        "samples_compared": matched,
        "numeric_date_fields_compared": 5 * matched,
        "input_plus_date_fields_compared": 7 * matched,
        "first_mismatch": first_mismatch,
        "derived_year_rows_unmodified": 4244,
        "verified_entire_year_comparisons": 0,
        "full_year_cross_engine_verified": False,
        "kotlin_source_unchanged": True,
        "independent_canonical_oracle_certified": False,
        "algorithmic_independence_certified": False,
        "soak_started": False,
    }


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--annual-dir", type=Path, required=True)
    p.add_argument("--kotlin-tsv", type=Path, required=True)
    p.add_argument("--output-verdict", type=Path, required=True)
    args = p.parse_args()
    verdict = compare(args.annual_dir, args.kotlin_tsv)
    with args.output_verdict.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(verdict, f, ensure_ascii=False, sort_keys=True, indent=2)
        f.write("\n")
    print("KOTLIN_VS_PY_ANNUAL_SAMPLE_V026=" + json.dumps(verdict, sort_keys=True))
    if verdict["status"] != "CROSS_ORIGINAL_KOTLIN_VS_DERIVED_PY_14_SAMPLE_MATCH_NOT_YEAR":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
