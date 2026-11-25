#!/usr/bin/env python3
"""Independent arbitrary-precision oracle for Stage08/DISCOVERY04 stone discovery."""
from __future__ import annotations
import re
import sys
from pathlib import Path

MODULUS = (1 << 127) - 1
SEED = [17, 29, 43, 71, 101]
FIELDS = ("w", "b", "s", "m", "r")
CELL_RE = re.compile(
    r"STAGE08_STONE_CELL row=(\d+) field=([wbsmr]) legacy=(\d+) expected=(\d+) class=(RED|MATCH)"
)

def save(value: int) -> int:
    return 1 + ((value - 1) % MODULUS)

def snapshot_next(old: list[int], i: int) -> list[int]:
    w, b, s, m, r = old
    return [save(w*w+3*b+i), save(b*b+5*s+w), save(s*s+7*m+b),
            save(m*m+11*r+s), save(r*r+13*w+m)]

def sequential_next(previous: list[int], i: int) -> list[int]:
    current = previous.copy()
    current[0] = save(current[0]*current[0]+3*current[1]+i)
    current[1] = save(current[1]*current[1]+5*current[2]+current[0])
    current[2] = save(current[2]*current[2]+7*current[3]+current[1])
    current[3] = save(current[3]*current[3]+11*current[4]+current[2])
    current[4] = save(current[4]*current[4]+13*current[0]+current[3])
    return current

def expected_tables() -> tuple[list[list[int]], list[list[int]]]:
    snapshot = [SEED.copy()]
    sequential = [SEED.copy()]
    for i in range(2, 47):
        snapshot.append(snapshot_next(snapshot[-1], i))
        sequential.append(sequential_next(sequential[-1], i))
    return sequential, snapshot

def self_test() -> None:
    sequential, snapshot = expected_tables()
    if sequential[1] != [378, 1434, 3780, 9932, 25047]:
        raise SystemExit("sequential row-2 witness changed")
    if snapshot[1] != [378, 1073, 2375, 6195, 10493]:
        raise SystemExit("snapshot row-2 witness changed")
    red = sum(sequential[r][c] != snapshot[r][c] for r in range(1, 46) for c in range(5))
    if (len(sequential), red, 225-red) != (46, 224, 1):
        raise SystemExit("Stage08 expected-RED classification changed")
    print("STAGE08_DISCOVERY04_ORACLE_SELF_TEST=PASS")

def verify_output(path: Path) -> None:
    lines = path.read_text(encoding="utf-8", errors="strict").splitlines()
    row_lines = [line for line in lines if "STAGE08_STONE_CELL" in line]
    if len(row_lines) != 225:
        raise SystemExit(f"expected 225 stone cells, got {len(row_lines)}")
    sequential, snapshot = expected_tables()
    observed: dict[tuple[int, str], tuple[int, int, str]] = {}
    for line in row_lines:
        m = CELL_RE.fullmatch(line)
        if not m:
            raise SystemExit(f"malformed stone cell: {line}")
        row, field = int(m.group(1)), m.group(2)
        key = (row, field)
        if key in observed:
            raise SystemExit(f"duplicate stone cell: {key}")
        observed[key] = (int(m.group(3)), int(m.group(4)), m.group(5))
    expected_keys = {(row, field) for row in range(2, 47) for field in FIELDS}
    if set(observed) != expected_keys:
        raise SystemExit(
            f"coverage mismatch missing={len(expected_keys-set(observed))} extra={len(set(observed)-expected_keys)}"
        )
    red = matches = 0
    for row in range(2, 47):
        for column, field in enumerate(FIELDS):
            classification = "MATCH" if sequential[row-1][column] == snapshot[row-1][column] else "RED"
            wanted = (sequential[row-1][column], snapshot[row-1][column], classification)
            actual = observed[(row, field)]
            if actual != wanted:
                raise SystemExit(f"oracle mismatch row={row} field={field}: {actual} != {wanted}")
            red += classification == "RED"
            matches += classification == "MATCH"
    required = (
        "STAGE08_STONE_SEED=17,29,43,71,101",
        "STAGE08_DISCOVERY04_ROWS=46 CELLS=230",
        "STAGE08_DISCOVERY04_EXPECTED_RED=224 MATCH=1 UNEXPECTED=0 GUARDS=4",
        "STAGE08_DISCOVERY04_BOOTSTRAP_ONLY=PASS",
    )
    for marker in required:
        if marker not in lines:
            raise SystemExit(f"missing Native marker: {marker}")
    if (red, matches) != (224, 1):
        raise SystemExit(f"unexpected classification RED={red} MATCH={matches}")
    print(f"STAGE08_DISCOVERY04_ORACLE=PASS ROWS=225 RED={red} MATCH={matches} GUARDS=4")

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--self-test":
        self_test()
    elif len(sys.argv) == 2:
        verify_output(Path(sys.argv[1]))
    else:
        raise SystemExit("usage: stage08_discovery04_stone_oracle.py --self-test | <native-stdout-file>")
