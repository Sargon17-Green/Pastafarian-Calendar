import hashlib
import pathlib
import unittest

from progress_fx_probe import CHECKPOINTS, COUNT, create_progress
from stage01_import_workspace import SOURCE_COMMIT, load_locked_sources

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = """[General]
Version=1
[Globals]
:0=V C 0 1 0 ''
:3=V C 0 1 0 ''
[Vars.0]
5={quad}lx=:3
[Fcns.0]
0=foo=:3
""".encode("cp1252")
MARKER = r"D:\a\_temp\apl_german_progress_20.txt"


class NativeProgressCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.locked = load_locked_sources(ROOT)

    def test_checkpoints_and_source_order_are_exact(self):
        candidate, receipt = create_progress(BASE, MARKER, ROOT)
        self.assertEqual(receipt["stage01"], "NOT_RUN")
        self.assertFalse(receipt["native_executed"])
        self.assertEqual(receipt["source_commit"], SOURCE_COMMIT)
        self.assertEqual(receipt["count"], COUNT)
        self.assertEqual(receipt["names"], [b["name"] for b in self.locked["blocks"][:COUNT]])
        self.assertEqual(receipt["candidate_sha256"], hashlib.sha256(candidate).hexdigest())
        self.assertEqual([p["after"] for p in receipt["checkpoints"]], list(CHECKPOINTS))
        self.assertEqual(len(set(p["path"] for p in receipt["checkpoints"])), len(CHECKPOINTS))
        self.assertIn(b"{quad}EC {quad}UCS", candidate)
        self.assertTrue(all(p["path"] != MARKER for p in receipt["checkpoints"]))
        for p in receipt["checkpoints"]:
            self.assertEqual(p["expected_bytes"], len(p["token"].encode("ascii")))
            self.assertEqual(p["token_sha256"], hashlib.sha256(p["token"].encode("ascii")).hexdigest())
            self.assertEqual(p["name"], "START" if p["after"] == 0 else receipt["names"][p["after"] - 1])

    def test_progress_expressions_are_ordered_and_final_receipt_is_last(self):
        candidate, receipt = create_progress(BASE, MARKER, ROOT)
        inserted = next(s for s in candidate.decode("cp1252").splitlines()
                        if s.startswith(":4=V C "))
        payload = inserted.split("'", 2)[1].replace("{quad}", "⎕")
        prefix = "⎕EC ⎕UCS "
        self.assertTrue(payload.startswith(prefix))
        inner = "".join(chr(int(n)) for n in payload[len(prefix):].split())
        checkpoints = receipt["checkpoints"]
        positions = []
        for p in checkpoints:
            encoded = "⎕UCS " + " ".join(str(ord(ch)) for ch in p["token"])
            positions.append(inner.index(encoded))
        self.assertEqual(positions, sorted(positions))
        self.assertLess(positions[-1], inner.index("⎕UCS " + " ".join(
            str(ord(ch)) for ch in receipt["marker_token"])))
        self.assertEqual(inner.count(" Stage01PrefixFix "), COUNT)
        self.assertIn("⎕FX ", inner)

    def test_small_canary_has_first_marker_and_no_fx(self):
        c, r = create_progress(BASE, MARKER, ROOT, mode="canary_only")
        self.assertEqual(r["mode"], "canary_only")
        self.assertEqual(r["fx_count"], 0)
        self.assertEqual([point["after"] for point in r["checkpoints"]], [0])
        self.assertEqual(r["checkpoints"][0]["name"], "START")
        self.assertIn("TRACE_CANARY_V1", r["marker_token"])
        self.assertEqual(r["candidate_sha256"], hashlib.sha256(c).hexdigest())

    def test_start_only_has_twenty_fx_and_initial_marker(self):
        c, r = create_progress(BASE, MARKER, ROOT, mode="start_only")
        self.assertEqual(r["mode"], "start_only")
        self.assertEqual(r["fx_count"], 20)
        self.assertEqual([p["after"] for p in r["checkpoints"]], [0])
        payload = next(s for s in c.decode("cp1252").splitlines() if s.startswith(":4=V C ")).split("'", 2)[1].replace("{quad}", "⎕")
        prefix = "⎕EC ⎕UCS "
        self.assertTrue(payload.startswith(prefix))
        inner = "".join(chr(int(n)) for n in payload[len(prefix):].split())
        self.assertEqual(inner.count(" Stage01PrefixFix "), 20)
        self.assertLess(inner.index("⎕NAPPEND"), inner.index("⎕FX"))
        self.assertEqual(r["candidate_sha256"], hashlib.sha256(c).hexdigest())

    def test_padded_canary_is_length_matched_without_any_fx(self):
        c, receipt = create_progress(BASE, MARKER, ROOT, mode="padded_canary")
        self.assertEqual(receipt["mode"], "padded_canary")
        self.assertEqual(receipt["fx_count"], 0)
        self.assertEqual([row["after"] for row in receipt["checkpoints"]], [0])
        self.assertTrue(abs(receipt["outer_lx_chars"] - 95883) < 10)
        self.assertEqual(receipt["candidate_sha256"], hashlib.sha256(c).hexdigest())
        expression = next(s for s in c.decode("cp1252").splitlines() if s.startswith(":4=V C ")).split("'", 2)[1].replace("{quad}", "⎕")
        self.assertTrue(expression.startswith("⎕EC ⎕UCS "))
        inner = "".join(chr(int(x)) for x in expression[len("⎕EC ⎕UCS "):].split())
        self.assertIn("Stage01PadCount←⍴⎕UCS 65", inner)
        self.assertNotIn("⎕FX", inner)
        self.assertNotIn("Stage01PrefixFix", inner)
        self.assertEqual(inner.count("⎕NAPPEND"), 2)

    def test_invalid_mode_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "INVALID_PROGRESS_MODE"):
            create_progress(BASE, MARKER, ROOT, mode="typo")
        self.assertNotEqual(
            create_progress(BASE, MARKER, ROOT, mode="full")[0],
            create_progress(BASE, MARKER, ROOT, mode="start_only")[0],
        )

    def test_crlf_preserved_and_manifest_reproducible(self):
        a, ra = create_progress(BASE, MARKER, ROOT)
        b, rb = create_progress(BASE, MARKER, ROOT)
        self.assertEqual(a, b)
        self.assertEqual(ra, rb)
        c, _ = create_progress(BASE.replace(b"\n", b"\r\n"), MARKER, ROOT)
        self.assertNotIn(b"\n", c.replace(b"\r\n", b""))


if __name__ == "__main__":
    unittest.main()
