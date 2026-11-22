#!/usr/bin/env python3
"""Independent partial Stage-1 oracle transcribed from the Hebrew Scroll.

This module deliberately imports neither normative_reference nor Fortran code.
It proves only the day-number, sauce, gate, and year-5000 selection pipeline.
Cutlets, months, weaving and full five-field dates remain UNVERIFIED.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from functools import lru_cache

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SCROLL_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7"
SCROLL_NAME = "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md"
MODULUS = (1 << 127) - 1
DROP_STIR_COEFFICIENTS = (
    (3, 5, 7, 11), (5, 7, 11, 13), (7, 11, 13, 17),
    (11, 13, 17, 19), (13, 17, 19, 23), (17, 19, 23, 29),
    (19, 23, 29, 31), (23, 29, 31, 37), (29, 31, 37, 41),
    (31, 37, 41, 43), (37, 41, 43, 47),
)
STONE_PATTERN = (0, 1, 2, 3, 4, 0, 1, 2, 3, 4, 0)
BOWL_CONST = (17, 19, 23, 29, 31, 37)


def save(value: int) -> int:
    """Hebrew Scroll table VI: one-based residue, including zero -> M."""
    if value < 0:
        raise ValueError("SAVE is defined here for nonnegative arithmetic")
    return (value - 1) % MODULUS + 1


def day_number(offset: int) -> int:
    """Offset is signed chronological days relative to Foundation Day."""
    return 2 * offset + 1 if offset >= 0 else -2 * offset


@lru_cache(maxsize=1)
def stones() -> tuple[tuple[int, ...], ...]:
    result = [(17, 29, 43, 71, 101)]
    for drop_index in range(2, 47):
        a, b, c, d, e = result[-1]
        result.append((
            save(a * a + 3 * b + drop_index),
            save(b * b + 5 * c + a),
            save(c * c + 7 * d + b),
            save(d * d + 11 * e + c),
            save(e * e + 13 * a + d),
        ))
    return tuple(result)


@lru_cache(maxsize=720)
def bowl_order(zero_based_rank: int) -> tuple[int, ...]:
    if not 0 <= zero_based_rank < 720:
        raise ValueError("permutation rank outside 0..719")
    remaining = [0, 1, 2, 3, 4, 5]
    result = []
    rank = zero_based_rank
    for width in range(6, 0, -1):
        block = 1
        for k in range(2, width):
            block *= k
        index, rank = divmod(rank, block)
        result.append(remaining.pop(index))
    return tuple(result)


@lru_cache(maxsize=2048)
def sauce(calculation_offset: int, question_offset: int) -> tuple:
    operation = day_number(calculation_offset)
    question = day_number(question_offset)
    distance = abs(question_offset - calculation_offset) + 1
    combined = operation + question
    direction = 1 if question_offset < calculation_offset else (
        2 if question_offset == calculation_offset else 3
    )
    values = stones()
    history: dict[int, int] = {}

    # Hidden drops are stored at indices 0, -1, ..., -6.
    for hidden_number in range(1, 8):
        j = hidden_number
        v = save(
            operation + (2 * j + 1) * question + (3 * j + 1) * distance
            + (4 * j + 2) * combined + (4 * j + 4) * direction
            + sum(values[j - 1])
        )
        for grind_index, stone_index in enumerate((0, 1, 2, 3, 4, 0, 1), start=1):
            old = v
            v = save(old * old + 3 * old + values[j - 1][stone_index] + grind_index)
        history[1 - j] = v

    bowls = tuple(
        save((operation + (index + 1) * question + distance + combined
              + direction + BOWL_CONST[index] ** 2) ** 2 + index + 1)
        for index in range(6)
    )
    last_order = None
    for drop_number in range(1, 47):
        previous = history[drop_number - 1]
        third_previous = history[drop_number - 3]
        seventh_previous = history[drop_number - 7]
        current_stones = values[drop_number - 1]
        raw = (
            current_stones[0] * operation + current_stones[1] * question
            + current_stones[2] * distance + current_stones[3] * combined
            + current_stones[4] * direction + previous
            + 3 * third_previous + 5 * seventh_previous + drop_number
        )
        drop = save(raw)
        for coeff, stone_index in zip(DROP_STIR_COEFFICIENTS, STONE_PATTERN):
            a, b, c, d = coeff
            old = drop
            drop = save(
                old * old + a * old + b * previous + c * third_previous
                + d * seventh_previous + current_stones[stone_index]
            )
        history[drop_number] = drop
        order = bowl_order((drop - 1) % 720)
        incoming = [0] * 6
        for position in range(3):
            bowl_id = order[position]
            incoming[bowl_id] = save(
                drop * drop + current_stones[position] * bowls[bowl_id]
                + drop_number * (2 * position + 3)
            )
        updated = [0] * 6
        for position, bowl_id in enumerate(order):
            before = bowls[order[(position - 1) % 6]]
            after = bowls[order[(position + 1) % 6]]
            amount = (
                bowls[bowl_id] + 2 * before + 3 * after
                + incoming[bowl_id] + drop + current_stones[position % 5]
            )
            updated[bowl_id] = save(
                amount * amount + 5 * before * after
                + drop_number * (position + 1)
            )
        bowls = tuple(updated)
        last_order = order

    assert last_order is not None
    # The twelve post-stirs use RAW sum in the update, SAVED sum for ordering.
    for stir_index in range(1, 13):
        raw_sum = sum(bowls)
        selected = save(raw_sum + 149 * stir_index)
        order = bowl_order((selected - 1) % 720)
        updated = [0] * 6
        for position, bowl_id in enumerate(order):
            before = bowls[order[(position - 1) % 6]]
            after = bowls[order[(position + 1) % 6]]
            amount = (
                bowls[bowl_id] + 3 * before + 5 * after
                + raw_sum + stir_index + (position + 1) ** 2
            )
            updated[bowl_id] = save(amount * amount + 7 * before * after)
        bowls = tuple(updated)
    return bowls, last_order


def bowl_answer(calculation_offset: int, question_offset: int,
                bowl_id: int, seal: int) -> tuple[int, int]:
    """Return first cyclic answer and its step direction, not a sampled index."""
    if not 1 <= bowl_id <= 6:
        raise ValueError("bowl_id must be 1..6")
    bowls, last_drop_order = sauce(calculation_offset, question_offset)
    at = last_drop_order.index(bowl_id - 1)
    next_id = last_drop_order[(at + 1) % 6]
    first = save(
        (bowls[bowl_id - 1] + seal + 181) ** 2
        + 179 * bowls[next_id] + seal
    )
    test = save(
        (first + seal + 1 + 193) ** 2 + 193 * first + 197 * bowls[5]
    )
    return first, (1 if test % 2 else -1)


def choose_index(calculation_offset: int, question_offset: int,
                 bowl_id: int, seal: int, option_count: int) -> int:
    """Zero-based unbiased selection from Hebrew Scroll table XVI."""
    if option_count <= 0:
        raise ValueError("cannot select from an empty choice list")
    first, step = bowl_answer(calculation_offset, question_offset, bowl_id, seal)
    if option_count <= MODULUS:
        ceiling = MODULUS - MODULUS % option_count
        cursor = first
        while cursor > ceiling:
            cursor = (cursor - 1 + step) % MODULUS + 1
        return (cursor - 1) % option_count
    base = MODULUS
    digits = 1
    space = base
    while space < option_count:
        space *= base
        digits += 1
    wide = 1
    for position in range(digits):
        digit = (first - 1 + position * step) % base
        wide += digit * (base ** position)
    ceiling = space - space % option_count
    while wide > ceiling:
        wide = (wide - 1 + step) % space + 1
    return (wide - 1) % option_count


def one_gate_step(direction: int, count_from_center: int) -> int:
    if direction not in (-1, 1) or count_from_center < 1:
        raise ValueError("gate direction/count invalid")
    # Gates use the n-th day away from Foundation, not the prior gate day.
    selected = choose_index(0, direction * count_from_center, 1, 1, 922)
    return 42 + selected


def gate_window(max_distance: int = 5878) -> list[tuple[int, int]]:
    """(gate index, signed chronological offset); index 0 is Foundation."""
    result = [(0, 0)]
    for sign in (-1, 1):
        position = 0
        number = 0
        while abs(position) <= max_distance:
            number += 1
            position += sign * one_gate_step(sign, number)
            result.append((sign * number, position))
    return sorted(result, key=lambda item: item[0])


def foundation_year_5000() -> dict:
    gates = gate_window()
    candidates = []
    for i, (open_index, open_day) in enumerate(gates):
        if open_day >= 0:
            break
        for close_index, close_day in gates[i + 1:]:
            if close_day < 0:
                continue
            total_days = close_day - open_day
            if total_days > 5878:
                break
            if close_index - open_index < 6 or total_days < 252:
                continue
            candidates.append((total_days, open_day, close_day, open_index, close_index))
    candidates.sort(key=lambda t: (t[0], t[1]))
    chosen = candidates[choose_index(0, 0, 1, 10, len(candidates))]
    days, opening, ending, open_index, close_index = chosen
    if not (opening < 0 <= ending and 252 <= days <= 5878
            and close_index - open_index >= 6):
        raise AssertionError("Foundation-Day year selection violates Hebrew constraints")
    return {
        "project_id": PROJECT_ID,
        "authority": {"snapshot": SCROLL_NAME, "sha256": SCROLL_SHA256},
        "independent_from_pinned_python": True,
        "full_stage1_accepted": False,
        "foundation_day_offset": 0,
        "foundation_day_number": day_number(0),
        "gate_steps_adjacent_to_foundation": {
            "past": one_gate_step(-1, 1),
            "future": one_gate_step(1, 1),
        },
        "year_5000": {
            "candidate_count": len(candidates),
            "opening_gate_index": open_index,
            "closing_gate_index": close_index,
            "opening_gate_day_offset": opening,
            "closing_gate_day_offset": ending,
            "gate_intervals": close_index - open_index,
            "calendar_day_count": days,
        },
        "scope": "DAY_NUMBER_SAUCE_GATE_YEAR5000_ONLY_NOT_FULL_DATE",
    }


def self_test() -> None:
    checks = 0
    def verify(condition: bool, description: str) -> None:
        nonlocal checks
        if not condition:
            raise AssertionError(description)
        checks += 1

    verify([day_number(x) for x in range(-3, 4)] == [6, 4, 2, 1, 3, 5, 7],
           "signed day-number order")
    verify(save(0) == MODULUS, "SAVE(0)")
    verify(save(MODULUS) == MODULUS, "SAVE(M)")
    verify(save(MODULUS + 1) == 1, "SAVE(M+1)")
    verify(save(2 * MODULUS) == MODULUS, "SAVE(2M)")
    verify(len(stones()) == 46, "number of stone vectors")
    verify(stones()[0] == (17, 29, 43, 71, 101), "first stones")
    verify(all(1 <= x <= MODULUS for stone in stones() for x in stone),
           "stones' residues")
    verify(bowl_order(0) == (0, 1, 2, 3, 4, 5), "first permutation")
    verify(bowl_order(719) == (5, 4, 3, 2, 1, 0), "last permutation")
    verify(len({bowl_order(i) for i in range(720)}) == 720, "unique permutations")
    verify(len(sauce(0, 0)[0]) == 6, "six bowls")
    verify(set(sauce(0, 0)[1]) == set(range(6)), "last drop permutation")
    verify(42 <= one_gate_step(-1, 1) <= 963, "past gate limit")
    verify(42 <= one_gate_step(1, 1) <= 963, "future gate limit")
    print(f"STAGE01_SCROLL_GATE_SELFTEST={checks}/{checks}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--foundation", action="store_true")
    parser.add_argument("--output")
    parser.add_argument("--scroll-file", help="optional authoritative snapshot for SHA check")
    args = parser.parse_args()
    if args.scroll_file:
        with open(args.scroll_file, "rb") as source:
            actual = hashlib.sha256(source.read()).hexdigest()
        if actual != SCROLL_SHA256:
            raise SystemExit("Hebrew Scroll SHA256 mismatch")
    if args.self_test:
        self_test()
    if args.foundation:
        result = foundation_year_5000()
        encoded = json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
        if args.output:
            with open(args.output, "w", encoding="utf-8") as target:
                target.write(encoded)
        print("STAGE01_SCROLL_FOUNDATION_YEAR5000_DIAGNOSTIC=PASS")
        print("STAGE01_SCROLL_FOUNDATION_YEAR5000_CANDIDATES="
              + str(result["year_5000"]["candidate_count"]))
        print("STAGE01_SCROLL_FOUNDATION_YEAR5000_DAYS="
              + str(result["year_5000"]["calendar_day_count"]))
        print("STAGE01_SCROLL_GATE_COMPONENT_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if not args.self_test and not args.foundation:
        parser.error("specify --self-test and/or --foundation")


if __name__ == "__main__":
    main()
