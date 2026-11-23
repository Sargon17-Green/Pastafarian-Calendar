#!/usr/bin/env python3
"""Isolated PyBoy Native391 12-retained-post-stirs gate."""
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    check_header(path.read_bytes())
    high = discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        result, case, status, frames = wait_for_completion(
            boy, max_frames=120000, high_byte_address=high)
        print(f"ROM_POSTSTIRS_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}", flush=True)
        assert (result, case, status) == (SUCCESS, 391, UNIMPLEMENTED)
        print("STAGE1_POSTSTIRS_NATIVE=PASS rounds=12 retained_sums=CHECKED "
              "final_six_bowls=CHECKED orderAt46=RETAINED "
              "invalid_round_negative_zero_idle_owner_lease_SRAM=CHECKED", flush=True)
    finally:
        boy.stop()


if __name__ == "__main__":
    main()
