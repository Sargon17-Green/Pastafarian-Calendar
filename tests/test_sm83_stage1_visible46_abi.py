#!/usr/bin/env python3
"""Independent 46-visible-drop oracle and static contract guard for Native386."""
from __future__ import annotations

import json
from pathlib import Path

from test_sm83_stage1_sauce_oracle import FOUNDATION, compute_sauce

ROOT = Path(__file__).resolve().parents[1]
MODULUS = (1 << 127) - 1


def signed32(value: int) -> int:
    return (value & 0xFFFFFFFF) - 0x80000000


def main() -> None:
    fixture = json.loads((ROOT / "tests/fixtures/sm83_stage1_canonical_vectors.json").read_text())
    pairs = [
        (FOUNDATION, FOUNDATION),
        (FOUNDATION - 1, FOUNDATION),
        (FOUNDATION, FOUNDATION + 1),
        (FOUNDATION + 1, FOUNDATION - 1),
        (FOUNDATION - 1, FOUNDATION + 1),
        (FOUNDATION - (1 << 31), FOUNDATION + (1 << 31) - 1),
        (FOUNDATION + (1 << 31) - 1, FOUNDATION - (1 << 31)),
        (FOUNDATION - (1 << 31), FOUNDATION - (1 << 31)),
    ]
    pairs.extend((item["c"], item["t"]) for item in fixture["vectors"])
    for i in range(54):
        c = FOUNDATION + signed32(i * 0x45D9F3B + 0x01234567)
        t = FOUNDATION + signed32(i * 0x119DE1F3 + 0x1F123BB5)
        pairs.append((c, t))
    assert len(pairs) == 72

    for c, t in pairs:
        trace = compute_sauce(c, t)
        assert len(trace.visible) == 46
        assert len(trace.hidden) == 7
        assert all(1 <= value <= MODULUS for value in trace.visible)
        assert trace.visible[0] == trace.first_visible
        assert trace.visible[-1] == trace.last_visible
        assert sorted(trace.order_at_46) == [1, 2, 3, 4, 5, 6]

    foundation_trace = compute_sauce(FOUNDATION, FOUNDATION)
    assert str(foundation_trace.visible[-1]) == fixture["canonical_checkpoint"]["visible_drop_46"]
    assert foundation_trace.visible[0] == foundation_trace.first_visible

    visible_source = (ROOT / "src/runtime/calendar_visible1.asm").read_text()
    chain_source = (ROOT / "src/runtime/calendar_hidden_visible46_chain.asm").read_text()
    boot_source = (ROOT / "src/boot.asm").read_text()
    assert "cp 47" in visible_source and "i=1..46" in visible_source
    assert "call CalendarHiddenVisible6Chain" in chain_source
    assert "call CalendarStoneTransitionStep" in chain_source
    assert "call CalendarVisibleDrop1" in chain_source
    assert "sub 2" in chain_source and "add 7" in chain_source
    assert "wCalendarVisibleRing+96" in chain_source
    assert "wCalendarVisibleRing:: ds 112" in boot_source
    assert "wCalendarVisibleSixth:: ds 16" in boot_source

    print(
        "HOST_STAGE1_VISIBLE46=PASS pairs=72 hidden=7/7 visible=46/46 "
        f"foundation_V46={foundation_trace.visible[-1]}",
        flush=True,
    )


if __name__ == "__main__":
    main()
