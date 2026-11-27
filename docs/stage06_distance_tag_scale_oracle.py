#!/usr/bin/env python3
"""Oracle independente: cardinalidade do intervalo fechado, sem BigInt Pascal."""
import csv
import sys
from pathlib import Path

F = -15055671
HEADER = ["c", "t", "action", "target", "distance", "connection", "direction"]
def tag(day):
    return 2 * (F-day) if day < F else 2 * (day-F) + 1

def vectors():
    m = (1 << 127)-1
    points = {0, 1, -1, F, F-1, F+1, m, -m}
    for magnitude in [2**k for k in (31,32,63,64,127,128,255,256,512)] + [10**(9*k) for k in (1,2,4,8,16)]:
        for sign in (-1,1):
            for offset in (-1,0,1):
                points.add(sign*magnitude+offset)
    assert len(points) == 90
    for c in sorted(points):
        for t in sorted(points):
            lo, hi = sorted((c,t))
            n = (hi+1)-lo
            a,b = tag(c),tag(t)
            yield (c,t,a,b,n,a+b,1 if t<c else 3 if t>c else 2)

def emit(path):
    with open(path,"w",encoding="ascii",newline="") as f:
        w=csv.writer(f,delimiter="\t",lineterminator="\n")
        w.writerow(HEADER)
        w.writerows(vectors())

def verify(path, output):
    expected = list(vectors())
    with open(path,encoding="ascii",newline="") as f:
        r=csv.reader(f,delimiter="\t")
        assert next(r)==HEADER
        assert [tuple(map(int,row)) for row in r]==expected
    reds=matches=0
    with open(output,encoding="ascii",newline="") as f:
        r=csv.reader(f,delimiter="\t")
        assert next(r)==["c","t"]+[p+"_"+k for p in ("direct","decimal","context") for k in HEADER[2:]]
        for e,row in zip(expected,r,strict=True):
            v=tuple(map(int,row))
            assert len(v)==17 and v[:2]==e[:2], (e,v)
            wanted=(e[2],e[3],e[4]+(e[4]-1),e[5],e[6])
            for i in (2,7,12):
                assert v[i:i+5]==wanted, (e,v,i)
            if e[0]==e[1]:
                assert wanted==e[2:]
                matches+=1
            else:
                assert wanted[2]!=e[4]
                reds+=1
    assert (reds,matches)==(8010,90)
    print("STAGE06_ROWS=8100")
    print("STAGE06_COMPARISONS=121500")
    print("STAGE06_EXPECTED_RED_ROWS=8010")
    print("STAGE06_CONTROL_MATCH_ROWS=90")
    print("STAGE06_UNEXPECTED_MISMATCHES=0")

if __name__=="__main__":
    if len(sys.argv)==3 and sys.argv[1]=="--emit":
        emit(sys.argv[2])
    elif len(sys.argv)==4 and sys.argv[1]=="--verify":
        verify(sys.argv[2],sys.argv[3])
    else:
        raise SystemExit(2)
