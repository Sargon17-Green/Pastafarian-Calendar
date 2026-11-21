#!/usr/bin/env python3
"""v159 static patch plan: 30 adversarial insert/strip/provenance tests."""
from __future__ import annotations
import ast
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_foundation_diagnostic_patchplan_v159 import (
    insert_once,strip_insertions,detect_eol,diff_bytes,python_blocks,
    ada_blocks,make_patched,plan,source_paths,output_paths,PY_ANCHORS,
    ADA_ANCHORS,VAR,MARK_OPEN_PY,MARK_OPEN_ADA
)

PY_SAMPLE=b"def f():\n    y = 1\n    return y\n"
ADA_SAMPLE=(b"procedure Test is\nbegin\n"
            b"   null;\n"
            b"end Test;\n")


class PatchProposalUnitTests(unittest.TestCase):
    def test_01_insert_python_once(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    print(y)"],"PY")
        self.assertIn(b"print(y)",p)
        self.assertEqual(strip_insertions(p,("T",),"PY"),PY_SAMPLE)

    def test_02_insert_ada_once(self):
        p=insert_once(ADA_SAMPLE,"   null;","T",
                      ['   Ada.Text_IO.Put_Line ("T");'],"ADA")
        self.assertIn(b"Put_Line",p)
        self.assertEqual(strip_insertions(p,("T",),"ADA"),ADA_SAMPLE)

    def test_03_preserve_crlf_python(self):
        original=PY_SAMPLE.replace(b"\n",b"\r\n")
        p=insert_once(original,"    return y","T",["    print(y)"],"PY")
        self.assertEqual(detect_eol(p),b"\r\n")
        self.assertEqual(strip_insertions(p,("T",),"PY"),original)

    def test_04_preserve_crlf_ada(self):
        original=ADA_SAMPLE.replace(b"\n",b"\r\n")
        p=insert_once(original,"   null;","T",
                      ["   null;"],"ADA")
        self.assertEqual(strip_insertions(p,("T",),"ADA"),original)

    def test_05_missing_anchor_refused(self):
        with self.assertRaisesRegex(ValueError,"unique"):
            insert_once(PY_SAMPLE,"    return foo","T",["    pass"],"PY")

    def test_06_duplicate_anchor_refused(self):
        src=b"abc\nabc\n"
        with self.assertRaisesRegex(ValueError,"unique"):
            insert_once(src,"abc","T",["x"],"PY")

    def test_07_markers_tamper_close_refused(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        p=p.replace(b"V159_QA_DIAG_INSTRUMENTED_COPY_ONLY T\n",
                    b"V159_QA_DIAG_INSTRUMENTED_COPY_ONLY U\n",1)
        with self.assertRaises(ValueError):
            strip_insertions(p,("T",),"PY")

    def test_08_strip_missing_marker_refused(self):
        with self.assertRaisesRegex(ValueError,"missing"):
            strip_insertions(PY_SAMPLE,("T",),"PY")

    def test_09_strip_orphan_close_refused(self):
        p=PY_SAMPLE+b"# <<< V159_QA_DIAG_INSTRUMENTED_COPY_ONLY T\n"
        with self.assertRaisesRegex(ValueError,"orphan"):
            strip_insertions(p,("T",),"PY")

    def test_10_strip_duplicate_marker_refused(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        # duplicate complete instrumentation block, preserving original
        start=b"    # >>> V159_QA_DIAG_INSTRUMENTED_COPY_ONLY T\n"
        end=b"    # <<< V159_QA_DIAG_INSTRUMENTED_COPY_ONLY T\n"
        fragment=p[p.index(start):p.index(end)+len(end)]
        p=p.replace(b"    return y\n",fragment+b"    return y\n")
        with self.assertRaisesRegex(ValueError,"duplicate"):
            strip_insertions(p,("T",),"PY")

    def test_11_nested_marker_refused(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        p=p.replace(b"    pass\n",
                    b"    # >>> V159_QA_DIAG_INSTRUMENTED_COPY_ONLY Z\n"
                    b"    pass\n")
        with self.assertRaisesRegex(ValueError,"nested"):
            strip_insertions(p,("T","Z"),"PY")

    def test_12_extra_marker_refused(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        with self.assertRaisesRegex(ValueError,"unexpected"):
            strip_insertions(p,("X",),"PY")

    def test_13_unclosed_marker_refused(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        p=p.replace(b"    # <<< V159_QA_DIAG_INSTRUMENTED_COPY_ONLY T\n",b"")
        with self.assertRaisesRegex(ValueError,"unclosed"):
            strip_insertions(p,("T",),"PY")

    def test_14_repeated_original_eol_without_stray_cr(self):
        self.assertEqual(detect_eol(ADA_SAMPLE),b"\n")
        with self.assertRaisesRegex(ValueError,"EOL"):
            detect_eol(b"first\rsecond\n")

    def test_15_source_nul_refused(self):
        with self.assertRaisesRegex(ValueError,"EOL"):
            detect_eol(b"bad\x00\n")

    def test_16_source_no_terminal_newline_refused(self):
        with self.assertRaisesRegex(ValueError,"newline"):
            detect_eol(b"bad")

    def test_17_source_above_size_limit_refused(self):
        with self.assertRaisesRegex(ValueError,"EOL"):
            detect_eol(b"a"*150_001+b"\n")

    def test_18_python_marker_lines_are_comments(self):
        p=insert_once(PY_SAMPLE,"    return y","T",
                      ["    print('toy')"],"PY")
        ast.parse(p.decode())

    def test_19_python_diagnostic_has_separate_stderr(self):
        selector,final=python_blocks()
        joined="\n".join(selector+final)
        self.assertIn('sys").stderr.write',joined)
        self.assertNotIn("stdout",joined)

    def test_20_ada_diagnostic_has_separate_stderr(self):
        blocks=ada_blocks()
        joined="\n".join(x for part in blocks for x in part)
        self.assertIn("Ada.Text_IO.Standard_Error",joined)
        self.assertNotIn("Standard_Output",joined)

    def test_21_diagnostic_opt_in_exact_value(self):
        both="\n".join(sum(([x for x in block] for block in ada_blocks()),[]))
        self.assertIn('Value ("PC_FOUNDATION_DIAG_V159") = "1"',both)
        self.assertIn("PC_FOUNDATION_DIAG_V159", "\n".join(python_blocks()[0]))

    def test_22_original_day_specific_values_not_hardcoded(self):
        joined="\n".join(
            x for part in (*python_blocks(),*ada_blocks()) for x in part
        )
        self.assertNotIn("-15055671",joined)
        self.assertNotIn("[5000,10,503,30,52]",joined)

    def test_23_rank_observed_without_selecting_a_new_rank(self):
        selector="\n".join(python_blocks()[0])
        self.assertIn('"global_rank_decimal": str(rank)',selector)
        self.assertNotIn("choose_rank(",selector)

    def test_24_original_source_lock_no_fabrication(self):
        with self.assertRaises(ValueError):
            make_patched({"REF-41":b"fabricated source"})

    def test_25_proposal_manifest_no_unverified_evidence(self):
        with self.assertRaises(ValueError):
            plan({"REF-41":b"fabricated"},{}) 

    def test_26_diffs_show_only_qa_patch(self):
        p=insert_once(PY_SAMPLE,"    return y","T",["    pass"],"PY")
        delta=diff_bytes(PY_SAMPLE,p,"old","new")
        self.assertTrue(delta.startswith(b"--- old\n+++ new\n"))
        self.assertIn(b"V159_QA_DIAG_INSTRUMENTED_COPY_ONLY",delta)

    def test_27_ada_source_anchor_count_pinned(self):
        self.assertEqual(len(ADA_ANCHORS),3)
        self.assertEqual(len(set(ADA_ANCHORS)),3)

    def test_28_python_source_anchor_count_pinned(self):
        self.assertEqual(len(PY_ANCHORS),2)
        self.assertEqual(len(set(PY_ANCHORS)),2)
        self.assertEqual(PY_ANCHORS[0],"        rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())")

    def test_29_source_relative_paths_from_exact_commits(self):
        p=source_paths(Path("/tmp/example"))
        self.assertEqual(set(p),{"REF-41","ADA-TELUGU","ADA-WEAVING"})
        self.assertIn("0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",str(p["REF-41"]))
        self.assertIn("a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72",str(p["ADA-TELUGU"]))

    def test_30_generated_outputs_not_same_paths_as_sources(self):
        p=output_paths(Path("/tmp/output"))
        self.assertEqual(set(p),{"REF-41","ADA-TELUGU"})
        self.assertTrue(str(p["REF-41"]).endswith(".py"))
        self.assertTrue(str(p["ADA-TELUGU"]).endswith(".adb"))


    def test_31_post_assignment_insertion_is_exactly_after_target(self):
        original=(b"def f():\n    rank = 1\n    return rank\n")
        modified=insert_once(original,"    rank = 1","T",
                             ["    print(rank)"],"PY",after=True)
        self.assertLess(modified.index(b"rank = 1"),
                        modified.index(b"print(rank)"))
        self.assertLess(modified.index(b"print(rank)"),
                        modified.index(b"return rank"))
        self.assertEqual(strip_insertions(modified,("T",),"PY"),original)

if __name__=="__main__":
    unittest.main()
