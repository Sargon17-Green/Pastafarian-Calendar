#!/usr/bin/env python3
"""Independent Python-bigint signed32 V5 oracle for Native384."""
from pathlib import Path
import random,re
from test_sm83_stage1_visible4_abi import compute as prior_four, ROWS
from test_sm83_stage1_chain1_abi import expected_hidden
from test_sm83_stage1_sauce_oracle import FOUNDATION, compute_sauce
M=(1<<127)-1
ROOT=Path(__file__).resolve().parents[1]
def canonical(n): return (n-1)%M+1
def compute(c,t):
    first,second,third,fourth,_,old=prior_four(c,t)
    p,q,r,s,u=old
    new=tuple(canonical(x) for x in (p*p+3*q+5,q*q+5*r+p,r*r+7*s+q,s*s+11*u+r,u*u+13*p+s))
    hidden=expected_hidden(c,t)
    prev=(fourth,second,hidden[2])
    wc=lambda x:2*abs(x) if x<0 else 2*x+1
    counts=(wc(c),wc(t),abs(t-c)+1,wc(c)+wc(t),1 if t<c else 2 if t==c else 3)
    value=canonical(sum(x*y for x,y in zip(new,counts))+prev[0]+3*prev[1]+5*prev[2]+5)
    for a,b,d,e,j in ROWS:
        value=canonical(value*value+a*value+b*prev[0]+d*prev[1]+e*prev[2]+new[j])
    return first,second,third,fourth,value,prev,new
def fixture(text,label):
    m=re.search(r"(?m)^\."+label+r":\s*\n((?:\s*db\s+[^\n]+\n?)+)",text)
    assert m,label
    return bytes(int(x.strip()[1:],16) for line in m.group(1).splitlines() for x in line.strip()[3:].split(","))
def main():
    bench=(ROOT/"src/tests/calendar_hidden_visible5_chain_native_test.asm").read_text()
    first,second,third,fourth,fifth,prev,new=compute(0,0)
    for label,nums in (("visible1Expected",(first,)),("visible2Expected",(second,)),
                       ("visible3Expected",(third,)),("visible4Expected",(fourth,)),
                       ("visibleExpected",(fifth,)),("selectedExpected",prev),("stones5Expected",new)):
        assert fixture(bench,label)==b"".join(x.to_bytes(16,"little") for x in nums),label
    rng=random.Random(0x384175)
    pairs=[(0,0),(1,2),(-1,-2),(-2,1),(-(1<<31),(1<<31)-1),
           ((1<<31)-1,-(1<<31)),(-(1<<31),-(1<<31)),((1<<31)-1,(1<<31)-1)]
    pairs += [(rng.randrange(-(1<<31),1<<31),rng.randrange(-(1<<31),1<<31)) for _ in range(64)]
    assert len(pairs)==72
    for c,t in pairs:
        a,b,d,e,f,prev,stones=compute(c,t)
        assert all(1<=x<=M for x in (a,b,d,e,f,*prev,*stones))
        assert prev[0]==e and prev[1]==b and len(stones)==5
        assert compute_sauce(FOUNDATION+c, FOUNDATION+t).visible[4] == f
    chain=(ROOT/"src/runtime/calendar_hidden_visible5_chain.asm").read_text()
    transition=(ROOT/"src/runtime/calendar_stone_transition.asm").read_text()
    visible=(ROOT/"src/runtime/calendar_visible1.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    assert "call CalendarHiddenVisible4Chain" in chain and "call CalendarStoneTransitionStep" in chain
    assert "wCalendarHiddenRetained+32" in chain and "wCalendarVisibleFourth" in chain and "wCalendarVisibleSecond" in chain
    assert "CalendarStoneRunValidated.validateSource" in transition
    assert "wCalendarVisibleFourth:: ds 16" in boot and "STAGE1_CHAIN5_NATIVE_BENCH" in boot
    assert "cp 5" in visible and "ld a, 128" in bench and ".checkFourth:" in bench
    assert "build/calendar_chain5.gb" in (ROOT/"Makefile").read_text()
    assert "dmg-chain5-native:" in (ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    print("HOST_STAGE1_VISIBLE5=PASS independent_pairs=72 signed32_endpoints=YES V1_V2_V3_V4_RETAINED=YES predecessor=V4_V2_H3 i5_stones=5 Native384=CI_REQUIRED",flush=True)
if __name__=="__main__":
    main()
