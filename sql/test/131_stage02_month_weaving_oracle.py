#!/usr/bin/env python3
"""SQL+தமிழ் Stage2 Slice22: standalone oracle and 40 preselected goldens.

The oracle extends independent exhaustive filtering of small multiset words;
it does not query production SQL, the normative SQL or another branch.
Its counting/unranking uses a direct state-factor recomputation, intentionally
unlike production's incremental candidate ratios.
"""
from __future__ import annotations

import argparse
from collections import Counter
from functools import lru_cache
from hashlib import sha256
from math import comb
import sys

sys.set_int_max_str_digits(0)

SMALL = ((2,2), (2,3), (3,3), (2,2,2), (3,2,2),
         (2,2,3), (3,3,3), (2,3,3), (3,2,3))
REALISTIC = (
    (84,84,84), (6,123,123), (80,82,90), (100,100,100),
    (120,120,120), (123,123,123,123), (4,4,123,123),
    (52,52,52,52,52), (62,63,64,65),
    (4,)*46+(68,), (5,)*30+(110,), (20,)*13,
    (23,)*11,
)
BOUNDARY = (120,)+(123,)*46


def brute_words(lengths: tuple[int,...]) -> list[tuple[int,...]]:
    """Enumerate distinct whole multiset words, then filter first/last orders."""
    remaining = list(lengths)
    path: list[int] = []
    good: list[tuple[int,...]] = []
    expected = tuple(range(1,len(lengths)+1))

    def visit() -> None:
        if all(x == 0 for x in remaining):
            w = tuple(path)
            firsts = tuple(sorted(expected,key=w.index))
            lasts = tuple(sorted(expected,key=lambda j: len(w)-1-w[::-1].index(j)))
            if firsts == expected and lasts == expected:
                good.append(w)
            return
        for j in range(len(remaining)):
            if remaining[j]:
                remaining[j] -= 1
                path.append(j+1)
                visit()
                path.pop()
                remaining[j] += 1

    visit()
    return sorted(good)


@lru_cache(maxsize=32)
def future(lengths: tuple[int,...]) -> tuple[tuple[int,...],...]:
    """Independent exact scalar F recurrence, indexed by opened count and tail."""
    if not lengths or min(lengths) < 2:
        raise ValueError("lengths >=2 required")
    k = len(lengths)
    bounds = [0]
    for h in lengths:
        bounds.append(bounds[-1]+h-1)
    rows: list[list[int]] = [[] for _ in range(k+1)]
    rows[k] = [1]*(bounds[k]+1)
    for a in range(k,0,-1):
        h = lengths[a-1]
        running = 0
        choose = 1
        for t in range(bounds[a-1]+1):
            running += rows[a][t+h-1]*choose
            rows[a-1].append(running)
            numerator = choose*(t+h-1)
            assert numerator % (t+1) == 0
            choose = numerator//(t+1)
    return tuple(tuple(row) for row in rows)


def count_after(lengths: tuple[int,...], prefix: tuple[int,...],
                rows: tuple[tuple[int,...],...]) -> int:
    """Exact admissible suffix count by independently rebuilding active factors."""
    k = len(lengths)
    if any(not 1 <= x <= k for x in prefix):
        return 0
    uses = Counter(prefix)
    if any(uses[j] > lengths[j-1] for j in range(1,k+1)):
        return 0
    first = sorted(uses, key=prefix.index)
    if first != list(range(1,len(uses)+1)):
        return 0
    opened = len(first)
    rem = [lengths[j-1]-uses[j] for j in range(1,k+1)]
    closed = 0
    while closed < opened and rem[closed] == 0:
        closed += 1
    if any(rem[j] == 0 for j in range(closed,opened)):
        return 0
    subtotal,active = 0,1
    for j in range(closed,opened):
        subtotal += rem[j]
        active *= comb(subtotal-1,rem[j]-1)
    return active*rows[opened][subtotal]


def unrank(lengths: tuple[int,...], rank: int,
           rows: tuple[tuple[int,...],...] | None = None) -> tuple[int,...]:
    if rows is None:
        rows = future(lengths)
    if rank < 1 or rank > rows[0][0]:
        raise ValueError("out-of-range rank")
    path: list[int] = []
    for _ in range(sum(lengths)):
        for j in range(1,len(lengths)+1):
            n = count_after(lengths,tuple(path+[j]),rows)
            if rank > n:
                rank -= n
            elif n > 0:
                path.append(j)
                break
        else:
            raise AssertionError("candidate partition failed")
    assert rank == 1
    return tuple(path)


def verify_word(lengths: tuple[int,...], word: tuple[int,...]) -> None:
    assert len(word) == sum(lengths)
    assert [word.count(j) for j in range(1,len(lengths)+1)] == list(lengths)
    ids = tuple(range(1,len(lengths)+1))
    assert tuple(sorted(ids,key=word.index)) == ids
    assert tuple(sorted(ids,key=lambda j: len(word)-1-word[::-1].index(j))) == ids


def goldens() -> list[tuple[str,tuple[int,...],int,tuple[int,...]]]:
    records = []
    for index,lengths in enumerate(REALISTIC,1):
        rows = future(lengths)
        n = rows[0][0]
        for letter,rank in zip("aml",(1,(n+1)//2,n)):
            name = f"g{index:02d}{letter}"
            word = unrank(lengths,rank,rows)
            verify_word(lengths,word)
            records.append((name,lengths,rank,word))
    rows = future(BOUNDARY)
    word = unrank(BOUNDARY,1,rows)
    verify_word(BOUNDARY,word)
    records.append(("g40-boundary",BOUNDARY,1,word))
    assert len(records) == 40
    assert len(set(item[0] for item in records)) == 40
    assert all(252 <= sum(v) <= 5778 and len(v) <= 47 and
               all(4 <= h <= 123 for h in v) for _,v,_,_ in records)
    return records


def self_test() -> None:
    total_words,total_prefix,total_ranks=0,0,0
    for lengths in SMALL:
        real = brute_words(lengths)
        rows = future(lengths)
        assert rows[0][0] == len(real)
        counts = Counter(prefix for word in real
                         for prefix in (word[:t] for t in range(len(word)+1)))
        for prefix,count in counts.items():
            assert count_after(lengths,prefix,rows) == count, (lengths,prefix)
            total_prefix += 1
        for index,word in enumerate(real,1):
            assert unrank(lengths,index,rows) == word, (lengths,index)
            total_ranks += 1
        total_words += len(real)
    assert (total_words,total_prefix,total_ranks) == (150,660,150)
    records = goldens()
    print(f"PASS small-vectors={len(SMALL)} brute-words={total_words} "
          f"prefixes={total_prefix} rank-roundtrips={total_ranks} "
          f"independent-realistic-goldens={len(records)} "
          f"boundary-D={sum(BOUNDARY)} boundary-k={len(BOUNDARY)}")


def emit_sql() -> None:
    print("-- Fixed inputs independently chosen before production Native execution.")
    print("CREATE TEMP TABLE slice22_goldens"
          "(name text PRIMARY KEY,lengths integer[] NOT NULL,"
          "rank1 numeric NOT NULL,expected integer[] NOT NULL);")
    for name,lengths,rank,word in goldens():
        lengths_sql = ",".join(map(str,lengths))
        word_sql = ",".join(map(str,word))
        print(f"INSERT INTO slice22_goldens VALUES "
              f"('{name}',ARRAY[{lengths_sql}]::integer[],{rank},"
              f"ARRAY[{word_sql}]::integer[]);")


def emit_hashes() -> None:
    for name,lengths,rank,word in goldens():
        payload = ",".join(map(str,word)).encode("ascii")
        print(f"{name} D={sum(lengths)} k={len(lengths)} "
              f"rank={rank} sha256={sha256(payload).hexdigest()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--self-test",action="store_true")
    group.add_argument("--emit-sql",action="store_true")
    group.add_argument("--emit-hashes",action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.emit_sql:
        emit_sql()
    else:
        emit_hashes()
