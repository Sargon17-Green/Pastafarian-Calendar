"""Synthetic 91-record v129+v130 evidence lineage checks, never native F(c,t)."""
from __future__ import annotations

import copy
import hashlib
import sys
from pathlib import Path
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))

from soak_scope_coverage_v127 import digest
from soak_source_lineage_screen_v131 import screen
from soak_source_census_v129 import git_blob_sha1
from soak_triage_path_v130 import run as triage_run
from test_soak_triage_path_v130 import fixture as triage_fixture, FakeGitHub


def sha_of(data):
    return {"source_sha256":hashlib.sha256(data).hexdigest(),
            "git_blob_sha1":git_blob_sha1(data),"bytes":len(data)}


def fixture():
    candidates,provenance,census,blobs=triage_fixture()
    roster={"schema":"PASTAFARI_SOAK_SOURCE_ROSTER_V127/1",
            "records":[{"record_id":r["record_id"],"engine_id":r["record_id"],
                        "algorithm_id":"UNASSESSED",
                        "source_kind":"triage" if r["source_path"] is None
                                      else "reference"}
                       for r in provenance["records"]]}
    census.update({
        "roster_sha256":digest(roster),
        "frozen_lock_sha256":None,
        "official_years_certified":0,
        "independent_execution_attested":False
    })
    lock_map={}
    for row in census["records"]:
        rid=row["record_id"]
        row.update({
            "observed_source":None if row["archived_source_path"] is None
                              else sha_of(("source content: "+rid+"\n").encode()),
            "frozen_source_lock_status":"NO_FROZEN_SOURCE_LOCK",
            "locked_commit":None,
            "native_build_success_verified_by_census":False,
            "native_full_date_execution_verified_by_census":False,
            "independent_algorithm_certified_by_census":False,
            "eligible_for_soak":False
        })
        if rid in {"REF-24","REF-41"}:
            row["frozen_source_lock_status"]="FROZEN_SOURCES_SHA_LOCK_PASS"
            row["locked_commit"]=row["observed_head_commit"]
            lock_map[rid]=row["observed_head_commit"]
    locks={
        "schema":"PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1",
        "main_changes_permitted":False,
        "engines":[{"id":rid,"commit":head}
                   for rid,head in sorted(lock_map.items())]
    }
    census["frozen_lock_sha256"]=digest(locks)
    triage=triage_run(candidates,provenance,census,FakeGitHub(blobs))
    index={
        "schema":"PASTAFARI_SOAK_PINNED_SOURCE_CI_JOB_INDEX_V129/1",
        "full_year_verified":False,
        "native_execution_attested":False,
        "independent_algorithms_certified":False,
        "claims":[{"record_id":rid} for rid in sorted(lock_map)]
    }
    ci={
        "schema":"PASTAFARI_SOAK_PINNED_CI_JOB_OBSERVATIONS_V129/1",
        "source_census_sha256":digest(census),
        "ci_index_sha256":digest(index),
        "frozen_lock_sha256":digest(locks),
        "claims_checked":2,
        "native_date_calls":0,"original_full_years_certified":0,
        "independent_algorithms_certified":False,
        "soak_dispatch_authorized":False,
        "observations":[{
            "record_id":rid,"source_commit":head,
            "ci_status":"PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED",
            "combined_source_ci_status":
                "SOURCE_LOCK_AND_HISTORICAL_CI_STATUS_OBSERVED",
            "pinned_source_sha_observation":"FROZEN_SOURCES_SHA_LOCK_PASS",
            "eligible_for_soak":False,
            "native_full_date_execution_proven":False,
            "original_full_years_certified":0
        } for rid,head in sorted(lock_map.items())]
    }
    return roster,provenance,census,candidates,triage,index,ci,locks


class SourceLineageTests(unittest.TestCase):
    def setUp(self):
        self.docs=list(fixture())

    def screen(self):
        return screen(*self.docs)

    def relock(self):
        r,p,c,m,t,i,ci,l=self.docs
        c["provenance_sha256"]=digest(p)
        c["roster_sha256"]=digest(r)
        c["frozen_lock_sha256"]=digest(l)
        t["archived_provenance_sha256"]=digest(p)
        t["v129_census_sha256"]=digest(c)
        t["candidate_manifest_sha256"]=digest(m)
        ci["source_census_sha256"]=digest(c)
        ci["ci_index_sha256"]=digest(i)
        ci["frozen_lock_sha256"]=digest(l)

    def test_all_91_bound_with_no_fake_soak_certification(self):
        result=self.screen()
        self.assertEqual(result["total_historical_records"],91)
        self.assertEqual(result["archived_source_paths_verified"],81)
        self.assertEqual(result["additional_triage_paths_verified_without_native_certification"],10)
        self.assertEqual(result["source_rows_bound_to_git_sha256"],91)
        self.assertEqual(result["pinned_source_and_historical_ci_record_ids"],
                         ["REF-24","REF-41"])
        self.assertEqual(result["native_original_full_date_engines_certified"],0)
        self.assertEqual(result["independent_algorithm_count_certified"],0)
        self.assertEqual(result["official_10000_year_soak_credit"],0)
        self.assertFalse(result["soak_dispatch_authorized"])
        self.assertTrue(all(not row["eligible_for_soak"] for row in result["records"]))

    def test_single_file_sha_reuse_across_different_branches_is_flagged(self):
        r,p,c,m,t,i,ci,l=self.docs
        a=next(x for x in c["records"] if x["record_id"]=="REF-10")
        b=next(x for x in c["records"] if x["record_id"]=="REF-11")
        b["observed_source"]=copy.deepcopy(a["observed_source"])
        self.relock()
        result=self.screen()
        pair={"REF-10","REF-11"}
        self.assertTrue(any(pair.issubset(set(x["record_ids"]))
                            for x in result["identical_file_content_groups"]))
        self.assertNotEqual(result["distinct_repository_branch_pairs"],0)
        self.assertEqual(result["independent_algorithm_count_certified"],0)

    def test_same_branch_same_commit_detects_shared_tree_not_algorithm(self):
        r,p,c,m,t,i,ci,l=self.docs
        a=next(x for x in p["records"] if x["record_id"]=="REF-10")
        b=next(x for x in p["records"] if x["record_id"]=="REF-11")
        b["branch"]=a["branch"]
        ca=next(x for x in c["records"] if x["record_id"]=="REF-10")
        cb=next(x for x in c["records"] if x["record_id"]=="REF-11")
        cb["branch"]=ca["branch"]
        cb["observed_head_commit"]=ca["observed_head_commit"]
        self.relock()
        result=self.screen()
        self.assertTrue(any(
            set(x["record_ids"])=={"REF-10","REF-11"} for x in result["same_tree_groups"]))
        self.assertFalse(next(x for x in result["records"] if x["record_id"]=="REF-11")
                         ["algorithmic_independence_certified"])

    def test_identical_location_additionally_flags_exact_path_overlap(self):
        r,p,c,m,t,i,ci,l=self.docs
        a=next(x for x in p["records"] if x["record_id"]=="REF-10")
        b=next(x for x in p["records"] if x["record_id"]=="REF-11")
        b["branch"]=a["branch"]
        b["source_path"]=a["source_path"]
        ca=next(x for x in c["records"] if x["record_id"]=="REF-10")
        cb=next(x for x in c["records"] if x["record_id"]=="REF-11")
        cb["branch"]=ca["branch"]
        cb["observed_head_commit"]=ca["observed_head_commit"]
        cb["archived_source_path"]=ca["archived_source_path"]
        cb["observed_source"]=copy.deepcopy(ca["observed_source"])
        self.relock()
        result=self.screen()
        self.assertTrue(any(
            set(x["record_ids"])=={"REF-10","REF-11"}
            for x in result["exact_source_location_groups"]))

    def test_tamper_v129_hash_rejected(self):
        self.docs[2]["roster_sha256"]="0"*64
        with self.assertRaisesRegex(ValueError,"v129 census not pinned"):
            self.screen()

    def test_v130_cannot_swap_a_candidate_path(self):
        self.docs[3]["entries"][0]["candidate_path"]="src/a-different-wrapper.py"
        with self.assertRaisesRegex(ValueError,"v130 Git-tree candidate evidence"):
            self.screen()

    def test_v130_blob_with_broken_sha_rejected(self):
        self.docs[4]["records"][0]["source"]["source_sha256"]="bad"
        with self.assertRaisesRegex(ValueError,"malformed TRIAGE"):
            self.screen()

    def test_v130_native_claim_rejected_even_if_other_receipts_match(self):
        self.docs[4]["records"][0]["candidate_is_verified_original_Fct"]=True
        with self.assertRaisesRegex(ValueError,"triage path or unsafe native promotion"):
            self.screen()

    def test_unknown_source_hash_rejected_not_counted_as_independent(self):
        target=next(x for x in self.docs[2]["records"] if x["record_id"]=="REF-10")
        target["observed_source"]=None
        self.relock()
        with self.assertRaisesRegex(ValueError,"unexpected REF-10 fields"):
            self.screen()

    def test_duplicate_v129_record_rejected(self):
        self.docs[2]["records"][0]["record_id"]=self.docs[2]["records"][1]["record_id"]
        with self.assertRaisesRegex(ValueError,"unknown or repeated v129"):
            self.screen()

    def test_omitted_provenance_record_rejected(self):
        self.docs[1]["records"].pop()
        with self.assertRaisesRegex(ValueError,"archived provenance"):
            self.screen()

    def test_archived_lineage_cannot_promote_itself(self):
        self.docs[0]["records"][0]["algorithm_id"]="SURELY_INDEPENDENT"
        self.relock()
        with self.assertRaisesRegex(ValueError,"promoted without review"):
            self.screen()

    def test_candidate_origin_repository_drift_rejected(self):
        self.docs[4]["records"][0]["repository"]="attacker/clone"
        with self.assertRaisesRegex(ValueError,"triage path or unsafe native promotion"):
            self.screen()

    def test_pinned_ci_status_must_have_completed_job_and_source_sha(self):
        self.docs[6]["observations"][0]["ci_status"]="QUEUED"
        with self.assertRaisesRegex(ValueError,"frozen source or completed CI evidence"):
            self.screen()

    def test_legacy_ci_metadata_cannot_grant_original_full_year_credit(self):
        self.docs[6]["original_full_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"historical pinned CI evidence"):
            self.screen()

    def test_source_observation_cannot_promote_to_eligible(self):
        self.docs[2]["records"][10]["eligible_for_soak"]=True
        # Rebind the derivative v130 and CI document digests so the test
        # reaches the *semantic* self-certification guard, not just the
        # outer immutable-input hash gate.
        self.relock()
        with self.assertRaisesRegex(ValueError,"self-certified historical source"):
            self.screen()


if __name__=="__main__":
    unittest.main()
