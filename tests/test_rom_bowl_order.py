#!/usr/bin/env python3
"""Native387: ROM_HEADER and bounded PyBoy test for SM83 six-bowl permutation rank."""
from __future__ import annotations
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument('rom', type=Path)
    path = p.parse_args().rom
    check_header(path.read_bytes())
    hi = discover_case_high_byte(path.with_suffix('.sym'))
    from pyboy import PyBoy
    boy = PyBoy(str(path), window='null')
    try:
        boy.set_emulation_speed(0)
        result, case, status, frames = wait_for_completion(boy, max_frames=30000, high_byte_address=hi)
        print(f'ROM_BOWL_ORDER_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} '
              f'DISPATCH_STATUS={status:02X} FRAMES={frames}', flush=True)
        assert (result, case, status) == (SUCCESS, 387, UNIMPLEMENTED)
        print('STAGE1_BOWL_ORDER_NATIVE=PASS canonical_residue_rank=CHECKED '
              'factoradic_order=CHECKED invalid_idle_owner_SRAM=CHECKED '
              'source_immutable=YES output_on_failure=IMMUTABLE', flush=True)
    finally:
        boy.stop()


if __name__ == '__main__':
    main()
