"""Pure fail-closed tests for experimental alternate-c 3569-row two-source pairing."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

F=Path(__file__).resolve().parents[1]/"runner/compare_annual_alternate_calculation_v034.py"
spec=importlib.util.spec_from_file_location("alt_c_annual_comparator_v034",F)
mod=importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


class AlternateCalculationAnnualTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.py=self.root/"python-year"
        self.py.mkdir()
        self.k=self.root/"derived-kotlin.tsv"
        self.original=self.root/"original-kotlin.tsv"
        self.lines=[]
        self.targets=[
            str(mod.FIRST),str(mod.FIRST+1),str(mod.FIRST+mod.ROWS//3),
            mod.C,str(mod.FIRST+(2*mod.ROWS)//3),
            str(mod.LAST-1),str(mod.LAST)
        ]
        for target in range(mod.FIRST,mod.LAST+1):
            self.lines.append("\t".join([
                mod.C,str(target),"5000","10","1","20","1"
            ])+"\n")
        payload="".join(self.lines).encode()
        (self.py/"python-derived-year5000-alternate-c.tsv").write_bytes(payload)
        self.k.write_bytes(payload)
        self.original.write_text("".join(
            self.lines[int(x)-mod.FIRST] for x in self.targets
        ))
        self.receipt={
            "schema":"PASTAFARI_ALTERNATE_C_PYTHON_ANNUAL_DERIVATIVE_V034/1",
            "status":"ALTERNATE_C_PY_3569_DERIVED_ROWS_SAMPLED_ORIGINAL_NOT_FULL_YEAR",
            "calculation_day":mod.C,
            "first_target_day":str(mod.FIRST),
            "last_target_day":str(mod.LAST),
            "derived_rows":mod.ROWS,
            "original_native_sample_matches":7,
            "original_native_sample_targets":self.targets,
            "all_3569_original_fct_calls_executed":False,
            "verified_original_full_years":0,
            "algorithmic_independence_certified":False,
            "soak_started":False,
            "derived_tsv_sha256":hashlib.sha256(payload).hexdigest(),
            "original_source_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        }
        self.save()

    def save(self):
        (self.py/"receipt.json").write_text(json.dumps(self.receipt))

    def test_all_3569_derived_rows_match_is_not_original_year(self):
        z=mod.evidence(self.py,self.k,self.original)
        self.assertEqual(z["status"],
            "ALTERNATE_C_3569_DERIVED_ROWS_MATCH_SAMPLED_NATIVE_NOT_CERTIFIED")
        self.assertEqual(z["derived_rows_matched"],3569)
        self.assertEqual(z["derived_fields_matched"],24983)
        self.assertEqual(z["original_kotlin_native_sample_matches"],7)
        self.assertFalse(z["original_native_3569_calls_per_engine_executed"])
        self.assertEqual(z["full_original_Fct_years_passed"],0)

    def test_first_mismatch_recorded(self):
        lines=self.k.read_text().splitlines()
        row=lines[12].split("\t")
        row[3]="11"
        lines[12]="\t".join(row)
        self.k.write_text("\n".join(lines)+"\n")
        result=mod.evidence(self.py,self.k,self.original)
        self.assertEqual(result["status"],"FIRST_MISMATCH_DERIVED_FIELDS_STOP")
        self.assertEqual(result["derived_rows_matched"],12)
        self.assertEqual(result["first_mismatch"]["first_difference_column0"],3)

    def test_missing_row_fails_closed(self):
        self.k.write_text("".join(self.lines[:-1]))
        result=mod.evidence(self.py,self.k,self.original)
        self.assertEqual(result["status"],"FIRST_MISMATCH_MISSING_ROW_STOP")
        self.assertEqual(result["derived_rows_matched"],3568)

    def test_invalid_python_hash_rejected(self):
        self.receipt["derived_tsv_sha256"]="0"*64
        self.save()
        with self.assertRaisesRegex(ValueError,"tampered"):
            mod.evidence(self.py,self.k,self.original)

    def test_first_original_sample_mismatch_fails(self):
        lines=self.original.read_text().splitlines()
        parts=lines[0].split("\t")
        parts[-1]="2"
        lines[0]="\t".join(parts)
        self.original.write_text("\n".join(lines)+"\n")
        result=mod.evidence(self.py,self.k,self.original)
        self.assertEqual(result["status"],"FIRST_MISMATCH_UNMODIFIED_KOTLIN_FCT_SAMPLE_STOP")
        self.assertEqual(result["original_kotlin_native_sample_matches"],0)

    def test_false_original_full_year_certification_rejected(self):
        self.receipt["all_3569_original_fct_calls_executed"]=True
        self.save()
        with self.assertRaisesRegex(ValueError,"overcertified"):
            mod.evidence(self.py,self.k,self.original)


if __name__=="__main__":
    unittest.main()
