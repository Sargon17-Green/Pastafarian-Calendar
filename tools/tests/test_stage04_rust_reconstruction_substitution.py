"""Negative controls for the explicitly approved 2026 reconstruction substitution.

These unit tests do not execute Rust and cannot establish historical RED.
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import stage04_rust_reconstruction_substitution as gate


def fixture_rows() -> tuple[str, str]:
    expect = ["index\tday\toracle_tag\tregion\tdistance"]
    observed = ["index\tday\tnative_tag"]
    for i in range(128):
        d = ((i + 1) << (i % 120)) + 37 * i + 3
        day = gate.F - d if i % 2 == 0 else gate.F + d
        tag = 2 * d + (0 if i % 2 == 0 else 1)
        expect.append(f"{i}\t{day}\t{tag}\t{'BEFORE' if i % 2 == 0 else 'ON_OR_AFTER'}\t{d}")
        observed.append(f"{i}\t{day}\t{tag}")
    return "\n".join(expect) + "\n", "\n".join(observed) + "\n"


class TestStage04ApprovedSubstitution(unittest.TestCase):
    def setUp(self):
        import hashlib
        from unittest.mock import patch
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.e = Path(self.tmp.name) / "oracle.tsv"
        self.o = Path(self.tmp.name) / "observed.tsv"
        e, o = fixture_rows()
        self.e.write_text(e, encoding="utf-8")
        self.o.write_text(o, encoding="utf-8")
        patches = [
            patch.object(gate, "EXPECTED_SHA256", hashlib.sha256(e.encode()).hexdigest()),
            patch.object(gate, "OBSERVED_SHA256", hashlib.sha256(o.encode()).hexdigest()),
        ]
        for item in patches:
            item.start()
            self.addCleanup(item.stop)

    def test_exact_128_observations_with_64_per_side(self):
        x = gate.verify_numeric(self.e, self.o)
        self.assertEqual((x["independently_verified_observed_rows"],
                          x["before_foundation"], x["on_or_after_foundation"]), (128, 64, 64))

    def test_tampered_observed_actual_rejected(self):
        data = self.o.read_text()
        self.o.write_text(data.replace("0\t-15055675\t8", "0\t-15055675\t9", 1))
        with self.assertRaisesRegex(gate.AdmissionError, "digest mismatch"):
            gate.verify_numeric(self.e, self.o)

    def test_truncated_native_rows_rejected(self):
        self.o.write_text("\n".join(self.o.read_text().splitlines()[:-1]) + "\n")
        with self.assertRaisesRegex(gate.AdmissionError, "digest mismatch"):
            gate.verify_numeric(self.e, self.o)

    def test_wrong_independent_oracle_rejected(self):
        self.e.write_text(self.e.read_text().replace("0\t-15055675\t8", "0\t-15055675\t7", 1))
        with self.assertRaisesRegex(gate.AdmissionError, "digest mismatch"):
            gate.verify_numeric(self.e, self.o)

    def test_stale_head_fails_closed(self):
        from unittest.mock import patch
        with patch.object(gate, "command", return_value="0" * 40):
            with self.assertRaisesRegex(gate.AdmissionError, "checkout"):
                gate.verify(Path(self.tmp.name), "f" * 40)


if __name__ == "__main__":
    unittest.main()
