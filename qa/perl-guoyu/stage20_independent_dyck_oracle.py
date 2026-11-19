#!/usr/bin/env python3
"""Standalone Stage20 mathematical oracle; does not import production code.

Enumerates complete balanced-parenthesis strings and maps opening and closing
indices to month symbols. This has no shared transition/memo code with Perl.
"""
import hashlib
import json
from math import comb


def oracle_words(pairs: int):
    if not isinstance(pairs, int) or pairs < 1:
        raise ValueError("pairs must be positive")
    parentheses = []

    def descend(opens: int, closes: int):
        if closes == pairs:
            opening_number = closing_number = 0
            labels = []
            for symbol in parentheses:
                if symbol == "(":
                    opening_number += 1
                    labels.append(opening_number)
                else:
                    closing_number += 1
                    labels.append(closing_number)
            yield tuple(labels)
            return
        if opens < pairs:
            parentheses.append("(")
            yield from descend(opens + 1, closes)
            parentheses.pop()
        if closes < opens:
            parentheses.append(")")
            yield from descend(opens, closes + 1)
            parentheses.pop()

    yield from descend(0, 0)


def verify(pairs=11):
    count = 0
    last = None
    first = middle = None
    digest = hashlib.sha256()
    expected = comb(2 * pairs, pairs) // (pairs + 1)
    # Parenthesis traversal order is NOT numerical month-label lexical order.
    # Materialize and sort oracle words before assigning ranks.
    words = sorted(oracle_words(pairs))
    for word in words:
        count += 1
        assert len(word) == 2 * pairs
        assert all(word.count(symbol) == 2 for symbol in range(1, pairs + 1))
        first_positions = [word.index(symbol) for symbol in range(1, pairs + 1)]
        last_positions = [len(word) - 1 - word[::-1].index(symbol) for symbol in range(1, pairs + 1)]
        assert first_positions == sorted(first_positions)
        assert last_positions == sorted(last_positions)
        if last is not None:
            assert last < word, "lexicographic order regression"
        if count == 1:
            first = word
        if count == (expected + 1) // 2:
            middle = word
        digest.update((",".join(str(v) for v in word) + "\n").encode("ascii"))
        last = word
    assert count == expected
    return {"project_id":"PC-BRANCH-PERL-GUOYU", "stage":20,
            "oracle":"independent_parentheses_enumeration", "pairs":pairs,
            "word_length":2*pairs, "count":count,
            "catalan_formula":f"binomial({2*pairs},{pairs})/({pairs}+1)",
            "sha256_sorted_csv_lines":digest.hexdigest(),
            "first_word":first,"middle_word":middle,"last_word":last,
            "native_production_validation":False}


if __name__ == "__main__":
    print(json.dumps(verify(),ensure_ascii=False,indent=2))
