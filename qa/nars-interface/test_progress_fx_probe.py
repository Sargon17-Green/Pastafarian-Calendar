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

    def test_crlf_preserved_and_manifest_reproducible(self):
        a, ra = create_progress(BASE, MARKER, ROOT)
        b, rb = create_progress(BASE, MARKER, ROOT)
        self.assertEqual(a, b)
        self.assertEqual(ra, rb)
        c, _ = create_progress(BASE.replace(b"\n", b"\r\n"), MARKER, ROOT)
        self.assertNotIn(b"\n", c.replace(b"\r\n", b""))


if __name__ == "__main__":
    unittest.main()
