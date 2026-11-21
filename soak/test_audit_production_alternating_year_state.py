"""Synthetic parser and mutation tests; not evidence of Kotlin Native success."""
from __future__ import annotations
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_alternating_year_state import (
    AuditError, PLANS, ERRORS, GATES, HALF, LIMIT, parse_transcript, save,
)


def fixture():
    rows = []
    for series in ("A", "B"):
        for step, (name, _, _, outcome) in enumerate(PLANS[series]):
            if outcome in ERRORS:
                rows.append(f"QUERY\t{series}\t{step}\t{name}\t{ERRORS[outcome]}\t123\t17")
            else:
                rows.append(f"QUERY\t{series}\t{step}\t{name}\tOK\t123\t5000\t0\t6\t100\t400\t17")
    for index in range(-HALF, HALF + 1):
        rows.append(f"GATE\t{index}\t{index * 50}")
    rows.append("TRACE_GATES\t561")
    return rows


class AlternatingProtocolTests(unittest.TestCase):
    def setUp(self):
        self.lines = fixture()
        self.raw = "\n".join(self.lines) + "\n"

    def mutate(self, row, col, value):
        copy = self.lines.copy()
        cols = copy[row].split("\t")
        cols[col] = str(value)
        copy[row] = "\t".join(cols)
        return "\n".join(copy) + "\n"

    def test_valid_shape(self):
        queries, gates = parse_transcript(self.raw)
        self.assertEqual((len(queries), len(gates)), (34, GATES))

    def test_missing_row(self):
        with self.assertRaisesRegex(AuditError, "ROW_COUNT"):
            parse_transcript("\n".join(self.lines[:-2]) + "\n")

    def test_extra_stdout(self):
        with self.assertRaisesRegex(AuditError, "ROW_COUNT"):
            parse_transcript(self.raw + "EXTRA\n")

    def test_crlf(self):
        with self.assertRaisesRegex(AuditError, "FORMAT"):
            parse_transcript(self.raw.replace("\n", "\r\n"))

    def test_no_terminal_newline(self):
        with self.assertRaisesRegex(AuditError, "FORMAT"):
            parse_transcript(self.raw.rstrip("\n"))

    def test_order_mutation(self):
        with self.assertRaisesRegex(AuditError, "QUERY_ORDER"):
            parse_transcript(self.mutate(0, 2, 2))

    def test_label_mutation(self):
        with self.assertRaisesRegex(AuditError, "QUERY_ORDER"):
            parse_transcript(self.mutate(2, 3, "FORGED"))

    def test_error_mutation(self):
        with self.assertRaisesRegex(AuditError, "REJECT_SHAPE"):
            parse_transcript(self.mutate(12, 4, "OK"))

    def test_accepted_shape_mutation(self):
        with self.assertRaisesRegex(AuditError, "ACCEPT_SHAPE"):
            parse_transcript(self.mutate(0, 4, "FAIL"))

    def test_negative_zero_target(self):
        with self.assertRaisesRegex(AuditError, "NONCANONICAL"):
            parse_transcript(self.mutate(0, 5, "-0"))

    def test_leading_zero_cache(self):
        with self.assertRaisesRegex(AuditError, "NONCANONICAL"):
            parse_transcript(self.mutate(0, 11, "017"))

    def test_cache_decrease(self):
        with self.assertRaisesRegex(AuditError, "CACHE_REGRESSION"):
            parse_transcript(self.mutate(5, 11, "1"))

    def test_cache_exceeds_limit(self):
        with self.assertRaisesRegex(AuditError, "CACHE_LIMIT"):
            parse_transcript(self.mutate(0, 11, str(LIMIT + 1)))

    def test_wrong_gate_index(self):
        with self.assertRaisesRegex(AuditError, "GATE_ORDER"):
            parse_transcript(self.mutate(34, 1, "-279"))

    def test_wrong_trace_footer(self):
        with self.assertRaisesRegex(AuditError, "GATE_COUNT"):
            parse_transcript(self.raw.replace("TRACE_GATES\t561", "TRACE_GATES\t560"))

    def test_report_readback(self):
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "alt.json"
            sha = save(path, {"status": "TEST"})
            self.assertEqual(len(sha), 64)
            self.assertIn(sha, path.with_suffix(".json.sha256").read_text())


if __name__ == "__main__":
    unittest.main()
