#!/usr/bin/env python3
"""Stage21: 4x4 year-limit-adjacent calendar differential using the Stage14 independent Python oracle."""
import sys
from pathlib import Path
from stage14_real_oracle import FOUNDATION, date

CAL_DAYS = tuple(FOUNDATION + delta for delta in (-5779, -5778, 5778, 5779))
TARGET_DAYS = tuple(FOUNDATION + delta for delta in (-5779, -5778, 5778, 5779))
PAIRS = tuple((c,t) for c in CAL_DAYS for t in TARGET_DAYS)
FIELDS = ("year","cutlet","cutlet_day","month","month_day")
PIVOT = (FOUNDATION - 5778, FOUNDATION + 5778)

def selftest():
    assert len(PAIRS) == 16 and len(set(PAIRS)) == 16
    checked = 1
    assert sorted({abs(c - FOUNDATION) for c in CAL_DAYS}) == [5778, 5779]
    checked += 1
    assert sorted({abs(t - FOUNDATION) for t in TARGET_DAYS}) == [5778, 5779]
    checked += 1
    expected = {(c, t): tuple(date(c, t)) for c, t in PAIRS}
    for key, v in expected.items():
        assert len(v) == 5, key
        y, ct, cd, m, md = v
        for ok in (4900 <= y <= 5100, 1 <= ct <= 17, 1 <= cd <= 5778,
                   1 <= m <= 47, 1 <= md <= 123):
            assert ok, (key, v)
            checked += 1
    for a, b in zip(expected[PIVOT], tuple(date(*PIVOT))):
        assert a == b
        checked += 1
    assert checked == 88
    print(f"STAGE21_INDEPENDENT_EDGE_ADJACENT_SELFTEST_ASSERTIONS={checked}")


def compare(path):
    found={}
    markers=0
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        p=line.strip().split()
        if not p: continue
        if p[0]=="STAGE21_NATIVE_PAIR":
            if len(p)!=8: raise AssertionError(f"malformed native pair: {line}")
            n=tuple(map(int,p[1:]))
            key=n[:2]
            if key in found: raise AssertionError(f"duplicate pair {key}")
            found[key]=n[2:]
        elif p[0].startswith("STAGE21_NATIVE_EDGE_ADJACENT_ASSERTIONS="):
            if "".join(p)!="STAGE21_NATIVE_EDGE_ADJACENT_ASSERTIONS=85":
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
    assert checked==80
    print(f"STAGE21_REAL_FIVEFIELD_SCALARS={checked}")

if __name__=="__main__":
    if len(sys.argv)!=2: sys.exit("usage: stage21_edge_adjacent.py --selftest | <log>")
    selftest() if sys.argv[1]=="--selftest" else compare(sys.argv[1])
