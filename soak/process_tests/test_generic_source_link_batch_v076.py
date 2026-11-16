"""v076: prove immutable generic witness scanning is O(N) per recovery.

No source F(c,t) calls or GitHub artifact downloads; mocked link records are
deliberately NOT acceptable as original-date evidence.
"""
from __future__ import annotations

from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))

import original_generic_source_chunk_ledger_v073 as generic
from original_ref41_year_chunk_import_v059 import check_original_process_chunk_links


class _Cursor:
    def __init__(self,rows):
        self.rows=rows
    def fetchall(self):
        return list(self.rows)


class _Db:
    def __init__(self,rows):
        self.rows=rows
    def execute(self,query,*args):
        if query.startswith("SELECT engine,year,ordinal,artifact_sha256,native_raw_sha256,"):
            return _Cursor(self.rows)
        raise AssertionError("unexpected SQL in synthetic batch oracle: "+query)


class _Store:
    plan={}
    years={}
    def __init__(self,rows):
        self.db=_Db(rows)
    def _assert_immutable_plan(self):
        return None


def _link(ordinal):
    return ("REF-41","5000",ordinal,"a"*64,"b"*64,"c"*64,"d"*64)


class GenericSourceWitnessBatchV076(unittest.TestCase):
    def test_three_generic_links_trigger_only_one_global_witness_audit(self):
        rows=[_link(i) for i in (1017,1018,1019)]
        store=_Store(rows)
        with patch.object(generic,"check_generic_witnesses",return_value=3) as audit:
            with patch.object(generic,"verify_generic_source_link") as check_link:
                self.assertEqual(check_original_process_chunk_links(store),3)
        audit.assert_called_once_with(store)
        self.assertEqual(check_link.call_count,3)
        self.assertEqual(
            [call.kwargs["generic_witnesses_prevalidated"] for call in check_link.call_args_list],
            [True,True,True])

    def test_global_audit_failure_aborts_without_any_link_acceptance(self):
        store=_Store([_link(1017),_link(1018)])
        with patch.object(generic,"check_generic_witnesses",side_effect=ValueError("tampered witness")):
            with patch.object(generic,"verify_generic_source_link") as check_link:
                with self.assertRaisesRegex(ValueError,"tampered witness"):
                    check_original_process_chunk_links(store)
                check_link.assert_not_called()

    def test_standalone_link_call_still_audits_global_witnesses(self):
        with patch.object(generic,"manifest_for",return_value=({"artifact_sha256":"a"*64},"f"*64)):
            with patch.object(generic,"check_generic_witnesses",side_effect=ValueError("invalid ledger")) as audit:
                with self.assertRaisesRegex(ValueError,"invalid ledger"):
                    generic.verify_generic_source_link(object(),_link(1017))
                audit.assert_called_once()

    def test_prevalidated_link_still_rejects_corrupt_zip(self):
        with tempfile.TemporaryDirectory() as d:
            zipped=Path(d)/"bad.zip"
            zipped.write_bytes(b"not a valid ZIP")
            pin={"artifact_sha256":"a"*64}
            with patch.object(generic,"manifest_for",return_value=(pin,"f"*64)):
                with patch.object(generic,"check_generic_witnesses",side_effect=AssertionError("no rescan")) as audit:
                    with patch.object(generic,"witness_paths",return_value=(None,None,zipped,None)):
                        with patch.object(generic,"archive_files",side_effect=ValueError("corrupt ZIP")) as archive:
                            with self.assertRaisesRegex(ValueError,"corrupt ZIP"):
                                generic.verify_generic_source_link(
                                    object(),_link(1017),
                                    generic_witnesses_prevalidated=True)
                    audit.assert_not_called()
                    archive.assert_called_once_with(b"not a valid ZIP",pin)


if __name__=="__main__":
    unittest.main()
