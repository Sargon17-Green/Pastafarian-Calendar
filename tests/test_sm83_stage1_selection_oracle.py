#!/usr/bin/env python3
"""Normative bowl answer/short-and-wide Equal Selection oracle (M..Q).

All answers are calculated from the independently computed sauce E..K, not
from reference vector output labels. Wide selection intentionally follows
the historically specified nonuniform mechanism; it is NOT standard
rejection sampling from a uniform wide random number.

Source pinned to main README 56bc4173aae4975ded019ef5ab5a36249f1424df,
sections M, N and O through Q. Host-only; NOT an SM83 dispatcher.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
import json
from pathlib import Path

from test_sm83_stage1_sauce_oracle import (
    FOUNDATION, M, SauceTrace, compute_sauce, save,
)

SEALS = frozenset((1, 10, 11, 12, 20, 21, 22, 30, 31, 32, 33))
GAP_MIN, GAP_MAX = 42, 963
GAP_CHOICES = 922
YEAR_MIN, YEAR_MAX = 252, 5778


@dataclass(frozen=True)
class AnswerFlow:
    first: int
    step: int
    modulus: int = M

    def __post_init__(self) -> None:
        if self.modulus < 2 or not 1 <= self.first <= self.modulus:
            raise ValueError("invalid response ring")
        if self.step not in (-1, 1):
            raise ValueError("direction must be +1 or -1")

    def at(self, offset: int) -> int:
        if offset < 0:
            raise ValueError("response index must be nonnegative")
        return 1 + ((self.first - 1 + self.step * offset) % self.modulus)


@dataclass(frozen=True)
class Choice:
    rank: int
    digits: int
    initial_word: int
    accepted_word: int
    limit: int
    rejected_steps: int


def select(flow: AnswerFlow, n: int) -> Choice:
    """The exact short or wide choice prescribed by section N.

    The wide word's digits come from consecutive A_j, with A_0 the least
    significant digit; on rejection, walk from W itself on 1..M^k in the
    prescribed direction. Do NOT draw a fresh independent wide number.
    """
    if n < 1:
        raise ValueError("candidate count must be positive")
    modulus = flow.modulus
    if n <= modulus:
        limit = (modulus // n) * n
        value = flow.at(0)
        steps = 0
        while value > limit:
            steps += 1
            value = flow.at(steps)
            if steps > modulus:
                raise AssertionError("short selection could not reach an allowed value")
        return Choice(1 + ((value - 1) % n), 1, flow.first, value, limit, steps)

    digits, capacity = 1, modulus
    while capacity < n:
        digits += 1
        capacity *= modulus
    assert digits >= 2 and capacity // modulus < n <= capacity
    word, base = 1, 1
    for j in range(digits):
        word += (flow.at(j) - 1) * base
        base *= modulus
    assert base == capacity and 1 <= word <= capacity
    limit = (capacity // n) * n
    assert n <= limit <= capacity
    if word <= limit:
        accepted, steps = word, 0
    elif flow.step == 1:
        # From the rejected end region (limit, capacity], the very next
        # accepted word in the forward direction is 1, after wrap.
        accepted, steps = 1, capacity - word + 1
    else:
        # Reverse traversal of that same rejected tail reaches limit first.
        accepted, steps = limit, word - limit
    assert 1 <= accepted <= limit and steps >= 0
    assert accepted == 1 + ((word - 1 + flow.step * steps) % capacity)
    return Choice(1 + ((accepted - 1) % n), digits, word, accepted, limit, steps)


def bowl_answer_flow(sauce: SauceTrace, bowl: int, seal: int) -> AnswerFlow:
    """Resolve 'next' from orderAt46, never from fixed numeric bowl ID."""
    if bowl not in (1, 2, 3, 4, 5, 6) or seal not in SEALS:
        raise ValueError("unknown bowl or seal")
    order = sauce.order_at_46
    assert len(order) == 6 and set(order) == set(range(1, 7))
    next_bowl = order[(order.index(bowl) + 1) % 6]
    q = sauce.bowls
    a0 = save((q[bowl - 1] + seal + 181) ** 2 + 179 * q[next_bowl - 1] + seal)
    direction_value = save((a0 + seal + 1 + 193) ** 2 + 193 * a0 + 197 * q[5])
    return AnswerFlow(a0, 1 if direction_value % 2 else -1)


def ask(calculation: int, target: int, bowl: int, seal: int, n: int) -> Choice:
    return select(bowl_answer_flow(compute_sauce(calculation, target), bowl, seal), n)


@lru_cache(maxsize=1024)
def gate_gap(index: int, positive: bool) -> int:
    """Gaps are computed using (F,F±n), bowl 1, seal 1, rank 1..922."""
    if index < 1:
        raise ValueError("gate gap index starts at 1")
    target = FOUNDATION + (index if positive else -index)
    answer = ask(FOUNDATION, target, 1, 1, GAP_CHOICES)
    gap = answer.rank + 41
    assert GAP_MIN <= gap <= GAP_MAX
    return gap


@dataclass(frozen=True)
class YearCandidate:
    open_index: int
    close_index: int
    open_gate: int
    close_gate: int

    @property
    def length(self) -> int:
        return self.close_gate - self.open_gate


def year5000_at_foundation() -> tuple[YearCandidate, int, int]:
    """Compute all eligibility pairs containing F within the 5778-day cap.

    This is intentionally limited to c=Foundation, the sole year-gate
    checkpoint currently supplied. It does not claim a generic year engine.
    """
    gates = {0: FOUNDATION}
    left = FOUNDATION
    for n in range(1, 141):
        left -= gate_gap(n, False)
        gates[-n] = left
        if left < FOUNDATION - YEAR_MAX:
            break
    else:
        raise AssertionError("negative gates did not reach the year bound")
    right = FOUNDATION
    for n in range(1, 141):
        right += gate_gap(n, True)
        gates[n] = right
        if right > FOUNDATION + YEAR_MAX:
            break
    else:
        raise AssertionError("positive gates did not reach the year bound")
    candidates = []
    for open_idx in sorted(n for n in gates if n < 0):
        start = gates[open_idx]
        if start < FOUNDATION - YEAR_MAX:
            continue
        for close_idx in sorted(n for n in gates if n >= 0):
            finish = gates[close_idx]
            if finish > FOUNDATION + YEAR_MAX:
                continue
            span = finish - start
            if (
                close_idx - open_idx >= 6
                and YEAR_MIN <= span <= YEAR_MAX
                and start < FOUNDATION <= finish
            ):
                candidates.append(YearCandidate(open_idx, close_idx, start, finish))
    assert candidates
    candidates.sort(key=lambda p: (p.length, p.open_gate))
    assert len({(p.open_index, p.close_index) for p in candidates}) == len(candidates)
    rank = ask(FOUNDATION, FOUNDATION, 1, 10, len(candidates)).rank
    assert 1 <= rank <= len(candidates)
    return candidates[rank - 1], len(candidates), rank


def brute_choice(flow: AnswerFlow, n: int) -> Choice:
    """Small-ring independent enumerator; never calls select()."""
    m = flow.modulus
    k, space = 1, m
    while space < n:
        space *= m
        k += 1
    answers = [flow.at(i) for i in range(k)]
    initial = 1 + sum((a - 1) * (m ** i) for i, a in enumerate(answers))
    limit = (space // n) * n
    word = initial
    moves = 0
    while word > limit:
        moves += 1
        word = ((word - 1 + flow.step) % space) + 1
        if moves > space:
            raise AssertionError("brute enumerator cannot accept")
    return Choice((word - 1) % n + 1, k, initial, word, limit, moves)


def check_stage1_selection_oracle() -> None:
    fixture = json.loads(
        (Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8")
    )
    assert fixture["foundation"] == FOUNDATION
    assert fixture["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"

    # Exhaust every start and direction for small rings; this independently
    # checks both short rejection and wide carry / wrap semantics.
    checked = 0
    rejected_short = 0
    rejected_wide = 0
    for modulus in (2, 3, 4, 5):
        for first in range(1, modulus + 1):
            for step in (-1, 1):
                flow = AnswerFlow(first, step, modulus)
                assert [flow.at(i) for i in range(modulus)] == [
                    1 + ((first - 1 + step * i) % modulus)
                    for i in range(modulus)
                ]
                for n in range(1, modulus * modulus + 1):
                    got = select(flow, n)
                    expected = brute_choice(flow, n)
                    assert got == expected, (modulus, first, step, n, got, expected)
                    assert 1 <= got.rank <= n
                    assert got.digits == (1 if n <= modulus else 2)
                    if got.rejected_steps:
                        if n <= modulus:
                            rejected_short += 1
                        else:
                            rejected_wide += 1
                    checked += 1
    assert checked == sum(2 * m * m * m for m in (2, 3, 4, 5))
    assert rejected_short > 0 and rejected_wide > 0

    # The canonical N>M mechanism is demonstrably not a uniform chooser.
    outputs = {
        select(AnswerFlow(first, direction, 3), 4).rank
        for first in (1, 2, 3) for direction in (-1, 1)
    }
    assert outputs == {2, 3, 4}, outputs  # rank 1 has zero probability.

    checkpoint = fixture["canonical_checkpoint"]
    sauce = compute_sauce(FOUNDATION, FOUNDATION)
    assert tuple(map(str, sauce.bowls)) == tuple(checkpoint["post_stir_bowls"])
    assert sauce.order_at_46 == tuple(checkpoint["order_at_46"])
    for bowl in range(1, 7):
        for seal in SEALS:
            flow = bowl_answer_flow(sauce, bowl, seal)
            assert 1 <= flow.first <= M and flow.step in (-1, 1)
            assert flow.at(0) == flow.first
            assert flow.at(M) == flow.first
            assert flow.at(1) == 1 + ((flow.first - 1 + flow.step) % M)
            for n in (1, 2, 17, 47, 720, 922, M // 2 + 1, M, M + 1, M * M + 1):
                result = select(flow, n)
                assert 1 <= result.rank <= n
                assert result == select(flow, n)
                assert result.digits == (1 if n <= M else 2 if n <= M * M else 3)

    # The source's gate equation is a bound on computed answers, not an
    # independently provided golden gate position for n>0.
    sampled = []
    for n in range(1, 5):
        sampled.extend((gate_gap(n, True), gate_gap(n, False)))
    assert len(sampled) == 8 and all(42 <= gap <= 963 for gap in sampled)
    assert all(gate_gap(n, True) == gate_gap(n, True) for n in range(1, 5))

    # Canonical AC.1 Foundation checkpoint includes a unique selected year
    # with fully specified gates. No fixture output is fed to selection.
    selected, options, rank = year5000_at_foundation()
    assert selected.open_gate == checkpoint["year5000_open_gate"], (
        "computed year5000 opening gate mismatch", selected, options, rank,
        checkpoint["year5000_open_gate"],
    )
    assert selected.close_gate == checkpoint["year5000_close_gate"], (
        "computed year5000 closing gate mismatch", selected, options, rank,
        checkpoint["year5000_close_gate"],
    )
    assert selected.length == 4244 and selected.open_gate < FOUNDATION <= selected.close_gate
    assert options >= rank >= 1
    print(
        "HOST_STAGE1_ANSWER_SELECTION=PASS "
        f"small_ring_exhaustive={checked} rejected_short={rejected_short} "
        f"rejected_wide={rejected_wide} wide_nonuniform_unreachable_rank=1 "
        "bowls=6 seals=11 short_and_wide=YES negative_direction=YES "
        "gate_gap_samples=8 all_in_42_963=YES "
        f"foundation_year5000=PASS options={options} selected_rank={rank} "
        "gates=-15057703,-15053459 "
        "calendar_five_fields=NOT_COMPUTED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_selection_oracle()
