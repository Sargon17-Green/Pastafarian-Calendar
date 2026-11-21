"""Synthetic Git histories; no fixture is historical Rust RED."""
import io
import json
import shutil
import subprocess
from contextlib import redirect_stdout
from unittest.mock import patch
import sys
import tempfile
import tomllib
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import stage04_rust_witness_provenance as provenance
import stage04_rust_callability_eligibility as callability_cli
from stage04_rust_callability_eligibility import (
    RuntimeUnverified, check_callability, install_probe, supported_signature,
    validated_symbol, test_body)
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
        self.boundary_patch = patch.multiple(
            provenance, CANONICAL_STAGE3_CLOSURE=self.stage3,
            CANONICAL_STAGE4_INTRODUCTION=self.stage4)
        self.boundary_patch.start()
        self.addCleanup(self.boundary_patch.stop)

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

    def test_comment_and_literal_signature_spoof_rejected(self):
        fragments = [
            "// pub fn day(d: &BigInt) -> BigInt { d.clone() }\n",
            "/*\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n*/",
            "/* outer /*\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n*/ */",
            'const X: &str = r#"\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n"#;',
            "/* unterminated\npub fn day(d: &BigInt) -> BigInt { d.clone() }",
            # A legal 33-hash raw literal previously escaped the <=32-hash
            # filter and exposed a forged direct function declaration.
            'const S: &str = r' + '#' * 33
                + '""\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n""'
                + '#' * 33 + ';',
            'const S: &std::ffi::CStr = cr#" "'
                + '\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n" "#;',
        ]
        for source in fragments:
            with self.subTest(source=source[:35]):
                self.assertFalse(supported_signature(source, "day"))

    def test_reexport_and_nested_module_cannot_spoof_direct_witness(self):
        # Old regex accepted these signatures despite no direct file-scope
        # Rust function; a pub use alias would compile from a different file.
        source = (
            "use num_bigint::BigInt;\n"
            "mod actual {\n"
            "  use num_bigint::BigInt;\n"
            "  pub fn day(d: &BigInt) -> BigInt { d.clone() }\n"
            "}\n"
            "pub use actual::day;\n"
            "/*\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n*/"
        )
        self.assertFalse(supported_signature(source, "day"))
        self.assertFalse(supported_signature(
            "impl T {\npub fn day(d: &BigInt) -> BigInt { d.clone() }\n}", "day"))
        for attributes in (
            "#[cfg(any())]",
            "#[cfg(any())]\n#[inline]",
            "#![cfg(any())]",
            "#[inline]",
        ):
            with self.subTest(attributes=attributes):
                self.assertFalse(supported_signature(
                    attributes + "\npub fn day(d: &BigInt) -> BigInt { d.clone() }", "day"))
        self.assertFalse(supported_signature(
            "macro_rules! synth { () => { pub fn day(d: &BigInt) -> BigInt { d.clone() } } }",
            "day"))

    def test_real_top_level_definition_remains_eligible(self):
        self.assertTrue(supported_signature(
            'const S: &str = "/* not a comment */";\n'
            "pub /* comment */ fn day(d: &BigInt) -> BigInt { d.clone() }\n",
            "day"))
        self.assertFalse(supported_signature(
            "trait T {\npub fn day(d: &BigInt) -> BigInt;\n}", "day"))

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

    def test_placeholder_words_preserve_literal_rust_identifiers(self):
        # Original bug: crate_SYMBOL was rewritten by the second .replace().
        for crate in ("crate_SYMBOL", "CRATE_SYMBOL_FM_FF_FP", "normal_crate"):
            for symbol in ("old_CRATE_probe", "old_SYMBOL_probe", "old_FM_FF_FP_probe"):
                with self.subTest(crate=crate, symbol=symbol):
                    self.assertEqual(validated_symbol("src/lib.rs", symbol), symbol)
                    body = test_body(crate, symbol)
                    self.assertIn(
                        f"let old: fn(&BigInt) -> BigInt = {crate}::{symbol};",
                        body,
                    )
                    for value in (-15055672, -15055671, -15055670):
                        self.assertIn(f"BigInt::from({value})", body)

    def test_reserved_probe_and_original_archive_tree_are_preserved(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            probe = root / "tests" / "stage04_callability_gate.rs"
            probe.parent.mkdir()
            sentinel = "// PINNED_HISTORICAL_TEST_SENTINEL\\n"
            probe.write_text(sentinel, encoding="utf-8")
            with self.assertRaises(RuntimeUnverified):
                install_probe(root, "synthetic_rust_daytag", "old_numeric_probe")
            self.assertEqual(probe.read_text(encoding="utf-8"), sentinel)

        # A normal Git archive must reproduce all pinned tree members byte for
        # byte, even before the one-use test probe is installed.
        with tempfile.TemporaryDirectory() as temp:
            callability_cli.archive(self.repo, self.old, Path(temp))
            self.assertTrue((Path(temp) / "src/lib.rs").is_file())

        # git archive applies .gitattributes transformations. A successful
        # Cargo build from modified export bytes is not pinned historical code.
        changed = self.commit({
            ".gitattributes": "src/lib.rs export-subst\n",
            "src/lib.rs": 'const PIN: &str = "$Format:%H$";\n',
        })
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(RuntimeUnverified, "archived file bytes"):
                callability_cli.archive(self.repo, changed, Path(temp))

        changed = self.commit({
            ".gitattributes": "evidence.txt export-ignore\n",
            "evidence.txt": "historical tree member\n",
        })
        with tempfile.TemporaryDirectory() as temp:
            with self.assertRaisesRegex(RuntimeUnverified, "tree membership"):
                callability_cli.archive(self.repo, changed, Path(temp))

    def test_exclusive_probe_creation_is_one_use(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            probe = install_probe(root, "synthetic_rust_daytag", "old_numeric_probe")
            self.assertEqual(
                probe.read_text(encoding="utf-8"),
                test_body("synthetic_rust_daytag", "old_numeric_probe"),
            )
            before = probe.read_bytes()
            with self.assertRaises(RuntimeUnverified):
                install_probe(root, "synthetic_rust_daytag", "old_numeric_probe")
            self.assertEqual(probe.read_bytes(), before)

    def test_probe_binds_original_function_type(self):
        s = test_body("synthetic_rust_daytag", "old_numeric_probe")
        self.assertIn("let old: fn(&BigInt) -> BigInt = synthetic_rust_daytag::old_numeric_probe;", s)

    def assert_unavailable_subprocess_is_structured(self, error):
        # No Git/Cargo execution: inject the OS fault at the CLI boundary.
        args = ["stage04_rust_callability_eligibility.py"]
        for key, value in (
            ("witness-commit", "a"*40),
            ("witness-path", "src/lib.rs"),
            ("witness-blob", "b"*40),
            ("stage3-closure", "c"*40),
            ("stage4-introduction", "d"*40),
            ("branch-head", "e"*40),
            ("symbol", "old_numeric_probe"),
        ):
            args.extend(["--" + key, value])
        output = io.StringIO()
        with patch.object(callability_cli, "check_callability", side_effect=error):
            with patch.object(sys, "argv", args), redirect_stdout(output):
                status = callability_cli.main()
        payload = json.loads(output.getvalue())
        self.assertEqual(status, 3)
        self.assertEqual(payload["callability_status"], "RUNTIME_UNVERIFIED")
        self.assertFalse(payload["source_pin_eligible"])
        self.assertFalse(payload["observed_runtime_red"])
        self.assertFalse(payload["callable_day_tag_route_verified"])
        self.assertEqual(payload["stage04_closure"], "NOT_CLAIMED")
        self.assertIn(type(error).__name__, payload["reason"])

    def test_git_timeout_emits_bounded_json_not_traceback(self):
        self.assert_unavailable_subprocess_is_structured(
            subprocess.TimeoutExpired(["git", "merge-base"], 12))

    def test_missing_git_executable_emits_bounded_json_not_traceback(self):
        self.assert_unavailable_subprocess_is_structured(
            OSError("git executable unavailable"))


    def test_malformed_cargo_metadata_fails_closed_as_json(self):
        # Valid TOML syntax can still contain invalid Cargo metadata types.
        cases = (
            ("lib-string", 'lib = "bad"\n[package]\nname = "fixture"\n'),
            ("package-string", 'package = "bad"\n'),
            ("package-name-integer", '[package]\nname = 12\n'),
        )
        args = ["stage04_rust_callability_eligibility.py",
                "--repo", str(self.repo),
                "--witness-commit", self.old,
                "--witness-path", "src/lib.rs",
                "--witness-blob", self.blob,
                "--stage3-closure", self.stage3,
                "--stage4-introduction", self.stage4,
                "--branch-head", self.head,
                "--symbol", "old_numeric_probe"]
        for label, manifest_text in cases:
            with self.subTest(case=label):
                # Valid TOML is required: malformed metadata, not invalid syntax.
                self.assertIsInstance(tomllib.loads(manifest_text), dict)
                def fake_archive(_repo, _commit, dest):
                    (dest / "Cargo.toml").write_text(manifest_text, encoding="utf-8")
                output = io.StringIO()
                with patch.object(callability_cli, "archive", side_effect=fake_archive):
                    with patch.object(sys, "argv", args), redirect_stdout(output):
                        status = callability_cli.main()
                payload = json.loads(output.getvalue())
                self.assertEqual(status, 3)
                self.assertEqual(payload["callability_status"], "RUNTIME_UNVERIFIED")
                self.assertTrue(payload["source_pin_eligible"])
                self.assertFalse(payload["callable_numeric_function_verified"])
                self.assertFalse(payload["callable_day_tag_route_verified"])
                self.assertFalse(payload["observed_runtime_red"])
                self.assertEqual(payload["stage04_closure"], "NOT_CLAIMED")

if __name__ == "__main__":
    unittest.main()
