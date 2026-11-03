#!/usr/bin/env python3
"""Inspect a real DMG ROM and wait for execution of its SM83 test harness."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

# Cases 242-247 cover positive full-capacity boundaries; 248-255 cover
# fragmented-owner aliases and both mixed-sign high-zero invalid orientations.
# Cases 256-260 assert 16-bit ABI transition and both stale-owner operand positions.
# Case 261: independently revoked owners; 262: live max-owner comparison;
# 263: revoked max-owner zero versus live zero; 264: reverse operands.
# 265: revoked B negative-zero; all three verify SRAM sentinels.
# Keep the measured 9000-frame cap.
MAX_BOOT_AND_TEST_FRAMES = 9000
WRAM_RESULT = 0xC000
WRAM_TEST_CASE = 0xC001
WRAM_DISPATCH = 0xC002
SUCCESS = 0xA5
FAILURE = 0xE0
UNIMPLEMENTED = 0x40
TOTAL_CASES = 265


def discover_case_high_byte(symbol_path: Path) -> int:
    """Read the real RGBDS linker map; reject unverified WRAM aliases."""
    names = ("wTestResult", "wTestCase", "wRunStatus", "wTestCaseHi")
    found: dict[str, int] = {}
    for line in symbol_path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)", line.strip())
        if match is None or match.group(3) not in names:
            continue
        bank = int(match.group(1), 16)
        address = int(match.group(2), 16)
        name = match.group(3)
        assert bank == 0, f"{name}: expected WRAM bank 00, found {bank:02X}"
        assert name not in found, f"duplicate linker symbol {name}"
        found[name] = address
    assert set(found) == set(names), f"missing linker symbols: {sorted(set(names) - set(found))}"
    assert (found["wTestResult"], found["wTestCase"], found["wRunStatus"]) == (
        WRAM_RESULT, WRAM_TEST_CASE, WRAM_DISPATCH
    ), f"legacy test ABI changed: {found}"
    high_address = found["wTestCaseHi"]
    assert 0xC003 <= high_address <= 0xCFFF, (
        f"high case byte must occupy unused WRAM0 above C002: {high_address:04X}"
    )
    assert high_address not in (WRAM_RESULT, WRAM_TEST_CASE, WRAM_DISPATCH)
    return high_address


def check_header(data: bytes) -> None:
    assert len(data) == 32768, f"expected 32 KiB ROM; got {len(data)} bytes"
    assert data[0x143] == 0, "not a pure DMG cartridge"
    assert data[0x147] == 0x1A, "expected MBC5+RAM cartridge"
    assert data[0x148] == 0, "expected 32 KiB ROM size encoding"
    assert data[0x149] == 0x04, "expected 128 KiB cartridge SRAM"
    checksum = 0
    for b in data[0x134:0x14D]:
        checksum = (checksum - b - 1) & 0xFF
    assert data[0x14D] == checksum, "incorrect header checksum"
    actual_global = (sum(data) - data[0x14E] - data[0x14F]) & 0xFFFF
    stored_global = (data[0x14E] << 8) | data[0x14F]
    assert stored_global == actual_global, "incorrect global checksum"
    print("ROM_HEADER=PASS DMG=YES MBC=MBC5_RAM_128K", flush=True)


def wait_for_completion(boy: object, max_frames: int = MAX_BOOT_AND_TEST_FRAMES, *, high_byte_address: int | None = None) -> tuple[int, int, int, int]:
    """Poll the actual ROM completion markers, not an arbitrary initial frame."""
    if max_frames < 1:
        raise ValueError("max_frames must be positive")
    previous_case = 0
    for frame in range(1, max_frames + 1):
        boy.tick(1, render=False, sound=False)
        result = int(boy.memory[WRAM_RESULT])
        case_low = int(boy.memory[WRAM_TEST_CASE])
        case_high = int(boy.memory[high_byte_address]) if high_byte_address is not None else 0
        case = (case_high << 8) | case_low
        stage = int(boy.memory[WRAM_DISPATCH])
        if case != previous_case:
            print(f"ROM_PROGRESS_FRAME={frame} CASE={case}", flush=True)
            previous_case = case
        if stage == UNIMPLEMENTED and result in (SUCCESS, FAILURE):
            return result, case, stage, frame
    raise AssertionError(
        f"ROM did not signal completion within {max_frames} frames; "
        f"last_result={result:02X} last_case={case} last_dispatch={stage:02X}"
    )


def check_emulator(path: Path) -> None:
    try:
        from pyboy import PyBoy
    except ImportError as exc:
        raise SystemExit("BLOCKED: pip install 'pyboy>=2,<3' for SM83 execution") from exc
    high_byte_address = discover_case_high_byte(path.with_suffix(".sym"))
    print(f"ROM_CASE_HIGH_SYMBOL=PASS ADDRESS={high_byte_address:04X}", flush=True)
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        result, case, stage, frame = wait_for_completion(boy, high_byte_address=high_byte_address)
        print(
            f"ROM_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
            f"DISPATCH_STATUS={stage:02X} FRAMES={frame}",
            flush=True,
        )
        assert result == SUCCESS, f"SM83 self-test failed at case {case}"
        assert case == TOTAL_CASES, f"SM83 finished only {case}/{TOTAL_CASES} cases"
        assert stage == UNIMPLEMENTED, "calendar dispatcher must refuse a date"
        print("STAGE1_ARITHMETIC_SMOKE=PASS")
    finally:
        boy.stop()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    args = parser.parse_args()
    check_header(args.rom.read_bytes())
    check_emulator(args.rom)


if __name__ == "__main__":
    main()
