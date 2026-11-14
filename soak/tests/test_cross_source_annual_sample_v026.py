from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

PATH=Path(__file__).resolve().parents[1]/"runner/compare_kotlin_vs_annual_python_v026.py"
spec=importlib.util.spec_from_file_location("cross_source_sample_v026",PATH)
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

FIRST=-15057702
CALC=-15055671
N=4244
FIELDS=["5000","10","1","20","1"]


def emit(obj):
    return (json.dumps(obj,sort_keys=True,separators=(",",":"))+"\n").encode()


class KotlinCrossSamplePureTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.annual=self.root/"derived-year"
        self.annual.mkdir()
        self.targets=[str(FIRST+i*300) for i in range(14)]
        self.data=b"".join(emit({
            "calculation_day":str(CALC),
            "target_day":str(FIRST+i),
            "native_structure_derived_fields":FIELDS,
        }) for i in range(N))
        self.hash=hashlib.sha256(self.data).hexdigest()
        (self.annual/"derived_python_year5000_all_days.jsonl").write_bytes(self.data)
        self.receipt={
            "schema":"PASTAFARI_DERIVED_ANNUAL_PYTHON_NATIVE_STRUCTURE_V025/1",
            "status":"DERIVED_YEAR_TRANSCRIPT_SAMPLED_NATIVE_MATCH_NOT_CERTIFIED",
            "original_source_commit":mod.COMMIT_PY,
            "derived_stream_sha256":self.hash,
            "native_original_sample_count":14,
            "first_sample_mismatch":None,
            "independent_calendar_oracle_certified":False,
            "all_year_days_compared_to_original":False,
            "verified_full_year_comparisons":0,
            "soak_started":False,
            "native_original_compared_targets":self.targets,
            "derived_rows":N,
            "first_target_day":str(FIRST),
            "last_target_day":str(FIRST+N-1),
            "calculation_day":str(CALC),
        }
        self.save_receipt()
        self.kotlin=self.root/"kotlin.tsv"
        self.kotlin.write_text("".join("\t".join([str(CALC),target]+FIELDS)+"\n" for target in self.targets))

    def save_receipt(self):
        (self.annual/"derivation_receipt.json").write_text(json.dumps(self.receipt))

    def test_matching_native_sample_can_never_certify_year(self):
        with patch.object(mod,"ANNUAL_DIGEST",self.hash):
            result=mod.compare(self.annual,self.kotlin)
        self.assertEqual(result["status"],"CROSS_ORIGINAL_KOTLIN_VS_DERIVED_PY_14_SAMPLE_MATCH_NOT_YEAR")
        self.assertEqual(result["samples_compared"],14)
        self.assertEqual(result["numeric_date_fields_compared"],70)
        self.assertEqual(result["input_plus_date_fields_compared"],98)
        self.assertIs(result["full_year_cross_engine_verified"],False)

    def test_first_mismatch_stops_comparison_and_records_field(self):
        text=self.kotlin.read_text()
        self.kotlin.write_text(text.replace("\t5000\t10\t1\t20\t1\n",
                                               "\t5000\t10\t2\t20\t1\n",1))
        with patch.object(mod,"ANNUAL_DIGEST",self.hash):
            result=mod.compare(self.annual,self.kotlin)
        self.assertEqual(result["status"],"FIRST_NATIVE_KOTLIN_SAMPLE_MISMATCH_STOP")
        self.assertEqual(result["samples_compared"],0)
        self.assertEqual(result["first_mismatch"]["first_difference_column"],4)

    def test_mismatching_python_raw_hash_is_rejected(self):
        with self.kotlin.open("a") as f: f.write("")
        changed=self.data.replace(b'"5000"',b'"5001"',1)
        (self.annual/"derived_python_year5000_all_days.jsonl").write_bytes(changed)
        with patch.object(mod,"ANNUAL_DIGEST",self.hash):
            with self.assertRaisesRegex(ValueError,"hash incomplete"):
                mod.compare(self.annual,self.kotlin)

    def test_kotlin_duplicate_day_is_rejected(self):
        lines=self.kotlin.read_text().splitlines()
        lines[2]=lines[1]
        self.kotlin.write_text("\n".join(lines)+"\n")
        with patch.object(mod,"ANNUAL_DIGEST",self.hash):
            with self.assertRaisesRegex(ValueError,"duplicate"):
                mod.compare(self.annual,self.kotlin)

    def test_forbidden_false_full_year_receipt_is_rejected(self):
        self.receipt["all_year_days_compared_to_original"]=True
        self.save_receipt()
        with patch.object(mod,"ANNUAL_DIGEST",self.hash):
            with self.assertRaisesRegex(ValueError,"falsely certified"):
                mod.compare(self.annual,self.kotlin)

    def test_duplicate_json_keys_are_rejected(self):
        with self.assertRaisesRegex(ValueError,"duplicate JSON key"):
            mod.parse_json(b'{"a":1,"a":2}')


if __name__=="__main__":
    unittest.main()
