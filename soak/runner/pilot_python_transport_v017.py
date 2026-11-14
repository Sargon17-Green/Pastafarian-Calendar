#!/usr/bin/env python3
"""Pinned Python/Türkçe F(c,t) transport. Never infers a date field.

Use only as an admitted, low-priority child of the bounded Windows soak runner.
The default executable range is exactly one target day, and check-only does
not execute the converter. Outputs are append-free, write-once raw/normalized
JSONL; a crash leaves incomplete files, never a purported PASS.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "control/pilot_two_engine_source_locks_v001.json"
DECIMAL = re.compile(r"^(?:0|-?[1-9][0-9]*)$")


def canonical_integer(value: str) -> int:
    if not isinstance(value, str) or DECIMAL.fullmatch(value) is None:
        raise ValueError("noncanonical signed-decimal coordinate")
    return int(value)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def load_source(sources_root: Path):
    manifest = json.loads(LOCK.read_text(encoding="utf-8"))
    if manifest["schema"] != "PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1" or manifest["main_changes_permitted"]:
        raise ValueError("invalid or unsafe source lock")
    engine = next(e for e in manifest["engines"] if e["id"] == "REF-41")
    if engine["language"] != "Python" or len(engine["sources"]) != 1:
        raise ValueError("unexpected Python source closure")
    item = engine["sources"][0]
    source = sources_root / "Python-Turkce" / engine["commit"] / item["path"]
    data = source.read_bytes()
    if (len(data), sha(data), blob(data)) != (item["bytes"], item["sha256"], item["git_blob_sha1"]):
        raise ValueError("pinned Python source identity mismatch")
    sys.dont_write_bytecode = True
    name = "_locked_pastafarian_pilot_python"
    module_spec = importlib.util.spec_from_file_location(name, source)
    if module_spec is None or module_spec.loader is None:
        raise ValueError("cannot load pinned Python source")
    module = importlib.util.module_from_spec(module_spec)
    sys.modules[name] = module
    module_spec.loader.exec_module(module)
    if not callable(getattr(module.NormativeCalendar, "calendar_date_ids", None)):
        raise ValueError("native Python entrypoint missing")
    cutlets = module.FROZEN_CUTLET_NAMES
    months = module.FROZEN_MONTH_NAMES
    if len(cutlets) != 17 or len(months) != 47 or len(set(cutlets)) != 17 or len(set(months)) != 47:
        raise ValueError("native names catalog invalid")
    return module, engine, item


def produce(cal, module, c: int, t: int):
    ids = cal.calendar_date_ids(c, t)  # The only date computation: original pinned engine.
    values = (ids.year_number, ids.cutlet_name_index, ids.day_in_cutlet,
              ids.month_name_index, ids.day_in_month)
    if any(type(x) is not int for x in values):
        raise ValueError("native returned non-integer fields")
    year, ci, cd, mi, md = values
    if not (1 <= ci <= 17 and 1 <= mi <= 47 and cd > 0 and md > 0):
        raise ValueError("native returned invalid indices or ordinal")
    cutlet, month = module.FROZEN_CUTLET_NAMES[ci - 1], module.FROZEN_MONTH_NAMES[mi - 1]
    raw = {
        "calculation_day": str(c), "target_day": str(t),
        "native_date_ids": {"year_number": str(year), "cutlet_name_index": ci,
                            "day_in_cutlet": cd, "month_name_index": mi,
                            "day_in_month": md},
        "native_names": {"cutlet": cutlet, "month": month},
    }
    raw_line = (json.dumps(raw, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()
    norm = {
        "calculation_day": str(c), "target_day": str(t), "year": str(year),
        "cutlet_index": ci, "day_in_cutlet": cd, "month_index": mi,
        "day_in_month": md, "cutlet_name_raw": cutlet, "month_name_raw": month,
        "source_raw_sha256": sha(raw_line),
    }
    norm_line = (json.dumps(norm, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()
    return raw_line, norm_line


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--sources-root", type=Path, required=True)
    p.add_argument("--check-only", action="store_true")
    p.add_argument("--calculation-day")
    p.add_argument("--first-target-day")
    p.add_argument("--last-target-day")
    p.add_argument("--raw-out", type=Path)
    p.add_argument("--normalized-out", type=Path)
    p.add_argument("--receipt-out", type=Path)
    p.add_argument("--allow-whole-year", action="store_true")
    p.add_argument("--boundary-evidence-sha256")
    a = p.parse_args()
    module, engine, source = load_source(a.sources_root.resolve())
    if a.check_only:
        print(json.dumps({"status": "SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY",
                          "engine": engine["id"], "sha256": source["sha256"],
                          "converter_calls": 0}, sort_keys=True))
        return 0
    if os.environ.get("PASTAFARI_SOAK_RESOURCE_ADMITTED") != "1":
        raise RuntimeError("Windows resource admission not confirmed by scheduler")
    c = canonical_integer(a.calculation_day)
    first, last = canonical_integer(a.first_target_day), canonical_integer(a.last_target_day)
    if first > last:
        raise ValueError("inverted target range")
    if first != last and not (a.allow_whole_year and
           isinstance(a.boundary_evidence_sha256, str) and
           re.fullmatch(r"[0-9a-f]{64}", a.boundary_evidence_sha256)):
        raise ValueError("multi-day stream requires independently pinned boundary evidence")
    if first != last and last - first + 1 > 5778:
        raise ValueError("year exceeds normative upper bound")
    outputs = [a.raw_out, a.normalized_out, a.receipt_out]
    if any(x is None for x in outputs) or len({x.resolve() for x in outputs}) != 3:
        raise ValueError("three unique output files required")
    if any(x.exists() for x in outputs):
        raise FileExistsError("output file exists; never overwrite native evidence")
    cal = module.NormativeCalendar()
    rh, nh = hashlib.sha256(), hashlib.sha256()
    count = 0
    # Exclusive create on every output. A failure never turns partial results into PASS.
    with a.raw_out.open("xb") as raw_file, a.normalized_out.open("xb") as norm_file:
        for t in range(first, last + 1):
            raw_line, norm_line = produce(cal, module, c, t)
            raw_file.write(raw_line)
            norm_file.write(norm_line)
            rh.update(raw_line)
            nh.update(norm_line)
            count += 1
            raw_file.flush()
            norm_file.flush()
            print(f"PILOT_NATIVE_DAY_WRITTEN engine=REF-41 day={t} rows={count}", flush=True)
        os.fsync(raw_file.fileno())
        os.fsync(norm_file.fileno())
    receipt = {
        "status": "NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED",
        "engine": engine["id"], "source_commit": engine["commit"],
        "source_sha256": source["sha256"], "calculation_day": str(c),
        "first_target_day": str(first), "last_target_day": str(last),
        "rows": count, "raw_stream_sha256": rh.hexdigest(),
        "normalized_stream_sha256": nh.hexdigest(),
        "boundary_evidence_sha256": a.boundary_evidence_sha256,
        "verified_comparisons_completed": 0,
    }
    with a.receipt_out.open("x", encoding="utf-8", newline="\n") as f:
        json.dump(receipt, f, ensure_ascii=False, sort_keys=True, indent=2)
        f.write("\n")
    print(json.dumps(receipt, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
