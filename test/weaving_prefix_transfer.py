#!/usr/bin/env python3
"""Exact 1D insertion transfer for first/last-ordered month weaving.

Research-only: no Chapel or production modules imported.
The independent occurrence-poset oracle is used only for differential tests.
"""
from itertools import product
from math import comb


def weight(i, n, k, q, fixed_sum, first_fixed, tail):
    """Ways to insert k equal letters in n+1 gaps; first gap i, last gap n."""
    if i < q:
        if first_fixed != i:
            return 0
    elif fixed_sum or (i > q and tail):
        return 0
    start = max(i, q)
    gap_count = n - start + 1
    lower = {}
    if i >= q:
        lower[i] = 1
    if q >= i:
        lower[q] = max(lower.get(q, 0), tail)
    lower[n] = max(lower.get(n, 0), 1)
    slack = k - fixed_sum - sum(lower.values())
    if slack < 0:
        return 0
    return comb(slack + gap_count - 1, gap_count - 1)


def count_prefix(lengths, prefix=()):
    """Number of legal month words with the specified prefix (exact int)."""
    if not lengths or any(x <= 0 for x in lengths):
        raise ValueError("positive nonempty lengths required")
    if len(prefix) > sum(lengths) or any(
        not isinstance(x, int) or x < 1 or x > len(lengths) for x in prefix
    ):
        raise ValueError("invalid prefix")
    if any(prefix.count(i + 1) > length for i, length in enumerate(lengths)):
        return 0

    n = lengths[0]
    dp = [0] * (n + 1)
    dp[1] = 1
    for month, k in enumerate(lengths[1:], 2):
        # Project the fixed prefix onto letters <= month.
        # New letters in gaps preceding old-prefix tokens are fixed exactly.
        # The new-letter tail at gap q is only a lower bound.
        projected_gaps = [0]
        for symbol in prefix:
            if symbol > month:
                continue
            if symbol == month:
                projected_gaps[-1] += 1
            else:
                projected_gaps.append(0)
        fixed = projected_gaps[:-1]
        tail = projected_gaps[-1]
        q = len(fixed)
        fixed_sum = sum(fixed)
        first_fixed = next((j for j, x in enumerate(fixed) if x), -1)
        next_dp = [0] * (n + k + 1)
        summed = 0
        for i in range(n + 1):
            summed += dp[i]
            if summed:
                ways = weight(i, n, k, q, fixed_sum, first_fixed, tail)
                if ways:
                    next_dp[i + 1] = summed * ways
        dp, n = next_dp, n + k
    return sum(dp)


def rank_word(lengths, word):
    if len(word) != sum(lengths) or any(
        word.count(i + 1) != x for i, x in enumerate(lengths)
    ):
        raise ValueError("invalid word length or multiplicity")
    result = 0
    prefix = ()
    for symbol in word:
        for earlier in range(1, symbol):
            result += count_prefix(lengths, prefix + (earlier,))
        prefix += (symbol,)
        if count_prefix(lengths, prefix) == 0:
            raise ValueError("illegal first/last appearance order")
    return result


def unrank_word(lengths, rank0):
    total = count_prefix(lengths)
    if rank0 < 0 or rank0 >= total:
        raise ValueError("rank out of bounds")
    prefix = ()
    for _ in range(sum(lengths)):
        for symbol in range(1, len(lengths) + 1):
            block = count_prefix(lengths, prefix + (symbol,))
            if rank0 >= block:
                rank0 -= block
            else:
                prefix += (symbol,)
                break
        else:
            raise AssertionError("no legal continuation")
    assert rank0 == 0
    return prefix


def test_finite():
    import weaving_small_exact_oracle as independent

    cases = [p for m in range(1, 5)
             for p in product(range(1, 5), repeat=m) if sum(p) <= 8]
    cases.extend(((2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
                  (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
                  (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)))
    cases = list(dict.fromkeys(cases))
    prefix_checks = rank_checks = 0
    for lengths in cases:
        accepted = independent.brute_words(lengths)
        total, oracle_rank, oracle_unrank, _ = independent.poset_oracle(lengths)
        assert count_prefix(lengths) == total == len(accepted), lengths
        prefixes = {()}
        for word in accepted:
            for pos in range(len(word) + 1):
                prefixes.add(word[:pos])
        for prefix in prefixes:
            expected = sum(word[:len(prefix)] == prefix for word in accepted)
            assert count_prefix(lengths, prefix) == expected, (lengths, prefix)
            prefix_checks += 1
        for r, word in enumerate(accepted):
            assert rank_word(lengths, word) == oracle_rank(word) == r
            assert unrank_word(lengths, r) == oracle_unrank(r) == word
            rank_checks += 2
        if len(lengths) >= 2:
            assert count_prefix(lengths, (len(lengths),)) == 0
            prefix_checks += 1
        try:
            unrank_word(lengths, -1)
        except ValueError:
            pass
        else:
            raise AssertionError("negative rank accepted")
    assert len(cases) == 137 and rank_checks == 1982
    assert prefix_checks == 4983
    print("WEAVING_TRANSFER_CASES=137")
    print("WEAVING_TRANSFER_PREFIX_CHECKS=4983")
    print("WEAVING_TRANSFER_RANK_CHECKS=1982")
    print("WEAVING_TRANSFER_FINITE_RESULT=PASS")


def test_year5000_count():
    from hashlib import sha256
    from math import factorial, prod
    from time import monotonic
    from weaving_reachability_oracle import MONTH_LENGTHS

    lengths = MONTH_LENGTHS
    assert len(lengths) == 45 and sum(lengths) == 4244
    begin = monotonic()
    total = count_prefix(lengths)
    assert total == count_prefix(tuple(reversed(lengths)))
    assert total == count_prefix(lengths, (1,))
    assert total == count_prefix(lengths, (1, 1)) + count_prefix(lengths, (1, 2))
    multinomial = factorial(sum(lengths)) // prod(factorial(n) for n in lengths)
    assert 0 < total < multinomial
    assert total.bit_length() == 22470
    digest = sha256(total.to_bytes((total.bit_length() + 7) // 8, "big")).hexdigest()
    assert digest == "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
    print("WEAVING_TRANSFER_FULL_MONTHS=45")
    print("WEAVING_TRANSFER_FULL_DAYS=4244")
    print("WEAVING_TRANSFER_FULL_COUNT_BITS=22470")
    print("WEAVING_TRANSFER_FULL_SHA256_BE=" + digest)
    print("WEAVING_TRANSFER_FULL_SECONDS=" + format(monotonic() - begin, ".3f"))
    print("WEAVING_TRANSFER_FULL_COUNT_RESULT=PASS")
    # A whole-year rank/unrank performance claim is NOT made.


if __name__ == "__main__":
    test_finite()
    test_year5000_count()
