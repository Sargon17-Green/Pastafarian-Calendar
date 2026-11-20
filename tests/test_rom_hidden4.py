#!/usr/bin/env python3
"""Bounded PyBoy native cartridge check for k=4 hidden drop, case 375."""
from __future__ import annotations
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion

EXPECTED_CASE = 375
MAX_FRAMES = 30000


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    check_header(path.read_bytes())
    hi = discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        result, case, status, frames = wait_for_completion(
            boy, max_frames=MAX_FRAMES, high_byte_address=hi)
        print(f"ROM_HIDDEN4_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}", flush=True)
        assert (result, case, status) == (SUCCESS, EXPECTED_CASE, UNIMPLEMENTED)
        print("STAGE1_HIDDEN4_NATIVE=PASS k=4 output_bytes=16 "
              "stones_source=IMMUTABLE invalid=REJECTED "
              "owner_and_SRAM=CHECKED idle_output=IMMUTABLE "
              "default_9000_route=UNCHANGED", flush=True)
    finally:
        boy.stop()


if __name__ == "__main__":
    main()
