#!/usr/bin/env python3
"""Independent Python integer oracle for signed and absolute comparison."""
import csv
import re
from collections import Counter
from pathlib import Path
CATS=("EQUAL","ADJACENT","OPPOSITE","ZERO","RADIX_LOW","RADIX_HIGH")
DEC=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def sgn(x):
    return (x>0)-(x<0)
def main():
    with Path(__file__).with_name("bigint_compare_order_vectors.tsv").open(encoding="utf-8",newline="") as f:
        rows=list(csv.reader(f,delimiter="\t"))
    seen=set(); counts=Counter(); bounds=set(); signed=set(); absolute=set()
    longest=0; zeros=0; negative=0; positive=0
    for i,row in enumerate(rows,1):
        if len(row)!=5 or row[0] not in CATS or not all(DEC.fullmatch(s) for s in row[1:]):
            raise AssertionError(f"row {i}: noncanonical TSV")
        category,sa,sb,ss,sm=row
        if (sa,sb) in seen: raise AssertionError(f"row {i}: duplicate")
        seen.add((sa,sb))
        a,b,want_signed,want_abs=map(int,(sa,sb,ss,sm))
        actual_signed=sgn(a-b)
        actual_abs=sgn(abs(a)-abs(b))
        if (want_signed,want_abs)!=(actual_signed,actual_abs):
            raise AssertionError(f"row {i}: independent comparison oracle")
        if category=="EQUAL" and a!=b: raise AssertionError("equal")
        if category=="ADJACENT" and abs(a-b)!=1: raise AssertionError("adjacent")
        if category=="OPPOSITE" and a*b>=0: raise AssertionError("opposite")
        if category=="ZERO" and (a==0)==(b==0): raise AssertionError("exactly one zero")
        if category.startswith("RADIX_"):
            lo,hi=(1,14) if category=="RADIX_LOW" else (15,28)
            near=any(abs(abs(v)-10**(9*k))<=1 for v in (a,b) for k in range(lo,hi+1))
            if not near and max(len(sa.lstrip("-")),len(sb.lstrip("-")))!=256:
                raise AssertionError("radix family")
        counts[category]+=1
        longest=max(longest,len(sa.lstrip("-")),len(sb.lstrip("-")))
        zeros+=int(a==0 or b==0);negative+=int(a<0 or b<0);positive+=int(a>0 or b>0)
        signed.add(actual_signed);absolute.add(actual_abs)
        for k in range(1,29):
            p=10**(9*k)
            if abs(abs(a)-p)<=1 or abs(abs(b)-p)<=1: bounds.add(k)
    if len(rows)!=96 or len(seen)!=96 or counts!=Counter({c:16 for c in CATS}):
        raise AssertionError(f"distribution: {counts}")
    if longest!=256 or zeros<16 or not negative or not positive or bounds!=set(range(1,29)) or signed!={-1,0,1} or absolute!={-1,0,1}:
        raise AssertionError("missing sign/zero/radix/256-digit coverage")
    print(f"Python-int BigCompare oracle: 96/96 unique, 6x16, radix=28, max=256 digits, zero-pairs={zeros}, outcomes=-1/0/1 signed+absolute, 768 Pascal checks expected; 0 divergences")
if __name__=="__main__": main()
