"""v083: extend original-source CrashStore from four to five two-day chunks.

All five archives must be previously completed pinned GitHub Actions artifacts.
This test runs no new native F(c,t) process and certifies no whole year.
"""
from __future__ import annotations

import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"runner"))

from recovery_store import CrashStore
from native_execution_receipt_v038 import make_receipt
from original_ref41_year_chunk_import_v059 import (
    locked_full_year_experimental_plan, import_real_original_ref41_baseline,
    check_original_process_chunk_links,
)
from original_next_chunk_import_v066 import import_next_original_python_chunk
from original_generic_source_chunk_ledger_v073 import (
    import_generic_original_ref41_chunk, manifest_for,
    check_generic_witnesses, offline_original_chunk,
)
from original_chunk_artifact_gate_v072 import archive_files


class FiveActualOriginalChunks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        envnames = (
            "PASTAFARI_V053_REAL_ZIP",
            "PASTAFARI_V061_REAL_ZIP",
            "PASTAFARI_V070_REAL_ZIP",
            "PASTAFARI_V078_REAL_ZIP",
            "PASTAFARI_V081_REAL_ZIP",
            "PASTAFARI_ORIGINAL_PYTHON_ROOT",
            "PASTAFARI_ORIGINAL_KOTLIN_GIT",
        )
        vals = [os.environ.get(name) for name in envnames]
        if any(v is None for v in vals):
            raise RuntimeError("five original ZIPs and original Python/Kotlin source trees are required")
        cls.z1015, cls.z1016, cls.z1017, cls.z1018, cls.z1019 = [
            Path(x).read_bytes() for x in vals[:5]]
        cls.pyroot = Path(vals[5]).resolve(strict=True)
        cls.ktroot = Path(vals[6]).resolve(strict=True)
        cls.plan = locked_full_year_experimental_plan(cls.pyroot, cls.ktroot, cls.z1015)
        cls.pin1018, _ = manifest_for(1018)
        cls.pin1019, _ = manifest_for(1019)
        archive_files(cls.z1018, cls.pin1018)
        cls.files1019 = archive_files(cls.z1019, cls.pin1019)

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)/"ledger"

    def four(self, store):
        import_real_original_ref41_baseline(
            store, self.z1015, self.pyroot, self.ktroot)
        import_next_original_python_chunk(
            store, self.z1015, self.z1016, self.pyroot, self.ktroot)
        import_generic_original_ref41_chunk(
            store, 1017, self.z1017, self.z1015, self.pyroot, self.ktroot)
        import_generic_original_ref41_chunk(
            store, 1018, self.z1018, self.z1015, self.pyroot, self.ktroot)

    def fifth(self, store, archive=None):
        return import_generic_original_ref41_chunk(
            store, 1019, self.z1019 if archive is None else archive,
            self.z1015, self.pyroot, self.ktroot)

    def five(self, store):
        self.four(store)
        return self.fifth(store)

    def test_five_pinned_source_chunks_linked_in_one_year_without_whole_year_credit(self):
        with CrashStore(self.root, self.plan) as store:
            outcome = self.five(store)
            self.assertEqual(outcome["outcome"], "COMMITTED")
            self.assertEqual(outcome["ordinal"], 1019)
            p = store.progress()
            self.assertEqual(p["committed_chunks"], 5)
            self.assertEqual(p["original_process_linked_chunks_not_years"], 5)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"], 5)
            self.assertEqual(p["original_generic_source_witnesses_not_years"], 3)
            self.assertEqual(p["fully_verified_years"], 0)
            self.assertEqual(p["verified_comparisons_completed"], 0)
            self.assertEqual(p["original_native_full_year_soak_passes_certified"], 0)
            self.assertFalse(p["all_verified"])
            self.assertEqual(check_generic_witnesses(store), 3)
            self.assertEqual(check_original_process_chunk_links(store), 5)
            chunk = store._chunk("REF-41", "5000", 1019)
            self.assertEqual((chunk.first_day, chunk.last_day), ("-15055664", "-15055663"))
            self.assertEqual(store._chunk_path(chunk).read_bytes(),
                             self.files1019["REF-41/native-normalized.jsonl"])
            self.assertEqual(len(store.expected_chunks("REF-41", "5000")), 2122)

    def test_reopen_offline_revalidates_all_five_original_source_links(self):
        with CrashStore(self.root, self.plan) as store:
            self.five(store)
        with CrashStore(self.root, self.plan) as store:
            r = store.verify_and_recover()
            self.assertEqual(r["original_generic_source_witnesses_revalidated"], 3)
            self.assertEqual(r["original_source_process_chunk_links_revalidated"], 5)
            self.assertEqual(r["verified_existing_chunks"], 5)
            self.assertEqual(r["recovered_chunks"], 0)
            self.assertEqual(r["progress"]["fully_verified_years"], 0)

    def test_altered_1019_ZIP_cannot_commit(self):
        altered = self.z1019[:-1] + bytes([self.z1019[-1] ^ 1])
        with CrashStore(self.root, self.plan) as store:
            self.four(store)
            with self.assertRaises(ValueError):
                self.fifth(store, altered)
            self.assertEqual(store.progress()["committed_chunks"], 4)

    def test_corrupt_1018_process_link_blocks_subsequent_1019_import(self):
        with CrashStore(self.root, self.plan) as store:
            self.four(store)
            store.db.execute(
                "UPDATE original_process_chunk_links SET native_raw_sha256=? "
                "WHERE engine='REF-41' AND year='5000' AND ordinal=1018",
                ("0"*64,))
            with self.assertRaises(ValueError):
                self.fifth(store)
            self.assertEqual(store.progress()["committed_chunks"], 4)

    def test_missing_1019_link_requires_explicit_same_source_replay(self):
        with CrashStore(self.root, self.plan) as store:
            self.five(store)
            store.db.execute(
                "DELETE FROM original_process_chunk_links "
                "WHERE engine='REF-41' AND year='5000' AND ordinal=1019")
            with self.assertRaisesRegex(ValueError, "lost original process ZIP link"):
                store.verify_and_recover()
        with CrashStore(self.root, self.plan) as store:
            self.assertEqual(self.fifth(store)["outcome"], "ALREADY_COMMITTED")
            self.assertEqual(
                store.verify_and_recover()["original_source_process_chunk_links_revalidated"], 5)

    def test_kotlin_1019_candidate_rejected_before_full_python_year(self):
        with CrashStore(self.root, self.plan) as store:
            self.five(store)
            chunk = store._chunk("PROD-KT-CY", "5000", 1019)
            norm = self.files1019["kotlin-index-only-normalized.jsonl"]
            raw = self.files1019["PROD-KT-CY/os-stdout.tsv"]
            receipt = make_receipt(
                store.plan, store.plan_sha, "PROD-KT-CY", "5000",
                chunk.first_day, chunk.last_day, 1019, norm, raw)
            with self.assertRaisesRegex(ValueError, "complete previous engine year"):
                store.commit_chunk(
                    "PROD-KT-CY", "5000", 1019, norm,
                    raw_stdout=raw, native_receipt=receipt)
            self.assertEqual(store.progress()["committed_chunks"], 5)

    def test_1019_offline_integrity_not_licence_for_independence(self):
        proof = offline_original_chunk(self.z1019, self.pin1019)
        self.assertEqual(proof["ordinal"], 1019)
        self.assertEqual(proof["original_native_date_pairs"], 2)
        self.assertFalse(proof["source_lineage_certified"])
        self.assertFalse(proof["canonical_oracle_certified"])
        self.assertFalse(proof["independently_attested_OS_process"])
        self.assertEqual(proof["original_full_years_certified"], 0)


if __name__ == "__main__":
    unittest.main()
