"""Independent Python-int ASK21 / positive-part lexicographic oracle.
No candidate imports, no breakpoint compression or complement ranking.
Run python3 qa/logo_ask21_cutlet_oracle.py > fixture.json.
"""
import json
from functools import lru_cache
from itertools import product
from random import Random

M = (1 << 127) - 1

def norm(x):
    return (x - 1) % M + 1

def ask21(bowls, order):
    nxt = order[(order.index(2) + 1) % 6]
    first = norm((bowls[1] + 202) ** 2 + 179 * bowls[nxt - 1] + 21)
    d = norm((first + 215) ** 2 + 193 * first + 197 * bowls[5])
    return first, 1 if d % 2 else -1

def choose(stream, n):
    x, step = stream
    assert 1 <= x <= M and step in (-1, 1) and 1 <= n <= M
    limit = M // n * n
    if x > limit:
        # Compute distance to first accepted sample, without candidate's rank shortcut.
        distance = M - x + 1 if step == 1 else x - limit
        x = (x - 1 + step * distance) % M + 1
        assert 1 <= x <= limit
    return (x - 1) % n + 1

def counter(g, k, required):
    @lru_cache(None)
    def count(remaining, slots, hit):
        if slots == 0:
            return int(remaining == 0 and hit)
        if remaining < slots:
            return 0
        total = 0
        for x in range(1, remaining - slots + 2):
            prefix = g - remaining + x
            if not hit and prefix > required:
                break
            seen = hit or (slots > 1 and prefix == required)
            total += count(remaining - x, slots - 1, seen)
        return total
    return count

def partition(g, k, required, rank):
    count = counter(g, k, required)
    hit = required == -1
    n = count(g, k, hit)
    assert 1 <= rank <= n
    rem, slots, out = g, k, []
    while slots:
        for x in range(1, rem - slots + 2):
            prefix = g - rem + x
            if not hit and prefix > required:
                break
            seen = hit or (slots > 1 and prefix == required)
            block = count(rem - x, slots - 1, seen)
            if rank > block:
                rank -= block
            else:
                out.append(x)
                rem, slots, hit = rem - x, slots - 1, seen
                break
        else:
            raise AssertionError("no positive-part block")
    assert rem == 0 and hit and rank == 1
    return n, out

def exhaustive_smoke():
    from itertools import combinations
    for g in range(1, 9):
        for k in range(1, g + 1):
            for required in [-1, *range(1, g)]:
                # Enumerate actual positive parts; no use of candidate rank/unrank.
                expected = []
                def enumerate_parts(prefix, rem, slots):
                    if slots == 0:
                        if rem == 0 and (required == -1 or required in
                           [sum(prefix[:i]) for i in range(1, len(prefix))]):
                            expected.append(prefix)
                        return
                    for x in range(1, rem - slots + 2):
                        enumerate_parts(prefix + [x], rem - x, slots - 1)
                enumerate_parts([], g, k)
                assert counter(g, k, required)(g, k, required == -1) == len(expected)
                for rank, p in enumerate(expected, 1):
                    assert partition(g, k, required, rank) == (len(expected), p)

def fixtures():
    rng = Random(2026112821)
    rows = []
    for g, k in [(6,6),(71,6),(137,6),(137,17)]:
        for required in [-1, 1, g-1]:
            n = counter(g,k,required)(g,k,required == -1)
            assert n > 0
            for target in [-1,1]:
                for attempts in range(10000):
                    bowls = [rng.randrange(1,M+1) for _ in range(6)]
                    order = list(range(1,7))
                    rng.shuffle(order)
                    stream = ask21(bowls,order)
                    if stream[1] == target:
                        break
                else:
                    raise AssertionError("direction search exhausted")
                rank = choose(stream,n)
                actual_n, parts = partition(g,k,required,rank)
                assert n == actual_n and sum(parts) == g and len(parts) == k
                rows.append(dict(g=g,k=k,required=required,bowls=bowls,order=order,
                                 n=n,stream=stream,rank=rank,parts=parts))
    assert len(rows) == 24
    assert sum(r["stream"][1] == 1 for r in rows) == 12
    return rows

if __name__ == "__main__":
    exhaustive_smoke()
    rows = fixtures()
    print(json.dumps({"valid":rows,
        "empty":[[2,1,1],[8,1,1],[137,1,1]],
        "invalid":[[0,1,-1],[138,1,-1],[8,0,-1],[137,18,-1],[8,2,8]],
        "boundary":[["NONE",10,18,-1],[9,10,18,-1],[10,10,18,-1],
                    [11,10,18,1],[17,10,18,7],[18,10,18,-1],[19,10,18,-1]],
        "coverage":{"valid":24,"step_minus":12,"step_plus":12}},indent=2))
