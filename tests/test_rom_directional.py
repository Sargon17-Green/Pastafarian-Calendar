#!/usr/bin/env python3
"""Native396: actual-map full-sort differential, no synthetic ranks."""
from __future__ import annotations
import argparse
import hashlib
import re
from pathlib import Path
from struct import pack
from sm83_native396_vectors import vectors, actual_map, MAP_HASH, FOUNDATION
from test_rom_gate_year import check_header, parse_map_include
from test_rom import FAILURE, SUCCESS, UNIMPLEMENTED, WRAM_RESULT, discover_case_high_byte, wait_for_completion

LIMIT = 120000

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    rom = path.read_bytes()
    check_header(rom)
    map_text = path.with_suffix(".map").read_text(encoding="utf-8")
    r0 = re.search(r"ROM0:\s+\d+ bytes used / (\d+) free", map_text)
    rx = re.search(r"ROMX:\s+\d+ bytes used / \d+ free in (\d+) banks?", map_text)
    w0 = re.search(r"WRAM0:\s+\d+ bytes used / (\d+) free", map_text)
    assert r0 and rx and w0
    assert int(r0[1]) >= 10 and int(w0[1]) >= 32 and int(rx[1]) == 3
    print(f"NATIVE396_BUDGET=PASS ROM0_free={r0[1]} WRAM0_free={w0[1]} ROMX_banks={rx[1]}", flush=True)
    sym = {}
    for line in path.with_suffix(".sym").read_text(encoding="utf-8").splitlines():
        m = re.fullmatch(r"([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)", line.strip())
        if m:
            assert m[3] not in sym, m[3]
            sym[m[3]] = (int(m[1], 16), int(m[2], 16))
    for name in ("CalendarDirectionalSelect", "RunCalendarDirectionalBench", "CalendarGateYearSelect"):
        assert sym[name][0] == 3, name
    bank, addr = sym["CalendarGateYearMap"]
    assert bank == 2 and 0x4000 <= addr <= 0x8000-4100
    raw = parse_map_include(path.with_name("calendar_gate_year_map.inc"))
    g = actual_map()
    independent = b"".join(pack("<i", g[i]-FOUNDATION) for i in range(-512,513))
    assert len(raw) == 4100 and raw == independent
    assert hashlib.sha256(raw).hexdigest() == MAP_HASH
    pos = bank*0x4000 + addr-0x4000
    assert rom[pos:pos+len(raw)] == raw
    print(f"HOST_NATIVE396_MAP=PASS entries=1025 sha256={MAP_HASH}", flush=True)
    rows = vectors()
    assert len(rows) == 72
    assert sum(v.status == 0 for v in rows) == 43
    assert sum(v.status == 2 for v in rows) == 29
    assert sum(v.chained for v in rows) == 19
    from pyboy import PyBoy
    boy = PyBoy(str(path), window="null")
    try:
        boy.set_emulation_speed(0)
        def address(name):
            bank, addr = sym[name]
            assert bank == 0 and 0xC000 <= addr < 0xD000, name
            return addr
        def read(name,n):
            addr = address(name)
            return bytes(int(boy.memory[addr+i]) for i in range(n))
        def write(name,data):
            addr = address(name)
            for i,byte in enumerate(data):
                boy.memory[addr+i] = byte
        phase = address("wNative396Phase")
        def wait(value,label):
            for frame in range(1,LIMIT+1):
                boy.tick(1,render=False,sound=False)
                assert int(boy.memory[WRAM_RESULT]) != FAILURE, (label,"assembly failure")
                if int(boy.memory[phase]) == value:
                    return frame
            raise AssertionError((label,"phase timeout",value,LIMIT))
        preserved = {
            "wPairTargetOffset":4, "wCalendarAnswerInputBowl":1,
            "wCalendarAnswerInputSeal":1, "wCalendarSelectCount":2,
            "wCalendarSelectDirection":1, "wCalendarActive":1,
            "wCalendarActiveOwner":1, "wCalendarRequestedOwner":1,
            "wCalendarRequestedBanks":1, "wCalendarOrdinalSign":1,
            "wCalendarOrdinalLength":3, "wLeaseTable":16,
        }
        def caller():
            return {name:read(name,n) for name,n in preserved.items()}
        def sram():
            # Do not select a bank here: check the caller's visible bank too.
            return bytes(int(boy.memory[i]) for i in range(0xA000,0xC000))
        boot_frames = wait(1,"initial idle and lease")
        old_year = bytes([0xA6])*18
        previous = bytes([0x5A])*18
        assert read("wCalendarDirectionalResult",18) == previous
        assert read("wCalendarGateYearResultOpen",18) == old_year
        state = caller()
        assert state["wCalendarActive"] == b"\x01"
        assert state["wCalendarActiveOwner"] == bytes([70])
        assert state["wLeaseTable"][3] == 72
        assert sram()[0] == 0x6E
        # Distinctive entire-bank caller data, not a fabricated publication.
        pattern = bytes(((i*73) ^ (i>>5) ^ 0x6E)&255 for i in range(8192))
        for i,byte in enumerate(pattern):
            boy.memory[0xA000+i] = byte
        assert sram() == pattern
        last_c = None
        total = 0
        maximum = 0
        for v in rows:
            assert caller() == state
            assert read("wCalendarDirectionalResult",18) == previous
            assert read("wCalendarGateYearResultOpen",18) == old_year
            calc = pack("<i",v.calculation)
            prior = v.prior13
            if v.chained:
                assert last_c == v.calculation
                prior = read("wCalendarDirectionalResult",12) + v.prior13[12:]
                assert prior == v.prior13, (v.name,"chain prior")
            write("wPairCalcOffset",calc)
            write("wCalendarDirectionalInput",prior)
            boy.memory[phase] = 2
            elapsed = wait(3,v.name)
            total += elapsed
            maximum = max(maximum,elapsed)
            actual = read("wCalendarDirectionalResult",18)
            status = read("wCalendarStatus",1)[0]
            expected = v.result18 if v.status == 0 else previous
            assert status == v.status, (v.name,status,v.status)
            assert actual == expected, (v.name,actual.hex(),expected.hex())
            assert read("wCalendarDirectionalInput",13) == prior
            assert read("wPairCalcOffset",4) == calc
            assert caller() == state, (v.name,"caller/owner/tags")
            assert sram() == pattern, (v.name,"SRAM or selected bank")
            assert read("wCalendarGateYearResultOpen",18) == old_year
            print(f"NATIVE396_VECTOR name={v.name} c_abs={v.calculation} prior13={prior.hex()} "
                  f"status={status} result18={actual.hex()} expected18={expected.hex()} "
                  f"chained={int(v.chained)} frames={elapsed} caller_owner_lease_sram8192=PASS",flush=True)
            previous = actual
            last_c = v.calculation
            boy.memory[phase] = 4
            wait(1,v.name+" acknowledgement")
        boy.memory[phase] = 5
        end_frames = wait(6,"abort and idle")
        result,case,dispatch,tail = wait_for_completion(boy,max_frames=LIMIT,
            high_byte_address=discover_case_high_byte(path.with_suffix(".sym")))
        assert (result,case,dispatch) == (SUCCESS,396,UNIMPLEMENTED)
        assert read("wCalendarDirectionalResult",18) == previous
        assert read("wCalendarGateYearResultOpen",18) == old_year
        assert read("wCalendarActive",1) == b"\x00"
        assert read("wCalendarStatus",1) == b"\x06"
        assert read("wLeaseTable",16)[3] == 0
        boy.memory[0x0000] = 0x0A
        boy.memory[0x4000] = 3
        assert sram() == bytes(8192), "abort must scrub released bank"
        boy.memory[0x0000] = 0
        print(f"NATIVE396=PASS valid=43 invalid=29 vectors=72 chained=19 "
              f"selection_frames={total} max_case_frames={maximum} limit={LIMIT} "
              "idle_abort_publication_sram=PASS",flush=True)
        print(f"ROM_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={dispatch:02X} FRAMES={boot_frames+end_frames+tail}",flush=True)
    finally:
        boy.stop()

if __name__ == "__main__":
    main()
