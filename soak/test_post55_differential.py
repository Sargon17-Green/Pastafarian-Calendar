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

    def test_foundation_scope_is_bounded_and_preserves_default_corpus(self):
        foundation = soak.FOUNDATION
        self.assertEqual(
            soak.corpus(5, 55, "foundation"),
            [(foundation - 1, foundation - 1),
             (foundation, foundation),
             (foundation + 1, foundation + 1),
             (foundation, foundation + 1),
             (foundation + 1, foundation)],
        )
        self.assertEqual(soak.corpus(4, 55), soak.corpus(4, 55, "all"))
        with self.assertRaisesRegex(ValueError, "E_SOAK_ANCHOR_SCOPE"):
            soak.corpus(1, 55, "unsupported")

    def test_foundation_scope_evidence_not_certified(self):
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / "bounded.json"
            code = soak.main([
                "--kotlin-command", bridge_command(1),
                "--python-command", bridge_command(1),
                "--anchor-scope", "foundation", "--cases", "3", "--batch", "1",
                "--kotlin-mode", "production",
                "--kotlin-revision", "a" * 40,
                "--python-revision", "b" * 40,
                "--evidence", str(output),
            ])
            self.assertEqual(code, 0)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(report["anchor_scope"], "foundation")
            self.assertEqual(report["completed"], 3)
            self.assertEqual(report["status"], "PASS_DIAGNOSTIC_NOT_CERTIFIED")
            self.assertFalse(report["certifiable"])

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

    def test_no_unverified_engine_can_self_certify(self):
        # Mode alone cannot prove the executable is an independent Kotlin
        # production engine. Both modes must fail closed for certification.
        for mode in ("oracle", "production"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as td:
                with self.assertRaises(SystemExit) as caught:
                    soak.main([
                        "--kotlin-command", bridge_command(1),
                        "--python-command", bridge_command(1),
                        "--certify", "--kotlin-mode", mode,
                        "--kotlin-revision", "a" * 40,
                        "--python-revision", "b" * 40,
                        "--evidence", str(Path(td) / "evidence.json"),
                    ])
                self.assertEqual(caught.exception.code, 2)
                self.assertFalse((Path(td) / "evidence.json").exists())


    def test_tablets_geometric_exclusion_is_bound_to_production_sources(self):
        """Bounded static geometry guard, not a full-date certification.

        The Year-5000 candidate search needs 5778 days around the
        calculation date; no gate can jump more than 963 days, and the
        current production index budget is 8192 on either side.
        This test intentionally fails if those source assumptions drift.
        """
        root = Path(__file__).resolve().parents[1]
        gate = (root / "src/main/kotlin/pastafari/ProductionGateYear5000Engine.kt").read_text(
            encoding="utf-8"
        )
        navigator = (root / "src/main/kotlin/pastafari/ProductionYearNavigator.kt").read_text(
            encoding="utf-8"
        )
        bridge = (root / "soak/Post55ProductionDateBridge.kt").read_text(
            encoding="utf-8"
        )
        self.assertIn("private val maxGateAbsIndex: Int = 8192", gate)
        self.assertIn("check(chosen in 42..963)", gate)
        self.assertIn(
            "coverDays(calculationDay - 5778L, calculationDay + 5778L)", gate
        )
        self.assertIn("maxGateAbsIndex: Int = 8192", navigator)
        self.assertIn("8192L * 963L - 5778L", bridge)
        self.assertIn("E_POST55_GATE_GEOMETRIC_LIMIT", bridge)

        max_gate_index = 8192
        max_gap = 963
        candidate_half_window = 5778
        conservative_limit = max_gate_index * max_gap - candidate_half_window
        self.assertEqual(conservative_limit, 7883118)
        for tablets_day in (soak.TABLETS - 1, soak.TABLETS, soak.TABLETS + 1):
            with self.subTest(tablets_day=tablets_day):
                distance = abs(tablets_day - soak.FOUNDATION)
                minimum_gate_steps = (distance + max_gap - 1) // max_gap
                self.assertGreater(minimum_gate_steps, max_gate_index)
                self.assertGreater(distance, conservative_limit)

    def test_four_distinct_anchor_epochs_in_small_corpus(self):
        pairs = soak.corpus(4, 55)
        self.assertEqual(
            pairs, [(soak.FOUNDATION - 1, soak.FOUNDATION - 1),
                    (soak.TABLETS - 1, soak.TABLETS - 1),
                    (-1, -1), (739833, 739833)]
        )

    def test_fake_production_mode_is_still_diagnostic(self):
        with tempfile.TemporaryDirectory() as td:
            output = Path(td) / "evidence.json"
            code = soak.main([
                "--kotlin-command", bridge_command(1),
                "--python-command", bridge_command(1),
                "--kotlin-mode", "production",
                "--cases", "4",
                "--kotlin-revision", "a" * 40,
                "--python-revision", "b" * 40,
                "--evidence", str(output),
            ])
            self.assertEqual(code, 0)
            report = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(report["status"], "PASS_DIAGNOSTIC_NOT_CERTIFIED")
            self.assertFalse(report["certifiable"])


if __name__ == "__main__":
    unittest.main()
