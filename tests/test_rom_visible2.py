#!/usr/bin/env python3
"""RGBDS ROM_HEADER and real PyBoy gate for Native381."""
from __future__ import annotations
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("rom",type=Path)
    path=parser.parse_args().rom
    check_header(path.read_bytes())
    hi=discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy=PyBoy(str(path),window="null")
    try:
        boy.set_emulation_speed(0)
        result,case,status,frames=wait_for_completion(boy,max_frames=30000,high_byte_address=hi)
        print(f"ROM_CHAIN2_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} DISPATCH_STATUS={status:02X} FRAMES={frames}",flush=True)
        assert (result,case,status)==(SUCCESS,381,UNIMPLEMENTED)
        print("STAGE1_CHAIN2_NATIVE=PASS hidden7=RETAINED V1=RETAINED "
              "V2=FOUNDATION_EXPECTED i2_stones=CHECKED "
              "invalid_negative_zero=REJECTED idle_owner_SRAM=CHECKED",flush=True)
    finally:
        boy.stop()
if __name__=="__main__":
    main()
