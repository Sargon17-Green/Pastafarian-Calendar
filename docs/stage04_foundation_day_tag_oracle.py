#!/usr/bin/env python3
"""Independent Python-int preflight oracle for the Foundation Day tag.

Normative source: README.md, Sections B-C, pinned at
56bc4173aae4975ded019ef5ab5a36249f1424df.

This file does not import Pascal code, Stage02 fixtures, or another branch.
It validates the mathematical oracle and deterministic probe table only.
It is NOT a Native Pascal test and cannot accept Stage04 by itself.
"""
from __future__ import annotations

import argparse
from hashlib import sha256
from pathlib import Path

FOUNDATION_DAY = -15_055_671
EXPECTED_PROBES = 1_072
BOUNDARY_RADIUS = 512


def foundation_day_tag(day: int) -> int:
    """Return the positive, one-based tag defined by normative Section C."""
    delta = day - FOUNDATION_DAY
    return -2 * delta if delta < 0 else 2 * delta + 1


def inverse_foundation_day_tag(tag: int) -> int:
    """Inverse of the normative tag mapping for positive integer tags."""
    if tag < 1:
        raise ValueError("Foundation Day tags are positive integers")
    half, parity = divmod(tag, 2)
    return FOUNDATION_DAY + half if parity else FOUNDATION_DAY - half


def gregorian_jdn(year: int, month: int, day: int) -> int:
    """Proleptic Gregorian JDN using astronomical year numbering."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    return (
        day
        + (153 * m + 2) // 5
        + 365 * y
        + y // 4
        - y // 100
        + y // 400
        - 32045
    )


def julian_jdn(year: int, month: int, day: int) -> int:
    """Proleptic Julian JDN using astronomical year numbering."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    return day + (153 * m + 2) // 5 + 365 * y + y // 4 - 32083


def check_calendar_anchor() -> None:
    # 41,222 BCE Gregorian = astronomical year -41,221.
    gregorian = gregorian_jdn(-41_221, 12, 22)
    # 41,221 BCE Julian = astronomical year -41,220.
    julian = julian_jdn(-41_220, 10, 28)
    if gregorian != julian:
        raise AssertionError(
            f"Gregorian/Julian Foundation anchor differs: {gregorian} != {julian}"
        )
    # Gregorian 0001-01-01 is absolute day 1.
    absolute_day = gregorian - 1_721_425
    if absolute_day != FOUNDATION_DAY:
        raise AssertionError(
            f"Foundation absolute day mismatch: {absolute_day} != {FOUNDATION_DAY}"
        )


def probe_days() -> list[int]:
    days = set(
        range(
            FOUNDATION_DAY - BOUNDARY_RADIUS,
            FOUNDATION_DAY + BOUNDARY_RADIUS + 1,
        )
    )
    days.update(
        {
            FOUNDATION_DAY,
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY + 1,
            -(2**63) - 1,
            -(2**63),
            -(2**63) + 1,
            2**63 - 1,
            2**63,
            2**63 + 1,
            -1,
            0,
            1,
        }
    )
    for exponent in (63, 64, 127, 128, 255, 256, 512, 1024, 2048, 4096):
        power = 2**exponent
        days.update(
            {
                FOUNDATION_DAY - power,
                FOUNDATION_DAY + power,
                -power,
                power,
            }
        )
    result = sorted(days)
    if len(result) != EXPECTED_PROBES:
        raise AssertionError(
            f"Probe count changed: {len(result)} != {EXPECTED_PROBES}"
        )
    return result


def table_bytes() -> bytes:
    lines = ["day\ttag\tinverse_day\tside"]
    days = probe_days()
    tags: set[int] = set()
    for day in days:
        tag = foundation_day_tag(day)
        inverse = inverse_foundation_day_tag(tag)
        side = "BEFORE" if day < FOUNDATION_DAY else "FOUNDATION_OR_AFTER"
        if tag < 1:
            raise AssertionError(f"Non-positive tag for day {day}")
        if inverse != day:
            raise AssertionError(f"Inverse mismatch for day {day}: {inverse}")
        if (tag % 2 == 0) != (day < FOUNDATION_DAY):
            raise AssertionError(f"Parity mismatch for day {day}: tag {tag}")
        if tag in tags:
            raise AssertionError(f"Tag collision: {tag}")
        tags.add(tag)
        lines.append(f"{day}\t{tag}\t{inverse}\t{side}")
    return ("\n".join(lines) + "\n").encode("utf-8")


def self_test() -> bytes:
    check_calendar_anchor()
    days = probe_days()
    data = table_bytes()
    if len(days) != EXPECTED_PROBES:
        raise AssertionError("Unexpected probe count")
    if len(set(foundation_day_tag(day) for day in days)) != EXPECTED_PROBES:
        raise AssertionError("Tag mapping is not injective on probe set")
    if foundation_day_tag(FOUNDATION_DAY) != 1:
        raise AssertionError("Foundation Day must have tag 1")
    for offset in range(1, BOUNDARY_RADIUS + 1):
        if foundation_day_tag(FOUNDATION_DAY - offset) != 2 * offset:
            raise AssertionError(f"Before-boundary mismatch at offset {offset}")
        if foundation_day_tag(FOUNDATION_DAY + offset) != 2 * offset + 1:
            raise AssertionError(f"After-boundary mismatch at offset {offset}")
    for tag in range(1, 4097):
        if foundation_day_tag(inverse_foundation_day_tag(tag)) != tag:
            raise AssertionError(f"Tag round-trip mismatch at {tag}")
    return data


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--emit", type=Path, help="write deterministic UTF-8 TSV")
    group.add_argument("--check", type=Path, help="check exact TSV bytes")
    group.add_argument("--self-test", action="store_true", help="run oracle preflight")
    args = parser.parse_args()

    expected = self_test()
    if args.emit is not None:
        args.emit.write_bytes(expected)
        if args.emit.read_bytes() != expected:
            raise SystemExit("FAIL: emitted TSV readback differs")
    elif args.check is not None:
        if args.check.read_bytes() != expected:
            raise SystemExit("FAIL: TSV differs from independent oracle")

    print("PASS foundation_day_tag_oracle=YES")
    print(f"PROBES={EXPECTED_PROBES}")
    print(f"BOUNDARY_IDENTITIES={2 * BOUNDARY_RADIUS}")
    print("TAG_INVERSE_ROUNDTRIPS=4096/4096")
    print("GREGORIAN_JULIAN_ANCHOR=EQUAL")
    print("NATIVE_PASCAL_EXECUTED=NO")
    print("STAGE04_ACCEPTANCE=NOT_CLAIMED")
    print("TSV_SHA256=" + sha256(expected).hexdigest())


if __name__ == "__main__":
    main()
