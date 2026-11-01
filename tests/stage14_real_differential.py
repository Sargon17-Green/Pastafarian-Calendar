#!/usr/bin/env python3
"""Parse the GNAT observer's actual dates and compare each scalar to independent Python results."""
import sys
from pathlib import Path
from stage14_real_oracle import FOUNDATION, date, rank, unrank_labels, month_lengths, weave, MOD

DAYS = (FOUNDATION-1, FOUNDATION, FOUNDATION+1)
FIELD_NAMES = ("year", "cutlet", "cutlet_day", "month", "month_day")
PROVISIONAL = (
    (5000,10,502,6,58),
    (5000,10,503,30,52),
    (5000,14,1,22,33),
)

def selftest():
    checked = 0
    for day,expected in zip(DAYS,PROVISIONAL):
        got = date(FOUNDATION,day)
        for a,b in zip(got,expected):
            assert a==b,(day,got,expected)
            checked += 1
    assert date(FOUNDATION,FOUNDATION)==PROVISIONAL[1]
    checked += 1
    for n in range(2,6):
        from itertools import permutations
        for k in range(1,n+1):
            for r,p in enumerate(permutations(range(1,n+1),k),1):
                assert tuple(unrank_labels(n,k,r))==p
                checked += 1
    for lengths in ((4,5,4),(6,6),(4,4,4,4)):
        for s in ((1,1),(MOD,-1),(MOD//2,1),(MOD//2,-1)):
            sequence = weave(lengths,s)
            assert len(sequence)==sum(lengths)
            assert all(sequence.count(i)==v for i,v in enumerate(lengths))
            checked += 1
    print(f"STAGE14_REAL_ORACLE_SELFTEST_ASSERTIONS={checked}")

def compare(log_path):
    found = {}
    markers = []
    for line in Path(log_path).read_text(encoding="utf-8").splitlines():
        parts = line.strip().split()
        if not parts:
            continue
        if parts[0]=="STAGE14_NATIVE_DATE":
            if len(parts)!=7:
                raise AssertionError(f"bad native record: {line}")
            nums=tuple(map(int,parts[1:]))
            day,fields=nums[0],nums[1:]
            if day in found:
                raise AssertionError(f"duplicate native target: {day}")
            found[day]=fields
        if parts[0].startswith("STAGE14_NATIVE_DOMAIN_REPEAT_ASSERTIONS="):
            markers.append(parts)
    if len(markers)!=1 or markers[0][-1]!="21":
        raise AssertionError("native domain/repeat 21 marker missing or duplicated")
    if set(found)!=set(DAYS):
        raise AssertionError(f"wrong target set: {sorted(found)}")
    checked=0
    for day in DAYS:
        expected=date(FOUNDATION,day)
        actual=found[day]
        for name,observed,independent in zip(FIELD_NAMES,actual,expected):
            checked+=1
            if observed!=independent:
                raise AssertionError(
                    f"target={day} field={name}: Ada={observed} Python={independent}")
    if checked!=15:
        raise AssertionError(f"wrong scalar count {checked}")
    print(f"STAGE14_REAL_FIVEFIELD_SCALARS={checked}")

if __name__=="__main__":
    if len(sys.argv)==2 and sys.argv[1]=="--selftest":
        selftest()
    elif len(sys.argv)==2:
        compare(sys.argv[1])
    else:
        sys.exit("usage: stage14_real_differential.py --selftest | <native-log>")
