#!/usr/bin/env python3
"""Host Native390 full 46-drop integration: independent arithmetic and guards."""
from pathlib import Path
import json

from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce, counts_for
from test_sm83_stage1_bowls_abi import (
    initial_bowls, reference_bowl_update, pairs72,
)

ROOT = Path(__file__).resolve().parents[1]
FOUNDATION_BOWLS_46_LE = (
    "32b1a5ef3e075af1234c1e56f46b5a77",
    "5f21e98b3abd712ce2af0a4602756d28",
    "8791a78d2420540f51ff416537c76604",
    "c0097ee6e20003dd3d0a25c9d51e125b",
    "f4a514f9d9817090af9c8cd753bd4b3a",
    "c8a7f8e35b8cbbf494a34eb496303712",
)

def main():
    src = (ROOT / "src/runtime/calendar_bowl_trace46.asm").read_text()
    boot = (ROOT / "src/boot.asm").read_text()
    make = (ROOT / "Makefile").read_text()
    workflow = (ROOT / ".github/workflows/canonical-names-lock.yml").read_text()
    bench = (ROOT / "src/tests/calendar_bowl_trace46_native_test.asm").read_text()
    assert src.index("CalendarBowlsInitialize") < src.index("CalendarHiddenVisible1Chain")
    prev = -1
    for i in range(1, 7):
        label = "CalendarHiddenVisible" + str(i) + "Chain"
        idx = src.index("call " + label)
        assert idx > prev, label
        prev = idx
    for needle in ("CalendarStoneTransitionStep", "CalendarVisibleDrop1",
                   "CalendarBowlOrderFromResidue", "CalendarBowlUpdateStep",
                   "wCalendarBowlTraceSaved", "wCalendarBowlOrderAt46",
                   ".applyCurrent:", ".restoreFailure:", "wCalendarBowlsNext",
                   "wCalendarBowlsOld", "wCalendarVisibleRing",
                   "wCalendarVisibleSavedOutput"):
        assert needle in src, needle
    assert src.index("call CalendarBowlOrderFromResidue") < src.index("call CalendarBowlUpdateStep")
    assert src.index("ld hl, wCalendarBowlsNext") < src.index("ld de, wCalendarBowlsOld")
    assert "INCLUDE \"src/runtime/calendar_bowl_trace46.asm\"" in boot
    assert "STAGE1_BOWL_TRACE46_NATIVE_BENCH" in boot
    assert "build/calendar_bowl_trace46.gb" in make
    assert "dmg-bowl-trace46-native:" in workflow
    assert "RunCalendarBowlTrace46Bench::" in bench
    for data in FOUNDATION_BOWLS_46_LE:
        assert "    db " + ",".join("$"+data[i:i+2] for i in range(0, 32, 2)) in bench
    fixture = json.loads((ROOT/"tests/fixtures/sm83_stage1_canonical_vectors.json").read_text())
    pairs = pairs72(fixture)
    mutant_detected = 0
    for c,t in pairs:
        trace = compute_sauce(c,t)
        bowls = initial_bowls(counts_for(c,t))
        for i in range(1,47):
            bowls = reference_bowl_update(
                bowls, trace.orders[i-1], trace.visible[i-1], trace.stones[i-1], i)
            assert bowls == trace.bowl_trace[i-1], (c,t,i)
        assert trace.orders[-1] == trace.order_at_46
        assert len(bowls) == 6 and all(1 <= x <= M for x in bowls)
        # Explicit in-place mutant: a predecessor can see an already updated bowl.
        old = initial_bowls(counts_for(c,t))
        trace_first = reference_bowl_update(
            old, trace.orders[0], trace.visible[0], trace.stones[0], 1)
        assert trace_first == trace.bowl_trace[0]
        mutant = list(old)
        order = trace.orders[0]
        stone = trace.stones[0]
        drop = trace.visible[0]
        from test_sm83_stage1_sauce_oracle import save
        pours = {}
        for q in range(1, 4):
            b = order[q-1]
            pours[q] = save(drop**2 + stone[q-1] * old[b-1] + (2*q+1))
        for q,b in enumerate(order,1):
            p = mutant[order[(q-2)%6]-1]
            n = mutant[order[q%6]-1]
            u = (mutant[b-1] + 2*p + 3*n + pours.get(q,0)
                 + drop + stone[(q-1)%5])
            mutant[b-1] = save(u*u + 5*p*n + q)
        mutant_detected += tuple(mutant) != trace_first
        if c == FOUNDATION and t == FOUNDATION:
            assert tuple(int.from_bytes(bytes.fromhex(h),"little")
                         for h in FOUNDATION_BOWLS_46_LE) == bowls
            assert trace.order_at_46 == (4,5,2,3,6,1)
    assert mutant_detected == len(pairs), mutant_detected
    print(f"HOST_STAGE1_BOWL_TRACE46=PASS pairs={len(pairs)} "
          "per_pair_steps=46 independent_snapshot_model=YES "
          f"in_place_mutant_rejected={mutant_detected}/{len(pairs)} "
          "foundation_96_byte_pre_stir=PASS "
          "native390=CI_REQUIRED", flush=True)

if __name__ == "__main__":
    main()
