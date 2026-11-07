#!/usr/bin/env python3
"""Stage28: cross-axis 5780-remote/three-day differential against independent Stage14 source-derived oracle."""
import sys
from pathlib import Path
from stage14_real_oracle import FOUNDATION, date

CAL_DAYS = tuple(FOUNDATION + delta for delta in (-5780, -3, 0, 3, 5780))
TARGET_DAYS = tuple(FOUNDATION + delta for delta in (-5780, -3, 0, 3, 5780))
PAIRS = tuple((c,t) for c in CAL_DAYS for t in TARGET_DAYS)
FIELDS = ("year","cutlet","cutlet_day","month","month_day")
PIVOT = (FOUNDATION - 5780, FOUNDATION + 3)

def selftest():
    assert len(PAIRS) == 25 and len(set(PAIRS)) == 25
    checked = 1
    # Include Stage15 for local +/-1 corners; Stage17 and Stage18 are asymmetric.
    prior_matrices = (
        ((-1, 0, 1), (-1, 0, 1)),  # Stage15
        ((-31, -7, 0, 7, 31), (-31, -7, 0, 7, 31)),  # Stage16
        ((-1, 0, 1), (-5779, 0, 5779)),  # Stage17
        ((-5779, 0, 5779), (-1, 0, 1)),  # Stage18
        ((-5779, -31, 0, 31, 5779), (-5779, -31, 0, 31, 5779)),  # Stage20
        ((-5779, -5778, 5778, 5779), (-5779, -5778, 5778, 5779)),  # Stage21
        ((-5778, -31, 0, 31, 5778), (-5778, -31, 0, 31, 5778)),  # Stage22
        ((-5779, -7, 0, 7, 5779), (-5779, -7, 0, 7, 5779)),  # Stage23
        ((-5778, -7, 0, 7, 5778), (-5778, -7, 0, 7, 5778)),  # Stage24
        ((-5778, -1, 0, 1, 5778), (-5778, -1, 0, 1, 5778)),  # Stage25
        ((-5778, -2, 0, 2, 5778), (-5778, -2, 0, 2, 5778)),  # Stage26
        ((-5779, -2, 0, 2, 5779), (-5779, -2, 0, 2, 5779)),  # Stage27
    )
    previously_tested = {
        (FOUNDATION+c, FOUNDATION+t)
        for cal_axis, target_axis in prior_matrices
        for c in cal_axis for t in target_axis
    }
    new_pairs = set(PAIRS) - previously_tested
    expected_axis = (-5780, -3, 0, 3, 5780)
    expected_new = {
        (FOUNDATION + c, FOUNDATION + t)
        for c in expected_axis for t in expected_axis if (c, t) != (0, 0)
    }
    assert len(expected_new) == 24 and new_pairs == expected_new
    checked += 1
    assert sorted({abs(c - FOUNDATION) for c in CAL_DAYS}) == [0, 3, 5780]
    checked += 1
    assert sorted({abs(t - FOUNDATION) for t in TARGET_DAYS}) == [0, 3, 5780]
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
    for actual, anchor in zip(expected[(FOUNDATION, FOUNDATION)],
                              (5000, 10, 503, 30, 52)):
        assert actual == anchor
        checked += 1
    assert checked == 139
    print(f"STAGE28_INDEPENDENT_REMOTE_THREE_SELFTEST_ASSERTIONS={checked}")


def compare(path):
    found={}
    markers=0
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        p=line.strip().split()
        if not p: continue
        if p[0]=="STAGE28_NATIVE_PAIR":
            if len(p)!=8: raise AssertionError(f"malformed native pair: {line}")
            n=tuple(map(int,p[1:]))
            key=n[:2]
            if key in found: raise AssertionError(f"duplicate pair {key}")
            found[key]=n[2:]
        elif p[0].startswith("STAGE28_NATIVE_REMOTE_THREE_ASSERTIONS="):
            if "".join(p)!="STAGE28_NATIVE_REMOTE_THREE_ASSERTIONS=131":
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
    assert checked==125
    print(f"STAGE28_REAL_FIVEFIELD_SCALARS={checked}")

if __name__=="__main__":
    if len(sys.argv)!=2: sys.exit("usage: stage28_remote_three.py --selftest | <log>")
    selftest() if sys.argv[1]=="--selftest" else compare(sys.argv[1])
