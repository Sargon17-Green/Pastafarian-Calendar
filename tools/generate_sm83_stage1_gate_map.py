#!/usr/bin/env python3
"""Generate the bounded SM83 Stage1 gate map from the independent Host oracle."""
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests"))

from test_sm83_stage1_year_path_oracle import FOUNDATION, MAX_GATE_STEPS, gate_at  # noqa: E402

ENTRY_COUNT = 2 * MAX_GATE_STEPS + 1


def render() -> tuple[bytes, bytes]:
    values = [gate_at(index) - FOUNDATION for index in range(-MAX_GATE_STEPS, MAX_GATE_STEPS + 1)]
    assert len(values) == ENTRY_COUNT == 1025
    assert values[MAX_GATE_STEPS] == 0
    assert all(-(1 << 31) <= value < (1 << 31) for value in values)
    assert all(values[i] < values[i + 1] for i in range(len(values) - 1))
    gaps = [values[i + 1] - values[i] for i in range(len(values) - 1)]
    assert all(42 <= gap <= 963 for gap in gaps)
    foundation_raw = (FOUNDATION & 0xFFFFFFFF).to_bytes(4, "little")
    lines = [
        'DEF CALENDAR_GATE_YEAR_FOUNDATION_B' + str(i) + ' EQU $' + f"{byte:02X}"
        for i, byte in enumerate(foundation_raw)
    ]
    lines.append("CalendarGateYearMap::")
    for index, value in zip(range(-MAX_GATE_STEPS, MAX_GATE_STEPS + 1), values):
        raw = (value & 0xFFFFFFFF).to_bytes(4, "little")
        lines.append("    db " + ", ".join('$' + f"{byte:02X}" for byte in raw) + f" ; gate_index={index}")
    table_bytes = b"".join((value & 0xFFFFFFFF).to_bytes(4, "little") for value in values)
    return ("\n".join(lines) + "\n").encode("ascii"), table_bytes


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    data, table_bytes = render()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    print(
        "HOST_STAGE1_GATE_MAP_GENERATED=PASS "
        f"entries={ENTRY_COUNT} bytes={ENTRY_COUNT * 4} "
        f"sha256={hashlib.sha256(table_bytes).hexdigest()} "
        "index_range=-512..512 gap_bounds=42..963",
        flush=True,
    )


if __name__ == "__main__":
    main()
