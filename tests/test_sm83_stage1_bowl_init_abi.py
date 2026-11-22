#!/usr/bin/env python3
"""Native389 candidate independent Host/static 77-pair initialization oracle."""
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
M = (1 << 127)-1
SEEDS = (17,19,23,29,31,37)

def signed32(value):
    return value - (1 << 32) if value & (1 << 31) else value

def model(c, t):
    a = -2*c if c < 0 else 2*c+1
    b = -2*t if t < 0 else 2*t+1
    distance = abs(t-c)+1
    direction = 1 if t < c else 2 if t == c else 3
    return tuple(1 + (((a+j*b+distance+a+b+direction+s*s)**2+j-1) % M)
                 for j, s in enumerate(SEEDS,1))

def vectors(bench):
    result = []
    for case in (1,2):
        tail=bench.split(f".case{case}:\n",1)[1]
        if case==1:
            tail=tail.split(".case2:\n",1)[0]
        data=[]
        for line in tail.splitlines():
            line=line.strip()
            if line.startswith("db "):
                data.extend(int(s.strip()[1:],16) for s in line[3:].split(","))
        assert len(data)==104, (case,len(data))
        c=signed32(int.from_bytes(bytes(data[:4]),"little"))
        t=signed32(int.from_bytes(bytes(data[4:8]),"little"))
        expected=tuple(int.from_bytes(bytes(data[8+16*j:24+16*j]),"little")
                       for j in range(6))
        result.append((c,t,expected))
    return result

def main():
    runtime=(ROOT/"src/runtime/calendar_bowl_init.asm").read_text()
    bench=(ROOT/"src/tests/calendar_bowl_init_native_test.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    workflow=(ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    makefile=(ROOT/"Makefile").read_text()
    for s in ("CalendarBowlsInitialize::","CalendarOrdinalValidate",
              "WorkCountsFromOffsets32", "wCalendarBowlNewScratch",
              "wCalendarBowlsOld", "Mul128x128","SaveWide256",
              "Save127","dw 289,361,529,841,961,1369",".publish:"):
        assert s in runtime,s
    assert runtime.index(".publish:")>runtime.index(".nextBowl:")
    assert "STAGE1_BOWL_INIT_NATIVE_BENCH" in boot
    assert "RunCalendarBowlInitBench" in bench
    assert "build/calendar_bowl_init.gb" in makefile
    assert "dmg-bowl-init-native:" in workflow
    for c,t,expected in vectors(bench):
        assert model(c,t)==expected,(c,t)
    rng=random.Random(0x5A83389)
    cases=[(0,0),(-(1<<31),(1<<31)-1),((1<<31)-1,-(1<<31)),(-1,0),(0,-1)]
    cases += [(signed32(rng.getrandbits(32)), signed32(rng.getrandbits(32)))
              for _ in range(72)]
    from test_sm83_stage1_bowls_abi import initial_bowls
    from test_sm83_stage1_sauce_oracle import FOUNDATION,counts_for
    mutant_rejected=0
    for c,t in cases:
        result=model(c,t)
        assert result==initial_bowls(counts_for(FOUNDATION+c,FOUNDATION+t))
        assert len(result)==6 and all(1<=x<=M for x in result)
        a=-2*c if c<0 else 2*c+1
        b=-2*t if t<0 else 2*t+1
        d=abs(t-c)+1
        e=1 if t<c else 2 if t==c else 3
        mutant=tuple(1+(((a+j*b+d+a+b+e+j*j)**2+j-1)%M) for j in range(1,7))
        mutant_rejected+=mutant!=result
    assert mutant_rejected==len(cases),mutant_rejected
    print(f"HOST_STAGE1_BOWL_INIT=PASS pairs={len(cases)} ROM_vectors=2 "
          f"wrong_seed_mutant_rejected={mutant_rejected}/{len(cases)} "
          "atomic_publish=STATIC_GUARD native389=CI_REQUIRED",flush=True)

if __name__=="__main__":
    main()
