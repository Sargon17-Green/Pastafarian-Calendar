#!/usr/bin/env python3
"""Pure synthetic regression suite for v149 raw-bound whole-year comparison."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from native_execution_receipt_v038 import canonical, make_receipt
from soak_raw_bound_year_diff_v149 import SCHEMA, audit
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def mock_plan():
    def engine(name, marker, family, source_class):
        return {
            "id": name, "algorithm_id": family,
            "source_sha256": marker * 64,
            "binary_sha256": ("a" if marker == "1" else "b") * 64,
            "name_map_sha256": "d" * 64,
            "provenance": {
                "schema": IDENTITY_SCHEMA, "source_class": source_class,
                "source_commit": marker * 40,
                "repository": "Sargon17-Green/Pastafarian-Calendar",
                "source_path": "tests/" + name + ".py",
                "source_family": family,
                "native_entrypoint": name + ".F(c,t)",
                "execution_method": ("unchanged_reference_Fct" if source_class == "reference"
                                     else "unchanged_original_Fct"),
                "derived_from": None, "original_source_sha256": marker * 64
            }
        }
    return {
        "contract": PROVENANCE_CONTRACT, "identity_contract": IDENTITY_SCHEMA,
        "soak_purpose": "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status": "NOT_CERTIFIED",
        "calculation_day": "-15055672", "chunk_days": 2,
        "years": [{
            "year": "5000", "first_target_day": "-15056173",
            "last_target_day": "-15056170",
            "boundary_evidence_sha256": "f" * 64
        }],
        "engines": [
            engine("synthetic-a", "1", "synthetic-algo-a", "reference"),
            engine("synthetic-b", "2", "synthetic-algo-b", "original")
        ]
    }


class BoundWholeYearTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="soak-v149-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.plan = mock_plan()
        self.manifest = {
            "schema": SCHEMA, "year": "5000",
            "engine_a": "synthetic-a", "engine_b": "synthetic-b",
            "bundles": {"synthetic-a": [], "synthetic-b": []}
        }
        for engine in ("synthetic-a", "synthetic-b"):
            for i in range(2):
                self.make_bundle(engine, i)

    def make_bundle(self, engine, ordinal):
        first = -15056173 + 2 * ordinal
        raw = []
        rows = []
        for k in range(2):
            t = str(first + k)
            line = (engine + "\t" + t + "\t5000\t10\t503\t20\t56\n").encode("utf-8")
            raw.append(line)
            rows.append({
                "calculation_day": "-15055672", "target_day": t, "year": "5000",
                "cutlet_index": 10, "day_in_cutlet": 503 + ordinal * 2 + k,
                "month_index": 20, "day_in_month": 56 + ordinal * 2 + k,
                "cutlet_name_raw": "כליה" if engine == "synthetic-a" else "kidney",
                "month_name_raw": "חודש" if engine == "synthetic-a" else "month",
                "source_raw_sha256": hashlib.sha256(line).hexdigest()
            })
        raw_bytes = b"".join(raw)
        norm_bytes = b"".join(canonical(row) + b"\n" for row in rows)
        p = self.root / f"{engine}-{ordinal}"
        p.mkdir(exist_ok=True)
        paths = {
            "ordinal": ordinal,
            "raw_path": str(p / "raw.stdout"),
            "normalized_path": str(p / "normalized.jsonl"),
            "receipt_path": str(p / "native-receipt.json")
        }
        Path(paths["raw_path"]).write_bytes(raw_bytes)
        Path(paths["normalized_path"]).write_bytes(norm_bytes)
        plan_sha = hashlib.sha256(canonical(self.plan)).hexdigest()
        receipt = make_receipt(
            self.plan, plan_sha, engine, "5000",
            str(first), str(first + 1), ordinal, norm_bytes, raw_bytes
        )
        Path(paths["receipt_path"]).write_bytes(canonical(receipt) + b"\n")
        self.manifest["bundles"][engine].append(paths)

    def paths(self, engine="synthetic-b", ordinal=0):
        return self.manifest["bundles"][engine][ordinal]

    def mutate_receipt(self, field, value, engine="synthetic-b", ordinal=0):
        path = Path(self.paths(engine, ordinal)["receipt_path"])
        receipt = json.loads(path.read_bytes())
        receipt[field] = value
        path.write_bytes(canonical(receipt) + b"\n")

    def mutate_normalized(self, field, value, *, engine="synthetic-b",
                          ordinal=0, day_index=0, rebuild=False):
        paths = self.paths(engine, ordinal)
        norm = Path(paths["normalized_path"])
        rows = [json.loads(x) for x in norm.read_bytes().splitlines()]
        rows[day_index][field] = value
        norm_bytes = b"".join(canonical(row) + b"\n" for row in rows)
        norm.write_bytes(norm_bytes)
        if rebuild:
            raw = Path(paths["raw_path"]).read_bytes()
            receipt = json.loads(Path(paths["receipt_path"]).read_bytes())
            new_receipt = make_receipt(
                self.plan, hashlib.sha256(canonical(self.plan)).hexdigest(),
                engine, "5000", receipt["first_target_day"], receipt["last_target_day"],
                ordinal, norm_bytes, raw
            )
            Path(paths["receipt_path"]).write_bytes(canonical(new_receipt) + b"\n")

    def result(self):
        return audit(self.plan, self.manifest)

    def assert_invalid(self, contains=None):
        result = self.result()
        self.assertEqual(result["status"], "INVALID_EVIDENCE", result)
        self.assertFalse(result["technically_equal_complete_year"])
        self.assertTrue(result["halt_new_native_soak_dispatch"])
        self.assertEqual(result["original_years_certified"], 0)
        if contains is not None:
            self.assertIn(contains, result["error"])
        return result

    def test_01_all_four_days_two_chunks_per_engine_agree_without_certification(self):
        r = self.result()
        self.assertEqual(r["status"], "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED", r)
        self.assertTrue(r["technically_equal_complete_year"])
        self.assertEqual(r["fully_matched_days"], 4)
        self.assertEqual(r["total_day_pairs"], 4)
        self.assertEqual(len(r["raw_evidence_receipts"]), 2)
        self.assertEqual(len(r["raw_evidence_receipts"][0]["chunks"]), 2)
        self.assertFalse(r["trusted_execution_attested"])
        self.assertFalse(r["source_lineage_independence_verified"])
        self.assertEqual(r["original_converters_executed"], 0)
        self.assertEqual(r["original_years_certified"], 0)
        self.assertFalse(r["official_soak_10000_pass"])

    def test_02_different_original_language_names_not_a_numeric_difference(self):
        self.assertEqual(self.result()["status"], "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED")

    def test_03_changed_raw_byte_breaks_per_row_SHA_link(self):
        p = Path(self.paths()["raw_path"])
        p.write_bytes(p.read_bytes().replace(b"synthetic-b", b"synthetic-x", 1))
        self.assert_invalid("source_raw_sha256")

    def test_04_modified_normalized_byte_breaks_receipt(self):
        self.mutate_normalized("month_index", 30)
        self.assert_invalid("receipt contradicts")

    def test_05_rebuilt_consistent_receipt_does_not_hide_numeric_first_difference(self):
        self.mutate_normalized("month_index", 30, rebuild=True)
        r = self.result()
        self.assertEqual(r["status"], "FIRST_NUMERIC_DIFFERENCE", r)
        self.assertEqual(r["first_mismatch_target_day"], "-15056173")
        self.assertEqual(r["fully_matched_days"], 0)
        self.assertEqual(r["first_numeric_field_difference"]["field"], "month_index")
        self.assertEqual(r["first_numeric_field_difference"]["engine_a_value"], 20)
        self.assertEqual(r["first_numeric_field_difference"]["engine_b_value"], 30)

    def test_06_late_difference_exact_day_after_first_chunk(self):
        self.mutate_normalized("day_in_month", 99, ordinal=1, day_index=1, rebuild=True)
        r = self.result()
        self.assertEqual(r["status"], "FIRST_NUMERIC_DIFFERENCE", r)
        self.assertEqual(r["first_mismatch_target_day"], "-15056170")
        self.assertEqual(r["fully_matched_days"], 3)

    def test_07_receipt_source_commit_spoof_rejected(self):
        self.mutate_receipt("source_commit", "f" * 40)
        self.assert_invalid("receipt contradicts")

    def test_08_receipt_binary_SHA_spoof_rejected(self):
        self.mutate_receipt("binary_sha256", "f" * 64)
        self.assert_invalid("receipt contradicts")

    def test_09_receipt_raw_stream_SHA_spoof_rejected(self):
        self.mutate_receipt("raw_stdout_sha256", "f" * 64)
        self.assert_invalid("receipt contradicts")

    def test_10_receipt_wrong_engine_rejected(self):
        self.mutate_receipt("engine_id", "synthetic-a")
        self.assert_invalid("different engine identity")

    def test_11_receipt_claims_official_certification_rejected(self):
        self.mutate_receipt("official_soak_authorized", True)
        self.assert_invalid("receipt contradicts")

    def test_12_missing_final_chunk_rejected(self):
        self.manifest["bundles"]["synthetic-b"].pop()
        self.assert_invalid("incomplete original year")

    def test_13_duplicate_chunk_ordinal_rejected(self):
        self.paths("synthetic-b", 1)["ordinal"] = 0
        self.assert_invalid("out-of-order chunk ordinal")

    def test_14_reverse_chunk_order_rejected(self):
        self.manifest["bundles"]["synthetic-b"].reverse()
        self.assert_invalid("out-of-order chunk ordinal")

    def test_15_physical_raw_file_alias_between_engines_rejected(self):
        self.paths()["raw_path"] = self.paths("synthetic-a")["raw_path"]
        self.assert_invalid("same physical evidence file reused")

    def test_16_symlink_raw_alias_rejected(self):
        other = self.root / "alias-raw"
        try:
            other.symlink_to(self.paths("synthetic-a")["raw_path"])
        except (OSError, NotImplementedError) as exc:
            self.skipTest("symlink unsupported: " + str(exc))
        self.paths()["raw_path"] = str(other)
        self.assert_invalid("same physical evidence file reused")

    def test_17_hardlink_receipt_alias_rejected(self):
        old = Path(self.paths()["receipt_path"])
        old.unlink()
        try:
            os.link(self.paths("synthetic-a")["receipt_path"], old)
        except (OSError, NotImplementedError) as exc:
            self.skipTest("hardlink unsupported: " + str(exc))
        self.assert_invalid("same physical evidence file reused")

    def test_18_normalized_duplicate_key_rejected(self):
        p = Path(self.paths()["normalized_path"])
        lines = p.read_bytes().splitlines()
        lines[0] = lines[0][:-1] + b',"month_index":20}'
        p.write_bytes(b"\n".join(lines) + b"\n")
        self.assert_invalid("duplicate normalized evidence field")

    def test_19_normalized_NaN_extension_rejected(self):
        p = Path(self.paths()["normalized_path"])
        lines = p.read_bytes().splitlines()
        lines[0] = lines[0][:-1] + b',"comment":NaN}'
        p.write_bytes(b"\n".join(lines) + b"\n")
        self.assert_invalid("non-finite JSON")

    def test_20_missing_raw_final_LF_rejected(self):
        p = Path(self.paths()["raw_path"])
        p.write_bytes(p.read_bytes().rstrip(b"\n"))
        self.assert_invalid("missing final LF")

    def test_21_receipt_duplicate_JSON_key_rejected(self):
        p = Path(self.paths()["receipt_path"])
        data = p.read_bytes()
        p.write_bytes(data[:-2] + b',"engine_id":"synthetic-b"}\n')
        self.assert_invalid("duplicate JSON key")

    def test_22_missing_receipt_file_rejected(self):
        Path(self.paths()["receipt_path"]).unlink()
        self.assert_invalid()

    def test_23_zero_engine_identity_separation_rejected(self):
        self.manifest["engine_b"] = self.manifest["engine_a"]
        self.assert_invalid("two distinct engine")

    def test_24_unpinned_calculation_day_rejected(self):
        self.plan["calculation_day"] = "-15055671"
        self.assert_invalid("receipt")

    def test_25_derived_source_not_promoted_to_original(self):
        self.plan["engines"][1]["provenance"]["source_class"] = "derived"
        self.assert_invalid("derived")

    def test_26_chunk_coordinate_gap_rejected(self):
        self.mutate_receipt("first_target_day", "-15056174", ordinal=1)
        self.assert_invalid("chunk sequence has gap")

    def test_27_same_inodes_not_required_for_identical_contents(self):
        # Multiple engines can independently serialize the same normalized
        # rows; matching bytes do not imply that their output files coincide.
        left = Path(self.paths("synthetic-a")["normalized_path"])
        right = Path(self.paths("synthetic-b")["normalized_path"])
        self.assertNotEqual(left.stat().st_ino, right.stat().st_ino)
        self.assertEqual(self.result()["status"], "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED")

    def test_28_original_soak_never_authorized_even_when_equal(self):
        r = self.result()
        self.assertTrue(r["halt_new_native_soak_dispatch"])
        self.assertFalse(r["source_name_semantics_verified"])
        self.assertFalse(r["official_soak_10000_pass"])
        self.assertEqual(r["independent_original_algorithms_certified"], 0)


if __name__ == "__main__":
    unittest.main()
