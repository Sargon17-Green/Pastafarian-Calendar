#!/usr/bin/env python3
"""PC-BRANCH-CLOJURE-DUTCH: independent, TEST-ONLY DP feasibility oracle.

Cost is abstract cached states + legal transitions, NOT production insertion cells.
"""
import argparse
from collections import Counter
from functools import lru_cache

LIMIT = 5_000_000

class Unproven(Exception):
    pass


def brute(profile):
    """Enumerate unrestricted multiset words; filter by first/last order."""
    counts = Counter({i + 1: n for i, n in enumerate(profile)})
    size = sum(profile)
    if size > 11:
        raise ValueError("tiny oracle only")
    result = []
    def walk(word):
        if len(word) == size:
            first = [word.index(i) for i in range(1, len(profile) + 1)]
            last = [size - 1 - word[::-1].index(i)
                    for i in range(1, len(profile) + 1)]
            if first == sorted(first) and last == sorted(last):
                result.append(word)
            return
        for i in sorted(counts):
            if counts[i]:
                counts[i] -= 1
                walk(word + (i,))
                counts[i] += 1
    walk(())
    return result


def unrank(profile, rank, position, budget=LIMIT):
    """Exact suffix-state DP: f(s)=sum(f(s')) over legal next letters."""
    if not (2 <= len(profile) <= 47 and all(1 <= x <= 123 for x in profile)):
        raise ValueError("invalid profile")
    if not 1 <= budget <= LIMIT or not 1 <= position <= sum(profile):
        raise ValueError("invalid budget or position")
    spent = [0, 0]  # states, transitions
    def charge(which):
        if sum(spent) >= budget:
            raise Unproven("abstract-cell budget exceeded")
        spent[which] += 1
    def next_states(rest, opened, closed):
        for i in range(1, min(len(rest), opened + 1) + 1):
            n = rest[i - 1]
            if n == 0 or (n == 1 and i != closed + 1):
                continue
            updated = list(rest)
            updated[i - 1] -= 1
            yield i, tuple(updated), max(opened, i), closed + (n == 1)
    @lru_cache(None)
    def count(rest, opened, closed):
        charge(0)
        if not any(rest):
            return int(opened == closed == len(profile))
        total = 0
        for _, updated, new_opened, new_closed in next_states(rest, opened, closed):
            charge(1)
            total += count(updated, new_opened, new_closed)
        return total
    rest = (profile[0] - 1,) + profile[1:]
    opened, closed = 1, int(profile[0] == 1)
    total = count(rest, opened, closed)
    if not 1 <= rank <= total:
        raise ValueError("invalid rank")
    prefix = [1]
    while len(prefix) < position:
        for i, updated, new_opened, new_closed in next_states(rest, opened, closed):
            n = count(updated, new_opened, new_closed)
            if rank > n:
                rank -= n
            else:
                prefix.append(i)
                rest, opened, closed = updated, new_opened, new_closed
                break
        else:
            raise AssertionError("no legal suffix")
    return tuple(prefix), total, tuple(spent)


def test():
    profiles = [(2,2), (2,3), (3,2), (3,3), (4,4), (4,5), (5,4),
                (2,2,2), (3,3,2)]
    checks = words = max_spent = 0
    for profile in profiles:
        legal = brute(profile)
        assert legal == sorted(set(legal)) and legal
        words += len(legal)
        for rank, word in enumerate(legal, 1):
            for position in range(1, len(word) + 1):
                prefix, total, spent = unrank(profile, rank, position)
                assert prefix == word[:position] and total == len(legal)
                max_spent = max(max_spent, sum(spent))
                checks += 1
    try:
        unrank((4,4), 1, 4, 1)
        raise AssertionError("missing refusal")
    except Unproven:
        pass
    assert 4_995_675 <= LIMIT < 5_002_652
    assert 5_002_652 - LIMIT == 2_652
    print(f"STATIC_QA_PASS profiles={len(profiles)} words={words} "
          f"rank_position_checks={checks} max_abstract_cells={max_spent}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--profile", default="4,5")
    p.add_argument("--rank", type=int, default=2)
    p.add_argument("--position", type=int, default=5)
    p.add_argument("--budget", type=int, default=LIMIT)
    a = p.parse_args()
    if a.self_test:
        test()
    else:
        try:
            print(unrank(tuple(map(int, a.profile.split(","))), a.rank,
                         a.position, a.budget))
        except Unproven:
            print("BOUNDED_DP_UNPROVEN")
            raise SystemExit(2)
