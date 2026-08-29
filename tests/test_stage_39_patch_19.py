import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_year_cache import (
    GuardedYearCacheEntry,
    LegacyYearCacheRequest,
    LegacyYearCacheValue,
    LegacyYearNumberOnlyCacheMap,
    YearCacheActionGuardPatchWrapper,
    legacyYearNumberOnlyLookup,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


def _request(
    *,
    year_number: int = 5000,
    calculation_day: int = 100,
    open_gate: int = 0,
    close_gate: int = 10,
    token: str = "ilk",
) -> LegacyYearCacheRequest:
    return LegacyYearCacheRequest(
        year_number=year_number,
        calculation_day=calculation_day,
        open_gate=open_gate,
        close_gate=close_gate,
        value=LegacyYearCacheValue(
            token=token,
        ),
    )


class Stage39Patch19Tests(unittest.TestCase):
    def test_map_key_remains_only_year_number_after_guard_mismatch_overwrite(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        cache.lookup_or_store(
            ctx,
            _request(
                token="ilk",
            ),
        )
        cache.lookup_or_store(
            ctx,
            _request(
                calculation_day=101,
                token="ikinci",
            ),
        )

        self.assertEqual(
            cache.raw_keys(),
            (
                5000,
            ),
        )

    def test_guarded_entry_stores_exact_required_fields(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        request = _request(
            calculation_day=123,
            open_gate=-9,
            close_gate=19,
            token="yapı",
        )

        cache.lookup_or_store(
            ctx,
            request,
        )

        self.assertEqual(
            cache.raw_entry(
                5000,
            ),
            GuardedYearCacheEntry(
                calculationDayFingerprint=123,
                openGate=-9,
                closeGate=19,
                value=LegacyYearCacheValue(
                    token="yapı",
                ),
            ),
        )

    def test_valid_hit_requires_all_three_guards_and_keeps_cached_value(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        first = _request(
            token="ilk",
        )
        same_guards_new_value = _request(
            token="yeniden-hesaplanmamalı",
        )

        first_value = cache.lookup_or_store(
            ctx,
            first,
        )
        second_value = cache.lookup_or_store(
            ctx,
            same_guards_new_value,
        )

        self.assertEqual(
            second_value,
            first_value,
        )
        self.assertTrue(
            ctx.patch19_legacy_key_hit,
        )
        self.assertTrue(
            ctx.patch19_calculation_day_match,
        )
        self.assertTrue(
            ctx.patch19_open_gate_match,
        )
        self.assertTrue(
            ctx.patch19_close_gate_match,
        )
        self.assertTrue(
            ctx.patch19_all_guards_match,
        )
        self.assertEqual(
            ctx.legacy_year_cache_hit_count,
            1,
        )

    def test_each_guard_mismatch_is_a_miss_and_overwrites_same_key(self):
        base = _request(
            token="ilk",
        )

        cases = (
            _request(
                calculation_day=101,
                token="hesap",
            ),
            _request(
                open_gate=-1,
                token="açılış",
            ),
            _request(
                close_gate=11,
                token="kapanış",
            ),
        )

        for changed in cases:
            with self.subTest(
                calculation_day=changed.calculation_day,
                open_gate=changed.open_gate,
                close_gate=changed.close_gate,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )
                cache = LegacyYearNumberOnlyCacheMap()

                cache.lookup_or_store(
                    ctx,
                    base,
                )
                actual = cache.lookup_or_store(
                    ctx,
                    changed,
                )

                self.assertEqual(
                    actual,
                    changed.value,
                )
                self.assertFalse(
                    ctx.patch19_all_guards_match,
                )
                self.assertEqual(
                    ctx.legacy_year_cache_hit_count,
                    0,
                )
                self.assertEqual(
                    ctx.legacy_year_cache_miss_count,
                    2,
                )
                self.assertEqual(
                    cache.raw_keys(),
                    (
                        5000,
                    ),
                )
                self.assertEqual(
                    cache.raw_entry(
                        5000,
                    ).value,
                    changed.value,
                )

    def test_guard_mismatch_overwrite_becomes_valid_hit_on_next_identical_request(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        cache.lookup_or_store(
            ctx,
            _request(
                token="ilk",
            ),
        )

        changed = _request(
            calculation_day=101,
            open_gate=-1,
            close_gate=11,
            token="değişmiş",
        )

        cache.lookup_or_store(
            ctx,
            changed,
        )
        third = cache.lookup_or_store(
            ctx,
            changed,
        )

        self.assertEqual(
            third,
            changed.value,
        )
        self.assertTrue(
            ctx.legacy_year_cache_last_hit,
        )
        self.assertTrue(
            ctx.patch19_all_guards_match,
        )
        self.assertEqual(
            ctx.legacy_year_cache_miss_count,
            2,
        )
        self.assertEqual(
            ctx.legacy_year_cache_hit_count,
            1,
        )

    def test_legacy_year_number_only_lookup_is_still_called_before_guard_checks(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        cache.lookup_or_store(
            ctx,
            _request(
                token="ilk",
            ),
        )

        changed = _request(
            calculation_day=101,
            token="ikinci",
        )

        with patch(
            "pastafari_calendar.legacy_year_cache.legacyYearNumberOnlyLookup",
            wraps=legacyYearNumberOnlyLookup,
        ) as legacy_lookup:
            cache.lookup_or_store(
                ctx,
                changed,
            )

        self.assertEqual(
            legacy_lookup.call_count,
            1,
        )
        self.assertEqual(
            legacy_lookup.call_args.args[1],
            5000,
        )
        self.assertTrue(
            ctx.patch19_legacy_key_hit,
        )
        self.assertFalse(
            ctx.patch19_calculation_day_match,
        )

    def test_real_calendar_path_recomputes_changed_calculation_day_value(self):
        with patch(
            "pastafari_calendar.legacy_year_cache.YearCacheActionGuardPatchWrapper.cachePutWithGuard",
            autospec=True,
            wraps=YearCacheActionGuardPatchWrapper.cachePutWithGuard,
        ) as put_call:
            with self.assertRaises(StageNotIntegratedError) as raised:
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertIn(
                "Otuz dokuzuncu aşamada",
                str(
                    raised.exception
                ),
            )
            self.assertEqual(
                put_call.call_count,
                2,
            )

    def test_patch_state_is_invocation_local_even_when_cache_object_is_reused(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        cache = LegacyYearNumberOnlyCacheMap()

        cache.lookup_or_store(
            first,
            _request(
                token="ilk",
            ),
        )

        self.assertTrue(
            first.patch19_applied,
        )
        self.assertFalse(
            second.patch19_applied,
        )
        self.assertIsNone(
            second.patch19_last_written_token,
        )

    def test_observability_state_cannot_change_guarded_cache_result(self):
        plain = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        noisy = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        noisy.logs.extend(
            [
                (
                    "önceden",
                    1,
                ),
                (
                    "önceden",
                    2,
                ),
            ]
        )
        noisy.metrics[
            "yalnızca-gözlem"
        ] = 19100
        noisy.diagnostics.append(
            (
                "tanı",
                39,
            )
        )

        plain_cache = LegacyYearNumberOnlyCacheMap()
        noisy_cache = LegacyYearNumberOnlyCacheMap()

        base = _request(
            token="ilk",
        )
        changed = _request(
            calculation_day=101,
            token="ikinci",
        )

        plain_cache.lookup_or_store(
            plain,
            base,
        )
        noisy_cache.lookup_or_store(
            noisy,
            base,
        )

        plain_result = plain_cache.lookup_or_store(
            plain,
            changed,
        )
        noisy_result = noisy_cache.lookup_or_store(
            noisy,
            changed,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain_cache.raw_entry(
                5000,
            ),
            noisy_cache.raw_entry(
                5000,
            ),
        )


if __name__ == "__main__":
    unittest.main()
