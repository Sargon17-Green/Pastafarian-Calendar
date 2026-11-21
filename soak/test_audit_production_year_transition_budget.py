"""Synthetic protocol/mutation tests; these are not Kotlin Native or acceptance evidence."""
from __future__ import annotations
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_year_transition_budget import (
    AuditError, CASES, GATES, GAPS, GAP_INDICES, GROUPS, HALF, LABELS,
    LIMIT, PASS, check_gap_sequence, parse_transcript, save, validate_success)


def fixture():
    lines = []
    for i, label in enumerate(LABELS):
        if i in (0, 1):
            lines.append(f"CASE\t{i}\t{label}\tE_POST55_YEAR_TRANSITION_BUDGET")
        elif i in (2, 5):
            err = ("E_POST55_YEAR_FORWARD_BUDGET" if i == 2
                   else "E_POST55_YEAR_BACKWARD_BUDGET")
            lines.append(f"CASE\t{i}\t{label}\t-999\t{err}")
        elif i in (10, 11):
            lines.append(f"CASE\t{i}\t{label}\tOK")
        else:
            lines.append(f"CASE\t{i}\t{label}\t-999\t5000\t-4\t4\t-100\t100")
    for group in GROUPS:
        for step, count in enumerate((1, 30, 31)):
            lines.append(f"CACHE\t{group}\t{step}\t{count}")
    for i in range(-HALF, HALF + 1):
        lines.append(f"GATE\t{i}\t{-15055671 + 50 * i}")
    lines.append("TRACE_GATES\t561")
    return lines


def modified(lines, line_no, col, content):
    copied = list(lines)
    parts = copied[line_no].split("\t")
    parts[col] = str(content)
    copied[line_no] = "\t".join(parts)
    return "\n".join(copied) + "\n"


def valid_report():
    return {
        "status": PASS, "source_sha": "a" * 40,
        "jar_sha256": "b" * 64, "transcript_sha256": "c" * 64,
        "oracle_sha256": "d" * 64, "gap_trace_sha256": "e" * 64,
        "production_exit_code": 0, "cases": CASES, "mismatches": 0,
        "independent_gap_questions": GAPS,
        "independent_gate_comparisons": GATES,
        "cache_profiles": 4, "gate_limit": LIMIT,
        "time_limit_seconds": 900, "tablets_certified": False,
        "full_date_certified": False,
        "global_independence_certified": False,
    }


class BoundedTransitionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lines = fixture()
        cls.raw = "\n".join(cls.lines) + "\n"

    def test_valid_strict_transcript(self):
        parsed = parse_transcript(self.raw)
        self.assertEqual((len(parsed["cases"]), len(parsed["gates"]),
                          len(parsed["cache"])), (12, 561, 4))

    def test_missing_row(self):
        with self.assertRaisesRegex(AuditError, "ROW_COUNT"):
            parse_transcript("\n".join(self.lines[:-2]) + "\n")

    def test_extra_stdout(self):
        with self.assertRaisesRegex(AuditError, "ROW_COUNT"):
            parse_transcript(self.raw + "debug\n")

    def test_reordered_case_id(self):
        with self.assertRaisesRegex(AuditError, "CASE_ORDER"):
            parse_transcript(modified(self.lines, 3, 1, 2))

    def test_wrong_case_label(self):
        with self.assertRaisesRegex(AuditError, "CASE_ORDER"):
            parse_transcript(modified(self.lines, 2, 2, "WRONG"))

    def test_bad_case_shape(self):
        with self.assertRaisesRegex(AuditError, "CASE_SHAPE"):
            rows = self.lines.copy()
            rows[3] = "\t".join(rows[3].split("\t")[:-1])
            parse_transcript("\n".join(rows) + "\n")

    def test_negative_zero(self):
        with self.assertRaisesRegex(AuditError, "NONCANONICAL"):
            parse_transcript(modified(self.lines, 2, 3, "-0"))

    def test_leading_zero(self):
        with self.assertRaisesRegex(AuditError, "NONCANONICAL"):
            parse_transcript(modified(self.lines, 2, 3, "001"))

    def test_cache_order(self):
        with self.assertRaisesRegex(AuditError, "CACHE_ORDER"):
            parse_transcript(modified(self.lines, CASES, 2, 1))

    def test_cache_decreasing(self):
        with self.assertRaisesRegex(AuditError, "NONMONOTONE"):
            parse_transcript(modified(self.lines, CASES + 2, 3, 29))

    def test_cache_over_budget(self):
        with self.assertRaisesRegex(AuditError, "CACHE_BUDGET"):
            parse_transcript(modified(self.lines, CASES, 3, LIMIT + 1))

    def test_gate_index_mismatch(self):
        with self.assertRaisesRegex(AuditError, "GATE_ORDER"):
            parse_transcript(modified(self.lines, CASES + 12, 1, "-279"))

    def test_wrong_gate_count(self):
        with self.assertRaisesRegex(AuditError, "TRACE_COUNT"):
            parse_transcript(self.raw.replace("TRACE_GATES\t561", "TRACE_GATES\t560"))

    def test_crlf(self):
        with self.assertRaisesRegex(AuditError, "FORMAT"):
            parse_transcript(self.raw.replace("\n", "\r\n"))

    def test_missing_trailing_newline(self):
        with self.assertRaisesRegex(AuditError, "FORMAT"):
            parse_transcript(self.raw.rstrip("\n"))

    def test_missing_gap_question(self):
        with self.assertRaisesRegex(AuditError, "GAP_SEQUENCE"):
            check_gap_sequence(GAP_INDICES[:-1], GAPS - 1)

    def test_duplicate_gap_question(self):
        with self.assertRaisesRegex(AuditError, "GAP_SEQUENCE"):
            check_gap_sequence(GAP_INDICES[:-1] + (GAP_INDICES[0],), GAPS)

    def test_report_provenance(self):
        validate_success(valid_report())
        wrong = valid_report()
        wrong["source_sha"] = "wrong"
        with self.assertRaisesRegex(AuditError, "PROVENANCE"):
            validate_success(wrong)

    def test_report_limits(self):
        wrong = valid_report()
        wrong["cases"] = 11
        with self.assertRaisesRegex(AuditError, "REPORT_COUNTS"):
            validate_success(wrong)

    def test_readback_sha256(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "budget.json"
            result = save(path, valid_report())
            self.assertEqual(result, hashlib.sha256(path.read_bytes()).hexdigest())
            self.assertIn(result, path.with_suffix(".json.sha256").read_text())


if __name__ == "__main__":
    unittest.main()
