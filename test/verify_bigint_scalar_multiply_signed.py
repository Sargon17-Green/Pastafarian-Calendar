#!/usr/bin/env python3
"""Independent Python-int oracle for 96 BigMultiplyInt64 cases."""
import csv
import re
from collections import Counter
from pathlib import Path
CATS=("MIN_EDGE","MAX_EDGE","ZERO_FACTOR","RADIX_LOW","RADIX_HIGH","SIGN_GRID")
LO,HI=-(1<<63),(1<<63)-1
DEC=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def main():
    with Path(__file__).with_name("bigint_scalar_multiply_signed_vectors.tsv").open(encoding="utf-8",newline="") as fh:
        rows=list(csv.reader(fh,delimiter="\t"))
    seen=set(); counts=Counter(); boundaries=set()
    longest=zero=positive=negative=0
    for index,row in enumerate(rows,1):
        if len(row)!=6 or row[0] not in CATS or not all(DEC.fullmatch(x) for x in row[1:]):
            raise AssertionError(f"row {index}: six canonical fields")
        cat,sa,sb,sp,ss,sl=row
        if (sa,sb) in seen: raise AssertionError(f"row {index}: duplicate")
        seen.add((sa,sb))
        a,b,p,sign,limbs=map(int,(sa,sb,sp,ss,sl))
        if len(sa.lstrip("-"))>256 or not LO<=b<=HI:
            raise AssertionError(f"row {index}: input bounds")
        correct=a*b
        expected=(correct,(correct>0)-(correct<0),(len(str(abs(correct)))+8)//9 if correct else 0)
        if (p,sign,limbs)!=expected:
            raise AssertionError(f"row {index}: independent product/sign/limbs")
        if cat=="MIN_EDGE" and b!=LO: raise AssertionError("MIN_EDGE")
        if cat=="MAX_EDGE" and b!=HI: raise AssertionError("MAX_EDGE")
        if cat=="ZERO_FACTOR" and a!=0 and b!=0: raise AssertionError("ZERO_FACTOR")
        for k in range(1,29):
            if abs(abs(a)-10**(9*k))<=1: boundaries.add(k)
        if cat.startswith("RADIX_"):
            lo,hi=(1,14) if cat=="RADIX_LOW" else (15,28)
            if not any(abs(abs(a)-10**(9*k))<=1 for k in range(lo,hi+1)):
                raise AssertionError(f"row {index}: missing radix boundary")
        longest=max(longest,len(sa.lstrip("-")));counts[cat]+=1
        zero+=(p==0);positive+=(p>0);negative+=(p<0)
    if len(rows)!=96 or counts!=Counter({c:16 for c in CATS}):
        raise AssertionError(f"distribution: {counts}")
    if boundaries!=set(range(1,29)) or longest!=256 or zero<16 or not positive or not negative:
        raise AssertionError("coverage")
    print(f"Python-int oracle BigMultiplyInt64: 96/96 unique, 6x16, 28 radix boundaries, A=256 digits,"
          f" product zero={zero}, positive={positive}, negative={negative}; 480 Pascal checks expected; 0 divergences")
if __name__=="__main__": main()
