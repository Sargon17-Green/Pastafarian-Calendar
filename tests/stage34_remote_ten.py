#!/usr/bin/env python3
"""Stage34: cross-axis 5786-remote/ten-day differential against the independent Stage14 oracle."""
import sys
from pathlib import Path
from stage14_real_oracle import FOUNDATION, date

OFFSETS = (-5786, -10, 0, 10, 5786)
CAL_DAYS = tuple(FOUNDATION + delta for delta in OFFSETS)
TARGET_DAYS = tuple(FOUNDATION + delta for delta in OFFSETS)
PAIRS = tuple((cal, target) for cal in CAL_DAYS for target in TARGET_DAYS)
FIELDS = ("year", "cutlet", "cutlet_day", "month", "month_day")
PIVOT = (FOUNDATION - 5786, FOUNDATION + 10)

# Exact earlier ordered matrices. Stage19 is a subset of Stage20.
PRIOR_MATRICES = (
    ((-1, 0, 1), (-1, 0, 1)),  # Stage15
    ((-31, -7, 0, 7, 31), (-31, -7, 0, 7, 31)),  # Stage16
    ((-1, 0, 1), (-5779, 0, 5779)),  # Stage17
    ((-5779, 0, 5779), (-1, 0, 1)),  # Stage18
    ((-5779, -31, 0, 31, 5779), (-5779, -31, 0, 31, 5779)),  # Stage20
    ((-5779, -5778, 5778, 5779), (-5779, -5778, 5778, 5779)),  # Stage21
    ((-5778, -31, 0, 31, 5778), (-5778, -31, 0, 31, 5778)),  # Stage22
    ((-5779, -7, 0, 7, 5779), (-5779, -7, 0, 7, 5779)),  # Stage23
    ((-5778, -7, 0, 7, 5778), (-5778, -7, 0, 7, 5778)),  # Stage24
    ((-5778, -1, 0, 1, 5778), (-5778, -1, 0, 1, 5778)),  # Stage25
    ((-5778, -2, 0, 2, 5778), (-5778, -2, 0, 2, 5778)),  # Stage26
    ((-5779, -2, 0, 2, 5779), (-5779, -2, 0, 2, 5779)),  # Stage27
    ((-5780, -3, 0, 3, 5780), (-5780, -3, 0, 3, 5780)),  # Stage28
    ((-5781, -4, 0, 4, 5781), (-5781, -4, 0, 4, 5781)),  # Stage29
    ((-5782, -5, 0, 5, 5782), (-5782, -5, 0, 5, 5782)),  # Stage30
    ((-5783, -6, 0, 6, 5783), (-5783, -6, 0, 6, 5783)),  # Stage31
    ((-5784, -8, 0, 8, 5784), (-5784, -8, 0, 8, 5784)),  # Stage32
    ((-5785, -9, 0, 9, 5785), (-5785, -9, 0, 9, 5785)),  # Stage33
)


def selftest():
    assert len(PAIRS) == 25 and len(set(PAIRS)) == 25
    checked = 1

    previously_tested = {
        (FOUNDATION + cal_offset, FOUNDATION + target_offset)
        for cal_axis, target_axis in PRIOR_MATRICES
        for cal_offset in cal_axis
        for target_offset in target_axis
    }
    new_pairs = set(PAIRS) - previously_tested
    expected_new = {
        (FOUNDATION + cal_offset, FOUNDATION + target_offset)
        for cal_offset in OFFSETS
        for target_offset in OFFSETS
        if (cal_offset, target_offset) != (0, 0)
    }
    assert len(expected_new) == 24 and new_pairs == expected_new
    checked += 1

    assert sorted({abs(day - FOUNDATION) for day in CAL_DAYS}) == [0, 9, 5786]
    checked += 1
    assert sorted({abs(day - FOUNDATION) for day in TARGET_DAYS}) == [0, 9, 5786]
    checked += 1

    expected = {(cal, target): tuple(date(cal, target)) for cal, target in PAIRS}
    for key, value in expected.items():
        assert len(value) == 5, key
        year, cutlet, cutlet_day, month, month_day = value
        for valid in (
            4900 <= year <= 5100,
            1 <= cutlet <= 17,
            1 <= cutlet_day <= 5778,
            1 <= month <= 47,
            1 <= month_day <= 123,
        ):
            assert valid, (key, value)
            checked += 1

    # Five repeated oracle evaluations check deterministic output at the frontier pivot.
    for first, second in zip(expected[PIVOT], tuple(date(*PIVOT))):
        assert first == second
        checked += 1

    for actual, anchor in zip(
        expected[(FOUNDATION, FOUNDATION)],
        (5000, 10, 503, 30, 52),
    ):
        assert actual == anchor
        checked += 1

    assert checked == 139
    print(f"STAGE34_INDEPENDENT_REMOTE_NINE_SELFTEST_ASSERTIONS={checked}")


def compare(path):
    found = {}
    markers = 0
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        parts = line.strip().split()
        if not parts:
            continue
        if parts[0] == "STAGE34_NATIVE_PAIR":
            if len(parts) != 8:
                raise AssertionError(f"malformed native pair: {line}")
            numbers = tuple(map(int, parts[1:]))
            key = numbers[:2]
            if key in found:
                raise AssertionError(f"duplicate pair {key}")
            found[key] = numbers[2:]
        elif parts[0].startswith("STAGE34_NATIVE_REMOTE_NINE_ASSERTIONS="):
            if "".join(parts) != "STAGE34_NATIVE_REMOTE_NINE_ASSERTIONS=131":
                raise AssertionError(f"invalid native marker: {line}")
            markers += 1

    if markers != 1:
        raise AssertionError(f"native marker count={markers}")
    if set(found) != set(PAIRS):
        raise AssertionError(f"wrong pair set: {set(found) ^ set(PAIRS)}")

    checked = 0
    for key in PAIRS:
        native = found[key]
        oracle = tuple(date(*key))
        assert len(native) == len(oracle) == 5
        for field, actual, expected in zip(FIELDS, native, oracle):
            checked += 1
            if actual != expected:
                raise AssertionError(
                    f"cal={key[0]} target={key[1]} field={field} "
                    f"Ada={actual} Python={expected}"
                )

    assert checked == 125
    print(f"STAGE34_REAL_FIVEFIELD_SCALARS={checked}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: stage34_remote_ten.py --selftest | <log>")
    selftest() if sys.argv[1] == "--selftest" else compare(sys.argv[1])
