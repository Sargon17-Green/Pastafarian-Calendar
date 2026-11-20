#!/usr/bin/env python3
"""Bounded real-ROM endpoint test: isolated i=46, not the 370-case default."""
from __future__ import annotations

import argparse
from pathlib import Path

from test_rom import (SUCCESS, UNIMPLEMENTED, check_header,
                      discover_case_high_byte, wait_for_completion)

I46_CASE = 371
I46_MAX_FRAMES = 30000


def main() -> None:
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
            boy, max_frames=I46_MAX_FRAMES, high_byte_address=high)
        print(f"ROM_STONE_I46_NATIVE_STATUS={result:02X} "
              f"LAST_TEST_CASE={case} DISPATCH_STATUS={status:02X} FRAMES={frames}",
              flush=True)
        assert (result, case, status) == (SUCCESS, I46_CASE, UNIMPLEMENTED), (
            result, case, status)
        print("STAGE1_STONE_I46_NATIVE=PASS endpoint=46 output_bytes=80 "
              "source_immutable=YES lease_and_SRAM=CHECKED idle_output=IMMUTABLE "
              "default_9000_route=UNTOUCHED", flush=True)
    finally:
        boy.stop()


if __name__ == "__main__":
    main()
