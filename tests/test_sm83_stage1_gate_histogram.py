#!/usr/bin/env python3
"""Independent Host oracle for the bounded Stage1 gate-year radix histogram.

The runtime ordering is (year length, opening gate). This test compares the
radix histogram selector with an independently full-sorted candidate list.
Synthetic windows exercise the bounded combinatorics; one Foundation window
uses the source-derived gate stream and the real bowl-1/seal-10 answer flow.
This is Host-only evidence, not an SM83 Native acceptance.
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass

from test_sm83_stage1_selection_oracle import (
    FOUNDATION,
    YEAR_MAX,
    YEAR_MIN,
    ask,
)
from test_sm83_stage1_year_path_oracle import gate_window

MIN_GATE_GAP = 42
MAX_GATE_GAP = 963
MAX_GATES_PER_SIDE = YEAR_MAX // MIN_GATE_GAP + 1
MAX_CANDIDATES = MAX_GATES_PER_SIDE * MAX_GATES_PER_SIDE
SPAN_BUCKETS = YEAR_MAX - YEAR_MIN + 1
HIGH_BUCKETS = (YEAR_MAX >> 8) + 1
LOW_BUCKETS = 256

# A 256-wide high-byte bucket can contain at most seven closes per opening
# gate: floor(255 / 42) + 1. The low-byte bucket fixes the exact span, so
# each opening gate contributes at most one candidate there.
MAX_HIGH_BUCKET_COUNT = MAX_GATES_PER_SIDE * (((LOW_BUCKETS - 1) // MIN_GATE_GAP) + 1)
MAX_LOW_BUCKET_COUNT = MAX_GATES_PER_SIDE


@dataclass(frozen=True)
class Candidate:
    open_index: int
    close_index: int
    open_gate: int
    close_gate: int

    @property
    def length(self) -> int:
        return self.close_gate - self.open_gate


def build_candidates(
    left: list[tuple[int, int]],
    right: list[tuple[int, int]],
) -> list[Candidate]:
    """Enumerate in opening-gate-major order, without sorting."""
    assert len(left) <= MAX_GATES_PER_SIDE
    assert len(right) <= MAX_GATES_PER_SIDE
    assert len(left) * len(right) <= MAX_CANDIDATES
    assert all(
        left[i][0] < left[i + 1][0] and left[i][1] < left[i + 1][1]
        for i in range(len(left) - 1)
    )
    assert all(
        right[i][0] < right[i + 1][0] and right[i][1] < right[i + 1][1]
        for i in range(len(right) - 1)
    )

    result: list[Candidate] = []
    for open_index, open_gate in left:
        for close_index, close_gate in right:
            if close_index - open_index < 6:
                continue
            span = close_gate - open_gate
            if YEAR_MIN <= span <= YEAR_MAX:
                result.append(
                    Candidate(open_index, close_index, open_gate, close_gate)
                )
    return result


def histogram_select(
    candidates: list[Candidate],
    rank: int,
) -> tuple[Candidate, int, int]:
    """Select by 23xuint16 high histogram, 256xuint8 low histogram, then tie scan."""
    if not 1 <= rank <= len(candidates):
        raise ValueError("rank outside candidate count")

    high_counts = [0] * HIGH_BUCKETS
    for item in candidates:
        high_counts[item.length >> 8] += 1
    assert sum(high_counts) == len(candidates)
    assert max(high_counts, default=0) <= MAX_HIGH_BUCKET_COUNT

    remaining = rank
    selected_high = None
    for bucket, count in enumerate(high_counts):
        if remaining > count:
            remaining -= count
        else:
            selected_high = bucket
            break
    assert selected_high is not None

    low_counts = [0] * LOW_BUCKETS
    for item in candidates:
        if item.length >> 8 == selected_high:
            low_counts[item.length & 0xFF] += 1
    assert sum(low_counts) == high_counts[selected_high]
    assert max(low_counts, default=0) <= MAX_LOW_BUCKET_COUNT

    selected_low = None
    for bucket, count in enumerate(low_counts):
        if remaining > count:
            remaining -= count
        else:
            selected_low = bucket
            break
    assert selected_low is not None

    selected_span = (selected_high << 8) | selected_low

    # candidates were generated with opening gates ascending, then closing
    # gates ascending. For a fixed span each opening gate has at most one
    # matching close, so this scan implements the exact tie-break without sort.
    for item in candidates:
        if item.length == selected_span:
            remaining -= 1
            if remaining == 0:
                return (
                    item,
                    max(high_counts, default=0),
                    max(low_counts, default=0),
                )
    raise AssertionError("rank within selected span was not found")


def make_deterministic_window(seed: int) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    """Create a valid bounded gate window with deterministic 42..963 gaps."""
    state = (seed ^ 0x9E3779B9) & 0xFFFFFFFF

    def next_u32() -> int:
        nonlocal state
        state = (1664525 * state + 1013904223) & 0xFFFFFFFF
        return state

    if seed % 7 == 0:
        # c itself is a gate; the preceding gap is at least 42.
        left_near = 42 + (next_u32() % 922)
        right_near = 0
    else:
        # c lies strictly between two gates; their combined distance is >=42.
        left_near = 1 + (next_u32() % 41)
        right_near = 42 - left_near + (next_u32() % 922)

    left_descending = [-left_near]
    while len(left_descending) < MAX_GATES_PER_SIDE:
        next_gate = left_descending[-1] - (42 + (next_u32() % 922))
        if next_gate < -YEAR_MAX:
            break
        left_descending.append(next_gate)
    left_offsets = sorted(left_descending)

    right_offsets = [right_near]
    while len(right_offsets) < MAX_GATES_PER_SIDE:
        next_gate = right_offsets[-1] + (42 + (next_u32() % 922))
        if next_gate > YEAR_MAX:
            break
        right_offsets.append(next_gate)

    left = [(i, offset) for i, offset in enumerate(left_offsets)]
    right = [
        (len(left_offsets) + i, offset)
        for i, offset in enumerate(right_offsets)
    ]

    assert all(
        42 <= left[i + 1][1] - left[i][1] <= MAX_GATE_GAP
        for i in range(len(left) - 1)
    )
    assert all(
        42 <= right[i + 1][1] - right[i][1] <= MAX_GATE_GAP
        for i in range(len(right) - 1)
    )
    assert 42 <= right[0][1] - left[-1][1] <= MAX_GATE_GAP
    return left, right


def check_synthetic_windows() -> tuple[int, int, int, int, int]:
    tested = 0
    attempts = 0
    boundary_checks = 0
    max_candidates_seen = 0
    max_span_bucket_seen = 0
    max_high_seen = 0
    max_low_seen = 0

    while tested < 1000 and attempts < 10000:
        left, right = make_deterministic_window(attempts)
        candidates = build_candidates(left, right)
        attempts += 1
        if not candidates:
            continue

        full_sorted = sorted(
            candidates,
            key=lambda item: (item.length, item.open_gate),
        )
        rank_seed = (
            (attempts - 1) * 2654435761 + 0xA5A5A5A5
        ) & 0xFFFFFFFF
        rank = 1 + (rank_seed % len(candidates))
        selected, high_max, low_max = histogram_select(candidates, rank)
        assert selected == full_sorted[rank - 1], (
            attempts - 1,
            rank,
            selected,
            full_sorted[rank - 1],
        )

        if tested % 25 == 0:
            for boundary_rank in sorted(
                {1, len(candidates), (len(candidates) + 1) // 2}
            ):
                boundary_selected, _, _ = histogram_select(
                    candidates, boundary_rank
                )
                assert boundary_selected == full_sorted[boundary_rank - 1]
                boundary_checks += 1

        max_candidates_seen = max(max_candidates_seen, len(candidates))
        max_span_bucket_seen = max(
            max_span_bucket_seen,
            max(Counter(item.length for item in candidates).values()),
        )
        max_high_seen = max(max_high_seen, high_max)
        max_low_seen = max(max_low_seen, low_max)
        tested += 1

    assert tested == 1000, f"only {tested}/1000 nonempty windows were tested"
    assert max_candidates_seen <= MAX_CANDIDATES
    assert max_span_bucket_seen <= MAX_GATES_PER_SIDE
    assert max_high_seen <= MAX_HIGH_BUCKET_COUNT
    assert max_low_seen <= MAX_LOW_BUCKET_COUNT
    return (
        tested,
        boundary_checks,
        max_candidates_seen,
        max_span_bucket_seen,
        max_high_seen,
    )


def check_maximum_tie_bucket() -> int:
    """Stress the per-span tie-break with 138 gates on each side."""
    left = [
        (i, -YEAR_MAX + MIN_GATE_GAP * i)
        for i in range(MAX_GATES_PER_SIDE)
    ]
    right = [
        (MAX_GATES_PER_SIDE + i, 18 + MIN_GATE_GAP * i)
        for i in range(MAX_GATES_PER_SIDE)
    ]
    candidates = build_candidates(left, right)
    full_sorted = sorted(
        candidates,
        key=lambda item: (item.length, item.open_gate),
    )
    bucket_max = max(Counter(item.length for item in candidates).values())
    assert bucket_max == 137
    assert bucket_max <= MAX_GATES_PER_SIDE
    for rank in (1, 69, 137):
        selected, high_max, low_max = histogram_select(candidates, rank)
        assert selected == full_sorted[rank - 1]
        assert high_max <= MAX_HIGH_BUCKET_COUNT
        assert low_max <= MAX_LOW_BUCKET_COUNT
    return bucket_max


def check_source_derived_foundation_window() -> tuple[int, int]:
    gates = gate_window(
        FOUNDATION - YEAR_MAX,
        FOUNDATION + YEAR_MAX,
    )
    left = [(index, day) for index, day in gates if day < FOUNDATION]
    right = [(index, day) for index, day in gates if day >= FOUNDATION]
    candidates = build_candidates(left, right)
    assert len(candidates) == 43

    full_sorted = sorted(
        candidates,
        key=lambda item: (item.length, item.open_gate),
    )
    answer = ask(
        FOUNDATION,
        FOUNDATION,
        1,
        10,
        len(candidates),
    )
    assert answer.rank == 15
    selected, high_max, low_max = histogram_select(candidates, answer.rank)
    assert selected == full_sorted[answer.rank - 1]
    assert high_max <= MAX_HIGH_BUCKET_COUNT
    assert low_max <= MAX_LOW_BUCKET_COUNT
    return len(candidates), answer.rank


def main() -> None:
    assert SPAN_BUCKETS == 5527
    assert HIGH_BUCKETS == 23
    assert LOW_BUCKETS == 256
    assert MAX_CANDIDATES == 19044
    assert MAX_HIGH_BUCKET_COUNT == 966
    assert MAX_LOW_BUCKET_COUNT == 138

    windows, boundary_checks, max_candidates, max_span_bucket, max_high = (
        check_synthetic_windows()
    )
    stress_bucket = check_maximum_tie_bucket()
    foundation_candidates, foundation_rank = (
        check_source_derived_foundation_window()
    )

    print(
        "HOST_STAGE1_GATE_HISTOGRAM=PASS "
        f"windows={windows} sampled_rank_checks={windows} "
        f"boundary_rank_checks={boundary_checks} "
        f"foundation_candidates={foundation_candidates} "
        f"foundation_rank={foundation_rank} "
        f"candidate_bound={MAX_CANDIDATES} span_buckets={SPAN_BUCKETS} "
        f"per_span_bound={MAX_GATES_PER_SIDE} stress_bucket={stress_bucket} "
        f"high_hist={HIGH_BUCKETS}x16bit high_count_bound={MAX_HIGH_BUCKET_COUNT} "
        f"low_hist={LOW_BUCKETS}x8bit low_count_bound={MAX_LOW_BUCKET_COUNT} "
        "scratch_bytes=854 sram=UNTOUCHED",
        flush=True,
    )


if __name__ == "__main__":
    main()
