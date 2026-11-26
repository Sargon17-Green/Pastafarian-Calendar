#!/usr/bin/env python3
"""Compare checked calendarDate output with the independent structure oracle."""
from pathlib import Path
import sys


def read_markers(path: str) -> dict[str, str]:
    markers: dict[str, str] = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        markers[key] = value
    return markers


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: compare_calendar_date_results.py STRUCTURE_LOG API_LOG")
        return 2

    structure = read_markers(sys.argv[1])
    api = read_markers(sys.argv[2])

    if structure.get("YEAR_BOUNDARY_STRUCTURE_RESULT") != "PASS":
        print("YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_RESULT=MISSING_STRUCTURE_PASS")
        return 1
    if api.get("YEAR_BOUNDARY_CALENDAR_DATE_API_RESULT") != "PASS":
        print("YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_RESULT=MISSING_API_PASS")
        return 1

    pairs = (
        ("YEAR_BOUNDARY_EXPECTED_TARGET_DAY", "YEAR_BOUNDARY_API_TARGET_DAY"),
        ("YEAR_BOUNDARY_EXPECTED_YEAR_NUMBER", "YEAR_BOUNDARY_API_ACTUAL_YEAR_NUMBER"),
        ("YEAR_BOUNDARY_EXPECTED_CUTLET_NAME", "YEAR_BOUNDARY_API_ACTUAL_CUTLET_NAME"),
        ("YEAR_BOUNDARY_EXPECTED_DAY_IN_CUTLET", "YEAR_BOUNDARY_API_ACTUAL_DAY_IN_CUTLET"),
        ("YEAR_BOUNDARY_EXPECTED_MONTH_NAME", "YEAR_BOUNDARY_API_ACTUAL_MONTH_NAME"),
        ("YEAR_BOUNDARY_EXPECTED_DAY_IN_MONTH", "YEAR_BOUNDARY_API_ACTUAL_DAY_IN_MONTH"),
    )

    mismatches = []
    for expected_key, actual_key in pairs:
        expected = structure.get(expected_key)
        actual = api.get(actual_key)
        if expected is None or actual is None:
            mismatches.append((expected_key, expected, actual_key, actual, "missing"))
        elif expected != actual:
            mismatches.append((expected_key, expected, actual_key, actual, "different"))

    if mismatches:
        for expected_key, expected, actual_key, actual, reason in mismatches:
            print(
                "YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_MISMATCH="
                f"{reason}:{expected_key}={expected!r}:{actual_key}={actual!r}"
            )
        print("YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_RESULT=FAIL")
        return 1

    print(f"YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_FIELDS={len(pairs)}")
    print("YEAR_BOUNDARY_CALENDAR_DATE_DIFFERENTIAL_RESULT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
