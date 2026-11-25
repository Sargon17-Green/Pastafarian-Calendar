#!/usr/bin/env python3
"""Real Native393 end-to-end PyBoy gate; not a synthetic host test."""
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion

M = (1 << 127) - 1

def discover_source_symbols(symbol_path: Path) -> dict[str, int]:
    wanted = {"wCalendarPostStirSavedBowls", "wCalendarBowlOrderScratch"}
    found: dict[str, int] = {}
    for line in symbol_path.read_text(encoding="utf-8").splitlines():
        fields = line.strip().split()
        if len(fields) != 2 or fields[1] not in wanted or ":" not in fields[0]:
            continue
        bank_text, address_text = fields[0].split(":", 1)
        bank, address, name = int(bank_text, 16), int(address_text, 16), fields[1]
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

def rank_and_accepted(a0: int, direction: int, count: int) -> tuple[int, int]:
    assert 1 <= count <= 19044, f"invalid source-vector count: {count}"
    limit = M - (M % count)
    if a0 > limit:
        return (1 if direction == 1 else count), (1 if direction == 1 else limit)
    return 1 + ((a0 - 1) % count), a0

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
            (1, 10, 1, "0c6c8121da308925a2da405d4a491c38", 1, 1, "0c6c8121da308925a2da405d4a491c38"),
            (1, 11, 2, "abcdb55a7e61a599c7080559efcc571a", 255, 1, "abcdb55a7e61a599c7080559efcc571a"),
            (6, 12, 922, "d0e39c5ce6a31044c08e4ca5d880176c", 255, 810, "d0e39c5ce6a31044c08e4ca5d880176c"),
            (4, 12, 19044, "b11ae66b81ee806d27d965511b7a9239", 1, 11525, "b11ae66b81ee806d27d965511b7a9239"),
            (1, 12, 3, "4b2fea932292c10ded36c9549450937c", 255, 2, "4b2fea932292c10ded36c9549450937c"),
            (2, 10, 7, "e221aace70808f8257646fa52648852f", 1, 3, "e221aace70808f8257646fa52648852f"),
            (2, 11, 138, "a9962f206eabee8e2b52a71e7258b16f", 1, 83, "a9962f206eabee8e2b52a71e7258b16f"),
            (2, 12, 922, "730bb5716bd64d9bff3fdf97bd68dd2f", 255, 329, "730bb5716bd64d9bff3fdf97bd68dd2f"),
            (3, 10, 5778, "7d36809f9ad694464d656034b491dd1c", 255, 2639, "7d36809f9ad694464d656034b491dd1c"),
            (3, 11, 19044, "9131d11bbcc344121dc5b194d6d8a96e", 255, 1709, "9131d11bbcc344121dc5b194d6d8a96e"),
            (3, 12, 3, "a82c2298ddb0f4ddec2403f5f81f7640", 1, 3, "a82c2298ddb0f4ddec2403f5f81f7640"),
            (4, 10, 7, "01ff3bc8af4c6a50db748fe6ac297e21", 1, 1, "01ff3bc8af4c6a50db748fe6ac297e21"),
            (4, 11, 138, "d80c119a989df55e01a7fa1be451882d", 1, 62, "d80c119a989df55e01a7fa1be451882d"),
            (5, 10, 922, "f71606cce7a0b57c04d18e3dd2112e09", 255, 447, "f71606cce7a0b57c04d18e3dd2112e09"),
            (5, 11, 5778, "63c9e95d06f68cdea61fde49da64bc5b", 255, 937, "63c9e95d06f68cdea61fde49da64bc5b"),
            (5, 12, 19044, "d27bcdef244b6440496e2d56e2b74a2e", 1, 3122, "d27bcdef244b6440496e2d56e2b74a2e"),
            (6, 10, 3, "30dcee9d02c65169d4e07c6c568e701d", 255, 1, "30dcee9d02c65169d4e07c6c568e701d"),
            (6, 11, 7, "ffdf457df434b156cab7e4889707c444", 1, 3, "ffdf457df434b156cab7e4889707c444"),
        ]
        for bowl, seal, count, expected_hex, expected_direction, expected_rank, expected_accepted_hex in fixtures:
            actual, direction = source_a0_direction(bowl, seal, q, order)
            assert actual.to_bytes(16, "little").hex() == expected_hex, (
                f"independent source A0 mismatch bowl={bowl} seal={seal}: "
                f"{actual.to_bytes(16, 'little').hex()} != {expected_hex}"
            )
            assert direction == expected_direction, (
                f"independent source direction mismatch bowl={bowl} seal={seal}: "
                f"{direction:02X} != {expected_direction:02X}"
            )
            rank, accepted = rank_and_accepted(actual, direction, count)
            assert rank == expected_rank, (
                f"independent source rank mismatch bowl={bowl} seal={seal} N={count}: "
                f"{rank} != {expected_rank}"
            )
            assert accepted.to_bytes(16, "little").hex() == expected_accepted_hex, (
                f"independent source A_k mismatch bowl={bowl} seal={seal} N={count}: "
                f"{accepted.to_bytes(16, 'little').hex()} != {expected_accepted_hex}"
            )
        print(f"NATIVE393_SOURCE_Q={q_bytes.hex()}", flush=True)
        print(f"NATIVE393_SOURCE_ORDER_AT_46={order_bytes.hex()}", flush=True)
        print("NATIVE393_SOURCE_A0_DIRECTION_RANK_AK_ORACLE=PASS cases=18 foundation=4 nonfoundation=14", flush=True)
        print("STAGE1_BOWL_ANSWER_RANK_NATIVE=PASS A0_direction_rank_Ak=CHECKED "
              "source_derived=18 synthetic_boundaries invalid_count=0/19045 idle_invalid output_sentinels Q_order_ordinal_SRAM_snapshots owner_lease=CHECKED",flush=True)
    finally: boy.stop()

if __name__=="__main__": main()
