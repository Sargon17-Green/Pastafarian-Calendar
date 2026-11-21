#!/usr/bin/env python3
"""Independent Python-bigint signed32 oracle for stage1 native V4 (383)."""
from pathlib import Path
import random
import re
from test_sm83_stage1_visible3_abi import compute as prior_three, ROWS
from test_sm83_stage1_chain1_abi import expected_hidden
M=(1 << 127)-1
ROOT=Path(__file__).resolve().parents[1]

def save(n):
    return (n-1)%M+1

def compute(c,t):
    first,second,third,_,old=prior_three(c,t)
    a,b,d,e,f=old
    new=tuple(map(save,(a*a+3*b+4,b*b+5*d+a,d*d+7*e+b,
                        e*e+11*f+d,f*f+13*a+e)))
    drops=expected_hidden(c,t)
    prev=(third,first,drops[3])
    work=lambda x: 2*abs(x) if x < 0 else 2*x+1
    counts=(work(c),work(t),abs(t-c)+1,work(c)+work(t),
            1 if t<c else 2 if t==c else 3)
    cur=save(sum(x*y for x,y in zip(new,counts))
             +prev[0]+3*prev[1]+5*prev[2]+4)
    for aa,bb,dd,ee,j in ROWS:
        cur=save(cur*cur+aa*cur+bb*prev[0]+dd*prev[1]
                 +ee*prev[2]+new[j])
    return first,second,third,cur,prev,new

def fixture(src,label):
    mat=re.search(r"(?m)^\."+label+r":\s*\n((?:\s*db\s+[^\n]+\n?)+)",src)
    assert mat,label
    return bytes(int(z.strip()[1:],16) for line in mat.group(1).splitlines()
                 for z in line.strip()[3:].split(","))

def main():
    bench=(ROOT/"src/tests/calendar_hidden_visible4_chain_native_test.asm").read_text()
    first,second,third,fourth,prev,stones=compute(0,0)
    tests=(("visible1Expected",(first,)),("visible2Expected",(second,)),
           ("visible3Expected",(third,)),("visibleExpected",(fourth,)),
           ("selectedExpected",prev),("stones4Expected",stones))
    for label,values in tests:
        expected=b"".join(x.to_bytes(16,"little") for x in values)
        assert fixture(bench,label)==expected,label
    pairs=[(0,0),(1,2),(-1,-2),(-2,1),(-(1<<31),(1<<31)-1),
           ((1<<31)-1,-(1<<31)),(-(1<<31),-(1<<31)),
           ((1<<31)-1,(1<<31)-1)]
    rng=random.Random(0x383174)
    pairs.extend((rng.randrange(-(1<<31),1<<31),
                  rng.randrange(-(1<<31),1<<31)) for _ in range(64))
    for c,t in pairs:
        v1,v2,v3,v4,pre,s=compute(c,t)
        assert all(1<=x<=M for x in (v1,v2,v3,v4,*pre,*s))
        assert pre[0]==v3 and pre[1]==v1 and len(s)==5
    asm=(ROOT/"src/runtime/calendar_hidden_visible4_chain.asm").read_text()
    transition=(ROOT/"src/runtime/calendar_stone_transition.asm").read_text()
    visible=(ROOT/"src/runtime/calendar_visible1.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    make=(ROOT/"Makefile").read_text()
    ci=(ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    assert "call CalendarHiddenVisible3Chain" in asm
    assert "call CalendarStoneTransitionStep" in asm
    assert "wCalendarHiddenRetained+48" in asm
    assert "wCalendarVisibleThird:: ds 16" in boot
    assert "CalendarStoneRunValidated.validateSource" in transition
    assert "cp 4" in visible
    assert "STAGE1_CHAIN4_NATIVE_BENCH" in boot
    assert "ld a, 127" in bench and ".checkThird:" in bench
    assert "build/calendar_chain4.gb" in make
    assert "dmg-chain4-native:" in ci
    print("HOST_STAGE1_VISIBLE4=PASS independent_pairs=72 "
          "signed32_endpoints=YES V1_V2_V3_RETAINED=YES "
          "predecessor=V3_V1_H4 i4_stones=5 Native383=CI_REQUIRED",flush=True)

if __name__=="__main__":
    main()
