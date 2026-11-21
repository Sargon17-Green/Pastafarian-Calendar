#!/usr/bin/env python3
"""v152 source-only callsite regression tests. No date calculations performed."""
from __future__ import annotations
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from soak_static_name_output_path_v152 import (
    PY_RETURN, JS_IMPORT, JS_EXPORT, python_return_witness, js_return_witness
)

PY_GOOD = PY_RETURN + """
    def calendar_date_ids(self, calculation_day: int, target_day: int):
        pass
"""
JS_GOOD = """'use strict';
""" + JS_IMPORT + """
function calendarDate(calculationDay, targetDay) {
  const year = { number: 5000n };
  const chosenCutlet = { nameIndex: 10 };
  const dayInCutlet = 503n;
  const monthNameIndex = 20;
  const dayInMonth = 56n;
  return Object.freeze([
    year.number,
    textByCanonicalIndex('cutlet', chosenCutlet.nameIndex),
    dayInCutlet,
    textByCanonicalIndex('month', monthNameIndex),
    dayInMonth
  ]);
}
""" + JS_EXPORT + """
  SourceLanguageCatalog, calendarDate
});
"""
CAT_GOOD = """'use strict';
const SourceLanguageCatalog = Object.freeze({cutlets: CUTLETS, months: MONTHS});
function textByCanonicalIndex(group, canonicalIndex) {
  const rows = group === 'cutlet' ? SourceLanguageCatalog.cutlets : group === 'month' ? SourceLanguageCatalog.months : null;
  if (rows === null) throw Error('invalid catalog');
  return rows[canonicalIndex - 1].text;
}
module.exports = Object.freeze({ SourceLanguageCatalog, textByCanonicalIndex });
"""


class NativeOutputPathWitnessTests(unittest.TestCase):
    def p(self, source=PY_GOOD):
        return python_return_witness(source)

    def j(self, source=JS_GOOD, catalog=CAT_GOOD):
        return js_return_witness(source, catalog)

    def test_01_exact_python_source_name_return_witness(self):
        w=self.p()
        self.assertEqual(w["engine_id"],"REF-41")
        self.assertTrue(w["ast_callsite_witness"])
        self.assertIn("FROZEN_MONTH_NAMES",w["month_lookup"])

    def test_02_exact_js_source_name_return_witness(self):
        w=self.j()
        self.assertEqual(w["engine_id"],"REF-24")
        self.assertTrue(w["source_callsite_lexical_witness"])
        self.assertIn("textByCanonicalIndex",w["month_lookup"])

    def test_03_python_cutlet_index_swapped_rejected(self):
        source=PY_GOOD.replace("ids.cutlet_name_index - 1","ids.month_name_index - 1")
        with self.assertRaisesRegex(ValueError,"does not bind"):
            self.p(source)

    def test_04_python_month_name_from_wrong_table_rejected(self):
        source=PY_GOOD.replace("FROZEN_MONTH_NAMES[","FROZEN_CUTLET_NAMES[")
        with self.assertRaisesRegex(ValueError,"does not bind"):
            self.p(source)

    def test_05_python_cutlet_name_position_swapped_rejected(self):
        source=PY_GOOD.replace("ids.year_number,\n            FROZEN_CUTLET_NAMES",
                               "ids.day_in_cutlet,\n            FROZEN_CUTLET_NAMES")
        with self.assertRaisesRegex(ValueError,"does not bind"):
            self.p(source)

    def test_06_python_month_index_offset_mutation_rejected(self):
        source=PY_GOOD.replace("ids.month_name_index - 1","ids.month_name_index")
        with self.assertRaisesRegex(ValueError,"does not bind"):
            self.p(source)

    def test_07_python_calendar_date_method_rebound_rejected(self):
        source=PY_GOOD + "\n    def calendar_date(self, calculation_day, target_day):\n        return 0\n"
        with self.assertRaisesRegex(ValueError,"not unique"):
            self.p(source)

    def test_08_python_missing_numeric_id_method_rejected(self):
        source=PY_RETURN
        with self.assertRaisesRegex(ValueError,"not unique"):
            self.p(source)

    def test_09_python_other_name_class_rejected(self):
        source=PY_GOOD.replace("class NormativeCalendar:", "class WrapperCalendar:")
        with self.assertRaisesRegex(ValueError,"class not unique"):
            self.p(source)

    def test_10_js_wrong_cutlet_source_rejected(self):
        source=JS_GOOD.replace("chosenCutlet.nameIndex","monthNameIndex")
        with self.assertRaisesRegex(ValueError,"not sourced"):
            self.j(source)

    def test_11_js_wrong_month_source_rejected(self):
        source=JS_GOOD.replace("('month', monthNameIndex)","('cutlet', monthNameIndex)")
        with self.assertRaisesRegex(ValueError,"not sourced"):
            self.j(source)

    def test_12_js_result_order_mutation_rejected(self):
        source=JS_GOOD.replace("    dayInCutlet,\n", "    dayInMonth,\n")
        with self.assertRaisesRegex(ValueError,"not sourced"):
            self.j(source)

    def test_13_js_missing_source_import_rejected(self):
        source=JS_GOOD.replace(JS_IMPORT,"")
        with self.assertRaisesRegex(ValueError,"import not unique"):
            self.j(source)

    def test_14_js_unexported_function_rejected(self):
        source=JS_GOOD.replace("SourceLanguageCatalog, calendarDate","SourceLanguageCatalog")
        with self.assertRaisesRegex(ValueError,"not exported"):
            self.j(source)

    def test_15_js_duplicate_calendar_date_definition_rejected(self):
        source=JS_GOOD.replace(JS_EXPORT,"function calendarDate() {}\n"+JS_EXPORT)
        with self.assertRaisesRegex(ValueError,"not unique"):
            self.j(source)

    def test_16_js_dictionary_getter_off_by_one_rejected(self):
        catalog=CAT_GOOD.replace("rows[canonicalIndex - 1].text","rows[canonicalIndex].text")
        with self.assertRaisesRegex(ValueError,"not linked"):
            self.j(catalog=catalog)

    def test_17_js_dictionary_getter_wrong_source_rejected(self):
        catalog=CAT_GOOD.replace("SourceLanguageCatalog.months","SourceLanguageCatalog.cutlets")
        with self.assertRaisesRegex(ValueError,"not linked"):
            self.j(catalog=catalog)

    def test_18_js_duplicate_dictionary_lookup_definition_rejected(self):
        catalog=CAT_GOOD+"\nfunction textByCanonicalIndex() { return null; }\n"
        with self.assertRaisesRegex(ValueError,"not unique"):
            self.j(catalog=catalog)

    def test_19_js_catalog_not_exported_rejected(self):
        catalog=CAT_GOOD.replace("SourceLanguageCatalog, textByCanonicalIndex","textByCanonicalIndex")
        with self.assertRaisesRegex(ValueError,"not linked"):
            self.j(catalog=catalog)

    def test_20_js_date_result_not_frozen_array_rejected(self):
        source=JS_GOOD.replace("return Object.freeze([","return [")
        with self.assertRaisesRegex(ValueError,"not sourced"):
            self.j(source)


if __name__=="__main__":
    unittest.main()
