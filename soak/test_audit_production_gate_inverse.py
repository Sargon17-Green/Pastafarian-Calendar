"""Synthetic strict-protocol mutation suite; does not substitute for production JVM."""
from __future__ import annotations
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_gate_inverse import (
    FOUNDATION, GATE_COUNT, HALF_WIDTH, EXPECTED_CHECKS, INTERIOR_INDICES, INTERIOR_COUNT,
    InverseAuditError, parse_transcript, compare,
)

SHARED = (-12, -4, 4, 14)


class FakeLedger:
    def day(self, index):
        if type(index) is not int or not -HALF_WIDTH <= index <= HALF_WIDTH:
            raise InverseAuditError("E_FAKE_BOUNDS")
        return FOUNDATION + index * 100

    def gate_index(self, day):
        # Independent integer arithmetic inverse, no lookup in test transcript.
        gap = day - FOUNDATION
        return gap // 100 if gap % 100 == 0 and -HALF_WIDTH <= gap // 100 <= HALF_WIDTH else None


def valid_transcript():
    ledger = FakeLedger()
    rows = [f"GATE\t{i}\t{ledger.day(i)}" for i in range(-HALF_WIDTH, HALF_WIDTH + 1)]
    rows += [f"INVERSE\t{ledger.day(i)}\t{i}" for i in range(-HALF_WIDTH, HALF_WIDTH + 1)]
    for index in SHARED:
        rows.append(f"SHARED\t{index}")
        for offset in (-1, 1):
            rows.append(f"NEAR\t{index}\t{offset}\t{ledger.day(index)+offset}\tNONE")
    for index in INTERIOR_INDICES:
        left, right = ledger.day(index), ledger.day(index + 1)
        gap = right - left
        targets = (left + gap // 4, left + gap // 2, right - gap // 4)
        for ordinal, target in enumerate(targets, 1):
            rows.append(f"INTERIOR\t{index}\t{ordinal}\t{target}\tNONE")
    rows += ["PRODUCTION_GATE_LIMIT\t8192", f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT}"]
    return "\n".join(rows) + "\n"


class GateInverseContractTests(unittest.TestCase):
    def setUp(self):
        self.raw = valid_transcript()
        self.ledger = FakeLedger()

    def mutation(self, old, new, error, *, compare_result=True):
        self.assertIn(old, self.raw)
        changed = self.raw.replace(old, new, 1)
        with self.assertRaisesRegex(InverseAuditError, error):
            parsed = parse_transcript(changed)
            if compare_result:
                compare(parsed, self.ledger, SHARED)

    def test_valid_transcript_and_exact_count(self):
        result = compare(parse_transcript(self.raw), self.ledger, SHARED)
        self.assertEqual(result["typed_comparisons"], EXPECTED_CHECKS)
        self.assertEqual(result["exact_inverse_comparisons"], 561)
        self.assertEqual(result["non_gate_neighbor_comparisons"], 8)
        self.assertEqual(result["non_gate_interior_comparisons"], INTERIOR_COUNT)
        self.assertEqual(result["interior_sampled_intervals"], 16)
        self.assertEqual(EXPECTED_CHECKS, 1184)

    def test_gate_day_mutation_detected(self):
        i = 7
        self.mutation(f"GATE\t{i}\t{self.ledger.day(i)}\n",
                      f"GATE\t{i}\t{self.ledger.day(i)+1}\n", "E_GATE_DAY_MISMATCH_7")

    def test_exact_inverse_mutation_detected(self):
        i = 5
        self.mutation(f"INVERSE\t{self.ledger.day(i)}\t{i}\n",
                      f"INVERSE\t{self.ledger.day(i)}\t{i+1}\n", "E_EXACT_INVERSE_MISMATCH_5")

    def test_inverse_day_spoof_detected(self):
        i = 3
        self.mutation(f"INVERSE\t{self.ledger.day(i)}\t{i}\n",
                      f"INVERSE\t{self.ledger.day(i)+1}\t{i}\n", "E_EXACT_INVERSE_MISMATCH_3")

    def test_wrong_shared_boundary_detected(self):
        raw = self.raw.replace("SHARED\t-12\n", "SHARED\t-11\n", 1)
        raw = raw.replace("NEAR\t-12\t", "NEAR\t-11\t")
        with self.assertRaisesRegex(InverseAuditError, "E_SHARED_INDEPENDENT_MISMATCH"):
            compare(parse_transcript(raw), self.ledger, SHARED)

    def test_neighbor_false_positive_detected(self):
        i = -4
        self.mutation(f"NEAR\t{i}\t1\t{self.ledger.day(i)+1}\tNONE",
                      f"NEAR\t{i}\t1\t{self.ledger.day(i)+1}\t{i}",
                      "E_FALSE_POSITIVE_INVERSE_-4_1")

    def test_neighbor_day_spoof_detected(self):
        i = 4
        self.mutation(f"NEAR\t{i}\t-1\t{self.ledger.day(i)-1}\tNONE",
                      f"NEAR\t{i}\t-1\t{self.ledger.day(i)-2}\tNONE",
                      "E_NEAR_TARGET_MISMATCH_4_-1")

    def test_interior_false_positive_detected(self):
        index, ordinal = INTERIOR_INDICES[0], 1
        day = self.ledger.day(index) + 25
        self.mutation(f"INTERIOR\t{index}\t{ordinal}\t{day}\tNONE",
                      f"INTERIOR\t{index}\t{ordinal}\t{day}\t{index}",
                      f"E_INTERIOR_FALSE_POSITIVE_{index}_{ordinal}")

    def test_interior_day_spoof_detected(self):
        index, ordinal = INTERIOR_INDICES[1], 2
        day = self.ledger.day(index) + 50
        self.mutation(f"INTERIOR\t{index}\t{ordinal}\t{day}\tNONE",
                      f"INTERIOR\t{index}\t{ordinal}\t{day+1}\tNONE",
                      f"E_INTERIOR_TARGET_MISMATCH_{index}_{ordinal}")

    def test_duplicate_interior_detected(self):
        index = INTERIOR_INDICES[2]
        first, second = self.ledger.day(index) + 25, self.ledger.day(index) + 50
        self.mutation(f"INTERIOR\t{index}\t1\t{first}\tNONE",
                      f"INTERIOR\t{index}\t2\t{first}\tNONE",
                      "E_DUPLICATE_INTERIOR", compare_result=False)

    def test_interior_unknown_ordinal_detected(self):
        index = INTERIOR_INDICES[3]
        day = self.ledger.day(index) + 25
        self.mutation(f"INTERIOR\t{index}\t1\t{day}\tNONE",
                      f"INTERIOR\t{index}\t4\t{day}\tNONE",
                      "E_INTERIOR_SET", compare_result=False)

    def test_interior_noncanonical_ordinal_detected(self):
        index = INTERIOR_INDICES[4]
        day = self.ledger.day(index) + 25
        self.mutation(f"INTERIOR\t{index}\t1\t{day}\tNONE",
                      f"INTERIOR\t{index}\t01\t{day}\tNONE",
                      "E_NONCANONICAL_INTEGER", compare_result=False)

    def test_duplicate_gate_detected(self):
        self.mutation(f"GATE\t1\t{self.ledger.day(1)}",
                      f"GATE\t0\t{self.ledger.day(1)}", "E_DUPLICATE_GATE",compare_result=False)

    def test_duplicate_inverse_detected(self):
        self.mutation(f"INVERSE\t{self.ledger.day(1)}\t1",
                      f"INVERSE\t{self.ledger.day(0)}\t1", "E_DUPLICATE_INVERSE",compare_result=False)

    def test_duplicate_neighbor_detected(self):
        self.mutation(f"NEAR\t-4\t1\t{self.ledger.day(-4)+1}\tNONE",
                      f"NEAR\t-4\t-1\t{self.ledger.day(-4)+1}\tNONE", "E_DUPLICATE_NEAR", compare_result=False)

    def test_removed_row_detected(self):
        row = f"GATE\t1\t{self.ledger.day(1)}\n"
        self.mutation(row, "", "E_ROW_COUNT", compare_result=False)

    def test_plus_prefixed_integer_detected(self):
        self.mutation("SHARED\t-12", "SHARED\t+12", "E_NONCANONICAL_INTEGER",compare_result=False)

    def test_leading_zero_detected(self):
        self.mutation("GATE\t1\t", "GATE\t01\t", "E_NONCANONICAL_INTEGER",compare_result=False)

    def test_wrong_limit_detected(self):
        self.mutation("PRODUCTION_GATE_LIMIT\t8192", "PRODUCTION_GATE_LIMIT\t8193", "E_PRODUCTION_LIMIT",compare_result=False)

    def test_wrong_expansion_detected(self):
        self.mutation(f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT}",
                      f"PRODUCTION_EXPANDED_GATES\t{GATE_COUNT+1}", "E_PRODUCTION_EXPANDED",compare_result=False)

    def test_unknown_row_detected(self):
        self.mutation("SHARED\t-12", "OTHER\t-12", "E_UNKNOWN_ROW",compare_result=False)

    def test_missing_newline_and_crlf_detected(self):
        for raw in (self.raw[:-1], self.raw.replace("\n", "\r\n")):
            with self.subTest(suffix=raw[-4:]), self.assertRaisesRegex(InverseAuditError, "E_FORMAT"):
                parse_transcript(raw)

    def test_wrong_boundary_order_detected(self):
        raw = self.raw.replace("SHARED\t-12\n", "SHARED\t__SWAP__\n", 1).replace("SHARED\t14\n", "SHARED\t-12\n", 1).replace("SHARED\t__SWAP__\n", "SHARED\t14\n", 1)
        # Duplicate and wrong sequence must never silently pass.
        with self.assertRaises(InverseAuditError):
            parsed = parse_transcript(raw)
            compare(parsed, self.ledger, SHARED)


if __name__ == "__main__":
    unittest.main()
