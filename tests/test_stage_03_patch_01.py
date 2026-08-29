import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_arithmetic import (
    M_OLD,
    LegacyRemainderAdapter,
    oldRemainder,
    savePatch,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY, save


class Stage03Patch01Tests(unittest.TestCase):
    def test_save_patch_matches_normative_save_on_required_edges(self):
        cases = (
            1,
            M_OLD - 1,
            M_OLD,
            M_OLD + 1,
            2 * M_OLD,
            3 * M_OLD,
        )
        for value in cases:
            with self.subTest(value=value):
                self.assertEqual(savePatch(value), save(value))

    def test_old_remainder_is_still_physically_wrong(self):
        self.assertEqual(oldRemainder(M_OLD), 0)
        self.assertEqual(oldRemainder(2 * M_OLD), 0)
        self.assertEqual(oldRemainder(3 * M_OLD), 0)

    def test_save_patch_really_calls_the_legacy_helper(self):
        with patch(
            "pastafari_calendar.legacy_arithmetic.oldRemainder",
            wraps=oldRemainder,
        ) as legacy_call:
            self.assertEqual(savePatch(M_OLD), M_OLD)
            self.assertEqual(legacy_call.call_count, 1)
            self.assertEqual(legacy_call.call_args.args, (M_OLD,))

    def test_adapter_routes_through_patch_wrapper_and_keeps_state_local(self):
        first = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        second = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)

        actual = LegacyRemainderAdapter().call(first, M_OLD)

        self.assertEqual(actual, M_OLD)
        self.assertTrue(first.patch01_applied)
        self.assertEqual(first.patch01_input, M_OLD)
        self.assertEqual(first.patch01_value, M_OLD)
        self.assertFalse(second.patch01_applied)
        self.assertIsNone(second.patch01_input)
        self.assertIsNone(second.patch01_value)

    def test_observability_state_does_not_change_the_patch_result(self):
        plain = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        noisy = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        noisy.logs.extend([("önceden", 1), ("önceden", 2)])
        noisy.metrics["rastgele-gözlem-sayacı"] = 999
        noisy.diagnostics.append(("yalnızca-gözlem", M_OLD))

        self.assertEqual(
            LegacyRemainderAdapter().call(plain, 2 * M_OLD),
            LegacyRemainderAdapter().call(noisy, 2 * M_OLD),
        )


if __name__ == "__main__":
    unittest.main()
