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
NEXT2 = FakeYear(5002, 11, 18, FOUNDATION + 1100, FOUNDATION + 1800)
PREVIOUS2 = FakeYear(4998, -17, -10, FOUNDATION - 1700, FOUNDATION - 1000)

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
        if year == BASE:
            return NEXT
        if year == NEXT:
            return NEXT2
        raise AuditError("E_FAKE_NEXT_SOURCE")

    def previous(self, year, selector):
        if year == BASE:
            return PREVIOUS
        if year == PREVIOUS:
            return PREVIOUS2
        raise AuditError("E_FAKE_PREVIOUS_SOURCE")

    def find(self, calculation_day, target, selector):
        assert calculation_day == FOUNDATION
        if target == BASE.close_day + 1:
            return NEXT, 1
        if target == BASE.open_day:
            return PREVIOUS, 1
        if target == NEXT.close_day + 1:
            return NEXT2, 2
        if target == PREVIOUS.open_day:
            return PREVIOUS2, 2
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
        "NEXT2\t" + "\t".join(map(str, fields(NEXT2))),
        "PREVIOUS2\t" + "\t".join(map(str, fields(PREVIOUS2))),
        "FIND_FORWARD\t" + str(BASE.close_day + 1) + "\t" +
            "\t".join(map(str, fields(NEXT))),
        "FIND_BACKWARD\t" + str(BASE.open_day) + "\t" +
            "\t".join(map(str, fields(PREVIOUS))),
        "FIND_FORWARD2\t" + str(NEXT.close_day + 1) + "\t" +
            "\t".join(map(str, fields(NEXT2))),
        "FIND_BACKWARD2\t" + str(PREVIOUS.open_day) + "\t" +
            "\t".join(map(str, fields(PREVIOUS2))),
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
            "adjacent_year_comparisons", "two_hop_year_comparisons",
            "find_target_transition_comparisons", "find_two_hop_transition_comparisons",
            "production_gate_limit_checks",
            "production_expanded_gate_count_checks",
        ))
        self.assertEqual(comparisons, EXPECTED_ROWS)
        self.assertEqual(result["forward_transitions"], 1)
        self.assertEqual(result["backward_transitions"], 1)
        self.assertEqual(result["forward_two_hop_transitions"], 2)
        self.assertEqual(result["backward_two_hop_transitions"], 2)

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


    def test_next2_year_mutation_is_detected(self):
        changed = self.text.replace("NEXT2\t5002", "NEXT2\t5003", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_NEXT2_YEAR_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_previous2_year_mutation_is_detected(self):
        changed = self.text.replace("PREVIOUS2\t4998", "PREVIOUS2\t4997", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_PREVIOUS2_YEAR_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_forward2_find_result_mutation_is_detected(self):
        needle = f"FIND_FORWARD2\t{NEXT.close_day + 1}\t5002"
        changed = self.text.replace(needle, needle[:-1] + "3", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_FIND_FORWARD2_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_backward2_find_result_mutation_is_detected(self):
        needle = f"FIND_BACKWARD2\t{PREVIOUS.open_day}\t4998"
        changed = self.text.replace(needle, needle[:-1] + "7", 1)
        with self.assertRaisesRegex(AuditError, "E_REAL_FIND_BACKWARD2_MISMATCH"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_forward2_find_target_spoof_is_rejected(self):
        changed = self.text.replace(
            f"FIND_FORWARD2\t{NEXT.close_day + 1}\t",
            f"FIND_FORWARD2\t{NEXT.close_day + 2}\t", 1,
        )
        with self.assertRaisesRegex(AuditError, "E_FIND_FORWARD2_TARGET"):
            compare(parse_transcript(changed), self.ledger, self.geometry, lambda *_: 1)

    def test_backward2_find_target_spoof_is_rejected(self):
        changed = self.text.replace(
            f"FIND_BACKWARD2\t{PREVIOUS.open_day}\t",
            f"FIND_BACKWARD2\t{PREVIOUS.open_day - 1}\t", 1,
        )
        with self.assertRaisesRegex(AuditError, "E_FIND_BACKWARD2_TARGET"):
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
