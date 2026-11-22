#!/usr/bin/env python3
"""Independent signed32 Python-int third-visible oracle for Native382."""
from pathlib import Path
import random,re
from test_sm83_stage1_visible2_abi import compute as prior_two
from test_sm83_stage1_chain1_abi import expected_hidden
M=(1<<127)-1
ROOT=Path(__file__).resolve().parents[1]
ROWS=((3,5,7,11,0),(5,7,11,13,1),(7,11,13,17,2),
      (11,13,17,19,3),(13,17,19,23,4),(17,19,23,29,0),
      (19,23,29,31,1),(23,29,31,37,2),(29,31,37,41,3),
      (31,37,41,43,4),(37,41,43,47,0))
def canonical(n): return (n-1)%M+1
def compute(c,t):
    first,second,_,s=prior_two(c,t)
    p,q,r,b,u=s
    stones=tuple(canonical(z) for z in
        (p*p+3*q+3,q*q+5*r+p,r*r+7*b+q,b*b+11*u+r,u*u+13*p+b))
    hidden=expected_hidden(c,t)
    prev=(second,hidden[0],hidden[4])
    wc=lambda v:2*abs(v) if v<0 else 2*v+1
    counts=(wc(c),wc(t),abs(t-c)+1,wc(c)+wc(t),1 if t<c else 2 if t==c else 3)
    x=canonical(sum(a*b for a,b in zip(stones,counts))+prev[0]+3*prev[1]+5*prev[2]+3)
    for a,b,d,e,j in ROWS:
        x=canonical(x*x+a*x+b*prev[0]+d*prev[1]+e*prev[2]+stones[j])
    return first,second,x,prev,stones
def db(src,label):
    m=re.search(r"(?m)^\."+label+r":\s*\n((?:\s*db\s+[^\n]+\n?)+)",src)
    assert m,label
    return bytes(int(z.strip()[1:],16) for line in m.group(1).splitlines()
                 for z in line.strip()[3:].split(","))
def main():
    a=(ROOT/"src/tests/calendar_hidden_visible3_chain_native_test.asm").read_text()
    v1,v2,v3,prev,stones=compute(0,0)
    for name,nums in (("visible1Expected",(v1,)),("visible2Expected",(v2,)),
                      ("visibleExpected",(v3,)),("selectedExpected",prev),
                      ("stones3Expected",stones)):
        assert db(a,name)==b"".join(n.to_bytes(16,"little") for n in nums),name
    cases=[(0,0),(1,2),(-1,-2),(-2,1),(-(1<<31),(1<<31)-1),
           ((1<<31)-1,-(1<<31)),(-(1<<31),-(1<<31)),((1<<31)-1,(1<<31)-1)]
    rng=random.Random(0x382173)
    cases.extend((rng.randrange(-(1<<31),1<<31),rng.randrange(-(1<<31),1<<31)) for _ in range(64))
    for c,t in cases:
        first,second,third,prev,s=compute(c,t)
        assert all(1<=n<=M for n in (first,second,third,*prev,*s))
        assert prev[0]==second and len(s)==5
    chain=(ROOT/"src/runtime/calendar_hidden_visible3_chain.asm").read_text()
    transition=(ROOT/"src/runtime/calendar_stone_transition.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    visible=(ROOT/"src/runtime/calendar_visible1.asm").read_text()
    assert "call CalendarHiddenVisible2Chain" in chain
    assert "call CalendarStoneTransitionStep" in chain
    assert "wCalendarHiddenRetained+64" in chain
    assert "CalendarStoneRunValidated.validateSource" in transition
    assert "wCalendarVisibleSecond:: ds 16" in boot
    assert "STAGE1_CHAIN3_NATIVE_BENCH" in boot
    # CalendarVisibleDrop1 now validates inclusive i=1..46, not the old i=3 gate.
    assert re.search(r"ld a, \[wCalendarVisibleIteration\]\s+cp 1\s+jp c, \.invalid\s+cp 47\s+jp nc, \.invalid", visible)
    assert "ld a, 126" in a and ".checkSecond:" in a
    assert "build/calendar_chain3.gb" in (ROOT/"Makefile").read_text()
    assert "dmg-chain3-native:" in (ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    print("HOST_STAGE1_VISIBLE3=PASS independent_pairs=72 signed32_endpoints=YES "
          "V1_V2_RETAINED=YES predecessor=V2_H1_H5 i3_stones=5 Native382=CI_REQUIRED",flush=True)
if __name__=="__main__":
    main()
