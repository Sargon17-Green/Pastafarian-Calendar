#!/usr/bin/env python3
"""Unseeded, bounded gate-segment *navigation* proof of concept.

The injected gap function is NOT an independent sauce oracle. Do not use these
synthetic proofs to certify production dates or the canonical gate-gap formula.
No production implementation or its 8192-index ceiling is changed.
"""
from __future__ import annotations

from dataclasses import dataclass
import hashlib
import time
from typing import Callable, Mapping

FOUNDATION = -15055671
TABLETS = -278522
GAP_MIN, GAP_MAX = 42, 963
PRODUCTION_SEGMENT_LIMIT = 8192
PROOF_TOTAL_LIMIT = 32768


class SegmentProofError(ValueError):
    pass


@dataclass(frozen=True)
class Segment:
    first_index: int
    last_index: int
    start_day: int
    end_day: int
    questions: int
    chain_sha256: str


@dataclass(frozen=True)
class NavigationProof:
    target_day: int
    direction: int
    bracket_index: int
    bracket_low: int
    bracket_high: int
    steps: int
    anchor_checks: tuple[int, ...]
    segments: tuple[Segment, ...]
    independent_sauce: bool = False
    certified: bool = False


def locate_unseeded(
    target_day: int,
    gap_at_index: Callable[[int], int],
    *,
    expected_anchors: Mapping[int, int] | None = None,
    segment_limit: int = PRODUCTION_SEGMENT_LIMIT,
    total_limit: int = PROOF_TOTAL_LIMIT,
    deadline: float | None = None,
) -> NavigationProof:
    """Walk from FOUNDATION only; expected_anchors are comparison-only.

    Gap query i uses *global signed* gate index i, not segment-local index.
    Positive crossings add gap(+i), negative crossings subtract gap(-i).
    The return bracket contains target_day, inclusive at both ends.
    Work is limited globally and per segment; no checkpoint is used as a seed.
    """
    if type(target_day) is not int or target_day == FOUNDATION:
        raise SegmentProofError("E_TARGET_DAY")
    if (type(segment_limit) is not int or not 1 <= segment_limit <= PRODUCTION_SEGMENT_LIMIT
            or type(total_limit) is not int or not 1 <= total_limit <= PROOF_TOTAL_LIMIT):
        raise SegmentProofError("E_NAV_BUDGET")
    direction = 1 if target_day > FOUNDATION else -1
    distance = abs(target_day - FOUNDATION)
    # A lower bound only, never a claim that a target is reachable.
    if (distance + GAP_MAX - 1) // GAP_MAX > total_limit:
        raise SegmentProofError("E_GEOMETRY_BUDGET")
    anchors = {} if expected_anchors is None else dict(expected_anchors)
    if any(type(k) is not int or type(v) is not int for k, v in anchors.items()):
        raise SegmentProofError("E_ANCHOR_TYPE")
    if 0 in anchors and anchors[0] != FOUNDATION:
        raise SegmentProofError("E_ANCHOR_ORIGIN")

    pos = FOUNDATION
    chain = hashlib.sha256(b"GATE_SEGMENT_UNSEEDED_V1\n0:-15055671\n").hexdigest()
    parts: list[Segment] = []
    checked: list[int] = [0] if 0 in anchors else []
    start_day = FOUNDATION
    first_index = direction
    for n in range(1, total_limit + 1):
        if deadline is not None and time.monotonic() >= deadline:
            raise SegmentProofError("E_NAV_DEADLINE")
        index = direction * n
        delta = gap_at_index(index)
        if type(delta) is not int or not GAP_MIN <= delta <= GAP_MAX:
            raise SegmentProofError(f"E_GAP_RANGE_AT_{index}")
        old = pos
        pos += direction * delta
        if index in anchors:
            if pos != anchors[index]:
                raise SegmentProofError(f"E_ANCHOR_MISMATCH_AT_{index}")
            checked.append(index)
        if n % segment_limit == 0 or (direction * (pos - target_day)) >= 0:
            # Chain links every segment to the previous digest and its bounds.
            entry = f"{chain}|{first_index}|{index}|{start_day}|{pos}|{n}\n"
            chain = hashlib.sha256(entry.encode("ascii")).hexdigest()
            parts.append(Segment(first_index, index, start_day, pos,
                                 abs(index - first_index) + 1, chain))
            start_day = pos
            first_index = direction * (n + 1)
        if direction * (pos - target_day) >= 0:
            if not min(old, pos) <= target_day <= max(old, pos):
                raise SegmentProofError("E_NAV_BRACKET")
            return NavigationProof(target_day, direction, index,
                                   min(old, pos), max(old, pos), n,
                                   tuple(checked), tuple(parts))
    raise SegmentProofError("E_NAV_TOTAL_BUDGET")
