#!/usr/bin/env python3
"""Independent Python-integer implementation of normative sauce steps E..K.

Builds five stones, 7 hidden drops, 46 visible drops, 6 moving bowls and
12 canonical post-stirs from exact day counters. This does NOT implement
calendar gate selection, cutlet/month weaving, source names, or the native
SM83 dispatcher. Values in the golden JSON are *not* used in computation.

Normative source: pinned main README at
56bc4173aae4975ded019ef5ab5a36249f1424df, sections C..K.
"""
from __future__ import annotations

from dataclasses import dataclass
from itertools import permutations
import json
from pathlib import Path

FOUNDATION = -15_055_671
M = (1 << 127) - 1
# Lexicographic canonical rank 1 corresponds to index 0.
ORDERS = tuple(permutations(range(1, 7)))
INITIAL_STONES = (17, 29, 43, 71, 101)
INITIAL_BOWL_SEEDS = (17, 19, 23, 29, 31, 37)
HIDDEN_GRIND_STONES = (0, 1, 2, 3, 4, 0, 1)
VISIBLE_GRIND_ROWS = (
    (3, 5, 7, 11, 0), (5, 7, 11, 13, 1),
    (7, 11, 13, 17, 2), (11, 13, 17, 19, 3),
    (13, 17, 19, 23, 4), (17, 19, 23, 29, 0),
    (19, 23, 29, 31, 1), (23, 29, 31, 37, 2),
    (29, 31, 37, 41, 3), (31, 37, 41, 43, 4),
    (37, 41, 43, 47, 0),
)
assert len(ORDERS) == 720


def save(x: int) -> int:
    """Canonical retained residue, including 0 and negative integers."""
    return 1 + ((x - 1) % M)


def day_count(d: int) -> int:
    delta = d - FOUNDATION
    return 2 * -delta if delta < 0 else 2 * delta + 1


def counts_for(c: int, t: int) -> tuple[int, int, int, int, int]:
    a, b = day_count(c), day_count(t)
    return (a, b, abs(t - c) + 1, a + b, 1 if t < c else 2 if t == c else 3)


def stones_after(previous: tuple[int, ...], i: int) -> tuple[int, ...]:
    """Five simultaneous updates from the SAME old stones snapshot."""
    wheat, barley, salt, bitter, red = previous
    return (
        save(wheat * wheat + 3 * barley + i),
        save(barley * barley + 5 * salt + wheat),
        save(salt * salt + 7 * bitter + barley),
        save(bitter * bitter + 11 * red + salt),
        save(red * red + 13 * wheat + bitter),
    )


def lex_order(value: int) -> tuple[int, ...]:
    assert 1 <= value <= M
    return ORDERS[(value - 1) % 720]


def bowl_update_from_drop(
    old: tuple[int, ...], order: tuple[int, ...],
    drop: int, stone: tuple[int, ...], i: int,
) -> tuple[int, ...]:
    """Three direct pours; all six new bowls use the original snapshot."""
    pours = {}
    for q in range(1, 4):
        bowl = order[q - 1]
        pours[q] = save(drop * drop + stone[q - 1] * old[bowl - 1] + (2 * q + 1) * i)
    new = [0] * 6
    for q, bowl in enumerate(order, 1):
        prev_bowl = order[(q - 2) % 6]
        next_bowl = order[q % 6]
        p, n = old[prev_bowl - 1], old[next_bowl - 1]
        u = old[bowl - 1] + 2 * p + 3 * n + pours.get(q, 0) + drop + stone[(q - 1) % 5]
        new[bowl - 1] = save(u * u + 5 * p * n + i * q)
    return tuple(new)


def post_stir(
    old: tuple[int, ...], r: int, *, historical_mutant: bool = False,
) -> tuple[int, ...]:
    """The retained S_r belongs in BOTH rank and u (old mutant: raw sum)."""
    raw = sum(old)
    s = save(raw + 149 * r)
    order = lex_order(s)
    new = [0] * 6
    for q, bowl in enumerate(order, 1):
        prev_bowl = order[(q - 2) % 6]
        next_bowl = order[q % 6]
        p, n = old[prev_bowl - 1], old[next_bowl - 1]
        u = old[bowl - 1] + 3 * p + 5 * n + (raw if historical_mutant else s) + r + q * q
        new[bowl - 1] = save(u * u + 7 * p * n)
    return tuple(new)


@dataclass(frozen=True)
class SauceTrace:
    counts: tuple[int, int, int, int, int]
    hidden: tuple[int, ...]
    first_visible: int
    last_visible: int
    order_at_46: tuple[int, ...]
    bowls: tuple[int, ...]
    retained_post_stir_sums: tuple[int, ...]


def compute_sauce(c: int, t: int, *, historical_mutant: bool = False) -> SauceTrace:
    """Calculate from the normative recurrence; no fixture lookup or cache."""
    counts = counts_for(c, t)
    stones = {1: INITIAL_STONES}
    for i in range(2, 47):
        stones[i] = stones_after(stones[i - 1], i)

    hidden = {}
    for k in range(1, 8):
        a, b, cc, d = (2 * k + 1, 3 * k + 1, 4 * k + 2, 4 * k + 4)
        x = save(
            counts[0] + a * counts[1] + b * counts[2] + cc * counts[3]
            + d * counts[4] + sum(stones[k])
        )
        for r, stone_index in enumerate(HIDDEN_GRIND_STONES, 1):
            x = save(x * x + 3 * x + stones[k][stone_index] + r)
        hidden[k] = x

    # Hidden drop 1 sits at position 0; hidden drop 7 at position -6.
    drops = {1 - k: hidden[k] for k in range(1, 8)}
    bowls = tuple(
        save((counts[0] + identity * counts[1] + counts[2] + counts[3]
              + counts[4] + seed * seed) ** 2 + identity)
        for identity, seed in enumerate(INITIAL_BOWL_SEEDS, 1)
    )
    first_visible = 0
    order_at_46 = ()
    for i in range(1, 47):
        stone = stones[i]
        x = save(
            sum(stone[j] * counts[j] for j in range(5))
            + drops[i - 1] + 3 * drops[i - 3] + 5 * drops[i - 7] + i
        )
        for a, b, cc, d, stone_index in VISIBLE_GRIND_ROWS:
            old = x
            x = save(old * old + a * old + b * drops[i - 1]
                     + cc * drops[i - 3] + d * drops[i - 7]
                     + stone[stone_index])
        drops[i] = x
        order = lex_order(x)
        bowls = bowl_update_from_drop(bowls, order, x, stone, i)
        if i == 1:
            first_visible = x
        if i == 46:
            order_at_46 = order

    final_sums = []
    for r in range(1, 13):
        final_sums.append(save(sum(bowls) + 149 * r))
        bowls = post_stir(bowls, r, historical_mutant=historical_mutant)
    assert len(drops) == 53 and len(final_sums) == 12
    return SauceTrace(
        counts, tuple(hidden[k] for k in range(1, 8)), first_visible,
        drops[46], order_at_46, bowls, tuple(final_sums),
    )


def check_stage1_sauce_oracle() -> None:
    fixture = json.loads((Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8"))
    assert fixture["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    assert fixture["foundation"] == FOUNDATION
    checkpoint = fixture["canonical_checkpoint"]
    actual = compute_sauce(FOUNDATION, FOUNDATION)
    assert actual.counts == tuple(checkpoint["work_counts"])
    assert tuple(map(str, actual.hidden)) == tuple(checkpoint["hidden_drops"])
    assert str(actual.first_visible) == checkpoint["visible_drop_1"]
    assert str(actual.last_visible) == checkpoint["visible_drop_46"]
    assert actual.order_at_46 == tuple(checkpoint["order_at_46"])
    assert tuple(map(str, actual.bowls)) == tuple(checkpoint["post_stir_bowls"])
    assert len(actual.retained_post_stir_sums) == 12
    assert all(1 <= v <= M for v in actual.retained_post_stir_sums)

    # Negative control: independently compute the superseded raw-sum mutant.
    bad = compute_sauce(FOUNDATION, FOUNDATION, historical_mutant=True)
    forbidden = fixture["historical_superseded_noncanonical"]
    assert bad.hidden == actual.hidden
    assert bad.first_visible == actual.first_visible
    assert bad.last_visible == actual.last_visible
    assert bad.order_at_46 == actual.order_at_46
    assert bad.retained_post_stir_sums != actual.retained_post_stir_sums
    assert tuple(map(str, bad.bowls)) == tuple(forbidden["forbidden_bowls"])
    assert bad.bowls != actual.bowls

    # AC.1 inputs; outputs are deliberately not read or asserted as computed.
    distinct_results = set()
    for v in fixture["vectors"]:
        trace = compute_sauce(v["c"], v["t"])
        assert trace.counts == counts_for(v["c"], v["t"])
        assert len(trace.hidden) == 7 and len(trace.bowls) == 6
        assert len(set(trace.order_at_46)) == 6
        assert all(1 <= x <= M for x in (*trace.hidden, *trace.bowls))
        assert trace == compute_sauce(v["c"], v["t"]), "non-determinism"
        distinct_results.add(trace.bowls)
    assert len(distinct_results) == 10

    huge = compute_sauce(FOUNDATION - (1 << 80), FOUNDATION + (1 << 80))
    assert huge.counts[0] == 1 << 81
    assert huge.counts[1] == (1 << 81) + 1
    assert huge.counts[2] == (1 << 81) + 1
    assert len(huge.bowls) == 6 and all(1 <= x <= M for x in huge.bowls)

    print(
        "HOST_STAGE1_SAUCE_RECURRENCE=PASS normative_main=56bc4173aae4975ded019ef5ab5a36249f1424df "
        "canonical_checkpoint=FOUNDATION hidden=7/7 visible=1,46/2 "
        "orderAt46=PASS post_stir_bowls=6/6 retained_sum=YES "
        "historical_raw_sum_mutant=REPRODUCED_AND_EXCLUDED "
        "canonical_inputs=10 deterministic=YES unbounded_day_pair=1 "
        "calendar_outputs=NOT_COMPUTED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_sauce_oracle()
