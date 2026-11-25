#!/usr/bin/env python3
"""Independent arbitrary-precision oracle for Stage10/DISCOVERY05."""
from __future__ import annotations
import re
import sys
from pathlib import Path

M = (1 << 127) - 1
FOUNDATION = -15_055_671
SEED = [17, 29, 43, 71, 101]
COEFFICIENTS = (
    (3, 4, 6, 8), (5, 7, 10, 12), (7, 10, 14, 16),
    (9, 13, 18, 20), (11, 16, 22, 24), (13, 19, 26, 28),
    (15, 22, 30, 32),
)
GRIND_KINDS = (0, 1, 2, 3, 4, 0, 1)
PAIRS = (
    (0, 0), (-10, 11), (34, -19), (-90_001, -90_001),
    (123_456_789, -987_654_321),
)
CELL_RE = re.compile(
    r"STAGE10_HIDDEN_CELL case=(\d+) k=(\d+) actual=(\d+) expected=(\d+) class=(RED|MATCH)"
)
SLOT_RE = re.compile(r"STAGE10_STORAGE_SLOT case=(\d+) slot=(\d+) value=(\d+)")

def save(x: int) -> int:
    return 1 + ((x - 1) % M)

def day_tag(day: int) -> int:
    if day == FOUNDATION:
        return 1
    if day > FOUNDATION:
        return 2 * (day - FOUNDATION) + 1
    return 2 * (FOUNDATION - day)

def stone_table() -> list[list[int]]:
    rows = [SEED.copy()]
    for i in range(2, 47):
        w, b, s, m, r = rows[-1]
        rows.append([
            save(w*w + 3*b + i),
            save(b*b + 5*s + w),
            save(s*s + 7*m + b),
            save(m*m + 11*r + s),
            save(r*r + 13*w + m),
        ])
    return rows

def logical_hidden(calculation_day: int, target_day: int, stones: list[list[int]]) -> list[int]:
    action = day_tag(calculation_day)
    target = day_tag(target_day)
    distance = abs(target_day - calculation_day) + 1
    connection = action + target
    direction = 1 if target_day < calculation_day else 2 if target_day == calculation_day else 3
    hidden = [0] * 8
    for k in range(1, 8):
        c = COEFFICIENTS[k - 1]
        row = stones[k - 1]
        x = action + target*c[0] + distance*c[1] + connection*c[2] + direction*c[3] + sum(row)
        x = save(x)
        for grind, kind in enumerate(GRIND_KINDS, 1):
            x = save(x*x + 3*x + row[kind] + grind)
        hidden[k] = x
    return hidden

def backward_storage(hidden: list[int]) -> list[int]:
    physical = [0] * 8
    for k in range(1, 8):
        physical[8-k] = hidden[k]
    return physical

def self_test() -> None:
    stones = stone_table()
    hidden = logical_hidden(FOUNDATION, FOUNDATION, stones)
    expected = [
        0,
        119390830530032782664128530203002080344,
        11877236279154673426874867061566696749,
        24217814924229232987463457533828175476,
        166629231917547214614573522551290204247,
        81202913407267092008896220686064041568,
        73551520026920072430116213847585486272,
        6164285870955721082771365327359496898,
    ]
    assert hidden == expected
    physical = backward_storage(hidden)
    assert physical == [0, expected[7], expected[6], expected[5], expected[4], expected[3], expected[2], expected[1]]
    classes = ["MATCH" if physical[k] == hidden[k] else "RED" for k in range(1, 8)]
    assert classes.count("RED") == 6 and classes.count("MATCH") == 1
    assert [classes[k-1] for k in (1,2,4,6,7)].count("RED") == 4
    assert [classes[k-1] for k in (1,2,3,4,7)].count("RED") == 4
    print("STAGE10_DISCOVERY05_ORACLE_SELF_TEST=PASS")

def read_cells(lines: list[str]) -> dict[tuple[int, int], tuple[int, int, str]]:
    parsed = {}
    for line in lines:
        if "STAGE10_HIDDEN_CELL" not in line:
            continue
        match = CELL_RE.fullmatch(line)
        if not match:
            raise SystemExit(f"malformed Stage10 hidden cell: {line}")
        case, k, actual, expected, classification = match.groups()
        key = (int(case), int(k))
        if key in parsed:
            raise SystemExit(f"duplicate Stage10 hidden cell: {key}")
        parsed[key] = (int(actual), int(expected), classification)
    wanted = {(case, k) for case in range(5) for k in range(1, 8)}
    if set(parsed) != wanted:
        raise SystemExit(
            f"Stage10 cell coverage missing={len(wanted-set(parsed))} extra={len(set(parsed)-wanted)}"
        )
    return parsed

def verify(path: Path) -> None:
    lines = path.read_text(encoding="utf-8", errors="strict").splitlines()
    stones = stone_table()
    cells = read_cells(lines)
    all_red = all_match = 0
    for case, (dc, dt) in enumerate(PAIRS):
        hidden = logical_hidden(FOUNDATION + dc, FOUNDATION + dt, stones)
        physical = backward_storage(hidden)
        red = match = 0
        for k in range(1, 8):
            classification = "MATCH" if physical[k] == hidden[k] else "RED"
            if cells[(case, k)] != (physical[k], hidden[k], classification):
                raise SystemExit(f"Stage10 mismatch case={case} k={k}")
            if classification == "RED":
                red += 1
            else:
                match += 1
        if (red, match) != (6, 1):
            raise SystemExit(f"Stage10 class count case={case}: {red}/{match}")
        all_red += red
        all_match += match

    slots = {}
    for line in lines:
        if "STAGE10_STORAGE_SLOT" not in line:
            continue
        match = SLOT_RE.fullmatch(line)
        if not match:
            raise SystemExit(f"malformed Stage10 storage slot: {line}")
        case, slot, value = match.groups()
        key = (int(case), int(slot))
        if key in slots:
            raise SystemExit(f"duplicate Stage10 storage slot: {key}")
        slots[key] = int(value)
    expected_slots = {(0, slot) for slot in range(8)}
    if set(slots) != expected_slots:
        raise SystemExit("Stage10 storage-slot coverage mismatch")
    first = logical_hidden(FOUNDATION, FOUNDATION, stones)
    physical = backward_storage(first)
    if any(slots[(0, slot)] != physical[slot] for slot in range(8)):
        raise SystemExit("Stage10 physical storage order mismatch")

    markers = (
        "STAGE10_BACKWARD_STORAGE_PASS_7",
        "STAGE10_PATCH04_ROWS_GREEN_230",
        "STAGE10_PRODUCTION_WRONG_K1_PASS",
        "STAGE10_EXPECTED_RED_6_MATCH_1",
        "STAGE10_KOTLIN_SUBSET_RED_4_MATCH_1",
        "STAGE10_V_SUBSET_RED_4_MATCH_1",
        "STAGE10_CONTEXT_GUARDS_REPLAY_PASS",
        "STAGE10_BIGINT_INDEPENDENT_PASS_35",
        "STAGE10_BIGINT_PATCH04_STONES_GREEN_175",
        "STAGE10_EARLIER_ROUTES_PASS",
        "STAGE10_COMPLETE_EXPECTED_RED",
        "STAGE10_STRICT_RED_CONFIRMED=PASS",
    )
    for marker in markers:
        if marker not in lines:
            raise SystemExit(f"missing Stage10 marker {marker}")
    if (all_red, all_match) != (30, 5):
        raise SystemExit("Stage10 aggregate class mismatch")
    print("STAGE10_DISCOVERY05_ORACLE=PASS CELLS=35 RED=30 MATCH=5 STORAGE=8")

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
    elif len(sys.argv) == 2:
        verify(Path(sys.argv[1]))
    else:
        raise SystemExit("usage: stage10_discovery05_hidden_oracle.py --self-test | <native-stdout-file>")
