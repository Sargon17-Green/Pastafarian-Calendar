#!/usr/bin/env python3
"""Independent host oracle for work counters on two signed 32-bit offsets."""
from random import Random
LO,HI=-(1<<31),(1<<31)-1
def reference(c:int,t:int)->tuple[int,int,int,int,int]:
    if not (LO<=c<=HI and LO<=t<=HI): raise ValueError("out of range")
    a=2*(-c) if c<0 else 2*c+1
    b=2*(-t) if t<0 else 2*t+1
    return a,b,abs(t-c)+1,a+b,1 if t<c else 2 if t==c else 3
def other(c:int,t:int)->tuple[int,int,int,int,int]:
    def day(d:int)->int:
        bits=d&0xffffffff
        magnitude=((~bits+1)&0xffffffff) if bits&0x80000000 else bits
        return (magnitude<<1)+(0 if bits&0x80000000 else 1)
    ca=(c&0xffffffff)^0x80000000
    ta=(t&0xffffffff)^0x80000000
    direct=1 if ta<ca else 2 if ta==ca else 3
    larger,smaller=(c,t) if direct==1 else (t,c)
    delta=((larger&0xffffffff)-(smaller&0xffffffff))&0xffffffff
    a,b=day(c),day(t)
    return a,b,delta+1,a+b,direct
def main()->None:
    boundary=[LO,LO+1,-65536,-2,-1,0,1,2,65536,HI-1,HI]
    rng=Random(0x83AB32)
    pairs=[(a,b) for a in boundary for b in boundary]
    pairs.extend((rng.randint(LO,HI),rng.randint(LO,HI)) for _ in range(14000))
    for c,t in pairs:
        got=other(c,t); exp=reference(c,t)
        assert got==exp,(c,t,got,exp)
        assert all(0<=x<(1<<40) for x in got[:4])
    print(f"HOST_WORK_COUNTERS_DELTA32=PASS cases={len(pairs)}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")
if __name__=="__main__": main()
