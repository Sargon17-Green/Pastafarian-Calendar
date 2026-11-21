#!/usr/bin/env python3
"""Source-locked, offline structural cross-check for SQL+Tamil Slice25.

The original eight PostgreSQL 17 preflight archives are inputs, not generated
by this script. This DOES NOT execute the production SQL or grant Native PASS.
Usage: python3 sql/test/161_stage25_calendar_date_static_evidence.py --archives PATH
"""
from __future__ import annotations

import argparse
import hashlib
import json
from collections import Counter
from pathlib import Path
from zipfile import ZipFile

SOURCE = "1ddaef9a315f83402ececaf4dc31f96dbdd051bd"
EXPECTED = {
    "anchor": (14613743791, "54870a11698f23e2b6a21f7825ed1ac0fdb0bb907039ff01b6fd43fa1ef01c75", 6),
    "next_1": (14614701184, "e1f52060af62d15554794e3e6695a95d8bf7db8b44b2d6ddcbb65d3a2120ef56", 5),
    "next_2": (14614830269, "64e5ac64da6a15a2035ba912b011bb18a5f4ec0ad876edec9222bb5569a7228c", 3),
    "next_3": (14614018802, "160d4e4470702dd1a157fa08b435458f1ce92044ce485483d75a6e38c9bd7b8b", 3),
    "next_3_next": (14613823846, "5cf458be07cc19b258997f38a5af30e7316b61f0bad0688043537703a91cac81", 3),
    "prev_2": (14614715487, "44f7ef3d743d12b506542a55e27b93165727aac791e7ffd9974f0ea80f74f1f9", 3),
    "prev_3": (14614455831, "d77902efb02af29aabd1e124e2f9b4a548a2e8d621ab56784f9f66a8f75c8785", 3),
    "prev_3_prev": (14613763506, "615d08589a6b21386553e401470f3ee8707fbd38957c4fdf04aa3279ae792898", 3),
}
FIELDS = ("year_number", "cutlet_name", "day_in_cutlet", "month_name", "day_in_month")


def jsonl(data: bytes) -> list[dict]:
    return [json.loads(line) for line in data.decode("utf-8").splitlines() if line.strip()]


def check_one(case_name: str, archive: Path) -> tuple[int, int, list[str]]:
    artifact_id, raw_sha, expected_cases = EXPECTED[case_name]
    with archive.open("rb") as f:
        if hashlib.file_digest(f, "sha256").hexdigest() != raw_sha:
            raise AssertionError(f"incorrect original ZIP SHA256: {case_name}")
    with ZipFile(archive) as z:
        if z.testzip() is not None:
            raise AssertionError(f"bad original ZIP CRC: {case_name}")
        needed = {"year.jsonl", "cases.jsonl", "oracle.jsonl", "catalog.jsonl", "versions.txt", "derived-sha256.txt"}
        if not needed.issubset(z.namelist()):
            raise AssertionError(f"missing artifact members: {case_name}")
        versions = z.read("versions.txt").decode("utf-8")
        if SOURCE not in versions or "(PostgreSQL) 17.12" not in versions:
            raise AssertionError(f"source/version lock: {case_name}")
        derived = z.read("derived-sha256.txt").decode("utf-8").splitlines()
        for line in derived:
            sha, filename = line.split("  ", 1)
            basename = filename.split("/")[-1]
            if hashlib.sha256(z.read(basename)).hexdigest() != sha:
                raise AssertionError(f"bad derived source SHA: {case_name}: {basename}")
        year_rows = jsonl(z.read("year.jsonl"))
        cases = jsonl(z.read("cases.jsonl"))
        oracle = jsonl(z.read("oracle.jsonl"))
        catalog_rows = jsonl(z.read("catalog.jsonl"))

    if len(year_rows) != 1 or len(cases) != expected_cases or len(oracle) != expected_cases:
        raise AssertionError(f"wrong case count: {case_name}")
    y = year_rows[0]
    yr = y["year_data"]
    st = y["year_structure"]
    if y["year_id"] != case_name or st["year_data"] != yr:
        raise AssertionError(f"year record mismatch: {case_name}")
    if len(st["cutlet_partition"]) != st["cutlet_count"] or len(st["cutlet_name_indices"]) != st["cutlet_count"]:
        raise AssertionError(f"cutlet cardinality: {case_name}")
    if len(st["month_lengths"]) != st["month_count"] or len(st["month_name_indices"]) != st["month_count"]:
        raise AssertionError(f"month cardinality: {case_name}")
    if sum(st["month_lengths"]) != len(st["month_weaving"]) or len(st["month_weaving"]) != yr["close_gate_day"]-yr["open_gate_day"]:
        raise AssertionError(f"weaving length: {case_name}")
    gates = [int(p["gate_day"]) for p in y["cutlet_prefix_gates"]]
    if gates[0] != yr["open_gate_day"] or gates[-1] != yr["close_gate_day"] or len(gates) != st["cutlet_count"]+1:
        raise AssertionError(f"gate endpoint integrity: {case_name}")
    if any(b <= a for a, b in zip(gates, gates[1:])):
        raise AssertionError(f"gate ordering: {case_name}")
    prefixes = [0]
    for p in st["cutlet_partition"]:
        assert p > 0
        prefixes.append(prefixes[-1]+p)
    if [int(p["prefix"]) for p in y["cutlet_prefix_gates"]] != prefixes:
        raise AssertionError(f"partition/prefix integrity: {case_name}")

    catalog = {(row["category"], row["canonical_index"]):row["source_text_tamil"] for row in catalog_rows}
    if len(catalog) != 64 or {(k,i) for k,i in catalog} != ({("CUTLET",i) for i in range(1,18)} | {("MONTH",i) for i in range(1,48)}):
        raise AssertionError(f"canonical catalog integrity: {case_name}")
    oracle_by_id = {c["case_id"]: c for c in oracle}
    if len(oracle_by_id) != len(oracle):
        raise AssertionError(f"duplicate oracle case: {case_name}")
    names = []
    for case in cases:
        assert case["year_id"] == case_name and case["calculation_day"] == y["calculation_day"]
        day = int(case["target_day"])
        if not yr["open_gate_day"] < day <= yr["close_gate_day"]:
            raise AssertionError(f"unreachable day: {case['case_id']}")
        ci = next((i for i in range(st["cutlet_count"]) if gates[i]<day<=gates[i+1]), None)
        if ci is None:
            raise AssertionError(f"missing cutlet: {case['case_id']}")
        cutlet_ordinal = day-gates[ci]
        weaving = st["month_weaving"]
        month_position = day-yr["open_gate_day"]
        count = Counter()
        month_id = None
        for v in weaving[:month_position]:
            count[v] += 1
            month_id = v
        if month_id is None or count[month_id]>st["month_lengths"][month_id-1]:
            raise AssertionError(f"bad month ordinal: {case['case_id']}")
        actual = dict(zip(FIELDS, (
            yr["year_number"],
            catalog[("CUTLET",st["cutlet_name_indices"][ci])],
            cutlet_ordinal,
            catalog[("MONTH",st["month_name_indices"][month_id-1])],
            count[month_id],
        )))
        frozen = oracle_by_id[case["case_id"]]
        if actual != frozen["expected"] or frozen["target_day"] != day:
            raise AssertionError(f"five-field mismatch: {case['case_id']}")
        names.append(case["case_id"])
    return yr["year_number"],len(cases),names


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archives", type=Path, required=True)
    args = parser.parse_args()
    years, case_ids = [], []
    for name, (artifact_id, _, _) in EXPECTED.items():
        files = list(args.archives.glob(f"sql-tamil-struct-{name}-{artifact_id}.zip"))
        if len(files) != 1:
            raise SystemExit(f"missing/ambiguous original ZIP for {name}: {len(files)}")
        year, n, cases = check_one(name,files[0])
        years.append(year)
        case_ids.extend(cases)
        print(f"SLICE25_STATIC_ORACLE_YEAR={name} YEAR={year} CASES={n} OK")
    if len(set(years)) != 8 or len(case_ids)!=29 or len(set(case_ids))!=29:
        raise AssertionError("overall year/case coverage mismatch")
    print("SLICE25_STATIC_ORACLE=29/29 FIVE_FIELDS=145/145 ORIGINAL_ZIP_SHA256=8/8 CRC=8/8 PASS")
    print("CLASSIFICATION=STATIC_ORACLE_NOT_NATIVE_NOT_DIFFERENTIAL_NOT_SLICE25_ACCEPTANCE")

if __name__ == "__main__":
    main()
