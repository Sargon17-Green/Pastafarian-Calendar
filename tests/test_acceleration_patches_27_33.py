import gc
import json
import os
import random
import subprocess
import sys
import unittest

import pastafari_calendar.acceleration_scars as scars
import pastafari_calendar.calendar as calendar_module
from pastafari_calendar.acceleration_scars import (
    AccelerationScarContext,
    BuriedCalendarResult,
    GateShard,
    SelectionOracleKey,
    YearCheckpoint,
    acceleration_mode,
    cache_sizes,
    global_acceleration_metrics,
    lookup_final_result,
    reset_acceleration_scars_for_tests,
    semantic_fingerprint,
    set_test_fingerprint_salt,
    store_final_result,
)
from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.final_integration import (
    GATE_CHECKPOINTS_INTEGRATED,
    FinalSpaghettiIntegrationManager,
    IntegratedCutlet,
    IntegratedGateCache,
    IntegratedYear,
    IntegratedYearStructure,
    SpaghettiDateResult,
    _chooseIntegratedRank,
)
from pastafari_calendar.legacy_arithmetic import M_OLD
from pastafari_calendar.legacy_selection import (
    LegacyAnswerRing,
    answerAtRing,
    biasedLegacyPick,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG


FOUNDATION_DAY = -15055671


class AccelerationPatches2733Tests(unittest.TestCase):
    def setUp(self):
        reset_acceleration_scars_for_tests()
        set_test_fingerprint_salt("")

    def tearDown(self):
        set_test_fingerprint_salt("")
        reset_acceleration_scars_for_tests()

    def test_00_seeded_differential_cold_and_warm_full_result(self):
        rng = random.Random(2733)
        offsets = [0, 1000, rng.choice(range(-700, -1))]
        repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        src_root = os.path.join(repo_root, "src")

        child = r"""
import gc
import json
import sys
from pastafari_calendar.acceleration_scars import acceleration_mode, reset_acceleration_scars_for_tests
from pastafari_calendar.calendar import calendar_date_spaghetti

FOUNDATION_DAY = -15055671
offsets = json.loads(sys.argv[1])

def freeze(result):
    return [
        result.year_number,
        result.cutlet_name,
        result.day_in_cutlet,
        result.month_name,
        result.day_in_month,
    ]

rows = []
for offset in offsets:
    reset_acceleration_scars_for_tests()
    gc.collect()
    with acceleration_mode(False):
        slow = calendar_date_spaghetti(FOUNDATION_DAY, FOUNDATION_DAY + offset)

    reset_acceleration_scars_for_tests()
    gc.collect()
    with acceleration_mode(True):
        fast_cold = calendar_date_spaghetti(FOUNDATION_DAY, FOUNDATION_DAY + offset)
        fast_warm = calendar_date_spaghetti(FOUNDATION_DAY, FOUNDATION_DAY + offset)

    rows.append({
        "offset": offset,
        "slow": freeze(slow),
        "cold": freeze(fast_cold),
        "warm": freeze(fast_warm),
    })
    gc.collect()

print(json.dumps(rows, ensure_ascii=False))
"""

        env = os.environ.copy()
        existing = env.get("PYTHONPATH")
        env["PYTHONPATH"] = src_root if not existing else src_root + os.pathsep + existing
        completed = subprocess.run(
            [sys.executable, "-c", child, json.dumps(offsets)],
            cwd=repo_root,
            env=env,
            text=True,
            capture_output=True,
            check=True,
            timeout=90,
        )
        rows = json.loads(completed.stdout.strip().splitlines()[-1])
        self.assertEqual(len(rows), len(offsets))
        for row in rows:
            with self.subTest(offset=row["offset"]):
                self.assertEqual(row["cold"], row["slow"])
                self.assertEqual(row["warm"], row["slow"])
                self.assertEqual(len(row["slow"]), 5)

    def test_stale_final_fingerprint_is_observable_and_falls_back(self):
        ctx = MonsterContext(11, 12)
        ctx.acceleration_scars.enabled = True
        result = SpaghettiDateResult(1, "x", 2, "y", 3)
        fingerprint_a = semantic_fingerprint(calendar_module.calendar_date_spaghetti)
        store_final_result(ctx, result, fingerprint_a, full_monster_run=True)

        set_test_fingerprint_salt("changed-semantic-salt")
        fingerprint_b = semantic_fingerprint(calendar_module.calendar_date_spaghetti)
        probe = MonsterContext(11, 12)
        probe.acceleration_scars.enabled = True
        self.assertIsNone(lookup_final_result(probe, fingerprint_b))
        self.assertEqual(probe.acceleration_scars.final_cache_stale, 1)
        self.assertEqual(probe.metrics.get("final_result_cache_stale"), 1)

    def test_final_result_burial_cache_is_bounded_and_evicts(self):
        old_maximum = scars._FINAL_RESULTS.maximum
        scars._FINAL_RESULTS.maximum = 2
        try:
            fp = semantic_fingerprint(calendar_module.calendar_date_spaghetti)
            for day in (1, 2, 3):
                ctx = MonsterContext(day, day)
                ctx.acceleration_scars.enabled = True
                store_final_result(
                    ctx,
                    SpaghettiDateResult(day, "x", 1, "y", 1),
                    fp,
                    full_monster_run=True,
                )
            self.assertEqual(cache_sizes()["final_results"], 2)
            self.assertGreaterEqual(scars._FINAL_RESULTS.evictions, 1)
        finally:
            scars._FINAL_RESULTS.maximum = old_maximum

    def test_poisoned_checkpoint_is_rejected_then_legacy_year_walk_finishes(self):
        # Derive the witness from the current Year 5000 anchor instead of a
        # fixed Foundation+1000 offset.  The saved-sum correction changed the
        # anchor geometry, so the old fixed target could leave the injected
        # checkpoint no closer than the anchor and classify it as a miss.
        seed_ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        seed_manager = FinalSpaghettiIntegrationManager(seed_ctx)
        seed_anchor = seed_manager.year5000(FOUNDATION_DAY)
        target_day = seed_anchor.close_gate_day + 1

        expected_ctx = MonsterContext(FOUNDATION_DAY, target_day)
        expected_manager = FinalSpaghettiIntegrationManager(expected_ctx)
        with acceleration_mode(False):
            expected = expected_manager.findTargetYear(
                FOUNDATION_DAY,
                target_day,
            )

        ctx = MonsterContext(FOUNDATION_DAY, target_day)
        ctx.acceleration_scars.enabled = True
        manager = FinalSpaghettiIntegrationManager(ctx)
        anchor = manager.year5000(FOUNDATION_DAY)
        self.assertEqual(target_day, anchor.close_gate_day + 1)

        # Make the false checkpoint claim an exact (distance-zero) hit for the
        # target while retaining Year 5000 gate indices.  It must therefore be
        # selected ahead of the anchor (distance one), then fail gate-boundary
        # validation and be recorded as rejected/poisoned before the legacy
        # year walk finishes normally.
        bad = YearCheckpoint(
            calculation_day=FOUNDATION_DAY,
            year_number=5001,
            first_day=target_day,
            last_day=target_day,
            open_gate_index=anchor.open_gate_index,
            close_gate_index=anchor.close_gate_index,
            relevant_gate_index=anchor.open_gate_index,
            semantic_fingerprint=manager._acceleration_fingerprint,
        )
        scars._YEAR_CHECKPOINTS.put((FOUNDATION_DAY, 5001), bad)

        actual = manager.findTargetYear(
            FOUNDATION_DAY,
            target_day,
        )
        self.assertEqual(actual, expected)
        self.assertGreaterEqual(ctx.acceleration_scars.checkpoint_rejected, 1)
        self.assertGreaterEqual(ctx.metrics.get("year_checkpoint_rejected", 0), 1)

    def test_selection_oracle_false_prophecy_reverts_to_original_loop(self):
        ring = LegacyAnswerRing(first=M_OLD, direction_step=-1)
        family_count = M_OLD - 2000
        scope = ("test-selection-heavy", 1)
        ctx = MonsterContext(1, 1)
        ctx.acceleration_scars.enabled = True

        first = _chooseIntegratedRank(ring, family_count, ctx, scope)
        items = scars._SELECTION_ORACLE.items_snapshot()
        self.assertEqual(len(items), 1)
        key, remembered = items[0]
        remembered.accepted_answer += 1

        second = _chooseIntegratedRank(ring, family_count, ctx, scope)
        self.assertEqual(second, first)
        self.assertEqual(ctx.acceleration_scars.oracle_false_prophecies, 1)

    def test_gate_shard_round_trip_resurrection_does_not_generate_semantics(self):
        ctx = MonsterContext(1, 1)
        ctx.acceleration_scars.enabled = True
        cache = IntegratedGateCache(ctx)
        start = 1
        days = tuple(range(1000, 1000 + scars.GATE_SHARD_SIZE))
        scars.store_gate_shard(
            ctx,
            start,
            days,
            cache._acceleration_fingerprint,
        )
        fresh_ctx = MonsterContext(1, 1)
        fresh_ctx.acceleration_scars.enabled = True
        fresh = IntegratedGateCache(fresh_ctx)
        self.assertTrue(fresh._resurrect_shard_if_adjacent(1))
        self.assertEqual(fresh.gates[1], days[0])
        self.assertEqual(fresh.gates[scars.GATE_SHARD_SIZE], days[-1])
        self.assertEqual(fresh_ctx.acceleration_scars.gate_shard_hits, 1)
        self.assertEqual(fresh_ctx.integration_gate_questions, 0)

    def test_release_gate_checkpoints_are_monotonic_and_keep_foundation_anchor(self):
        indices = tuple(index for index, _ in GATE_CHECKPOINTS_INTEGRATED)
        days = tuple(day for _, day in GATE_CHECKPOINTS_INTEGRATED)

        self.assertEqual(tuple(sorted(indices)), indices)
        self.assertEqual(tuple(sorted(days)), days)
        self.assertEqual(len(indices), len(set(indices)))
        self.assertEqual(len(days), len(set(days)))
        self.assertIn((0, FOUNDATION_DAY), GATE_CHECKPOINTS_INTEGRATED)

    def test_release_gate_checkpoint_positive_reanchor_walks_both_directions_exactly(self):
        anchor_index = 31472
        anchor_day = 737010

        forward_ctx = MonsterContext(FOUNDATION_DAY, anchor_day)
        forward = IntegratedGateCache(forward_ctx)
        forward._reanchor_for_cover(anchor_day, anchor_day)
        self.assertEqual((forward.min_known, forward.max_known), (anchor_index, anchor_index))
        self.assertEqual(forward.gates, {anchor_index: anchor_day})
        self.assertEqual(forward.ensure_index(31488), 745943)

        backward_ctx = MonsterContext(FOUNDATION_DAY, anchor_day)
        backward = IntegratedGateCache(backward_ctx)
        backward._reanchor_for_cover(anchor_day, anchor_day)
        self.assertEqual(backward.ensure_index(31456), 729039)

        for ctx in (forward_ctx, backward_ctx):
            self.assertEqual(ctx.metrics.get("gate_checkpoint_reanchor"), 1)
            self.assertIn(
                ("GATE_CHECKPOINT_REANCHOR", anchor_index, anchor_day),
                ctx.branch_trace,
            )

    def test_release_gate_checkpoint_negative_reanchor_walks_both_directions_exactly(self):
        left_index = -2048
        left_day = -16082135
        right_index = -1856
        right_day = -15990665

        forward_ctx = MonsterContext(FOUNDATION_DAY, left_day)
        forward = IntegratedGateCache(forward_ctx)
        forward._reanchor_for_cover(left_day, left_day)
        self.assertEqual((forward.min_known, forward.max_known), (left_index, left_index))
        self.assertEqual(forward.ensure_index(right_index), right_day)

        backward_ctx = MonsterContext(FOUNDATION_DAY, right_day)
        backward = IntegratedGateCache(backward_ctx)
        backward._reanchor_for_cover(right_day, right_day)
        self.assertEqual((backward.min_known, backward.max_known), (right_index, right_index))
        self.assertEqual(backward.ensure_index(left_index), left_day)

    def test_release_gate_checkpoint_does_not_reanchor_cover_crossing_foundation(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        cache = IntegratedGateCache(ctx)
        cache.ensure_cover(FOUNDATION_DAY - 1, FOUNDATION_DAY + 1)

        self.assertEqual(ctx.metrics.get("gate_checkpoint_reanchor", 0), 0)
        self.assertIn(0, cache.gates)
        self.assertLess(cache.min_known, 0)
        self.assertGreater(cache.max_known, 0)

    def test_external_rollback_containment_restores_only_declared_stage_fields(self):
        year = IntegratedYear(
            number=5000,
            open_gate_index=0,
            close_gate_index=1,
            open_gate_day=100,
            close_gate_day=110,
        )
        structure = IntegratedYearStructure(
            cutlet_count=1,
            cutlet_partition=(1,),
            cutlet_name_indices=(1,),
            cutlets=(
                IntegratedCutlet(
                    name_index=1,
                    open_gate_index=0,
                    close_gate_index=1,
                    first_day=101,
                    last_day=110,
                ),
            ),
            month_count=1,
            month_lengths=(10,),
            month_weaving=(1,) * 10,
            month_name_indices=(1,),
        )
        expected = SpaghettiDateResult(
            year_number=5000,
            cutlet_name=SOURCE_LANGUAGE_CATALOG.cutlet_text(1),
            day_in_cutlet=1,
            month_name=SOURCE_LANGUAGE_CATALOG.month_text(1),
            day_in_month=1,
        )

        class OneScarFailureManager(FinalSpaghettiIntegrationManager):
            def __init__(self, ctx):
                super().__init__(ctx)
                self.failed_once = False

            def findTargetYear(self, calculation_day, target_day):
                self.ctx.integration_target_year_number = year.number
                self.ctx.integration_target_year_open_day = year.open_gate_day
                self.ctx.integration_target_year_close_day = year.close_gate_day
                return year

            def buildStructure(self, calculation_day, original_target_day, semantic_year):
                if not self.failed_once:
                    self.failed_once = True
                    self.ctx.integration_structure_semantic_target_day = 999999999
                    raise AssertionError("injected containment witness")
                self.ctx.integration_structure = structure
                return structure

        ctx = MonsterContext(100, 101)
        ctx.acceleration_scars.enabled = True
        manager = OneScarFailureManager(ctx)
        actual = manager.execute(100, 101)
        self.assertEqual(actual, expected)
        self.assertEqual(ctx.integration_retry_count, 1)
        self.assertGreaterEqual(ctx.acceleration_scars.rollback_containment_applied, 1)
        self.assertGreaterEqual(ctx.acceleration_scars.rollback_containment_fields_restored, 1)


if __name__ == "__main__":
    unittest.main()
