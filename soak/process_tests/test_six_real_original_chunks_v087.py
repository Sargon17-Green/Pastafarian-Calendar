"""v087: sixth pinned original two-day chunk in disposable CrashStore.

This suite does NOT run original F(c,t); all ZIPs are GitHub-original evidence.
"""
from __future__ import annotations
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from recovery_store import CrashStore
from original_ref41_year_chunk_import_v059 import (
    locked_full_year_experimental_plan,import_real_original_ref41_baseline,
    check_original_process_chunk_links)
from original_next_chunk_import_v066 import import_next_original_python_chunk
from original_generic_source_chunk_ledger_v073 import (
    import_generic_original_ref41_chunk,manifest_for,check_generic_witnesses,
    offline_original_chunk)
from original_chunk_artifact_gate_v072 import archive_files
from native_execution_receipt_v038 import make_receipt


class SixActualOriginalSourceChunks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        names=[f"PASTAFARI_ZIP_{i}" for i in range(1015,1021)]
        names+=["PASTAFARI_ORIGINAL_PYTHON_ROOT","PASTAFARI_ORIGINAL_KOTLIN_GIT"]
        env=[os.environ.get(n) for n in names]
        if any(v is None for v in env):
            raise RuntimeError("all six genuine source ZIPs and unchanged original trees required")
        cls.zips={i:Path(env[i-1015]).read_bytes() for i in range(1015,1021)}
        cls.python=Path(env[6]).resolve(strict=True)
        cls.kotlin=Path(env[7]).resolve(strict=True)
        cls.plan=locked_full_year_experimental_plan(cls.python,cls.kotlin,cls.zips[1015])
        cls.pin,_=manifest_for(1020)
        cls.files=archive_files(cls.zips[1020],cls.pin)

    def setUp(self):
        temp=tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root=Path(temp.name)/"source-ledger"

    def first_five(self,s):
        import_real_original_ref41_baseline(s,self.zips[1015],self.python,self.kotlin)
        import_next_original_python_chunk(s,self.zips[1015],self.zips[1016],
                                          self.python,self.kotlin)
        for n in range(1017,1020):
            import_generic_original_ref41_chunk(
                s,n,self.zips[n],self.zips[1015],self.python,self.kotlin)

    def six(self,s,archive=None):
        self.first_five(s)
        return self.sixth(s,archive)

    def sixth(self,s,archive=None):
        return import_generic_original_ref41_chunk(
            s,1020,self.zips[1020] if archive is None else archive,
            self.zips[1015],self.python,self.kotlin)

    def test_six_original_archive_chunks_committed_without_year_credit(self):
        with CrashStore(self.root,self.plan) as s:
            outcome=self.six(s)
            self.assertEqual(outcome["outcome"],"COMMITTED")
            self.assertEqual(outcome["ordinal"],1020)
            p=s.progress()
            self.assertEqual(p["committed_chunks"],6)
            self.assertEqual(p["original_process_linked_chunks_not_years"],6)
            self.assertEqual(p["original_generic_source_witnesses_not_years"],4)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"],6)
            self.assertEqual(p["verified_comparisons_completed"],0)
            self.assertEqual(p["fully_verified_years"],0)
            self.assertEqual(check_generic_witnesses(s),4)
            self.assertEqual(check_original_process_chunk_links(s),6)
            chunk=s._chunk("REF-41","5000",1020)
            self.assertEqual((chunk.first_day,chunk.last_day),("-15055662","-15055661"))
            self.assertEqual(s._chunk_path(chunk).read_bytes(),
                             self.files["REF-41/native-normalized.jsonl"])

    def test_full_offline_recovery_verifies_six_immutable_source_links(self):
        with CrashStore(self.root,self.plan) as s:
            self.six(s)
        with CrashStore(self.root,self.plan) as s:
            recovered=s.verify_and_recover()
            self.assertEqual(recovered["original_source_process_chunk_links_revalidated"],6)
            self.assertEqual(recovered["original_generic_source_witnesses_revalidated"],4)
            self.assertEqual(recovered["verified_existing_chunks"],6)
            self.assertEqual(recovered["recovered_chunks"],0)
            self.assertEqual(recovered["progress"]["fully_verified_years"],0)

    def test_modified_1020_source_zip_rejected_before_chunk_commit(self):
        modified=self.zips[1020][:-1]+bytes([self.zips[1020][-1]^1])
        with CrashStore(self.root,self.plan) as s:
            self.first_five(s)
            with self.assertRaises(ValueError):
                self.sixth(s,modified)
            self.assertEqual(s.progress()["committed_chunks"],5)

    def test_deleted_1020_process_link_requires_explicit_same_source_replay(self):
        with CrashStore(self.root,self.plan) as s:
            self.six(s)
            s.db.execute(
                "DELETE FROM original_process_chunk_links WHERE "
                "engine='REF-41' AND year='5000' AND ordinal=1020")
            with self.assertRaisesRegex(ValueError,"lost original process ZIP link"):
                s.verify_and_recover()
        with CrashStore(self.root,self.plan) as s:
            self.assertEqual(self.sixth(s)["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(s.verify_and_recover()[
                "original_source_process_chunk_links_revalidated"],6)

    def test_missing_predecessor_process_link_never_bypassed(self):
        with CrashStore(self.root,self.plan) as s:
            self.first_five(s)
            s.db.execute(
                "DELETE FROM original_process_chunk_links WHERE "
                "engine='REF-41' AND year='5000' AND ordinal=1019")
            with self.assertRaises(ValueError):
                self.sixth(s)
            self.assertEqual(s.progress()["committed_chunks"],5)

    def test_kotlin_candidate_1020_cannot_commit_before_full_python_year(self):
        with CrashStore(self.root,self.plan) as s:
            self.six(s)
            chunk=s._chunk("PROD-KT-CY","5000",1020)
            norm=self.files["kotlin-index-only-normalized.jsonl"]
            raw=self.files["PROD-KT-CY/os-stdout.tsv"]
            receipt=make_receipt(s.plan,s.plan_sha,"PROD-KT-CY","5000",
                                 chunk.first_day,chunk.last_day,1020,norm,raw)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                s.commit_chunk("PROD-KT-CY","5000",1020,norm,
                               raw_stdout=raw,native_receipt=receipt)
            self.assertEqual(s.progress()["committed_chunks"],6)


if __name__=="__main__":
    unittest.main()
