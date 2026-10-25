"""Fail-closed harness tests; does not claim a production-vs-production soak."""
import json
import shlex
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import post55_differential as soak  # noqa: E402


def bridge_command(month):
    code = (
        "import sys\n"
        "for line in sys.stdin:\n"
        " c,t = line.rstrip('\\n').split('\\t')\n"
        f" print(c+'\\t'+t+'\\t5000\\t1\\t1\\t{month}\\t1', flush=True)\n"
    )
    return shlex.join([sys.executable, "-c", code])


class SoakRunnerTests(unittest.TestCase):
    def test_deterministic_and_diverse(self):
        a = soak.corpus(100, 123456)
        self.assertEqual(a, soak.corpus(100, 123456))
        self.assertEqual(len(a), 100)
        self.assertEqual(len(set(a)), 100)
        self.assertTrue(any(c != t for c, t in a))
        self.assertTrue(any(c < 0 for c, _ in a))
        self.assertTrue(any(c > 0 for c, _ in a))

    def test_bad_protocol_is_rejected(self):
        pair = [(1, 2)]
        with self.assertRaisesRegex(ValueError, "LINE_COUNT"):
            soak.normalized("", pair, "TEST")
        with self.assertRaisesRegex(ValueError, "FORMAT"):
            soak.normalized("1\t2\t5000\t1\t1\t1\t01", pair, "TEST")
        with self.assertRaisesRegex(ValueError, "PAIR"):
            soak.normalized("1\t3\t5000\t1\t1\t1\t1", pair, "TEST")
        with self.assertRaisesRegex(ValueError, "CANONICAL_RANGE"):
            soak.normalized("1\t2\t5000\t18\t1\t1\t1", pair, "TEST")

    def test_external_program_protocol(self):
        self.assertEqual(
            soak.invoke(bridge_command(3), [(1, 2), (-200, 300)], 30, "FAKE"),
            [(5000, 1, 1, 3, 1), (5000, 1, 1, 3, 1)],
        )

    def test_matching_diagnostic_is_not_certification(self):
        with tempfile.TemporaryDirectory() as td:
            evidence = Path(td) / "evidence.json"
            command = bridge_command(1)
            code = soak.main([
                "--kotlin-command", command,
                "--python-command", command,
                "--cases", "6", "--seed", "99", "--batch", "3",
                "--kotlin-revision", "a" * 40,
                "--python-revision", "b" * 40,
                "--evidence", str(evidence),
            ])
            self.assertEqual(code, 0)
            data = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(data["completed"], 6)
            self.assertEqual(data["status"], "PASS_DIAGNOSTIC_NOT_CERTIFIED")
            self.assertFalse(data["certifiable"])

    def test_mismatch_is_fail_closed_with_witness(self):
        with tempfile.TemporaryDirectory() as td:
            evidence = Path(td) / "evidence.json"
            code = soak.main([
                "--kotlin-command", bridge_command(1),
                "--python-command", bridge_command(2),
                "--cases", "1",
                "--kotlin-revision", "a" * 40,
                "--python-revision", "b" * 40,
                "--evidence", str(evidence),
            ])
            self.assertEqual(code, 2)
            data = json.loads(evidence.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "FAIL_MISMATCH")
            self.assertEqual(data["mismatch"]["index"], 0)
            self.assertNotEqual(data["mismatch"]["kotlin"], data["mismatch"]["python"])

    def test_oracle_cannot_be_certified(self):
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaises(SystemExit) as caught:
                soak.main([
                    "--kotlin-command", bridge_command(1),
                    "--python-command", bridge_command(1),
                    "--certify", "--kotlin-mode", "oracle",
                    "--kotlin-revision", "a" * 40,
                    "--python-revision", "b" * 40,
                    "--evidence", str(Path(td) / "evidence.json"),
                ])
            self.assertEqual(caught.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
