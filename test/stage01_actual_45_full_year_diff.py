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
    return mod.NormativeCalendar()


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
    oracle = reference(python_path)
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

    raw_lines = bounded_fortran(fortran_exe)
    meta = parse_csv(exactly_one(raw_lines, "STAGE01_45_META="), 5)
    check(meta == (EXPECTED_YEAR, year.open_gate_day, year.close_gate_day,
                   EXPECTED_DAYS, EXPECTED_MONTHS), "Fortran year metadata mismatch")
    lengths = parse_csv(exactly_one(raw_lines, "STAGE01_45_LENGTHS="), 45)
    check(lengths == tuple(structure.month_lengths),
          "independently selected month lengths differ")
    check(int(exactly_one(raw_lines, "STAGE01_45_DONE=")) == days,
          "Fortran did not finish all year days")
    output_rows = [line for line in raw_lines if line.startswith("STAGE01_45_ROW=")]
    check(len(output_rows) == days, "Fortran row count differs")
    check(len(raw_lines) == days + 3, "unexpected Fortran records")

    ordinal = [0] * (EXPECTED_MONTHS + 1)
    cutlet_index = 0
    matched_fields = 0
    matched_weave_ids = 0
    failures = []
    for index, raw in enumerate(output_rows, 1):
        target = year.open_gate_day + index
        month_id = structure.month_weaving[index - 1]
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
    result = {
        "project_id": PROJECT_ID, "source_commit": SOURCE_COMMIT,
        "reference_blob": REFERENCE_BLOB, "year": EXPECTED_YEAR,
        "actual_months": EXPECTED_MONTHS, "actual_days": days,
        "month_lengths": list(structure.month_lengths),
        "independent_weaving_sha256": hashlib.sha256(
            bytes(structure.month_weaving)).hexdigest(),
        "matched_month_ids": matched_weave_ids, "total_month_ids": days,
        "matched_fields": matched_fields, "total_fields": 5 * days,
        "full_stage1_accepted": False,
        "original_full_entrypoint_for_every_day": False,
        "fortran_original_build_plus_projection": True,
        "discrepancies": failures[:30]
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    passed = matched_weave_ids == days and matched_fields == 5 * days
    print("STAGE01_ACTUAL_45_FULL_YEAR_WEAVING="
          + str(matched_weave_ids) + "/" + str(days), flush=True)
    print("STAGE01_ACTUAL_45_FULL_YEAR_FIELDS="
          + str(matched_fields) + "/" + str(5 * days), flush=True)
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
