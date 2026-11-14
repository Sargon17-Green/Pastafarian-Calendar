#!/usr/bin/env python3
"""EXPERIMENTAL annual structure reuse over a pinned original Python reference.

Not an independent engine and not a full-year comparison. Builds the native
year/structure ONCE; expands the native structure into all year-day tuples;
compares a bounded deterministic sample to the original, unchanged
NormativeCalendar.calendar_date_ids(c,t) entry point. Never labels sampled
equivalence as a full-year canonical certification.
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
import time

ORIGINAL_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
ORIGINAL_SHA256 = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
HEX64 = re.compile(r"^[a-f0-9]{64}$")
CANDIDATE_FIELDS = (
    "calculation_day", "year", "open_gate_index", "close_gate_index",
    "open_gate_day", "close_gate_day", "first_target_day", "last_target_day",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def exact_json(data: bytes):
    def no_duplicates(pairs):
        out = {}
        for name, val in pairs:
            if name in out:
                raise ValueError("duplicate JSON key: " + name)
            out[name] = val
        return out
    return json.loads(data, object_pairs_hook=no_duplicates)


def check_candidate(file: Path):
    candidate = exact_json(file.read_bytes())
    if (candidate.get("schema") != "PASTAFARI_SOAK_THREE_NATIVE_YEAR5000_BOUNDARY_CANDIDATE/1"
            or candidate.get("status") != "THREE_NATIVE_YEAR5000_CANDIDATES_AGREE_NOT_CERTIFIED"
            or candidate.get("source_independence_certified") is not False
            or candidate.get("independent_canonical_oracle_certified") is not False
            or candidate.get("comparison_of_all_year_days_completed") is not False
            or candidate.get("validated_entire_year_count") != 0):
        raise ValueError("candidate is not the uncertified three-source boundary witness")
    canonical = (json.dumps(
        {k: candidate[k] for k in CANDIDATE_FIELDS},
        sort_keys=True, separators=(",", ":"),
    ) + "\n").encode("utf-8")
    if (sha256(canonical) != candidate["candidate_2_source_sha256"]
            or sha256(canonical) != "b464d81b2d02cf6270092ee887f4e0f6d3668b0de67a64c4423e358984cfd276"):
        raise ValueError("candidate year boundary digest mismatch")
    c = int(candidate["calculation_day"])
    first = int(candidate["first_target_day"])
    last = int(candidate["last_target_day"])
    if (c != -15055671 or candidate["year"] != "5000"
            or first != -15057702 or last != -15053459 or last - first + 1 != 4244):
        raise ValueError("unexpected year geometry; refusing to extrapolate")
    return candidate, c, first, last


def original_module(source: Path):
    content = source.read_bytes()
    if sha256(content) != ORIGINAL_SHA256:
        raise ValueError("original reference SHA-256 changed")
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("_pinned_python_annual_reuse", source)
    if spec is None or spec.loader is None:
        raise ValueError("cannot import original Python source")
    obj = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = obj
    spec.loader.exec_module(obj)
    return obj


def native_tuple(date) -> tuple[int, int, int, int, int]:
    fields = (date.year_number, date.cutlet_name_index, date.day_in_cutlet,
              date.month_name_index, date.day_in_month)
    if any(type(x) is not int for x in fields):
        raise ValueError("non-integer native date ID")
    return fields


def expand_structure(year, structure):
    """Only rearrange a pinned original YearStructure; no new calendar decisions."""
    first = year.open_gate_day + 1
    last = year.close_gate_day
    length = last - first + 1
    if not 252 <= length <= 5778:
        raise ValueError("out-of-range year span")
    if (len(structure.month_weaving) != length
            or len(structure.month_name_indices) != structure.month_count
            or len(structure.month_lengths) != structure.month_count
            or len(structure.cutlets) != structure.cutlet_count
            or sum(structure.month_lengths) != length):
        raise ValueError("inconsistent original year structure")
    if any(type(x) is not int for x in structure.month_weaving):
        raise ValueError("noninteger month identity")
    if any(not 1 <= x <= structure.month_count for x in structure.month_weaving):
        raise ValueError("invalid month identity in native weaving")
    counts = [0] * structure.month_count
    cutlet_index = 0
    rows = []
    for offset, month_id in enumerate(structure.month_weaving):
        t = first + offset
        while cutlet_index < len(structure.cutlets) and t > structure.cutlets[cutlet_index].last_day:
            cutlet_index += 1
        if cutlet_index >= len(structure.cutlets):
            raise ValueError("uncovered target day in native cutlets")
        cutlet = structure.cutlets[cutlet_index]
        if t < cutlet.first_day:
            raise ValueError("gap in original cutlet interval")
        counts[month_id - 1] += 1
        out = (year.number, cutlet.name_index, t - cutlet.first_day + 1,
               structure.month_name_indices[month_id - 1], counts[month_id - 1])
        if any(type(x) is not int or x <= 0 for x in out):
            raise ValueError("invalid derived native indices")
        rows.append(out)
    if counts != list(structure.month_lengths):
        raise ValueError("original month weaving counts differ from native lengths")
    if structure.cutlets[0].first_day != first or structure.cutlets[-1].last_day != last:
        raise ValueError("cutlets do not cover whole year endpoints")
    for a, b in zip(structure.cutlets, structure.cutlets[1:]):
        if b.first_day != a.last_day + 1:
            raise ValueError("noncontiguous original cutlet intervals")
    return rows


def sample_targets(c: int, first: int, last: int, structure, cap: int):
    if cap < 9:
        raise ValueError("at least 9 original-entrypoint checks required")
    length = last - first + 1
    required = [
        first, first + 1, first + 2, last - 2, last - 1, last,
        c - 1, c, c + 1,
    ]
    if any(not first <= x <= last for x in required):
        raise ValueError("the foundation year lacks required witness days")
    anchors = [
        first + length // 4, first + length // 2, first + 3 * length // 4,
    ]
    for cutlet in structure.cutlets:
        anchors.extend([cutlet.first_day, cutlet.last_day])
    observed = set()
    for idx, month in enumerate(structure.month_weaving):
        if month not in observed:
            observed.add(month)
            anchors.append(first + idx)
    targets = list(dict.fromkeys(required))
    for x in anchors:
        if len(targets) >= cap:
            break
        if first <= x <= last and x not in targets:
            targets.append(x)
    if len(targets) != cap:
        raise ValueError("insufficient unique samples")
    return targets


def write_evidence(out: Path, c: int, first: int, rows, compared, candidate):
    out.mkdir(parents=True, exist_ok=False)
    raw_path = out / "derived_python_year5000_all_days.jsonl"
    row_sha = hashlib.sha256()
    with raw_path.open("xb") as dest:
        for i, fields in enumerate(rows):
            line = (json.dumps({
                "calculation_day": str(c), "target_day": str(first + i),
                "native_structure_derived_fields": [str(x) for x in fields],
            }, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")
            dest.write(line)
            row_sha.update(line)
        dest.flush()
        os.fsync(dest.fileno())
    receipt = {
        "schema": "PASTAFARI_DERIVED_ANNUAL_PYTHON_NATIVE_STRUCTURE_V025/1",
        "status": "DERIVED_YEAR_TRANSCRIPT_SAMPLED_NATIVE_MATCH_NOT_CERTIFIED",
        "original_source_commit": ORIGINAL_COMMIT,
        "original_source_sha256": ORIGINAL_SHA256,
        "original_native_entrypoint": "NormativeCalendar.calendar_date_ids(c,t)",
        "derived_structure_entrypoints": [
            "NormativeCalendar.year5000(c)", "NormativeCalendar.build_year_structure(c,year)",
        ],
        "calculation_day": str(c),
        "year": candidate["year"],
        "first_target_day": str(first),
        "last_target_day": str(first + len(rows) - 1),
        "derived_rows": len(rows),
        "derived_stream_sha256": row_sha.hexdigest(),
        "native_original_sample_count": len(compared),
        "native_original_compared_targets": [str(x) for x in compared],
        "first_sample_mismatch": None,
        "all_year_days_compared_to_original": False,
        "independent_calendar_oracle_certified": False,
        "independent_engine_count_added": 0,
        "verified_full_year_comparisons": 0,
        "soak_started": False,
        "source_rewritten": False,
        "derived_python_compared_as_independent": False,
        "candidate_boundary_sha256": candidate["candidate_2_source_sha256"],
    }
    with (out / "derivation_receipt.json").open("x", encoding="utf-8", newline="\n") as f:
        json.dump(receipt, f, sort_keys=True, indent=2)
        f.write("\n")
    return receipt


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--original-python", type=Path, required=True)
    p.add_argument("--boundary-candidate", type=Path, required=True)
    p.add_argument("--output-dir", type=Path, required=True)
    p.add_argument("--sample-cap", type=int, default=14)
    a = p.parse_args()
    if not 9 <= a.sample_cap <= 20:
        raise ValueError("native sample cap must be 9..20")
    if a.output_dir.exists():
        raise FileExistsError("never overwrite output directory")
    candidate, c, first, last = check_candidate(a.boundary_candidate)
    module = original_module(a.original_python.resolve())
    started = time.monotonic()
    original_cal = module.NormativeCalendar()
    year = original_cal.year5000(c)
    observed_bounds = (year.number, year.open_gate_index, year.close_gate_index,
                       year.open_gate_day, year.close_gate_day)
    expected_bounds = tuple(int(candidate[k]) for k in (
        "year", "open_gate_index", "close_gate_index", "open_gate_day", "close_gate_day",
    ))
    if observed_bounds != expected_bounds:
        raise ValueError("new native year5000 source differs from pinned 3-source candidate")
    structure = original_cal.build_year_structure(c, year)
    rows = expand_structure(year, structure)
    if len(rows) != last - first + 1:
        raise ValueError("derived transcript length mismatch")
    t_struct = time.monotonic() - started
    targets = sample_targets(c, first, last, structure, a.sample_cap)
    comparisons = []
    for t in targets:
        direct = native_tuple(module.NormativeCalendar().calendar_date_ids(c, t))
        derived = rows[t - first]
        if direct != derived:
            # Fail immediately; never emit any candidate PASS transcript.
            raise AssertionError(
                f"FIRST_MISMATCH_STOP t={t} original={direct} derived={derived}"
            )
        comparisons.append(t)
        print(f"ANNUAL_REUSE_ORIGINAL_SAMPLE_PASS t={t} count={len(comparisons)}", flush=True)
    receipt = write_evidence(a.output_dir, c, first, rows, comparisons, candidate)
    receipt["elapsed_structure_seconds"] = round(t_struct, 4)
    receipt["elapsed_total_seconds"] = round(time.monotonic() - started, 4)
    # The stored receipt intentionally excludes mutable clock metrics; keep
    # deterministic raw and signed identity in it.
    print("ANNUAL_REUSE_V025_VERDICT=" + json.dumps(receipt, sort_keys=True), flush=True)


if __name__ == "__main__":
    main()
