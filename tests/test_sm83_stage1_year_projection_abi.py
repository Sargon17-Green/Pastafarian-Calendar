#!/usr/bin/env python3
"""Independent signed32 ABI oracle for a read-only *known* year span.

The Native primitive does NOT compute gate positions or choose among year
candidates. The previously accepted dynamic year-path oracle computes the
spans; this module independently checks their byte ABI and open/closed edges.
"""
from __future__ import annotations

import json
from pathlib import Path
from test_sm83_stage1_year_path_oracle import find_year

I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1


def magnitude_encode(value: int) -> tuple[int, bytes]:
    sign = int(value < 0)
    magnitude = abs(value)
    data = magnitude.to_bytes((magnitude.bit_length() + 7) // 8, "little")
    return sign, data


def project(sign: int, magnitude: bytes, opening: bytes, closing: bytes, year: int) -> int | None:
    """Reference Python integer arithmetic; no ASM routine or fixture outputs."""
    if sign not in (0, 1) or len(magnitude) > 4:
        return None
    if not magnitude and sign:
        return None
    if magnitude and magnitude[-1] == 0:
        return None
    absolute = int.from_bytes(magnitude, "little")
    target = -absolute if sign else absolute
    if not I32_MIN <= target <= I32_MAX:
        return None
    left = int.from_bytes(opening, "little", signed=True)
    right = int.from_bytes(closing, "little", signed=True)
    return year if left < target <= right else None


def check_stage1_year_projection_abi() -> None:
    fixture = json.loads((Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8"))
    assert fixture["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    checked = 0
    boundaries = 0
    nonfoundation = set()
    for record in fixture["vectors"]:
        c, t = record["c"], record["t"]
        span = find_year(c, t)
        left, right = span.span.open_gate, span.span.close_gate
        assert I32_MIN <= left < right <= I32_MAX
        open_bytes = left.to_bytes(4, "little", signed=True)
        close_bytes = right.to_bytes(4, "little", signed=True)
        sign, data = magnitude_encode(t)
        assert project(sign, data, open_bytes, close_bytes, span.year_number) == record["expected"][0]
        assert span.year_number == record["expected"][0]
        if c != fixture["foundation"]:
            nonfoundation.add(c)
        for x, want in ((left, None), (left + 1, span.year_number),
                        (right, span.year_number), (right + 1, None)):
            sx, dx = magnitude_encode(x)
            assert project(sx, dx, open_bytes, close_bytes, span.year_number) == want
            boundaries += 1
        checked += 1
    assert checked == 10 and boundaries == 40 and len(nonfoundation) >= 3
    # Signed overflow, noncanonical negative zero, high zero, negative edge.
    lo = (-100).to_bytes(4, "little", signed=True)
    hi = (500).to_bytes(4, "little", signed=True)
    assert project(0, b"\x00\x00\x00\x80", lo, hi, 5000) is None
    assert project(1, b"\x00\x00\x00\x80", lo, hi, 5000) is None  # -2^31 outside the span
    assert project(1, b"", lo, hi, 5000) is None
    assert project(0, b"\x01\x00", lo, hi, 5000) is None
    assert project(0, b"\x01" * 5, lo, hi, 5000) is None
    assert project(1, b"\x01", lo, hi, 5000) == 5000
    print(
        "HOST_STAGE1_YEAR_PROJECTION_ABI=PASS "
        "canonical_years=10/10 edge_checks=40 nonfoundation_calculations=3 "
        "signed32_and_canonicality=YES independent_Python_int=YES "
        "native_candidate_count=9 native_execution=CI_REQUIRED "
        "gate_generation=NOT_IMPLEMENTED full_calendar=NOT_IMPLEMENTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_year_projection_abi()
