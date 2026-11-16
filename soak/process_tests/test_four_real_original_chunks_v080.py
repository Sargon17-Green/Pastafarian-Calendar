"""v080: frozen 1015-1018 original-source archive CrashStore integration tests.

The suite reuses pinned original process ZIPs. It never invokes native F(c,t).
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
    check_original_process_chunk_links)
from original_next_chunk_import_v066 import import_next_original_python_chunk
from original_generic_source_chunk_ledger_v073 import (
    import_generic_original_ref41_chunk, manifest_for, witness_paths,
    check_generic_witnesses, offline_original_chunk)
from original_chunk_artifact_gate_v072 import archive_files


class FourOriginalSourceChunks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        names = ("PASTAFARI_V053_REAL_ZIP", "PASTAFARI_V061_REAL_ZIP",
                 "PASTAFARI_V070_REAL_ZIP", "PASTAFARI_V078_REAL_ZIP",
                 "PASTAFARI_ORIGINAL_PYTHON_ROOT", "PASTAFARI_ORIGINAL_KOTLIN_GIT")
        v = [os.environ.get(n) for n in names]
        if any(x is None for x in v):
            raise RuntimeError("four true source ZIPs and pinned trees are mandatory")
        cls.a, cls.b, cls.c, cls.d = [Path(x).read_bytes() for x in v[:4]]
        cls.python = Path(v[4]).resolve(strict=True)
        cls.kotlin = Path(v[5]).resolve(strict=True)
        cls.plan = locked_full_year_experimental_plan(cls.python, cls.kotlin, cls.a)
        cls.pin, _ = manifest_for(1018)
        cls.files = archive_files(cls.d, cls.pin)

    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)/"ledger"

    def three(self, store):
        import_real_original_ref41_baseline(store, self.a, self.python, self.kotlin)
        import_next_original_python_chunk(store, self.a, self.b, self.python, self.kotlin)
        import_generic_original_ref41_chunk(
            store, 1017, self.c, self.a, self.python, self.kotlin)

    def fourth(self, store, zip_bytes=None):
        return import_generic_original_ref41_chunk(
            store, 1018, self.d if zip_bytes is None else zip_bytes,
            self.a, self.python, self.kotlin)

    def test_four_original_chunks_and_process_links_without_full_year_credit(self):
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            result = self.fourth(store)
            self.assertEqual(result["outcome"], "COMMITTED")
            self.assertEqual(result["ordinal"], 1018)
            p = store.progress()
            self.assertEqual(p["committed_chunks"], 4)
            self.assertEqual(p["original_generic_source_witnesses_not_years"], 2)
            self.assertEqual(p["original_process_linked_chunks_not_years"], 4)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"], 4)
            self.assertEqual(p["verified_comparisons_completed"], 0)
            self.assertEqual(p["fully_verified_years"], 0)
            self.assertEqual(check_generic_witnesses(store), 2)
            self.assertEqual(check_original_process_chunk_links(store), 4)
            chunk = store._chunk("REF-41", "5000", 1018)
            self.assertEqual((chunk.first_day, chunk.last_day),
                             ("-15055666", "-15055665"))
            self.assertEqual(store._chunk_path(chunk).read_bytes(),
                             self.files["REF-41/native-normalized.jsonl"])

    def test_offline_recovery_verifies_four_source_links(self):
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            self.fourth(store)
        with CrashStore(self.root, self.plan) as store:
            r = store.verify_and_recover()
            self.assertEqual(r["original_generic_source_witnesses_revalidated"], 2)
            self.assertEqual(r["original_source_process_chunk_links_revalidated"], 4)
            self.assertEqual(r["verified_existing_chunks"], 4)
            self.assertEqual(r["recovered_chunks"], 0)
            self.assertEqual(r["progress"]["fully_verified_years"], 0)

    def test_duplicate_1018_replay_is_idempotent(self):
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            self.fourth(store)
            self.assertEqual(self.fourth(store)["outcome"], "ALREADY_COMMITTED")
            self.assertEqual(store.progress()["committed_chunks"], 4)

    def test_tampered_fourth_ZIP_refused_before_commit(self):
        tampered = self.d[:-1] + bytes([self.d[-1] ^ 1])
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            with self.assertRaises(ValueError):
                self.fourth(store, tampered)
            self.assertEqual(store.progress()["committed_chunks"], 3)

    def test_missing_1018_link_blocks_recovery_until_explicit_replay(self):
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            self.fourth(store)
            store.db.execute(
                "DELETE FROM original_process_chunk_links "
                "WHERE engine='REF-41' AND year='5000' AND ordinal=1018")
            with self.assertRaisesRegex(ValueError, "lost original process ZIP link"):
                store.verify_and_recover()
        with CrashStore(self.root, self.plan) as store:
            self.assertEqual(self.fourth(store)["outcome"], "ALREADY_COMMITTED")
            self.assertEqual(
                store.verify_and_recover()["original_source_process_chunk_links_revalidated"], 4)

    def test_kotlin_original_still_blocked_until_entire_python_year(self):
        with CrashStore(self.root, self.plan) as store:
            self.three(store)
            self.fourth(store)
            chunk = store._chunk("PROD-KT-CY", "5000", 1018)
            norm = self.files["kotlin-index-only-normalized.jsonl"]
            raw = self.files["PROD-KT-CY/os-stdout.tsv"]
            receipt = make_receipt(store.plan, store.plan_sha, "PROD-KT-CY", "5000",
                                   chunk.first_day, chunk.last_day, 1018, norm, raw)
            with self.assertRaisesRegex(ValueError, "complete previous engine year"):
                store.commit_chunk("PROD-KT-CY", "5000", 1018, norm,
                                   raw_stdout=raw, native_receipt=receipt)
            self.assertEqual(store.progress()["committed_chunks"], 4)


if __name__ == "__main__":
    unittest.main()
