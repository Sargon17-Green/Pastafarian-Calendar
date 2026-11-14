from __future__ import annotations
import hashlib
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import unittest

FILE = Path(__file__).resolve().parents[1] / "runner/pilot_python_transport_v017.py"
spec = importlib.util.spec_from_file_location("pilot_python_transport_v017", FILE)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class NativePythonTransportTests(unittest.TestCase):
    def test_signed_decimal_inputs_not_reinterpreted(self):
        self.assertEqual(mod.canonical_integer("-15055671"), -15055671)
        self.assertEqual(mod.canonical_integer("0"), 0)
        for bad in ("-0", "+2", "00", "01", "-01", " 2", "1.0", "1\n", "", "1e3"):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                mod.canonical_integer(bad)

    def test_normalization_is_transport_not_date_computation(self):
        fake_module = SimpleNamespace(
            FROZEN_CUTLET_NAMES=tuple("C" + str(i) for i in range(1, 18)),
            FROZEN_MONTH_NAMES=tuple("M" + str(i) for i in range(1, 48)),
        )
        result = SimpleNamespace(year_number=5000, cutlet_name_index=10,
                                 day_in_cutlet=503, month_name_index=20,
                                 day_in_month=56)
        calls = []
        class FakeCalendar:
            def calendar_date_ids(self, c, t):
                calls.append((c, t))
                return result
        raw, norm = mod.produce(FakeCalendar(), fake_module, -15055671, -15055671)
        self.assertEqual(calls, [(-15055671, -15055671)])
        source = json.loads(raw)
        row = json.loads(norm)
        self.assertEqual(source["native_date_ids"]["cutlet_name_index"], 10)
        self.assertEqual(source["native_names"], {"cutlet": "C10", "month": "M20"})
        self.assertEqual(tuple(row[k] for k in ("year", "cutlet_index", "day_in_cutlet",
                                               "month_index", "day_in_month")),
                         ("5000", 10, 503, 20, 56))
        self.assertEqual(row["source_raw_sha256"], hashlib.sha256(raw).hexdigest())
        self.assertTrue(raw.endswith(b"\n") and norm.endswith(b"\n"))
        self.assertEqual(row["calculation_day"], row["target_day"])

    def test_bad_native_fields_not_silently_repaired(self):
        fake = SimpleNamespace(
            FROZEN_CUTLET_NAMES=tuple("C" + str(i) for i in range(1, 18)),
            FROZEN_MONTH_NAMES=tuple("M" + str(i) for i in range(1, 48)))
        for bad in (0, 18, True):
            with self.subTest(bad=bad):
                native = SimpleNamespace(year_number=5000, cutlet_name_index=bad,
                      day_in_cutlet=1, month_name_index=1, day_in_month=1)
                class Stub:
                    def calendar_date_ids(self, c, t): return native
                with self.assertRaises(ValueError):
                    mod.produce(Stub(), fake, 0, 0)


if __name__ == "__main__":
    unittest.main()
