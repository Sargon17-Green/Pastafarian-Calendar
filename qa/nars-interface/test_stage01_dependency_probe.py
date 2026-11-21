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
        self.assertEqual(self.receipt["program_count"], 96)

    def test_exact_original_source_lines_and_diagnostic_anchors(self):
        anchors = self.receipt["source_dependency_anchors"]
        self.assertEqual([anchors[x]["source_line"] for x in ("ownership", "oracle", "year")],
                         [39, 108, 147])
        self.assertEqual(anchors["sauce"]["source_function"], "Sauce")
        self.assertEqual(anchors["gap"]["source_function"], "GateGap")
        self.assertEqual(anchors["post_stir_saved"]["source_function"], "PostStir12")
        self.assertEqual(anchors["post_saved"]["source_function"], "PostStirSavedSum")
        self.assertEqual(anchors["post_stir_perm"]["source_function"], "PermutationUnrank1")
        for a in anchors.values():
            self.assertEqual(a["source_sha256"], hashlib.sha256(a["source_text"].encode()).hexdigest())

    def test_messages_and_probe_inventory_are_complete_not_acceptance(self):
        r = self.receipt
        self.assertEqual(r["schema"], "APL_GERMAN_STAGE01_ROOTCAUSE_DIAGNOSTIC_V4")
        self.assertEqual(r["stage01"], "NOT_ACCEPTED")
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertEqual(r["marker_token"], FINAL)
        self.assertEqual(r["program_count"], 96)
        self.assertEqual(len(r["dependency_probes"]), 61)
        self.assertEqual(len({p["start_path"] for p in r["dependency_probes"]}), 61)
        self.assertEqual(len({p["message_path"] for p in r["dependency_probes"]}), 61)
        self.assertTrue(all(c["message_code_path"] for c in r["calls"]))
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][13:18]],
            ["ownership_expected_dr", "ownership_actual_dr", "ownership_numeric_equal",
             "ownership_expected_rank", "ownership_actual_rank"]
        )
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][18:28]],
            ["sauce_work_counts", "sauce_build_hidden", "sauce_build_visible",
             "sauce_initial_bowls", "sauce_apply_visible", "sauce_post_stir",
             "sauce_result", "sauce_next_bowl", "sauce_ask_bowl", "sauce_choose_rank"]
        )
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][28:43]],
            ["ownership_vector_match", "sauce_post_old", "sauce_post_saved",
             "sauce_post_saved_value", "sauce_post_rank", "sauce_post_rank_value",
             "sauce_post_order", "sauce_post_order_value", "sauce_post_first_id",
             "sauce_post_first_prev", "sauce_post_first_next", "sauce_post_first_s",
             "sauce_post_first_value", "sauce_post_next_bowls", "sauce_post_assign_first"]
        )
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][43:]],
            ["ownership_vector_match_correct", "sauce_post_old_shape", "sauce_post_old_rank",
             "sauce_post_old_sum", "sauce_post_old_value", "sauce_post_saved_shape",
             "sauce_post_saved_rank", "sauce_post_saved_known_vector",
             "sauce_post_saved_known_vector_rank", "sauce_post_rank_shape",
             "sauce_post_rank_rank"]
        )
        self.assertEqual(
            [p["name"] for p in r["dependency_probes"][54:]],
            ["sauce_fixed_fx_exists", "sauce_fixed_saved_known", "sauce_fixed_saved_actual",
             "sauce_fixed_saved_actual_rank", "sauce_fixed_order",
             "sauce_fixed_poststir12", "sauce_fixed_poststir12_value"]
        )
        fixed = r["qa_fixed_poststir"]
        self.assertEqual(fixed["source_function"], "PostStir12")
        self.assertEqual(fixed["copy_function"], "QAFixedPostStir12")
        self.assertEqual(fixed["helper_function"], "QAFixedPostStirSavedSum")
        self.assertEqual(len(fixed["source_sha256"]), 64)
        self.assertEqual(len(fixed["copy_sha256"]), 64)
        self.assertEqual(len(fixed["helper_sha256"]), 64)
        self.assertIn("bowls←⊃⊃args[1]", fixed["only_logic_change"])
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
