"""Mutation tests for three fresh production navigator query orders."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_order_invariance import (
    AuditError, FOUNDATION, GATE_COUNT, HALF_WIDTH, ORDERS,
    EXPECTED_LINES, compare, parse_transcript, PASS,
)
from audit_production_adjacent_year_navigation import independent_interior_targets
from test_audit_production_adjacent_year_navigation import (
    BASE, NEXT, NEXT2, PREVIOUS, PREVIOUS2, FakeLedger, FakeGeometry,
    fields,
)

YEARS = (PREVIOUS2, PREVIOUS, BASE, NEXT, NEXT2)


def synthetic_transcript():
    cases = []
    for year in YEARS:
        for ordinal, target in enumerate(independent_interior_targets(year), 1):
            cases.append((year.number, ordinal, target, fields(year)))
    lines = []
    for name, indices in ORDERS.items():
        for index in indices:
            year, ordinal, target, result = cases[index]
            lines.append("\t".join(map(str, (
                "ORDER", name, index, year, ordinal, target, *result,
            ))))
        lines.append(f"ORDER_GATES\t{name}\t{GATE_COUNT}")
    ledger = FakeLedger()
    for index in range(-HALF_WIDTH, HALF_WIDTH + 1):
        lines.append(f"GATE\t{index}\t{ledger.day(index)}")
    lines.append(f"SEED_GATES\t{GATE_COUNT}")
    assert len(lines) == EXPECTED_LINES
    return "\n".join(lines) + "\n"


def mutate_case(text, name, index, offset, replacement):
    lines = text.splitlines()
    for i, line in enumerate(lines):
        fields_ = line.split("\t")
        if (len(fields_) == 11 and fields_[:3] ==
                ["ORDER", name, str(index)]):
            fields_[offset] = str(replacement)
            lines[i] = "\t".join(fields_)
            return "\n".join(lines) + "\n"
    raise AssertionError("missing synthetic row")


class OrderInvariantTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = synthetic_transcript()
        cls.ledger = FakeLedger()
        cls.geometry = FakeGeometry()

    def compare(self, raw):
        return compare(parse_transcript(raw), self.ledger,
                       self.geometry, lambda *_: 1)

    def test_three_orders_cover_fifteen_unique_samples(self):
        self.assertEqual(len(ORDERS), 3)
        self.assertEqual({len(set(v)) for v in ORDERS.values()}, {15})
        self.assertEqual(len(set(tuple(v) for v in ORDERS.values())), 3)

    def test_clean_synthetic_full_oracle_comparison(self):
        report = self.compare(self.raw)
        self.assertEqual(report["real_production_ordered_queries"], 45)
        self.assertEqual(report["unique_strict_interior_targets"], 15)
        self.assertEqual(report["verified_fresh_navigator_instances"], 3)
        self.assertEqual(report["production_gate_trace_compared"], 561)

    def test_cached_result_pollution_in_reversed_order_is_detected(self):
        broken = mutate_case(self.raw, "REVERSED", 7, 6, 4999)
        with self.assertRaisesRegex(AuditError, "E_ORDER_REAL_MISMATCH_REVERSED_7"):
            self.compare(broken)

    def test_cached_result_pollution_in_permuted_order_is_detected(self):
        broken = mutate_case(self.raw, "PERMUTED", 14, 6, 5003)
        with self.assertRaisesRegex(AuditError, "E_ORDER_REAL_MISMATCH_PERMUTED_14"):
            self.compare(broken)

    def test_independent_target_spoof_is_detected(self):
        broken = mutate_case(self.raw, "NATURAL", 6, 5,
                             independent_interior_targets(BASE)[0] + 1)
        with self.assertRaisesRegex(AuditError, "E_ORDER_REAL_MISMATCH_NATURAL_6"):
            self.compare(broken)

    def test_source_year_spoof_is_detected(self):
        broken = mutate_case(self.raw, "NATURAL", 6, 3, 6000)
        with self.assertRaisesRegex(AuditError, "E_ORDER_REAL_MISMATCH_NATURAL_6"):
            self.compare(broken)

    def test_order_permutation_is_strict(self):
        lines = self.raw.splitlines()
        lines[0], lines[1] = lines[1], lines[0]
        with self.assertRaisesRegex(AuditError, "E_ORDER_PERMUTATION"):
            parse_transcript("\n".join(lines) + "\n")

    def test_duplicate_index_is_rejected(self):
        lines = self.raw.splitlines()
        second = lines[1].split("\t")
        second[2] = "0"
        lines[1] = "\t".join(second)
        with self.assertRaisesRegex(AuditError, "E_ORDER_PERMUTATION"):
            parse_transcript("\n".join(lines) + "\n")

    def test_wrong_order_name_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_ROW_SHAPE"):
            parse_transcript(self.raw.replace("ORDER\tREVERSED\t",
                                               "ORDER\tUNDECLARED\t", 1))

    def test_unexpected_extra_row_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_ROW_COUNT"):
            parse_transcript("EXTRA\n" + self.raw)

    def test_missing_row_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_ROW_COUNT"):
            parse_transcript("\n".join(self.raw.splitlines()[:-1]) + "\n")

    def test_crlf_and_missing_trailing_newline_fail_closed(self):
        for damaged in (self.raw.replace("\n", "\r\n"),
                        self.raw.rstrip("\n")):
            with self.subTest(damaged=damaged[-20:]):
                with self.assertRaisesRegex(AuditError, "E_ORDER_TRANSCRIPT_FORMAT"):
                    parse_transcript(damaged)

    def test_noncanonical_numeric_field_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(self.raw.replace("ORDER\tNATURAL\t0\t",
                                               "ORDER\tNATURAL\t00\t", 1))

    def test_noncanonical_negative_gate_index_is_rejected(self):
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(self.raw.replace("GATE\t-1\t",
                                               "GATE\t-01\t", 1))

    def test_worker_gate_budget_is_enforced(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_GATE_BUDGET"):
            parse_transcript(self.raw.replace(
                f"ORDER_GATES\tNATURAL\t{GATE_COUNT}",
                "ORDER_GATES\tNATURAL\t8193", 1))

    def test_seed_gate_count_is_enforced(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_SEED_BUDGET"):
            parse_transcript(self.raw.replace(
                f"SEED_GATES\t{GATE_COUNT}", "SEED_GATES\t560", 1))

    def test_gate_trace_index_mutation_is_detected(self):
        with self.assertRaisesRegex(AuditError, "E_ORDER_GATE_INDEX"):
            parse_transcript(self.raw.replace(
                f"GATE\t1\t{FOUNDATION + 100}",
                f"GATE\t2\t{FOUNDATION + 100}", 1))

    def test_gate_trace_day_mutation_is_detected(self):
        damaged = self.raw.replace(
            f"GATE\t1\t{FOUNDATION + 100}",
            f"GATE\t1\t{FOUNDATION + 101}", 1)
        with self.assertRaisesRegex(AuditError, "E_ORDER_INDEPENDENT_GATE_MISMATCH"):
            self.compare(damaged)

    def test_malformed_result_tuple_fails_closed(self):
        lines = self.raw.splitlines()
        lines[0] += "\textra"
        with self.assertRaisesRegex(AuditError, "E_ORDER_ROW_SHAPE"):
            parse_transcript("\n".join(lines) + "\n")

    def test_reverse_only_invalidation_does_not_pass(self):
        result = mutate_case(self.raw, "REVERSED", 0, 10,
                             PREVIOUS2.close_day + 99)
        with self.assertRaisesRegex(AuditError, "E_ORDER_REAL_MISMATCH_REVERSED_0"):
            self.compare(result)


if __name__ == "__main__":
    unittest.main()
