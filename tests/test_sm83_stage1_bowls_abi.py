#!/usr/bin/env python3
"""Independent bowl-snapshot, post-stir and lexicographic-rank contract tests."""
from __future__ import annotations

import json
from pathlib import Path

from test_sm83_stage1_sauce_oracle import (
    FOUNDATION, INITIAL_BOWL_SEEDS, INITIAL_STONES, M, ORDERS,
    compute_sauce, counts_for, lex_order, save, stones_after,
)

ROOT = Path(__file__).resolve().parents[1]
FACTORIALS = (120, 24, 6, 2, 1, 1)


def signed32(value: int) -> int:
    return (value & 0xFFFFFFFF) - 0x80000000


def modulo720_128(value: int) -> int:
    """Bit-serial unsigned 128-bit modulo; one subtraction per bit is sufficient."""
    assert 1 <= value <= M
    remainder = 0
    for bit in range(127, -1, -1):
        remainder = (remainder << 1) | ((value >> bit) & 1)
        if remainder >= 720:
            remainder -= 720
    return remainder


def unrank_factoradic(index: int) -> tuple[int, ...]:
    """Zero-based lexicographic unranking of one of the 6! permutations."""
    assert 0 <= index < 720
    available = [1, 2, 3, 4, 5, 6]
    result = []
    for divisor in FACTORIALS:
        digit, index = divmod(index, divisor)
        result.append(available.pop(digit))
    assert index == 0
    return tuple(result)


def initial_bowls(counts: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(
        save((counts[0] + identity * counts[1] + counts[2] + counts[3]
              + counts[4] + seed * seed) ** 2 + identity)
        for identity, seed in enumerate(INITIAL_BOWL_SEEDS, 1)
    )


def reference_bowl_update(
    old: tuple[int, ...], order: tuple[int, ...],
    drop: int, stone: tuple[int, ...], i: int,
) -> tuple[int, ...]:
    """Dictionary-based reference: every read comes from one frozen snapshot."""
    snapshot = tuple(old)
    direct_pours = {}
    for q in range(1, 4):
        identity = order[q - 1]
        direct_pours[q] = save(
            drop * drop + stone[q - 1] * snapshot[identity - 1] + (2 * q + 1) * i
        )
    updated = {}
    for q, identity in enumerate(order, 1):
        previous = order[(q - 2) % 6]
        following = order[q % 6]
        p = snapshot[previous - 1]
        n = snapshot[following - 1]
        pour = direct_pours[q] if q <= 3 else 0
        u = snapshot[identity - 1] + 2 * p + 3 * n + pour + drop + stone[(q - 1) % 5]
        updated[identity] = save(u * u + 5 * p * n + i * q)
    return tuple(updated[identity] for identity in range(1, 7))


def reference_post_stir(old: tuple[int, ...], r: int) -> tuple[int, tuple[int, ...]]:
    snapshot = tuple(old)
    retained_sum = save(sum(snapshot) + 149 * r)
    order = lex_order(retained_sum)
    updated = {}
    for q, identity in enumerate(order, 1):
        previous = order[(q - 2) % 6]
        following = order[q % 6]
        p = snapshot[previous - 1]
        n = snapshot[following - 1]
        u = snapshot[identity - 1] + 3 * p + 5 * n + retained_sum + r + q * q
        updated[identity] = save(u * u + 7 * p * n)
    return retained_sum, tuple(updated[identity] for identity in range(1, 7))


def pairs72(fixture: dict) -> list[tuple[int, int]]:
    pairs = [
        (FOUNDATION, FOUNDATION),
        (FOUNDATION - 1, FOUNDATION),
        (FOUNDATION, FOUNDATION + 1),
        (FOUNDATION + 1, FOUNDATION - 1),
        (FOUNDATION - 1, FOUNDATION + 1),
        (FOUNDATION - (1 << 31), FOUNDATION + (1 << 31) - 1),
        (FOUNDATION + (1 << 31) - 1, FOUNDATION - (1 << 31)),
        (FOUNDATION - (1 << 31), FOUNDATION - (1 << 31)),
    ]
    pairs.extend((v["c"], v["t"]) for v in fixture["vectors"])
    for i in range(54):
        c = FOUNDATION + signed32(i * 0x45D9F3B + 0x01234567)
        t = FOUNDATION + signed32(i * 0x119DE1F3 + 0x1F123BB5)
        pairs.append((c, t))
    assert len(pairs) == 72
    return pairs


def main() -> None:
    fixture = json.loads((ROOT / "tests/fixtures/sm83_stage1_canonical_vectors.json").read_text())
    assert len(ORDERS) == 720
    assert tuple(unrank_factoradic(i) for i in range(720)) == ORDERS

    for c, t in pairs72(fixture):
        trace = compute_sauce(c, t)
        assert len(trace.stones) == 46
        assert len(trace.visible) == 46
        assert len(trace.orders) == 46
        assert len(trace.bowl_trace) == 46
        assert len(trace.post_stir_bowls_trace) == 12
        assert len(trace.retained_post_stir_sums) == 12
        assert trace.post_stir_bowls_trace[-1] == trace.bowls
        assert trace.orders[-1] == trace.order_at_46

        counts = counts_for(c, t)
        bowls = initial_bowls(counts)
        stones = {1: INITIAL_STONES}
        for i in range(2, 47):
            stones[i] = stones_after(stones[i - 1], i)

        for i, (drop, stone, order, expected_bowls) in enumerate(
            zip(trace.visible, trace.stones, trace.orders, trace.bowl_trace), 1
        ):
            rem = modulo720_128(drop)
            index = 719 if rem == 0 else rem - 1
            assert index == (drop - 1) % 720
            assert unrank_factoradic(index) == order == lex_order(drop)
            assert stone == stones[i]
            bowls = reference_bowl_update(bowls, order, drop, stone, i)
            assert bowls == expected_bowls

        for r, (retained, expected_bowls) in enumerate(
            zip(trace.retained_post_stir_sums, trace.post_stir_bowls_trace), 1
        ):
            rem = modulo720_128(retained)
            index = 719 if rem == 0 else rem - 1
            assert index == (retained - 1) % 720
            assert unrank_factoradic(index) == lex_order(retained)
            actual_sum, bowls = reference_post_stir(bowls, r)
            assert actual_sum == retained
            assert bowls == expected_bowls
            assert len(bowls) == 6 and all(1 <= x <= M for x in bowls)

    print(
        "HOST_STAGE1_BOWLS=PASS pairs=72 stones=46/46 visible_orders=46/46 "
        "simultaneous_bowl_updates=276/276 post_stirs=12/12 "
        "permutations=720/720 modulo720=PASS snapshots=PASS",
        flush=True,
    )


if __name__ == "__main__":
    main()
