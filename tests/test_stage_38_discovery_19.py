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
    LegacyYearCacheRequest,
    LegacyYearCacheValue,
    LegacyYearNumberOnlyCacheMap,
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


class Stage38Discovery19Tests(unittest.TestCase):
    def test_year_number_only_cache_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_year_cache.LegacyYearNumberOnlyCacheMap.lookup_or_store",
            autospec=True,
            wraps=LegacyYearNumberOnlyCacheMap.lookup_or_store,
        ) as cache_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(cache_call.call_count, 2)
            first_request = cache_call.call_args_list[0].args[2]
            second_request = cache_call.call_args_list[1].args[2]

            self.assertEqual(
                first_request.year_number,
                second_request.year_number,
            )
            self.assertNotEqual(
                first_request.calculation_day,
                second_request.calculation_day,
            )

    def test_legacy_map_really_has_only_year_number_as_key(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        cache = LegacyYearNumberOnlyCacheMap()

        first = _request(token="ilk")
        changed = _request(
            calculation_day=101,
            open_gate=-1,
            close_gate=11,
            token="değişmiş",
        )

        first_value = cache.lookup_or_store(ctx, first)
        second_value = cache.lookup_or_store(ctx, changed)

        self.assertEqual(cache.raw_keys(), (5000,))
        self.assertEqual(first_value, LegacyYearCacheValue(token="ilk"))
        self.assertEqual(second_value, changed.value)

        raw_entry = cache.raw_entry(5000)

        self.assertIsNotNone(raw_entry)
        self.assertEqual(
            legacyYearNumberOnlyLookup(
                cache._map,
                5000,
            ),
            raw_entry,
        )
        self.assertEqual(
            raw_entry.value,
            changed.value,
        )

    def test_cache_state_records_guard_mismatch_as_miss(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        cache = LegacyYearNumberOnlyCacheMap()

        cache.lookup_or_store(ctx, _request(token="ilk"))
        cache.lookup_or_store(
            ctx,
            _request(
                calculation_day=101,
                token="ikinci",
            ),
        )

        self.assertEqual(ctx.legacy_year_cache_miss_count, 2)
        self.assertEqual(ctx.legacy_year_cache_hit_count, 0)
        self.assertFalse(ctx.legacy_year_cache_last_hit)
        self.assertEqual(ctx.legacy_year_cache_last_returned_token, "ikinci")
        self.assertEqual(ctx.legacy_year_cache_map_keys, (5000,))

    def test_separate_cache_instances_do_not_share_map_state(self):
        first_ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        second_ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        first_cache = LegacyYearNumberOnlyCacheMap()
        second_cache = LegacyYearNumberOnlyCacheMap()

        first_cache.lookup_or_store(
            first_ctx,
            _request(token="birinci-instance"),
        )
        second_value = second_cache.lookup_or_store(
            second_ctx,
            _request(token="ikinci-instance"),
        )

        self.assertEqual(
            second_value,
            LegacyYearCacheValue(token="ikinci-instance"),
        )
        self.assertEqual(second_ctx.legacy_year_cache_miss_count, 1)
        self.assertEqual(second_ctx.legacy_year_cache_hit_count, 0)

    def test_current_year_number_only_cache_reuses_stale_value_when_guard_source_changes(self):
        base = _request(token="ilk")
        cases = (
            _request(
                calculation_day=101,
                token="hesap-günü-değişti",
            ),
            _request(
                open_gate=-1,
                token="açılış-kapısı-değişti",
            ),
            _request(
                close_gate=11,
                token="kapanış-kapısı-değişti",
            ),
        )

        for changed in cases:
            with self.subTest(
                calculation_day=changed.calculation_day,
                open_gate=changed.open_gate,
                close_gate=changed.close_gate,
            ):
                ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
                cache = LegacyYearNumberOnlyCacheMap()
                cache.lookup_or_store(ctx, base)
                actual = cache.lookup_or_store(ctx, changed)
                expected = changed.value

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy cache yalnız year.number key kullandığı için guard kaynağı değişse de eski value yeniden kullanıldı",
                )


if __name__ == "__main__":
    unittest.main()
