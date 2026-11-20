import hashlib
import pathlib
import unittest

from chunked_fx_probe import ASSERT_HELPER, build_chunked
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
MARKER = r"D:\a\_temp\chunked_fx_15.txt"

class ChunkedFxTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.locked = load_locked_sources(ROOT)

    def test_fifteen_lock_and_three_stages(self):
        candidate, receipt = build_chunked(BASE, ROOT, MARKER, count=15)
        self.assertEqual(receipt["source_commit"], SOURCE_COMMIT)
        self.assertEqual(receipt["stage01"], "NOT_RUN")
        self.assertFalse(receipt["native_executed"])
        self.assertEqual(receipt["names"], [b["name"] for b in self.locked["blocks"][:15]])
        self.assertEqual(receipt["chunk_count"], 3)
        self.assertEqual([x["after"] for x in receipt["stages"]], [5, 10, 15])
        self.assertEqual(receipt["candidate_sha256"], hashlib.sha256(candidate).hexdigest())
        self.assertEqual(receipt["marker_path"], MARKER)
        self.assertIn("Stage01ChunkAssert", " ".join(ASSERT_HELPER))

    def test_twenty_lock_and_four_stages(self):
        candidate, receipt = build_chunked(BASE, ROOT, MARKER, count=20)
        self.assertEqual(receipt["chunk_count"], 4)
        self.assertEqual([x["after"] for x in receipt["stages"]], [5, 10, 15, 20])
        self.assertEqual(receipt["names"], [b["name"] for b in self.locked["blocks"][:20]])
        self.assertTrue(all(s["inner_chars"] > 0 for s in receipt["stages"]))
        self.assertEqual(receipt["candidate_sha256"], hashlib.sha256(candidate).hexdigest())

    def test_outer_has_independent_ec_expressions_and_count_guards(self):
        candidate, receipt = build_chunked(BASE, ROOT, MARKER, count=15)
        line = next(l for l in candidate.decode("cp1252").splitlines() if l.startswith(":4=V C "))
        payload = line.split("'", 2)[1].replace("{quad}", "⎕")
        self.assertEqual(payload.count("⎕EC ⎕UCS "), 4)
        programs = []
        for fragment in payload.split(" ⋄ "):
            self.assertTrue(fragment.startswith("⎕EC ⎕UCS "))
            programs.append("".join(chr(int(n)) for n in fragment[len("⎕EC ⎕UCS "):].split()))
        for idx, n in enumerate((5, 10, 15)):
            self.assertEqual(programs[idx].count(" Stage01PrefixFix "), 5)
            self.assertIn(f"{n} Stage01ChunkAssert 0", programs[idx])
            self.assertIn("⎕NAPPEND", programs[idx])
        self.assertEqual(programs[-1].count(" Stage01PrefixFix "), 0)
        self.assertIn("15 Stage01ChunkAssert 0", programs[-1])
        self.assertIn("⎕NAPPEND", programs[-1])
        self.assertEqual(receipt["outer_lx_chars"], len(payload))

    def test_native_markers_are_independent_and_byte_locked(self):
        _, r = build_chunked(BASE, ROOT, MARKER, count=20)
        self.assertEqual(len({p["marker_path"] for p in r["stages"]}), 4)
        self.assertNotIn(r["marker_path"], [p["marker_path"] for p in r["stages"]])
        for p in r["stages"]:
            token = p["token"].encode("ascii")
            self.assertEqual(p["token_sha256"], hashlib.sha256(token).hexdigest())
            self.assertEqual(p["expected_bytes"], len(token))
            self.assertIn("SOURCE=" + SOURCE_COMMIT, p["token"])

    def test_rejects_invalid_sizes(self):
        for count in (0, 1, 14, 16, 19, 21, 95):
            with self.subTest(count=count):
                with self.assertRaisesRegex(ValueError, "CHUNK_COUNT_OR_SIZE_NOT_ALLOWED"):
                    build_chunked(BASE, ROOT, MARKER, count=count)
        with self.assertRaisesRegex(ValueError, "CHUNK_COUNT_OR_SIZE_NOT_ALLOWED"):
            build_chunked(BASE, ROOT, MARKER, count=15, chunk_size=6)

    def test_reproducible_and_crlf_stable(self):
        a, ra = build_chunked(BASE, ROOT, MARKER, count=15)
        b, rb = build_chunked(BASE, ROOT, MARKER, count=15)
        self.assertEqual(a, b)
        self.assertEqual(ra, rb)
        c, _ = build_chunked(BASE.replace(b"\n", b"\r\n"), ROOT, MARKER, count=15)
        self.assertNotIn(b"\n", c.replace(b"\r\n", b""))

if __name__ == "__main__":
    unittest.main()
