"""v050 bounded two-engine ORIGINAL transcript gate with synthetic 2nd day.

The one-day fixture reproduces v045's observed bytes/values. All second-day
fixtures are artificial and NOT claims of a real F(c,t) output.
"""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from original_bounded_chunk_gate_v050 import (
    BOUNDARY_SHA,C,YEAR,YEAR_FIRST,YEAR_LAST,LIMIT,SCHEMA,
    EvidenceError,verify_bounded_original_chunk,
)

def name_tables():
    cutlets={f"synthetic-cutlet-{i}":i for i in range(1,18)}
    months={f"synthetic-month-{i}":i for i in range(1,48)}
    cutlets.pop("synthetic-cutlet-10")
    months.pop("synthetic-month-20")
    cutlets["Akrep"]=10
    months["Kuyu"]=20
    return cutlets,months

def original_python_row(t,cd,md):
    raw={
        "calculation_day":C,"target_day":str(t),
        "native_date_ids":{
            "year_number":YEAR,"cutlet_name_index":10,
            "day_in_cutlet":cd,"month_name_index":20,"day_in_month":md,
        },"native_names":{"cutlet":"Akrep","month":"Kuyu"},
    }
    raw_line=(json.dumps(raw,sort_keys=True,ensure_ascii=False,
                         separators=(",",":"))+"\n").encode("utf8")
    normalized={
        "calculation_day":C,"target_day":str(t),"year":YEAR,
        "cutlet_index":10,"day_in_cutlet":cd,
        "month_index":20,"day_in_month":md,
        "cutlet_name_raw":"Akrep","month_name_raw":"Kuyu",
        "source_raw_sha256":hashlib.sha256(raw_line).hexdigest(),
    }
    norm_line=(json.dumps(normalized,sort_keys=True,ensure_ascii=False,
                          separators=(",",":"))+"\n").encode("utf8")
    return raw_line,norm_line

def fixtures(days=1):
    raws=[];norms=[];kt=[]
    for i in range(days):
        t=-15055671+i
        raw,norm=original_python_row(t,503+i,56+i)
        raws.append(raw);norms.append(norm)
        kt.append((f"{C}\t{t}\t{YEAR}\t10\t{503+i}\t20\t{56+i}\n").encode())
    names=name_tables()
    return dict(
        python_original_raw=b"".join(raws),
        python_original_normalized=b"".join(norms),
        kotlin_original_stdout=b"".join(kt),
        calculation_day=C,year=YEAR,
        first_target_day="-15055671",
        last_target_day=str(-15055671+days-1),
        boundary_evidence_sha256=BOUNDARY_SHA,
        frozen_python_cutlets=names[0],
        frozen_python_months=names[1],
    )

class BoundedOriginalGateTests(unittest.TestCase):
    def test_pinned_one_day_fixture_exact_original_v045_source_sha(self):
        x=fixtures(1)
        self.assertEqual(hashlib.sha256(x["python_original_raw"]).hexdigest(),
            "bbad31d4bbc177c9c002423ccc3134dcb052c2eeff8e06290bb76b2c962c9173")
        self.assertEqual(hashlib.sha256(x["python_original_normalized"]).hexdigest(),
            "834cc548105faeadb99e5e3fb384d72e957d55c607847800f7cf0f0c8dc627c4")
        self.assertEqual(hashlib.sha256(x["kotlin_original_stdout"]).hexdigest(),
            "476676d64c9d514dfebd598df53cee8bfacf489422bf12d24d6492bf6bb41c34")
        out=verify_bounded_original_chunk(**x)
        self.assertEqual(out["status"],"BOUNDED_ORIGINAL_CHUNK_MATCH_NOT_FULL_YEAR")
        self.assertEqual(out["matched_original_day_pairs"],1)
        self.assertEqual(out["original_full_year_length"],4244)
        self.assertFalse(out["kotlin_native_names_reported"])
        self.assertEqual(out["original_full_year_soak_passes_certified"],0)
        rows=out["kotlin_index_only_normalized_jsonl"].splitlines()
        self.assertEqual(len(rows),1)
        row=json.loads(rows[0])
        self.assertEqual(row["cutlet_name_raw"],"10")
        self.assertEqual(row["month_name_raw"],"20")
        self.assertEqual(row["native_name_provenance"],
                         "INDEX_ONLY_NO_CYMRAEG_NAMES_IN_SOURCE")
        self.assertEqual(row["source_raw_sha256"],
                         hashlib.sha256(x["kotlin_original_stdout"]).hexdigest())

    def test_synthetic_two_days_both_original_shape_matches_without_year_credit(self):
        out=verify_bounded_original_chunk(**fixtures(2))
        self.assertEqual(out["matched_original_day_pairs"],2)
        self.assertFalse(out["halt_new_dispatch"])
        self.assertIsNone(out["first_mismatch"])
        self.assertEqual(len(out["kotlin_index_only_normalized_jsonl"].splitlines()),2)
        self.assertEqual(out["original_full_year_soak_passes_certified"],0)

    def test_second_original_day_mismatch_stops_before_recording_partial_stream(self):
        x=fixtures(2)
        x["kotlin_original_stdout"]=x["kotlin_original_stdout"].replace(
            b"\t504\t20\t57\n",b"\t504\t21\t57\n")
        out=verify_bounded_original_chunk(**x)
        self.assertEqual(out["status"],"ORIGINAL_NATIVE_FIRST_MISMATCH_HALT")
        self.assertEqual(out["matched_original_day_pairs"],1)
        self.assertEqual(out["first_mismatch"]["ordinal"],1)
        self.assertEqual(out["first_mismatch"]["target_day"],"-15055670")
        self.assertEqual(out["first_mismatch"]["first_different_field"],"month_index")
        self.assertTrue(out["halt_new_dispatch"])
        self.assertIsNone(out["kotlin_index_only_normalized_jsonl"])
        self.assertEqual(out["original_full_year_soak_passes_certified"],0)

    def test_mismatch_first_day_stops_with_zero_matching_days(self):
        x=fixtures()
        x["kotlin_original_stdout"]=x["kotlin_original_stdout"].replace(
            b"\t503\t",b"\t502\t")
        out=verify_bounded_original_chunk(**x)
        self.assertEqual(out["matched_original_day_pairs"],0)
        self.assertEqual(out["first_mismatch"]["first_different_field"],"day_in_cutlet")

    def test_truncated_native_kotlin_stream_fails_closed(self):
        x=fixtures(2);x["kotlin_original_stdout"]=x["kotlin_original_stdout"].splitlines(keepends=True)[0]
        with self.assertRaisesRegex(EvidenceError,"missing/duplicate"):
            verify_bounded_original_chunk(**x)

    def test_reordered_or_duplicated_native_kotlin_day_fails_closed(self):
        x=fixtures(2)
        lines=x["kotlin_original_stdout"].splitlines(keepends=True)
        x["kotlin_original_stdout"]=lines[0]+lines[0]
        with self.assertRaisesRegex(EvidenceError,"c/t/year"):
            verify_bounded_original_chunk(**x)

    def test_missing_last_python_raw_row_fails_closed(self):
        x=fixtures(2);x["python_original_raw"]=x["python_original_raw"].splitlines(keepends=True)[0]
        with self.assertRaisesRegex(EvidenceError,"missing/duplicate"):
            verify_bounded_original_chunk(**x)

    def test_tampered_python_source_line_digest_fails_closed(self):
        x=fixtures()
        x["python_original_raw"]=x["python_original_raw"].replace(b"Akrep",b"Other")
        with self.assertRaisesRegex(EvidenceError,"raw source invalid"):
            verify_bounded_original_chunk(**x)

    def test_forged_native_name_breaks_source_catalog(self):
        x=fixtures();x["frozen_python_cutlets"].pop("Akrep")
        x["frozen_python_cutlets"]["other-name"]=10
        with self.assertRaisesRegex(EvidenceError,"raw source invalid"):
            verify_bounded_original_chunk(**x)

    def test_no_cross_calculation_day(self):
        x=fixtures();x["calculation_day"]="-15055672"
        with self.assertRaisesRegex(EvidenceError,"c/year/boundary"):
            verify_bounded_original_chunk(**x)

    def test_no_cross_boundary_evidence(self):
        x=fixtures();x["boundary_evidence_sha256"]="0"*64
        with self.assertRaisesRegex(EvidenceError,"c/year/boundary"):
            verify_bounded_original_chunk(**x)

    def test_no_other_year_admission(self):
        x=fixtures();x["year"]="4999"
        with self.assertRaisesRegex(EvidenceError,"c/year/boundary"):
            verify_bounded_original_chunk(**x)

    def test_cannot_claim_entire_witnessed_year_by_setting_bounds_without_rows(self):
        x=fixtures()
        x["first_target_day"]=str(YEAR_FIRST)
        x["last_target_day"]=str(YEAR_LAST)
        with self.assertRaisesRegex(EvidenceError,"exceeds cap"):
            verify_bounded_original_chunk(**x)

    def test_outside_original_year_rejected(self):
        x=fixtures();x["first_target_day"]=str(YEAR_FIRST-1)
        with self.assertRaisesRegex(EvidenceError,"outside witnessed"):
            verify_bounded_original_chunk(**x)

    def test_kotlin_tsv_extra_column_rejected(self):
        x=fixtures();x["kotlin_original_stdout"]=x["kotlin_original_stdout"].replace(
            b"\n",b"\t8\n")
        with self.assertRaisesRegex(EvidenceError,"seven fields"):
            verify_bounded_original_chunk(**x)

    def test_kotlin_tsv_nonnumeric_rejected(self):
        x=fixtures();x["kotlin_original_stdout"]=x["kotlin_original_stdout"].replace(
            b"\t503\t",b"\tNaN\t")
        with self.assertRaisesRegex(EvidenceError,"noncanonical"):
            verify_bounded_original_chunk(**x)

    def test_kotlin_original_names_not_fabricated(self):
        x=fixtures();out=verify_bounded_original_chunk(**x)
        payload=json.loads(out["kotlin_index_only_normalized_jsonl"])
        self.assertNotEqual(payload["cutlet_name_raw"],"Akrep")
        self.assertNotEqual(payload["month_name_raw"],"Kuyu")
        self.assertFalse(out["canonical_oracle_certified"])
        self.assertFalse(out["algorithmic_independence_certified"])

    def test_oversized_raw_output_blocked(self):
        x=fixtures()
        x["python_original_raw"]+=b"a"*16384
        with self.assertRaisesRegex(EvidenceError,"framing or size"):
            verify_bounded_original_chunk(**x)

    def test_invalid_python_name_map_rejected(self):
        x=fixtures();x["frozen_python_months"].clear()
        with self.assertRaisesRegex(EvidenceError,"name tables"):
            verify_bounded_original_chunk(**x)

if __name__=="__main__":
    unittest.main()
