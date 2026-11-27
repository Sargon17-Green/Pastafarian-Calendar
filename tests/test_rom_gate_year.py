#!/usr/bin/env python3
"""Native395 differential: 1025-entry ROMX bank-2 map and bounded year selector."""
from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

from test_rom import (
    MAX_BOOT_AND_TEST_FRAMES,
    FAILURE,
    WRAM_RESULT,
    SUCCESS,
    TOTAL_CASES,
    UNIMPLEMENTED,
    discover_case_high_byte,
    wait_for_completion,
)
from test_sm83_stage1_year_path_oracle import (
    FOUNDATION,
    YEAR_MAX,
    gate_window,
    year5000,
)


def parse_symbols(path: Path) -> dict[str, tuple[int, int]]:
    found: dict[str, tuple[int, int]] = {}
    wanted = {
        "CalendarGateYearMap",
        "CalendarGateYearSelect",
        "RunCalendarGateYearBench",
        "wCalendarGateYearResultOpen",
        "wCalendarGateYearResultClose",
        "wCalendarGateYearResultSpan",
        "wCalendarGateYearResultCount",
        "wCalendarGateYearResultRank",
        "wCalendarGateYearResultGateCount",
        "wCalendarGateYearResultLeftCount",
        "wCalendarGateYearResultRightCount",
        "wCalendarActive",
        "wCalendarStatus",
        "wLeaseTable",
        "wNative395ExtendedPhase",
        "wPairCalcOffset",
        "wPairTargetOffset",
        "wCalendarAnswerInputBowl",
        "wCalendarAnswerInputSeal",
        "wCalendarSelectCount",
        "wCalendarSelectDirection",
        "wCalendarActiveOwner",
        "wCalendarRequestedOwner",
        "wCalendarRequestedBanks",
        "wCalendarOrdinalSign",
        "wCalendarOrdinalLength",
    }
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\s+([A-Za-z_]\w*)", line.strip())
        if match is None or match.group(3) not in wanted:
            continue
        name = match.group(3)
        assert name not in found, f"duplicate symbol {name}"
        found[name] = (int(match.group(1), 16), int(match.group(2), 16))
    assert set(found) == wanted, f"missing symbols: {sorted(wanted - set(found))}"
    return found


def check_header(data: bytes) -> None:
    assert len(data) == 65536, f"expected four 16-KiB ROM banks; got {len(data)} bytes"
    assert data[0x143] == 0, "not a pure DMG cartridge"
    assert data[0x147] == 0x1A, "expected MBC5+RAM cartridge"
    assert data[0x148] == 1, "expected 64-KiB ROM size encoding"
    assert data[0x149] == 0x04, "expected 128-KiB cartridge SRAM"
    checksum = 0
    for byte in data[0x134:0x14D]:
        checksum = (checksum - byte - 1) & 0xFF
    assert data[0x14D] == checksum, "incorrect header checksum"
    actual_global = (sum(data) - data[0x14E] - data[0x14F]) & 0xFFFF
    stored_global = (data[0x14E] << 8) | data[0x14F]
    assert stored_global == actual_global, "incorrect global checksum"
    print("ROM_HEADER=PASS size=65536 DMG=YES MBC5_RAM_128K", flush=True)


def parse_map_include(path: Path) -> bytes:
    raw = bytearray()
    foundation = {}
    for line in path.read_text(encoding="ascii").splitlines():
        payload = line.split(";", 1)[0].strip()
        if not payload:
            continue
        constant = re.fullmatch(
            r"DEF CALENDAR_GATE_YEAR_FOUNDATION_B([0-3]) EQU \$([0-9A-Fa-f]{2})",
            payload,
        )
        if constant:
            foundation[int(constant.group(1))] = int(constant.group(2), 16)
            continue
        if payload == "CalendarGateYearMap::":
            continue
        assert payload.lower().startswith("db "), f"unexpected map directive: {line}"
        tokens = re.findall(r"\$([0-9A-Fa-f]{2})", payload)
        assert len(tokens) == 4, f"each map row must contain exactly four bytes: {line}"
        raw.extend(int(token, 16) for token in tokens)
    assert set(foundation) == {0, 1, 2, 3}, "missing generated Foundation byte constants"
    assert bytes(foundation[i] for i in range(4)) == (FOUNDATION & 0xFFFFFFFF).to_bytes(4, "little")
    assert len(raw) == 1025 * 4, f"map has {len(raw)//4} entries, expected 1025"
    return bytes(raw)


def check_map_budget(path: Path) -> None:
    content = path.read_text(encoding="utf-8")
    rom0 = re.search(r"ROM0:\s+(\d+) bytes used / (\d+) free", content)
    romx = re.search(r"ROMX:\s+(\d+) bytes used / (\d+) free in (\d+) banks?", content)
    wram = re.search(r"WRAM0:\s+(\d+) bytes used / (\d+) free", content)
    assert rom0 and romx and wram, "missing ROM0/ROMX/WRAM0 linker budget lines"
    assert int(rom0.group(2)) >= 10, f"ROM0 free budget too small: {rom0.group(2)}"
    assert int(romx.group(3)) >= 3, f"expected ROMX banks 1..3, got {romx.group(3)}"
    assert int(wram.group(2)) >= 32, f"WRAM0 free budget too small: {wram.group(2)}"
    print(
        f"NATIVE395_BUDGET=PASS ROM0_free={rom0.group(2)} "
        f"ROMX_banks={romx.group(3)} WRAM0_free={wram.group(2)}",
        flush=True,
    )



def extended_year_vectors() -> list[tuple[str, int, int, bytes]]:
    """Host-only coverage expansion; never use ROM output as an oracle.

    The map boundary is inclusive: equality with its first/last gate is
    sufficient for coverage. The older gate_window requires a strictly
    external gate, so compare against year5000 only in the strict interior.
    All day inputs and published endpoints are absolute signed32; the sauce
    oracle translates absolute days to Foundation-relative work counts.
    """
    from struct import pack
    from test_sm83_stage1_selection_oracle import ask, gate_gap, YEAR_MIN

    # Rebuild both directions iteratively from normative gap selections,
    # independently of the generated include and the runtime histogram.
    negative = [FOUNDATION]
    positive = [FOUNDATION]
    for i in range(1, 513):
        negative.append(negative[-1] - gate_gap(i, False))
        positive.append(positive[-1] + gate_gap(i, True))
    gates = negative[:0:-1] + positive
    assert len(gates) == 1025 and gates[512] == FOUNDATION
    raw = b"".join(pack("<i", g - FOUNDATION) for g in gates)
    assert hashlib.sha256(raw).hexdigest() == (
        "d4bc06694ca0389bac5cc856593c527449f059c81971243c0b481b06f198f407"
    ), "independent recurrence differs from accepted map"
    low, high = gates[0] + YEAR_MAX, gates[-1] - YEAR_MAX
    assert low < FOUNDATION < high
    days = [("foundation", FOUNDATION)]
    for index in (-17, -1, 0, 1, 17):
        for delta in (-1, 0, 1):
            if index == delta == 0:
                continue
            days.append((f"gate{index:+d}_day{delta:+d}", gates[512 + index] + delta))
    days += [("lower_edge", low), ("lower_inside", low + 1),
             ("upper_edge", high), ("upper_inside", high - 1),
             ("lower_outside", low - 1), ("upper_outside", high + 1),
             ("int32_min", -(1 << 31)), ("int32_max", (1 << 31) - 1)]
    vectors = []
    abi_mutants_rejected = 0
    strict_checks = 0
    for name, c in days:
        if not low <= c <= high:
            # Runtime status 2; previous 18-byte publication must survive.
            vectors.append((name, c, 2, b""))
            continue
        window = [(i, g) for i, g in enumerate(gates) if c-YEAR_MAX <= g <= c+YEAR_MAX]
        left = [(i, g) for i, g in window if g < c]
        right = [(i, g) for i, g in window if g >= c]
        pairs = sorted((b-a, a, b) for i, a in left for j, b in right
                       if j-i >= 6 and YEAR_MIN <= b-a <= YEAR_MAX)
        n = len(pairs)
        assert 1 <= n <= 19044 and len(left) <= 138 and len(right) <= 138
        assert len(set(pairs)) == n
        rank = ask(c, c, 1, 10, n).rank
        assert 1 <= rank <= n
        span, opening, closing = pairs[rank-1]
        assert opening < c <= closing and closing-opening == span
        if low < c < high:
            old, old_count, old_rank = year5000(c)
            assert (opening, closing, span, n, rank) == (
                old.open_gate, old.close_gate, old.length, old_count, old_rank)
            strict_checks += 1
        # The old native ABI bug fed c instead of c-F into the sauce;
        # ask(F+c,F+c) reproduces that error in absolute-day oracle terms.
        wrong_rank = ask(FOUNDATION+c, FOUNDATION+c, 1, 10, n).rank
        abi_mutants_rejected += wrong_rank != rank
        payload = pack("<iiHHHHBB", opening, closing, span, n, rank,
                       len(window), len(left), len(right))
        assert len(payload) == 18
        vectors.append((name, c, 0, payload))
    assert len(vectors) == 23
    assert sum(status == 2 for _, _, status, _ in vectors) == 4
    assert strict_checks == 17
    assert abi_mutants_rejected > 0, "suite failed to distinguish absolute/relative ABI mutant"
    assert vectors[0][3] == pack("<iiHHHHBB", -15057703, -15053459, 4244, 43, 15, 21, 11, 10)
    for name, c, status, payload in vectors:
        print(f"HOST_YEAR_VECTOR name={name} c_abs={c} sauce_rel={c-FOUNDATION} "
              f"status={status} result18={payload.hex() if payload else 'UNCHANGED'}", flush=True)
    print(f"HOST_STAGE1_GATE_YEAR_EXTENDED=PASS valid=19 invalid=4 "
          f"strict_crosschecks={strict_checks} abi_mutants_rejected={abi_mutants_rejected} "
          "native_extended=NOT_EXECUTED", flush=True)
    return vectors


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    args = parser.parse_args()
    rom_path = args.rom
    rom = rom_path.read_bytes()
    check_header(rom)
    check_map_budget(rom_path.with_suffix(".map"))
    assert (TOTAL_CASES, MAX_BOOT_AND_TEST_FRAMES) == (370, 9000), "Native370 ABI/frame gate changed"
    symbols = parse_symbols(rom_path.with_suffix(".sym"))
    high_address = discover_case_high_byte(rom_path.with_suffix(".sym"))

    map_bank, map_address = symbols["CalendarGateYearMap"]
    assert map_bank == 2 and 0x4000 <= map_address < 0x8000, (
        f"gate table must reside in ROMX bank 2: {(map_bank, map_address)}"
    )
    assert symbols["CalendarGateYearSelect"][0] == 3
    assert symbols["RunCalendarGateYearBench"][0] == 3
    include_bytes = parse_map_include(rom_path.with_name("calendar_gate_year_map.inc"))
    rom_offset = map_bank * 0x4000 + (map_address - 0x4000)
    assert rom[rom_offset:rom_offset + len(include_bytes)] == include_bytes, (
        "ROMX bank-2 bytes differ from the generated source-derived map"
    )
    values = [
        int.from_bytes(include_bytes[i:i + 4], "little", signed=True)
        for i in range(0, len(include_bytes), 4)
    ]
    assert values[512] == 0
    gaps = [values[i + 1] - values[i] for i in range(1024)]
    assert all(42 <= gap <= 963 for gap in gaps)
    assert all(gaps[i] > 0 for i in range(len(gaps)))
    print(
        "HOST_STAGE1_GATE_MAP=PASS entries=1025 bytes=4100 "
        f"sha256={hashlib.sha256(include_bytes).hexdigest()} "
        f"min_gap={min(gaps)} max_gap={max(gaps)} ROMX_bank=2",
        flush=True,
    )

    chosen, options, rank = year5000(FOUNDATION)
    gates = gate_window(FOUNDATION - YEAR_MAX, FOUNDATION + YEAR_MAX)
    left_count = sum(1 for _, day in gates if day < FOUNDATION)
    right_count = sum(1 for _, day in gates if day >= FOUNDATION)
    assert chosen.open_gate == -15057703
    assert chosen.close_gate == -15053459
    assert chosen.length == 4244 and options == 43 and rank == 15
    print(
        "HOST_STAGE1_GATE_YEAR=PASS candidates=43 rank=15 "
        "open=-15057703 close=-15053459 span=4244 "
        f"window_gates={len(gates)} left={left_count} right={right_count}",
        flush=True,
    )

    vectors = extended_year_vectors()

    try:
        from pyboy import PyBoy
    except ImportError as exc:
        raise SystemExit("BLOCKED: pip install 'pyboy>=2,<3' for Native395") from exc

    boy = PyBoy(str(rom_path), window="null")
    try:
        boy.set_emulation_speed(0)
        # Drive only the isolated ROM test mailbox. The expected publication
        # comes from the independent Host recurrence/full-sort oracle above.
        # Never write expected results into emulator RAM.
        def address(name: str) -> int:
            bank, addr = symbols[name]
            assert bank == 0 and 0xC000 <= addr < 0xD000, (name, bank, addr)
            return addr

        def read_bytes(name: str, size: int) -> bytes:
            addr = address(name)
            return bytes(int(boy.memory[addr + i]) for i in range(size))

        def write_bytes(name: str, payload: bytes) -> None:
            addr = address(name)
            for i, value in enumerate(payload):
                boy.memory[addr + i] = value

        phase = address("wNative395ExtendedPhase")

        def wait_phase(expected: int, limit: int, label: str) -> int:
            for frames_waited in range(1, limit + 1):
                boy.tick(1, render=False, sound=False)
                assert int(boy.memory[WRAM_RESULT]) != FAILURE, (
                    f"{label}: assembly failure before phase {expected}"
                )
                if int(boy.memory[phase]) == expected:
                    return frames_waited
            raise AssertionError(f"{label}: phase {expected} timeout after {limit} frames")

        # Each ready/completed handshake prevents frame polling from missing
        # a fast invalid case. Both the bootstrap and each selection are bounded.
        baseline_frames = wait_phase(1, 120000, "original Foundation baseline")
        assert read_bytes("wCalendarGateYearResultOpen", 18) == vectors[0][3]

        preserved = {
            "wPairTargetOffset": 4,
            "wCalendarAnswerInputBowl": 1,
            "wCalendarAnswerInputSeal": 1,
            "wCalendarSelectCount": 2,
            "wCalendarSelectDirection": 1,
            "wCalendarActive": 1,
            "wCalendarActiveOwner": 1,
            "wCalendarRequestedOwner": 1,
            "wCalendarRequestedBanks": 1,
            "wCalendarOrdinalSign": 1,
            "wCalendarOrdinalLength": 3,
            "wLeaseTable": 16,
        }

        def caller_state() -> dict[str, bytes]:
            return {name: read_bytes(name, size) for name, size in preserved.items()}

        def leased_sram() -> bytes:
            # The assembly check maps the live leased bank 3 at each handshake.
            # Compare every byte, not only its existing $6e sentinel.
            return bytes(int(boy.memory[i]) for i in range(0xA000, 0xC000))

        initial_caller = caller_state()
        assert initial_caller["wCalendarActive"] == b"\x01"
        assert initial_caller["wCalendarActiveOwner"] == bytes([70])
        assert initial_caller["wLeaseTable"][3] == 72
        initial_sram = leased_sram()
        assert initial_sram[0] == 0x6E
        previous = vectors[0][3]
        total_vector_frames = 0
        for name, c, status, payload in vectors:
            assert caller_state() == initial_caller, f"{name}: caller changed before selection"
            assert read_bytes("wCalendarGateYearResultOpen", 18) == previous
            calc = c.to_bytes(4, "little", signed=True)
            write_bytes("wPairCalcOffset", calc)
            boy.memory[phase] = 2
            elapsed = wait_phase(3, 120000, name)
            total_vector_frames += elapsed
            actual_status = read_bytes("wCalendarStatus", 1)[0]
            actual = read_bytes("wCalendarGateYearResultOpen", 18)
            expected = payload if status == 0 else previous
            assert actual_status == status, (name, actual_status, status)
            assert actual == expected, (name, actual.hex(), expected.hex())
            assert read_bytes("wPairCalcOffset", 4) == calc, f"{name}: calculation input"
            assert caller_state() == initial_caller, f"{name}: caller/owner/lease restoration"
            assert leased_sram() == initial_sram, f"{name}: leased SRAM mutated"
            print(
                f"NATIVE395_EXTENDED_VECTOR name={name} c_abs={c} status={actual_status} "
                f"result18={actual.hex()} expected18={expected.hex()} frames={elapsed} "
                "caller_owner_lease_sram8192=PASS",
                flush=True,
            )
            previous = expected
            boy.memory[phase] = 4
            wait_phase(1, 120000, f"{name} acknowledgement")

        boy.memory[phase] = 5
        restore_frames = wait_phase(6, 120000, "Foundation restoration")
        result, case, dispatch, tail_frames = wait_for_completion(
            boy, max_frames=120000, high_byte_address=high_address
        )
        frames = baseline_frames + restore_frames + tail_frames
        assert frames <= 120000, f"baseline and restoration frame budget: {frames}"
        print(f"NATIVE395_EXTENDED=PASS valid=19 invalid=4 vectors=23 "
              f"selection_frames={total_vector_frames} per_case_limit=120000 "
              f"baseline_restore_frames={frames}", flush=True)
        print(
            f"ROM_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
            f"DISPATCH_STATUS={dispatch:02X} FRAMES={frames}",
            flush=True,
        )
        assert (result, case, dispatch) == (SUCCESS, 395, UNIMPLEMENTED)

        def read(name: str, size: int) -> bytes:
            bank, address = symbols[name]
            assert bank == 0, f"{name}: expected WRAM0 bank 0, got {bank}"
            return bytes(int(boy.memory[address + i]) for i in range(size))

        actual_open = int.from_bytes(read("wCalendarGateYearResultOpen", 4), "little", signed=True)
        actual_close = int.from_bytes(read("wCalendarGateYearResultClose", 4), "little", signed=True)
        actual_span = int.from_bytes(read("wCalendarGateYearResultSpan", 2), "little")
        actual_count = int.from_bytes(read("wCalendarGateYearResultCount", 2), "little")
        actual_rank = int.from_bytes(read("wCalendarGateYearResultRank", 2), "little")
        actual_gate_count = int.from_bytes(read("wCalendarGateYearResultGateCount", 2), "little")
        actual_left = read("wCalendarGateYearResultLeftCount", 1)[0]
        actual_right = read("wCalendarGateYearResultRightCount", 1)[0]
        assert (
            actual_open, actual_close, actual_span, actual_count, actual_rank,
            actual_gate_count, actual_left, actual_right
        ) == (
            chosen.open_gate, chosen.close_gate,
            chosen.length, options, rank, len(gates), left_count, right_count
        ), "Native395 selected year differs from independent Host oracle"

        assert read("wCalendarActive", 1)[0] == 0
        assert read("wCalendarStatus", 1)[0] == 6
        lease_address = symbols["wLeaseTable"][1]
        assert int(boy.memory[lease_address + 3]) == 0
        boy.memory[0x0000] = 0x0A
        boy.memory[0x4000] = 3
        assert int(boy.memory[0xA000]) == 0, "Native395 did not release/scrub SRAM bank 3"
        boy.memory[0x0000] = 0
        print(
            "NATIVE395_YEAR=PASS differential=Foundation_year5000 "
            f"candidates={actual_count} rank={actual_rank} "
            f"open={actual_open} close={actual_close} span={actual_span} "
            f"window_gates={actual_gate_count} left={actual_left} right={actual_right} "
            f"frames={frames} idle_invalid_pair_restore_owner_lease_SRAM=CHECKED",
            flush=True,
        )
    finally:
        boy.stop()


if __name__ == "__main__":
    main()
