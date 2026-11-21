#!/usr/bin/env python3
"""Independent signed32 mathematical oracle for isolated Native381 visible2."""
from __future__ import annotations
from pathlib import Path
import random
import re
from test_sm83_stage1_chain1_abi import expected_hidden
from test_sm83_stage1_visible1_abi import independent_visible1
M = (1 << 127)-1
ROOT=Path(__file__).resolve().parents[1]
ASM=ROOT/"src/tests/calendar_hidden_visible2_chain_native_test.asm"
GRIND=((3,5,7,11,0),(5,7,11,13,1),(7,11,13,17,2),
       (11,13,17,19,3),(13,17,19,23,4),(17,19,23,29,0),
       (19,23,29,31,1),(23,29,31,37,2),(29,31,37,41,3),
       (31,37,41,43,4),(37,41,43,47,0))
def save(x:int)->int:
    return (x-1)%M+1
def compute(c:int,t:int):
    count=lambda n: (-2*n if n<0 else 2*n+1)
    a,b=count(c),count(t)
    wc=(a,b,abs(t-c)+1,a+b,1 if t<c else 2 if t==c else 3)
    p,q,r,s,u=(17,29,43,71,101)
    stone=tuple(map(save,(p*p+3*q+2,q*q+5*r+p,r*r+7*s+q,
                          s*s+11*u+r,u*u+13*p+s)))
    hidden=expected_hidden(c,t)
    first,_=independent_visible1(c,t)
    prev=(first,hidden[1],hidden[5])
    x=save(sum(k*n for k,n in zip(stone,wc))+prev[0]+
           3*prev[1]+5*prev[2]+2)
    for a,b,d,e,j in GRIND:
        x=save(x*x+a*x+b*prev[0]+d*prev[1]+e*prev[2]+stone[j])
    return first,x,prev,stone
def db(label:str,src:str)->bytes:
    pattern=r"(?m)^\."+label+r":\s*\n((?:\s*db\s+[^\n]+\n?)+)"
    m=re.search(pattern,src)
    assert m is not None,label
    return bytes(int(x.strip()[1:],16)
                 for line in m.group(1).splitlines()
                 for x in line.strip()[3:].split(","))
def main():
    asm=ASM.read_text(encoding="utf-8")
    v1,v2,prev,stones=compute(0,0)
    assert db("visible1Expected",asm)==v1.to_bytes(16,"little")
    assert db("visibleExpected",asm)==v2.to_bytes(16,"little")
    assert db("selectedExpected",asm)==b"".join(x.to_bytes(16,"little") for x in prev)
    assert db("stones2Expected",asm)==b"".join(x.to_bytes(16,"little") for x in stones)
    pairs=[(0,0),(1,2),(-1,-2),(-2,1),(-(1<<31),(1<<31)-1),
           ((1<<31)-1,-(1<<31)),(-(1<<31),-(1<<31)),
           ((1<<31)-1,(1<<31)-1)]
    rng=random.Random(0x381123)
    pairs.extend((rng.randrange(-(1<<31),1<<31),
                  rng.randrange(-(1<<31),1<<31)) for _ in range(64))
    for c,t in pairs:
        first,second,prev,stone=compute(c,t)
        assert 1<=first<=M and 1<=second<=M
        assert len(prev)==3 and len(stone)==5
    runtime=(ROOT/"src/runtime/calendar_hidden_visible2_chain.asm").read_text()
    visible=(ROOT/"src/runtime/calendar_visible1.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    assert "call CalendarHiddenVisible1Chain" in runtime
    assert "call CalendarStoneTransitionRange" in runtime
    assert "wCalendarHiddenRetained+16" in runtime
    assert "wCalendarHiddenRetained+80" in runtime
    assert "jp CalendarVisibleDrop1" in runtime
    assert "ld a, [wCalendarVisibleIteration]" in visible
    assert "wCalendarVisibleFirst:: ds 16" in boot
    assert "STAGE1_CHAIN2_NATIVE_BENCH" in boot
    assert "ld a, 125" in asm and ".checkFirst:" in asm
    assert "build/calendar_chain2.gb" in (ROOT/"Makefile").read_text()
    assert "dmg-chain2-native:" in (ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    print("HOST_STAGE1_VISIBLE2=PASS independent_pairs=72 signed32_endpoints=YES "
          "first_retained=YES prev=V1_H2_H6 i2_stones=5 "
          "Native381=CI_REQUIRED bowls=NOT_IMPLEMENTED",flush=True)
if __name__=="__main__":
    main()
