#!/usr/bin/env python3
"""Synthetic fail-closed tests only; real JVM oracle is a separate CI step."""
from __future__ import annotations
import unittest
from independent_year_geometry_oracle import Year

from audit_production_seven_field_unseeded import (
    FOUNDATION, TARGETS, HALF_WIDTH, QUESTION_COUNT, SevenFieldAuditError,
    boundary_targets, canonical_number, compare_rows, expected_indices, parse_production,
    validate_boundary_years, validate_ledger_trace,
)


class SevenFieldIndependentProtocolTests(unittest.TestCase):
    @staticmethod
    def record(target, year=5000, cutlet=7, day=24, month=12, mday=3):
        return f"{FOUNDATION}\t{target}\t{year}\t{cutlet}\t{day}\t{month}\t{mday}\n"

    def valid(self):
        return "".join(self.record(t) for t in TARGETS)

    def test_exact_five_neighborhood_targets(self):
        self.assertEqual(tuple(t-FOUNDATION for t in TARGETS), (-2, -1, 0, 1, 2))

    def test_five_strict_seven_column_rows(self):
        rows = parse_production(self.valid())
        self.assertEqual(len(rows), 5)
        self.assertEqual([r[1] for r in rows], list(TARGETS))

    def test_independent_equal_rows(self):
        rows = parse_production(self.valid())
        ref = [(5000, 7, 24, 12, 3)] * 5
        self.assertEqual(len(compare_rows(rows, ref)), 5)

    def test_independent_mismatch_rejected(self):
        rows = parse_production(self.valid())
        ref = [(5000, 7, 24, 12, 3)] * 5
        ref[3] = (5000, 7, 24, 12, 4)
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_UNSEEDED_DIFFERENTIAL"):
            compare_rows(rows, ref)

    def test_malformed_newline_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_PROTOCOL"):
            parse_production(self.valid().rstrip("\n"))

    def test_extra_row_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_ROW_COUNT"):
            parse_production(self.valid() + self.record(TARGETS[0]))

    def test_missing_column_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_COLUMN_COUNT"):
            parse_production(self.valid().replace("\t3\n", "\n", 1))

    def test_wrong_input_echo_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_INPUT_ECHO"):
            parse_production(self.valid().replace(str(TARGETS[0]), str(TARGETS[0]-20), 1))

    def test_all_noncanonical_integers_rejected(self):
        for value in ("+1", "-0", "00", " 1", "1 ", "1.0", "", "٠"):
            with self.subTest(value=value), self.assertRaisesRegex(
                SevenFieldAuditError, "E_SEVEN_NONCANONICAL"
            ):
                canonical_number(value)

    def test_bounds_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_BOUNDS"):
            parse_production(self.valid().replace("\t12\t3\n", "\t48\t3\n", 1))

    def test_strict_signed_gap_order(self):
        self.assertEqual(len(expected_indices()), QUESTION_COUNT)
        self.assertEqual(expected_indices()[:2], [-1, -2])
        self.assertEqual(expected_indices()[-2:], [HALF_WIDTH-1, HALF_WIDTH])
        validate_ledger_trace([(i, 42 + abs(i) % 922) for i in expected_indices()])

    def test_wrong_gate_order_rejected(self):
        rows = [(i, 42) for i in expected_indices()]
        rows[0], rows[1] = rows[1], rows[0]
        with self.assertRaisesRegex(SevenFieldAuditError, "E_UNSEEDED_SIGNED_TRACE"):
            validate_ledger_trace(rows)

    def test_short_gate_trace_rejected(self):
        with self.assertRaisesRegex(SevenFieldAuditError, "E_UNSEEDED_SIGNED_TRACE"):
            validate_ledger_trace([(i, 42) for i in expected_indices()[:-1]])

    def test_noninteger_or_out_of_bound_gap_rejected(self):
        for bad in (41, 964, True, 0):
            rows = [(i, 42) for i in expected_indices()]
            rows[9] = (rows[9][0], bad)
            with self.subTest(bad=bad), self.assertRaisesRegex(
                SevenFieldAuditError, "E_UNSEEDED_SIGNED_TRACE"
            ):
                validate_ledger_trace(rows)


    def test_boundary_target_oracle(self):
        year = Year(5000, -10, 10, FOUNDATION - 300, FOUNDATION + 400)
        self.assertEqual(boundary_targets(year), (
            FOUNDATION - 301, FOUNDATION - 300, FOUNDATION - 299,
            FOUNDATION + 399, FOUNDATION + 400, FOUNDATION + 401))

    def test_boundary_target_fails_closed(self):
        for year in (
            Year(5001, -10, 10, FOUNDATION - 300, FOUNDATION + 400),
            Year(5000, -10, 10, FOUNDATION + 1, FOUNDATION + 400),
            Year(5000, -10, 10, FOUNDATION - 100, FOUNDATION + 100),
        ):
            with self.subTest(year=year), self.assertRaisesRegex(
                SevenFieldAuditError, "E_INDEPENDENT_YEAR_BOUNDARY"
            ):
                boundary_targets(year)

    def test_eleven_real_row_protocol_with_boundary_witnesses(self):
        year = Year(5000, -10, 10, FOUNDATION - 300, FOUNDATION + 400)
        targets = TARGETS + boundary_targets(year)
        payload = "".join(self.record(target) for target in targets)
        rows = parse_production(payload, targets)
        self.assertEqual(len(rows), 11)
        self.assertEqual(len(compare_rows(
            rows, [(5000, 7, 24, 12, 3)] * 11, targets)), 11)
        with self.assertRaisesRegex(SevenFieldAuditError, "E_SEVEN_INPUT_ECHO"):
            parse_production(payload, targets[:-2] + (targets[-1], targets[-2]))

    def test_independent_boundary_year_witnesses(self):
        years = (4999, 5000, 5000, 5000, 5000, 5001)
        validate_boundary_years([(year, 1, 1, 1, 1) for year in years])

    def test_boundary_year_witness_drift_fails_closed(self):
        years = (4999, 5000, 5000, 5000, 5000, 5001)
        original = [(year, 1, 1, 1, 1) for year in years]
        for position in range(len(years)):
            drift = list(original)
            drift[position] = (years[position] + 1, 1, 1, 1, 1)
            with self.subTest(position=position), self.assertRaisesRegex(
                SevenFieldAuditError, "E_YEAR_EDGE_INDEPENDENT_YEAR_WITNESS"
            ):
                validate_boundary_years(drift)
        with self.assertRaisesRegex(
            SevenFieldAuditError, "E_YEAR_EDGE_INDEPENDENT_YEAR_WITNESS"
        ):
            validate_boundary_years(original[:-1])

    def test_boolean_oracle_field_rejected(self):
        rows = parse_production(self.valid())
        refs = [(5000, 7, 24, 12, 3)] * 5
        refs[0] = (True, 7, 24, 12, 3)
        with self.assertRaisesRegex(SevenFieldAuditError, "E_ORACLE_FIVE_FIELD_SHAPE"):
            compare_rows(rows, refs)


if __name__ == "__main__":
    unittest.main()
