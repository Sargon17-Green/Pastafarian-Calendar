#!/usr/bin/env python3
"""Native394 differential gate-gap test against the independent Host oracle."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

from test_rom import (
    SUCCESS,
    UNIMPLEMENTED,
    check_header,
    discover_case_high_byte,
    wait_for_completion,
)
from test_sm83_stage1_sauce_oracle import FOUNDATION, compute_sauce
from test_sm83_stage1_selection_oracle import bowl_answer_flow, gate_gap, select

CASES = ((1, 1), (1, 2), (512, 1), (512, 2))
RECORD_SIZE = 40


def discover_symbols(symbol_path: Path) -> dict[str, int]:
    wanted = {
        "wNative394ResultCount",
        "wCalendarGateGapNativeResults",
        "wCalendarGateGapResult",
        "wCalendarActive",
        "wCalendarStatus",
        "wLeaseTable",
    }
    found: dict[str, int] = {}
    for line in symbol_path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(
            r"([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)",
            line.strip(),
        )
        if match is None or match.group(3) not in wanted:
            continue
        bank = int(match.group(1), 16)
        address = int(match.group(2), 16)
        name = match.group(3)
        assert bank == 0, f"{name}: expected WRAM bank 00, found {bank:02X}"
        assert name not in found, f"duplicate linker symbol {name}"
        found[name] = address
    assert set(found) == wanted, f"missing WRAM symbols: {sorted(wanted - set(found))}"
    return found


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    check_header(path.read_bytes())
    high = discover_case_high_byte(path.with_suffix(".sym"))
    symbols = discover_symbols(path.with_suffix(".sym"))

    try:
        from pyboy import PyBoy
    except ImportError as exc:
        raise SystemExit("BLOCKED: pip install 'pyboy>=2,<3' for Native394") from exc

    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)

        def read(name: str, size: int) -> bytes:
            address = symbols[name]
            return bytes(int(boy.memory[address + i]) for i in range(size))

        result, case, dispatch, frames = wait_for_completion(
            boy, max_frames=120000, high_byte_address=high
        )
        print(
            f"NATIVE394_STATUS={result:02X} LAST_TEST_CASE={case} "
            f"DISPATCH_STATUS={dispatch:02X} FRAMES={frames}",
            flush=True,
        )
        assert (result, case, dispatch) == (SUCCESS, 394, UNIMPLEMENTED)

        count = read("wNative394ResultCount", 1)[0]
        assert count == len(CASES), f"Native394 recorded {count}/{len(CASES)} gap results"
        records = read("wCalendarGateGapNativeResults", RECORD_SIZE * count)

        for i, (wanted_index, wanted_direction) in enumerate(CASES):
            record = records[i * RECORD_SIZE:(i + 1) * RECORD_SIZE]
            index = int.from_bytes(record[0:2], "little")
            direction = record[2]
            actual_gap = int.from_bytes(record[3:5], "little")
            actual_a0 = int.from_bytes(record[5:21], "little")
            actual_direction = record[21]
            actual_rank = int.from_bytes(record[22:24], "little")
            actual_accepted = int.from_bytes(record[24:40], "little")

            assert (index, direction) == (wanted_index, wanted_direction), (
                f"case {i}: Native input echo {(index, direction)} != "
                f"{(wanted_index, wanted_direction)}"
            )
            target = FOUNDATION + (index if direction == 1 else -index)
            sauce = compute_sauce(FOUNDATION, target)
            flow = bowl_answer_flow(sauce, 1, 1)
            choice = select(flow, 922)
            expected_gap = choice.rank + 41
            expected_direction = 1 if flow.step == 1 else 0xFF
            assert gate_gap(index, direction == 1) == expected_gap, (
                f"Host gate_gap and Host A0/rank paths disagree at n={index}, dir={direction}"
            )
            assert actual_a0 == flow.first, (
                f"n={index}, dir={direction}: A0 {actual_a0:032x} != {flow.first:032x}"
            )
            assert actual_direction == expected_direction, (
                f"n={index}, dir={direction}: direction {actual_direction:02x} "
                f"!= {expected_direction:02x}"
            )
            assert actual_rank == choice.rank, (
                f"n={index}, dir={direction}: rank {actual_rank} != {choice.rank}"
            )
            assert actual_accepted == choice.accepted_word, (
                f"n={index}, dir={direction}: accepted A_k mismatch"
            )
            assert actual_gap == expected_gap and 42 <= actual_gap <= 963, (
                f"n={index}, dir={direction}: gap {actual_gap} != {expected_gap}"
            )
            print(
                f"NATIVE394_GAP=PASS n={index} direction={direction} "
                f"A0={actual_a0:032x} answer_dir={actual_direction:02x} "
                f"rank={actual_rank} gap={actual_gap}",
                flush=True,
            )

        assert read("wCalendarActive", 1)[0] == 0, "invocation remained active after abort"
        assert read("wLeaseTable", 4)[3] == 0, "owner lease was not released"
        assert read("wCalendarStatus", 1)[0] == 6, "final idle call did not return status 6"
        assert read("wCalendarGateGapResult", 2) == b"\x5a\x5a", (
            "idle call changed the published gate-gap result"
        )
        print(
            f"STAGE1_GATE_GAP_NATIVE=PASS vectors={count} frames={frames} "
            "seal1_A0_direction_rank_Ak=DIFFERENTIAL "
            "bounds_invalid_idle_pair_restore_input_restore_owner_lease_SRAM=CHECKED",
            flush=True,
        )
    finally:
        boy.stop()


if __name__ == "__main__":
    main()
