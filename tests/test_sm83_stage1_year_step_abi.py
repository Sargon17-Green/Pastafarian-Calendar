#!/usr/bin/env python3
"""Independent integer contract for bounded adjacent-year SM83 transition.

The SM83 routine takes a *supplied* c-dependent span. It does not derive
the gate stream, year-5000 rank or seal 11/12 choice. Native329..340 exercise
a separate deterministic synthetic boundary matrix. Dynamic source-derived
host checks use the preexisting normative independent year-path calculation.
"""
from __future__ import annotations

from dataclasses import dataclass

MIN_YEAR, MAX_YEAR = 252, 5778
MIN_I32, MAX_I32 = -(1 << 31), (1 << 31) - 1


@dataclass(frozen=True)
class State:
    opening: int
    closing: int
    year: int
    output: int = 0xCDAB


def advance(current: State, proposal: tuple[int, int], direction: int,
            *, active: bool = True, canonical: bool = True) -> tuple[int, State]:
    """Status and immutable result using Python int; no assembly implementation."""
    if not active:
        return 6, current
    left, right = proposal
    if (not canonical or direction not in (1, 2)
            or not all(MIN_I32 <= x <= MAX_I32 for x in
                       (current.opening, current.closing, left, right))
            or not left < right or not MIN_YEAR <= right - left <= MAX_YEAR):
        return 2, current
    joint = current.closing if direction == 1 else current.opening
    adjoining = left if direction == 1 else right
    if joint != adjoining:
        return 2, current
    candidate = current.year + (1 if direction == 1 else -1)
    if not 0 <= candidate <= 65535:
        return 2, current
    return 0, State(left, right, candidate, current.output)


def check_stage1_year_step_abi() -> None:
    foundation = State(-15057703, -15053459, 5000)
    next_span = (-15053459, -15050000)
    prev_span = (-15058000, -15057703)
    cases = (
        (foundation, next_span, 1, False, True, 6),
        (foundation, next_span, 1, True, True, 0),
        (State(*next_span, 5001), (foundation.opening, foundation.closing), 2, True, True, 0),
        (foundation, (-15053458, -15050000), 1, True, True, 2),
        (foundation, (-15053459, -15053208), 1, True, True, 2),
        (foundation, (-15053459, -15047680), 1, True, True, 2),
        (foundation, next_span, 3, True, True, 2),
        (foundation, next_span, 1, True, False, 2),
        (State(foundation.opening, foundation.closing, 65535), next_span, 1, True, True, 2),
        (State(foundation.opening, foundation.closing, 0), prev_span, 2, True, True, 2),
        (foundation, prev_span, 2, True, True, 0),
    )
    passed = 0
    for initial, proposal, direction, active, canonical, expected in cases:
        snapshot = initial
        status, result = advance(initial, proposal, direction, active=active, canonical=canonical)
        assert status == expected, (passed, status, expected)
        assert initial == snapshot
        if status != 0:
            assert result is initial, (passed, "failed call mutated state")
        else:
            assert result.output == initial.output
            assert result.opening == proposal[0] and result.closing == proposal[1]
        passed += 1
    assert passed == 11
    # Explicit signed32 / length limits, independent of the Native fixtures.
    edges = 0
    for size in (251, 252, 253, 5777, 5778, 5779, 65536, (1 << 31)):
        left = -200000
        status, _ = advance(State(left - 300, left, 5000), (left, left + size), 1)
        assert status == (0 if MIN_YEAR <= size <= MAX_YEAR else 2)
        edges += 1
    for direction, candidate in ((1, 65535), (2, 0)):
        state = State(-15057703, -15053459, candidate)
        proposal = next_span if direction == 1 else prev_span
        assert advance(state, proposal, direction)[0] == 2
        edges += 1

    # Production gate/choice calculations are still Host-only. Check the new
    # ABI against normative c-dependent candidate choices without trusting
    # a previously computed expected-year fixture as an input.
    from test_sm83_stage1_year_path_oracle import year5000, next_year, previous_year
    from test_sm83_stage1_sauce_oracle import FOUNDATION
    calculation_days = (FOUNDATION, FOUNDATION - 1234, FOUNDATION + 1234)
    dynamic = 0
    pairs = set()
    for c in calculation_days:
        base, _, rank = year5000(c)
        pairs.add((base.open_gate, base.close_gate))
        assert rank >= 1
        root = State(base.open_gate, base.close_gate, 5000)
        nxt = next_year(c, base)
        prv = previous_year(c, base)
        st, forward = advance(root, (nxt.open_gate, nxt.close_gate), 1)
        assert st == 0 and forward.year == 5001
        st, reset = advance(forward, (base.open_gate, base.close_gate), 2)
        assert st == 0 and reset == root
        st, backward = advance(root, (prv.open_gate, prv.close_gate), 2)
        assert st == 0 and backward.year == 4999
        st, reset = advance(backward, (base.open_gate, base.close_gate), 1)
        assert st == 0 and reset == root
        dynamic += 4
    assert len(pairs) >= 2, "calculation day must affect selected year spans"
    print(
        f"HOST_STAGE1_YEAR_STEP_ABI=PASS synthetic={passed} edges={edges} "
        f"dynamic_c_dependent={dynamic} directions=NEXT11,PREVIOUS12 "
        "signed32=YES immutable_failure=YES "
        "native_candidate_count=12 native_execution=CI_REQUIRED "
        "gate_generation=HOST_ONLY seal_ranking=HOST_ONLY",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_year_step_abi()
