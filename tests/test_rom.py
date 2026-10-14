#!/usr/bin/env python3
"""Host-side DMG ROM inspector; does not implement calendar semantics."""
from __future__ import annotations
import argparse
from pathlib import Path

def check_header(data: bytes) -> None:
    assert len(data) == 32768, f"expected 32 KiB ROM; got {len(data)} bytes"
    assert data[0x143] == 0, "not a pure DMG cartridge"
    assert data[0x147] == 0, "expected ROM-only cartridge"
    assert data[0x148] == 0, "expected 32 KiB ROM size encoding"
    assert data[0x149] == 0, "expected no cartridge SRAM"
    checksum = 0
    for b in data[0x134:0x14D]:
        checksum = (checksum - b - 1) & 0xFF
    assert data[0x14D] == checksum, "incorrect header checksum"
    actual_global = (sum(data) - data[0x14E] - data[0x14F]) & 0xFFFF
    stored_global = (data[0x14E] << 8) | data[0x14F]
    assert stored_global == actual_global, "incorrect global checksum"
    print("ROM_HEADER=PASS DMG=YES MBC=ROM_ONLY")

def check_emulator(path: Path) -> None:
    try:
        from pyboy import PyBoy
    except ImportError as exc:
        raise SystemExit("BLOCKED: pip install 'pyboy>=2,<3' for native execution") from exc
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        boy.tick(30, render=False, sound=False)
        result = boy.memory[0xC000]
        case = boy.memory[0xC001]
        stage = boy.memory[0xC002]
        print(f"ROM_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} DISPATCH_STATUS={stage:02X}")
        assert result == 0xA5, f"SM83 self-test failed at case {case}"
        assert case == 22, "SM83 did not run all 22 test cases"
        assert stage == 0x40, "production dispatcher must explicitly refuse a date"
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
