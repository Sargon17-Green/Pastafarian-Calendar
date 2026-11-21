"""Synthetic fail-closed protocol and mutation controls (not Native PASS)."""
from __future__ import annotations
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_production_gate_cache_state import (
    AuditError, FOUNDATION, GAP_INDICES, GAPS, INDICES, LIMIT, MIDS,
    ORDERS, PASS, ROUNDS, WARMS, ROWS, check_gap_sequence, compare,
    parse_transcript, validate_success, write_report
)


class FakeLedger:
    def day(self, index):
        return FOUNDATION + 50 * index

    def gate_index(self, day):
        offset = day - FOUNDATION
        return offset // 50 if offset % 50 == 0 else None


def transcript():
    ledger, out = FakeLedger(), []
    for name, order in ORDERS.items():
        for pos, index in enumerate(order):
            out.append(f"WARM\t{name}\t{pos}\t{index}\t{ledger.day(index)}")
        for pos, index in enumerate(INDICES):
            out.append(f"ROUND\t{name}\t{pos}\t{index}\t{ledger.day(index)}\t{index}")
        for pos, index in enumerate(INDICES):
            out.append(f"MID\t{name}\t{pos}\t{index}\t{ledger.day(index)+25}\tNONE")
        out.append(f"SESSION\t{name}\t562")
    assert len(out) == ROWS
    return "\n".join(out) + "\n"


def replace_field(raw, row, column, new):
    lines = raw.splitlines()
    fields = lines[row].split("\t")
    fields[column] = str(new)
    lines[row] = "\t".join(fields)
    return "\n".join(lines) + "\n"


def good_report():
    return {
        "status": PASS, "source_sha": "a"*40, "production_exit_code": 0,
        "production_jar_sha256": "a"*64, "transcript_sha256": "b"*64,
        "gap_trace_sha256": "c"*64, "oracle_code_sha256": "d"*64,
        "independent_gap_questions": GAPS, "independent_gate_days": 562,
        "roundtrips": ROUNDS, "nongate_probes": MIDS, "warming_rows": WARMS,
        "mismatches": 0, "max_year_transitions_configured": 8,
        "year_transitions_exercised": False,
        "session_gate_counts": {name: 562 for name in ORDERS},
    }


class GateCacheTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = transcript()

    def check(self, raw):
        return compare(parse_transcript(raw), FakeLedger())

    def test_clean(self):
        result = self.check(self.raw)
        self.assertEqual((result["roundtrips"], result["nongate_probes"],
                          result["warming_rows"], result["mismatches"]),
                         (57, 57, 38, 0))

    def test_warming_orders_distinct(self):
        self.assertEqual(len(INDICES), len(set(INDICES)))
        self.assertEqual(ORDERS["FRESH"], ())
        self.assertEqual(ORDERS["NEGATIVE_FIRST"], tuple(reversed(ORDERS["POSITIVE_FIRST"])))

    def test_missing_row(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_ROWS"):
            parse_transcript("\n".join(self.raw.splitlines()[:-1]) + "\n")

    def test_duplicated_row(self):
        lines = self.raw.splitlines()
        lines[1] = lines[0]
        with self.assertRaisesRegex(AuditError, "E_CACHE_PROTOCOL"):
            parse_transcript("\n".join(lines) + "\n")

    def test_off_by_one_gate(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_GATE_MISMATCH"):
            self.check(replace_field(self.raw, 0, 4, FakeLedger().day(-280)+1))

    def test_sign_inversion(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_PROTOCOL"):
            parse_transcript(replace_field(self.raw, 0, 3, 280))

    def test_stale_cache_warm(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_STALE_WARM"):
            self.check(replace_field(self.raw, 39, 4, FakeLedger().day(-280)-50))

    def test_wrong_inverse(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_ROUNDTRIP"):
            parse_transcript(replace_field(self.raw, 0, 5, 1))

    def test_mid_off_by_one(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_NONGATE_MISMATCH"):
            self.check(replace_field(self.raw, 19, 4, FakeLedger().day(-280)+24))

    def test_mid_false_positive(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_FALSE_POSITIVE"):
            parse_transcript(replace_field(self.raw, 19, 5, "-280"))

    def test_reorder(self):
        lines = self.raw.splitlines()
        lines[0], lines[1] = lines[1], lines[0]
        with self.assertRaisesRegex(AuditError, "E_CACHE_PROTOCOL"):
            parse_transcript("\n".join(lines) + "\n")

    def test_noncanonical_integer(self):
        with self.assertRaisesRegex(AuditError, "E_NONCANONICAL_INTEGER"):
            parse_transcript(replace_field(self.raw, 0, 2, "00"))

    def test_crlf(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_FORMAT"):
            parse_transcript(self.raw.replace("\n", "\r\n"))

    def test_no_final_newline(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_FORMAT"):
            parse_transcript(self.raw.rstrip("\n"))

    def test_extra_stdout(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_ROWS"):
            parse_transcript(self.raw + "debug\n")

    def test_exceeded_budget(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_GATE_BUDGET"):
            parse_transcript(self.raw.replace("SESSION\tFRESH\t562",
                                              f"SESSION\tFRESH\t{LIMIT+1}", 1))

    def test_gap_missing(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_ORACLE_QUESTION_ORDER"):
            check_gap_sequence(GAP_INDICES[:-1], GAPS-1)

    def test_gap_duplicate(self):
        with self.assertRaisesRegex(AuditError, "E_CACHE_ORACLE_QUESTION_ORDER"):
            check_gap_sequence(GAP_INDICES[:-1] + (GAP_INDICES[0],), GAPS)

    def test_provenance(self):
        validate_success(good_report())
        wrong = good_report()
        wrong["oracle_code_sha256"] = "x"
        with self.assertRaisesRegex(AuditError, "E_CACHE_PROVENANCE"):
            validate_success(wrong)

    def test_bad_report_count(self):
        wrong = good_report()
        wrong["roundtrips"] = 56
        with self.assertRaisesRegex(AuditError, "E_CACHE_REPORT_COUNTS"):
            validate_success(wrong)

    def test_sha_readback(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "cache.json"
            sha = write_report(path, good_report())
            self.assertEqual(sha, hashlib.sha256(path.read_bytes()).hexdigest())
            self.assertIn(sha, path.with_suffix(".json.sha256").read_text())


if __name__ == "__main__":
    unittest.main()
