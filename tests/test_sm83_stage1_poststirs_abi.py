#!/usr/bin/env python3
"""Stage1 Native391 host gate: independent integer post-stir model and ABI."""
from __future__ import annotations

from math import factorial
from pathlib import Path
import json
import re

from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce
from test_sm83_stage1_bowls_abi import pairs72

ROOT = Path(__file__).resolve().parents[1]


def canonical(n: int) -> int:
    # Euclidean residue without borrowing the reference oracle's SAVE function.
    return ((n - 1) % M) + 1


def order_factoradic(s: int) -> tuple[int, ...]:
    k = (s - 1) % factorial(6)
    available = [1, 2, 3, 4, 5, 6]
    order = []
    for remaining in range(6, 0, -1):
        f = factorial(remaining - 1)
        index, k = divmod(k, f)
        order.append(available.pop(index))
    return tuple(order)


def post_stir_reference(previous: tuple[int, ...], round_no: int,
                        *, raw_sum_mutant: bool = False,
                        in_place_mutant: bool = False) -> tuple[tuple[int, ...], int]:
    """Independent entire-round arithmetic from six untouched prior values."""
    assert len(previous) == 6 and 1 <= round_no <= 12
    raw = sum(previous)
    retained = canonical(raw + 149 * round_no)
    order = order_factoradic(retained)
    new = list(previous) if in_place_mutant else [0] * 6
    for q in range(6):
        b = order[q] - 1
        p = order[(q - 1) % 6] - 1
        n = order[(q + 1) % 6] - 1
        src = new if in_place_mutant else previous
        u = src[b] + 3 * src[p] + 5 * src[n] + (
            raw if raw_sum_mutant else retained
        ) + round_no + (q + 1) ** 2
        new[b] = canonical(u * u + 7 * src[p] * src[n])
    return tuple(new), retained


def fixture_bytes(source: str, start: str, stop: str) -> bytes:
    chunk = source.split(start, 1)[1].split(stop, 1)[0]
    return bytes(int(m, 16) for m in re.findall(r"\$([0-9a-fA-F]{2})", chunk))


def main() -> None:
    asm = (ROOT / "src/runtime/calendar_bowl_poststirs.asm").read_text()
    boot = (ROOT / "src/boot.asm").read_text()
    make = (ROOT / "Makefile").read_text()
    wf = (ROOT / ".github/workflows/canonical-names-lock.yml").read_text()
    bench = (ROOT / "src/tests/calendar_bowl_poststirs_native_test.asm").read_text()
    for needle in (
        "CalendarBowlPostStirs12::", "CalendarBowlPostStirStep::",
        "wCalendarPostStirSavedBowls", "wCalendarPostStirSumsScratch",
        "wCalendarPostStirSum", "wCalendarBowlOrderInput",
        "call CalendarBowlOrderFromResidue", "call Mul128x128",
        "call SaveWide256", "wCalendarBowlNewScratch",
        "wCalendarBowlsNext", "wCalendarBowlsOld", ".restoreFailure:",
        "ld a, 149", "ld a, 7", "ld a, 3", "ld a, 5",
    ):
        assert needle in asm, needle
    assert asm.index("ld hl, wCalendarPostStirSum\n    ld de, wCalendarBowlOrderInput") \
        < asm.index("call CalendarBowlOrderFromResidue")
    assert asm.count("ld hl, wCalendarPostStirSum\n    ld de, wAddend") == 1
    assert asm.index("ld hl, wCalendarPostStirSumsScratch\n    ld de, wCalendarPostStirSums") \
        > asm.index("cp 13\n    jp nz, .loop")
    assert 'INCLUDE "src/runtime/calendar_bowl_poststirs.asm"' in boot
    assert "STAGE1_POSTSTIRS_NATIVE_BENCH" in boot
    assert "build/calendar_bowl_poststirs.gb" in make
    assert "dmg-bowl-poststirs-native:" in wf
    assert "RunCalendarBowlPostStirsBench::" in bench
    assert len(fixture_bytes(bench, ".bowlsExpected:", ".sumsExpected:")) == 96
    assert len(fixture_bytes(bench, ".sumsExpected:", ".order46Expected:")) == 192

    fixtures = json.loads((ROOT / "tests/fixtures/sm83_stage1_canonical_vectors.json").read_text())
    pairs = pairs72(fixtures)
    raw_rejected, inplace_rejected = 0, 0
    for c, t in pairs:
        trace = compute_sauce(c, t)
        before = trace.bowl_trace[-1]
        assert len(trace.post_stir_bowls_trace) == 12
        for index in range(12):
            r = index + 1
            after, s = post_stir_reference(before, r)
            assert s == trace.retained_post_stir_sums[index], (c, t, r, "S")
            assert after == trace.post_stir_bowls_trace[index], (c, t, r, "bowls")
            assert all(1 <= item <= M for item in after)
            if r == 1:
                raw_rejected += (post_stir_reference(before, r, raw_sum_mutant=True)[0] != after)
                inplace_rejected += (post_stir_reference(before, r, in_place_mutant=True)[0] != after)
            before = after
        assert before == trace.bowls
        if c == FOUNDATION and t == FOUNDATION:
            final = fixture_bytes(bench, ".bowlsExpected:", ".sumsExpected:")
            sums = fixture_bytes(bench, ".sumsExpected:", ".order46Expected:")
            assert tuple(int.from_bytes(final[i:i+16], "little")
                         for i in range(0, 96, 16)) == before
            assert tuple(int.from_bytes(sums[i:i+16], "little")
                         for i in range(0, 192, 16)) == trace.retained_post_stir_sums
    assert raw_rejected == len(pairs), (raw_rejected, len(pairs))
    assert inplace_rejected == len(pairs), (inplace_rejected, len(pairs))
    print(f"HOST_STAGE1_POSTSTIRS=PASS pairs={len(pairs)} rounds=12 "
          f"raw_sum_mutant_rejected={raw_rejected}/{len(pairs)} "
          f"in_place_mutant_rejected={inplace_rejected}/{len(pairs)} "
          "foundation_96_plus_192_bytes=PASS "
          "native391=CI_REQUIRED", flush=True)


if __name__ == "__main__":
    main()
