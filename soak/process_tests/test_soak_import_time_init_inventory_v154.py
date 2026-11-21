#!/usr/bin/env python3
"""v154: 20 synthetic negative cases for import-time computation inventory."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from soak_import_time_init_inventory_v154 import (
    python_import_inventory, js_engine_import_inventory, js_catalog_import_inventory
)

PY = '''
from __future__ import annotations
from dataclasses import dataclass
M = 2**127 - 1
FROZEN_CUTLET_NAMES = ("a", "b")
FROZEN_MONTH_NAMES = ("x", "y")
def save(x: int) -> int:
    return x
def build_stones():
    rows = [tuple()] * 47
    for i in range(2, 47):
        old = rows[i - 1]
        rows[i] = (
            save(old[0]),
            save(old[1]),
            save(old[2]),
            save(old[3]),
            save(old[4]),
        )
    return tuple(rows)
STONES = build_stones()
@dataclass(frozen=True, slots=True)
class Value:
    a: int
    b: int
def calendar_date_ids(c, t):
    return c, t
'''

JS = """
'use strict';
const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');
const M = (1n << 127n) - 1n;
function buildStones() {
  const stone = [];
  stone.push(Object.freeze([17n, 29n, 43n, 71n, 101n]));
  for (let i = 2; i <= 46; i += 1) {
    const old = stone[i - 2];
    stone.push(Object.freeze(old));
  }
  return Object.freeze(stone);
}
const STONES = buildStones();
function calendarDate(c,t) {
 return [c,t];
}
"""
CAT = """
'use strict';
const CUTLETS = Object.freeze([
  Object.freeze({ canonicalIndex: 1, text: 'a' })
]);
const MONTHS = Object.freeze([
  Object.freeze({ canonicalIndex: 1, text: 'b' })
]);
const SourceLanguageCatalog = Object.freeze({
  cutlets: CUTLETS, months: MONTHS
});
function textByCanonicalIndex(group, canonicalIndex) {
  return group === 'month' ? MONTHS[canonicalIndex-1].text : CUTLETS[canonicalIndex-1].text;
}
module.exports = Object.freeze({ SourceLanguageCatalog, textByCanonicalIndex });
"""


class ImportWorkInventoryTests(unittest.TestCase):
    def altered(self, original, fragment, replacement):
        self.assertIn(fragment, original)
        return original.replace(fragment, replacement, 1)

    def py_rejected(self, text, pattern=None):
        with self.assertRaises(ValueError) as error:
            python_import_inventory(text)
        if pattern:
            self.assertIn(pattern, str(error.exception))

    def js_rejected(self, text, pattern=None):
        with self.assertRaises(ValueError) as error:
            js_engine_import_inventory(text)
        if pattern:
            self.assertIn(pattern, str(error.exception))

    def cat_rejected(self, text, pattern=None):
        with self.assertRaises(ValueError) as error:
            js_catalog_import_inventory(text)
        if pattern:
            self.assertIn(pattern, str(error.exception))

    def test_01_python_eager_stones_is_not_zero_import_work(self):
        x = python_import_inventory(PY)
        self.assertFalse(x["module_import_work_is_zero"])
        self.assertEqual(x["immediate_native_precomputation_iterations_in_source"], 45)
        self.assertEqual(x["module_level_eager_calls"], ["STONES = build_stones()"])
        self.assertEqual(x["dataclass_decorator_calls_on_import"], 1)

    def test_02_js_eager_stones_is_not_zero_import_work(self):
        x = js_engine_import_inventory(JS)
        self.assertFalse(x["module_import_work_is_zero"])
        self.assertEqual(x["immediate_native_precomputation_iterations_in_source"], 45)

    def test_03_js_catalog_object_freeze_is_not_zero_import_work(self):
        x = js_catalog_import_inventory(CAT)
        self.assertFalse(x["module_import_work_is_zero"])
        self.assertEqual(x["module_level_frozen_name_arrays"], 2)

    def test_04_python_extra_import_side_effect_rejected(self):
        self.py_rejected(PY + "\nimport subprocess\n", "unapproved Python")

    def test_05_python_top_level_executed_Fct_rejected(self):
        self.py_rejected(PY + "\ncalendar_date_ids(1,2)\n", "top-level expression")

    def test_06_python_second_stones_precomputation_rejected(self):
        self.py_rejected(PY + "\nANOTHER = build_stones()\n", "eager native")

    def test_07_python_stones_missing_rejected(self):
        self.py_rejected(self.altered(PY, "STONES = build_stones()", "STONES = ()"),
                         "eager native")

    def test_08_python_dynamic_global_initializer_rejected(self):
        self.py_rejected(PY + "\nSIDE = __import__('os')\n", "eager native")

    def test_09_python_dataclass_decorator_replaced_rejected(self):
        self.py_rejected(self.altered(PY, "@dataclass(frozen=True, slots=True)",
                                       "@custom_decorator"), "unreviewed")

    def test_10_python_class_body_call_rejected(self):
        self.py_rejected(self.altered(PY, "    b: int", "    b: int\n    dangerous()"),
                         "class-body")

    def test_11_python_45_iterations_changed_rejected(self):
        self.py_rejected(self.altered(PY, "range(2, 47)", "range(2, 4700)"),
                         "precomputation loop")

    def test_12_python_five_stone_updates_changed_rejected(self):
        self.py_rejected(self.altered(PY, "            save(old[4]),", "            old[4],"),
                         "precomputation loop")

    def test_13_python_top_level_function_default_side_effect_rejected(self):
        self.py_rejected(PY + "\ndef bad(x=dangerous()): return x\n",
                         "definition-time defaults")

    def test_14_js_extra_require_rejected(self):
        self.js_rejected(JS + "\nconst evil = require('node:child_process');\n",
                         "CommonJS dependencies")

    def test_15_js_eager_stones_missing_rejected(self):
        self.js_rejected(self.altered(JS, "const STONES = buildStones();",
                                         "const STONES = null;"), "eager precomputation")

    def test_16_js_precompute_loop_changed_rejected(self):
        self.js_rejected(self.altered(JS, "i <= 46", "i <= 47000"),
                         "45-iteration loop")

    def test_17_js_direct_calendar_date_call_before_function_rejected(self):
        self.js_rejected(self.altered(JS, "function calendarDate(c,t)",
                                         "const x=calendarDate(1n,2n);\nfunction calendarDate(c,t)"),
                         "unexpected JS native Fct")

    def test_18_js_catalog_import_removed_rejected(self):
        self.js_rejected(self.altered(JS, "require('../src/source-language-catalog')",
                                         "require('../src/something-else')"),
                         "not exactly pinned")

    def test_19_js_catalog_new_require_rejected(self):
        self.cat_rejected(CAT + "\nconst net = require('net');\n",
                          "module initialization dependency")

    def test_20_js_catalog_named_array_removed_rejected(self):
        self.cat_rejected(self.altered(CAT, "const MONTHS = Object.freeze([",
                                          "const MONTHS = ["),
                          "frozen arrays")

    def test_21_inert_source_function_reference_default_is_allowed(self):
        # The real locked Python engine has __init__(sauce_function=sauce).
        source = PY.replace("    b: int", "    b: int\n    def __init__(self, sauce_function=save):\n        self.f = sauce_function")
        r = python_import_inventory(source)
        self.assertEqual(r["module_level_eager_calls"], ["STONES = build_stones()"])
        self.assertFalse(r["module_import_work_is_zero"])

    def test_22_effectful_source_method_default_call_is_rejected(self):
        source = PY.replace("    b: int",
                            "    b: int\n    def __init__(self, sauce_function=save(4)):\n        self.f = sauce_function")
        self.py_rejected(source, "effectful Python method default")

    def test_23_unreviewed_source_method_attribute_default_is_rejected(self):
        source = PY.replace("    b: int",
                            "    b: int\n    def __init__(self, factory=thing.property):\n        self.f = factory")
        self.py_rejected(source, "effectful Python method default")


if __name__ == "__main__":
    unittest.main()
