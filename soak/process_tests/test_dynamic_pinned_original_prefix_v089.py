"""v089: one reusable bounded CI gate for any contiguous frozen source prefix.

All archives are actual pinned GitHub Actions ZIP bytes. NO original F(c,t)
calls and NO complete-year/pair certifications are made in these tests.
"""
from __future__ import annotations
import hashlib
import json
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
    import_generic_original_ref41_chunk,check_generic_witnesses)
from native_execution_receipt_v038 import make_receipt


class DynamicPinnedSourcePrefixV089(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        names=("PASTAFARI_V089_INDEX",
               "PASTAFARI_ORIGINAL_PYTHON_ROOT",
               "PASTAFARI_ORIGINAL_KOTLIN_GIT")
        a=[os.environ.get(n) for n in names]
        if any(v is None for v in a):
            raise RuntimeError("frozen GitHub source index and two true original trees mandatory")
        cls.index=json.loads(Path(a[0]).read_bytes())
        cls.last=cls.index["last_ordinal"]
        cls.sources={
            item["ordinal"]:Path(item["path"]).read_bytes()
            for item in cls.index["artifacts"]
        }
        if list(cls.sources)!=list(range(1015,cls.last+1)):
            raise RuntimeError("noncontiguous original archived source set")
        for entry in cls.index["artifacts"]:
            actual=hashlib.sha256(cls.sources[entry["ordinal"]]).hexdigest()
            if actual!=entry["sha256"]:
                raise RuntimeError("original source ZIP digest differs from frozen CI index")
        cls.pyroot=Path(a[1]).resolve(strict=True)
        cls.ktroot=Path(a[2]).resolve(strict=True)
        cls.plan=locked_full_year_experimental_plan(cls.pyroot,cls.ktroot,cls.sources[1015])

    def setUp(self):
        temp=tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root=Path(temp.name)/"ledger"

    def ingest(self,s,last=None):
        end=self.last if last is None else last
        import_real_original_ref41_baseline(s,self.sources[1015],
                                            self.pyroot,self.ktroot)
        import_next_original_python_chunk(s,self.sources[1015],
                                          self.sources[1016],self.pyroot,self.ktroot)
        result=None
        for ordinal in range(1017,end+1):
            result=import_generic_original_ref41_chunk(
                s,ordinal,self.sources[ordinal],self.sources[1015],
                self.pyroot,self.ktroot)
        return result

    def latest(self,s,payload=None):
        return import_generic_original_ref41_chunk(
            s,self.last,
            self.sources[self.last] if payload is None else payload,
            self.sources[1015],self.pyroot,self.ktroot)

    def test_full_frozen_source_prefix_has_no_year_credit(self):
        with CrashStore(self.root,self.plan) as s:
            r=self.ingest(s)
            self.assertEqual(r["outcome"],"COMMITTED")
            self.assertEqual(r["ordinal"],self.last)
            p=s.progress()
            count=len(self.sources)
            self.assertEqual(p["committed_chunks"],count)
            self.assertEqual(p["original_process_linked_chunks_not_years"],count)
            self.assertEqual(p["original_generic_source_witnesses_not_years"],count-2)
            self.assertEqual(p["native_receipt_rows_recorded_without_revalidation"],count)
            self.assertEqual(p["verified_comparisons_completed"],0)
            self.assertEqual(p["verified_day_pair_comparisons"],0)
            self.assertEqual(p["fully_verified_years"],0)
            self.assertEqual(p["original_native_full_year_soak_passes_certified"],0)
            self.assertFalse(p["all_verified"])
            self.assertEqual(check_original_process_chunk_links(s),count)
            self.assertEqual(check_generic_witnesses(s),count-2)

    def test_offline_reopen_revalidates_every_registered_source(self):
        with CrashStore(self.root,self.plan) as s:
            self.ingest(s)
        with CrashStore(self.root,self.plan) as s:
            r=s.verify_and_recover()
            self.assertEqual(r["verified_existing_chunks"],len(self.sources))
            self.assertEqual(r["recovered_chunks"],0)
            self.assertEqual(r["original_source_process_chunk_links_revalidated"],len(self.sources))
            self.assertEqual(r["progress"]["fully_verified_years"],0)

    def test_changed_latest_original_zip_is_refused(self):
        altered=self.sources[self.last][:-1]+bytes([self.sources[self.last][-1]^1])
        with CrashStore(self.root,self.plan) as s:
            self.ingest(s,self.last-1)
            with self.assertRaises(ValueError):
                self.latest(s,altered)
            self.assertEqual(s.progress()["committed_chunks"],len(self.sources)-1)

    def test_missing_current_process_link_requires_identical_explicit_replay(self):
        with CrashStore(self.root,self.plan) as s:
            self.ingest(s)
            s.db.execute(
                "DELETE FROM original_process_chunk_links WHERE "
                "engine='REF-41' AND year='5000' AND ordinal=?",(self.last,))
            with self.assertRaisesRegex(ValueError,"lost original process ZIP link"):
                s.verify_and_recover()
        with CrashStore(self.root,self.plan) as s:
            self.assertEqual(self.latest(s)["outcome"],"ALREADY_COMMITTED")
            self.assertEqual(s.verify_and_recover()[
                "original_source_process_chunk_links_revalidated"],len(self.sources))

    def test_missing_previous_process_link_fails_closed(self):
        with CrashStore(self.root,self.plan) as s:
            self.ingest(s,self.last-1)
            s.db.execute(
                "DELETE FROM original_process_chunk_links WHERE "
                "engine='REF-41' AND year='5000' AND ordinal=?",(self.last-1,))
            with self.assertRaises(ValueError):
                self.latest(s)
            self.assertEqual(s.progress()["committed_chunks"],len(self.sources)-1)

    def test_kotlin_candidate_requires_completed_python_year(self):
        with CrashStore(self.root,self.plan) as s:
            self.ingest(s)
            chunk=s._chunk("PROD-KT-CY","5000",self.last)
            from original_generic_source_chunk_ledger_v073 import manifest_for
            from original_chunk_artifact_gate_v072 import archive_files
            pin,_=manifest_for(self.last)
            files=archive_files(self.sources[self.last],pin)
            norm=files["kotlin-index-only-normalized.jsonl"]
            raw=files["PROD-KT-CY/os-stdout.tsv"]
            receipt=make_receipt(s.plan,s.plan_sha,"PROD-KT-CY","5000",
                                 chunk.first_day,chunk.last_day,self.last,norm,raw)
            with self.assertRaisesRegex(ValueError,"complete previous engine year"):
                s.commit_chunk("PROD-KT-CY","5000",self.last,norm,
                               raw_stdout=raw,native_receipt=receipt)
            self.assertEqual(s.progress()["committed_chunks"],len(self.sources))


if __name__=="__main__":
    unittest.main()
