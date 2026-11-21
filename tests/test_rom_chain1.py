#!/usr/bin/env python3
"""Real PyBoy/ROM_HEADER Native380 gate for hidden-seven/visible-one chain."""
from __future__ import annotations
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion
EXPECTED_CASE = 380
MAX_FRAMES = 30000

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("rom",type=Path)
    path=parser.parse_args().rom
    check_header(path.read_bytes())
    hi=discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy=PyBoy(str(path),window="null")
    try:
        boy.set_emulation_speed(0)
        result,case,status,frames=wait_for_completion(boy,max_frames=MAX_FRAMES,high_byte_address=hi)
        print(f"ROM_CHAIN1_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} DISPATCH_STATUS={status:02X} FRAMES={frames}",flush=True)
        assert (result,case,status)==(SUCCESS,EXPECTED_CASE,UNIMPLEMENTED)
        print("STAGE1_CHAIN1_NATIVE=PASS hidden1to7=RETAINED visible1=FOUNDATION_EXPECTED "
              "negative_zero=REJECTED idle=IMMUTABLE owner_and_SRAM=CHECKED",flush=True)
    finally:
        boy.stop()

if __name__=="__main__":
    main()
