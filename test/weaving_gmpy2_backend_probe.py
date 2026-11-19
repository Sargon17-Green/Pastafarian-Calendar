#!/usr/bin/env python3
"""Bounded research probe: keep the sparse DP but move its integer backend to GMP.

This is not a production change or a full 4244-symbol rank/unrank acceptance.
Correctness is checked against signed differential cases and an independent
finite occurrence-poset oracle. Performance is a paired five-month diagnostic.
"""
import hashlib
import resource
import statistics
import sys
import time
from functools import lru_cache
from itertools import accumulate, chain, islice, product, repeat
from operator import mul
from pathlib import Path

import gmpy2
from gmpy2 import mpz

sys.path.insert(0, str(Path(__file__).resolve().parent))
import weaving_sparse_dual as dual
from weaving_reachability_oracle import MONTH_LENGTHS
from weaving_small_exact_oracle import brute_words, poset_oracle

PY_TRANSFER = dual.sparse_transfer


@lru_cache(maxsize=96)
def gmp_coefficients(n, k):
    return tuple(mpz(value) for value in dual.free_gap_coefficients(n, k))


def gmp_transfer(previous, n, k, spec):
    q, fixed_sum, first_fixed, tail = spec
    if fixed_sum or tail:
        return PY_TRANSFER(previous, n, k, spec)
    if q > n:
        return dual.SparseVector(0, ())
    first = max(0, q)
    width = n - first
    begin, stop = first + 1, n + 1
    overlap_begin = max(begin, previous.offset)
    overlap_stop = min(stop, previous.offset + len(previous.values))
    if overlap_begin < overlap_stop:
        updates = chain(
            repeat(0, overlap_begin - begin),
            islice(previous.values,
                   overlap_begin - previous.offset,
                   overlap_stop - previous.offset),
            repeat(0, stop - overlap_stop))
    else:
        updates = repeat(0, width)
    coefficients = gmp_coefficients(n, k)
    prefixes = accumulate(updates, initial=mpz(previous.prefix(first)))
    out = list(map(mul, prefixes, reversed(coefficients[:width + 1])))
    left = 0
    while left < len(out) and out[left] == 0:
        left += 1
    if left == len(out):
        return dual.SparseVector(0, ())
    right = len(out)
    while right > left and out[right - 1] == 0:
        right -= 1
    return dual.SparseVector(first + 1 + left, tuple(out[left:right]))


def test_signed_differential():
    checks = 0
    for n in (0, 1, 4, 17, 64, 127):
        vectors = (
            dual.SparseVector(
                0, tuple((1 if i % 2 == 0 else -1) * (i + 1)
                         for i in range(n + 1))),
            dual.SparseVector(
                n // 3,
                tuple((1 if i % 2 == 0 else -1) * (i + 3)**3
                      for i in range(max(1, n // 2)))),
            dual.SparseVector(n // 2, (5, -5, 7, -7, 0)),
            dual.SparseVector(n + 3, ()),
        )
        for k in (1, 2, 7, 125):
            for q in (-1, 0, 1, n // 2, n, n + 1):
                spec = (q, 0, -1, 0)
                for previous in vectors:
                    expected = dual._reference_free_gap_transfer(
                        previous, n, k, spec)
                    assert gmp_transfer(previous, n, k, spec) == expected
                    checks += 1
    assert checks == 576
    print("WEAVING_GMPY2_SIGNED_CHECKS=" + str(checks))
    print("WEAVING_GMPY2_SIGNED_DIFFERENTIAL=PASS")


def test_finite_oracle():
    cases = [p for m in range(1, 5)
             for p in product(range(1, 5), repeat=m) if sum(p) <= 8]
    cases += [
        (2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
        (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
        (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    roundtrips = partitions = 0
    saved = dual.sparse_transfer
    dual.sparse_transfer = gmp_transfer
    try:
        for lengths in cases:
            accepted = brute_words(lengths)
            count, oracle_rank, oracle_unrank, _ = poset_oracle(lengths)
            assert int(dual.SparseDualWeaving(lengths).total) == count == len(accepted)
            for rank, word in enumerate(accepted):
                assert tuple(dual.dual_unrank(lengths, rank)) == oracle_unrank(rank) == word
                assert int(dual.dual_rank(lengths, word)) == oracle_rank(word) == rank
                roundtrips += 2
                state = dual.SparseDualWeaving(lengths)
                for symbol in word:
                    assert int(sum(state.blocks())) == int(state.total)
                    state.take(symbol)
                    partitions += 1
    finally:
        dual.sparse_transfer = saved
    assert len(cases) == 137
    assert roundtrips == 1982
    assert partitions == 8361
    print("WEAVING_GMPY2_FINITE_CASES=" + str(len(cases)))
    print("WEAVING_GMPY2_FINITE_RANK_ROUNDTRIPS=" + str(roundtrips))
    print("WEAVING_GMPY2_FINITE_PARTITIONS=" + str(partitions))
    print("WEAVING_GMPY2_FINITE_ORACLE=PASS")


def build_median_prefix(transfer):
    saved = dual.sparse_transfer
    dual.sparse_transfer = transfer
    started = time.perf_counter()
    try:
        state = dual.SparseDualWeaving(MONTH_LENGTHS)
        root = int(state.total)
        assert root.bit_length() == 22470
        digest = hashlib.sha256(
            root.to_bytes((root.bit_length() + 7) // 8, "big")
        ).hexdigest()
        assert digest == "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
        residual = state.total // 2
        prefix = []
        for _ in range(6):
            blocks = state.blocks()
            for symbol in range(1, 46):
                if residual >= blocks[symbol]:
                    residual -= blocks[symbol]
                else:
                    state.take(symbol)
                    prefix.append(symbol)
                    break
            else:
                raise AssertionError("no legal median-prefix transition")
        assert tuple(prefix) == (1, 2, 3, 4, 5, 6)
        return state, root, tuple(prefix), time.perf_counter() - started
    finally:
        dual.sparse_transfer = saved


def test_paired_hotset():
    python_state, python_root, python_prefix, python_build = build_median_prefix(PY_TRANSFER)
    gmp_state, gmp_root, gmp_prefix, gmp_build = build_median_prefix(gmp_transfer)
    assert python_root == gmp_root
    assert python_prefix == gmp_prefix == (1, 2, 3, 4, 5, 6)
    assert int(python_state.total) == int(gmp_state.total)
    print("WEAVING_GMPY2_ROOT_SHA256=PASS")
    print("WEAVING_GMPY2_MEDIAN_PREFIX=1,2,3,4,5,6")
    print("WEAVING_GMPY2_PYTHON_BUILD_SECONDS=" + format(python_build, ".6f"))
    print("WEAVING_GMPY2_GMP_BUILD_SECONDS=" + format(gmp_build, ".6f"))
    print("WEAVING_GMPY2_RSS_KIB=" + str(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss))

    months = (39, 42, 43, 44, 45)
    checks = 0
    sum_python = sum_gmp = 0.0
    for month in months:
        previous_python = python_state.states[month - 1]
        previous_gmp = gmp_state.states[month - 1]
        n = python_state.sizes[month - 1]
        k = python_state.lengths[month - 1]
        spec = python_state.specs[month]
        assert n == gmp_state.sizes[month - 1]
        assert spec == gmp_state.specs[month]
        assert spec[1] == 0 and spec[3] == 0 and spec[0] <= n
        assert tuple(int(x) for x in previous_gmp.values) == previous_python.values
        expected = PY_TRANSFER(previous_python, n, k, spec)
        assert gmp_transfer(previous_gmp, n, k, spec) == expected
        checks += 1
        samples = {"python": [], "gmp": []}
        for _ in range(3):
            for method in ("python", "gmp", "gmp", "python"):
                started = time.perf_counter()
                observed = (PY_TRANSFER(previous_python, n, k, spec)
                            if method == "python"
                            else gmp_transfer(previous_gmp, n, k, spec))
                samples[method].append(time.perf_counter() - started)
                assert observed == expected
                checks += 1
        python_time = statistics.median(samples["python"])
        gmp_time = statistics.median(samples["gmp"])
        assert python_time > 0 and gmp_time > 0
        sum_python += python_time
        sum_gmp += gmp_time
        print("WEAVING_GMPY2_MONTH_" + str(month) + "_PYTHON_SECONDS=" + format(python_time, ".6f"))
        print("WEAVING_GMPY2_MONTH_" + str(month) + "_GMP_SECONDS=" + format(gmp_time, ".6f"))
        print("WEAVING_GMPY2_MONTH_" + str(month) + "_RATIO_GMP_OVER_PYTHON=" + format(gmp_time / python_time, ".4f"))
    assert checks == 65
    print("WEAVING_GMPY2_HOTSET_MONTHS=39,42,43,44,45")
    print("WEAVING_GMPY2_HOTSET_CHECKS=" + str(checks))
    print("WEAVING_GMPY2_HOTSET_PYTHON_SECONDS=" + format(sum_python, ".6f"))
    print("WEAVING_GMPY2_HOTSET_GMP_SECONDS=" + format(sum_gmp, ".6f"))
    print("WEAVING_GMPY2_HOTSET_RATIO_GMP_OVER_PYTHON=" + format(sum_gmp / sum_python, ".4f"))
    print("WEAVING_GMPY2_HOTSET_EQUALITY=PASS")
    print("WEAVING_GMPY2_PERFORMANCE_ACCEPTANCE=NOT_TESTED")



def test_bounded_extended_median_prefix():
    """Research only: exact GMP rank-prefix steps, bounded by wall time and RSS.

    This deliberately cannot certify full 4244-day rank or reverse-rank.
    A separate process isolates peak RSS from the preceding comparison runs.
    """
    import signal

    assert sys.platform.startswith("linux"), "Linux CI is required for RSS KiB and SIGALRM"
    target, seconds_limit, rss_limit_kib = 96, 110.0, 512 * 1024
    reference_depths = (6, 16, 32, 64, 96)
    expected_root = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
    completed = []
    reference_checks = 0
    outcome = "UNSET"
    remaining = 0
    began = time.monotonic()
    saved_transfer = dual.sparse_transfer
    saved_handler = signal.getsignal(signal.SIGALRM)

    def alarm_handler(_signum, _frame):
        raise TimeoutError("bounded GMP median-prefix wall clock expired")

    print("WEAVING_GMPY2_EXTENDED_TARGET=" + str(target), flush=True)
    print("WEAVING_GMPY2_EXTENDED_LIMIT_SECONDS=" + str(seconds_limit), flush=True)
    print("WEAVING_GMPY2_EXTENDED_RSS_LIMIT_KIB=" + str(rss_limit_kib), flush=True)
    signal.signal(signal.SIGALRM, alarm_handler)
    signal.setitimer(signal.ITIMER_REAL, seconds_limit)
    try:
        dual.sparse_transfer = gmp_transfer
        state = dual.SparseDualWeaving(MONTH_LENGTHS)
        root = int(state.total)
        assert root.bit_length() == 22470
        assert hashlib.sha256(root.to_bytes((root.bit_length() + 7) // 8, "big")).hexdigest() == expected_root
        remaining = root // 2
        for _ in range(target):
            assert 0 <= remaining < state.total
            blocks = state.blocks()
            assert sum(blocks) == state.total
            choice = None
            for symbol in range(1, len(MONTH_LENGTHS) + 1):
                if remaining >= blocks[symbol]:
                    remaining -= blocks[symbol]
                else:
                    choice = symbol
                    break
            assert choice is not None, "no legal median-prefix choice"
            state.take(choice)
            completed.append(choice)
            assert 0 <= remaining < state.total
            if len(completed) == 6:
                assert tuple(completed) == (1, 2, 3, 4, 5, 6)
            if len(completed) in reference_depths:
                # Separate dense insertion recurrence, not GMP sparse state.
                independent = dual.count_prefix(MONTH_LENGTHS, tuple(completed))
                assert independent == int(state.total), "independent prefix-count mismatch"
                reference_checks += 1
                print("WEAVING_GMPY2_EXTENDED_CHECKPOINT=" + str(len(completed)) +
                      ":DENSE_REFERENCE_EQUAL", flush=True)
            rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
            if rss > rss_limit_kib:
                outcome = "INCONCLUSIVE_RSS_BUDGET"
                break
        else:
            outcome = "PREFIX_TARGET_REACHED_ONLY"
    except TimeoutError:
        outcome = "INCONCLUSIVE_TIME_BUDGET"
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, saved_handler)
        dual.sparse_transfer = saved_transfer
    # Six previously verified positions plus independent dense confirmation are
    # minimum QA gates. A shorter run is a regression, not a successful probe.
    assert len(completed) >= 6 and reference_checks >= 1, (
        "extended prefix failed minimum 6-symbol/independent-reference gate",
        len(completed), reference_checks, outcome)
    prefix_bytes = ",".join(map(str, completed)).encode("ascii")
    print("WEAVING_GMPY2_EXTENDED_RESULT=" + outcome)
    print("WEAVING_GMPY2_EXTENDED_SYMBOLS=" + str(len(completed)))
    print("WEAVING_GMPY2_EXTENDED_REFERENCE_CHECKS=" + str(reference_checks))
    print("WEAVING_GMPY2_EXTENDED_PREFIX_SHA256=" + hashlib.sha256(prefix_bytes).hexdigest())
    print("WEAVING_GMPY2_EXTENDED_REMAINING_BITS=" + str(int(remaining).bit_length()))
    print("WEAVING_GMPY2_EXTENDED_SECONDS=" + format(time.monotonic() - began, ".6f"))
    print("WEAVING_GMPY2_EXTENDED_RSS_KIB=" +
          str(resource.getrusage(resource.RUSAGE_SELF).ru_maxrss))
    print("WEAVING_GMPY2_EXTENDED_FULL_4244_RANK_UNRANK=NOT_TESTED")
    print("WEAVING_GMPY2_EXTENDED_PRODUCTION_CHANGE=NONE")


if __name__ == "__main__":
    import subprocess

    if sys.argv[1:] == ["--extended-prefix"]:
        test_bounded_extended_median_prefix()
    elif len(sys.argv) == 1:
        print("WEAVING_GMPY2_VERSION=" + gmpy2.version())
        test_signed_differential()
        test_finite_oracle()
        test_paired_hotset()
        print("WEAVING_GMPY2_FULL_4244_RANK_UNRANK=NOT_TESTED")
        print("WEAVING_GMPY2_PRODUCTION_CHANGE=NONE")
        # Process isolation keeps the expanded prefix peak RSS attributable.
        # The child has an internal 110s alarm and an external 125s hard cap.
        subprocess.run([sys.executable, "-u", str(Path(__file__).resolve()),
                        "--extended-prefix"], check=True, timeout=125)
    else:
        raise SystemExit("unexpected probe arguments")
