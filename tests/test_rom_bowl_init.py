#!/usr/bin/env python3
"""Isolated real Native389 PyBoy execution gate."""
from pathlib import Path
import argparse
from test_rom import SUCCESS,UNIMPLEMENTED,check_header,discover_case_high_byte,wait_for_completion

def main():
    p=argparse.ArgumentParser()
    p.add_argument("rom",type=Path)
    path=p.parse_args().rom
    check_header(path.read_bytes())
    hi=discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy=PyBoy(str(path),window="null")
    try:
        boy.set_emulation_speed(0)
        result,case,status,frames=wait_for_completion(
            boy,max_frames=30000,high_byte_address=hi)
        print(f"ROM_BOWL_INIT_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}",flush=True)
        assert (result,case,status)==(SUCCESS,389,UNIMPLEMENTED)
        print("STAGE1_BOWL_INIT_NATIVE=PASS six_initial_bowls=CHECKED "
              "signed32_edges=CHECKED invalid_idle_owner_SRAM=CHECKED",flush=True)
    finally:
        boy.stop()

if __name__=="__main__":
    main()
