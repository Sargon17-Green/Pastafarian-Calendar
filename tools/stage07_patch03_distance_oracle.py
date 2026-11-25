#!/usr/bin/env python3
"""Independent arbitrary-precision oracle for Stage07/PATCH03 distance selection."""

from __future__ import annotations

import re
import sys
from pathlib import Path

FOUNDATION = -15_055_671
LOCAL_OFFSETS = (-11, -5, -2, -1, 0, 1, 2, 5, 11)
WIDE_OFFSETS = tuple(
    value
    for bits in (130, 1032)
    for value in (-(1 << bits), 1 << bits)
)
WIDEST = (1 << 4097) + 1
OFFSETS = LOCAL_OFFSETS + WIDE_OFFSETS + (-WIDEST, WIDEST)
ROW_RE = re.compile(
    r"PATCH03_DISTANCE_ROW c=(-?\d+) t=(-?\d+) legacy=(-?\d+) "
    r"chronological=(-?\d+) mismatch=(true|false) selected=(-?\d+) result=(-?\d+)"
)


def tag_from_offset(offset: int) -> int:
    if offset < 0:
        return -2 * offset
    return 2 * offset + 1


def expected_row(c: int, t: int) -> tuple[int, int, bool, int, int]:
    legacy = abs(tag_from_offset(c) - tag_from_offset(t))
    chronological = abs(t - c)
    mismatch = legacy != chronological
    selected = chronological if mismatch else legacy
    result = selected + 1
    return legacy, chronological, mismatch, selected, result


def self_test() -> None:
    vectors = {
        (0, 0): (0, 0, False, 0, 1),
        (-1, 0): (1, 1, False, 1, 2),
        (-2, 0): (3, 2, True, 2, 3),
        (-1, 1): (1, 2, True, 2, 3),
    }
    for pair, expected in vectors.items():
        actual = expected_row(*pair)
        if actual != expected:
            raise SystemExit(f"self-test failed for {pair}: {actual} != {expected}")
    mismatches = sum(expected_row(c, t)[2] for c in OFFSETS for t in OFFSETS)
    if (len(OFFSETS), len(OFFSETS) ** 2, mismatches) != (15, 225, 204):
        raise SystemExit("self-test domain or mismatch count changed")
    print("STAGE07_PATCH03_ORACLE_SELF_TEST=PASS")


def verify_output(path: Path) -> None:
    lines = path.read_text(encoding="utf-8", errors="strict").splitlines()
    row_lines = [line for line in lines if "PATCH03_DISTANCE_ROW" in line]
    if len(row_lines) != 225:
        raise SystemExit(f"expected 225 row lines, got {len(row_lines)}")

    observed: dict[tuple[int, int], tuple[int, int, bool, int, int]] = {}
    for line in row_lines:
        match = ROW_RE.fullmatch(line)
        if not match:
            raise SystemExit(f"malformed row: {line}")
        c, t, legacy, chronological, selected, result = (
            int(match.group(1)),
            int(match.group(2)),
            int(match.group(3)),
            int(match.group(4)),
            int(match.group(6)),
            int(match.group(7)),
        )
        mismatch = match.group(5) == "true"
        key = (c, t)
        if key in observed:
            raise SystemExit(f"duplicate pair: {key}")
        observed[key] = (legacy, chronological, mismatch, selected, result)

    expected_pairs = {(c, t) for c in OFFSETS for t in OFFSETS}
    if set(observed) != expected_pairs:
        missing = expected_pairs - set(observed)
        extra = set(observed) - expected_pairs
        raise SystemExit(f"pair set mismatch: missing={len(missing)} extra={len(extra)}")

    mismatch_count = 0
    match_count = 0
    for (c, t), actual in observed.items():
        expected = expected_row(c, t)
        if actual != expected:
            raise SystemExit(f"oracle mismatch for {(c, t)}: {actual} != {expected}")
        mismatch_count += int(actual[2])
        match_count += int(not actual[2])

        reverse = observed[(t, c)]
        if reverse != actual:
            raise SystemExit(f"symmetry failure for {(c, t)}: {actual} != {reverse}")

    expected_marker = "STAGE07_PATCH03_ROWS=225 MISMATCH=204 MATCH=21 GUARDS=226"
    if expected_marker not in lines:
        raise SystemExit("missing Native row/guard marker")
    if "STAGE07_PATCH03_BOOTSTRAP_ONLY=PASS" not in lines:
        raise SystemExit("missing BootstrapOnly guard")
    if (mismatch_count, match_count) != (204, 21):
        raise SystemExit("unexpected mismatch classification")

    print(
        "STAGE07_PATCH03_ORACLE=PASS "
        f"ROWS={len(observed)} MISMATCH={mismatch_count} "
        f"MATCH={match_count} GUARDS=226"
    )


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
    elif len(sys.argv) == 2:
        verify_output(Path(sys.argv[1]))
    else:
        raise SystemExit(
            "usage: stage07_patch03_distance_oracle.py --self-test | <native-stdout-file>"
        )
