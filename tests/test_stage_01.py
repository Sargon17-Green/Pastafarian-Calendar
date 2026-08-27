import itertools
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG

from normative_reference import (
    M,
    FOUNDATION_DAY,
    TABLETS_DAY,
    AnswerStream,
    BoundedCompositionFamily,
    CutletPartitionFamily,
    MonthWeavingFamily,
    NormativeCalendar,
    ask_bowl,
    bowl_order_from_number,
    brute_weavings,
    choose_rank,
    day_count,
    next_bowl_in_drop46_order,
    permutation_unrank1,
    save,
    sauce,
    unrank_distinct_indices,
    work_counts,
)


class Stage01Tests(unittest.TestCase):
    def test_day_axis_and_save(self):
        self.assertEqual(TABLETS_DAY - FOUNDATION_DAY, 14777149)
        self.assertEqual(day_count(FOUNDATION_DAY - 3), 6)
        self.assertEqual(day_count(FOUNDATION_DAY - 1), 2)
        self.assertEqual(day_count(FOUNDATION_DAY), 1)
        self.assertEqual(day_count(FOUNDATION_DAY + 1), 3)
        self.assertEqual(save(1), 1)
        self.assertEqual(save(M), M)
        self.assertEqual(save(M + 1), 1)
        self.assertEqual(save(2 * M), M)
        self.assertEqual(save(0), M)

    def test_work_counts(self):
        same = work_counts(FOUNDATION_DAY, FOUNDATION_DAY)
        self.assertEqual(same.distance, 1)
        self.assertEqual(same.direction, 2)
        before = work_counts(FOUNDATION_DAY + 9, FOUNDATION_DAY - 4)
        self.assertEqual(before.distance, 14)
        self.assertEqual(before.direction, 1)

    def test_permutation_edges(self):
        self.assertEqual(
            bowl_order_from_number(1),
            (1, 2, 3, 4, 5, 6),
        )
        self.assertEqual(
            bowl_order_from_number(720),
            (6, 5, 4, 3, 2, 1),
        )
        self.assertEqual(
            permutation_unrank1(1, (1, 2, 3)),
            (1, 2, 3),
        )
        self.assertEqual(
            permutation_unrank1(6, (1, 2, 3)),
            (3, 2, 1),
        )

    def test_sauce_determinism_and_query_wrap(self):
        first = sauce(FOUNDATION_DAY, FOUNDATION_DAY + 17)
        second = sauce(FOUNDATION_DAY, FOUNDATION_DAY + 17)
        self.assertEqual(first, second)
        self.assertTrue(all(1 <= x <= M for x in first.bowls[1:]))
        last_bowl = first.order_at_drop_46[-1]
        self.assertEqual(
            next_bowl_in_drop46_order(first, last_bowl),
            first.order_at_drop_46[0],
        )

    def test_short_and_wide_selection_ranges(self):
        result = sauce(FOUNDATION_DAY, FOUNDATION_DAY)
        stream = ask_bowl(result, 1, 1)
        self.assertEqual(choose_rank(stream, 1), 1)
        self.assertTrue(1 <= choose_rank(stream, M) <= M)
        self.assertTrue(1 <= choose_rank(stream, M + 1) <= M + 1)

    def test_bounded_composition_lexicographic_order(self):
        family = BoundedCompositionFamily(8, 3, 1, 5)
        brute = [
            row
            for row in itertools.product(range(1, 6), repeat=3)
            if sum(row) == 8
        ]
        self.assertEqual(family.count(), len(brute))
        self.assertEqual(
            [family.unrank1(i + 1) for i in range(family.count())],
            brute,
        )

    def test_cutlet_partition_filter(self):
        family = CutletPartitionFamily(9, 4, 5)
        brute = []
        for row in itertools.product(range(1, 10), repeat=4):
            if sum(row) != 9:
                continue
            total = 0
            hit = False
            for value in row:
                total += value
                if total == 5:
                    hit = True
            if hit:
                brute.append(row)
        self.assertEqual(family.count(), len(brute))
        self.assertEqual(
            [family.unrank1(i + 1) for i in range(family.count())],
            brute,
        )

    def test_distinct_name_unrank(self):
        rows = [
            unrank_distinct_indices(4, 3, i)
            for i in range(1, 4 * 3 * 2 + 1)
        ]
        self.assertEqual(len(rows), len(set(rows)))
        self.assertTrue(all(len(set(row)) == 3 for row in rows))
        self.assertEqual(rows, sorted(rows))

    def test_month_weaving_matches_bruteforce(self):
        cases = (
            (1,),
            (2,),
            (2, 2),
            (2, 3),
            (2, 2, 2),
            (2, 3, 2),
            (3, 2, 3),
            (3, 3, 2),
        )
        for lengths in cases:
            family = MonthWeavingFamily(lengths)
            brute = brute_weavings(lengths)
            self.assertEqual(
                family.count(),
                len(brute),
                msg=f"Örgü sayısı uyuşmadı: {lengths}",
            )
            opened = tuple(
                family.unrank1(i)
                for i in range(1, family.count() + 1)
            )
            self.assertEqual(
                opened,
                brute,
                msg=f"Örgü sırası uyuşmadı: {lengths}",
            )

    def test_month_weaving_all_small_domains(self):
        checked = 0
        for month_count in range(1, 5):
            for lengths in itertools.product((1, 2, 3), repeat=month_count):
                if sum(lengths) > 9:
                    continue
                family = MonthWeavingFamily(lengths)
                brute = brute_weavings(lengths)
                self.assertEqual(family.count(), len(brute))
                if brute:
                    self.assertEqual(family.unrank1(1), brute[0])
                    self.assertEqual(family.unrank1(len(brute)), brute[-1])
                checked += 1
        self.assertGreaterEqual(checked, 80)

    def test_source_language_catalog_is_frozen_and_index_stable(self):
        self.assertEqual(SOURCE_LANGUAGE_CATALOG.version, "1.3.1")
        self.assertEqual(SOURCE_LANGUAGE_CATALOG.natural_language, "Türkçe")
        self.assertEqual(len(SOURCE_LANGUAGE_CATALOG.cutlets), 17)
        self.assertEqual(len(SOURCE_LANGUAGE_CATALOG.months), 47)
        self.assertEqual(
            tuple(x.canonical_index for x in SOURCE_LANGUAGE_CATALOG.cutlets),
            tuple(range(1, 18)),
        )
        self.assertEqual(
            tuple(x.canonical_index for x in SOURCE_LANGUAGE_CATALOG.months),
            tuple(range(1, 48)),
        )
        self.assertEqual(len({x.text for x in SOURCE_LANGUAGE_CATALOG.cutlets}), 17)
        self.assertEqual(len({x.text for x in SOURCE_LANGUAGE_CATALOG.months}), 47)

    def test_context_is_per_invocation(self):
        first = MonsterContext(1, 2)
        second = MonsterContext(1, 2)
        first.branch_trace.append("X")
        first.metrics["a"] = 1
        self.assertEqual(second.branch_trace, [])
        self.assertEqual(second.metrics, {})

    def test_production_does_not_call_oracle(self):
        before = set(sys.modules)
        with self.assertRaises(StageNotIntegratedError):
            calendar_date_spaghetti(FOUNDATION_DAY, FOUNDATION_DAY)
        newly_loaded = set(sys.modules) - before
        self.assertNotIn("normative_reference", newly_loaded)

    def test_no_future_patch_names_in_production(self):
        production_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "src" / "pastafari_calendar").glob("*.py")
        )
        forbidden = (
            "oldRemainder",
            "oldDayTag",
            "oldDistance",
            "mutateStonesWrong",
            "orderAt46Latch",
            "biasedLegacyPick",
            "LEGACY_YEAR_MAX",
            "oldJumpGuess",
            "VirtualLegacyList",
            "legacyChooseEachDaySeparately",
            "oldContiguousMonthDayGuess",
        )
        for token in forbidden:
            self.assertNotIn(token, production_text)

    def test_normative_year5000_and_structure_smoke(self):
        calendar = NormativeCalendar()
        year = calendar.year5000(FOUNDATION_DAY)
        self.assertEqual(year.number, 5000)
        self.assertTrue(252 <= year.close_gate_day - year.open_gate_day <= 5778)
        structure = calendar.build_year_structure(FOUNDATION_DAY, year)
        self.assertEqual(len(structure.cutlets), structure.cutlet_count)
        self.assertEqual(len(structure.month_lengths), structure.month_count)
        self.assertEqual(sum(structure.month_lengths), year.close_gate_day - year.open_gate_day)
        self.assertEqual(len(structure.month_weaving), year.close_gate_day - year.open_gate_day)
        self.assertEqual(len(set(structure.cutlet_name_indices)), structure.cutlet_count)
        self.assertEqual(len(set(structure.month_name_indices)), structure.month_count)


if __name__ == "__main__":
    unittest.main()
