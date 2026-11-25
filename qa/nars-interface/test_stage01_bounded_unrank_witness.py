"""Fail-closed unit tests for the native BoundedUnrank QA witness."""
import copy
import hashlib
import pathlib
import unittest

import stage01_bounded_unrank_witness as witness
from stage01_chunked_import import STAGE01_MARKER
from stage01_import_workspace import SOURCE_COMMIT, fx_definition_lines, load_locked_sources

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = b"""[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
"""
MARKER = r"D:\a\_temp\apl_german_bounded_unrank_v27.txt"


class BoundedUnrankWitnessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.candidate, cls.receipt = witness.build_bounded_unrank_witness(
            BASE, ROOT, MARKER
        )

    def test_exact_source_anchor_and_qa_copy_preservation(self):
        locked = load_locked_sources(ROOT)
        block = next(b for b in locked["blocks"] if b["name"] == "BoundedUnrank")
        trace, meta = witness.instrument_bounded_unrank(block)
        source = fx_definition_lines(block)
        self.assertEqual(meta["source_path"], "src/normative_oracle.apl")
        self.assertEqual(meta["source_lines"], [388, 412])
        self.assertEqual(meta["source_function"], "BoundedUnrank")
        self.assertEqual(meta["alias"], "QABoundedUnrankTrace")
        self.assertTrue(meta["source_statements_preserved"])
        self.assertEqual(
            meta["source_definition_sha256"],
            hashlib.sha256("\n".join(source).encode("utf-8")).hexdigest(),
        )
        self.assertEqual(
            meta["steps"],
            witness.TRACE_STEPS,
        )
        self.assertTrue(any("QABoundedTraceLog←QABoundedTraceLog,14" in x for x in trace))
        self.assertTrue(any("QABoundedTraceLog←QABoundedTraceLog,15" in x for x in trace))
        self.assertTrue(any("QABoundedTraceCandidateState" in x for x in trace))

    def test_source_anchor_rejects_a_changed_statement(self):
        locked = load_locked_sources(ROOT)
        block = copy.deepcopy(next(b for b in locked["blocks"] if b["name"] == "BoundedUnrank"))
        block["lines"][1] = block["lines"][1].replace("total←args[1]", "total←args[2]", 1)
        with self.assertRaisesRegex(ValueError, "BOUNDED_UNRANK_SOURCE_ANCHOR_CHANGED"):
            witness.instrument_bounded_unrank(block)

    def test_95_fx_prerequisite_and_23_exact_chunks(self):
        r = self.receipt
        self.assertEqual(r["source_commit"], SOURCE_COMMIT)
        self.assertEqual((r["function_count"], r["chunk_count"]), (95, 23))
        self.assertEqual(r["chunk_boundaries"], [
            5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
            65, 70, 75, 80, 85, 90, 91, 92, 93, 94, 95,
        ])
        self.assertEqual(len(r["chunk_records"]), 23)
        self.assertEqual(len(r["import_program_sha256"]), 23)
        self.assertEqual(r["program_count"], 26)
        self.assertEqual(r["final_expression"], "BOUNDED_UNRANK_WITNESS_ONLY")

    def test_witness_is_exactly_the_failed_native_call(self):
        w = self.receipt["witness"]
        self.assertEqual(w["input"], [12, 3, 4, 4, 1])
        self.assertEqual(w["expected_fixture"], "FIX_BOUNDED_444")
        self.assertEqual(w["original_call"], "BoundedUnrank 12 3 4 4 1")
        self.assertEqual(w["trace_call"], "QABoundedUnrankTrace 12 3 4 4 1")
        self.assertIn("PHASE=COMPILED_DIAGNOSTIC", w["compile_token"])
        self.assertIn("PHASE=START", w["start_token"])
        self.assertIn("CAPTURED_NOT_PASS", w["captured_token"])
        self.assertEqual(self.receipt["trace"]["source_lines"], [388, 412])
        self.assertTrue(self.receipt["trace"]["source_statements_preserved"])

    def test_never_invokes_stage1_entrypoint_or_acceptance_token(self):
        r = self.receipt
        self.assertEqual(r["stage01"], "NOT_ACCEPTED")
        self.assertFalse(r["final_original_stage01_tests_executed"])
        self.assertFalse(r["original_entrypoint_invoked"])
        self.assertFalse(r["original_stage01_acceptance_token_present"])
        self.assertFalse(r["production_source_modified"])
        self.assertIn("NOT_STAGE01", r["marker_token"])
        self.assertNotIn("STAGE01_NATIVE_PASS", r["marker_token"])
        lines, pos, match, programs = witness._decode_chunked_candidate(self.candidate)
        self.assertEqual(len(programs), 26)
        self.assertFalse(any("RunStage01Tests" in p for p in programs[23:]))
        self.assertFalse(any(STAGE01_MARKER in p for p in programs[23:]))

    def test_candidate_hash_and_determinism(self):
        r = self.receipt
        self.assertEqual(hashlib.sha256(self.candidate).hexdigest(), r["candidate_sha256"])
        candidate2, receipt2 = witness.build_bounded_unrank_witness(BASE, ROOT, MARKER)
        self.assertEqual(candidate2, self.candidate)
        self.assertEqual(receipt2, r)
        crlf = BASE.replace(b"\n", b"\r\n")
        candidate3, _ = witness.build_bounded_unrank_witness(crlf, ROOT, MARKER)
        self.assertNotIn(b"\n", candidate3.replace(b"\r\n", b""))


if __name__ == "__main__":
    unittest.main()
