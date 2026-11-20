"""v141: fail-closed tests for original month-weave DP port contract; no Fct."""
from __future__ import annotations
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_ada_month_weave_dp_contract_v141 as v

P=Path(__file__).resolve().parents[1]/"control"/"ada_month_weave_dp_contract_v141.json"

PY_SOURCE=b"""
class MonthWeavingFamily:
    def _state_count(
    def _moves(
    def unrank1(
    if n == 1 and index != closed:
    for index in range(closed, opened):
    if opened < self.month_count:
    next_opened = opened + 1
    block = self._state_count(
    if rank1 > block:
    rank1 -= block
    row[x] = weighted_prefix[x + n - 1]
    comb(y - 1, n - 2) * self._h[opened + 1][y]
    base_count *= comb(n + base_length - 1, base_length)
"""
ADA_SOURCE=b"""
    function From_Choices
    Remains (J) := Lengths (J) - 2;
    Output (Pos) := J;
"""

class GH:
    def __init__(self):
        self.run={"id":v.V140_RUN,"head_sha":v.V140_SHA,
                  "status":"completed","conclusion":"success"}
        self.art={"total_count":1,"artifacts":[{
            "id":v.V140_ART,"digest":"sha256:"+v.V140_ZIP_SHA,
            "expired":False}]}
        self.issue={"number":29,"state":"open",
                    "body":"CONFIRMED_ORIGINAL_SOURCE_MISMATCH"}
    def get(self,path):
        base="/repos/"+v.REPO
        if path==base+"/actions/runs/"+str(v.V140_RUN):return self.run
        if path==base+"/actions/runs/"+str(v.V140_RUN)+"/artifacts?per_page=100":
            return self.art
        if path==base+"/issues/29":return self.issue
        raise AssertionError("unexpected GitHub call "+path)

class V141Synthetic(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(P.read_text(encoding="utf-8"))
        self.gh=GH()
        self.src={v.PY_SHA:PY_SOURCE,v.ADA_SHA:ADA_SOURCE}
        self.blobs={v.PY_SHA:v.PY_BLOB,v.ADA_SHA:v.ADA_BLOB}
        def loader(_gh,repo,rev,path):
            self.assertEqual(repo,v.REPO)
            self.assertEqual(path,"tests/normative_reference.py" if rev==v.PY_SHA
                             else "src/month_weaving.adb")
            return self.src[rev],{"git_blob_sha1":self.blobs[rev]}
        self.mock=patch.object(v,"checked_blob",side_effect=loader)
        self.mock.start()
        self.addCleanup(self.mock.stop)
    def test_contract_exact_source_and_scientific_stop(self):
        v.manifest_check(self.m)
    def test_source_two_frozen_original_blobs(self):
        self.assertEqual(v.source_check(self.m,self.gh)["original_source_blobs_pinned"],2)
    def test_previous_v140_ci_artifact_and_open_original_mismatch_issue(self):
        self.assertTrue(v.previous_qa_check(self.gh)["issue_29_open"])
    def test_full_pure_mathematical_fixtures(self):
        x=v.mathematical_fixture_checks(self.m)
        self.assertEqual(len(x["fixtures"]),6)
        self.assertTrue(x["all_expected_legal_counts_and_rank_bijections_verified"])
        self.assertFalse(x["original_Fct_covered"])
    def test_family_4_4_exact_count_20_versus_ada_6(self):
        self.assertEqual(v.FullFamilyDP((4,4)).count(),20)
        self.assertEqual(v.fixed_two_rail_count((4,4)),6)
    def test_independent_brute_matches_all_20_sequences(self):
        model=v.FullFamilyDP((4,4))
        brute=v.exhaustive((4,4))
        self.assertEqual(len(brute),20)
        self.assertEqual([model.unrank(i) for i in range(1,21)],brute)
    def test_independent_brute_matches_all_35_sequences_4_5(self):
        model=v.FullFamilyDP((4,5))
        brute=v.exhaustive((4,5))
        self.assertEqual(len(brute),35)
        self.assertEqual([model.unrank(i) for i in range(1,36)],brute)
    def test_independent_brute_matches_all_1301_4_4_4(self):
        model=v.FullFamilyDP((4,4,4))
        brute=v.exhaustive((4,4,4))
        self.assertEqual(len(brute),1301)
        self.assertTrue(all(model.unrank(i)==seq
                     for i,seq in enumerate(brute,1)))
    def test_independent_brute_matches_all_3499_4_5_4(self):
        model=v.FullFamilyDP((4,5,4))
        brute=v.exhaustive((4,5,4))
        self.assertEqual(len(brute),3499)
        self.assertTrue(all(model.rank(seq)==i
                     for i,seq in enumerate(brute,1)))
    def test_177260_count_without_enumerating_original_calendar(self):
        model=v.FullFamilyDP((4,4,4,4))
        self.assertEqual(model.count(),177260)
        for rank in (1,3,88700,177259,177260):
            self.assertEqual(model.rank(model.unrank(rank)),rank)
    def test_singleton_months_preserve_order(self):
        self.assertEqual(v.FullFamilyDP((1,1,1)).count(),1)
        self.assertEqual(v.FullFamilyDP((1,1,1)).unrank(1),(1,2,3))
    def test_tiny_mixed_months_2_2_2_have_5_sequences(self):
        model=v.FullFamilyDP((2,2,2))
        self.assertEqual(model.count(),5)
        self.assertEqual([model.unrank(i) for i in range(1,6)],
                         v.exhaustive((2,2,2)))
    def test_rank_is_one_based_and_zero_rejected(self):
        with self.assertRaisesRegex(ValueError,"one-based"):
            v.FullFamilyDP((4,4)).unrank(0)
    def test_rank_greater_than_family_is_rejected(self):
        with self.assertRaisesRegex(ValueError,"one-based"):
            v.FullFamilyDP((4,4)).unrank(21)
    def test_rank_rejects_illegal_sequence(self):
        with self.assertRaisesRegex(ValueError,"not in original legal"):
            v.FullFamilyDP((4,4)).rank((2,2,2,2,1,1,1,1))
    def test_brute_guard_disallows_too_many_days(self):
        with self.assertRaisesRegex(ValueError,"brute enumeration forbidden"):
            v.exhaustive((4,4,4,4,4))
    def test_month_model_guard_disallows_more_than_30_days(self):
        with self.assertRaisesRegex(ValueError,"finite toy"):
            v.FullFamilyDP((4,4,4,4,4,4,4,4))
    def test_noninteger_month_length_rejected(self):
        with self.assertRaisesRegex(ValueError,"finite toy"):
            v.FullFamilyDP((4,4.0))
    def test_original_ada_git_blob_substitution_rejected(self):
        self.blobs[v.ADA_SHA]="f"*40
        with self.assertRaisesRegex(ValueError,"source Git blob"):
            v.source_check(self.m,self.gh)
    def test_original_python_global_rank_source_mutation_rejected(self):
        self.src[v.PY_SHA]=b"class MonthWeavingFamily: def unrank1("
        with self.assertRaisesRegex(ValueError,"DP states/transitions"):
            v.source_check(self.m,self.gh)
    def test_previous_qa_queue_cannot_upgrade_to_pass(self):
        self.gh.run["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            v.previous_qa_check(self.gh)
    def test_qa_artifact_digest_flip_rejected(self):
        self.gh.art["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"digest/availability"):
            v.previous_qa_check(self.gh)
    def test_original_mismatch_issue_close_requires_formal_gate(self):
        self.gh.issue["state"]="closed"
        with self.assertRaisesRegex(ValueError,"no longer verifiably open"):
            v.previous_qa_check(self.gh)
    def test_unsafe_claim_of_ada_implementation_rejected(self):
        self.m["dp_contract"]["production_ada_implementation_not_yet_provided"]=False
        with self.assertRaisesRegex(ValueError,"production readiness"):
            v.manifest_check(self.m)
    def test_unsafe_native_soak_restart_rejected(self):
        self.m["scientific_status"]["STOP_NEW_NATIVE_SOAK_DISPATCH"]=False
        with self.assertRaisesRegex(ValueError,"stop gate"):
            v.manifest_check(self.m)
    def test_unsafe_year_acceptance_claim_rejected(self):
        self.m["scientific_status"]["original_full_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"stop gate"):
            v.manifest_check(self.m)
    def test_global_rank_schedule_cannot_be_replaced_by_tickets(self):
        self.m["source_ordered_transitions"]["rank_schedule"]="one ticket per slot"
        with self.assertRaisesRegex(ValueError,"global rank contract"):
            v.manifest_check(self.m)
    def test_full_readonly_audit_zero_original_Fct(self):
        result=v.audit(self.m,self.gh)
        self.assertEqual(result["new_native_or_calendar_Fct_executions"],0)
        self.assertEqual(result["scientific_original_full_years_certified"],0)
        self.assertFalse(result["Ada_production_patch_made"])
        self.assertFalse(result["sole_cause_of_foundation_mismatch_proven"])
        self.assertTrue(result["STOP_NEW_NATIVE_SOAK_DISPATCH"])

    def test_29_portable_goldens_verify_35_exact_one_based_sequences(self):
        path=P.parent/"ada_month_weave_rank_vectors_v141.json"
        vectors=json.loads(path.read_text(encoding="utf-8"))
        result=v.golden_vectors_check(vectors)
        self.assertEqual(result["portable_rank_vector_groups"],6)
        self.assertEqual(result["portable_rank_vectors_verified"],35)
        self.assertFalse(result["production_Ada_code_compiled"])
    def test_30_mutated_portable_golden_day_rejected(self):
        path=P.parent/"ada_month_weave_rank_vectors_v141.json"
        vectors=json.loads(path.read_text(encoding="utf-8"))
        vectors["families"][0]["vectors"][0][1][0]=2
        with self.assertRaisesRegex(ValueError,"golden vector differs"):
            v.golden_vectors_check(vectors)
    def test_31_removed_portable_family_rejected(self):
        path=P.parent/"ada_month_weave_rank_vectors_v141.json"
        vectors=json.loads(path.read_text(encoding="utf-8"))
        vectors["families"].pop()
        with self.assertRaisesRegex(ValueError,"family count changed"):
            v.golden_vectors_check(vectors)
    def test_32_portable_goldens_cannot_authorize_original_native_soak(self):
        path=P.parent/"ada_month_weave_rank_vectors_v141.json"
        vectors=json.loads(path.read_text(encoding="utf-8"))
        vectors["allowed_in_original_soak_dispatch"]=True
        with self.assertRaisesRegex(ValueError,"not approved original"):
            v.golden_vectors_check(vectors)

if __name__=="__main__":unittest.main()
