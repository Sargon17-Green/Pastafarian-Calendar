#!/usr/bin/env python3
"""Capture the corrected Fortran Foundation-Day structure without treating it as an oracle."""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import subprocess
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SCROLL_SNAPSHOT = "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md"
SCROLL_SNAPSHOT_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7"


def one(lines: list[str], name: str) -> str:
    prefix = name + "="
    matches = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    if len(matches) != 1:
        raise AssertionError("{} marker count is {}".format(name, len(matches)))
    return matches[0]


def ints(value: str) -> list[int]:
    if not value:
        return []
    return [int(part) for part in value.split(",")]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fortran-exe", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    completed = subprocess.run(
        [str(args.fortran_exe.resolve())],
        check=True,
        capture_output=True,
        text=True,
        timeout=180,
    )
    lines = completed.stdout.splitlines()
    if "STAGE01_FOUNDATION_CANDIDATE_INVARIANTS=PASS" not in lines:
        raise AssertionError("Fortran candidate probe omitted invariant PASS")
    if "STAGE01_FOUNDATION_CANDIDATE_ONLY_NOT_CANONICAL" not in lines:
        raise AssertionError("Fortran candidate probe omitted non-canonical marker")

    calculation_day = one(lines, "STAGE01_FOUNDATION_CANDIDATE_CALCULATION_DAY")
    target_day = one(lines, "STAGE01_FOUNDATION_CANDIDATE_TARGET_DAY")
    if calculation_day != target_day:
        raise AssertionError("candidate must use Foundation Day for both input dates")
    fields = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_FIELDS"))
    if len(fields) != 5:
        raise AssertionError("Foundation date did not return exactly five fields")
    cutlet_position = int(one(lines, "STAGE01_FOUNDATION_CANDIDATE_CUTLET_POSITION"))
    month_id = int(one(lines, "STAGE01_FOUNDATION_CANDIDATE_MONTH_ID"))
    year_number = int(one(lines, "STAGE01_FOUNDATION_CANDIDATE_YEAR_NUMBER"))
    month_count = int(one(lines, "STAGE01_FOUNDATION_CANDIDATE_MONTH_COUNT"))
    day_count = int(one(lines, "STAGE01_FOUNDATION_CANDIDATE_DAY_COUNT"))
    gate_indices = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_GATE_INDICES"))
    gate_days = one(lines, "STAGE01_FOUNDATION_CANDIDATE_GATE_DAYS").split(",")
    cutlet_partition = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_CUTLET_PARTITION"))
    cutlet_names = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_CUTLET_NAME_INDICES"))
    cutlet_first_days = [int(x) for x in one(lines, "STAGE01_FOUNDATION_CANDIDATE_CUTLET_FIRST_DAYS").split(",")]
    cutlet_last_days = [int(x) for x in one(lines, "STAGE01_FOUNDATION_CANDIDATE_CUTLET_LAST_DAYS").split(",")]
    month_lengths = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_MONTH_LENGTHS"))
    month_names = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_MONTH_NAME_INDICES"))
    month_weaving = ints(one(lines, "STAGE01_FOUNDATION_CANDIDATE_MONTH_WEAVING"))

    if fields[0] != year_number or year_number != 5000:
        raise AssertionError("Foundation candidate fields/year metadata disagree")
    if len(gate_indices) != 2 or len(gate_days) != 2 or gate_indices[0] >= gate_indices[1]:
        raise AssertionError("invalid gate metadata")
    if len(cutlet_partition) == 0 or len(cutlet_names) != len(cutlet_partition):
        raise AssertionError("cutlet dimensions disagree")
    if len(cutlet_first_days) != len(cutlet_partition) or len(cutlet_last_days) != len(cutlet_partition):
        raise AssertionError("cutlet day dimensions disagree")
    if sum(cutlet_partition) != gate_indices[1] - gate_indices[0]:
        raise AssertionError("cutlet partition does not span gate interval")
    if any(last < first or last - first + 1 != length for first, last, length in zip(cutlet_first_days, cutlet_last_days, cutlet_partition)):
        raise AssertionError("cutlet day boundaries differ from partition")
    if len(month_lengths) != month_count or len(month_names) != month_count:
        raise AssertionError("month dimensions disagree")
    if day_count != sum(month_lengths) or day_count != len(month_weaving):
        raise AssertionError("month lengths do not cover the weaving")
    if any(length < 4 or length > 123 for length in month_lengths):
        raise AssertionError("month length outside 4..123")
    if len(set(cutlet_names)) != len(cutlet_names) or any(not 1 <= x <= 17 for x in cutlet_names):
        raise AssertionError("invalid or repeated cutlet names")
    if len(set(month_names)) != len(month_names) or any(not 1 <= x <= 47 for x in month_names):
        raise AssertionError("invalid or repeated month names")
    if not 1 <= cutlet_position <= len(cutlet_partition):
        raise AssertionError("containing cutlet position outside partition")
    if fields[1] != cutlet_names[cutlet_position - 1]:
        raise AssertionError("projected cutlet canonical name index mismatch")
    if not 1 <= fields[2] <= cutlet_partition[cutlet_position - 1]:
        raise AssertionError("projected day outside containing cutlet")
    if not 1 <= month_id <= month_count:
        raise AssertionError("containing month ID outside year")
    if fields[3] != month_names[month_id - 1]:
        raise AssertionError("projected month canonical name index mismatch")
    if not 1 <= fields[4] <= month_lengths[month_id - 1]:
        raise AssertionError("projected day outside containing month")
    if any(not 1 <= month_id_value <= month_count for month_id_value in month_weaving):
        raise AssertionError("month weaving contains an invalid month ID")

    counts = collections.Counter(month_weaving)
    if [counts[i] for i in range(1, month_count + 1)] != month_lengths:
        raise AssertionError("weaving frequencies differ from month lengths")
    first_positions = []
    last_positions = []
    for month_id_value in range(1, month_count + 1):
        positions = [i for i, value in enumerate(month_weaving, start=1) if value == month_id_value]
        if not positions:
            raise AssertionError("month ID is absent from weaving")
        first_positions.append(positions[0])
        last_positions.append(positions[-1])
    if any(a >= b for a, b in zip(first_positions, first_positions[1:])):
        raise AssertionError("first occurrence order is not increasing")
    if any(a >= b for a, b in zip(last_positions, last_positions[1:])):
        raise AssertionError("last occurrence order is not increasing")

    weaving_bytes = ",".join(str(x) for x in month_weaving).encode("ascii")
    report = {
        "project_id": PROJECT_ID,
        "canonical_source_snapshot": SCROLL_SNAPSHOT,
        "canonical_source_snapshot_sha256": SCROLL_SNAPSHOT_SHA256,
        "candidate_only": True,
        "full_stage1_accepted": False,
        "calculation_day": calculation_day,
        "target_day": target_day,
        "date_fields": {
            "year_number": fields[0],
            "cutlet_canonical_index": fields[1],
            "day_in_cutlet": fields[2],
            "month_canonical_index": fields[3],
            "day_in_month": fields[4],
        },
        "cutlet_position": cutlet_position,
        "month_id": month_id,
        "year": {
            "number": year_number,
            "month_count": month_count,
            "day_count": day_count,
            "open_gate_index": gate_indices[0],
            "close_gate_index": gate_indices[1],
            "open_gate_day": gate_days[0],
            "close_gate_day": gate_days[1],
        },
        "cutlets": {
            "partition": cutlet_partition,
            "name_indices": cutlet_names,
            "first_days": cutlet_first_days,
            "last_days": cutlet_last_days,
        },
        "months": {
            "lengths": month_lengths,
            "name_indices": month_names,
            "weaving_sha256": hashlib.sha256(weaving_bytes).hexdigest(),
            "weaving": month_weaving,
        },
        "fortran_probe_stdout_sha256": hashlib.sha256(completed.stdout.encode("utf-8")).hexdigest(),
        "invariants": {
            "month_frequency": True,
            "first_occurrence_order": True,
            "last_occurrence_order": True,
            "cutlet_partition_span": True,
            "projected_date_bounds": True,
        },
    }
    encoded = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(encoded, encoding="utf-8")
    print("STAGE01_FOUNDATION_CANDIDATE_CAPTURE=PASS")
    print("STAGE01_FOUNDATION_CANDIDATE_YEAR=5000 MONTHS={} DAYS={}".format(month_count, day_count))
    print("STAGE01_FOUNDATION_CANDIDATE_FIELDS={}".format(",".join(str(x) for x in fields)))
    print("STAGE01_FOUNDATION_CANDIDATE_WEAVING_SHA256=" + report["months"]["weaving_sha256"])
    print("STAGE01_FOUNDATION_CANDIDATE_ONLY_NOT_CANONICAL")


if __name__ == "__main__":
    main()
