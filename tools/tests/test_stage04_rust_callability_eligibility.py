"""Synthetic Git histories; no fixture is historical Rust RED."""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from stage04_rust_callability_eligibility import (
    check_callability, supported_signature, validated_symbol, test_body)
from stage04_rust_witness_provenance import ProvenanceError

class CallabilityTests(unittest.TestCase):
    def setUp(self):
        t = tempfile.TemporaryDirectory()
        self.addCleanup(t.cleanup)
        self.repo = Path(t.name)
        self.git("init", "-qb", "main")
        self.git("config", "user.name", "Test Fixture")
        self.git("config", "user.email", "qa@example.invalid")
        self.old = self.commit({
          "Cargo.toml": '[package]\nname="synthetic-rust-daytag"\nversion="0.1.0"\nedition="2021"\n[lib]\nname="synthetic_rust_daytag"\n[dependencies]\nnum-bigint="0.4"\n',
          "src/lib.rs": 'use num_bigint::BigInt;\npub fn old_numeric_probe(day: &BigInt) -> BigInt { day + BigInt::from(7) }\n'})
        self.blob = self.git("rev-parse", self.old+":src/lib.rs")
        self.stage3 = self.commit({"README.md": "stage3\n"})
        self.stage4 = self.commit({"README.md": "stage4\n"})
        self.head = self.commit({"README.md": "head\n"})

    def git(self, *args):
        return subprocess.check_output(["git","-C",str(self.repo),*args],
                                       text=True, stderr=subprocess.DEVNULL, timeout=12).strip()

    def commit(self, files):
        for name, body in files.items():
            f = self.repo/name
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(body, encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "-qm", "synthetic")
        return self.git("rev-parse", "HEAD")

    def check(self, symbol="old_numeric_probe", commit=None, path="src/lib.rs", blob=None):
        return check_callability(self.repo, commit or self.old, path, blob or self.blob,
                                 self.stage3, self.stage4, self.head, symbol, timeout=180)

    def test_positive_executed_native_historical_function(self):
        if not shutil.which("cargo"):
            self.skipTest("cargo absent locally: CI runs native case")
        r = self.check()
        self.assertEqual(r["callability_status"], "EXECUTED_PINNED_RUST_PRODUCTION_FUNCTION")
        self.assertEqual(r["observed_outputs"], [-15055665,-15055664,-15055663])
        self.assertTrue(r["callable_numeric_function_verified"])
        self.assertFalse(r["callable_day_tag_route_verified"])
        self.assertFalse(r["observed_runtime_red"])
        self.assertEqual(r["stage04_closure"], "NOT_CLAIMED")

    def test_source_only_does_not_imply_callability(self):
        r = self.check(symbol="calendar_date_spaghetti")
        self.assertEqual(r["callability_status"], "SOURCE_ONLY_NO_SUPPORTED_SIGNATURE")
        self.assertFalse(r["callable_day_tag_route_verified"])
        self.assertFalse(r["callable_numeric_function_verified"])

    def test_wrong_and_private_signature(self):
        self.assertFalse(supported_signature("fn day(d: &BigInt)->BigInt { d.clone() }", "day"))
        self.assertFalse(supported_signature("pub fn day(d: i64)->i64 {d}", "day"))

    def test_module_path_is_pinned(self):
        self.assertEqual(validated_symbol("src/old.rs","old::day"),"old::day")
        with self.assertRaises(ProvenanceError):
            validated_symbol("src/old.rs","other::day")

    def test_injection_disallowed(self):
        with self.assertRaises(ProvenanceError):
            validated_symbol("src/lib.rs","fn; panic!()")

    def test_wrong_blob_rejected(self):
        with self.assertRaises(ProvenanceError):
            self.check(blob="a"*40)

    def test_post_stage4_rust_is_not_historical(self):
        rev = self.commit({"src/new.rs":"pub fn day(d: &BigInt) -> BigInt {d.clone()}\n"})
        blob = self.git("rev-parse", rev+":src/new.rs")
        with self.assertRaises(ProvenanceError):
            self.check(symbol="new::day", commit=rev, path="src/new.rs", blob=blob)

    def test_stale_head_is_rejected(self):
        self.git("checkout", "-q", "--detach", self.stage4)
        self.addCleanup(lambda:self.git("checkout","-q","main"))
        with self.assertRaises(ProvenanceError):
            self.check()

    def test_template_placeholders_preserve_rust_identifiers(self):
        # Regression: number placeholders must resolve before crate/symbol insertion.
        for tag in ("FM", "FF", "FP", "FM_FF_FP"):
            with self.subTest(tag=tag):
                symbol = "old_" + tag + "_probe"
                self.assertEqual(validated_symbol("src/lib.rs", symbol), symbol)
                body = test_body("crate_FM_FF_FP", symbol)
                self.assertIn("crate_FM_FF_FP::" + symbol + ";", body)
                for value in (-15055672, -15055671, -15055670):
                    self.assertIn("BigInt::from(" + str(value) + ")", body)

    def test_probe_binds_original_function_type(self):
        s = test_body("synthetic_rust_daytag", "old_numeric_probe")
        self.assertIn("let old: fn(&BigInt) -> BigInt = synthetic_rust_daytag::old_numeric_probe;", s)

if __name__ == "__main__":
    unittest.main()
