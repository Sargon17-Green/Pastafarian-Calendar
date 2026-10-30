#!/usr/bin/env python3
"""Inspect a real DMG ROM and wait for execution of its SM83 test harness."""
from __future__ import annotations

import argparse
from pathlib import Path

MAX_BOOT_AND_TEST_FRAMES = 7200
WRAM_RESULT = 0xC000
WRAM_TEST_CASE = 0xC001
WRAM_DISPATCH = 0xC002
SUCCESS = 0xA5
FAILURE = 0xE0
UNIMPLEMENTED = 0x40
TOTAL_CASES = 183


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


def wait_for_completion(boy: object, max_frames: int = MAX_BOOT_AND_TEST_FRAMES) -> tuple[int, int, int, int]:
    """Poll the actual ROM completion markers, not an arbitrary initial frame."""
    if max_frames < 1:
        raise ValueError("max_frames must be positive")
    previous_case = 0
    for frame in range(1, max_frames + 1):
        boy.tick(1, render=False, sound=False)
        result = int(boy.memory[WRAM_RESULT])
        case = int(boy.memory[WRAM_TEST_CASE])
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
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        result, case, stage, frame = wait_for_completion(boy)
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
