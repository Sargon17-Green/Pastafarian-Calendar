"""Mutation and fail-closed tests for adjacent production year navigation."""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_adjacent_year_navigation import (
    AuditError, FOUNDATION, GATE_COUNT, ORACLE_HALF_WIDTH, compare,
    parse_transcript, EXPECTED_ROWS,
)

@dataclass(frozen=True)
class FakeYear:
    number: int
    open_index: int
    close_index: int
    open_day: int
    close_day: int

BASE = FakeYear(5000, -3, 4, FOUNDATION - 300, FOUNDATION + 400)
NEXT = FakeYear(5001, 4, 11, FOUNDATION + 400, FOUNDATION + 1100)
PREVIOUS = FakeYear(4999, -10, -3, FOUNDATION - 1000, FOUNDATION - 300)

class FakeLedger:
    def day(self, index):
        if type(index) is not int or not -ORACLE_HALF_WIDTH <= index <= ORACLE_HALF_WIDTH:
            raise AuditError("E_FAKE_LEDGER_RANGE")
        return FOUNDATION + index * 100

class FakeGeometry:
    def year5000(self, calculation_day, selector):
        assert calculation_day == FOUNDATION
        return BASE

    def next(self, year, selector):
        assert year == BASE
        return NEXT

    def previous(self, year, selector):
        assert year == BASE
        return PREVIOUS

    def find(self, calculation_day, target, selector):
        assert calculation_day == FOUNDATION
        if target == BASE.close_day + 1:
            return NEXT, 1
        if target == BASE.open_day:
            return PREVIOUS, 1
        if BASE.open_day < target <= BASE.close_day:
            return BASE, 0
        raise AuditError("E_FAKE_TARGET_OUTSIDE")


def fields(year):
    return (year.number, year.open_index, year.close_index,
            year.open_day, year.close_day)


def valid_transcript():
    ledger = FakeLedger()
    lines = [
        f"GATE\t{index}\t{ledger.day(index)}"
        for index in range(-ORACLE_HALF_WIDTH, ORACLE_HALF_WIDTH + 1)
    ]
    lines.extend((
        "YEAR\t" + "\t".join(map(str, fields(BASE))),
        "NEXT\t" + "\t".join(map(str, fields(NEXT))),
        "PREVIOUS\t" + "\t".join(map(str, fields(PREVIOUS))),
        "FIND_FORWARD\t" + str(BASE.close_day + 1) + "\t" +
            "\t".join(map(str, fields(NEXT))),
        "FIND_BACKWARD\t" + str(BASE.open_day) + "\t" +
            "\t".join(map(str, fields(PREVIOUS))),
        "PRODUCTION_GATE_LIMIT\t8192",
        f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT}",
    ))
    assert len(lines) == EXPECTED_ROWS
    return "\n".join(lines) + "\n"


class AdjacentYearContractTests(unittest.TestCase):
    def setUp(self):
        self.text = valid_transcript()
        self.ledger = FakeLedger()
        self.geometry = FakeGeometry()

    def test_valid_synthetic_transcript_and_exact_comparison_count(self):
        parsed = parse_transcript(self.text)
        result = compare(parsed, self.ledger, self.geometry, lambda *_: 1)
        comparisons = sum(result[key] for key in (
            "production_gate_day_comparisons", "year5000_comparisons",
            "adjacent_year_comparisons", "find_target_transition_comparisons",
            "production_gate_limit_checks",
            "production_expanded_gate_count_checks",
        ))
        self.assertEqual(comparisons, EXPECTED_ROWS)
        self.assertEqual(result["forward_transitions"], 1)
        self.assertEqual(result["backward_transitions"], 1)

    def test_gate_mutation_is_detected(self):
        changed = self.text.replace(
            f"GATE\t1\t{FOUNDATION + 100}",
            f"GATE\t1\t{FOUNDATION + 101}",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_REAL_GATE_MISMATCH_1"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_year5000_mutation_is_detected(self):
        changed = self.text.replace("YEAR\t5000", "YEAR\t5001", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_YEAR5000_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_next_year_mutation_is_detected(self):
        changed = self.text.replace("NEXT\t5001", "NEXT\t5002", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_NEXT_YEAR_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_previous_year_mutation_is_detected(self):
        changed = self.text.replace("PREVIOUS\t4999", "PREVIOUS\t4998", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_PREVIOUS_YEAR_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_forward_find_result_mutation_is_detected(self):
        changed = self.text.replace(
            f"FIND_FORWARD\t{BASE.close_day + 1}\t5001",
            f"FIND_FORWARD\t{BASE.close_day + 1}\t5002",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_REAL_FIND_FORWARD_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_backward_find_result_mutation_is_detected(self):
        changed = self.text.replace(
            f"FIND_BACKWARD\t{BASE.open_day}\t4999",
            f"FIND_BACKWARD\t{BASE.open_day}\t4998",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_REAL_FIND_BACKWARD_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_forward_find_target_spoof_is_rejected(self):
        changed = self.text.replace(
            f"FIND_FORWARD\t{BASE.close_day + 1}\t",
            f"FIND_FORWARD\t{BASE.close_day + 2}\t",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_FIND_FORWARD_TARGET"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_backward_find_target_spoof_is_rejected(self):
        changed = self.text.replace(
            f"FIND_BACKWARD\t{BASE.open_day}\t",
            f"FIND_BACKWARD\t{BASE.open_day - 1}\t",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_FIND_BACKWARD_TARGET"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_duplicate_gate_is_rejected(self):
        changed = self.text.replace(
            f"GATE\t1\t{FOUNDATION + 100}",
            f"GATE\t0\t{FOUNDATION}",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_DUPLICATE_GATE"):
            parse_transcript(changed)

    def test_missing_gate_row_is_rejected(self):
        changed = self.text.replace(f"GATE\t1\t{FOUNDATION + 100}\n", "", 1)
        with self.assertRaisesRegex(AuditError, "E_TRANSCRIPT_ROW_COUNT"):
            parse_transcript(changed)

    def test_noncanonical_integer_is_rejected(self):
        changed = self.text.replace(
            f"GATE\t1\t{FOUNDATION + 100}",
            f"GATE\t01\t{FOUNDATION + 100}",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(changed)

    def test_wrong_production_gate_limit_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_PRODUCTION_LIMIT_DRIFT"):
            parse_transcript(self.text.replace(
                "PRODUCTION_GATE_LIMIT\t8192",
                "PRODUCTION_GATE_LIMIT\t8193",
                1,
            ))

    def test_wrong_expanded_gate_count_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_PRODUCTION_EXPANDED_GATE_COUNT"):
            parse_transcript(self.text.replace(
                f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT}",
                f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT + 1}",
                1,
            ))

    def test_missing_newline_and_crlf_are_rejected(self):
        for malformed in (
            self.text.rstrip("\n"),
            self.text.replace("\n", "\r\n"),
        ):
            with self.subTest(malformed=malformed[-30:]), self.assertRaisesRegex(
                AuditError, "E_TRANSCRIPT_FORMAT"
            ):
                parse_transcript(malformed)

    def test_unknown_row_is_rejected(self):
        changed = self.text.replace(
            "PRODUCTION_EXPANDED_GATES",
            "UNEXPECTED_ROW",
            1,
        )
        with self.assertRaisesRegex(AuditError, "E_UNKNOWN_TRANSCRIPT_ROW"):
            parse_transcript(changed)


if __name__ == "__main__":
    unittest.main()
