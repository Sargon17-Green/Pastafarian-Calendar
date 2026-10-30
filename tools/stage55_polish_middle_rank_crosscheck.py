#!/usr/bin/env python3
"""Separate Python exact-integer crosscheck for the saved Stage55 day-3 cursor.

This uses a streaming first-position insertion recurrence and a brute-force
small-family reference. It is independent code/runtime, not the normative
oracle or a verification of the complete 4,244-symbol calendar word.
Run: python3 tools/stage55_polish_middle_rank_crosscheck.py AFTER_3.json
(or supply the original GitHub Actions ZIP).
"""
import sys
import json
import zipfile
import time
import hashlib
import pathlib

sys.set_int_max_str_digits(0)
YEAR_L = [115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
          97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
          97,50,122,110,81,54,101,83,88,40,25,77,98,122,105]
CHECKPOINT_SHA256 = "ace93f07ba132027edb6c2eb750b1c6e509efb2ead7839b560c94139f4f96504"

def suffix_count(R, opened, closed):
    """Count legal suffixes using exact integer insertion by first position.

    The newest month's last appearance must end its insertion.
    F_i(p) is the count with that month's first appearance at p.
    """
    assert all(x == 0 for x in R[:closed])
    assert all(x > 0 for x in R[closed:])
    assert 0 <= closed <= opened <= len(R)
    r = R[closed:]
    if not r:
        return 1
    n = r[0]
    f = [0] * (n + 1)
    f[1] = 1
    total = 1
    for j, m in enumerate(r[1:], start=2):
        nnew = n + m
        needs_first_order = (closed + j > opened + 1)
        pref = []
        if needs_first_order:
            p_sum = 0
            for x in f:
                p_sum += x
                pref.append(p_sum)
        fnew = [0] * (nnew + 1)
        if m == 1:
            fnew[nnew] = total
        else:
            choose = 1
            for p in range(n + 1, 0, -1):
                eligible = pref[p - 1] if needs_first_order else total
                fnew[p] = choose * eligible
                if p > 1:
                    numer = choose * (nnew - p)
                    denom = n - p + 2
                    assert numer % denom == 0
                    choose = numer // denom
        f = fnew
        n = nnew
        total = sum(f)
    return total

def allowed(state, opened, closed, i):
    return (state[i-1] > 0 and i <= opened + 1 and
            (state[i-1] != 1 or i == closed + 1))

def advance(state, L, opened, closed, i):
    j = i - 1
    n = state[j]
    next_state = state.copy()
    next_state[j] -= 1
    return next_state, opened + (n == L[j]), closed + (n == 1)

def enumerate_small(L):
    words = []
    def walk(state, o, c, prefix):
        if sum(state) == 0:
            words.append(tuple(prefix))
            return
        for i in range(1, len(L) + 1):
            if allowed(state, o, c, i):
                ns, no, nc = advance(state, L, o, c, i)
                walk(ns, no, nc, prefix + [i])
    walk(L.copy(), 0, 0, [])
    return words

def interval(L, prefix):
    state = L.copy()
    opened = closed = 0
    lo = 1
    for selected in prefix:
        assert allowed(state, opened, closed, selected)
        for i in range(1, selected):
            if allowed(state, opened, closed, i):
                r, o, c = advance(state, L, opened, closed, i)
                lo += suffix_count(r, o, c)
        state, opened, closed = advance(state, L, opened, closed, selected)
    count = suffix_count(state, opened, closed)
    return lo, lo + count - 1, count, state, opened, closed

def main(artifact):
    fixtures = [[1],[2],[1,1],[1,2],[2,1],[2,2],[1,1,1],
                [1,2,1],[2,1,2],[2,2,2],[2,3,2],[3,2,3],
                [1,1,1,1],[2,1,1,2]]
    small_words = prefix_cases = 0
    for L in fixtures:
        words = enumerate_small(L)
        assert words == sorted(set(words))
        assert suffix_count(L.copy(), 0, 0) == len(words)
        small_words += len(words)
        for p in sorted(set(w[:min(len(w), 3)] for w in words)):
            lo, hi, count, *_ = interval(L, list(p))
            expected = [i+1 for i, w in enumerate(words)
                        if w[:len(p)] == p]
            assert (lo, hi, count) == (min(expected), max(expected),
                                       len(expected)), (L, p)
            prefix_cases += 1
    print("PYTHON_INDEPENDENT_SMALL_ENUMERATION_PASS",
          "FAMILIES", len(fixtures), "WORDS", small_words,
          "PREFIXES", prefix_cases, flush=True)

    source = pathlib.Path(artifact)
    if source.suffix.lower() == ".zip":
        with zipfile.ZipFile(source) as z:
            checkpoint_bytes = z.read("STAGE55_REAL_YEAR_INNER_CURSOR_AFTER_3.json")
    else:
        checkpoint_bytes = source.read_bytes()
    digest = hashlib.sha256(checkpoint_bytes).hexdigest()
    assert digest == CHECKPOINT_SHA256, "Evidence checkpoint digest mismatch"
    ck = json.loads(checkpoint_bytes)
    assert ck["originalLengths"] == YEAR_L
    assert ck["openedUpTo"] == 3 and ck["closedUpTo"] == 0
    assert ck["remaining"][:3] == [114,107,118]

    start = time.perf_counter()
    full = suffix_count(YEAR_L.copy(), 0, 0)
    lo, hi, count, R, o, c = interval(YEAR_L, [1,2,3])
    assert R == ck["remaining"] and o == 3 and c == 0
    assert int(ck["countDecimal"]) == count
    middle = full // 2 + 1
    assert lo <= middle <= hi
    assert int(ck["rankDecimal"]) == middle - lo + 1
    assert len(str(full)) == len(str(count)) == 6765
    print("PYTHON_INDEPENDENT_REAL_YEAR_PREFIX_PASS",
          "YEAR", 5000, "MONTHS", 45, "DAYS", 4244,
          "PREFIX", [1,2,3], "COUNT_DIGITS", len(str(count)),
          "MID_INSIDE_INTERVAL", True, "CHECKPOINT_SHA256", digest,
          "SECONDS", round(time.perf_counter()-start, 3), flush=True)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python3 tools/stage55_polish_middle_rank_crosscheck.py AFTER_3.json|artifact.zip")
    main(sys.argv[1])
