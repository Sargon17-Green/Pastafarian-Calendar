#!/usr/bin/env python3
"""Independent, linear-time FIFO first/last-occurrence witness audit.

Research QA only. Does not import Chapel, sparse transfer, or GMP and does not
establish Stage 6 acceptance. This verifies membership, not lexical rank.
"""
from itertools import permutations, product


def verify_fifo_word(lengths, word):
    """Reject words unless first and last occurrences each follow month order.

    This is a streaming occurrence-order checker, independent from the
    transfer/counting and rank/unrank algorithms.
    """
    if not lengths or any(type(n) is not int or n < 1 for n in lengths):
        raise ValueError("positive integer month lengths required")
    if len(word) != sum(lengths):
        raise ValueError("word length mismatch")
    left = list(lengths)
    opened = closed = 0
    for symbol in word:
        if type(symbol) is not int or not 1 <= symbol <= len(left):
            raise ValueError("invalid month identifier")
        index = symbol - 1
        if left[index] == 0:
            raise ValueError("month multiplicity exceeded")
        if left[index] == lengths[index]:
            if symbol != opened + 1:
                raise ValueError("first occurrences not ordered")
            opened += 1
        if left[index] == 1:
            if symbol != closed + 1:
                raise ValueError("last occurrences not ordered")
            closed += 1
        left[index] -= 1
    if any(left) or opened != len(lengths) or closed != len(lengths):
        raise ValueError("incomplete occurrence order")
    return len(word)


def test_small_exhaustive():
    # Independent positional oracle enumerates all multiset permutations and
    # compares their first/last occurrence indices, not DP transition counts.
    families = [p for m in range(1, 5)
                for p in product(range(1, 4), repeat=m) if sum(p) <= 8]
    families.append((2, 2, 2, 2))
    families = tuple(dict.fromkeys(families))
    cases = accepted = rejected = 0
    for lengths in families:
        word_base = tuple(i + 1 for i, n in enumerate(lengths) for _ in range(n))
        for word in set(permutations(word_base)):
            first = [word.index(i) for i in range(1, len(lengths) + 1)]
            last = [len(word) - 1 - word[::-1].index(i)
                    for i in range(1, len(lengths) + 1)]
            expected = first == sorted(first) and last == sorted(last)
            try:
                observed = verify_fifo_word(lengths, word) == len(word)
            except ValueError:
                observed = False
            assert observed == expected, (lengths, word, observed, expected)
            accepted += observed
            rejected += not observed
            cases += 1
    # Explicit shape/type/adversarial guards.
    invalid = [((2, 2), (1, 2, 1)),
               ((2, 2), (1, 1, 2, 0)),
               ((2, 2), (1, 1, 2, 3)),
               ((2, 2), (1, 1, 1, 2)),
               ((2, 2), (2, 1, 1, 2)),
               ((2, 2), (1, 2, 2, 1)),
               ((2, 2), (True, 1, 2, 2))]
    for lengths, word in invalid:
        try:
            verify_fifo_word(lengths, word)
        except ValueError:
            pass
        else:
            raise AssertionError((lengths, word, "invalid accepted"))
    assert verify_fifo_word((2, 2), (1, 2, 1, 2)) == 4
    print("WEAVING_FIFO_ORACLE_FAMILIES=" + str(len(families)))
    print("WEAVING_FIFO_ORACLE_PERMUTATIONS=" + str(cases))
    print("WEAVING_FIFO_ORACLE_ACCEPTED=" + str(accepted))
    print("WEAVING_FIFO_ORACLE_REJECTED=" + str(rejected))
    print("WEAVING_FIFO_ORACLE_ADVERSARIAL=" + str(len(invalid)))
    print("WEAVING_FIFO_ORACLE_RESULT=PASS")


if __name__ == "__main__":
    test_small_exhaustive()
