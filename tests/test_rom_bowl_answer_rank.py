#!/usr/bin/env python3
"""Real Native393 end-to-end PyBoy gate; not a synthetic host test."""
import argparse
import re
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion

M = (1 << 127) - 1

def discover_source_symbols(symbol_path: Path) -> dict[str, int]:
    wanted = {"wCalendarPostStirSavedBowls", "wCalendarBowlOrderScratch"}
    found: dict[str, int] = {}
    for line in symbol_path.read_text(encoding="utf-8").splitlines():
        match = re.fullmatch(r"([0-9A-Fa-f]{2}):([0-9A-Fa-f]{4})\\s+([A-Za-z_]\\w*)", line.strip())
        if match is None or match.group(3) not in wanted:
            continue
        bank, address, name = int(match.group(1), 16), int(match.group(2), 16), match.group(3)
        assert bank == 0, f"{name}: expected WRAM bank 00, found {bank:02X}"
        assert name not in found, f"duplicate linker symbol {name}"
        found[name] = address
    assert set(found) == wanted, f"missing source-state symbols: {sorted(wanted - set(found))}"
    return found

def save127(value: int) -> int:
    reduced = value % M
    return reduced if reduced else M

def source_a0_direction(bowl: int, seal: int, q: list[int], order: list[int]) -> tuple[int, int]:
    position = order.index(bowl)
    successor = order[(position + 1) % 6]
    a0 = save127((q[bowl - 1] + seal + 181) ** 2 + 179 * q[successor - 1] + seal)
    d = save127((a0 + seal + 194) ** 2 + 193 * a0 + 197 * q[5])
    return a0, (1 if d & 1 else 0xFF)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("rom",type=Path)
    path=p.parse_args().rom
    check_header(path.read_bytes())
    symbol_path = path.with_suffix(".sym")
    high=discover_case_high_byte(symbol_path)
    source_symbols = discover_source_symbols(symbol_path)
    from pyboy import PyBoy
    boy=PyBoy(str(path),window="null")
    try:
        boy.set_emulation_speed(0)
        result,case,status,frames=wait_for_completion(boy,max_frames=120000,high_byte_address=high)
        print(f"ROM_BOWL_ANSWER_RANK_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
              f"DISPATCH_STATUS={status:02X} FRAMES={frames}",flush=True)
        assert (result,case,status)==(SUCCESS,393,UNIMPLEMENTED)
        q_bytes = bytes(int(boy.memory[source_symbols["wCalendarPostStirSavedBowls"] + i]) for i in range(96))
        order_bytes = bytes(int(boy.memory[source_symbols["wCalendarBowlOrderScratch"] + i]) for i in range(6))
        q = [int.from_bytes(q_bytes[i:i+16], "little") for i in range(0, 96, 16)]
        order = list(order_bytes)
        assert all(0 < value <= M for value in q), "Native393 Q snapshot is not six canonical SAVE residues"
        assert sorted(order) == [1, 2, 3, 4, 5, 6], f"Native393 orderAt46 is not a permutation: {order}"
        fixtures = [
            (1, 10, "0c6c8121da308925a2da405d4a491c38", 1),
            (1, 11, "abcd b55a7e61a599c7080559efcc571a".replace(" ", ""), 0xFF),
            (6, 12, "d0e39c5ce6a31044c08e4ca5d880176c", 0xFF),
            (4, 12, "b11ae66b81ee806d27d965511b7a9239", 1),
        ]
        for bowl, seal, expected_hex, expected_direction in fixtures:
            actual, direction = source_a0_direction(bowl, seal, q, order)
            assert actual.to_bytes(16, "little").hex() == expected_hex, (
                f"independent source A0 mismatch bowl={bowl} seal={seal}: "
                f"{actual.to_bytes(16, 'little').hex()} != {expected_hex}"
            )
            assert direction == expected_direction, (
                f"independent source direction mismatch bowl={bowl} seal={seal}: "
                f"{direction:02X} != {expected_direction:02X}"
            )
        print(f"NATIVE393_SOURCE_Q={q_bytes.hex()}", flush=True)
        print(f"NATIVE393_SOURCE_ORDER_AT_46={order_bytes.hex()}", flush=True)
        print("NATIVE393_SOURCE_A0_DIRECTION_ORACLE=PASS cases=4", flush=True)
        print("STAGE1_BOWL_ANSWER_RANK_NATIVE=PASS A0_direction_rank_Ak=CHECKED "
              "synthetic_boundaries_invalid_idle_owner_lease_SRAM=CHECKED",flush=True)
    finally: boy.stop()

if __name__=="__main__": main()
