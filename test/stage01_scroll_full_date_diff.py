#!/usr/bin/env python3
"""Independent full-date Stage-1 oracle transcribed from the Hebrew Scroll.

This composes the independently transcribed day/sauce/gate, cutlet, month,
month-name and reverse-endpoint weaving components. It imports neither the
pinned cross-branch Python calendar nor candidate Fortran code. The Fortran
program is invoked only as the system under test.

The default differential is deliberately bounded to adjacent target days and
the same target under adjacent calculation-day contexts. It is QA evidence,
not full Stage-1 acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import resource
import subprocess
import sys
from functools import lru_cache
from pathlib import Path

from stage01_scroll_gate_independent import (
    MODULUS, SCROLL_NAME, SCROLL_SHA256, YEAR_MAX_DAYS,
    choose_index, day_number, eligible_year_span, gate_window, save,
)
from stage01_scroll_cutlets_independent import (
    CUTLET_NAMES, count_with_required_gate, permutation_count,
    unrank_name_indices, unrank_partition,
)
from stage01_scroll_months_independent import (
    admissible_month_counts, count_length_books, unrank_length_book,
)
from stage01_scroll_month_names_independent import (
    MONTH_NAMES, number_of_name_books, unrank_names,
)
from stage01_scroll_weaving_reverse_endpoint import (
    Budget, ResourceLimit, exact_unrank, future_factor,
    reverse_distributions, word_invariants,
)

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b"
FOUNDATION_DAY = -15055671
BOUNDARY_CASES = (
    ("target-minus-one", 0, -1),
    ("foundation-target", 0, 0),
    ("target-plus-one", 0, 1),
    ("same-target-calc-minus-one", -1, 0),
    ("same-target-calc-plus-one", 1, 0),
    ("previous-year-boundary-left", -1, -2033),
    ("previous-year-boundary-right", 1, -2031),
    ("next-year-boundary-left", -1, 2212),
    ("next-year-boundary-right", 1, 2214),
)
WIDE_CONTEXT_CASES = (
    ("wide-calc-minus-8192-target-minus-3192", -8192, -3192),
    ("wide-calc-plus-8192-target-plus-3192", 8192, 3192),
    ("wide-calc-plus-137-target-plus-137", 137, 137),
    ("wide-calc-minus-2048-target-zero", -2048, 0),
    ("wide-calc-plus-2048-target-zero", 2048, 0),
    ("wide-calc-plus-one-target-minus-2032", 1, -2032),
    ("wide-calc-minus-one-target-plus-2213", -1, 2213),
    ("wide-calc-minus-one-target-minus-2032", -1, -2032),
    ("wide-calc-plus-one-target-plus-2213", 1, 2213),
)
LEGACY_OFFSET_ZERO_CASES = (
    ("old-normative-minus-2032", 0, -2032),
    ("old-normative-minus-2031", 0, -2031),
    ("old-normative-minus-one", 0, -1),
    ("old-normative-foundation", 0, 0),
    ("old-normative-plus-one", 0, 1),
    ("old-normative-plus-2212", 0, 2212),
    ("old-normative-plus-2213", 0, 2213),
    ("old-expanded-minus-2169", 0, -2169),
    ("old-expanded-plus-271", 0, 271),
    ("old-expanded-plus-2350", 0, 2350),
)

_STRUCTURE_CACHE: dict[tuple[int, int, int, int], dict] = {}


@lru_cache(maxsize=8)
def gate_data(max_distance: int):
    pairs = tuple(gate_window(max_distance))
    by_index = {index: offset for index, offset in pairs}
    by_day = {offset: index for index, offset in pairs}
    if len(by_index) != len(pairs) or len(by_day) != len(pairs):
        raise AssertionError("gate sequence contains duplicate index or day")
    return pairs, by_index, by_day


def pairs_by_index(pairs):
    return {index: offset for index, offset in pairs}


def year5000(calculation_offset: int, pairs):
    """Table 18: enumerate every eligible pair and rank by (days, opening gate)."""
    candidates = []
    for position, (open_index, open_day) in enumerate(pairs):
        if open_day >= calculation_offset:
            break
        for close_index, close_day in pairs[position + 1:]:
            if close_day < calculation_offset:
                continue
            days = close_day - open_day
            if days > 5778:
                break
            intervals = close_index - open_index
            if eligible_year_span(days, intervals):
                candidates.append((days, open_day, open_index, close_index, close_day, intervals))
    candidates.sort(key=lambda item: (item[0], item[1]))
    if not candidates:
        raise ValueError("year-5000 candidate set is empty")
    days, _, open_index, close_index, close_day, intervals = candidates[
        choose_index(calculation_offset, calculation_offset, 1, 10, len(candidates))
    ]
    open_day = pairs_by_index(pairs)[open_index]
    if not (open_day < calculation_offset <= close_day):
        raise AssertionError("year-5000 selection violates open/close inequalities")
    return {
        "number": 5000, "open_index": open_index, "close_index": close_index,
        "open_day": open_day, "close_day": close_day, "days": days,
        "intervals": intervals, "candidate_count": len(candidates),
    }


def next_year(calculation_offset: int, known: dict, pairs):
    """Table 19: keep the opening gate, rank eligible later closing gates."""
    open_index, open_day = known["close_index"], known["close_day"]
    candidates = []
    for close_index, close_day in pairs:
        if close_index <= open_index:
            continue
        days = close_day - open_day
        if days > 5778:
            break
        intervals = close_index - open_index
        if eligible_year_span(days, intervals):
            candidates.append((days, close_index, close_day, intervals))
    candidates.sort(key=lambda item: item[0])  # stable gate order breaks ties
    if not candidates:
        raise ValueError("next-year candidate set is empty; gate window insufficient")
    days, close_index, close_day, intervals = candidates[
        choose_index(calculation_offset, open_day, 1, 11, len(candidates))
    ]
    return {
        "number": known["number"] + 1, "open_index": open_index,
        "close_index": close_index, "open_day": open_day,
        "close_day": close_day, "days": days, "intervals": intervals,
        "candidate_count": len(candidates),
    }


def previous_year(calculation_offset: int, known: dict, pairs):
    """Table 19: keep the closing gate, rank eligible earlier opening gates."""
    close_index, close_day = known["open_index"], known["open_day"]
    candidates = []
    for open_index, open_day in reversed(pairs):
        if open_index >= close_index:
            continue
        days = close_day - open_day
        if days > 5778:
            break
        intervals = close_index - open_index
        if eligible_year_span(days, intervals):
            candidates.append((days, open_index, open_day, intervals))
    candidates.sort(key=lambda item: item[0])  # stable reverse gate order breaks ties
    if not candidates:
        raise ValueError("previous-year candidate set is empty; gate window insufficient")
    days, open_index, open_day, intervals = candidates[
        choose_index(calculation_offset, close_day, 1, 12, len(candidates))
    ]
    return {
        "number": known["number"] - 1, "open_index": open_index,
        "close_index": close_index, "open_day": open_day,
        "close_day": close_day, "days": days, "intervals": intervals,
        "candidate_count": len(candidates),
    }


def find_year(calculation_offset: int, target_offset: int, pairs):
    year = year5000(calculation_offset, pairs)
    for _ in range(1000):
        if target_offset > year["close_day"]:
            year = next_year(calculation_offset, year, pairs)
            continue
        if target_offset <= year["open_day"]:
            year = previous_year(calculation_offset, year, pairs)
            continue
        if year["open_day"] < target_offset <= year["close_day"]:
            return year
        raise AssertionError("year walk failed its inclusive endpoint invariant")
    raise ValueError("year walk exceeded the finite guard")


def build_year_structure(calculation_offset, year, by_index, by_day, max_seconds, max_states):
    """Tables 20–22 plus complete table-21 weaving, from Scroll-derived oracles."""
    cache_key = (calculation_offset, year["number"], year["open_index"], year["close_index"])
    if cache_key in _STRUCTURE_CACHE:
        return _STRUCTURE_CACHE[cache_key]
    first_day = year["open_day"] + 1
    gate_steps = year["close_index"] - year["open_index"]
    if any(i not in by_index for i in range(year["open_index"], year["close_index"] + 1)):
        raise ValueError("gate window does not contain every gate in selected year")

    cutlet_counts = tuple(range(6, min(17, gate_steps) + 1))
    if not cutlet_counts:
        raise ValueError("selected year has no legal cutlet count")
    cutlet_count = cutlet_counts[choose_index(calculation_offset, first_day, 2, 20, len(cutlet_counts))]
    calculation_gate = by_day.get(calculation_offset)
    required_boundary = 0
    if calculation_gate is not None and year["open_index"] < calculation_gate < year["close_index"]:
        required_boundary = calculation_gate - year["open_index"]
    partition_count = count_with_required_gate(gate_steps, cutlet_count, required_boundary)
    if partition_count <= 0:
        raise AssertionError("selected cutlet partition space is empty")
    partition_rank = choose_index(calculation_offset, first_day, 2, 21, partition_count)
    partition = unrank_partition(gate_steps, cutlet_count, required_boundary, partition_rank)

    cutlet_name_count = permutation_count(len(CUTLET_NAMES), cutlet_count)
    cutlet_name_rank = choose_index(calculation_offset, first_day, 5, 22, cutlet_name_count)
    cutlet_name_indices = unrank_name_indices(len(CUTLET_NAMES), cutlet_count, cutlet_name_rank)
    cutlets = []
    cursor = year["open_index"]
    for length, name_index_zero in zip(partition, cutlet_name_indices):
        next_gate = cursor + length
        cutlets.append({
            "name_index": name_index_zero + 1,
            "first_day": by_index[cursor] + 1,
            "last_day": by_index[next_gate],
            "opening_gate_index": cursor,
            "closing_gate_index": next_gate,
            "gate_steps": length,
        })
        cursor = next_gate
    if cursor != year["close_index"]:
        raise AssertionError("cutlet partition does not end at year closing gate")

    month_counts = admissible_month_counts(year["days"])
    if not month_counts:
        raise AssertionError("selected year has no admissible month count")
    month_count = month_counts[choose_index(calculation_offset, first_day, 3, 30, len(month_counts))]
    length_count = count_length_books(year["days"], month_count)
    if length_count <= 0:
        raise AssertionError("selected month count has no legal length books")
    length_rank = choose_index(calculation_offset, first_day, 3, 31, length_count)
    month_lengths = unrank_length_book(year["days"], month_count, length_rank)

    budget = Budget(seconds=max_seconds, entries=max_states)
    distributions = reverse_distributions(month_lengths, budget)
    weaving_count = future_factor(distributions[0], 0)
    if weaving_count <= 0:
        raise AssertionError("selected month lengths have no legal weaving")
    weaving_rank = choose_index(calculation_offset, first_day, 4, 32, weaving_count)
    unranked_count, weaving, cache_entries = exact_unrank(month_lengths, weaving_rank, budget)
    if unranked_count != weaving_count:
        raise AssertionError("weaving count changed between count and unrank")
    word_invariants(month_lengths, weaving)

    month_name_count = number_of_name_books(len(MONTH_NAMES), month_count)
    month_name_rank = choose_index(calculation_offset, first_day, 5, 33, month_name_count)
    month_name_indices = unrank_names(len(MONTH_NAMES), month_count, month_name_rank)
    result = {
        "first_day": first_day, "year_days": year["days"], "gate_steps": gate_steps,
        "cutlet_count": cutlet_count, "cutlet_partition": list(partition),
        "cutlets": cutlets, "month_count": month_count,
        "month_lengths": list(month_lengths), "weaving": tuple(weaving),
        "weaving_count": weaving_count, "weaving_rank": weaving_rank,
        "weaving_cache_entries": cache_entries,
        "month_name_indices": tuple(month_name_indices),
    }
    _STRUCTURE_CACHE[cache_key] = result
    return result


def full_date(calculation_offset, target_offset, max_seconds, max_states):
    max_distance = max(abs(calculation_offset), abs(target_offset)) + 2 * 5778 + 963
    pairs, by_index, by_day = gate_data(max_distance)
    year = find_year(calculation_offset, target_offset, pairs)
    structure = build_year_structure(calculation_offset, year, by_index, by_day, max_seconds, max_states)
    target_index = target_offset - structure["first_day"]
    if not 0 <= target_index < structure["year_days"]:
        raise AssertionError("target offset is outside selected year")
    cutlets = [x for x in structure["cutlets"] if x["first_day"] <= target_offset <= x["last_day"]]
    if len(cutlets) != 1:
        raise AssertionError("target day belongs to zero or multiple cutlets")
    cutlet = cutlets[0]
    day_in_cutlet = target_offset - cutlet["first_day"] + 1
    month_id = structure["weaving"][target_index]
    month_name_index = structure["month_name_indices"][month_id - 1]
    day_in_month = sum(1 for value in structure["weaving"][:target_index + 1] if value == month_id)
    fields = (year["number"], cutlet["name_index"], day_in_cutlet, month_name_index, day_in_month)
    return {
        "fields": fields,
        "year": {
            "number": year["number"], "open_gate_index": year["open_index"],
            "close_gate_index": year["close_index"], "open_day_offset": year["open_day"],
            "close_day_offset": year["close_day"], "day_count": year["days"],
            "gate_intervals": year["intervals"],
        },
        "structure": {
            "cutlet_count": structure["cutlet_count"],
            "cutlet_partition": structure["cutlet_partition"],
            "month_count": structure["month_count"],
            "month_lengths": structure["month_lengths"],
            "weaving_length": len(structure["weaving"]),
            "weaving_sha256": hashlib.sha256(",".join(map(str, structure["weaving"])).encode("ascii")).hexdigest(),
            "weaving_count_digits": len(str(structure["weaving_count"])),
            "weaving_rank_digits": len(str(structure["weaving_rank"])),
        },
    }


def memory_limiter(memory_mib):
    def apply_limit():
        size = memory_mib * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (size, size))
    return apply_limit


def parse_one(stdout, prefix):
    values = [line[len(prefix):] for line in stdout.splitlines() if line.startswith(prefix)]
    if len(values) != 1:
        raise ValueError("missing or duplicate Fortran output record: " + prefix)
    return values[0]


def run_fortran(executable, calculation_offset, target_offset, timeout_seconds):
    process = subprocess.run(
        [str(executable.resolve()), str(calculation_offset), str(target_offset)],
        capture_output=True, text=True, timeout=timeout_seconds, check=False,
        preexec_fn=memory_limiter(1024),
    )
    if process.returncode != 0:
        raise RuntimeError(f"Fortran exit={process.returncode}; stdout={process.stdout[-1000:]}; stderr={process.stderr[-1000:]}")
    if int(parse_one(process.stdout, "STAGE01_SCROLL_DATE_CALC_OFFSET=")) != calculation_offset:
        raise ValueError("Fortran calculation offset framing mismatch")
    if int(parse_one(process.stdout, "STAGE01_SCROLL_DATE_TARGET_OFFSET=")) != target_offset:
        raise ValueError("Fortran target offset framing mismatch")
    raw = parse_one(process.stdout, "STAGE01_SCROLL_DATE_FIELDS=").split(",")
    if len(raw) != 5:
        raise ValueError("Fortran did not return exactly five date fields")
    return tuple(int(value) for value in raw)


def self_test():
    checks = 0
    def verify(condition, message):
        nonlocal checks
        if not condition:
            raise AssertionError(message)
        checks += 1
    verify(len(SOURCE_SHA256) == 64, "source SHA-256 length")
    verify(SOURCE_SHA256 == SCROLL_SHA256, "shared source pin")
    verify([day_number(i) for i in range(-3, 4)] == [6, 4, 2, 1, 3, 5, 7], "day-number mapping")
    verify(save(0) == MODULUS and save(MODULUS + 1) == 1 and save(2 * MODULUS) == MODULUS, "one-based SAVE")
    pairs, by_index, by_day = gate_data(2 * 5778 + 963)
    verify(by_index[0] == 0 and by_day[0] == 0, "Foundation gate identity")
    verify(all(42 <= by_index[i] - by_index[i - 1] <= 963 for i in range(min(by_index)+1, max(by_index)+1)), "gate gaps")
    selected = year5000(0, pairs)
    reference = __import__("stage01_scroll_gate_independent").foundation_year_5000()["year_5000"]
    verify(selected["candidate_count"] == reference["candidate_count"], "Foundation year candidate count")
    verify(selected["open_index"] == reference["opening_gate_index"], "Foundation opening gate")
    verify(selected["close_index"] == reference["closing_gate_index"], "Foundation closing gate")
    verify(selected["days"] == reference["calendar_day_count"], "Foundation year day count")
    for calculation in (-1, 0, 1):
        candidate = find_year(calculation, 0, pairs)
        verify(candidate["open_day"] < 0 <= candidate["close_day"], "Foundation target containment")
    verify(len(CUTLET_NAMES) == 17 and len(MONTH_NAMES) == 47, "canonical name catalog sizes")
    verify(len(LEGACY_OFFSET_ZERO_CASES) == 10 and all(calc == 0 for _, calc, _ in LEGACY_OFFSET_ZERO_CASES), "ten exact legacy pairs use calculation offset zero")
    verify(tuple(target for _, _, target in LEGACY_OFFSET_ZERO_CASES) == (-2032, -2031, -1, 0, 1, 2212, 2213, -2169, 271, 2350), "legacy target offsets")
    return checks


def compare(args):
    suites = {
        "boundary": BOUNDARY_CASES,
        "wide": WIDE_CONTEXT_CASES,
        "legacy-offset-zero": LEGACY_OFFSET_ZERO_CASES,
    }
    cases = suites[args.suite]
    report = {
        "project_id": PROJECT_ID, "source_snapshot": SCROLL_NAME,
        "source_sha256": SOURCE_SHA256, "source_bytes_verified": args.scroll_file is not None,
        "oracle": "independent Hebrew Scroll component composition; no pinned Python imports",
        "suite": args.suite,
        "scope": f"{len(cases)} independent Hebrew Scroll full-date differentials in the selected suite",
        "full_stage1_accepted": False, "cases": [],
    }
    matched_cases = matched_fields = 0
    for index, (label, calculation_offset, target_offset) in enumerate(cases, start=1):
        expected = full_date(calculation_offset, target_offset, args.max_seconds, args.max_states)
        actual = run_fortran(args.fortran_exe, calculation_offset, target_offset, args.fortran_timeout)
        expected_fields = tuple(expected["fields"])
        field_matches = sum(a == b for a, b in zip(expected_fields, actual))
        matched_fields += field_matches
        matched_cases += field_matches == 5
        report["cases"].append({
            "case": index, "label": label,
            "calculation_offset": calculation_offset, "target_offset": target_offset,
            "calculation_day": FOUNDATION_DAY + calculation_offset,
            "target_day": FOUNDATION_DAY + target_offset,
            "expected_fields": list(expected_fields), "fortran_fields": list(actual),
            "matched_fields": field_matches, "year": expected["year"],
            "structure": expected["structure"],
        })
        print(f"STAGE01_SCROLL_FULL_DATE_CASE={index} LABEL={label} CALC_OFFSET={calculation_offset} TARGET_OFFSET={target_offset} MATCHED_FIELDS={field_matches}/5", flush=True)
        if field_matches != 5:
            print("STAGE01_SCROLL_FULL_DATE_EXPECTED=" + ",".join(map(str, expected_fields)))
            print("STAGE01_SCROLL_FULL_DATE_FORTRAN=" + ",".join(map(str, actual)))
    report["matched_cases"] = matched_cases
    report["total_cases"] = len(cases)
    report["matched_fields"] = matched_fields
    report["total_fields"] = 5 * len(cases)
    report["status"] = "PASS_BOUNDED_INDEPENDENT_SCROLL_DIFFERENTIAL" if matched_cases == len(cases) and matched_fields == 5 * len(cases) else "MISMATCH"
    report["full_stage1_accepted"] = False
    output = args.output or Path(f"build/stage01-scroll-full-date-{args.suite}.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    if matched_cases == len(cases) and matched_fields == 5 * len(cases):
        print(f"STAGE01_SCROLL_FULL_DATE_DIFFERENTIAL={matched_cases}/{len(cases)} CASES; {matched_fields}/{5 * len(cases)} EXACT FIELDS")
        print("STAGE01_SCROLL_FULL_DATE_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
        return 0
    print(f"STAGE01_SCROLL_FULL_DATE_NOT_ACCEPTED={matched_cases}/{len(cases)} CASES; {matched_fields}/{5 * len(cases)} EXACT FIELDS")
    return 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--fortran-exe", type=Path)
    parser.add_argument("--suite", choices=("boundary", "wide", "legacy-offset-zero"), default="boundary")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--scroll-file", type=Path)
    parser.add_argument("--max-seconds", type=float, default=180)
    parser.add_argument("--max-states", type=int, default=150000)
    parser.add_argument("--fortran-timeout", type=int, default=120)
    args = parser.parse_args()
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(20000)
    if args.scroll_file is not None:
        actual = hashlib.sha256(args.scroll_file.read_bytes()).hexdigest()
        if actual != SOURCE_SHA256:
            raise SystemExit("Hebrew Scroll source SHA-256 mismatch: " + actual)
        print("STAGE01_SCROLL_SOURCE_BYTES_SHA256=VERIFIED")
    if args.self_test:
        checks = self_test()
        print(f"STAGE01_SCROLL_FULL_DATE_ORACLE_SELFTEST={checks}/{checks}")
    if args.fortran_exe is not None:
        return compare(args)
    if not args.self_test:
        parser.error("specify --self-test and/or --fortran-exe")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ResourceLimit as exc:
        print("STAGE01_SCROLL_FULL_DATE_RESOURCE_LIMIT_INCONCLUSIVE=" + str(exc))
        raise SystemExit(2)
