#!/usr/bin/env python3
"""Issue #29: finite, source-independent mathematical and telemetry checks.

No original or instrumented calendar converter is imported or executed.
Does not run F(c,t), fetch sources, or schedule native work.
"""
import ast
from itertools import combinations
from math import comb
from pathlib import Path
import sys
import unittest


def legal_sequences(a: int, b: int) -> tuple[tuple[int, ...], ...]:
    if a < 2 or b < 2:
        raise ValueError("months must have at least two occurrences")
    legal = []
    for p in combinations(range(a + b), a):
        slots = set(p)
        seq = tuple(1 if i in slots else 2 for i in range(a + b))
        if seq.index(1) < seq.index(2) and seq[::-1].index(1) > seq[::-1].index(2):
            legal.append(seq)
    return tuple(legal)


def rails(sequences: tuple[tuple[int, ...], ...]) -> tuple[tuple[int, ...], ...]:
    return tuple(x for x in sequences if x[:2] == (1, 2) and x[-2:] == (1, 2))


class Issue29StaticContract(unittest.TestCase):
    def test_four_day_minimal_counterexample(self):
        full = legal_sequences(2, 2)
        self.assertEqual(full, ((1, 1, 2, 2), (1, 2, 1, 2)))
        self.assertEqual(rails(full), ((1, 2, 1, 2),))

    def test_eight_day_general_versus_rails(self):
        full = legal_sequences(4, 4)
        limited = rails(full)
        self.assertEqual(len(full), 20)
        self.assertEqual(len(limited), 6)
        self.assertTrue(set(limited) < set(full))

    def test_nine_day_general_versus_rails(self):
        full = legal_sequences(4, 5)
        limited = rails(full)
        self.assertEqual(len(full), 35)
        self.assertEqual(len(limited), 10)
        self.assertTrue(set(limited) < set(full))

    def test_independent_closed_form_two_month_counts(self):
        for a, b in ((2, 2), (4, 4), (4, 5), (5, 7)):
            with self.subTest(lengths=(a, b)):
                legal = legal_sequences(a, b)
                self.assertEqual(len(legal), comb(a + b - 2, a - 1))
                self.assertEqual(len(rails(legal)), comb(a + b - 4, a - 2))

    def test_month_name_index_is_not_internal_id(self):
        # Independent finite non-injective witness, not a foundation-day claim.
        w1, n1, o1 = (1, 2, 1, 1, 2, 2), (20, 30), 3
        w2, n2, o2 = (1, 2, 2, 2, 1, 1), (30, 20), 3
        def project(w, n, o):
            identifier = w[o]
            return (n[identifier - 1], sum(x == identifier for x in w[:o + 1]))
        self.assertEqual(project(w1, n1, o1), (20, 3))
        self.assertEqual(project(w2, n2, o2), (20, 3))
        self.assertNotEqual(w1[o1], w2[o2])

    def test_lossless_hex_avoids_decimal_digit_limit(self):
        # This is a diagnostic telemetry test; never alters global limits.
        rank = 10**5000 + 8191
        hex_text = format(rank, "x")
        self.assertEqual(int(hex_text, 16), rank)
        self.assertGreater(len(hex_text), 4300 * 3 // 4)
        if hasattr(sys, "get_int_max_str_digits") and sys.get_int_max_str_digits() != 0:
            if sys.get_int_max_str_digits() < 5001:
                with self.assertRaises(ValueError):
                    str(rank)

    def test_instrumentation_uses_hex_and_reversible_blocks(self):
        runner = Path(__file__).resolve().parents[1] / "runner" / "issue29_foundation_capture_v160.py"
        source = runner.read_text(encoding="utf-8")
        ast.parse(source)
        self.assertIn('"family_count_hex": format(family.count(), "x")', source)
        self.assertIn('"global_rank_hex": format(rank, "x")', source)
        self.assertIn('strip_insertions(', source)
        self.assertIn('RUN_STARTED_ONCE', source)
        self.assertIn('MAX_OUTPUT_BYTES = 256 * 1024', source)
        self.assertIn('RUN_TIMEOUT_SECONDS = 30', source)


if __name__ == "__main__":
    unittest.main()
