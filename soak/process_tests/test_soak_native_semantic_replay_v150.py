#!/usr/bin/env python3
"""v150: synthetic raw -> native decoder -> normalized numeric/name replay.

Only 4 synthetic days with 2 chunks per engine. Never a real F(c,t) call.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from native_execution_receipt_v038 import canonical, make_receipt
from soak_native_semantic_replay_v150 import SCHEMA, replay
from soak_raw_bound_year_diff_v149 import SCHEMA as V149_SCHEMA, audit as audit_v149
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def fixture_plan():
    def engine(e, token, source_class):
        return {
            "id": e,
            "algorithm_id": "synthetic-algo-" + token,
            "source_sha256": token * 64,
            "binary_sha256": ("a" if token == "1" else "b") * 64,
            "name_map_sha256": "0" * 64,
            "provenance": {
                "schema": IDENTITY_SCHEMA,
                "source_class": source_class,
                "source_commit": token * 40,
                "repository": "Sargon17-Green/Pastafarian-Calendar",
                "source_path": "synthetic/" + e + ".not-original",
                "source_family": "synthetic-family-" + token,
                "native_entrypoint": e + ".SYNTHETIC_ONLY",
                "execution_method": (
                    "unchanged_reference_Fct" if source_class == "reference"
                    else "unchanged_original_Fct"
                ),
                "derived_from": None,
                "original_source_sha256": token * 64
            }
        }
    return {
        "contract": PROVENANCE_CONTRACT,
        "identity_contract": IDENTITY_SCHEMA,
        "soak_purpose": "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status": "NOT_CERTIFIED",
        "calculation_day": "-15055672",
        "chunk_days": 2,
        "years": [{
            "year": "5000",
            "first_target_day": "-15056173",
            "last_target_day": "-15056170",
            "boundary_evidence_sha256": "f" * 64
        }],
        "engines": [
            engine("synthetic-a", "1", "reference"),
            engine("synthetic-b", "2", "original")
        ]
    }


class SemanticReplayTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="soak-v150-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.plan = fixture_plan()
        self.profiles = {"schema": SCHEMA, "engines": []}
        self.manifest = {
            "schema": V149_SCHEMA, "year": "5000",
            "engine_a": "synthetic-a", "engine_b": "synthetic-b",
            "bundles": {"synthetic-a": [], "synthetic-b": []}
        }
        for e, kind in (("synthetic-a", "SOURCE_NATIVE_JSON_IDS_V018"),
                        ("synthetic-b", "SOURCE_NATIVE_JSON_NAMED_TUPLE_V018")):
            cutlet = [e + "-C" + str(i) for i in range(1, 18)]
            month = [e + "-M" + str(i) for i in range(1, 48)]
            descriptor = next(p for p in self.plan["engines"] if p["id"] == e)
            descriptor["name_map_sha256"] = hashlib.sha256(canonical({
                "cutlets": cutlet, "months": month
            })).hexdigest()
            self.profiles["engines"].append({
                "engine_id": e, "codec": kind,
                "source_sha256": descriptor["source_sha256"],
                "source_commit": descriptor["provenance"]["source_commit"],
                "cutlet_names": cutlet, "month_names": month,
                "source_mapping_independently_attested": False
            })
        for e in ("synthetic-a", "synthetic-b"):
            for ordinal in range(2):
                self.write_bundle(e, ordinal)

    def profile(self, engine="synthetic-b"):
        return next(p for p in self.profiles["engines"] if p["engine_id"] == engine)

    def paths(self, engine="synthetic-b", ordinal=0):
        return self.manifest["bundles"][engine][ordinal]

    def native_row(self, engine, idx):
        p = self.profile(engine)
        t = str(-15056173 + idx)
        if engine == "synthetic-a":
            return {
                "calculation_day": "-15055672",
                "target_day": t,
                "native_date_ids": {
                    "year_number": "5000",
                    "cutlet_name_index": 10,
                    "day_in_cutlet": 503 + idx,
                    "month_name_index": 20,
                    "day_in_month": 56 + idx,
                },
                "native_names": {
                    "cutlet": p["cutlet_names"][9],
                    "month": p["month_names"][19]
                }
            }
        return {
            "calculation_day": "-15055672",
            "target_day": t,
            "native_tuple": [
                "5000", p["cutlet_names"][9], str(503 + idx),
                p["month_names"][19], str(56 + idx)
            ]
        }

    def normalized_row(self, engine, idx, native_bytes):
        p = self.profile(engine)
        return {
            "calculation_day": "-15055672",
            "target_day": str(-15056173 + idx),
            "year": "5000",
            "cutlet_index": 10,
            "day_in_cutlet": 503 + idx,
            "month_index": 20,
            "day_in_month": 56 + idx,
            "cutlet_name_raw": p["cutlet_names"][9],
            "month_name_raw": p["month_names"][19],
            "source_raw_sha256": hashlib.sha256(native_bytes).hexdigest()
        }

    def write_bundle(self, engine, ordinal):
        folder = self.root / (engine + "-" + str(ordinal))
        folder.mkdir(exist_ok=True)
        paths = {
            "ordinal": ordinal,
            "raw_path": str(folder / "raw"),
            "normalized_path": str(folder / "normalized"),
            "receipt_path": str(folder / "receipt")
        }
        self.manifest["bundles"][engine].append(paths)
        raw = []
        norm = []
        for i in range(ordinal * 2, ordinal * 2 + 2):
            line = canonical(self.native_row(engine, i)) + b"\n"
            raw.append(line)
            norm.append(canonical(self.normalized_row(engine, i, line)) + b"\n")
        Path(paths["raw_path"]).write_bytes(b"".join(raw))
        Path(paths["normalized_path"]).write_bytes(b"".join(norm))
        self.refresh_receipt(engine, ordinal)

    def refresh_receipt(self, engine="synthetic-b", ordinal=0):
        paths = self.paths(engine, ordinal)
        raw = Path(paths["raw_path"]).read_bytes()
        norm = Path(paths["normalized_path"]).read_bytes()
        first = -15056173 + ordinal * 2
        receipt = make_receipt(
            self.plan, hashlib.sha256(canonical(self.plan)).hexdigest(), engine,
            "5000", str(first), str(first + 1), ordinal, norm, raw
        )
        Path(paths["receipt_path"]).write_bytes(canonical(receipt) + b"\n")

    def tamper_raw(self, fn, engine="synthetic-b", ordinal=0, row=0,
                   change_normalized=None):
        paths = self.paths(engine, ordinal)
        raw_path = Path(paths["raw_path"])
        norm_path = Path(paths["normalized_path"])
        raw = [json.loads(x) for x in raw_path.read_bytes().splitlines()]
        norm = [json.loads(x) for x in norm_path.read_bytes().splitlines()]
        fn(raw[row])
        new_line = canonical(raw[row]) + b"\n"
        norm[row]["source_raw_sha256"] = hashlib.sha256(new_line).hexdigest()
        if change_normalized is not None:
            change_normalized(norm[row])
        raw_path.write_bytes(
            b"".join(canonical(x) + b"\n" for x in raw)
        )
        norm_path.write_bytes(b"".join(canonical(x) + b"\n" for x in norm))
        self.refresh_receipt(engine, ordinal)

    def tamper_normalized(self, fn, engine="synthetic-b", ordinal=0, row=0):
        paths = self.paths(engine, ordinal)
        norm = [json.loads(x) for x in Path(paths["normalized_path"]).read_bytes().splitlines()]
        fn(norm[row])
        Path(paths["normalized_path"]).write_bytes(
            b"".join(canonical(x) + b"\n" for x in norm)
        )
        self.refresh_receipt(engine, ordinal)

    def result(self):
        return replay(self.plan, self.manifest, self.profiles)

    def assert_invalid(self, why=None):
        result = self.result()
        self.assertEqual(result["status"], "INVALID_SEMANTIC_EVIDENCE", result)
        self.assertTrue(result["halt_new_native_soak_dispatch"])
        self.assertFalse(result["official_soak_10000_pass"])
        self.assertEqual(result["original_years_certified"], 0)
        if why is not None:
            self.assertIn(why, result["error"])
        return result

    def test_01_both_structured_native_profiles_fully_replay(self):
        r = self.result()
        self.assertEqual(r["status"], "SEMANTICALLY_EQUAL_UNCERTIFIED", r)
        self.assertEqual(r["semantic_rows_checked"], 8)
        self.assertEqual(r["semantic_day_pairs_checked"], 4)
        self.assertTrue(r["all_source_to_normalized_fields_replayed"])
        self.assertFalse(r["native_source_lineage_attested"])
        self.assertFalse(r["native_process_execution_attested"])
        self.assertFalse(r["native_name_maps_independently_attested"])

    def test_02_source_native_month_changed_but_normalized_20_and_rehashed(self):
        self.tamper_raw(lambda r: r["native_tuple"].__setitem__(3, self.profile()["month_names"][29]))
        # Even v149 considers independently rehashed normalized rows equal.
        self.assertEqual(audit_v149(self.plan, self.manifest)["status"],
                         "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED")
        self.assert_invalid("native raw semantics do not match")

    def test_03_native_python_month_id_wrong_and_rehashed(self):
        self.tamper_raw(lambda r: r["native_date_ids"].__setitem__("month_name_index", 30),
                        engine="synthetic-a")
        self.assert_invalid("native raw semantics do not match")

    def test_04_native_day_in_cutlet_wrong_and_rehashed(self):
        self.tamper_raw(lambda r: r["native_tuple"].__setitem__(2, "900"))
        self.assert_invalid("native raw semantics do not match")

    def test_05_native_month_name_wrong_and_rehashed(self):
        self.tamper_raw(lambda r: r["native_tuple"].__setitem__(3, "NOT_IN_SOURCE_CATALOG"))
        self.assert_invalid("native raw semantics do not match")

    def test_06_raw_year_wrong_and_rehashed(self):
        self.tamper_raw(lambda r: r["native_tuple"].__setitem__(0, "5001"))
        self.assert_invalid("native raw semantics do not match")

    def test_07_native_target_day_wrong_and_rehashed(self):
        self.tamper_raw(lambda r: r.__setitem__("target_day", "999"))
        self.assert_invalid("native raw semantics do not match")

    def test_08_normalized_day_wrong_but_receipt_rebuilt(self):
        self.tamper_normalized(lambda r: r.__setitem__("day_in_month", 99))
        self.assertEqual(audit_v149(self.plan, self.manifest)["status"], "FIRST_NUMERIC_DIFFERENCE")
        self.assert_invalid("native raw semantics do not match")

    def test_09_real_native_and_normalized_difference_remains_recorded(self):
        self.tamper_raw(
            lambda r: r["native_tuple"].__setitem__(3, self.profile()["month_names"][29]),
            change_normalized=lambda row: (
                row.__setitem__("month_index", 30),
                row.__setitem__("month_name_raw", self.profile()["month_names"][29])
            )
        )
        r = self.result()
        self.assertEqual(r["status"], "SEMANTICALLY_REPLAYED_FIRST_DIFFERENCE", r)
        self.assertEqual(r["first_numeric_difference"]["field"], "month_index")
        self.assertEqual(r["first_mismatch_target_day"], "-15056173")
        self.assertEqual(r["original_years_certified"], 0)

    def test_10_real_native_late_day_difference_remains_recorded(self):
        self.tamper_raw(
            lambda r: r["native_tuple"].__setitem__(4, "99"),
            ordinal=1, row=1,
            change_normalized=lambda n: n.__setitem__("day_in_month", 99)
        )
        r = self.result()
        self.assertEqual(r["status"], "SEMANTICALLY_REPLAYED_FIRST_DIFFERENCE", r)
        self.assertEqual(r["first_mismatch_target_day"], "-15056170")

    def test_11_missing_decoder_profile_rejected(self):
        self.profiles["engines"].pop()
        self.assert_invalid("exactly two decoder profiles")

    def test_12_duplicate_engine_profile_rejected(self):
        self.profiles["engines"][1] = dict(self.profiles["engines"][0])
        self.assert_invalid("missing, duplicate")

    def test_13_unknown_codec_rejected(self):
        self.profile()["codec"] = "ARBITRARY_SOURCE_FORMAT"
        self.assert_invalid("format unsupported")

    def test_14_codec_swap_rejected_by_native_schema(self):
        self.profile()["codec"] = "SOURCE_NATIVE_JSON_IDS_V018"
        self.assert_invalid("native raw semantics do not match")

    def test_15_wrong_source_SHA_in_profile_rejected(self):
        self.profile()["source_sha256"] = "e" * 64
        self.assert_invalid("declared source")

    def test_16_wrong_source_commit_in_profile_rejected(self):
        self.profile()["source_commit"] = "a" * 40
        self.assert_invalid("declared source")

    def test_17_profile_must_never_self_attest_mapping(self):
        self.profile()["source_mapping_independently_attested"] = True
        self.assert_invalid("cannot attest original")

    def test_18_changed_name_table_without_pinned_digest_rejected(self):
        self.profile()["month_names"][19] = "fake-month"
        self.assert_invalid("name_map_sha256")

    def test_19_duplicate_native_name_catalog_rejected(self):
        p = self.profile()
        p["cutlet_names"][9] = p["cutlet_names"][0]
        self.assert_invalid("repeated or invalid")

    def test_20_short_catalog_rejected(self):
        self.profile()["month_names"].pop()
        self.assert_invalid("all 17 cutlet")

    def test_21_invalid_newline_name_rejected(self):
        self.profile()["month_names"][5] += "\n"
        self.assert_invalid("repeated or invalid")

    def test_22_missing_raw_chunk_prevents_semantic_replay(self):
        Path(self.paths()["raw_path"]).unlink()
        self.assert_invalid("v149 raw-byte")

    def test_23_duplicate_raw_JSON_key_rejected_with_rebuilt_hashes(self):
        paths = self.paths()
        raw_path = Path(paths["raw_path"])
        norm_path = Path(paths["normalized_path"])
        lines = raw_path.read_bytes().splitlines(keepends=True)
        lines[0] = lines[0][:-2] + b',"target_day":"-15056173"}\n'
        raw_path.write_bytes(b"".join(lines))
        norms = [json.loads(x) for x in norm_path.read_bytes().splitlines()]
        norms[0]["source_raw_sha256"] = hashlib.sha256(lines[0]).hexdigest()
        norm_path.write_bytes(b"".join(canonical(x) + b"\n" for x in norms))
        self.refresh_receipt()
        self.assertEqual(audit_v149(self.plan, self.manifest)["status"],
                         "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED")
        self.assert_invalid("native raw semantics do not match")

    def test_24_separately_encoded_raw_names_are_permitted(self):
        # Both languages use separate native names; semantic equality is numeric.
        r = self.result()
        self.assertEqual(r["status"], "SEMANTICALLY_EQUAL_UNCERTIFIED")
        self.assertNotEqual(self.profile("synthetic-a")["month_names"][19],
                            self.profile("synthetic-b")["month_names"][19])

    def test_25_source_raw_hash_unrelated_to_semantic_correctness(self):
        self.tamper_raw(lambda r: r["native_tuple"].__setitem__(2, "501"))
        v149 = audit_v149(self.plan, self.manifest)
        self.assertEqual(v149["status"], "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED")
        self.assert_invalid("native raw semantics do not match")

    def test_26_no_actual_original_converter_or_soak_certification(self):
        r = self.result()
        self.assertEqual(r["original_converters_executed"], 0)
        self.assertEqual(r["original_years_certified"], 0)
        self.assertFalse(r["native_process_execution_attested"])
        self.assertFalse(r["official_soak_10000_pass"])


if __name__ == "__main__":
    unittest.main()
