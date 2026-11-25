#!/usr/bin/env python3
"""Independent exhaustive multiset-permutation oracle for frozen small families."""
from itertools import permutations
from pathlib import Path
import json

path=Path("qa/issue29/v197_families.txt")
families=[]
total=0
for raw in path.read_text().splitlines():
    line=raw.strip()
    if not line or line.startswith("#"):
        continue
    left,right=line.split("|",1)
    lengths=tuple(map(int,left.split(",")))
    expected=right.split(";")
    assert all(2 <= n <= 3 for n in lengths)
    assert len(set(expected)) == len(expected)
    assert expected == sorted(expected)
    symbols="".join(str(i)*n for i,n in enumerate(lengths,1))
    actual=set()
    for candidate in set(permutations(symbols)):
        first=[candidate.index(str(i)) for i in range(1,len(lengths)+1)]
        last=[len(candidate)-1-candidate[::-1].index(str(i)) for i in range(1,len(lengths)+1)]
        if all(first[i] < first[i+1] for i in range(len(lengths)-1)) and all(last[i] < last[i+1] for i in range(len(lengths)-1)):
            actual.add("".join(candidate))
    actual=sorted(actual)
    assert actual == expected, {"lengths":lengths,"expected":expected,"actual":actual}
    total += len(actual)
    families.append({"lengths":lengths,"count":len(actual),"first":actual[0],"last":actual[-1]})
assert len(families)==14 and total==192, (len(families),total)
Path("evidence").mkdir(exist_ok=True)
Path("evidence/independent-oracle.json").write_text(json.dumps({"families":families,"total_words":total,"permutation_rule":"first positions and last positions both strictly increase by month index"},indent=2)+"\n")
print(f"V197_INDEPENDENT_FIXTURE_PASS families={len(families)} words={total}")
