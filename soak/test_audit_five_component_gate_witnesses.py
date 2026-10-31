"""Synthetic contracts for independent signed gate witness five-field audit."""
import sys
from pathlib import Path
import tempfile
import time
import json
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_five_component_gate_witnesses import (
    WitnessError, FIELDS, compare_five_fields, make_witnesses, save_evidence,
)


def gaps(index):
    return 50 if index < 0 else 60


class FiveComponentGateWitnessTests(unittest.TestCase):
    def test_signed_global_indices_and_boundary_cases(self):
        queries = []
        def oracle(index):
            queries.append(index)
            return gaps(index)
        pairs, gates = make_witnesses(oracle, gaps, foundation=1000)
        self.assertEqual(queries, [-1, 1])
        self.assertEqual([g["gate_day"] for g in gates], [950, 1060])
        self.assertEqual(pairs, [(1000, 1000), (1000, 949), (1000, 950),
                                 (1000, 951), (1000, 1059), (1000, 1060),
                                 (1000, 1061)])

    def test_all_five_fields_match(self):
        pairs, _ = make_witnesses(gaps, gaps, foundation=1000)
        rows = [(5000, 1, 2, 3, 4)] * 7
        self.assertIsNone(compare_five_fields(pairs, rows, rows))

    def test_each_of_five_fields_can_fail_closed(self):
        pairs, _ = make_witnesses(gaps, gaps, foundation=1000)
        row = (5000, 1, 2, 3, 4)
        for idx, field in enumerate(FIELDS):
            with self.subTest(field=field):
                bad = list(row)
                bad[idx] += 1
                mismatch = compare_five_fields(pairs, [row] * 7,
                                                [row, row, row, tuple(bad)] + [row] * 3)
                self.assertEqual(mismatch["index"], 3)
                self.assertEqual(mismatch["fields"], [field])

    def test_gap_mismatch_at_precise_signed_index(self):
        with self.assertRaisesRegex(WitnessError, "E_WITNESS_GATE_MISMATCH_AT_-1"):
            make_witnesses(gaps, lambda i: gaps(i) + (1 if i == -1 else 0))

    def test_invalid_gap_ranges_and_bool_rejected(self):
        for gap in (41, 964, True):
            with self.subTest(gap=gap):
                with self.assertRaisesRegex(WitnessError, "E_WITNESS_INDEPENDENT_RANGE_AT_-1"):
                    make_witnesses(lambda i: gap, gaps)

    def test_deadline_and_bad_origin(self):
        with self.assertRaisesRegex(WitnessError, "E_WITNESS_DEADLINE"):
            make_witnesses(gaps, gaps, deadline=time.monotonic() - 1)
        with self.assertRaisesRegex(WitnessError, "E_WITNESS_ORIGIN_TYPE"):
            make_witnesses(gaps, gaps, foundation=True)

    def test_protocol_shape_fail_closed(self):
        pairs, _ = make_witnesses(gaps, gaps, foundation=1000)
        with self.assertRaisesRegex(WitnessError, "E_WITNESS_ROW_COUNT"):
            compare_five_fields(pairs, [(1,2,3,4,5)] * 6, [(1,2,3,4,5)] * 7)
        with self.assertRaisesRegex(WitnessError, "E_WITNESS_FIELD_COUNT_AT_0"):
            compare_five_fields(pairs, [(1,2,3,4)] * 7, [(1,2,3,4,5)] * 7)

    def test_json_evidence_atomic_output(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "nested" / "evidence.json"
            save_evidence(p, {"status": "synthetic"})
            self.assertEqual(json.loads(p.read_text())["status"], "synthetic")
            self.assertFalse(p.with_suffix(".json.partial").exists())


if __name__ == "__main__":
    unittest.main()
