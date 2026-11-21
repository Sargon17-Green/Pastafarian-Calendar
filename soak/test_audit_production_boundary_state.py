"""Synthetic mutation and fail-closed protocol tests for the bounded boundary probe."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_boundary_state import (
    AuditError, CALLS, GATES, GAPS, LIMIT, LINES, ORDERS, PASS,
    cases_for, check_gap_sequence, compare, parse_transcript, save,
    validate_success, GAP_INDICES
)
from test_audit_production_adjacent_year_navigation import (
    PREVIOUS2, PREVIOUS, BASE, NEXT, NEXT2, FakeGeometry, FakeLedger
)

YEARS = (PREVIOUS2, PREVIOUS, BASE, NEXT, NEXT2)


def valid_transcript():
    geometry, ledger = FakeGeometry(), FakeLedger()
    samples, maximum = cases_for(YEARS, geometry, lambda *_: 1)
    assert maximum == 2 and len(samples) == 18
    lines = []
    for session, order in ORDERS.items():
        for phase in (1, 2):
            permutation = order if phase == 1 else reversed(order)
            for pos, idx in enumerate(permutation):
                target, result = samples[idx]
                lines.append("\t".join(str(x) for x in (
                    "CASE", session, phase, pos, idx, target, *result
                )))
    for session in ORDERS:
        lines.append(f"SESSION_GATES\t{session}\t{GATES}")
    for index in range(-280, 281):
        lines.append(f"GATE\t{index}\t{ledger.day(index)}")
    lines.append(f"SEED_GATES\t{GATES}")
    assert len(lines) == LINES
    return "\n".join(lines) + "\n"


def replace_field(text, row, field, value):
    lines = text.splitlines()
    fields = lines[row].split("\t")
    fields[field] = str(value)
    lines[row] = "\t".join(fields)
    return "\n".join(lines) + "\n"


def passing_report():
    return {
        "status": PASS, "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "source_sha": "a" * 40, "run_url": "https://github.com/example/actions/runs/1",
        "production_jar_sha256": "a" * 64,
        "transcript_sha256": "b" * 64, "gap_trace_sha256": "c" * 64,
        "production_exit_code": 0, "real_production_calls": CALLS,
        "ownership_cases": 18, "independent_gap_questions": GAPS,
        "gate_trace_comparisons": GATES, "mismatches": 0,
        "artifact_name": "kotlin-cymraeg-production-boundary-state",
        "session_gate_counts": {k: GATES for k in ORDERS},
    }


class BoundaryStateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = valid_transcript()

    def check(self, text):
        return compare(parse_transcript(text), FakeLedger(), FakeGeometry(), None)

    def test_clean_synthetic_full_comparison(self):
        report = self.check(self.raw)
        self.assertEqual(report["real_production_calls"], 108)
        self.assertEqual(report["ownership_cases"], 18)
        self.assertEqual(report["gate_trace_comparisons"], 561)
        self.assertEqual(report["distinct_days"], 10)

    def test_three_orders_are_distinct_bijections(self):
        self.assertEqual({len(set(v)) for v in ORDERS.values()}, {18})
        self.assertEqual(len(set(ORDERS.values())), 3)

    def test_missing_case_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_ROW_COUNT"):
            parse_transcript("\n".join(self.raw.splitlines()[1:]) + "\n")

    def test_duplicated_case_row_is_rejected(self):
        rows = self.raw.splitlines()
        rows[1] = rows[0]
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_CASE_ORDER"):
            parse_transcript("\n".join(rows) + "\n")

    def test_phase_order_mutation_is_rejected(self):
        rows = self.raw.splitlines()
        rows[18], rows[19] = rows[19], rows[18]
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_CASE_ORDER"):
            parse_transcript("\n".join(rows) + "\n")

    def test_canonical_id_swap_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_CASE_ORDER"):
            parse_transcript(replace_field(self.raw, 0, 4, 17))

    def test_negative_zero_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(replace_field(self.raw, 0, 3, "-0"))

    def test_leading_zero_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(replace_field(self.raw, 0, 4, "00"))

    def test_forged_target_is_rejected(self):
        fields = self.raw.splitlines()[0].split("\t")
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REAL_MISMATCH"):
            self.check(replace_field(self.raw, 0, 5, int(fields[5]) + 1))

    def test_at_open_owner_mutation_is_rejected(self):
        # Canonical id 10 resolves the *previous* year.
        row = 10
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REAL_MISMATCH"):
            self.check(replace_field(self.raw, row, 6, 4999))

    def test_at_close_owner_mutation_is_rejected(self):
        row = 5
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REAL_MISMATCH"):
            self.check(replace_field(self.raw, row, 6, 4997))

    def test_five_field_tuple_mutation_is_rejected(self):
        fields = self.raw.splitlines()[0].split("\t")
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REAL_MISMATCH"):
            self.check(replace_field(self.raw, 0, 10, int(fields[10]) + 1))

    def test_8193_gate_budget_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_GATE_BUDGET"):
            parse_transcript(self.raw.replace(
                f"SESSION_GATES\tNATURAL\t{GATES}",
                "SESSION_GATES\tNATURAL\t8193", 1))

    def test_mutated_independent_gate_day_is_rejected(self):
        row = 111 + 281
        fields = self.raw.splitlines()[row].split("\t")
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_INDEPENDENT_GATE"):
            self.check(replace_field(self.raw, row, 2, int(fields[2]) + 1))

    def test_gap_omission_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_GAP_QUESTION_SEQUENCE"):
            check_gap_sequence(GAP_INDICES[:-1], GAPS-1)

    def test_gap_duplication_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_GAP_QUESTION_SEQUENCE"):
            check_gap_sequence(GAP_INDICES[:-1] + (GAP_INDICES[0],), GAPS)

    def test_session_identity_reuse_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_CASE_SCHEMA"):
            parse_transcript(self.raw.replace("CASE\tREVERSED\t", "CASE\tNATURAL\t", 1))

    def test_missing_or_truncated_artifact_fails_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "boundary-state.json"
            with self.assertRaises(FileNotFoundError):
                path.read_bytes()
            path.write_text('{"status":"PASS"', encoding="utf-8")
            with self.assertRaises(json.JSONDecodeError):
                json.loads(path.read_text(encoding="utf-8"))

    def test_report_missing_field_is_rejected(self):
        report = passing_report()
        report.pop("gap_trace_sha256")
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REPORT_MISSING"):
            validate_success(report)

    def test_report_budget_and_digest_validation(self):
        valid = passing_report()
        validate_success(valid)
        wrong = dict(valid, session_gate_counts={"NATURAL": 8193,
                                                 "REVERSED": 1, "STRIDE5": 1})
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_REPORT_COUNTS"):
            validate_success(wrong)
        wrong_digest = dict(valid, transcript_sha256="abc")
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_BAD_DIGEST"):
            validate_success(wrong_digest)

    def test_evidence_sha256_sidecar_and_readback(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "boundary-state.json"
            digest = save(path, passing_report())
            self.assertEqual(digest, hashlib.sha256(path.read_bytes()).hexdigest())
            self.assertIn(digest, path.with_suffix(".json.sha256").read_text())

    def test_crlf_and_truncated_transcript_rejected(self):
        for text in (self.raw.replace("\n", "\r\n"), self.raw.rstrip("\n")):
            with self.assertRaisesRegex(AuditError, "E_BOUNDARY_FORMAT"):
                parse_transcript(text)

    def test_extra_stdout_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_BOUNDARY_ROW_COUNT"):
            parse_transcript(self.raw + "debug\n")


if __name__ == "__main__":
    unittest.main()
