#!/usr/bin/env python3
"""Independent remaining-count DP oracle for Lua Haitian sparse-prefix QA.
No production, Lua date, or real 47-month weaving. Resource caps are not validity limits.
"""
import argparse
import time
from functools import lru_cache
from itertools import permutations, product

PROJECT_ID = 'PC-BRANCH-LUA-HAITIAN'
MAX_STATES = 250000

class ResourceLimit(Exception):
    pass

def dp_count(lengths, prefix=(), state_limit=MAX_STATES):
    """Enumerate residual-word states, not endpoint paths or generating functions."""
    if not lengths or any(type(x) is not int or x < 2 for x in lengths):
        raise ValueError('COUNTS')
    m = len(lengths)
    remaining = list(lengths)
    first = last = 0
    for label in prefix:
        if type(label) is not int or not 0 <= label < m:
            return 0, 0
        n = remaining[label]
        if n == 0:
            return 0, 0
        if n == lengths[label]:
            if label != first:
                return 0, 0
            first += 1
        elif n == 1:
            if label != last:
                return 0, 0
            last += 1
        elif not last <= label < first:
            return 0, 0
        remaining[label] -= 1

    visited = 0
    @lru_cache(maxsize=None)
    def recur(rem, open_index, close_index):
        nonlocal visited
        visited += 1
        if visited > state_limit:
            raise ResourceLimit('DP_STATE_CAP')
        if not any(rem):
            return 1
        result = 0
        for label, n in enumerate(rem):
            if not n:
                continue
            if n == lengths[label]:
                if label != open_index:
                    continue
                a, b = open_index + 1, close_index
            elif n == 1:
                if label != close_index:
                    continue
                a, b = open_index, close_index + 1
            else:
                if not close_index <= label < open_index:
                    continue
                a, b = open_index, close_index
            nxt = rem[:label] + (n - 1,) + rem[label + 1:]
            result += recur(nxt, a, b)
        return result
    return recur(tuple(remaining), first, last), visited

def word_oracle(lengths):
    """Independent exhaustive multiset enumeration; check first/last positions."""
    rem = list(lengths)
    word, accepted = [], []
    def visit():
        if not any(rem):
            starts = tuple(word.index(i) for i in range(len(lengths)))
            stops = tuple(len(word) - 1 - word[::-1].index(i) for i in range(len(lengths)))
            if starts == tuple(sorted(starts)) and stops == tuple(sorted(stops)):
                accepted.append(tuple(word))
            return
        for i, n in enumerate(rem):
            if n:
                rem[i] -= 1
                word.append(i)
                visit()
                word.pop()
                rem[i] += 1
    visit()
    return accepted

def mutation_rejection():
    words = set(permutations((0, 0, 1, 1)))
    def tests(w):
        opens = w.index(0) < w.index(1)
        closes = max(i for i, v in enumerate(w) if v == 0) < max(i for i, v in enumerate(w) if v == 1)
        return opens, closes
    full = sum(all(tests(w)) for w in words)
    missing_close_gate = sum(tests(w)[0] for w in words)
    missing_open_gate = sum(tests(w)[1] for w in words)
    assert full == 2
    assert missing_close_gate == 3 and missing_close_gate != full
    assert missing_open_gate == 3 and missing_open_gate != full
    return 2

def selftest(with_original=True):
    if with_original:
        import lua_haitian_sparse_path_qa as gf
    fixtures = [v for m in range(1, 4) for v in product((2, 3, 4), repeat=m)
                if sum(v) <= 12]
    fixtures += [(2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 2, 2), (3, 3, 2, 2)]
    counts = prefixes = ranks = 0
    for lengths in fixtures:
        words = word_oracle(lengths)
        total, states = dp_count(lengths)
        assert total == len(words) and states > 0, (lengths, total)
        if with_original:
            assert total == gf.suffix_count(lengths, ()), (lengths, 'GF_COUNT')
        counts += 1
        probes = {(), (0,), (len(lengths) - 1,), (0, 0)}
        if words:
            for idx in (0, len(words) // 2, len(words) - 1):
                probes.add(words[idx][:min(4, sum(lengths))])
        for prefix in probes:
            expected = sum(w[:len(prefix)] == prefix for w in words)
            actual, _ = dp_count(lengths, prefix)
            assert actual == expected, (lengths, prefix, actual, expected)
            if with_original:
                assert actual == gf.suffix_count(lengths, prefix), (lengths, prefix, 'GF_PREFIX')
            prefixes += 1
        for idx in sorted({0, len(words) // 2, len(words) - 1}):
            rank, output = idx + 1, []
            while len(output) < sum(lengths):
                for label in range(len(lengths)):
                    block, _ = dp_count(lengths, tuple(output) + (label,))
                    if rank > block:
                        rank -= block
                    elif block:
                        output.append(label)
                        break
                else:
                    raise AssertionError('DP_LEX_UNRANK_EXHAUSTED')
            assert tuple(output) == words[idx] and rank == 1
            if with_original:
                assert tuple(output) == gf.unrank(lengths, idx + 1)
            ranks += 1
    assert (counts, prefixes, ranks) == (43, 290, 122)
    assert dp_count((2, 2), (1,))[0] == 0
    assert dp_count((2, 2), (0, 0, 1, 1))[0] == 1
    assert dp_count((2, 2), (0, 0, 1, 1, 1))[0] == 0
    assert mutation_rejection() == 2
    for invalid in ((), (1,), (2, 1), (2, 2.0)):
        try:
            dp_count(invalid)
        except ValueError:
            pass
        else:
            raise AssertionError(('INVALID_COUNTS_ACCEPTED', invalid))
    try:
        dp_count((3,) * 5, state_limit=1)
    except ResourceLimit as e:
        assert str(e) == 'DP_STATE_CAP'
    else:
        raise AssertionError('STATE_CAP_MISSED')
    print('LUA_HAITIAN_SPARSE_INDEPENDENT_COUNTS_PASS: 43/43')
    print('LUA_HAITIAN_SPARSE_INDEPENDENT_PREFIX_PASS: 290/290')
    print('LUA_HAITIAN_SPARSE_INDEPENDENT_UNRANK_PASS: 122/122')
    print('LUA_HAITIAN_SPARSE_MUTATIONS_REJECTED: 2/2')
    print('LUA_HAITIAN_SPARSE_GUARD_PASS: 5/5')
    for m in (4, 6, 8, 10):
        start = time.perf_counter()
        try:
            total, states = dp_count((3,) * m)
            print(f'BENCH_DP|m={m}|length={3*m}|states={states}|seconds={time.perf_counter()-start:.6f}|count_digits={len(str(total))}|status=EXACT')
        except (ResourceLimit, RecursionError) as exc:
            print(f'BENCH_DP|m={m}|length={3*m}|status=RESOURCE_LIMIT|reason={type(exc).__name__}')
    start = time.perf_counter()
    total, states = dp_count((2,) * 47)
    print(f'BENCH_DP|m=47|length=94|states={states}|seconds={time.perf_counter()-start:.6f}|count_digits={len(str(total))}|status=EXACT_TRIVIAL_TWO_COPIES_ONLY')
    print('REAL_47_MONTHS_5294_DAYS: NOT_EVALUATED; FULL_DATE: NOT_RUN; PRODUCTION: UNCHANGED')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--standalone', action='store_true')
    options = parser.parse_args()
    selftest(with_original=not options.standalone)
