#!/usr/bin/env python3
"""Stage14: independent synthetic five-field numerical composition oracle.

This intentionally does NOT claim to compute the full real Calendar_Date:
year/gates, cutlet partition, month lengths/names and sealed stream are
synthetic inputs. The independent algorithm uses expanded occurrences,
Python list.pop and bisect, not Ada Month_Weaving.From_Choices.
"""
from bisect import bisect_left
from dataclasses import dataclass
from typing import Tuple

Five = Tuple[int, int, int, int, int]

@dataclass(frozen=True)
class Structure:
    year: int
    gates: Tuple[int, ...]
    cutlet_names: Tuple[int, ...]
    lengths: Tuple[int, ...]
    month_names: Tuple[int, ...]
    picks: Tuple[int, ...]

def five_fields(s: Structure, target: int) -> Five:
    """Independent numerical projection from explicit structural witnesses."""
    m = len(s.lengths)
    if not m or len(s.month_names) != m:
        raise ValueError("invalid month-name cardinality")
    if len(s.gates) != len(s.cutlet_names) + 1:
        raise ValueError("invalid cutlet-name cardinality")
    if len(set(s.month_names)) != m or len(set(s.cutlet_names)) != len(s.cutlet_names):
        raise ValueError("canonical labels must be distinct")
    if any(b <= a for a, b in zip(s.gates, s.gates[1:])):
        raise ValueError("gate order is not strict")
    if any(n < 2 for n in s.lengths):
        raise ValueError("each month needs opening and closing occurrences")
    if sum(s.lengths) != s.gates[-1] - s.gates[0]:
        raise ValueError("year length mismatch")
    available = [
        canonical for canonical, length in enumerate(s.lengths, start=1)
        for _ in range(length - 2)
    ]
    if len(s.picks) != len(available):
        raise ValueError("incorrect ticket count")
    sequence = list(range(1, m + 1))
    for ticket in s.picks:
        if ticket < 1 or ticket > len(available):
            raise ValueError("ticket exceeds the remaining occurrences")
        sequence.append(available.pop(ticket - 1))
    sequence.extend(range(1, m + 1))
    if available or len(sequence) != sum(s.lengths):
        raise ValueError("weave does not conserve the multiplicities")
    if not (s.gates[0] < target <= s.gates[-1]):
        raise ValueError("target outside the modeled year")
    cutlet = bisect_left(s.gates, target) - 1
    offset = target - s.gates[0] - 1
    mid = sequence[offset]
    return (
        s.year, s.cutlet_names[cutlet], target - s.gates[cutlet],
        s.month_names[mid - 1], sequence[:offset + 1].count(mid),
    )

def run() -> None:
    checked = 0
    def check(observed: Five, expected: Five, name: str) -> None:
        nonlocal checked
        for index, (left, right) in enumerate(zip(observed, expected), 1):
            checked += 1
            if left != right:
                raise AssertionError(
                    f"{name}: field {index}: got {left}; expected {right}"
                )

    small = Structure(
        year=5000,
        gates=(1000, 1002, 1005, 1008, 1010, 1013),
        cutlet_names=(9, 2, 17, 6, 4),
        lengths=(4, 5, 4),
        month_names=(11, 7, 23),
        picks=(3, 4, 2, 1, 3, 2, 1),
    )
    # Literal witnesses derived by separately enumerating the 13-day sequence
    # and counting each month occurrence. None comes from Ada Calendar_Date.
    cases = (
        (1001, (5000, 9, 1, 11, 1)),
        (1002, (5000, 9, 2, 7, 1)),
        (1003, (5000, 2, 1, 23, 1)),
        (1004, (5000, 2, 2, 7, 2)),
        (1005, (5000, 2, 3, 7, 3)),
        (1007, (5000, 17, 2, 11, 3)),
        (1009, (5000, 6, 1, 23, 3)),
        (1011, (5000, 4, 1, 11, 4)),
        (1013, (5000, 4, 3, 23, 4)),
    )
    for day, expected in cases:
        check(five_fields(small, day), expected, f"small:{day}")

    months = 45
    total = months * 94
    inside = total - 2 * months
    shared = dict(
        year=5000,
        gates=(0, 846, 1692, 2538, 3384, 4230),
        cutlet_names=(3, 7, 9, 11, 15),
        lengths=(94,) * months,
        month_names=tuple(range(46, 1, -1)),
    )
    first = Structure(**shared, picks=(1,) * inside)
    last = Structure(**shared, picks=tuple(range(inside, 0, -1)))
    # Closed-form rail witnesses, including the first interior slot after
    # the 45 opening positions; independent of arbitrary ranking choices.
    check(five_fields(first, 1), (5000, 3, 1, 46, 1), "large:first")
    check(five_fields(first, 4230), (5000, 15, 846, 2, 94), "large:last")
    check(five_fields(last, 46), (5000, 3, 46, 2, 2), "large:reverse")

    try:
        five_fields(Structure(**shared, picks=(inside + 1,) + (1,) * (inside - 1)), 1)
    except ValueError:
        checked += 1
    else:
        raise AssertionError("out-of-range ticket was not rejected")

    if checked != 61:
        raise AssertionError(f"wrong assertion count: {checked}")
    print(f"STAGE14_SYNTHETIC_FIVEFIELD_ASSERTIONS={checked}")

if __name__ == "__main__":
    run()
