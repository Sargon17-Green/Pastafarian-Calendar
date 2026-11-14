"""Candidate year boundaries: data consistency only; NOT independent canonical proof."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import unittest

CANDIDATE=Path(__file__).resolve().parents[1]/"control/foundation_year5000_two_native_candidate_v021.json"
FIELDS=("calculation_day","year","open_gate_index","close_gate_index",
        "open_gate_day","close_gate_day","first_target_day","last_target_day")


class FoundationYearCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=json.loads(CANDIDATE.read_text(encoding="utf8"))

    def test_candidate_is_never_implicitly_certified(self):
        d=self.document
        self.assertEqual(d["schema"],"PASTAFARI_SOAK_YEAR_BOUNDARY_CANDIDATE/1")
        self.assertEqual(d["status"],"TWO_NATIVE_BOUNDARY_CANDIDATES_AGREE_NOT_INDEPENDENT")
        for name in ("independent_boundary_oracle_proven",
                     "algorithmic_independence_proven",
                     "boundaries_admitted_for_full_year_soak",
                     "main_changes_permitted"):
            self.assertIs(d[name],False)
        self.assertEqual(d["verified_comparisons_completed"],0)

    def test_year_edges_contiguity_and_safe_length(self):
        d=self.document
        c=int(d["calculation_day"])
        o,cl=int(d["open_gate_day"]),int(d["close_gate_day"])
        self.assertLess(o,c)
        self.assertLessEqual(c,cl)
        self.assertEqual(int(d["first_target_day"]),o+1)
        self.assertEqual(int(d["last_target_day"]),cl)
        self.assertEqual(int(d["length_days"]),cl-o)
        self.assertTrue(252<=cl-o<=5778)
        self.assertGreaterEqual(int(d["close_gate_index"])-int(d["open_gate_index"]),6)

    def test_reconstruct_exact_ci_candidate_hash(self):
        d=self.document
        obj={k:d[k] for k in FIELDS}
        witness=(json.dumps(obj,sort_keys=True,separators=(",",":"))+"\n").encode("utf8")
        self.assertEqual(hashlib.sha256(witness).hexdigest(),d["candidate_receipt_sha256"])

    def test_pinned_native_provenance_not_counted_twice(self):
        sources=self.document["sources"]
        self.assertEqual({x["id"] for x in sources},{"REF-41","REF-24"})
        self.assertEqual(len({x["commit"] for x in sources}),2)
        self.assertTrue(all(len(x["commit"])==40 for x in sources))
        self.assertNotEqual(sources[0]["source"],sources[1]["source"])


if __name__=="__main__":
    unittest.main()
