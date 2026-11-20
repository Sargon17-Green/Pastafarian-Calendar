"""16 synthetic fail-closed original Ada/Python weaving-family provenance gates.

Never import either original date engine; pure tiny (4,4) toy enumeration only.
"""
from __future__ import annotations
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_weave_family_divergence_v139 as target

INDEX=Path(__file__).resolve().parents[1]/"control"/"weave_family_divergence_v139.json"

def fake_source(path):
    if path=="src/month_weaving.adb":
        return ("function From_Choices\nfor J in Lengths'Range loop\n"
            "Output (Pos) := J;\nRemains (J) := Lengths (J) - 2;\n"
            "for I in Picks'Range loop\nfunction Canonical_Weave_Count").encode()
    if path=="src/normative_oracle.adb":
        return ("Interior : constant Natural := Total - 2 * M_Count;\n"
            "Tickets (I)\nMonth_Weaving.From_Choices (Lengths, Tickets)\n"
            "Month_Canonical => Positive (Month_Names (Month_Id))").encode()
    if path=="tests/normative_reference.py":
        return ("class MonthWeavingFamily:\n"
            "def _moves(\nfor index in range(closed, opened):\n"
            "if opened < self.month_count:\nnext_opened = opened + 1\n"
            "def choose_month_weaving(\n"
            "family = MonthWeavingFamily(month_lengths)\n"
            "rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())\n"
            "return family.unrank1(rank)").encode()
    if path=="src/pastafari_calendar/legacy_month_weaving.py":
        return ("class LegalMonthWeavingDP:\ndef compatibleMonthWeavingRank(\n"
            "legal_family = LegalMonthWeavingDP(\n"
            "correct_weaving = legal_family.unrank1(").encode()
    if path=="tests/stage14_real_oracle.py":
        return ("seq = list(range(len(lengths)))\n"
            "occurrences = [i for i,n in enumerate(lengths) for _ in range(n-2)]\n"
            "return seq+list(range(len(lengths)))").encode()
    if path=="tests/stage14_real_differential.py":
        return ("PROVISIONAL = (\n    (5000,10,503,30,52),\n)\n"
            "assert date(FOUNDATION,FOUNDATION)==PROVISIONAL[1]").encode()
    raise AssertionError("unexpected source: "+path)

class FakeGH:
    def __init__(self):
        self.issue={"number":29,"state":"open",
            "title":"[SOAK] Ada+తెలుగు original month index 30",
            "body":"CONFIRMED_ORIGINAL_SOURCE_MISMATCH\n"
                 "V103_ADA_ORIGINAL_FCT_NATIVE -15055671 -15055671  5000  10  503  30  52\n"
                 "Fortran+English [5000,10,503,20,56]"}
    def get(self,path):
        if path=="/repos/"+target.REPO+"/issues/29":return self.issue
        raise AssertionError("unexpected API request: "+path)

class V139Cases(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(INDEX.read_text(encoding="utf8"))
        self.gh=FakeGH()
        self.files={path:fake_source(path)
                    for path in list(target.ADA_FILES)+list(target.PY_FILES)}
        self.hashes={**target.ADA_FILES,**target.PY_FILES}
        def loader(_gh,repo,sha,path):
            self.assertEqual(repo,target.REPO)
            self.assertEqual(sha,target.ADA if path in target.ADA_FILES else target.PYTHON)
            return self.files[path],{"git_blob_sha1":self.hashes[path]}
        self.p=patch.object(target,"checked_blob",side_effect=loader)
        self.p.start()
        self.addCleanup(self.p.stop)
    def test_legal_original_family_20_and_ada_6(self):
        x=target.check_family(self.m)
        self.assertEqual((x["python_legal_count"],x["ada_two_rail_count"]),(20,6))
        self.assertEqual(x["original_only_legal_sequences"],14)
        self.assertTrue(x["ada_subset_of_python"])
    def test_original_valid_ada_impossible_weave_example(self):
        a=target.enumerate_original_legal((4,4))
        b=target.enumerate_ada_two_rail((4,4))
        self.assertIn(target.PY_EXAMPLE,a)
        self.assertNotIn(target.PY_EXAMPLE,b)
        self.assertTrue(set(b)<set(a))
    def test_source_six_pinned_blobs(self):
        x=target.check_source(self.m,self.gh)
        self.assertEqual(x["pinned_source_blobs_fetched"],6)
        self.assertTrue(x["Ada_fixed_two_rail_source_confirmed"])
        self.assertTrue(x["Python_original_open_close_interleaving_source_confirmed"])
    def test_branch_local_provisional_is_not_independent_reference_41(self):
        x=target.check_source(self.m,self.gh)
        self.assertTrue(x["Ada_branch_local_provisional_foundation_not_independent_REF41"])
        self.assertFalse(x["sole_cause_of_original_foundation_Fct_mismatch_proven"])
    def test_original_issue_not_closed_or_silently_resolved(self):
        self.assertEqual(target.check_issue(self.gh)["state"],"open")
    def test_original_issue_closed_rejected(self):
        self.gh.issue["state"]="closed"
        with self.assertRaisesRegex(ValueError,"not verifiable"):
            target.check_issue(self.gh)
    def test_failed_issue_body_not_proven(self):
        self.gh.issue["body"]="no original native evidence"
        with self.assertRaisesRegex(ValueError,"not verifiable"):
            target.check_issue(self.gh)
    def test_incorrect_ada_source_blob_sha_rejected(self):
        self.hashes["src/month_weaving.adb"]="f"*40
        with self.assertRaisesRegex(ValueError,"source Git blob mismatch"):
            target.check_source(self.m,self.gh)
    def test_nonrail_ada_source_changes_failclosed(self):
        p="src/month_weaving.adb"
        self.files[p]=self.files[p].replace(b"Remains (J) := Lengths (J) - 2;",b"no longer")
        with self.assertRaisesRegex(ValueError,"Ada source no longer demands"):
            target.check_source(self.m,self.gh)
    def test_python_original_no_opening_move_rejected(self):
        p="tests/normative_reference.py"
        self.files[p]=self.files[p].replace(b"if opened < self.month_count:",b"if False:")
        with self.assertRaisesRegex(ValueError,"Python original legal weaving"):
            target.check_source(self.m,self.gh)
    def test_wrong_local_provisional_expected_rejected(self):
        self.m["local_ada_provisional_oracle_has_same_ada_foundation"]=[5000,10,503,20,56]
        with self.assertRaisesRegex(ValueError,"scientific Fct stop"):
            target.validate(self.m)
    def test_do_not_claim_sole_root_cause_of_foundation(self):
        self.m["not_proven_that_rail_only_explains_foundation_numeric_difference"]=False
        with self.assertRaisesRegex(ValueError,"scientific Fct stop"):
            target.validate(self.m)
    def test_do_not_authorize_original_native_dispatch(self):
        self.m["scientific_soak_dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"scientific Fct stop"):
            target.validate(self.m)
    def test_do_not_claim_10000_accepted(self):
        self.m["year_10000_pass"]=True
        with self.assertRaisesRegex(ValueError,"scientific Fct stop"):
            target.validate(self.m)
    def test_all_remote_static_audit_zero_years_and_no_native_calls(self):
        x=target.audit(self.m,self.gh)
        self.assertTrue(x["source_family_divergence_proven"])
        self.assertTrue(x["foundation_mismatch_single_root_cause_not_proven"])
        self.assertEqual(x["original_native_Fct_calls"],0)
        self.assertEqual(x["scientific_years_certified"],0)
        self.assertFalse(x["soak_dispatch_authorized"])
    def test_non_toy_large_original_day_calculation_forbidden(self):
        with self.assertRaisesRegex(ValueError,"small finite family only"):
            target.enumerate_original_legal((4,4,4))

if __name__=="__main__":unittest.main()
