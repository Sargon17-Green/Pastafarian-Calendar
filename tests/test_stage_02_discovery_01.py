import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_arithmetic import M_OLD, oldRemainder
from pastafari_calendar.monster_bootstrap import StageNotIntegratedError
from normative_reference import FOUNDATION_DAY, save


class Stage02Discovery01Tests(unittest.TestCase):
    def test_legacy_remainder_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_arithmetic.oldRemainder",
            wraps=oldRemainder,
        ) as legacy_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(FOUNDATION_DAY, FOUNDATION_DAY)
            self.assertEqual(legacy_call.call_count, 1)
            self.assertEqual(legacy_call.call_args.args, (M_OLD,))

    def test_patch_is_not_present_yet(self):
        production_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "src" / "pastafari_calendar").glob("*.py")
        )
        self.assertNotIn("savePatch", production_text)

    def test_legacy_remainder_diverges_from_normative_save(self):
        cases = (
            M_OLD,
            2 * M_OLD,
            3 * M_OLD,
            M_OLD + 1,
        )
        for value in cases:
            with self.subTest(value=value):
                self.assertEqual(
                    oldRemainder(value),
                    save(value),
                    msg="Eski kalan işlemi normatif kaydetme işlemiyle uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
