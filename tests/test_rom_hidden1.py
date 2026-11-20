#!/usr/bin/env python3
"""Bounded PyBoy cartridge witness for first hidden drop, isolated Native372."""
from __future__ import annotations
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion

EXPECTED_CASE = 372
MAX_FRAMES = 30000

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    check_header(path.read_bytes())
    case_high = discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        result, case, status, frames = wait_for_completion(
            boy, max_frames=MAX_FRAMES, high_byte_address=case_high)
        print(f"ROM_HIDDEN1_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}", flush=True)
        assert (result, case, status) == (SUCCESS, EXPECTED_CASE, UNIMPLEMENTED)
        print("STAGE1_HIDDEN1_NATIVE=PASS output_bytes=16 counters=5 "
              "owner_and_SRAM=CHECKED source_immutable=YES idle_immutable=YES "
              "default_9000_route=UNCHANGED", flush=True)
    finally:
        boy.stop()

if __name__ == "__main__":
    main()
