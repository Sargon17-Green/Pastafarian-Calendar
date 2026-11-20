"""Independent synthetic arithmetic window oracle; no SQL/reference imports."""
from bisect import bisect_left, bisect_right
from random import Random
rng = Random(20261120)
G = {0: 0}
for k in range(1, 401):
    G[k] = G[k - 1] + rng.randint(42, 963)
for k in range(-1, -401, -1):
    G[k] = G[k + 1] - rng.randint(42, 963)
keys = sorted(G)
vals = [G[k] for k in keys]
def trusted(day):
    low, high = day - 5778, day + 5778
    lo = keys[bisect_right(vals, low) - 1] - 1
    hi = keys[bisect_left(vals, high)] + 1
    return lo, [G[k] for k in range(lo, hi + 1)]
def fast(day):
    low, high = day - 5778, day + 5778
    visited = {0: 0}
    for direction, limit in ((1, high), (-1, low)):
        i, d, done = 0, 0, False
        while not done:
            prior = d
            i += direction
            d += G[i] - G[i - direction]
            visited[i] = d
            done = prior >= limit if direction == 1 else prior <= limit
    lo = max(k for k, v in visited.items() if v <= low) - 1
    hi = min(k for k, v in visited.items() if v >= high) + 1
    return lo, [visited[k] for k in range(lo, hi + 1)]
days = {0, 1, -1, 42, -42, 5778, -5778}
for k, v in G.items():
    if abs(v) <= 40000:
        for delta in (-1, 0, 1, 5778, -5778):
            days.add(v + delta)
for _ in range(4000):
    days.add(rng.randint(-40000, 40000))
for x in sorted(days):
    assert trusted(x) == fast(x), x
print('SYNTHETIC_WINDOW_EQUIVALENCE_PASS', len(days),
      'cases; signed/exact-gate/adjacent/5778; seed=20261120')
