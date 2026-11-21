"""Deterministic source-locked QA-only root-cause candidate tests."""
import hashlib
import pathlib
import unittest
from stage01_dependency_probe import build_dependency_probe, FINAL
from stage01_statement_probe import build_statement_probe
from stage01_import_workspace import SOURCE_COMMIT

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARKER = r"D:\a\_temp\apl_german_rootcause_probe.txt"
BASE = """[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
""".encode("cp1252")


class RootCauseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.candidate, cls.receipt = build_dependency_probe(BASE, ROOT, MARKER)

    def test_source_lock_and_unchanged_95fx_prefix(self):
        previous, r = build_statement_probe(BASE, ROOT, MARKER)
        self.assertEqual(self.receipt["source_commit"], SOURCE_COMMIT)
        self.assertEqual(self.receipt["import_program_sha256"], r["import_program_sha256"])
        self.assertEqual(self.receipt["prior_candidate_sha256"], hashlib.sha256(previous).hexdigest())
        self.assertEqual((self.receipt["function_count"], self.receipt["chunk_count"]), (95, 23))
        self.assertEqual((len(self.receipt["tests"]), len(self.receipt["calls"])), (3, 3))
        self.assertEqual(self.receipt["program_count"], 62)

    def test_exact_original_source_lines_and_diagnostic_anchors(self):
        anchors = self.receipt["source_dependency_anchors"]
        self.assertEqual([anchors[x]["source_line"] for x in ("ownership", "oracle", "year")],
                         [39, 108, 147])
        self.assertIn("Sauce", anchors)
        self.assertIn("GateGap", anchors)
        for a in anchors.values():
            self.assertEqual(a["source_sha256"], hashlib.sha256(a["source_text"].encode()).hexdigest())

    def test_messages_and_probe_inventory_are_complete_not_acceptance(self):
        r = self.receipt
        self.assertEqual(r["schema"], "APL_GERMAN_STAGE01_ROOTCAUSE_DIAGNOSTIC_V1")
        self.assertEqual(r["stage01"], "NOT_ACCEPTED")
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertEqual(r["marker_token"], FINAL)
        self.assertEqual(r["program_count"], 62)
        self.assertEqual(len(r["dependency_probes"]), 28)
        self.assertEqual(len({p["start_path"] for p in r["dependency_probes"]}), 28)
        self.assertEqual(len({p["message_path"] for p in r["dependency_probes"]}), 28)
        self.assertTrue(all(c["message_code_path"] for c in r["calls"]))
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][13:18]],
            ["ownership_expected_dr", "ownership_actual_dr", "ownership_numeric_equal",
             "ownership_expected_rank", "ownership_actual_rank"]
        )
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][18:]],
            ["sauce_work_counts", "sauce_build_hidden", "sauce_build_visible",
             "sauce_initial_bowls", "sauce_apply_visible", "sauce_post_stir",
             "sauce_result", "sauce_next_bowl", "sauce_ask_bowl", "sauce_choose_rank"]
        )
        for p in r["dependency_probes"]:
            self.assertTrue(p["start_token"].endswith("START"))
            self.assertTrue(p["captured_token"].endswith("CAPTURED_NOT_PASS"))
            self.assertNotEqual(p["start_path"], p["captured_path"])
            self.assertRegex(p["program_sha256"], "^[0-9a-f]{64}$")

    def test_determinism_and_crlf(self):
        c2, r2 = build_dependency_probe(BASE, ROOT, MARKER)
        self.assertEqual((c2, r2), (self.candidate, self.receipt))
        self.assertEqual(hashlib.sha256(c2).hexdigest(), r2["candidate_sha256"])
        crlf, _ = build_dependency_probe(BASE.replace(b"\n", b"\r\n"), ROOT, MARKER)
        self.assertNotIn(b"\n", crlf.replace(b"\r\n", b""))


if __name__ == "__main__":
    unittest.main()
