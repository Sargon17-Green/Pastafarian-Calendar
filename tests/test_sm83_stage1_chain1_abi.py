#!/usr/bin/env python3
"""Independent integer reference and static ABI guard for chained Native380.

The normative five-stone and hidden recurrences are independently expressed
as Python big integers. Native assembler output is not used as an oracle.
"""
from __future__ import annotations
from pathlib import Path
import random
import re
import sys
from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce
from test_sm83_stage1_visible1_abi import independent_visible1
ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "src/tests/calendar_hidden_visible1_chain_native_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_hidden_visible1_chain.asm"
BOOT = ROOT / "src/boot.asm"
MAKE = ROOT / "Makefile"
WF = ROOT / ".github/workflows/canonical-names-lock.yml"

def save(n: int) -> int:
    return 1 + (n - 1) % M

def expected_hidden(c: int, t: int) -> tuple[int, ...]:
    def work(n: int) -> int:
        return 2*abs(n) if n < 0 else 2*n+1
    a, b = work(c), work(t)
    distance = abs(t-c)+1
    total = a+b
    direction = 1 if t < c else 2 if c == t else 3
    stones = (17, 29, 43, 71, 101)
    out = []
    for k in range(1, 8):
        if k > 1:
            w, barley, salt, bitter, red = stones
            stones = tuple(save(v) for v in (
                w*w+3*barley+k, barley*barley+5*salt+w,
                salt*salt+7*bitter+barley, bitter*bitter+11*red+salt,
                red*red+13*w+bitter
            ))
        x = save(a+(2*k+1)*b+(3*k+1)*distance+
                 (4*k+2)*total+(4*k+4)*direction+sum(stones))
        for r in range(1, 8):
            x = save(x*x+3*x+stones[(r-1)%5]+r)
        out.append(x)
    return tuple(out)

def data(label: str, asm: str) -> bytes:
    m = re.search(r"(?m)^\." + label + r":\s*\n((?:\s*db\s+[^\n]+\n?)+)", asm)
    assert m is not None, label
    return bytes(int(tok.strip()[1:], 16)
                 for line in m.group(1).splitlines()
                 for tok in line.strip()[3:].strip().split(","))

def main() -> None:
    rom = ROM.read_text(encoding="utf-8")
    hs = expected_hidden(0, 0)
    assert data("hiddenExpected", rom) == b"".join(n.to_bytes(16,"little") for n in hs)
    assert data("selectedExpected", rom) == b"".join(hs[k].to_bytes(16,"little") for k in (0,2,6))
    out, prior = independent_visible1(0, 0)
    assert tuple(hs[k] for k in (0,2,6)) == prior
    assert data("visibleExpected", rom) == out.to_bytes(16,"little")
    pair = [(0,0),(1,2),(-1,-2),(-2,1),
            (-(1<<31),(1<<31)-1),((1<<31)-1,-(1<<31)),
            (-(1<<31),-(1<<31)),((1<<31)-1,(1<<31)-1)]
    rng = random.Random(0x718046)
    pair.extend((rng.randrange(-(1<<31),1<<31),rng.randrange(-(1<<31),1<<31)) for _ in range(64))
    for c,t in pair:
        hs = expected_hidden(c,t)
        first, prior = independent_visible1(c,t)
        assert tuple(hs[k] for k in (0,2,6)) == prior
        assert compute_sauce(FOUNDATION+c,FOUNDATION+t).first_visible == first
        assert all(1 <= n <= M for n in hs)
    src=RUNTIME.read_text(encoding="utf-8")
    for label in ["CalendarHiddenDrop1","CalendarHiddenDrop2","CalendarHiddenDrop3",
                  "CalendarHiddenDrop4","CalendarHiddenDrop5","CalendarHiddenDrop6",
                  "CalendarHiddenDrop7","CalendarVisibleDrop1"]:
        assert ("call " if label != "CalendarVisibleDrop1" else "jp ") + label in src
    assert src.count("call CalendarStoneTransitionRange") == 6
    assert src.count("call .retain") == 7
    assert "wCalendarHiddenRetained:: ds 112" in BOOT.read_text(encoding="utf-8")
    assert "STAGE1_CHAIN1_NATIVE_BENCH" in BOOT.read_text(encoding="utf-8")
    assert "build/calendar_chain1.gb" in MAKE.read_text(encoding="utf-8")
    assert "dmg-chain1-native:" in WF.read_text(encoding="utf-8")
    assert "ld a, 124" in rom and "call CalendarInvocationAbort" in rom
    print("HOST_STAGE1_CHAIN1=PASS independent_pairs=72 hidden7=7x16 "
          "visible1=16 Foundation_expected=YES signed32_endpoints=YES "
          "source_and_lease=STATIC_NATIVE_ASSERTIONS Native380=CI_REQUIRED "
          "visible2_46_bowls=NOT_IMPLEMENTED", flush=True)

if __name__ == "__main__":
    main()
