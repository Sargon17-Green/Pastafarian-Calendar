#!/usr/bin/env python3
"""Real Native392 end-to-end PyBoy gate; not a synthetic host test."""
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion

def main():
    p=argparse.ArgumentParser()
    p.add_argument("rom",type=Path)
    path=p.parse_args().rom
    check_header(path.read_bytes())
    high=discover_case_high_byte(path.with_suffix(".sym"))
    from pyboy import PyBoy
    boy=PyBoy(str(path),window="null")
    try:
        boy.set_emulation_speed(0)
        result,case,status,frames=wait_for_completion(boy,max_frames=120000,high_byte_address=high)
        print(f"ROM_BOWL_ANSWER_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}",flush=True)
        assert (result,case,status)==(SUCCESS,392,UNIMPLEMENTED)
        print("STAGE1_BOWL_ANSWER_NATIVE=PASS A0_direction=CHECKED "
              "invalid_idle_owner_lease_SRAM=CHECKED",flush=True)
    finally: boy.stop()

if __name__=="__main__": main()
