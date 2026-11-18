"""Mutation tests for the transcript comparator; synthetic, not a real date proof."""
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_year_gate_unseeded import (
    AuditError, FOUNDATION, MAX_PRODUCTION_GATE_INDEX,
    parse_transcript, compare, EXPECTED_CHECKS,
)

@dataclass(frozen=True)
class FakeYear:
    number: int = 5000
    open_index: int = -3
    close_index: int = 4
    open_day: int = FOUNDATION - 300
    close_day: int = FOUNDATION + 400

class FakeLedger:
    def day(self, index):
        return FOUNDATION + 100 * index
    def gate_index(self, day):
        delta = day - FOUNDATION
        return delta // 100 if delta % 100 == 0 else None

class FakeGeometry:
    def year5000(self, origin, selector):
        assert origin == FOUNDATION
        return FakeYear()
    def find(self, origin, target, selector):
        assert origin == FOUNDATION
        assert FakeYear().open_day < target <= FakeYear().close_day
        return FakeYear(), 0

def valid_text():
    ledger = FakeLedger()
    year = FakeYear()
    fields = f"{year.number}\t{year.open_index}\t{year.close_index}\t{year.open_day}\t{year.close_day}"
    lines = [f"GATE\t{i}\t{ledger.day(i)}" for i in range(-2, 3)]
    lines.append(f"YEAR\t{fields}")
    for target in (year.open_day + 1, FOUNDATION, year.close_day):
        lines.append(f"FIND\t{target}\t{fields}")
    for day in (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1,
                year.open_day, year.close_day):
        idx = ledger.gate_index(day)
        lines.append(f"EXACT\t{day}\t{idx if idx is not None else 'NONE'}")
    lines.append(f"PRODUCTION_GATE_LIMIT\t{MAX_PRODUCTION_GATE_INDEX}")
    assert len(lines) == EXPECTED_CHECKS
    return "\n".join(lines) + "\n"

class ProductionYearGateContractTests(unittest.TestCase):
    def test_valid_synthetic_transcript(self):
        parsed = parse_transcript(valid_text())
        result = compare(parsed, FakeLedger(), FakeGeometry(), lambda *_: 1)
        self.assertEqual(sum(result[k] for k in (
            "gate_day_comparisons", "year5000_comparisons",
            "find_target_comparisons", "exact_gate_index_comparisons",
            "production_gate_limit_check")), 15)
        self.assertTrue(result["tablets_beyond_production_gate_budget"])

    def test_gate_mutation_is_detected(self):
        text = valid_text().replace(f"GATE\t1\t{FOUNDATION + 100}",
                                    f"GATE\t1\t{FOUNDATION + 101}")
        with self.assertRaisesRegex(AuditError, "E_REAL_GATE_MISMATCH_1"):
            compare(parse_transcript(text), FakeLedger(), FakeGeometry(), lambda *_: 1)

    def test_year_mutation_is_detected(self):
        with self.assertRaisesRegex(AuditError, "E_REAL_YEAR5000_MISMATCH"):
            compare(parse_transcript(valid_text().replace("YEAR\t5000", "YEAR\t5001")),
                    FakeLedger(), FakeGeometry(), lambda *_: 1)

    def test_find_mutation_is_detected(self):
        text = valid_text().replace(f"FIND\t{FOUNDATION}\t5000", f"FIND\t{FOUNDATION}\t5001")
        with self.assertRaisesRegex(AuditError, "E_REAL_FIND_MISMATCH"):
            compare(parse_transcript(text), FakeLedger(), FakeGeometry(), lambda *_: 1)

    def test_exact_gate_mutation_is_detected(self):
        text = valid_text().replace(f"EXACT\t{FOUNDATION}\t0", f"EXACT\t{FOUNDATION}\t1")
        with self.assertRaisesRegex(AuditError, "E_REAL_EXACT_GATE_MISMATCH"):
            compare(parse_transcript(text), FakeLedger(), FakeGeometry(), lambda *_: 1)

    def test_rejects_duplicate_gate(self):
        text = valid_text().replace(f"GATE\t1\t{FOUNDATION + 100}", f"GATE\t0\t{FOUNDATION}")
        with self.assertRaisesRegex(AuditError, "E_DUPLICATE_OR_INVALID_GATE"):
            parse_transcript(text)

    def test_rejects_wrong_production_limit(self):
        with self.assertRaisesRegex(AuditError, "E_PRODUCTION_LIMIT_DRIFT"):
            parse_transcript(valid_text().replace("PRODUCTION_GATE_LIMIT\t8192",
                                                  "PRODUCTION_GATE_LIMIT\t8193"))

    def test_rejects_row_count_and_unexpected_lines(self):
        with self.assertRaisesRegex(AuditError, "E_TRANSCRIPT_ROW_COUNT"):
            parse_transcript(valid_text() + "GATE\t3\t1\n")
        with self.assertRaisesRegex(AuditError, "E_UNKNOWN_TRANSCRIPT_ROW"):
            parse_transcript(valid_text().replace("PRODUCTION_GATE_LIMIT", "CERTIFIED"))

    def test_rejects_noncanonical_and_bool_like(self):
        for bad in ("+1", "01", "-0", "False", "1.0"):
            with self.subTest(bad=bad), self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
                parse_transcript(valid_text().replace("GATE\t1\t", "GATE\t" + bad + "\t"))

    def test_rejects_missing_newline_and_windows_crlf(self):
        for text in (valid_text().rstrip("\n"), valid_text().replace("\n", "\r\n")):
            with self.assertRaisesRegex(AuditError, "E_TRANSCRIPT_FORMAT"):
                parse_transcript(text)

    def test_rejects_spoofed_find_target(self):
        y = FakeYear()
        text = valid_text().replace(f"FIND\t{y.open_day + 1}", f"FIND\t{y.open_day + 2}")
        with self.assertRaisesRegex(AuditError, "E_FIND_TARGET_SET"):
            compare(parse_transcript(text), FakeLedger(), FakeGeometry(), lambda *_: 1)

    def test_rejects_spoofed_exact_day(self):
        text = valid_text().replace(f"EXACT\t{FOUNDATION - 1}", f"EXACT\t{FOUNDATION - 2}")
        with self.assertRaisesRegex(AuditError, "E_EXACT_TARGET_SET"):
            compare(parse_transcript(text), FakeLedger(), FakeGeometry(), lambda *_: 1)

if __name__ == "__main__":
    unittest.main()
