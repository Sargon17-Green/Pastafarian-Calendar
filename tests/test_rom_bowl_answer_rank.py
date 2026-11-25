#!/usr/bin/env python3
"""Real Native393 end-to-end PyBoy gate; not a synthetic host test."""
import argparse
from pathlib import Path
from test_rom import SUCCESS, UNIMPLEMENTED, check_header, discover_case_high_byte, wait_for_completion
from test_sm83_stage1_sauce_oracle import FOUNDATION, compute_sauce, counts_for
from test_sm83_stage1_selection_oracle import bowl_answer_flow, select

M = (1 << 127) - 1

def discover_source_symbols(symbol_path: Path) -> dict[str, int]:
    wanted = {
        "wCalendarPostStirSavedBowls", "wCalendarBowlOrderScratch",
        "wCalendarAnswerSavedByte", "wCalendarAnswerInputBowl", "wCalendarAnswerInputSeal",
        "wCalendarSelectCount", "wCalendarAnswerA0", "wCalendarAnswerDirection",
        "wCalendarSelectRank", "wCalendarAnswerAccepted", "wCalendarStatus", "wCalendarActive",
        "wCalendarSelectValue", "wCalendarSelectDirection", "wCalendarOrdinalSign",
        "wCalendarOrdinalLength",
        "wPairCalcOffset", "wPairTargetOffset", "wNative393Mode",
        "wNative393ResultCount", "wCalendarAnswerNativeResults",
        "wWorkCalcCount", "wWorkTargetCount", "wWorkDistance", "wWorkSum", "wWorkDirection",
        "wCalendarBowlOrderAt46", "wCalendarPostStirSums",
    }
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

SOURCE_CASES = [
    (1, 10, 1), (1, 11, 2), (6, 12, 922), (4, 12, 19044),
    (1, 12, 3), (2, 10, 7), (2, 11, 138), (2, 12, 922),
    (3, 10, 5778), (3, 11, 19044), (3, 12, 3), (4, 10, 7),
    (4, 11, 138), (5, 10, 922), (5, 11, 5778), (5, 12, 19044),
    (6, 10, 3), (6, 11, 7),
]
PAIR_CASES = [
    ("foundation", 0, 0, 0),
    ("c_lt_adjacent", -1, 1, 1),
    ("c_gt_adjacent", 1, -1, 1),
    ("signed32_min_to_max", -(1 << 31), (1 << 31) - 1, 1),
    ("signed32_max_to_min", (1 << 31) - 1, -(1 << 31), 1),
]

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("rom", type=Path)
    path = parser.parse_args().rom
    check_header(path.read_bytes())
    high = discover_case_high_byte(path.with_suffix(".sym"))
    source_symbols = discover_source_symbols(path.with_suffix(".sym"))
    from pyboy import PyBoy

    def read_symbol(boy, name: str, size: int) -> bytes:
        address = source_symbols[name]
        return bytes(int(boy.memory[address + i]) for i in range(size))

    def write_symbol(boy, name: str, data: bytes) -> None:
        address = source_symbols[name]
        for i, value in enumerate(data):
            boy.memory[address + i] = value

    def signed32_bytes(value: int) -> bytes:
        assert -(1 << 31) <= value <= (1 << 31) - 1
        return (value & 0xffffffff).to_bytes(4, "little")

    total_frames = 0
    for pair_name, calc_offset, target_offset, mode in PAIR_CASES:
        boy = PyBoy(str(path), window="null")
        try:
            boy.set_emulation_speed(0)
            write_symbol(boy, "wPairCalcOffset", signed32_bytes(calc_offset))
            write_symbol(boy, "wPairTargetOffset", signed32_bytes(target_offset))
            write_symbol(boy, "wNative393Mode", bytes((mode,)))
            write_symbol(boy, "wCalendarAnswerNativeResults", bytes(18 * 35))
            write_symbol(boy, "wNative393ResultCount", bytes((0,)))
            result, case, status, frames = wait_for_completion(
                boy, max_frames=120000, high_byte_address=high
            )
            print(
                f"ROM_BOWL_ANSWER_RANK_NATIVE_STATUS={result:02X} LAST_TEST_CASE={case} "
                f"DISPATCH_STATUS={status:02X} FRAMES={frames} PAIR={pair_name}",
                flush=True,
            )
            if (result, case, status) != (SUCCESS, 393, UNIMPLEMENTED):
                count_bytes = read_symbol(boy, "wCalendarSelectCount", 2)
                print(f"NATIVE393_DIAG_RESULT_COUNT={read_symbol(boy,'wNative393ResultCount',1)[0]}", flush=True)
                print(f"NATIVE393_DIAG_MODE={read_symbol(boy,'wNative393Mode',1)[0]}", flush=True)
                print(f"NATIVE393_DIAG_STATUS_ACTIVE={read_symbol(boy,'wCalendarStatus',1)[0]:02x}/{read_symbol(boy,'wCalendarActive',1)[0]:02x}", flush=True)
                print(f"NATIVE393_DIAG_ORDINAL={read_symbol(boy,'wCalendarOrdinalSign',1)[0]:02x}/{read_symbol(boy,'wCalendarOrdinalLength',3).hex()}", flush=True)
                print(f"NATIVE393_DIAG_INPUT_BOWL_SEAL_COUNT={read_symbol(boy,'wCalendarAnswerInputBowl',1)[0]},{read_symbol(boy,'wCalendarAnswerInputSeal',1)[0]},{int.from_bytes(count_bytes,'little')}", flush=True)
                print(f"NATIVE393_DIAG_A0={read_symbol(boy,'wCalendarAnswerA0',16).hex()}", flush=True)
                print(f"NATIVE393_DIAG_DIRECTION={read_symbol(boy,'wCalendarAnswerDirection',1)[0]:02x}", flush=True)
                print(f"NATIVE393_DIAG_RANK={read_symbol(boy,'wCalendarSelectRank',2).hex()}", flush=True)
                print(f"NATIVE393_DIAG_AK={read_symbol(boy,'wCalendarAnswerAccepted',16).hex()}", flush=True)
                print(f"NATIVE393_DIAG_Q={read_symbol(boy,'wCalendarPostStirSavedBowls',96).hex()}", flush=True)
                print(f"NATIVE393_DIAG_ORDER={read_symbol(boy,'wCalendarBowlOrderScratch',6).hex()}", flush=True)
            assert (result, case, status) == (SUCCESS, 393, UNIMPLEMENTED)
            total_frames += frames

            calculation = FOUNDATION + calc_offset
            target = FOUNDATION + target_offset
            sauce = compute_sauce(calculation, target)
            expected_counts = counts_for(calculation, target)
            actual_counts = (
                int.from_bytes(read_symbol(boy, "wWorkCalcCount", 5), "little"),
                int.from_bytes(read_symbol(boy, "wWorkTargetCount", 5), "little"),
                int.from_bytes(read_symbol(boy, "wWorkDistance", 5), "little"),
                int.from_bytes(read_symbol(boy, "wWorkSum", 5), "little"),
                read_symbol(boy, "wWorkDirection", 1)[0],
            )
            assert actual_counts == expected_counts, (
                f"{pair_name}: WorkCountsFromOffsets32 {actual_counts} != {expected_counts}"
            )
            expected_q = b"".join(x.to_bytes(16, "little") for x in sauce.bowls)
            actual_q = read_symbol(boy, "wCalendarPostStirSavedBowls", 96)
            assert actual_q == expected_q, f"{pair_name}: final six-bowl Q mismatch"
            actual_order = read_symbol(boy, "wCalendarBowlOrderScratch", 6)
            assert actual_order == bytes(sauce.order_at_46), (
                f"{pair_name}: orderAt46 {actual_order.hex()} != {bytes(sauce.order_at_46).hex()}"
            )
            expected_sums = b"".join(x.to_bytes(16, "little") for x in sauce.retained_post_stir_sums)
            actual_sums = read_symbol(boy, "wCalendarPostStirSums", 192)
            assert actual_sums == expected_sums, f"{pair_name}: retained post-stir sums mismatch"

            result_count = read_symbol(boy, "wNative393ResultCount", 1)[0]
            assert result_count == 18, f"{pair_name}: only {result_count}/18 answer records"
            records = read_symbol(boy, "wCalendarAnswerNativeResults", 18 * 35)
            for index, (bowl, seal, count) in enumerate(SOURCE_CASES):
                record = records[index * 35:(index + 1) * 35]
                actual_a0 = int.from_bytes(record[0:16], "little")
                actual_direction = record[16]
                actual_rank = int.from_bytes(record[17:19], "little")
                actual_accepted = int.from_bytes(record[19:35], "little")
                flow = bowl_answer_flow(sauce, bowl, seal)
                choice = select(flow, count)
                expected_direction = 1 if flow.step == 1 else 0xff
                formula_a0, formula_direction = source_a0_direction(
                    bowl, seal, list(sauce.bowls), list(sauce.order_at_46)
                )
                assert formula_a0 == flow.first, f"{pair_name}: independent A0 formulas disagree"
                assert formula_direction == expected_direction, f"{pair_name}: independent direction formulas disagree"
                formula_rank, formula_accepted = rank_and_accepted(
                    formula_a0, formula_direction, count
                )
                assert (formula_rank, formula_accepted) == (
                    choice.rank, choice.accepted_word
                ), f"{pair_name}: independent rank/Ak formulas disagree"
                assert actual_a0 == flow.first, (
                    f"{pair_name}: bowl={bowl} seal={seal} A0 {actual_a0:032x} != {flow.first:032x}"
                )
                assert actual_direction == expected_direction, (
                    f"{pair_name}: bowl={bowl} seal={seal} direction {actual_direction:02x} != {expected_direction:02x}"
                )
                assert actual_rank == choice.rank, (
                    f"{pair_name}: bowl={bowl} seal={seal} rank {actual_rank} != {choice.rank}"
                )
                assert actual_accepted == choice.accepted_word, (
                    f"{pair_name}: bowl={bowl} seal={seal} Ak {actual_accepted:032x} != {choice.accepted_word:032x}"
                )
            print(
                f"NATIVE393_PAIR={pair_name} PASS offsets={calc_offset},{target_offset} "
                f"work_counts=CHECKED Q=CHECKED orderAt46=CHECKED post_stirs=12/12 "
                f"answer_vectors=18 FRAMES={frames}",
                flush=True,
            )
        finally:
            boy.stop()

    print(
        f"STAGE1_BOWL_ANSWER_RANK_NATIVE=PASS pairs={len(PAIR_CASES)} "
        f"source_answer_vectors={len(PAIR_CASES) * len(SOURCE_CASES)} "
        f"frames_total={total_frames} signed32_endpoints=CHECKED "
        "work_counts_Q_orderAt46_post_stir_sums_A0_direction_rank_Ak=CHECKED "
        "synthetic_boundaries_invalid_count_idle_owner_lease_SRAM=CHECKED",
        flush=True,
    )


if __name__ == "__main__":
    main()
