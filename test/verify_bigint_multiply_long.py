#!/usr/bin/env python3
"""Oracle independente de multiplicacao signed/long via Python int."""
import csv
import re
from collections import Counter
from pathlib import Path
SRC=Path(__file__).with_name("bigint_multiply_long_vectors.tsv")
DEC=re.compile(r"(?:0|-?[1-9][0-9]*)$")
REQUIRED={"PP":16,"PN":16,"NP":16,"NN":16,"ZERO":16,"LIMB":16}
def main():
    with SRC.open(encoding="utf-8",newline="") as f:
        rows=list(csv.reader(f,delimiter="\t"))
    counts=Counter()
    unique=set()
    bounds=set()
    max_a=max_b=0
    zleft=zright=0
    cascade=False
    for i,fields in enumerate(rows,1):
        if len(fields)!=4 or fields[0] not in REQUIRED or not all(DEC.fullmatch(x) for x in fields[1:]):
            raise AssertionError(f"linha {i}: quatro campos validos exigidos")
        cat,sa,sb,sp=fields
        if (sa,sb) in unique: raise AssertionError(f"linha {i}: par duplicado")
        unique.add((sa,sb))
        la=len(sa.lstrip("-"));lb=len(sb.lstrip("-"))
        max_a=max(max_a,la);max_b=max(max_b,lb)
        if la>256 or lb>256: raise AssertionError("256 digits excedidos")
        a,b,p=map(int,(sa,sb,sp))
        if a*b!=p: raise AssertionError(f"linha {i}: Python int divergente")
        valid={"PP":a>0 and b>0,"PN":a>0 and b<0,
               "NP":a<0 and b>0,"NN":a<0 and b<0,
               "ZERO":a==0 or b==0,"LIMB":a!=0 and b!=0}
        if not valid[cat]: raise AssertionError(f"linha {i}: grupo/sinal incorreto")
        for k in range(1,29):
            q=10**(9*k)
            if abs(abs(a)-q)<=1 or abs(abs(b)-q)<=1:bounds.add(k)
        if cat=="ZERO":
            zleft+=a==0;zright+=b==0
        cascade|=abs(a)==10**256-1 and abs(b)==10**256-1
        counts[cat]+=1
    if len(rows)!=96 or counts!=Counter(REQUIRED):raise AssertionError(f"quantidade/grupos: {counts}")
    if max_a!=256 or max_b!=256 or len(bounds)<20 or not cascade:
        raise AssertionError("coverage 256/radix/carry")
    if zleft<8 or zright<8:raise AssertionError("zero esquerda/direita")
    print(f"Python int BigMultiply: 96/96 pares; 6x16 grupos; {len(bounds)} expoentes radix; 384 verificacoes esperadas; 0 divergencias")
if __name__=="__main__":main()
