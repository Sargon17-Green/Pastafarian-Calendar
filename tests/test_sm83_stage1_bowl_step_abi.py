#!/usr/bin/env python3
"""Stage1 Native388 contract: two independently calculated ROM vectors, 72
nonfixture differential steps, old-snapshot isolation and static ABI guards.
This is Host/static only, NEVER evidence of RGBDS, ROM or PyBoy success.
"""
from __future__ import annotations
from itertools import permutations
from pathlib import Path
import random
import re

from test_sm83_stage1_bowls_abi import reference_bowl_update

ROOT=Path(__file__).resolve().parents[1]
M=(1<<127)-1

def save(value: int) -> int:
    return (value-1)%M+1

def independent_step(old, order, drop, stones, iteration):
    # Position-to-identity mapping is explicit. No in-place bowl writes.
    predecessor={order[q]:order[(q-1)%6] for q in range(6)}
    successor={order[q]:order[(q+1)%6] for q in range(6)}
    pours={}
    for q in range(3):
        b=order[q]
        pours[b]=save(drop**2+stones[q]*old[b-1]+(2*q+3)*iteration)
    out=[0]*6
    for q,b in enumerate(order):
        p=old[predecessor[b]-1]
        n=old[successor[b]-1]
        u=old[b-1]+2*p+3*n+pours.get(b,0)+drop+stones[q%5]
        out[b-1]=save(u*u+5*p*n+iteration*(q+1))
    return tuple(out)

def parse_rom_case(source: str, n: int):
    block=source.split(f".case{n}:\n",1)[1].split(
        f".case{n+1}:\n",1)[0] if n==1 else source.split(".case2:\n",1)[1]
    data=[]
    for line in block.splitlines():
        line=line.strip()
        if not line.startswith("db "):
            continue
        for part in line[3:].split(","):
            part=part.strip()
            data.append(int(part[1:],16) if part.startswith("$") else int(part))
    assert len(data)==96+80+16+6+1+96, (n,len(data))
    def read_residues(begin,count):
        return tuple(int.from_bytes(bytes(data[begin+j*16:begin+(j+1)*16]),"little") for j in range(count))
    old=read_residues(0,6)
    stones=read_residues(96,5)
    drop=int.from_bytes(bytes(data[176:192]),"little")
    order=tuple(data[192:198])
    iteration=data[198]
    expected=read_residues(199,6)
    return old,order,drop,stones,iteration,expected

def wrong_in_place(old,order,drop,stones,iteration):
    updated=list(old)
    # This deliberately illegal mutant illustrates dependence on new values.
    pours=[save(drop*drop+stones[q]*old[order[q]-1]+(2*q+3)*iteration) for q in range(3)]
    for q,b in enumerate(order):
        p=updated[order[(q-1)%6]-1]
        n=updated[order[(q+1)%6]-1]
        u=updated[b-1]+2*p+3*n+(pours[q] if q<3 else 0)+drop+stones[q%5]
        updated[b-1]=save(u*u+5*p*n+iteration*(q+1))
    return tuple(updated)

def main():
    runtime=(ROOT/"src/runtime/calendar_bowl_step.asm").read_text()
    bench=(ROOT/"src/tests/calendar_bowl_step_native_test.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    workflow=(ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    makefile=(ROOT/"Makefile").read_text()
    for name in ("CalendarBowlUpdateStep::","CalendarOrdinalValidate",
                 "wCalendarBowlsOld","wCalendarBowlNewScratch",
                 "wCalendarBowlsNext",".validateOrder:",".pours:",
                 ".loadNeighbors:",".each:",".publish:","Mul128x128",
                 "SaveWide256","Save127","wCalendarBowlRepeat"):
        assert name in runtime,name
    assert runtime.index(".publish:")>runtime.index(".each:")
    assert "ld hl, wCalendarBowlNewScratch\n    ld de, wCalendarBowlsNext" in runtime
    assert "ld hl, wCalendarBowlsOld" in runtime
    assert "STAGE1_BOWL_STEP_NATIVE_BENCH" in boot
    assert "RunCalendarBowlStepBench" in bench
    assert "build/calendar_bowl_step.gb" in makefile
    assert "dmg-bowl-step-native:" in workflow
    assert "wCalendarBowlNewScratch:: ds 96" in boot
    assert "wCalendarBowlsNext:: ds 96" in boot

    for n in (1,2):
        old,order,drop,stones,i,expected=parse_rom_case(bench,n)
        assert len(set(order))==6 and set(order)==set(range(1,7))
        assert 1<=i<=46
        assert all(1<=v<=M for v in (*old,*stones,drop,*expected))
        actual=independent_step(old,order,drop,stones,i)
        assert actual==expected, (n,actual,expected)
        assert reference_bowl_update(old,order,drop,stones,i)==expected
        assert wrong_in_place(old,order,drop,stones,i)!=expected

    rng=random.Random(0x5A83388)
    orders=list(permutations(range(1,7)))
    mutations=0
    for j in range(72):
        old=tuple(rng.randint(1,M) for _ in range(6))
        stones=tuple(rng.randint(1,M) for _ in range(5))
        drop=rng.randint(1,M)
        order=orders[(j*37)%720]
        i=1+(j*11)%46
        expected=reference_bowl_update(old,order,drop,stones,i)
        assert independent_step(old,order,drop,stones,i)==expected
        mutations+=wrong_in_place(old,order,drop,stones,i)!=expected
    assert mutations>=70,mutations
    print("HOST_STAGE1_BOWL_STEP=PASS ROM_vectors=2 independent_72=YES "
          f"old_snapshot_mutant_rejected={mutations}/72 "
          "six_outputs=ATOMIC_STATIC_GUARD native388=CI_REQUIRED",flush=True)

if __name__=="__main__":
    main()
