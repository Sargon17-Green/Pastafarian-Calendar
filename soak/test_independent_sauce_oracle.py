"""Bounded independent structural sauce checks; pinned-source differential in CI."""
import os
import sys
import time
import unittest
import subprocess
import importlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_sauce_oracle import (
    FOUNDATION, MODULUS, _order_from_rank, _save, evaluate,
    gap_from_witness, SauceOracleError,
)


class SauceOracleTests(unittest.TestCase):
    def test_ring_arithmetic_boundary(self):
        self.assertEqual([_save(n) for n in (-MODULUS, 0, 1, MODULUS, MODULUS+1)],
                         [MODULUS, MODULUS, 1, MODULUS, 1])

    def test_permutation_exhaustion(self):
        perms = {_order_from_rank(k) for k in range(1, 721)}
        self.assertEqual(len(perms), 720)
        self.assertEqual(_order_from_rank(1), (1, 2, 3, 4, 5, 6))
        self.assertEqual(_order_from_rank(720), (6, 5, 4, 3, 2, 1))
        self.assertEqual(_order_from_rank(721), (1, 2, 3, 4, 5, 6))

    def test_boundary_witness_invariants(self):
        for a, b in [(FOUNDATION, FOUNDATION), (FOUNDATION-1, FOUNDATION),
                     (FOUNDATION+1, FOUNDATION), (FOUNDATION, FOUNDATION-1),
                     (FOUNDATION, FOUNDATION+1), (0, 0), (-1, 1)]:
            w = evaluate(a, b)
            self.assertEqual(len(w.bowls), 7)
            self.assertEqual(set(w.order_at_drop_46), set(range(1, 7)))
            self.assertTrue(all(1 <= x <= MODULUS for x in w.bowls[1:]))
            self.assertTrue(all(1 <= x <= MODULUS for x in w.hidden_by_nearness))
            self.assertTrue(w.independent_sauce)
            self.assertFalse(w.certified)

    def test_determinism_and_distinct_inputs(self):
        a = evaluate(FOUNDATION, FOUNDATION+1)
        b = evaluate(FOUNDATION, FOUNDATION+1)
        c = evaluate(FOUNDATION, FOUNDATION+2)
        self.assertEqual(a, b)
        self.assertNotEqual(a, c)

    def test_gap_bounds(self):
        for delta in (-3, -1, 0, 1, 2, 41):
            gap = gap_from_witness(evaluate(FOUNDATION, FOUNDATION + delta))
            self.assertTrue(42 <= gap <= 963)

    def test_bad_input_and_deadline(self):
        for bad in (True, 0.0, '1'):
            with self.assertRaisesRegex(SauceOracleError, 'E_SAUCE_INPUT'):
                evaluate(bad, 1)
        with self.assertRaisesRegex(SauceOracleError, 'E_SAUCE_DEADLINE'):
            evaluate(FOUNDATION, FOUNDATION+1, deadline=time.monotonic()-1)


class PinnedSourceDifferential(unittest.TestCase):
    """Requires independently checked-out exact source SHA."""
    def test_all_stages_against_pinned_source(self):
        source = os.environ.get('PASTAFARIAN_PYTHON_SRC')
        if not source:
            self.skipTest('No separate pinned source checkout: structural tests only')
        source = Path(source).resolve()
        sha = subprocess.check_output(['git', '-C', str(source.parent), 'rev-parse', 'HEAD'],
                                      text=True, timeout=10).strip()
        self.assertEqual(sha, '7cb12bf355461e5a179e0deadb7365689288bf29')
        self.assertTrue((source/'pastafari_calendar'/'final_integration.py').is_file())
        sys.path.insert(0, str(source))
        fi = importlib.import_module('pastafari_calendar.final_integration')
        self.assertTrue(Path(fi.__file__).resolve().is_relative_to(source))
        from pastafari_calendar.monster_bootstrap import MonsterContext
        from pastafari_calendar.legacy_day_counts import LegacyDayTagAdapter
        from pastafari_calendar.legacy_distance import LegacyDistanceAdapter
        from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
        from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
        from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter

        for d in (-3, -2, -1, 0, 1, 2, 3, 42, 963):
            action, target = FOUNDATION, FOUNDATION + d
            oracle = evaluate(action, target, deadline=time.monotonic()+20)
            real = fi.sauceWithScars(action, target)
            self.assertEqual(oracle.bowls, real.bowls, f'final bowls at {d}')
            self.assertEqual(oracle.order_at_drop_46, real.order_at_drop_46, f'latch at {d}')
            ctx = MonsterContext(calculation_day=action, target_day=target)
            LegacyDayTagAdapter().call(ctx, action, 'action')
            LegacyDayTagAdapter().call(ctx, target, 'target')
            LegacyDistanceAdapter().call(ctx, action, target)
            stones = LegacyStoneBuilderAdapter().call(ctx)
            self.assertEqual(oracle.stone_46, stones[46], f'stones at {d}')
            LegacyHiddenDropAdapter().call(ctx)
            self.assertEqual(oracle.hidden_by_nearness,
                             tuple(ctx.legacy_hidden_storage[8-k] for k in range(1, 8)),
                             f'hidden at {d}')
            LegacyVisibleDropBuilderAdapter().call(ctx)
            self.assertEqual(oracle.visible_46, ctx.legacy_visible_drop_table[46],
                             f'visible at {d}')
            if d != 0:
                gate_ctx = MonsterContext(calculation_day=action, target_day=target)
                gate_ctx.acceleration_scars.enabled = False
                engine = fi.IntegratedGateCache(gate_ctx)
                self.assertEqual(gap_from_witness(oracle), engine._gap(d),
                                 f'full gap at {d}')


if __name__ == '__main__':
    unittest.main()
