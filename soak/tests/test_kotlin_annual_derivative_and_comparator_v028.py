"""Pure isolation tests for v028 derivative generation and fail-first comparator."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]


def module(file, name):
    spec=importlib.util.spec_from_file_location(name, ROOT/file)
    obj=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj


derive=module("experiments/derive_kotlin_annual_stream_v028.py","derivative_generator_v028")
compare=module("runner/compare_two_derived_annual_streams_v028.py","derived_comparator_v028")


class KotlinDerivativeGeneratorTests(unittest.TestCase):
    def test_clone_original_unchanged_and_add_whole_year(self):
        native=(
            "package pastafari\nclass ProductionMonthWeavingEngine {\n"
            "    fun dayAt(rank1: BigInteger, targetOffset0: Int): Day {\n"
            '        require(targetOffset0 in 0 until totalDays) { "E_WEAVING_OFFSET" }\n'
            "        for (position in 0..targetOffset0) {\n"
            '            check(found) { "E_WEAVING_UNRANK" }\n'
            "        }\n"
            "        return Day(selected + 1, lengths[selected] - remaining[selected])\n"
            "    }\n\n}\n"
        )
        derived, original=derive.derive(native)
        self.assertIn(original,derived)
        self.assertEqual(derived.count("fun wholeYearAt("),1)
        self.assertEqual(derived.count("fun dayAt("),1)
        self.assertIn("for (position in 0 until totalDays)",derived)
        self.assertIn("transcript.add(Day(selected + 1",derived)
        self.assertIn("return transcript",derived)
        self.assertLess(derived.index("fun dayAt("),derived.index("fun wholeYearAt("))

    def test_source_shape_rejects_missing_original_require(self):
        bad=(
            "class A {\n"
            "    fun dayAt(rank1: BigInteger, targetOffset0: Int): Day {\n"
            "        for (position in 0..targetOffset0) {\n"
            '            check(found) { "E_WEAVING_UNRANK" }\n'
            "        }\n"
            "        return Day(selected + 1, lengths[selected] - remaining[selected])\n"
            "    }\n\n}\n"
        )
        with self.assertRaises(ValueError):
            derive.derive(bad)


class DerivedAnnualComparisonTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.py=self.root/"py.jsonl"
        self.kt=self.root/"kt.tsv"
        self.sample=self.root/"sample.json"
        self.first=-15057702
        self.n=4244
        self.fields=["5000","10","1","20","1"]
        self.py_lines=[]
        self.kt_lines=[]
        for i in range(self.n):
            c="-15055671"
            t=str(self.first+i)
            self.py_lines.append((json.dumps({
                "calculation_day":c,
                "target_day":t,
                "native_structure_derived_fields":self.fields,
            },sort_keys=True,separators=(",",":"))+"\n").encode("utf8"))
            self.kt_lines.append(("\t".join([c,t]+self.fields)+"\n").encode("utf8"))
        self.py.write_bytes(b"".join(self.py_lines))
        self.kt.write_bytes(b"".join(self.kt_lines))
        self.digest=hashlib.sha256(self.py.read_bytes()).hexdigest()
        self.metadata={
            "schema":"PASTAFARI_ANNUAL_REUSE_CROSS_NATIVE_SAMPLE_EVIDENCE/1",
            "status":"CROSS_ORIGINAL_KOTLIN_VS_DERIVED_PY_14_SAMPLE_MATCH_NOT_YEAR",
            "original_python_annual_derived_stream_sha256":self.digest,
            "original_kotlin_sample_matches":14,
            "original_python_sample_matches":14,
            "entire_year_cross_engine_compared":False,
            "verified_full_year_comparisons":0,
            "original_kotlin_production_commit":"0c703446d8a3b7435698bd16402ac5fa30e461c9",
            "original_python_source_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        }
        self.write_metadata()

    def write_metadata(self):
        self.sample.write_text(json.dumps(self.metadata),encoding="utf8")

    def run_comparison(self):
        with patch.object(compare,"PINNED_PYTHON_ANNUAL_SHA",self.digest):
            return compare.compare(self.py,self.kt,self.sample)

    def test_full_derived_stream_match_has_no_native_year_pass(self):
        d=self.run_comparison()
        self.assertEqual(d["status"],
            "TWO_DERIVED_4244_ROW_TRANSCRIPTS_MATCH_NOT_NATIVE_YEAR_CERTIFIED")
        self.assertEqual(d["rows_exactly_compared"],4244)
        self.assertIs(d["two_independent_original_full_year_transcripts_compared"],False)
        self.assertEqual(d["verified_full_year_soak_comparisons"],0)

    def test_first_difference_stops_at_exact_field(self):
        altered=self.kt_lines[:]
        altered[20]=altered[20].replace(b"\t10\t",b"\t11\t",1)
        self.kt.write_bytes(b"".join(altered))
        d=self.run_comparison()
        self.assertEqual(d["status"],"FIRST_MISMATCH_DATE_FIELDS_STOP")
        self.assertEqual(d["rows_exactly_compared"],20)
        self.assertEqual(d["first_mismatch"]["target"],str(self.first+20))
        self.assertEqual(d["first_mismatch"]["first_difference_column0"],3)

    def test_truncated_kotlin_stream_rejected(self):
        self.kt.write_bytes(b"".join(self.kt_lines[:-1]))
        d=self.run_comparison()
        self.assertEqual(d["status"],"FIRST_MISMATCH_STREAM_LENGTH_STOP")
        self.assertEqual(d["rows_exactly_compared"],4243)

    def test_extra_kotlin_row_rejected(self):
        self.kt.write_bytes(b"".join(self.kt_lines+[self.kt_lines[-1]]))
        d=self.run_comparison()
        self.assertEqual(d["status"],"FIRST_MISMATCH_STREAM_LENGTH_STOP")
        self.assertEqual(d["rows_exactly_compared"],4244)

    def test_tampered_python_blob_rejected_even_if_rows_match(self):
        self.py.write_bytes(self.py.read_bytes().replace(b'"5000"',b'"5001"',1))
        with self.assertRaisesRegex(ValueError,"source SHA"):
            self.run_comparison()

    def test_false_original_full_year_certificate_rejected(self):
        self.metadata["verified_full_year_comparisons"]=1
        self.write_metadata()
        with self.assertRaisesRegex(ValueError,"overcertified"):
            self.run_comparison()

    def test_duplicate_json_keys_rejected(self):
        with self.assertRaisesRegex(ValueError,"duplicate"):
            compare.strict_json(b'{"x":1,"x":2}')


if __name__=="__main__":
    unittest.main()
