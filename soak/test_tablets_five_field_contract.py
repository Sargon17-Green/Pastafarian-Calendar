"""Synthetic safety gates for TABLETS five-field acceptance; NO real DATE PASS."""
import sys
from pathlib import Path
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_five_field_contract import (
    ContractError, DateImplementation, PINNED_SHA, STATUS,
    compare_tablets_five_fields, verify_bracket_receipt,
)

ORIGIN = 0
TARGETS = (83, 84, 85)
SRC = DateImplementation("pinned", PINNED_SHA, "a" * 64, "pinned integration")
IND = DateImplementation("independent", "b" * 40, "c" * 64, "structural date")


def receipt():
    return {
        "status": "PASS_TABLETS_INDEPENDENT_UNSEEDED_BRACKETS_NOT_CERTIFIED",
        "origin": 0, "targets": [83, 84, 85], "checkpoint_seed_used": False,
        "tablets_bracket_verified": True, "certifiable": False,
        "full_date_verified": False, "tablets_date_components_verified": False,
        "production_gate_limit_unchanged": 8192, "questions": 3,
        "segment_limit": 2,
        "brackets": [
            {"target_day": 83, "bracket_low": 42, "bracket_high": 84,
             "gate_index": 2, "from_foundation": 2},
            {"target_day": 84, "bracket_low": 42, "bracket_high": 84,
             "gate_index": 2, "from_foundation": 2},
            {"target_day": 85, "bracket_low": 84, "bracket_high": 126,
             "gate_index": 3, "from_foundation": 3},
        ],
        "segments": [
            {"end_index": 2, "end_day": 84, "segment_sha256": "1" * 64},
            {"end_index": 3, "end_day": 126, "segment_sha256": "2" * 64},
        ],
        "segment_count": 2, "terminal_segment_sha256": "2" * 64,
        "trace_sha256": "3" * 64,
    }


def one(_origin, _target):
    return (5000, 2, 4, 7, 11)


def two(_origin, _target):
    return (5000, 2, 4, 7, 11)


def run(**kwargs):
    args = dict(receipt=receipt(), independent_date=one, pinned_date=two,
                independent_source=IND, pinned_source=SRC, origin=ORIGIN,
                targets=TARGETS)
    args.update(kwargs)
    return compare_tablets_five_fields(**args)


class TabletsFiveFieldContracts(unittest.TestCase):
    def test_synthetic_three_by_five_not_certified(self):
        r = run()
        self.assertEqual(r["status"], STATUS)
        self.assertEqual((r["cases"], r["fields_per_case"]), (3, 5))
        self.assertFalse(r["full_date_certified"])
        self.assertFalse(r["algorithmic_independence_certified"])
        self.assertFalse(r["receipt_replay_verified_here"])
        self.assertFalse(r["source_cache_independence_verified_here"])

    def test_requires_independent_date_not_merely_gate_bracket(self):
        with self.assertRaisesRegex(ContractError, "E_TABLETS_INDEPENDENT_DATE_ORACLE_REQUIRED"):
            run(independent_date=None)
        with self.assertRaisesRegex(ContractError, "E_TABLETS_INDEPENDENT_DATE_ORACLE_REQUIRED"):
            run(independent_date=two, pinned_date=two)

    def test_all_five_mismatches_detected(self):
        for slot in range(5):
            def wrong(_origin, _target):
                row = list(one(0, 0))
                row[slot] += 1
                return tuple(row)
            with self.subTest(field=slot):
                with self.assertRaisesRegex(ContractError, "E_TABLETS_DATE_MISMATCH_AT_83"):
                    run(pinned_date=wrong)

    def test_bool_and_string_not_accepted_as_date_integer(self):
        for invalid in (True, "2", 2.0):
            def malformed(_origin, _target):
                return (5000, invalid, 4, 7, 11)
            with self.subTest(value=invalid):
                with self.assertRaisesRegex(ContractError, "E_INDEPENDENT_DATE_FIELDS_AT_83"):
                    run(independent_date=malformed)

    def test_date_ranges(self):
        for row in ((0, 1, 1, 1, 1), (5000, 18, 1, 1, 1),
                    (5000, 1, 0, 1, 1), (5000, 1, 1, 48, 1),
                    (5000, 1, 1, 1, 0)):
            with self.subTest(row=row):
                with self.assertRaisesRegex(ContractError, "E_INDEPENDENT_DATE_RANGE_AT_83"):
                    run(independent_date=lambda *_: row)

    def test_source_provenance_must_be_distinct_and_pinned(self):
        with self.assertRaisesRegex(ContractError, "E_TABLETS_DATE_SOURCE_SEPARATION"):
            run(independent_source=SRC)
        with self.assertRaisesRegex(ContractError, "E_TABLETS_DATE_SOURCE_SEPARATION"):
            run(pinned_source=IND)
        with self.assertRaisesRegex(ContractError, "E_INDEPENDENT_PROVENANCE"):
            run(independent_source=DateImplementation("", "b" * 40, "c" * 64, ""))

    def test_required_unseeded_and_uncertified(self):
        for key, value in (("checkpoint_seed_used", True), ("certifiable", True),
                           ("full_date_verified", True),
                           ("tablets_date_components_verified", True),
                           ("production_gate_limit_unchanged", 8193)):
            data = receipt()
            data[key] = value
            with self.subTest(key=key):
                with self.assertRaisesRegex(ContractError, "E_TABLETS_UNSEEDED_PROOF_REQUIRED"):
                    run(receipt=data)

    def test_receipt_cannot_be_empty_or_wrong_target(self):
        with self.assertRaisesRegex(ContractError, "E_TABLETS_BRACKET_RECEIPT"):
            run(receipt=None)
        data = receipt()
        data["targets"][1] += 1
        with self.assertRaisesRegex(ContractError, "E_TABLETS_UNSEEDED_PROOF_REQUIRED"):
            run(receipt=data)

    def test_query_budget_fail_closed(self):
        for invalid in (0, 32769, True):
            data = receipt()
            data["questions"] = invalid
            with self.subTest(invalid=invalid):
                with self.assertRaisesRegex(ContractError, "E_TABLETS_PROOF_BUDGET"):
                    run(receipt=data)

    def test_bracket_gap_and_index_fail_closed(self):
        data = receipt()
        data["brackets"][2]["bracket_high"] = 1060
        with self.assertRaisesRegex(ContractError, "E_TABLETS_BRACKET_CONTENT"):
            run(receipt=data)
        data = receipt()
        data["brackets"][0]["gate_index"] = True
        with self.assertRaisesRegex(ContractError, "E_TABLETS_BRACKET_CONTENT"):
            run(receipt=data)

    def test_segment_chain_length_and_terminal_fail_closed(self):
        data = receipt()
        data["segments"][1]["end_index"] = 2
        with self.assertRaisesRegex(ContractError, "E_TABLETS_SEGMENT_CHAIN"):
            run(receipt=data)
        data = receipt()
        data["terminal_segment_sha256"] = "4" * 64
        with self.assertRaisesRegex(ContractError, "E_TABLETS_SEGMENT_TERMINAL"):
            run(receipt=data)

    def test_expired_deadline(self):
        with self.assertRaisesRegex(ContractError, "E_TABLETS_DATE_DEADLINE"):
            run(deadline=time.monotonic() - 1)

    def test_no_implicit_checkpoint_trust(self):
        verify_bracket_receipt(receipt(), targets=TARGETS, origin=0)
        data = receipt()
        data["checkpoint_seed_used"] = True
        with self.assertRaises(ContractError):
            verify_bracket_receipt(data, targets=TARGETS, origin=0)


if __name__ == "__main__":
    unittest.main()
