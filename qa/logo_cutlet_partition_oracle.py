#!/usr/bin/env python3
# Independent Python-int breakpoint-subset oracle and Native fixture generator.
import argparse
import itertools
import math
from pathlib import Path

MAX_G, HOST_G, NATIVE_G = 5778, 12, 8
BOUNDARY_G, BOUNDARY_K = (6, 71, 137), (6, 17)


def count(g, k, r):
    if not (1 <= g <= MAX_G and 1 <= k <= g):
        raise ValueError("G/K")
    if r == -1:
        return math.comb(g - 1, k - 1)
    if not (1 <= r < g):
        raise ValueError("required")
    return 0 if k == 1 else math.comb(g - 2, k - 2)


def parts(g, cuts):
    out, prev = [], 0
    for x in cuts:
        out.append(x - prev)
        prev = x
    return tuple(out + [g - prev])


def cuts_of(p):
    out, s = [], 0
    for x in p[:-1]:
        s += x
        out.append(s)
    return tuple(out)


def enum_cuts(g, k, r):
    if r == -1:
        return list(itertools.combinations(range(1, g), k - 1))
    if k == 1:
        return []
    rest = [x for x in range(1, g) if x != r]
    return sorted(tuple(sorted((*c, r))) for c in itertools.combinations(rest, k - 2))


def rank_subset(n, xs):
    rank0, prev, m = 0, 0, len(xs)
    for i, x in enumerate(xs):
        rem = m - i
        rank0 += math.comb(n - prev, rem) - math.comb(n - x + 1, rem)
        prev = x
    return rank0 + 1


def unrank_subset(n, m, rank1):
    total = math.comb(n, m)
    if not 1 <= rank1 <= total:
        raise ValueError("rank")
    r0, prev, out = rank1 - 1, 0, []
    for rem in range(m, 0, -1):
        for x in range(prev + 1, n - rem + 2):
            block = math.comb(n - x, rem - 1)
            if r0 < block:
                out.append(x)
                prev = x
                break
            r0 -= block
        else:
            raise AssertionError("unrank")
    return tuple(out)


def unrank_parts(g, k, r, rank1):
    if not 1 <= rank1 <= count(g, k, r):
        raise ValueError("partition rank")
    if r == -1:
        cuts = unrank_subset(g - 1, k - 1, rank1)
    else:
        c = unrank_subset(g - 2, k - 2, rank1)
        cuts = tuple(sorted((*[x if x < r else x + 1 for x in c], r)))
    return parts(g, cuts)


def rank_parts(g, k, r, p):
    c = cuts_of(p)
    if r == -1:
        return rank_subset(g - 1, c)
    return rank_subset(g - 2, tuple(x if x < r else x - 1 for x in c if x != r))


def bi(v):
    if v == 0:
        return "bi.zero"
    ds = []
    while v:
        v, d = divmod(v, 10000)
        ds.append(str(d))
    return "(bi.make 1 [" + " ".join(ds) + "])"


def ll(xs):
    return "[]" if not xs else "[" + " ".join(map(str, xs)) + "]"


HEADER = r'''load "src/exact_integer.logo
load "src/stage02_context.logo
load "qa/logo_cutlet_partition_candidate.logo
make "QA.CP.FAILED "false
make "QA.CP.CHECKS 0
make "QA.CP.DOMAINS 0
make "QA.CP.PAIRS 0
make "QA.CP.INVALID 0

to qa.cp.native.require :ok :tag
  make "QA.CP.CHECKS (:QA.CP.CHECKS + 1)
  if not :ok [make "QA.CP.FAILED "true print sentence [CP_NATIVE_FAIL] :tag]
end
to qa.cp.native.domain :g :k :r :expected :tag
  make "QA.CP.DOMAINS (:QA.CP.DOMAINS + 1)
  localmake "actual qa.cp.count :g :k :r
  qa.cp.native.require (monster.stage02.bi.canonical :actual) (list :tag [count_canonical])
  qa.cp.native.require (bi.eq :actual :expected) (list :tag [count_value])
end
to qa.cp.native.pair :g :k :r :expectedRank :expectedParts :tag
  make "QA.CP.PAIRS (:QA.CP.PAIRS + 1)
  localmake "actualRank qa.cp.rank :g :k :r :expectedParts
  qa.cp.native.require (monster.stage02.bi.canonical :actualRank) (list :tag [rank_canonical])
  qa.cp.native.require (bi.eq :actualRank :expectedRank) (list :tag [rank_value])
  localmake "actualParts qa.cp.unrank :g :k :r :expectedRank
  qa.cp.native.require (equalp :actualParts :expectedParts) (list :tag [unrank_value])
  localmake "backRank qa.cp.rank :g :k :r :actualParts
  qa.cp.native.require (bi.eq :backRank :expectedRank) (list :tag [inverse])
end
to qa.cp.native.invalid :actual :tag
  make "QA.CP.INVALID (:QA.CP.INVALID + 1)
  qa.cp.native.require (equalp :actual []) :tag
end

'''


def invalid_tests():
    cases = [
        ("qa.cp.count 0 1 -1", "G_zero"),
        ("qa.cp.count 5779 6 -1", "G_above_max"),
        ("qa.cp.count 5.5 2 -1", "G_fraction"),
        ("qa.cp.count 7 0 -1", "K_zero"),
        ("qa.cp.count 7 8 -1", "K_above_G"),
        ("qa.cp.count 7 2.5 -1", "K_fraction"),
        ("qa.cp.count 7 3 0", "r_zero"),
        ("qa.cp.count 7 3 7", "r_G"),
        ("qa.cp.count 7 3 1.5", "r_fraction"),
        ("qa.cp.count 7 3 -2", "r_below_minus_one"),
        ("qa.cp.rank 7 3 -1 [1 1]", "parts_length"),
        ("qa.cp.rank 7 3 -1 [0 2 5]", "parts_nonpositive"),
        ("qa.cp.rank 7 3 -1 [1 2 3]", "parts_sum"),
        ("qa.cp.rank 7 3 3 [1 1 5]", "parts_missing_r"),
        ("qa.cp.rank 7 3 1 [2 2 3]", "parts_passed_r"),
        ("qa.cp.unrank 7 3 -1 bi.zero", "rank_zero"),
        ("qa.cp.unrank 7 3 -1 (bi.small -1)", "rank_negative"),
        ("qa.cp.unrank 7 3 -1 (list 1 [1 0])", "rank_high_zero"),
        ("qa.cp.unrank 7 3 -1 (list 1 [10000])", "rank_digit"),
        ("qa.cp.unrank 7 3 -1 (list 2 [1])", "rank_sign"),
        ("qa.cp.unrank 7 3 -1 (bi.add (qa.cp.count 7 3 -1) (bi.small 1))", "rank_above_count"),
    ]
    out = [f"qa.cp.native.invalid ({x}) [bad_{tag}]" for x, tag in cases]
    out += [
        "qa.cp.native.require (bi.eq (qa.cp.count 5 1 2) bi.zero) [empty_count_zero]",
        'qa.cp.native.require (equalp (qa.cp.ask.allowed 5 1 2) "false) [empty_no_ask]',
        'qa.cp.native.require (equalp (qa.cp.ask.allowed 5 2 2) "true) [nonempty_ask_allowed]',
    ]
    return out


def host_audit():
    domains = comps = empty = pairs = 0
    for g in range(1, HOST_G + 1):
        comps += 2 ** (g - 1)
        for k in range(1, g + 1):
            for r in (-1, *range(1, g)):
                domains += 1
                cs = enum_cuts(g, k, r)
                n = count(g, k, r)
                assert len(cs) == n and cs == sorted(set(cs))
                ps = [parts(g, c) for c in cs]
                assert all(len(p) == k and sum(p) == g and min(p, default=1) > 0 for p in ps)
                if r != -1:
                    assert all(r in c for c in cs)
                if n == 0:
                    empty += 1
                pairs += len(ps)
                for i, (c, p) in enumerate(zip(cs, ps), 1):
                    assert cuts_of(p) == c and rank_parts(g, k, r, p) == i
                    assert unrank_parts(g, k, r, i) == p
    assert (domains, comps, empty, pairs) == (650, 4095, 66, 24576)
    return domains, comps, empty, pairs


def small_cases():
    out, domains, pairs = [], 0, 0
    for g in range(1, NATIVE_G + 1):
        for k in range(1, g + 1):
            for r in (-1, *range(1, g)):
                cs = enum_cuts(g, k, r)
                tag = f"S{g}_{k}_{'m1' if r == -1 else r}"
                out.append(f"qa.cp.native.domain {g} {k} {r} {bi(len(cs))} [{tag}]")
                domains += 1
                for i, c in enumerate(cs, 1):
                    p = parts(g, c)
                    assert rank_parts(g, k, r, p) == i
                    out.append(f"qa.cp.native.pair {g} {k} {r} {bi(i)} {ll(p)} [{tag}_{i}]")
                    pairs += 1
    return out + invalid_tests(), domains, pairs


def large_cases():
    out, domains, pairs = [], 0, 0
    for g in BOUNDARY_G:
        for k in BOUNDARY_K:
            if k > g:
                continue
            for r in dict.fromkeys((-1, 1, g // 2, g - 1)):
                n = count(g, k, r)
                tag = f"L{g}_{k}_{'m1' if r == -1 else r}"
                out.append(f"qa.cp.native.domain {g} {k} {r} {bi(n)} [{tag}]")
                domains += 1
                ranks = sorted({1, min(2, n), (n + 1) // 2, max(1, n - 1), n})
                for sample_index, i in enumerate(ranks, 1):
                    p = unrank_parts(g, k, r, i)
                    assert rank_parts(g, k, r, p) == i
                    out.append(f"qa.cp.native.pair {g} {k} {r} {bi(i)} {ll(p)} [{tag}_P{sample_index}]")
                    pairs += 1
    return out, domains, pairs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shard", choices=("small-exhaustive", "large-boundary"), required=True)
    ap.add_argument("--output", type=Path, required=True)
    a = ap.parse_args()
    d, c, e, p = host_audit()
    print(f"CP_HOST_EXHAUSTIVE_DOMAINS {d}")
    print(f"CP_HOST_EXHAUSTIVE_COMPOSITIONS {c}")
    print(f"CP_HOST_EXHAUSTIVE_EMPTY_DOMAINS {e}")
    print(f"CP_HOST_EXHAUSTIVE_INDEX_PAIRS {p}")
    print("CP_HOST_ORACLE=PASS")
    if a.shard == "small-exhaustive":
        body, nd, np = small_cases()
        marker = f"print [CP_NATIVE_SMALL_DOMAINS {nd}]"
        pm = f"print [CP_NATIVE_SMALL_PARTITIONS {np}]"
    else:
        body, nd, np = large_cases()
        marker = f"print [CP_NATIVE_LARGE_DOMAINS {nd}]"
        pm = f"print [CP_NATIVE_LARGE_PARTITIONS {np}]"
    a.output.parent.mkdir(parents=True, exist_ok=True)
    footer = "\n".join([
        'if :QA.CP.FAILED [print [CP_NATIVE_FALIIS] stop]',
        'print sentence [CP_NATIVE_CHECKS] :QA.CP.CHECKS',
        'print sentence [CP_NATIVE_DOMAINS] :QA.CP.DOMAINS',
        'print sentence [CP_NATIVE_PARTITIONS] :QA.CP.PAIRS',
        'print sentence [CP_NATIVE_INVALID_CASES] :QA.CP.INVALID',
        marker, pm, 'print [CP_NATIVE_PASIS]', ''
    ])
    a.output.write_text(HEADER + "\n".join(body) + "\n" + footer, encoding="utf-8")
    print(f"CP_HOST_NATIVE_SHARD {a.shard}")
    print(f"CP_HOST_NATIVE_DOMAINS {nd}")
    print(f"CP_HOST_NATIVE_PARTITIONS {np}")
    print(f"CP_HOST_NATIVE_LOGO_BYTES {a.output.stat().st_size}")
    print("CP_HOST_NATIVE_FIXTURES=PASS")


if __name__ == "__main__":
    main()
