#!/usr/bin/env python3
"""Independently compute year number via gates and NEXT11/PREVIOUS12 (O..R).

This is a bounded, source-derived Python integer Host oracle, not the SM83
calendar engine. No canonical output vector is used as an input to a
calculation. The entire 5-field calendar is not implemented here.

Pinned source: main README at 56bc4173aae4975ded019ef5ab5a36249f1424df,
sections O, P, Q, R, and normative AC.1 vectors.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
import json
from pathlib import Path

from test_sm83_stage1_selection_oracle import (
    FOUNDATION, GAP_MIN, YEAR_MAX, YEAR_MIN, YearCandidate, ask, gate_gap,
    year5000_at_foundation,
)

# Deliberate resource guard for the partial Stage1 Host oracle: all canonical
# AC.1 vectors lie much closer to Foundation than this bound. Beyond it,
# fail closed rather than silently claiming general arbitrary-ordinal support.
MAX_GATE_STEPS = 512
MAX_YEAR_WALKS = 128


@lru_cache(maxsize=4096)
def gate_at(index: int) -> int:
    """Fixed Foundation gate map, independently derived from each gap."""
    if abs(index) > MAX_GATE_STEPS:
        raise NotImplementedError("Stage1 bounded gate horizon exhausted")
    if index == 0:
        return FOUNDATION
    if index > 0:
        return gate_at(index - 1) + gate_gap(index, True)
    return gate_at(index + 1) - gate_gap(-index, False)


def gate_window(lo: int, hi: int) -> tuple[tuple[int, int], ...]:
    """Generate every gate in the [lo,hi] window without missing the edge."""
    if lo > hi:
        raise ValueError("reversed gate window")
    items: list[tuple[int, int]] = []
    anchor = FOUNDATION
    if lo <= anchor <= hi:
        items.append((0, anchor))
    if hi >= anchor:
        for idx in range(1, MAX_GATE_STEPS + 1):
            day = gate_at(idx)
            if lo <= day <= hi:
                items.append((idx, day))
            if day > hi:
                break
        else:
            raise NotImplementedError("positive gate horizon exceeded")
    if lo <= anchor:
        for n in range(1, MAX_GATE_STEPS + 1):
            idx = -n
            day = gate_at(idx)
            if lo <= day <= hi:
                items.append((idx, day))
            if day < lo:
                break
        else:
            raise NotImplementedError("negative gate horizon exceeded")
    return tuple(sorted(items))


def valid_years_at(day: int) -> tuple[YearCandidate, ...]:
    """All (open,close] intervals eligible to be chosen as year 5000."""
    gates = gate_window(day - YEAR_MAX, day + YEAR_MAX)
    result = []
    for ai, start in gates:
        if start >= day:
            continue
        for bi, finish in gates:
            if finish < day:
                continue
            span = finish - start
            if bi - ai >= 6 and YEAR_MIN <= span <= YEAR_MAX:
                result.append(YearCandidate(ai, bi, start, finish))
    result.sort(key=lambda y: (y.length, y.open_gate))
    assert result and len(set((y.open_index, y.close_index) for y in result)) == len(result)
    return tuple(result)


def year5000(calculation: int) -> tuple[YearCandidate, int, int]:
    candidates = valid_years_at(calculation)
    choice = ask(calculation, calculation, 1, 10, len(candidates))
    chosen = candidates[choice.rank - 1]
    assert chosen.open_gate < calculation <= chosen.close_gate
    return chosen, len(candidates), choice.rank


def next_year(calculation: int, previous: YearCandidate) -> YearCandidate:
    """Seal 11: the previous closing gate is the new opening gate."""
    start_i, start = previous.close_index, previous.close_gate
    gates = gate_window(start + 1, start + YEAR_MAX)
    candidates = [
        YearCandidate(start_i, idx, start, day)
        for idx, day in gates
        if idx - start_i >= 6 and YEAR_MIN <= day - start <= YEAR_MAX
    ]
    candidates.sort(key=lambda y: (y.length, y.open_gate))
    assert candidates
    choice = ask(calculation, start, 1, 11, len(candidates))
    selected = candidates[choice.rank - 1]
    assert selected.open_gate == start
    assert selected.open_index == start_i
    return selected


def previous_year(calculation: int, following: YearCandidate) -> YearCandidate:
    """Seal 12: the following opening gate is the new closing gate."""
    close_i, close = following.open_index, following.open_gate
    gates = gate_window(close - YEAR_MAX, close - 1)
    candidates = [
        YearCandidate(idx, close_i, day, close)
        for idx, day in gates
        if close_i - idx >= 6 and YEAR_MIN <= close - day <= YEAR_MAX
    ]
    candidates.sort(key=lambda y: (y.length, y.open_gate))
    assert candidates
    choice = ask(calculation, close, 1, 12, len(candidates))
    selected = candidates[choice.rank - 1]
    assert selected.close_gate == close
    assert selected.close_index == close_i
    return selected


@dataclass(frozen=True)
class YearResult:
    year_number: int
    span: YearCandidate
    walks: int
    direction: int


def find_year(calculation: int, target: int) -> YearResult:
    """From calculation-specific 5000, walk in exactly one direction."""
    span, _, _ = year5000(calculation)
    number, steps = 5000, 0
    direction = 3 if target > span.close_gate else 1 if target <= span.open_gate else 2
    while target > span.close_gate:
        steps += 1
        if steps > MAX_YEAR_WALKS:
            raise NotImplementedError("bounded Stage1 year-walk horizon exceeded")
        span = next_year(calculation, span)
        number += 1
    while target <= span.open_gate:
        steps += 1
        if steps > MAX_YEAR_WALKS:
            raise NotImplementedError("bounded Stage1 year-walk horizon exceeded")
        span = previous_year(calculation, span)
        number -= 1
    assert span.open_gate < target <= span.close_gate
    assert span.close_index - span.open_index >= 6
    assert YEAR_MIN <= span.length <= YEAR_MAX
    return YearResult(number, span, steps, direction)


def check_stage1_year_path_oracle() -> None:
    data = json.loads(
        (Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8")
    )
    assert data["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    checkpoint = data["canonical_checkpoint"]

    selected, options, rank = year5000_at_foundation()
    computed, all_options, computed_rank = year5000(FOUNDATION)
    assert (selected, options, rank) == (computed, all_options, computed_rank)
    assert computed.open_gate == checkpoint["year5000_open_gate"]
    assert computed.close_gate == checkpoint["year5000_close_gate"]
    assert computed.open_gate < FOUNDATION <= computed.close_gate

    checked = 0
    previous_walks = 0
    next_walks = 0
    nonfoundation_calculations = set()
    for record in data["vectors"]:
        c, t = record["c"], record["t"]
        expected_year = record["expected"][0]  # ASSERTION ONLY; never input to the oracle.
        result = find_year(c, t)
        assert result.year_number == expected_year, (
            record["id"], c, t, result, expected_year
        )
        assert result == find_year(c, t), "year-walk not deterministic"
        assert result.span.open_gate < t <= result.span.close_gate
        if c != FOUNDATION:
            nonfoundation_calculations.add(c)
        if result.direction == 1:
            previous_walks += result.walks
            assert result.year_number <= 5000
        elif result.direction == 3:
            next_walks += result.walks
            assert result.year_number >= 5000
        else:
            assert result.year_number == 5000 and result.walks == 0
        checked += 1
    assert checked == 10 and len(nonfoundation_calculations) >= 3
    assert previous_walks >= 1 and next_walks >= 2

    # Exact half-open year boundaries: opening day belongs to PREVIOUS,
    # closing day to the current year, and the day after to NEXT.
    current = find_year(FOUNDATION, FOUNDATION).span
    assert find_year(FOUNDATION, current.open_gate).year_number == 4999
    assert find_year(FOUNDATION, current.open_gate + 1).year_number == 5000
    assert find_year(FOUNDATION, current.close_gate).year_number == 5000
    assert find_year(FOUNDATION, current.close_gate + 1).year_number == 5001

    gates = gate_window(FOUNDATION - 10000, FOUNDATION + 10000)
    assert len(gates) > 20
    assert all(gates[i][0] < gates[i + 1][0] for i in range(len(gates) - 1))
    assert all(gates[i][1] < gates[i + 1][1] for i in range(len(gates) - 1))
    assert all(GAP_MIN <= gates[i + 1][1] - gates[i][1] <= 963
               for i in range(len(gates) - 1))
    print(
        "HOST_STAGE1_YEAR_PATH=PASS "
        f"golden_year_numbers={checked}/10 year5000_candidates={all_options} "
        f"foundation_rank={computed_rank} "
        f"forward_walks={next_walks} backward_walks={previous_walks} "
        f"nonfoundation_calculations={len(nonfoundation_calculations)} "
        "half_open_gate_edges=4 sorted_gate_map=YES "
        "full_calendar_five_fields=NOT_COMPUTED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_year_path_oracle()
