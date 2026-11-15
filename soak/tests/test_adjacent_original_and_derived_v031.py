"""Pure fail-first contracts for adjacent native boundaries and annual DERIVATIVES.

Never turns Python/Kotlin annual structure outputs into unmodified original
F(c,t) comparisons. Synthetic test rows are not canonical calendar evidence.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]

def load(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    obj=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj

bounds=load("adjacent_bounds_v030","runner/compare_adjacent_original_bounds_v030.py")
annual=load("adjacent_years_v031","runner/compare_adjacent_derived_years_v031.py")

NATIVE={
    4999:{"open_gate_index":"-12","close_gate_index":"-4",
          "open_gate_day":"-15061829","close_gate_day":"-15057703"},
    5000:{"open_gate_index":"-4","close_gate_index":"4",
          "open_gate_day":"-15057703","close_gate_day":"-15053459"},
    5001:{"open_gate_index":"4","close_gate_index":"14",
          "open_gate_day":"-15053459","close_gate_day":"-15047892"},
}

class AdjacentEvidencePureTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.d=self.root/"py"
        self.d.mkdir()
        self.kt=self.root/"kt.tsv"
        self.ks=self.root/"sample.tsv"
        self.names=("calculation_day","year","open_gate_index","close_gate_index",
                    "open_gate_day","close_gate_day","first_target_day",
                    "last_target_day","length_days")
        self.boundaries=[]
        for y,v in NATIVE.items():
            o,c=int(v["open_gate_day"]),int(v["close_gate_day"])
            self.boundaries.append({"calculation_day":"-15055671","year":str(y),
                **v,"first_target_day":str(o+1),"last_target_day":str(c),
                "length_days":str(c-o)})
        self.py_bound=self.root/"original-py.json"
        self.kt_bound=self.root/"original-kt.tsv"
        self.py_bound.write_text(json.dumps(self.boundaries),encoding="utf8")
        self.kt_bound.write_text("".join(
            "\t".join(row[k] for k in self.names)+"\n" for row in self.boundaries),
            encoding="utf8")
        self.receipt={
            "schema":"PASTAFARI_TWO_ADJACENT_PY_DERIVED_ANNUAL_V031/1",
            "status":"TWO_ADJACENT_PY_ANNUAL_TRANSCRIPTS_SAMPLED_NATIVE_MATCH_NOT_FULL_YEAR",
            "calculation_day":"-15055671",
            "original_full_year_native_comparisons":0,
            "original_source_not_modified":True,
            "all_days_recomputed_via_original_fct":False,
            "independent_canonical_oracle_certified":False,
            "soak_started":False,
            "years":[],
        }
        kt_stream=[]
        sample_stream=[]
        for year,(first,last) in annual.YEARS.items():
            source=[]
            targets=[first,first+1,first+(last-first)//3,
                     first+(last-first)*2//3,last-1,last]
            for t in range(first,last+1):
                row=["-15055671",str(t),str(year),"10","1","20","1"]
                source.append("\t".join(row)+"\n")
                if t in targets:
                    sample_stream.append(row)
            raw="".join(source).encode("utf8")
            (self.d/f"python-derived-{year}.tsv").write_bytes(raw)
            self.receipt["years"].append({
                "year":str(year),"first_target_day":str(first),
                "last_target_day":str(last),
                "derived_rows":last-first+1,
                "derived_sha256":hashlib.sha256(raw).hexdigest(),
                "direct_original_fct_sample_matches":6,
                "direct_original_fct_targets":[str(x) for x in targets],
            })
            kt_stream.extend(source)
        self.kt.write_text("".join(kt_stream),encoding="utf8")
        self.ks.write_text("".join("\t".join(x)+"\n" for x in sample_stream),encoding="utf8")
        self.save()

    def save(self):
        (self.d/"receipt.json").write_text(json.dumps(self.receipt),encoding="utf8")

    def test_native_three_year_original_boundaries_match(self):
        r=bounds.candidate(self.py_bound,self.kt_bound)
        self.assertEqual(r["boundary_fields_compared"],27)
        self.assertIsNone(r["first_mismatch"])
        self.assertIs(r["canonical_oracle_certified"],False)
        self.assertEqual(r["original_full_year_date_comparisons"],0)

    def test_adjacent_original_boundary_first_mismatch(self):
        lines=self.kt_bound.read_text().splitlines()
        fields=lines[0].split("\t")
        fields[2]="-11"
        lines[0]="\t".join(fields)
        self.kt_bound.write_text("\n".join(lines)+"\n")
        r=bounds.candidate(self.py_bound,self.kt_bound)
        self.assertEqual(r["status"],"FIRST_NATIVE_ADJACENT_YEAR_BOUNDARY_MISMATCH_STOP")

    def test_full_derived_9693_match_is_not_original_soak(self):
        r=annual.compare(self.d,self.kt,self.ks)
        self.assertEqual(r["status"],
            "TWO_ADJACENT_DERIVED_YEARS_9693_ROWS_MATCH_NATIVE_SAMPLED_NOT_CERTIFIED")
        self.assertEqual(r["derived_rows_compared"],9693)
        self.assertEqual(r["fully_compared_derived_years"],2)
        self.assertEqual(r["kotlin_original_sample_matches"],12)
        self.assertIs(r["original_native_all_year_days_executed"],False)
        self.assertEqual(r["verified_original_soak_full_year_comparisons"],0)

    def test_first_mismatch_exact_offset_and_nonapproval(self):
        lines=self.kt.read_text().splitlines()
        row=lines[100].split("\t")
        row[3]="11"
        lines[100]="\t".join(row)
        self.kt.write_text("\n".join(lines)+"\n")
        r=annual.compare(self.d,self.kt,self.ks)
        self.assertEqual(r["status"],"FIRST_MISMATCH_DERIVED_DATE_FIELDS_STOP")
        self.assertEqual(r["derived_rows_compared"],100)
        self.assertEqual(r["first_mismatch"]["difference_column0"],3)
        self.assertEqual(r["verified_original_soak_full_year_comparisons"],0)

    def test_truncated_derived_kotlin_stream_rejected(self):
        lines=self.kt.read_text().splitlines()
        self.kt.write_text("\n".join(lines[:-1])+"\n")
        r=annual.compare(self.d,self.kt,self.ks)
        self.assertEqual(r["status"],"FIRST_MISMATCH_MISSING_DERIVED_ROW_STOP")
        self.assertEqual(r["derived_rows_compared"],9692)

    def test_tampered_python_derived_file_hash_rejected(self):
        p=self.d/"python-derived-4999.tsv"
        p.write_bytes(p.read_bytes().replace(b"\t10\t",b"\t11\t",1))
        with self.assertRaisesRegex(ValueError,"SHA mismatch"):
            annual.compare(self.d,self.kt,self.ks)

    def test_false_original_year_verification_rejected(self):
        self.receipt["original_full_year_native_comparisons"]=1
        self.save()
        with self.assertRaisesRegex(ValueError,"falsely promoted"):
            annual.compare(self.d,self.kt,self.ks)

    def test_original_kotlin_sample_mismatch_rejected(self):
        lines=self.ks.read_text().splitlines()
        row=lines[0].split("\t")
        row[-1]="2"
        lines[0]="\t".join(row)
        self.ks.write_text("\n".join(lines)+"\n")
        r=annual.compare(self.d,self.kt,self.ks)
        self.assertEqual(r["status"],"FIRST_MISMATCH_ORIGINAL_KOTLIN_FCT_SAMPLE_STOP")
        self.assertEqual(r["kotlin_original_sample_matches"],0)


if __name__=="__main__":
    unittest.main()
