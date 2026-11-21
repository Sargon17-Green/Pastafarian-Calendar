#!/usr/bin/env python3
"""v151 synthetic source-byte, source-lock, and profile spoofing regressions.

Uses only mock AST/JavaScript source FILES; no calendar engine is ever imported
or executed. The separate CI download gate tests real historical pinned bytes.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
import native_raw_pair_gate_v018 as pilot
from native_execution_receipt_v038 import canonical, make_receipt
import soak_source_derived_names_v151 as v151
from soak_raw_bound_year_diff_v149 import SCHEMA as V149_SCHEMA
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def sha(data):
    return hashlib.sha256(data).hexdigest()


class SourceBoundTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="v151-source-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.sources = self.home / "locked-sources"
        self.sources.mkdir()
        self.original_lock = v151.LOCK_PATH
        self.original_hash = v151.LOCK_GIT_BLOB_SHA1
        self.original_pilot = pilot.LOCK
        self.addCleanup(self.restore_lock)
        v151.LOCK_PATH = self.home / "source-lock.json"
        pilot.LOCK = v151.LOCK_PATH

        self.cut = {"REF-41": ["TR-C" + str(i) for i in range(1, 18)],
                    "REF-24": ["OE-C" + str(i) for i in range(1, 18)]}
        self.mon = {"REF-41": ["TR-M" + str(i) for i in range(1, 48)],
                    "REF-24": ["OE-M" + str(i) for i in range(1, 48)]}
        py = ("FROZEN_CUTLET_NAMES = " + repr(tuple(self.cut["REF-41"])) +
              "\nFROZEN_MONTH_NAMES = " + repr(tuple(self.mon["REF-41"])) + "\n").encode()
        def js_group(key, names):
            rows = ["  Object.freeze({ canonicalIndex: " + str(i) +
                    ", text: '" + label + "' })"
                    for i, label in enumerate(names, 1)]
            return ("const " + key + " = Object.freeze([\n" +
                    ",\n".join(rows) + "\n]);\n")
        js = ("'use strict';\n" +
              js_group("CUTLETS", self.cut["REF-24"]) +
              js_group("MONTHS", self.mon["REF-24"])).encode()
        jscore = b"'use strict';\n// Synthetic fixture; not a converter.\n"
        self.blobs = {
            "REF-41": [("tests/normative_reference.py", py)],
            "REF-24": [("tests/normative-reference.js", jscore),
                       ("src/source-language-catalog.js", js)]
        }
        self.lock = {
            "schema": "PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1",
            "immutable": True, "main_changes_permitted": False,
            "converter_execution": False, "full_year_run": False,
            "semantics_validated": False, "syntactic_only": True,
            "engines": []
        }
        for e, folder, token, entry in (
            ("REF-41", "Python-Turkce", "1", "NormativeCalendar().calendar_date_ids(c,t)"),
            ("REF-24", "JavaScript-Interlingue", "2", "calendarDate(BigInt(c),BigInt(t))")
        ):
            commit = token * 40
            srcs = []
            for path, data in self.blobs[e]:
                file = self.sources / folder / commit / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_bytes(data)
                srcs.append({"path": path, "sha256": sha(data),
                             "bytes": len(data), "git_blob_sha1": pilot.git_blob(data)})
            self.lock["engines"].append({
                "id": e, "repository": "Sargon17-Green/Pastafarian-Calendar",
                "commit": commit, "entrypoint": entry, "sources": srcs
            })
        self.write_lock()

        self.plan = {
            "contract": PROVENANCE_CONTRACT,
            "identity_contract": IDENTITY_SCHEMA,
            "soak_purpose": "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
            "independence_audit_status": "NOT_CERTIFIED",
            "calculation_day": "-15055672", "chunk_days": 2,
            "years": [{"year": "5000", "first_target_day": "-15056173",
                       "last_target_day": "-15056170",
                       "boundary_evidence_sha256": "f" * 64}],
            "engines": []
        }
        for e, token in (("REF-41", "1"), ("REF-24", "2")):
            engine = next(x for x in self.lock["engines"] if x["id"] == e)
            maps = {"cutlets": self.cut[e], "months": self.mon[e]}
            self.plan["engines"].append({
                "id": e, "algorithm_id": "synthetic-algo-" + token,
                "source_sha256": engine["sources"][0]["sha256"],
                "binary_sha256": ("a" if token == "1" else "b") * 64,
                "name_map_sha256": sha(canonical(maps)),
                "provenance": {
                    "schema": IDENTITY_SCHEMA,
                    "source_class": "reference",
                    "source_commit": engine["commit"],
                    "repository": engine["repository"],
                    "source_path": engine["sources"][0]["path"],
                    "source_family": "synthetic-family-" + token,
                    "native_entrypoint": engine["entrypoint"],
                    "execution_method": "unchanged_reference_Fct",
                    "derived_from": None,
                    "original_source_sha256": engine["sources"][0]["sha256"],
                }
            })
        self.manifest = {
            "schema": V149_SCHEMA, "year": "5000",
            "engine_a": "REF-41", "engine_b": "REF-24",
            "bundles": {"REF-41": [], "REF-24": []},
        }
        for e in ("REF-41", "REF-24"):
            for ordinal in range(2):
                self.bundle(e, ordinal)

    def restore_lock(self):
        v151.LOCK_PATH = self.original_lock
        v151.LOCK_GIT_BLOB_SHA1 = self.original_hash
        pilot.LOCK = self.original_pilot

    def write_lock(self):
        self.lock_bytes = canonical(self.lock) + b"\n"
        v151.LOCK_PATH.write_bytes(self.lock_bytes)
        v151.LOCK_GIT_BLOB_SHA1 = pilot.git_blob(self.lock_bytes)

    def paths(self, e="REF-24", ordinal=0):
        return self.manifest["bundles"][e][ordinal]

    def original_row(self, e, index):
        t = str(-15056173 + index)
        if e == "REF-41":
            return {
                "calculation_day": "-15055672", "target_day": t,
                "native_date_ids": {
                    "year_number": "5000", "cutlet_name_index": 10,
                    "day_in_cutlet": 503 + index,
                    "month_name_index": 20, "day_in_month": 56 + index,
                },
                "native_names": {
                    "cutlet": self.cut[e][9], "month": self.mon[e][19]
                }
            }
        return {
            "calculation_day": "-15055672", "target_day": t,
            "native_tuple": ["5000", self.cut[e][9], str(503 + index),
                             self.mon[e][19], str(56 + index)]
        }

    def bundle(self, e, ordinal):
        folder = self.home / "evidence" / e / str(ordinal)
        folder.mkdir(parents=True, exist_ok=True)
        b = {
            "ordinal": ordinal,
            "raw_path": str(folder / "raw.jsonl"),
            "normalized_path": str(folder / "normalized.jsonl"),
            "receipt_path": str(folder / "receipt.json")
        }
        self.manifest["bundles"][e].append(b)
        raw, normalized = [], []
        for index in (ordinal * 2, ordinal * 2 + 1):
            original = canonical(self.original_row(e, index)) + b"\n"
            raw.append(original)
            normalized.append(canonical({
                "calculation_day": "-15055672",
                "target_day": str(-15056173 + index), "year": "5000",
                "cutlet_index": 10, "day_in_cutlet": 503 + index,
                "month_index": 20, "day_in_month": 56 + index,
                "cutlet_name_raw": self.cut[e][9],
                "month_name_raw": self.mon[e][19],
                "source_raw_sha256": sha(original)
            }) + b"\n")
        Path(b["raw_path"]).write_bytes(b"".join(raw))
        Path(b["normalized_path"]).write_bytes(b"".join(normalized))
        self.rebuild_receipt(e, ordinal)

    def rebuild_receipt(self, e="REF-24", ordinal=0):
        b = self.paths(e, ordinal)
        raw = Path(b["raw_path"]).read_bytes()
        norm = Path(b["normalized_path"]).read_bytes()
        first = -15056173 + ordinal * 2
        rec = make_receipt(self.plan, sha(canonical(self.plan)), e, "5000",
                           str(first), str(first + 1), ordinal, norm, raw)
        Path(b["receipt_path"]).write_bytes(canonical(rec) + b"\n")

    def mutate_consistent(self, mutate_raw, mutate_normalized=None, e="REF-24", ordinal=0):
        b = self.paths(e, ordinal)
        raw_path = Path(b["raw_path"])
        norm_path = Path(b["normalized_path"])
        raws = [json.loads(l) for l in raw_path.read_bytes().splitlines()]
        norms = [json.loads(l) for l in norm_path.read_bytes().splitlines()]
        mutate_raw(raws[0])
        row_bytes = canonical(raws[0]) + b"\n"
        norms[0]["source_raw_sha256"] = sha(row_bytes)
        if mutate_normalized is not None:
            mutate_normalized(norms[0])
        raw_path.write_bytes(b"".join(canonical(v) + b"\n" for v in raws))
        norm_path.write_bytes(b"".join(canonical(v) + b"\n" for v in norms))
        self.rebuild_receipt(e, ordinal)

    def report(self, profiles=None):
        return v151.audit(self.plan, self.manifest, self.sources, profiles)

    def blocked(self, substring=None):
        r = self.report()
        self.assertEqual(r["status"], "INVALID_SOURCE_BOUND_EVIDENCE", r)
        self.assertEqual(r["original_years_certified"], 0)
        self.assertTrue(r["halt_new_native_soak_dispatch"])
        if substring is not None:
            self.assertIn(substring, r["error"])
        return r

    def test_01_valid_two_pinned_source_ast_and_js_catalogs_replayed(self):
        r = self.report()
        self.assertEqual(r["status"], "SOURCE_LOCKED_SEMANTIC_EQUAL_UNCERTIFIED", r)
        self.assertEqual(r["source_code_files_bytes_verified"], 3)
        self.assertEqual(r["source_native_rows_replayed"], 8)
        self.assertEqual(r["source_native_day_pairs_checked"], 4)
        self.assertFalse(r["original_process_execution_attested"])

    def test_02_source_only_reads_all_three_pinned_files(self):
        r = v151.source_only(self.sources)
        self.assertEqual(r["status"], "PINNED_SOURCE_CATALOG_BYTES_VERIFIED_UNCERTIFIED", r)
        self.assertEqual(r["source_code_files_bytes_verified"], 3)
        self.assertEqual(r["source_catalogs"]["REF-41"]["catalog"]["months"][19], "TR-M20")
        self.assertEqual(r["source_catalogs"]["REF-24"]["catalog"]["months"][19], "OE-M20")

    def test_03_python_source_changed_cannot_preserve_pinned_lock(self):
        f = self.sources / "Python-Turkce" / ("1" * 40) / "tests/normative_reference.py"
        f.write_bytes(f.read_bytes().replace(b"TR-M20", b"TR-M30"))
        self.blocked("source bytes differ")

    def test_04_javascript_catalog_changed_cannot_preserve_pinned_lock(self):
        f = self.sources / "JavaScript-Interlingue" / ("2" * 40) / "src/source-language-catalog.js"
        f.write_bytes(f.read_bytes().replace(b"OE-M20", b"OE-M30"))
        self.blocked("source bytes differ")

    def test_05_unrelated_js_engine_source_change_also_blocked(self):
        f = self.sources / "JavaScript-Interlingue" / ("2" * 40) / "tests/normative-reference.js"
        f.write_bytes(f.read_bytes() + b"\n// malicious untracked edit\n")
        self.blocked("source bytes differ")

    def test_06_modified_lock_rejected_before_all_source_reads(self):
        v151.LOCK_PATH.write_bytes(self.lock_bytes + b" ")
        self.blocked("source-lock file bytes changed")

    def test_07_plan_map_digest_mismatch_not_accepted(self):
        self.plan["engines"][1]["name_map_sha256"] = "e" * 64
        self.blocked("not bound")

    def test_08_plan_source_SHA_wrong_not_accepted(self):
        self.plan["engines"][1]["source_sha256"] = "e" * 64
        self.plan["engines"][1]["provenance"]["original_source_sha256"] = "e" * 64
        self.blocked("not bound")

    def test_09_plan_historical_commit_changed_not_accepted(self):
        self.plan["engines"][0]["provenance"]["source_commit"] = "f" * 40
        self.blocked("not bound")

    def test_10_plan_source_path_changed_not_accepted(self):
        self.plan["engines"][0]["provenance"]["source_path"] = "tests/other_source.py"
        self.blocked("not bound")

    def test_11_plan_native_entrypoint_changed_not_accepted(self):
        self.plan["engines"][0]["provenance"]["native_entrypoint"] = "fake_calendar(c,t)"
        self.blocked("not bound")

    def test_12_input_profile_name_forgery_not_accepted(self):
        p = v151.source_profiles(self.plan, self.manifest, v151.extract_names(self.sources))
        p["engines"][1]["month_names"][19] = "FORGED"
        r = self.report(p)
        self.assertEqual(r["status"], "INVALID_SOURCE_BOUND_EVIDENCE", r)
        self.assertIn("source-derived maps", r["error"])

    def test_13_exact_derived_user_profile_does_not_override_source(self):
        p = v151.source_profiles(self.plan, self.manifest, v151.extract_names(self.sources))
        self.assertEqual(self.report(p)["status"], "SOURCE_LOCKED_SEMANTIC_EQUAL_UNCERTIFIED")

    def test_14_consistent_raw_month_tamper_and_recomputed_hash_rejected(self):
        self.mutate_consistent(lambda row: row["native_tuple"].__setitem__(3, self.mon["REF-24"][29]))
        self.blocked("native raw semantics do not match normalized")

    def test_15_consistent_native_numeric_difference_is_not_normalized_away(self):
        self.mutate_consistent(
            lambda row: row["native_tuple"].__setitem__(3, self.mon["REF-24"][29]),
            lambda norm: (norm.__setitem__("month_index", 30),
                          norm.__setitem__("month_name_raw", self.mon["REF-24"][29]))
        )
        r = self.report()
        self.assertEqual(r["status"], "SOURCE_LOCKED_REPLAYED_FIRST_DIFFERENCE_UNCERTIFIED", r)
        self.assertEqual(r["first_mismatch_target_day"], "-15056173")
        self.assertEqual(r["first_numeric_difference"]["field"], "month_index")

    def test_16_no_missing_pinned_python_file_can_pass(self):
        f = self.sources / "Python-Turkce" / ("1" * 40) / "tests/normative_reference.py"
        f.unlink()
        self.blocked()

    def test_17_no_missing_pinned_js_catalog_file_can_pass(self):
        f = self.sources / "JavaScript-Interlingue" / ("2" * 40) / "src/source-language-catalog.js"
        f.unlink()
        self.blocked()

    def test_18_source_labels_swapped_in_plan_are_rejected(self):
        self.plan["engines"][1]["provenance"]["source_path"] = "tests/normative_reference.py"
        self.blocked("not bound")

    def test_19_extra_engine_id_in_manifest_rejected(self):
        self.manifest["engine_b"] = "SYNTHETIC-UNPINNED"
        self.blocked("reference-engine")

    def test_20_all_certification_fields_remain_false(self):
        r = self.report()
        self.assertTrue(r["halt_new_native_soak_dispatch"])
        self.assertFalse(r["official_soak_10000_pass"])
        self.assertFalse(r["original_process_execution_attested"])
        self.assertFalse(r["original_algorithmic_independence_attested"])
        self.assertEqual(r["independent_original_algorithms_certified"], 0)
        self.assertEqual(r["original_converters_executed"], 0)


if __name__ == "__main__":
    unittest.main()
