#!/usr/bin/env python3
"""Independent Slice25 calendar-date ordinal oracle and bounded self-tests.

The oracle consumes PG17-produced year_structure records and the read-only
canonical Tamil source map. It does not call SQL, copy the normative function,
or generate any expected values from calendar_date.
"""
from __future__ import annotations

import argparse
import json
from itertools import combinations, product
from pathlib import Path


def read_jsonl(path: Path) -> list[dict]:
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    if not rows:
        raise ValueError(f"empty JSONL input: {path}")
    return rows


def cutlet_interval(target_day: int, gate_days: list[int]):
    matches = []
    for cutlet_index in range(1, len(gate_days)):
        previous_gate_day = gate_days[cutlet_index - 1]
        current_gate_day = gate_days[cutlet_index]
        if previous_gate_day < target_day <= current_gate_day:
            matches.append((cutlet_index - 1, previous_gate_day + 1, current_gate_day))
    if len(matches) > 1:
        raise AssertionError("cutlet interval is not unique")
    return matches[0] if matches else None


def month_occurrence_ordinal(weaving: list[int], zero_based_offset: int) -> tuple[int, int]:
    if not 0 <= zero_based_offset < len(weaving):
        raise ValueError("month offset outside weaving")
    month_id = weaving[zero_based_offset]
    ordinal = sum(1 for value in weaving[:zero_based_offset + 1] if value == month_id)
    return month_id, ordinal


def validate_and_oracle(year_row: dict, case: dict, catalog: dict[tuple[str, int], str]) -> dict:
    year = year_row["year_data"]
    structure = year_row["year_structure"]
    if structure["year_data"] != year:
        raise AssertionError("year_structure.year_data differs from locked year record")

    year_number = int(year["year_number"])
    open_index = int(year["open_gate_index"])
    open_day = int(year["open_gate_day"])
    close_day = int(year["close_gate_day"])
    cutlet_partition = [int(x) for x in structure["cutlet_partition"]]
    cutlet_names = [int(x) for x in structure["cutlet_name_indices"]]
    month_lengths = [int(x) for x in structure["month_lengths"]]
    weaving = [int(x) for x in structure["month_weaving"]]
    month_names = [int(x) for x in structure["month_name_indices"]]
    cutlet_count = int(structure["cutlet_count"])
    month_count = int(structure["month_count"])

    if cutlet_count != len(cutlet_partition) or len(cutlet_names) != cutlet_count:
        raise AssertionError("cutlet array cardinality mismatch")
    if month_count != len(month_lengths) or len(month_names) != month_count:
        raise AssertionError("month array cardinality mismatch")
    if len(weaving) != close_day - open_day or sum(month_lengths) != len(weaving):
        raise AssertionError("month weaving length mismatch")

    prefix_gates = year_row["cutlet_prefix_gates"]
    expected_prefixes = [0]
    running = 0
    for part in cutlet_partition:
        if part <= 0:
            raise AssertionError("non-positive cutlet partition")
        running += part
        expected_prefixes.append(running)

    actual_prefixes = [int(row["prefix"]) for row in prefix_gates]
    actual_gate_indices = [int(row["gate_index"]) for row in prefix_gates]
    gate_days = [int(row["gate_day"]) for row in prefix_gates]
    if actual_prefixes != expected_prefixes:
        raise AssertionError("independently accumulated cutlet prefixes disagree")
    if actual_gate_indices != [open_index + p for p in expected_prefixes]:
        raise AssertionError("cutlet prefix gate indices disagree")
    if len(gate_days) != cutlet_count + 1 or gate_days[0] != open_day or gate_days[-1] != close_day:
        raise AssertionError("cutlet prefix gate endpoints disagree")
    if any(a >= b for a, b in zip(gate_days, gate_days[1:])):
        raise AssertionError("cutlet prefix gate days are not strictly increasing")

    target_day = int(case["target_day"])
    if int(case["calculation_day"]) != int(year_row["calculation_day"]):
        raise AssertionError("calculation day differs from source-locked year input")
    if not open_day < target_day <= close_day:
        raise AssertionError("target day is not reachable in its source-locked year")

    selected = cutlet_interval(target_day, gate_days)
    if selected is None:
        raise AssertionError("no cutlet contains reachable target")
    cutlet_index, first_day, last_day = selected
    if not 0 <= cutlet_index < cutlet_count:
        raise AssertionError("cutlet index outside structure")

    zero_based_offset = target_day - (open_day + 1)
    month_id, day_in_month = month_occurrence_ordinal(weaving, zero_based_offset)
    if not 1 <= month_id <= month_count:
        raise AssertionError("month id outside structure")
    if day_in_month > month_lengths[month_id - 1]:
        raise AssertionError("month ordinal exceeds declared month length")

    cutlet_name_index = cutlet_names[cutlet_index]
    month_name_index = month_names[month_id - 1]
    cutlet_name = catalog[("CUTLET", cutlet_name_index)]
    month_name = catalog[("MONTH", month_name_index)]

    purpose = case["purpose"]
    if purpose == "year_first" and target_day != open_day + 1:
        raise AssertionError("year_first provenance mismatch")
    if purpose == "year_first" and target_day - first_day + 1 != 1:
        raise AssertionError("first day is not cutlet day 1")
    if purpose == "year_last" and target_day != close_day:
        raise AssertionError("year_last provenance mismatch")
    if purpose == "cutlet_boundary":
        if target_day not in gate_days[1:-1] or target_day != last_day:
            raise AssertionError("cutlet boundary case is not the end of a cutlet")
    if purpose == "cutlet_boundary_minus":
        if target_day + 1 not in gate_days[1:-1] or target_day != last_day - 1:
            raise AssertionError("cutlet boundary -1 case is malformed")
    if purpose == "cutlet_boundary_plus":
        if target_day - 1 not in gate_days[1:-1] or target_day != first_day:
            raise AssertionError("cutlet boundary +1 case is malformed")
    if purpose == "month_first_occurrence":
        if month_id != int(case["focus_month_id"]) or day_in_month != 1:
            raise AssertionError("month first-occurrence case is malformed")
    if purpose == "month_repeated_occurrence":
        if month_id != int(case["focus_month_id"]) or day_in_month != 2:
            raise AssertionError("month repeated-occurrence case is malformed")

    return {
        "year_number": year_number,
        "cutlet_name": cutlet_name,
        "day_in_cutlet": target_day - first_day + 1,
        "month_name": month_name,
        "day_in_month": day_in_month,
    }


def all_compositions(total: int, parts: int):
    if parts == 1:
        yield (total,)
        return
    for cuts in combinations(range(1, total), parts - 1):
        points = (0,) + cuts + (total,)
        yield tuple(points[i + 1] - points[i] for i in range(parts))


def self_test() -> tuple[int, int]:
    composition_checks = 0
    for total in range(1, 11):
        for count in range(1, min(4, total) + 1):
            for parts in all_compositions(total, count):
                gates = [0]
                for ordinal, part in enumerate(parts, 1):
                    gates.append(gates[-1] + part * 2 + ordinal)
                for target in range(1, gates[-1] + 1):
                    if cutlet_interval(target, gates) is None:
                        raise AssertionError("synthetic day not covered by a cutlet")
                    composition_checks += 1
                if cutlet_interval(0, gates) is not None:
                    raise AssertionError("day before year was accepted")
                if cutlet_interval(gates[-1] + 1, gates) is not None:
                    raise AssertionError("day after year was accepted")
                for i in range(1, len(gates) - 1):
                    if cutlet_interval(gates[i], gates)[0] != i - 1:
                        raise AssertionError("boundary belongs to the preceding cutlet")
                    if cutlet_interval(gates[i] + 1, gates)[0] != i:
                        raise AssertionError("day after boundary belongs to next cutlet")

    month_checks = 0
    for month_count in range(1, 4):
        for length in range(1, 8):
            for weaving in product(range(1, month_count + 1), repeat=length):
                for offset in range(length):
                    month_id, ordinal = month_occurrence_ordinal(list(weaving), offset)
                    expected = sum(1 for value in weaving[:offset + 1] if value == month_id)
                    if ordinal != expected:
                        raise AssertionError("month occurrence ordinal mismatch")
                    month_checks += 1
    return composition_checks, month_checks


def run_oracle(year_file: Path, cases_file: Path, catalog_file: Path, output_file: Path) -> int:
    years = read_jsonl(year_file)
    cases = read_jsonl(cases_file)
    catalog_rows = read_jsonl(catalog_file)

    catalog: dict[tuple[str, int], str] = {}
    for row in catalog_rows:
        key = (str(row["category"]), int(row["canonical_index"]))
        if key in catalog:
            raise AssertionError(f"duplicate canonical catalog key: {key}")
        catalog[key] = str(row["source_text_tamil"])

    cutlet_keys = sorted(index for category, index in catalog if category == "CUTLET")
    month_keys = sorted(index for category, index in catalog if category == "MONTH")
    if cutlet_keys != list(range(1, 18)) or month_keys != list(range(1, 48)):
        raise AssertionError("canonical Tamil catalog is incomplete or non-contiguous")

    if len(years) != 1:
        raise AssertionError("each preflight artifact must contain exactly one year structure")
    year_row = years[0]
    if len(cases) not in (3, 5, 6):
        raise AssertionError(f"unexpected target case count: {len(cases)}")
    if any(case["year_id"] != year_row["year_id"] for case in cases):
        raise AssertionError("case/year provenance mismatch")

    outputs = []
    for case in cases:
        expected = validate_and_oracle(year_row, case, catalog)
        outputs.append({
            "case_id": case["case_id"],
            "year_id": case["year_id"],
            "calculation_day": int(case["calculation_day"]),
            "target_day": int(case["target_day"]),
            "purpose": case["purpose"],
            "focus_month_id": case.get("focus_month_id"),
            "expected": expected,
        })

    output_file.write_text(
        "".join(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n" for row in outputs),
        encoding="utf-8",
    )
    print(f"slice25_oracle_cases={len(outputs)} PASS")
    print(f"slice25_canonical_catalog={len(catalog)} PASS")
    print("slice25_oracle_provenance=PG17 year_structure + independent Python ordinal logic + read-only canonical source map")
    return len(outputs)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--year-file", type=Path)
    parser.add_argument("--cases-file", type=Path)
    parser.add_argument("--catalog-file", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        compositions, months = self_test()
        print(f"slice25_selftest_cutlet_days={compositions} PASS")
        print(f"slice25_selftest_month_positions={months} PASS")

    supplied = [args.year_file, args.cases_file, args.catalog_file, args.output]
    if any(value is not None for value in supplied):
        if not all(value is not None for value in supplied):
            parser.error("all four oracle file arguments are required together")
        run_oracle(args.year_file, args.cases_file, args.catalog_file, args.output)
    elif not args.self_test:
        parser.error("supply --self-test and/or all oracle file arguments")


if __name__ == "__main__":
    main()
