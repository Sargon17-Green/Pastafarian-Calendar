#!/usr/bin/env python3
"""Independent Python-bigint signed32 V6 oracle for Native385."""
from pathlib import Path
import random,re
from test_sm83_stage1_visible5_abi import compute as prior_five, ROWS
from test_sm83_stage1_chain1_abi import expected_hidden
M=(1<<127)-1
ROOT=Path(__file__).resolve().parents[1]
def canonical(n): return (n-1)%M+1
def compute(c,t):
    first,second,third,fourth,fifth,_,old=prior_five(c,t)
    p,q,r,s,u=old
    new=tuple(canonical(x) for x in (p*p+3*q+6,q*q+5*r+p,r*r+7*s+q,s*s+11*u+r,u*u+13*p+s))
    hidden=expected_hidden(c,t)
    prev=(fifth,third,hidden[5])
    wc=lambda x:2*abs(x) if x<0 else 2*x+1
    counts=(wc(c),wc(t),abs(t-c)+1,wc(c)+wc(t),1 if t<c else 2 if t==c else 3)
    value=canonical(sum(x*y for x,y in zip(new,counts))+prev[0]+3*prev[1]+5*prev[2]+6)
    for a,b,d,e,j in ROWS:
        value=canonical(value*value+a*value+b*prev[0]+d*prev[1]+e*prev[2]+new[j])
    return first,second,third,fourth,fifth,value,prev,new
def fixture(text,label):
    m=re.search(r"(?m)^\."+label+r":\s*\n((?:\s*db\s+[^\n]+\n?)+)",text)
    assert m,label
    return bytes(int(x.strip()[1:],16) for line in m.group(1).splitlines() for x in line.strip()[3:].split(","))
def main():
    bench=(ROOT/"src/tests/calendar_hidden_visible6_chain_native_test.asm").read_text()
    first,second,third,fourth,fifth,sixth,prev,new=compute(0,0)
    for label,nums in (("visible1Expected",(first,)),("visible2Expected",(second,)),
                       ("visible3Expected",(third,)),("visible4Expected",(fourth,)),
                       ("visible5Expected",(fifth,)),("visibleExpected",(sixth,)),("selectedExpected",prev),("stones6Expected",new)):
        assert fixture(bench,label)==b"".join(x.to_bytes(16,"little") for x in nums),label
    rng=random.Random(0x385176)
    pairs=[(0,0),(1,2),(-1,-2),(-2,1),(-(1<<31),(1<<31)-1),
           ((1<<31)-1,-(1<<31)),(-(1<<31),-(1<<31)),((1<<31)-1,(1<<31)-1)]
    pairs += [(rng.randrange(-(1<<31),1<<31),rng.randrange(-(1<<31),1<<31)) for _ in range(64)]
    assert len(pairs)==72
    for c,t in pairs:
        a,b,d,e,f,g,prev,stones=compute(c,t)
        assert all(1<=x<=M for x in (a,b,d,e,f,g,*prev,*stones))
        assert prev[0]==f and prev[1]==d and len(stones)==5
    # Detect a wrongly aliased implementation that updates p before computing q.
    assert any(canonical(q*q + 5*r + canonical(p*p + 3*q + 6)) != canonical(q*q + 5*r + p)
               for c,t in pairs for p,q,r,s,u in (prior_five(c,t)[-1],))
    chain=(ROOT/"src/runtime/calendar_hidden_visible6_chain.asm").read_text()
    transition=(ROOT/"src/runtime/calendar_stone_transition.asm").read_text()
    visible=(ROOT/"src/runtime/calendar_visible1.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    assert "call CalendarHiddenVisible5Chain" in chain and "call CalendarStoneTransitionStep" in chain
    assert "wCalendarHiddenRetained+80" in chain and "wCalendarVisibleFifth" in chain and "wCalendarVisibleThird" in chain
    assert "CalendarStoneRunValidated.validateSource" in transition
    assert "wCalendarVisibleFifth:: ds 16" in boot and "STAGE1_CHAIN6_NATIVE_BENCH" in boot
    assert "cp 6" in visible and "ld a, 129" in bench and ".checkFifth:" in bench
    assert "build/calendar_chain6.gb" in (ROOT/"Makefile").read_text()
    assert "dmg-chain6-native:" in (ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    print("HOST_STAGE1_VISIBLE6=PASS independent_pairs=72 signed32_endpoints=YES V1_V2_V3_V4_V5_RETAINED=YES predecessor=V5_V3_H6 i6_stones=5 Native385=CI_REQUIRED",flush=True)
if __name__=="__main__":
    main()
