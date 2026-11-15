"""Changed calculation-day original year5000 comparator, pure adversarial tests."""
from __future__ import annotations
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

S=Path(__file__).resolve().parents[1]/"runner/compare_original_calculation_variation_v033.py"
spec=importlib.util.spec_from_file_location("changed_calculation_original_v033",S)
m=importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class ChangedCalculationYearBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.py=self.root/"python.json"
        self.kt=self.root/"kotlin.tsv"
        self.rows=[]
        for i,c in enumerate(m.CASES):
            o=-15057703-i*400
            cl=-15053459-i*400
            if not o < int(c) <= cl:
                o=int(c)-2000
                cl=int(c)+1000
            self.rows.append(dict(zip(m.FIELDS, (
                c,"5000",str(-4-i*2),str(4-i*2),
                str(o),str(cl),str(o+1),str(cl),str(cl-o)
            ))))
        self.emit()

    def emit(self):
        self.py.write_text(json.dumps(self.rows)+"\n",encoding="utf8")
        self.kt.write_text("".join(
            "\t".join(x[f] for f in m.FIELDS)+"\n" for x in self.rows),
            encoding="utf8",
        )

    def test_matching_alternate_native_boundaries_cannot_certify_soak(self):
        x=m.compare(self.py,self.kt)
        self.assertEqual(x["status"],"THREE_CALCULATION_NATIVE_YEAR_BOUNDS_MATCH_NOT_CERTIFIED")
        self.assertEqual(x["boundary_fields_exactly_compared"],27)
        self.assertIsNone(x["first_mismatch"])
        self.assertFalse(x["independent_oracle_certified"])
        self.assertEqual(x["full_date_native_calls"],0)
        self.assertEqual(x["original_full_year_soak_passes"],0)

    def test_changed_kotlin_geometry_can_fail_with_exact_coordinate(self):
        lines=self.kt.read_text().splitlines()
        parts=lines[1].split("\t")
        parts[2]=str(int(parts[2])-1)
        lines[1]="\t".join(parts)
        self.kt.write_text("\n".join(lines)+"\n",encoding="utf8")
        x=m.compare(self.py,self.kt)
        self.assertEqual(x["status"],"FIRST_NATIVE_CALCULATION_YEAR_BOUNDARY_MISMATCH_STOP")
        self.assertEqual(x["first_mismatch"]["calculation_day"],m.CASES[1])
        self.assertEqual(x["first_mismatch"]["column"],"open_gate_index")

    def test_bad_geometry_rejected(self):
        self.rows[0]["length_days"]="999"
        self.emit()
        with self.assertRaisesRegex(ValueError,"geometry"):
            m.compare(self.py,self.kt)

    def test_missing_native_row_fails_closed(self):
        self.kt.write_text("\n".join(self.kt.read_text().splitlines()[:-1])+"\n")
        with self.assertRaisesRegex(ValueError,"count"):
            m.compare(self.py,self.kt)

    def test_duplicate_json_key_rejected(self):
        with self.assertRaisesRegex(ValueError,"duplicate evidence"):
            m.load_json(b'{"x":1,"x":2}')


if __name__=="__main__":
    unittest.main()
