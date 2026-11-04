#!/usr/bin/env python3
"""DISCOVERY03: bounded exact kernel differential, separate from rank oracle.

Compare sparse forward transfer against the existing independent dense transfer,
and sparse transpose against a directly evaluated matrix transpose. Adjoint test
vectors deliberately include negative values to test linearity, not just counting.
No Chapel production modification or Stage 6 acceptance is implied.
"""
from itertools import product
from time import monotonic
from resource import getrusage, RUSAGE_SELF

from weaving_prefix_batch import specs_for_prefix, transfer as dense_transfer, extend_spec
from weaving_prefix_transfer import weight
from weaving_small_exact_oracle import brute_words
from weaving_sparse_dual import SparseVector, sparse_transfer, sparse_transpose


def expand_sparse(vec, last):
    result = [0] * (last + 1)
    for ix, value in enumerate(vec.values):
        pos = vec.offset + ix
        assert 0 <= pos <= last
        result[pos] = value
    return result


def direct_transpose(after, n, k, spec):
    """Evaluate (T^t a)[p] by the defining matrix sum, not a recurrence."""
    if spec[0] > n:
        return [0] * (n + 1)
    weighted = [after[i+1] * weight(i, n, k, *spec)
                for i in range(n + 1)]
    result = []
    for p in range(n + 1):
        result.append(sum(weighted[p:]))
    return result


def main():
    cases = [p for m in range(1, 5)
             for p in product(range(1, 5), repeat=m) if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2),
              (3, 2, 3, 2), (2, 2, 3, 3),
              (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    started = monotonic()
    prefixes = transfers = transpose_checks = 0
    for lengths in cases:
        words = brute_words(lengths)
        for word in dict.fromkeys((words[0], words[len(words)//2], words[-1])):
            for position in range(len(word)):
                prefix = word[:position]
                specs = specs_for_prefix(lengths, prefix)
                n = lengths[0]
                before = [0] * (n + 1)
                before[1] = 1
                sparse_before = SparseVector(1, (1,))
                for j in range(2, len(lengths) + 1):
                    k, spec = lengths[j-1], specs[j]
                    after = dense_transfer(before, n, k, spec)
                    sparse_after = sparse_transfer(sparse_before, n, k, spec)
                    assert expand_sparse(sparse_after, n+k) == after, (
                        "forward", lengths, prefix, j)
                    transfers += 1
                    # Distinct signed vectors expose bugs hidden by all-ones vectors.
                    vector = [(17*t + 7*j + 3*position) % 29 - 14
                              for t in range(n+k+1)]
                    for probe in (spec, extend_spec(spec, j, 1)):
                        reverse = sparse_transpose(vector, n, k, probe)
                        exact = direct_transpose(vector, n, k, probe)
                        assert reverse == exact, (
                            "transpose", lengths, prefix, j, probe)
                        transpose_checks += 1
                    assert sum(after[i+1] * vector[i+1]
                               for i in range(n+k)) == sum(
                        before[p] * direct_transpose(vector, n, k, spec)[p]
                        for p in range(n+1)), ("adjoint", lengths, prefix, j)
                    sparse_before, before, n = sparse_after, after, n+k
                prefixes += 1
    elapsed = monotonic() - started
    rss = getrusage(RUSAGE_SELF).ru_maxrss
    assert len(cases) == 137 and prefixes == 1988
    assert transfers == 4901 and transpose_checks == 9802
    assert elapsed < 25.0 and rss < 512*1024, (elapsed, rss)
    print("WEAVING_SPARSE_KERNEL_CASES=137")
    print("WEAVING_SPARSE_KERNEL_PREFIXES=1988")
    print("WEAVING_SPARSE_KERNEL_FORWARD_CHECKS=4901")
    print("WEAVING_SPARSE_KERNEL_TRANSPOSE_CHECKS=9802")
    print("WEAVING_SPARSE_KERNEL_SECONDS=" + format(elapsed, ".3f"))
    print("WEAVING_SPARSE_KERNEL_RSS_KIB=" + str(rss))
    print("WEAVING_SPARSE_KERNEL_RESULT=PASS")


if __name__ == "__main__":
    main()
