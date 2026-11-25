#!/usr/bin/env python3
"""Independent arbitrary-precision oracle for Rust Stage06 DISCOVERY03 output."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

FOUNDATION = -15_055_671
SMALL_OFFSETS = (-8, -3, -2, -1, 0, 1, 2, 3, 8)
DISTANCE_BITS = (129, 1031)
WRAPPER_BITS = (129, 1031, 4097)
ANSI_ESCAPE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
DISTANCE_ROW = re.compile(
    r"DISCOVERY03_DISTANCE_ROW\s+c=(-?\d+)\s+t=(-?\d+)\s+"
    r"legacy=(-?\d+)\s+normative=(-?\d+)\s+red=(true|false)"
)
WRAPPER_ROW = re.compile(
    r"PATCH02_WRAPPER_ROW\s+day=(-?\d+)\s+raw=(-?\d+)\s+corrected=(-?\d+)"
)


def distance_offsets() -> set[int]:
    values = set(SMALL_OFFSETS)
    for bits in DISTANCE_BITS:
        wide = 1 << bits
        values.update((-wide, wide))
    return values


def wrapper_offsets() -> set[int]:
    values = set(range(-31, 32))
    for bits in WRAPPER_BITS:
        wide = 1 << bits
        values.update((-wide, wide))
    return values


def corrected_tag(offset: int) -> int:
    """Independent mathematical tag N(F+x), not a call into Rust code."""
    day = FOUNDATION + offset
    raw_tag = 2 * abs(day - FOUNDATION) + 1
    return raw_tag - 1 if day < FOUNDATION else raw_tag


def legacy_distance_oracle(calculation_offset: int, target_offset: int) -> int:
    return abs(corrected_tag(calculation_offset) - corrected_tag(target_offset))


def normative_distance(calculation_offset: int, target_offset: int) -> int:
    return abs(target_offset - calculation_offset) + 1


def self_test() -> None:
    examples = (
        (-20, -19, 2, 2),
        (-7, 3, 7, 11),
        (0, 0, 0, 1),
        (-1, 0, 1, 2),
        (1, 3, 4, 3),
    )
    for calculation, target, expected_legacy, expected_normative in examples:
        assert legacy_distance_oracle(calculation, target) == expected_legacy
        assert normative_distance(calculation, target) == expected_normative
    offsets = distance_offsets()
    assert len(offsets) == 13
    red = sum(
        legacy_distance_oracle(c, t) != normative_distance(c, t)
        for c in offsets
        for t in offsets
    )
    assert red == 153 and 169 - red == 16
    wrapper = wrapper_offsets()
    assert len(wrapper) == 69
    assert sum(x < 0 for x in wrapper) == 34
    assert sum(x >= 0 for x in wrapper) == 35


def validate_output(stdout: str) -> tuple[int, int, int]:
    text = ANSI_ESCAPE.sub("", stdout)
    required_markers = (
        "STAGE06_DISTANCE_EXPECTED_RED=153 CONTROL=16 UNEXPECTED=0 GUARDS=170",
        "STAGE05_WRAPPER_RECONCILIATION=69 RED_SCAR=34 CONTROL=35 GUARDS=69",
        "STAGE06_DISCOVERY03_ROWS=46 CELLS=230",
        "STAGE06_DISCOVERY03_BOUNDS=230 DETERMINISM=PASS",
        "STAGE06_DISCOVERY03_BOOTSTRAP_ONLY=PASS",
    )
    for marker in required_markers:
        if marker not in text:
            raise ValueError(f"required Rust test marker missing: {marker}")

    distance_matches = list(DISTANCE_ROW.finditer(text))
    distance_occurrences = text.count("DISCOVERY03_DISTANCE_ROW")
    if distance_occurrences != len(distance_matches):
        raise ValueError(
            f"malformed distance rows: {distance_occurrences} marker(s), "
            f"{len(distance_matches)} parseable row(s)"
        )
    offsets = distance_offsets()
    expected_pairs = {(c, t) for c in offsets for t in offsets}
    seen: set[tuple[int, int]] = set()
    red_count = 0
    control_count = 0
    for match in distance_matches:
        c, t, observed, reported_normative = map(int, match.groups()[:4])
        reported_red = match.group(5) == "true"
        pair = (c, t)
        if pair in seen:
            raise ValueError(f"duplicate distance pair: {pair}")
        seen.add(pair)
        if c not in offsets or t not in offsets:
            raise ValueError(f"out-of-contract distance input: {pair}")
        expected_legacy = legacy_distance_oracle(c, t)
        expected_normative = normative_distance(c, t)
        expected_red = expected_legacy != expected_normative
        if observed != expected_legacy:
            raise ValueError(
                f"legacy mismatch at {pair}: observed={observed}, oracle={expected_legacy}"
            )
        if reported_normative != expected_normative:
            raise ValueError(
                f"normative mismatch at {pair}: reported={reported_normative}, "
                f"oracle={expected_normative}"
            )
        if reported_red != expected_red:
            raise ValueError(f"RED/CONTROL classification mismatch at {pair}")
        if expected_red:
            red_count += 1
        else:
            control_count += 1

    if len(distance_matches) != 169 or seen != expected_pairs:
        missing = sorted(expected_pairs - seen)[:5]
        extra = sorted(seen - expected_pairs)[:5]
        raise ValueError(
            f"distance matrix incomplete: rows={len(distance_matches)}, "
            f"unique={len(seen)}, missing={missing}, extra={extra}"
        )
    if (red_count, control_count) != (153, 16):
        raise ValueError(f"wrong RED/CONTROL totals: {red_count}/{control_count}")

    wrapper_matches = list(WRAPPER_ROW.finditer(text))
    wrapper_occurrences = text.count("PATCH02_WRAPPER_ROW")
    if wrapper_occurrences != len(wrapper_matches):
        raise ValueError(
            f"malformed Stage05 wrapper rows: {wrapper_occurrences} marker(s), "
            f"{len(wrapper_matches)} parseable row(s)"
        )
    expected_days = {FOUNDATION + offset for offset in wrapper_offsets()}
    seen_days: set[int] = set()
    wrapper_red = 0
    wrapper_control = 0
    for match in wrapper_matches:
        day, raw, corrected = map(int, match.groups())
        if day in seen_days:
            raise ValueError(f"duplicate Stage05 wrapper day: {day}")
        seen_days.add(day)
        offset = day - FOUNDATION
        if offset not in wrapper_offsets():
            raise ValueError(f"out-of-contract Stage05 wrapper input: {day}")
        expected_raw = 2 * abs(offset) + 1
        expected_corrected = expected_raw - 1 if offset < 0 else expected_raw
        if raw != expected_raw or corrected != expected_corrected:
            raise ValueError(f"Stage05 wrapper oracle mismatch at day {day}")
        if offset < 0:
            wrapper_red += 1
        else:
            wrapper_control += 1
    if len(wrapper_matches) != 69 or seen_days != expected_days:
        raise ValueError(
            f"Stage05 wrapper set incomplete: rows={len(wrapper_matches)}, "
            f"unique={len(seen_days)}"
        )
    if (wrapper_red, wrapper_control) != (34, 35):
        raise ValueError(
            f"wrong Stage05 wrapper totals: {wrapper_red}/{wrapper_control}"
        )

    return len(distance_matches), red_count, control_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("stdout", nargs="?", help="cargo test --nocapture stdout file")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            self_test()
            print("STAGE06_DISTANCE_ORACLE_SELF_TEST=PASS")
        if args.stdout:
            rows, red, control = validate_output(
                Path(args.stdout).read_text(encoding="utf-8", errors="replace")
            )
            print(
                f"STAGE06_DISCOVERY03_DISTANCE_ORACLE=PASS "
                f"ROWS={rows} RED={red} CONTROL={control} GUARDS=170"
            )
            print(
                "STAGE05_PATCH02_WRAPPER_ORACLE=PASS "
                "ROWS=69 RED_SCAR=34 CONTROL=35 GUARDS=69"
            )
        elif not args.self_test:
            parser.error("provide stdout or --self-test")
    except (OSError, UnicodeError, ValueError, AssertionError) as exc:
        print(f"STAGE06_DISCOVERY03_DISTANCE_ORACLE=FAIL {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
