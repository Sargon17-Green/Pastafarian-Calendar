#!/usr/bin/env python3
"""Independent Python-integer oracle for the SM83 short Equal Selection ABI."""
from __future__ import annotations

from test_sm83_stage1_selection_oracle import (
    AnswerFlow, GAP_MIN, M, YEAR_MAX, YEAR_MIN, YearCandidate,
    bowl_answer_flow, select,
)
from test_sm83_stage1_sauce_oracle import FOUNDATION, compute_sauce
from test_sm83_stage1_year_path_oracle import (
    gate_window, next_year, previous_year, valid_years_at, year5000,
)

MAX_CANDIDATES = (YEAR_MAX // GAP_MIN + 1) ** 2
assert MAX_CANDIDATES == 19044


def short_rank(a0: int, direction: int, count: int) -> int:
    """Exact short-choice rank, independently expressed with Python integers."""
    if not 1 <= a0 <= M:
        raise ValueError("A0 is not a canonical positive 127-bit residue")
    if direction not in (-1, 1):
        raise ValueError("direction must be +1 or -1")
    if not 1 <= count <= MAX_CANDIDATES:
        raise ValueError("candidate count outside the proven Stage1 bound")
    limit = M - (M % count)
    if a0 > limit:
        return 1 if direction == 1 else count
    return 1 + ((a0 - 1) % count)


def next_candidates(previous: YearCandidate) -> tuple[YearCandidate, ...]:
    start_i, start = previous.close_index, previous.close_gate
    gates = gate_window(start + 1, start + YEAR_MAX)
    candidates = [
        YearCandidate(start_i, index, start, day)
        for index, day in gates
        if index - start_i >= 6 and YEAR_MIN <= day - start <= YEAR_MAX
    ]
    candidates.sort(key=lambda item: (item.length, item.open_gate))
    return tuple(candidates)


def previous_candidates(following: YearCandidate) -> tuple[YearCandidate, ...]:
    close_i, close = following.open_index, following.open_gate
    gates = gate_window(close - YEAR_MAX, close - 1)
    candidates = [
        YearCandidate(index, close_i, day, close)
        for index, day in gates
        if close_i - index >= 6 and YEAR_MIN <= close - day <= YEAR_MAX
    ]
    candidates.sort(key=lambda item: (item.length, item.open_gate))
    return tuple(candidates)


def check_stage1_short_select_abi() -> None:
    synthetic = (
        (1, 1, 1, 1),
        (M, 1, 1, 1),
        (M, 1, 2, 1),
        (M, -1, 2, 2),
        (M - 1, 1, 2, 2),
        (M - 1, 1, 3, 3),
        (M - 3, -1, 5, 4),
        (M, -1, 922, 922),
        (M, -1, 19044, 19044),
        (1, 1, 19044, 1),
    )
    for a0, direction, count, expected in synthetic:
        got = short_rank(a0, direction, count)
        assert got == expected
        assert got == select(AnswerFlow(a0, direction), count).rank
    synthetic_checked = len(synthetic)

    boundary_checks = 0
    for count in (1, 2, 3, 5, 922, MAX_CANDIDATES):
        limit = M - (M % count)
        values = sorted({1, M, max(1, limit - 1), limit, min(M, limit + 1)})
        for a0 in values:
            for direction in (-1, 1):
                got = short_rank(a0, direction, count)
                assert got == select(AnswerFlow(a0, direction), count).rank
                assert 1 <= got <= count
                if a0 <= limit:
                    assert got == 1 + ((a0 - 1) % count)
                else:
                    assert got == (1 if direction == 1 else count)
                boundary_checks += 1

    invalid = ((0, 1, 1), (M + 1, 1, 1), (1, 0, 1), (1, 1, 0),
               (1, 1, MAX_CANDIDATES + 1))
    for a0, direction, count in invalid:
        try:
            short_rank(a0, direction, count)
        except ValueError:
            pass
        else:
            raise AssertionError((a0, direction, count))

    dynamic = 0
    for calculation in (FOUNDATION, FOUNDATION - 1234, FOUNDATION + 1234):
        base, count10, _ = year5000(calculation)
        candidates10 = valid_years_at(calculation)
        flow10 = bowl_answer_flow(compute_sauce(calculation, calculation), 1, 10)
        rank10 = short_rank(flow10.first, flow10.step, count10)
        assert rank10 == select(flow10, count10).rank
        assert candidates10[rank10 - 1] == base
        assert count10 <= MAX_CANDIDATES
        dynamic += 1

        candidates11 = next_candidates(base)
        flow11 = bowl_answer_flow(compute_sauce(calculation, base.close_gate), 1, 11)
        rank11 = short_rank(flow11.first, flow11.step, len(candidates11))
        assert rank11 == select(flow11, len(candidates11)).rank
        assert candidates11[rank11 - 1] == next_year(calculation, base)
        assert 1 <= len(candidates11) <= MAX_CANDIDATES
        dynamic += 1

        candidates12 = previous_candidates(base)
        flow12 = bowl_answer_flow(compute_sauce(calculation, base.open_gate), 1, 12)
        rank12 = short_rank(flow12.first, flow12.step, len(candidates12))
        assert rank12 == select(flow12, len(candidates12)).rank
        assert candidates12[rank12 - 1] == previous_year(calculation, base)
        assert 1 <= len(candidates12) <= MAX_CANDIDATES
        dynamic += 1

    assert dynamic == 9
    print(
        "HOST_STAGE1_SHORT_SELECT_ABI=PASS "
        f"synthetic={synthetic_checked} boundary_checks={boundary_checks} "
        f"dynamic_c_dependent={dynamic} seals=10,11,12 "
        f"max_candidates={MAX_CANDIDATES} "
        "independent_Python_int=YES native_execution=CI_REQUIRED "
        "sauce_and_gate_generation=NOT_IMPLEMENTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_short_select_abi()
