#!/usr/bin/env python3
"""QA only: all 4244 days and 21220 date fields in actual 45-month year 5000.

Python reference is an independent, exact SHA-pinned implementation.
Fortran materializes its own original year once and projects every day
with original project_calendar_date. Existing separate CI checks execute
the original public normative_calendar_date on independently chosen dates.
No full Stage1 acceptance is implied by this bounded differential.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import resource
import subprocess
import sys
from collections import Counter
from pathlib import Path

if hasattr(sys, "set_int_max_str_digits"):
    sys.set_int_max_str_digits(0)

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_COMMIT = "83f1069e5eef4a349d5a9efe6097525cddc7300e"
REFERENCE_BLOB = "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"
FOUNDATION = -15055671
EXPECTED_YEAR = 5000
EXPECTED_MONTHS = 45
EXPECTED_DAYS = 4244
FIELDS = ("year_number", "cutlet_name_index", "day_in_cutlet",
          "month_name_index", "day_in_month")
OUT = Path("build/stage01-actual-45-full-year.json")


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def exactly_one(lines, prefix):
    found = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    check(len(found) == 1, "missing/duplicate marker " + prefix)
    return found[0]


def parse_csv(text, size):
    parts = text.split(",")
    check(len(parts) == size, "wrong CSV field count")
    return tuple(int(part) for part in parts)


def score_row(raw, index, month_id, expected):
    """Validate the same wire row used by the 4244-day differential gate."""
    check(raw.startswith("STAGE01_45_ROW="), "wrong row marker")
    observed = parse_csv(raw[len("STAGE01_45_ROW="):], 7)
    check(observed[0] == index, "out-of-order/duplicate row index")
    month_match = int(observed[1] == month_id)
    actual_fields = observed[2:]
    field_matches = sum(a == b for a, b in zip(actual_fields, expected))
    issues = []
    if not month_match:
        issues.append({"day": index, "kind": "month_id",
                       "expected": month_id, "actual": observed[1]})
    if field_matches != len(FIELDS):
        issues.append({"day": index, "kind": "date",
                       "expected": expected, "actual": actual_fields})
    return month_match, field_matches, issues


def parse_rank_row(raw, index):
    check(raw.startswith("STAGE01_45_RANK_ROW="), "wrong rank-row marker")
    observed = parse_csv(raw[len("STAGE01_45_RANK_ROW="):], 5)
    check(observed[0] == index, "out-of-order/duplicate rank-row index")
    month_ids = observed[1:]
    check(all(1 <= month_id <= EXPECTED_MONTHS for month_id in month_ids),
          "rank-boundary month ID outside range")
    return tuple(month_ids)


def score_rank_row(raw, index, expected):
    observed = parse_rank_row(raw, index)
    return tuple(int(actual == wanted) for actual, wanted in zip(observed, expected))


def validate_weave_ordering(sequence, lengths, label):
    month_count = len(lengths)
    check(len(sequence) == sum(lengths), label + ": wrong sequence length")
    counts = [0] * (month_count + 1)
    first = [None] * (month_count + 1)
    last = [None] * (month_count + 1)
    for position, month_id in enumerate(sequence, 1):
        check(1 <= month_id <= month_count, label + ": month ID outside range")
        counts[month_id] += 1
        if first[month_id] is None:
            first[month_id] = position
        last[month_id] = position
    check(tuple(counts[1:]) == tuple(lengths), label + ": month frequency mismatch")
    first_order = all(first[i] < first[i + 1] for i in range(1, month_count))
    last_order = all(last[i] < last[i + 1] for i in range(1, month_count))
    check(first_order, label + ": first-occurrence order mismatch")
    check(last_order, label + ": last-occurrence order mismatch")
    return {"first_occurrence_order": first_order, "last_occurrence_order": last_order}


def expect_rejection(action, message):
    try:
        action()
    except AssertionError:
        return
    raise AssertionError(message)


def selftest():
    check(parse_csv("1,2,3,4,5,6,7", 7) == tuple(range(1, 8)), "CSV roundtrip")
    check(exactly_one(["STAGE01_45_DONE=4"], "STAGE01_45_DONE=") == "4", "marker")
    check(sum(Counter([1, 2, 1, 3, 2, 1]).values()) == 6, "frequency")
    try:
        parse_csv("1,2,3", 7)
    except AssertionError:
        pass
    else:
        raise AssertionError("short row accepted")
    try:
        exactly_one(["STAGE01_45_DONE=4", "STAGE01_45_DONE=4"], "STAGE01_45_DONE=")
    except AssertionError:
        pass
    else:
        raise AssertionError("duplicate marker accepted")
    check(len(FIELDS) == 5, "five-field schema")
    # Adversarial QA: every corrupted field and the month ID must be detected.
    baseline = [1, 18, 5000, 2, 7, 31, 4]
    expected = tuple(baseline[2:])
    wire = lambda values: "STAGE01_45_ROW=" + ",".join(str(v) for v in values)
    check(score_row(wire(baseline), 1, 18, expected) == (1, 5, []),
          "intact row rejected")
    for position in range(2, 7):
        changed = list(baseline)
        changed[position] += 1
        month_ok, fields_ok, issues = score_row(wire(changed), 1, 18, expected)
        check(month_ok == 1 and fields_ok == 4 and
              [issue["kind"] for issue in issues] == ["date"],
              "corrupted date component accepted: " + str(position))
    changed = list(baseline)
    changed[1] += 1
    month_ok, fields_ok, issues = score_row(wire(changed), 1, 18, expected)
    check(month_ok == 0 and fields_ok == 5 and
          [issue["kind"] for issue in issues] == ["month_id"],
          "corrupted weaving ID accepted")
    for bad in (wire([2, *baseline[1:]]), wire(baseline[:-1])):
        try:
            score_row(bad, 1, 18, expected)
        except AssertionError:
            pass
        else:
            raise AssertionError("out-of-order or truncated row accepted")
    rank_baseline = [1, 1, 1, 45, 45]
    rank_expected = (1, 1, 45, 45)
    rank_wire = lambda values: "STAGE01_45_RANK_ROW=" + ",".join(str(v) for v in values)
    check(score_rank_row(rank_wire(rank_baseline), 1, rank_expected) == (1, 1, 1, 1),
          "intact rank-boundary row rejected")
    rank_mutations = (
        ([1, 2, 1, 45, 45], (0, 1, 1, 1)),
        ([1, 1, 2, 45, 45], (1, 0, 1, 1)),
        ([1, 1, 1, 44, 45], (1, 1, 0, 1)),
        ([1, 1, 1, 45, 44], (1, 1, 1, 0)),
    )
    for changed, expected_matches in rank_mutations:
        check(score_rank_row(rank_wire(changed), 1, rank_expected) == expected_matches,
              "rank-boundary corruption was not isolated")
    expect_rejection(lambda: parse_rank_row(rank_wire([2, 1, 1, 45, 45]), 1),
                     "out-of-order rank row accepted")
    expect_rejection(lambda: parse_rank_row(rank_wire([1, 1, 1, 45]), 1),
                     "truncated rank row accepted")
    expect_rejection(lambda: parse_rank_row(rank_wire([1, 1, 1, 45, 45, 9]), 1),
                     "extra rank-row field accepted")
    expect_rejection(lambda: parse_rank_row(rank_wire([1, 0, 1, 45, 45]), 1),
                     "zero rank month ID accepted")
    expect_rejection(lambda: parse_rank_row(rank_wire([1, 1, 46, 45, 45]), 1),
                     "out-of-range rank month ID accepted")
    expect_rejection(lambda: parse_rank_row(rank_wire([1, 1, 1, 45, 46]), 1),
                     "out-of-range final rank month ID accepted")
    print("STAGE01_ACTUAL_45_RANK_BOUNDARY_MUTATIONS=10/10")
    print("STAGE01_ACTUAL_45_FULL_YEAR_MUTATIONS=8/8")
    print("STAGE01_ACTUAL_45_FULL_YEAR_SELFTEST=6/6")


def reference(path):
    data = path.read_bytes()
    sha = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    check(sha == REFERENCE_BLOB, "independent source Git blob mismatch: " + sha)
    spec = importlib.util.spec_from_file_location("pinned_actual_45_full_year", path)
    check(spec is not None and spec.loader is not None, "cannot import pinned source")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    check(mod.FOUNDATION_DAY == FOUNDATION, "reference foundation mismatch")
    check(mod.MAX_MONTHS == 47 and mod.MIN_MONTH_DAYS == 4 and
          mod.MAX_MONTH_DAYS == 123, "reference contract changed")
    return mod.NormativeCalendar(), mod.MonthWeavingFamily


def bounded_fortran(executable):
    def cap():
        bound = 1024 * 1024 * 1024
        resource.setrlimit(resource.RLIMIT_AS, (bound, bound))
    result = subprocess.run([str(executable.resolve())], text=True, capture_output=True,
                            check=False, timeout=360, preexec_fn=cap)
    check(result.returncode == 0, "Fortran return code " + str(result.returncode)
          + "; stderr=" + result.stderr[-1000:])
    return result.stdout.splitlines()


def compare(python_path, fortran_exe):
    oracle, month_weaving_family = reference(python_path)
    year = oracle.year5000(FOUNDATION)
    structure = oracle.build_year_structure(FOUNDATION, year)
    days = year.close_gate_day - year.open_gate_day
    check(year.number == EXPECTED_YEAR, "wrong actual year")
    check(days == EXPECTED_DAYS, "wrong actual gate span")
    check(structure.month_count == EXPECTED_MONTHS, "not an actual 45-month year")
    check(len(structure.month_weaving) == days, "independent weave length")
    check(len(structure.month_lengths) == EXPECTED_MONTHS, "independent length count")
    check(len(set(structure.month_name_indices)) == EXPECTED_MONTHS, "month names repeat")
    check(all(4 <= length <= 123 for length in structure.month_lengths),
          "month lengths outside range")
    check(tuple(Counter(structure.month_weaving)[i] for i in range(1, 46))
          == tuple(structure.month_lengths), "independent month frequency")
    check(len(structure.cutlets) > 0 and
          structure.cutlets[0].first_day == year.open_gate_day + 1 and
          structure.cutlets[-1].last_day == year.close_gate_day,
          "independent cutlet coverage")
    for before, after in zip(structure.cutlets, structure.cutlets[1:]):
        check(after.first_day == before.last_day + 1, "cutlet gap or overlap")

    family = month_weaving_family(structure.month_lengths)
    weaving_count = family.count()
    check(weaving_count > 2, "actual weaving family too small for boundary ranks")
    boundary_ranks = (1, 2, weaving_count - 1, weaving_count)
    expected_boundary_sequences = tuple(family.unrank1(rank) for rank in boundary_ranks)
    check(all(left < right for left, right in zip(expected_boundary_sequences,
                                                  expected_boundary_sequences[1:])),
          "independent boundary ranks are not strictly lexicographic")

    raw_lines = bounded_fortran(fortran_exe)
    meta = parse_csv(exactly_one(raw_lines, "STAGE01_45_META="), 5)
    check(meta == (EXPECTED_YEAR, year.open_gate_day, year.close_gate_day,
                   EXPECTED_DAYS, EXPECTED_MONTHS), "Fortran year metadata mismatch")
    lengths = parse_csv(exactly_one(raw_lines, "STAGE01_45_LENGTHS="), 45)
    check(lengths == tuple(structure.month_lengths),
          "independently selected month lengths differ")
    check(exactly_one(raw_lines, "STAGE01_45_RANK_TOTAL=") == str(weaving_count),
          "Fortran and independent Python weaving counts differ")
    check(int(exactly_one(raw_lines, "STAGE01_45_DONE=")) == days,
          "Fortran did not finish all year days")
    check(int(exactly_one(raw_lines, "STAGE01_45_RANK_DONE=")) == days,
          "Fortran did not finish all rank-boundary rows")
    check(exactly_one(raw_lines, "STAGE01_45_ORDERING_PASS=") == "5/5",
          "Fortran first/last occurrence ordering gate incomplete")
    output_rows = [line for line in raw_lines if line.startswith("STAGE01_45_ROW=")]
    rank_rows = [line for line in raw_lines if line.startswith("STAGE01_45_RANK_ROW=")]
    check(len(output_rows) == days, "Fortran row count differs")
    check(len(rank_rows) == days, "Fortran rank-boundary row count differs")
    check(len(raw_lines) == 2 * days + 6, "unexpected Fortran records")

    ordinal = [0] * (EXPECTED_MONTHS + 1)
    actual_sequence = []
    rank_sequences = [[], [], [], []]
    rank_matches = [0, 0, 0, 0]
    cutlet_index = 0
    matched_fields = 0
    matched_weave_ids = 0
    failures = []
    for index, raw in enumerate(output_rows, 1):
        target = year.open_gate_day + index
        month_id = structure.month_weaving[index - 1]
        actual_sequence.append(month_id)
        ordinal[month_id] += 1
        while cutlet_index + 1 < len(structure.cutlets) and (
                target > structure.cutlets[cutlet_index].last_day):
            cutlet_index += 1
        cutlet = structure.cutlets[cutlet_index]
        check(cutlet.first_day <= target <= cutlet.last_day, "cutlet omission")
        expected = (EXPECTED_YEAR, cutlet.name_index,
                    target - cutlet.first_day + 1,
                    structure.month_name_indices[month_id - 1], ordinal[month_id])
        month_matches, field_matches, row_failures = score_row(
            raw, index, month_id, expected)
        matched_weave_ids += month_matches
        matched_fields += field_matches
        for issue in row_failures:
            if len(failures) < 30:
                failures.append(issue)
    check(tuple(ordinal[1:]) == tuple(structure.month_lengths),
          "yearwide independent ordinal mismatch")
    check(tuple(actual_sequence) == tuple(structure.month_weaving),
          "Fortran actual weaving differs from independent reference")

    for index, raw in enumerate(rank_rows, 1):
        observed = parse_rank_row(raw, index)
        for slot, month_id in enumerate(observed):
            rank_sequences[slot].append(month_id)
            rank_matches[slot] += int(month_id == expected_boundary_sequences[slot][index - 1])
    for slot, (observed, expected, rank) in enumerate(
            zip(rank_sequences, expected_boundary_sequences, boundary_ranks)):
        check(tuple(observed) == tuple(expected),
              "Fortran original unrank differs at boundary rank " + str(rank))
        check(rank_matches[slot] == days,
              "rank-boundary exact month-ID count incomplete at rank " + str(rank))

    actual_ordering = validate_weave_ordering(
        tuple(actual_sequence), structure.month_lengths, "actual normative weave")
    boundary_orderings = [
        validate_weave_ordering(tuple(sequence), structure.month_lengths,
                                 "rank " + str(rank))
        for sequence, rank in zip(rank_sequences, boundary_ranks)
    ]
    ordering_passes = 1 + len(boundary_orderings)
    check(ordering_passes == 5, "first/last occurrence ordering coverage incomplete")

    rank_hashes = [
        hashlib.sha256(bytes(sequence)).hexdigest()
        for sequence in rank_sequences
    ]
    rank_total_text = str(weaving_count)
    result = {
        "project_id": PROJECT_ID, "source_commit": SOURCE_COMMIT,
        "reference_blob": REFERENCE_BLOB, "year": EXPECTED_YEAR,
        "actual_months": EXPECTED_MONTHS, "actual_days": days,
        "month_lengths": list(structure.month_lengths),
        "independent_weaving_sha256": hashlib.sha256(
            bytes(structure.month_weaving)).hexdigest(),
        "weaving_count_decimal": rank_total_text,
        "weaving_count_digits": len(rank_total_text),
        "weaving_count_sha256": hashlib.sha256(rank_total_text.encode()).hexdigest(),
        "weaving_count_matches_reference": True,
        "rank_boundary_ranks": [str(rank) for rank in boundary_ranks],
        "rank_boundary_cases": 4,
        "rank_boundary_cases_passed": 4,
        "matched_month_ids": matched_weave_ids, "total_month_ids": days,
        "matched_rank1_ids": rank_matches[0], "total_rank1_ids": days,
        "matched_rank2_ids": rank_matches[1], "total_rank2_ids": days,
        "matched_rank_penultimate_ids": rank_matches[2], "total_rank_penultimate_ids": days,
        "matched_rank_last_ids": rank_matches[3], "total_rank_last_ids": days,
        "rank1_sha256": rank_hashes[0],
        "rank2_sha256": rank_hashes[1],
        "rank_penultimate_sha256": rank_hashes[2],
        "rank_last_sha256": rank_hashes[3],
        "actual_first_occurrence_order": actual_ordering["first_occurrence_order"],
        "actual_last_occurrence_order": actual_ordering["last_occurrence_order"],
        "rank_boundary_first_last_ordering": boundary_orderings,
        "first_last_occurrence_ordering_passed": ordering_passes,
        "fortran_original_unrank_boundary_probes": True,
        "independent_rank_oracle_blob": REFERENCE_BLOB,
        "full_stage1_accepted": False,
        "original_full_entrypoint_for_every_day": False,
        "fortran_original_build_plus_projection": True,
        "discrepancies": failures[:30]
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    passed = (matched_weave_ids == days and matched_fields == 5 * days
              and all(matches == days for matches in rank_matches)
              and ordering_passes == 5)
    print("STAGE01_ACTUAL_45_FULL_YEAR_WEAVING="
          + str(matched_weave_ids) + "/" + str(days), flush=True)
    print("STAGE01_ACTUAL_45_FULL_YEAR_FIELDS="
          + str(matched_fields) + "/" + str(5 * days), flush=True)
    print("STAGE01_ACTUAL_45_FULL_YEAR_RANK_BOUNDARIES=4/4 "
          + "FIRST=" + str(rank_matches[0]) + "/" + str(days)
          + " SECOND=" + str(rank_matches[1]) + "/" + str(days)
          + " PENULTIMATE=" + str(rank_matches[2]) + "/" + str(days)
          + " LAST=" + str(rank_matches[3]) + "/" + str(days), flush=True)
    print("STAGE01_ACTUAL_45_FULL_YEAR_ORDERING=" + str(ordering_passes) + "/5", flush=True)
    print("STAGE01_ACTUAL_45_FULL_YEAR_QA_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    return 0 if passed else 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--fortran-exe", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        selftest()
        return 0
    check(args.reference is not None and args.fortran_exe is not None,
          "reference and Fortran executable required")
    return compare(args.reference, args.fortran_exe)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        if not OUT.exists():
            OUT.write_text(json.dumps({
                "project_id": PROJECT_ID, "source_commit": SOURCE_COMMIT,
                "full_stage1_accepted": False, "status": "error",
                "error": type(exc).__name__ + ": " + str(exc)
            }, indent=2) + "\n", encoding="utf-8")
        print("STAGE01_ACTUAL_45_FULL_YEAR_ERROR=" + repr(exc), file=sys.stderr)
        sys.exit(1)
