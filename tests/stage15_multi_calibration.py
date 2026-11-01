#!/usr/bin/env python3
"""Stage15: source-independent 3x3 date matrix differential against GNAT output."""
import sys
from pathlib import Path
from stage14_real_oracle import FOUNDATION, date

DAYS = (FOUNDATION-1, FOUNDATION, FOUNDATION+1)
PAIRS = tuple((c,t) for c in DAYS for t in DAYS)
FIELDS = ("year","cutlet","cutlet_day","month","month_day")
CENTER = (5000,10,503,30,52)

def selftest():
    expected = {(c,t):tuple(date(c,t)) for c,t in PAIRS}
    checked = 0
    for key,v in expected.items():
        assert len(v)==5, key
        y,ct,cd,m,md=v
        for ok in (4999<=y<=5001, 1<=ct<=17, 1<=cd<=5778,
                   1<=m<=47, 1<=md<=123):
            assert ok,(key,v)
            checked+=1
    for got,golden in zip(expected[(FOUNDATION,FOUNDATION)],CENTER):
        assert got==golden
        checked+=1
    for d in DAYS:
        assert tuple(date(d,d))==expected[(d,d)]
        checked+=1
    assert checked==53
    print(f"STAGE15_INDEPENDENT_MATRIX_SELFTEST_ASSERTIONS={checked}")

def compare(path):
    found={}
    markers=0
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        p=line.strip().split()
        if not p: continue
        if p[0]=="STAGE15_NATIVE_PAIR":
            if len(p)!=8: raise AssertionError(f"malformed native pair: {line}")
            n=tuple(map(int,p[1:]))
            key=n[:2]
            if key in found: raise AssertionError(f"duplicate pair {key}")
            found[key]=n[2:]
        elif p[0].startswith("STAGE15_NATIVE_DOMAIN_REPEAT_ASSERTIONS="):
            if "".join(p)!="STAGE15_NATIVE_DOMAIN_REPEAT_ASSERTIONS=51":
                raise AssertionError(f"invalid marker: {line}")
            markers+=1
    if markers!=1: raise AssertionError(f"native marker count={markers}")
    if set(found)!=set(PAIRS):
        raise AssertionError(f"wrong pair set: {set(found)^set(PAIRS)}")
    checked=0
    for key in PAIRS:
        native,oracle=found[key],tuple(date(*key))
        assert len(native)==len(oracle)==5
        for field,a,b in zip(FIELDS,native,oracle):
            checked+=1
            if a!=b:
                raise AssertionError(
                    f"cal={key[0]} target={key[1]} field={field} Ada={a} Python={b}")
    assert checked==45
    print(f"STAGE15_REAL_FIVEFIELD_SCALARS={checked}")

if __name__=="__main__":
    if len(sys.argv)!=2: sys.exit("usage: stage15_multi_calibration.py --selftest | <log>")
    selftest() if sys.argv[1]=="--selftest" else compare(sys.argv[1])
