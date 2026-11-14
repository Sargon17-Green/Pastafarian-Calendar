#!/usr/bin/env python3
"""Independent per-line RAW <-> normalized evidence gate for the two pinned pilot engines.

This verifies transport integrity and name-index mapping; it is NOT a calendar
oracle and does not certify date correctness or a whole year.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import itertools
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "control/pilot_two_engine_source_locks_v001.json"
DECIMAL = re.compile(r"^(?:0|-?[1-9][0-9]*)$")
HEX64 = re.compile(r"^[a-f0-9]{64}$")
ROW_KEYS = {"calculation_day", "target_day", "year", "cutlet_index",
            "day_in_cutlet", "month_index", "day_in_month", "cutlet_name_raw",
            "month_name_raw", "source_raw_sha256"}


class EvidenceError(ValueError):
    pass


def fail(reason: str) -> None:
    raise EvidenceError(reason)


def canonical_decimal(text: str) -> int:
    if not isinstance(text, str) or not DECIMAL.fullmatch(text):
        fail("noncanonical decimal value")
    return int(text)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def unique_pairs(pairs):
    data = {}
    for key, value in pairs:
        if key in data:
            fail("duplicate JSON object key")
        data[key] = value
    return data


def parse_json_line(data: bytes):
    if not data.endswith(b"\n") or data.count(b"\n") != 1:
        fail("raw/normalized JSONL record must end with exactly one newline")
    try:
        return json.loads(data.decode("utf-8"), object_pairs_hook=unique_pairs)
    except (UnicodeError, ValueError, TypeError) as exc:
        raise EvidenceError("malformed UTF-8 JSONL record") from exc


def verify_locked_sources(source_root: Path, engine_id: str):
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    if lock["schema"] != "PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1" or lock["main_changes_permitted"]:
        fail("unsafe source lock")
    engine = next((e for e in lock["engines"] if e["id"] == engine_id), None)
    if engine is None:
        fail("unknown engine identity")
    folder = "Python-Turkce" if engine_id == "REF-41" else "JavaScript-Interlingue"
    result = {}
    for item in engine["sources"]:
        if Path(item["path"]).is_absolute() or ".." in Path(item["path"]).parts:
            fail("unsafe source path in lock")
        content = (source_root / folder / engine["commit"] / item["path"]).read_bytes()
        if (len(content), sha(content), git_blob(content)) != (
            item["bytes"], item["sha256"], item["git_blob_sha1"]):
            fail("source bytes differ from pinned lock")
        result[item["path"]] = content.decode("utf-8")
    return engine, result


def name_maps(engine_id: str, source_files: dict):
    if engine_id == "REF-41":
        tree = ast.parse(source_files["tests/normative_reference.py"])
        names = {}
        for node in tree.body:
            if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                if node.targets[0].id in ("FROZEN_CUTLET_NAMES", "FROZEN_MONTH_NAMES"):
                    names[node.targets[0].id] = ast.literal_eval(node.value)
        groups = [names.get("FROZEN_CUTLET_NAMES"), names.get("FROZEN_MONTH_NAMES")]
    elif engine_id == "REF-24":
        text = source_files["src/source-language-catalog.js"]
        groups = []
        for group in ("CUTLETS", "MONTHS"):
            found = re.search(r"const " + group + r" = Object\.freeze\(\[(.*?)\]\);", text, re.S)
            if found is None:
                fail("pinned native name group missing")
            rows = re.findall(r"Object\.freeze\(\{\s*canonicalIndex:\s*(\d+),\s*text:\s*'([^']+)'\s*\}\)", found.group(1))
            if not rows or [int(i) for i, _ in rows] != list(range(1, len(rows) + 1)):
                fail("JS native catalog indices not canonical")
            groups.append(tuple(name for _, name in rows))
    else:
        fail("unrecognized engine")
    if any(g is None for g in groups) or [len(x) for x in groups] != [17, 47]:
        fail("invalid language catalog size")
    if any(len(set(g)) != len(g) or not all(isinstance(x, str) and x for x in g) for g in groups):
        fail("nonunique native names")
    return [{name: i + 1 for i, name in enumerate(group)} for group in groups]


def verify_pair(engine_id: str, raw_bytes: bytes, normalized_bytes: bytes,
                cutlets: dict, months: dict, calculation_day: str, target_day: str):
    raw = parse_json_line(raw_bytes)
    row = parse_json_line(normalized_bytes)
    if not isinstance(raw, dict) or not isinstance(row, dict) or set(row) != ROW_KEYS:
        fail("raw/normalized object or normalized schema invalid")
    if row["calculation_day"] != calculation_day or row["target_day"] != target_day:
        fail("normalized input coordinates changed")
    if raw.get("calculation_day") != calculation_day or raw.get("target_day") != target_day:
        fail("native raw input coordinates changed")
    if row["source_raw_sha256"] != sha(raw_bytes):
        fail("normalized line does not bind to raw native bytes")
    if engine_id == "REF-41":
        if set(raw) != {"calculation_day", "target_day", "native_date_ids", "native_names"}:
            fail("invalid raw Python shape")
        ids, names = raw["native_date_ids"], raw["native_names"]
        if set(ids) != {"year_number", "cutlet_name_index", "day_in_cutlet",
                        "month_name_index", "day_in_month"} or set(names) != {"cutlet", "month"}:
            fail("incomplete Python native fields")
        year = canonical_decimal(ids["year_number"])
        ci, cd, mi, md = (ids[k] for k in ("cutlet_name_index", "day_in_cutlet",
                                           "month_name_index", "day_in_month"))
        cn, mn = names["cutlet"], names["month"]
    elif engine_id == "REF-24":
        if set(raw) != {"calculation_day", "target_day", "native_tuple"}:
            fail("invalid raw JS shape")
        values = raw["native_tuple"]
        if not isinstance(values, list) or len(values) != 5:
            fail("invalid native tuple")
        year = canonical_decimal(values[0])
        cn, mn = values[1], values[3]
        cd, md = canonical_decimal(values[2]), canonical_decimal(values[4])
        ci, mi = cutlets.get(cn), months.get(mn)
    else:
        fail("unknown engine")
    if not all(type(v) is int for v in (year, ci, cd, mi, md)):
        fail("noninteger native date field")
    if ci < 1 or mi < 1 or cd < 1 or md < 1:
        fail("zero or negative date index")
    if cutlets.get(cn) != ci or months.get(mn) != mi:
        fail("native name/index mapping invalid")
    expected = {
        "year": str(year), "cutlet_index": ci, "day_in_cutlet": cd,
        "month_index": mi, "day_in_month": md,
        "cutlet_name_raw": cn, "month_name_raw": mn
    }
    for key, val in expected.items():
        if row[key] != val or type(row[key]) is not type(val):
            fail("native/normalized mismatch: " + key)
    return row


def verify_stream(engine_id: str, source_root: Path, raw_path: Path,
                  norm_path: Path, receipt_path: Path):
    engine, source_files = verify_locked_sources(source_root, engine_id)
    cutlets, months = name_maps(engine_id, source_files)
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"), object_pairs_hook=unique_pairs)
    if receipt.get("status") != "NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED":
        fail("no successful native transport completion receipt")
    if receipt.get("engine") != engine_id or receipt.get("source_commit") != engine["commit"]:
        fail("wrong engine or commit receipt")
    expected_sha = [x["sha256"] for x in engine["sources"]]
    if receipt.get("source_sha256") != (expected_sha[0] if engine_id == "REF-41" else expected_sha):
        fail("source SHA receipt differs from locked source")
    c = receipt["calculation_day"]
    first = canonical_decimal(receipt["first_target_day"])
    last = canonical_decimal(receipt["last_target_day"])
    canonical_decimal(c)
    if first > last or last - first + 1 > 5778:
        fail("invalid or excessive target interval")
    if (last > first and (not isinstance(receipt.get("boundary_evidence_sha256"), str)
           or not HEX64.fullmatch(receipt["boundary_evidence_sha256"]))):
        fail("multi-day transport has no independently pinned year boundary receipt")
    if receipt.get("verified_comparisons_completed") != 0 or type(receipt.get("rows")) is not int:
        fail("transport receipt wrongly claims comparisons or has invalid count")
    raw_sha = hashlib.sha256()
    norm_sha = hashlib.sha256()
    rows = 0
    with raw_path.open("rb") as ra, norm_path.open("rb") as no:
        for lines in itertools.zip_longest(ra, no):
            if None in lines:
                fail("native and normalized streams have different lengths")
            target = str(first + rows)
            verify_pair(engine_id, lines[0], lines[1], cutlets, months, c, target)
            raw_sha.update(lines[0])
            norm_sha.update(lines[1])
            rows += 1
    if rows != last - first + 1 or rows != receipt.get("rows"):
        fail("stream incomplete or duplicate day")
    if raw_sha.hexdigest() != receipt.get("raw_stream_sha256") or norm_sha.hexdigest() != receipt.get("normalized_stream_sha256"):
        fail("stream SHA digest does not match receipt")
    return {"status": "NATIVE_RAW_TRANSPORT_EVIDENCE_PASS_BOUNDED",
            "engine": engine_id, "rows_verified": rows, "year_certified": False,
            "source_commit": engine["commit"], "calendar_oracle_checks": 0,
            "verified_comparisons_completed": 0}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--engine", choices=("REF-41", "REF-24"), required=True)
    for arg in ("sources-root", "raw", "normalized", "receipt"):
        p.add_argument("--" + arg, type=Path, required=True)
    a = p.parse_args()
    print(json.dumps(verify_stream(a.engine, a.sources_root, a.raw,
                                   a.normalized, a.receipt), sort_keys=True))


if __name__ == "__main__":
    main()
