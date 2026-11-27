import hashlib
import pathlib
import unittest

from stage01_authorized_import import (
    CHUNK_SIZE, TAIL_START, TAIL_CHUNK_SIZE, EXPECTED_CHUNK_BOUNDARIES,
    STAGE01_MARKER, build_stage01_chunked,
)
from stage01_authorized_source import (
    EXPECTED_TOTAL_FUNCTIONS, SOURCE_COMMIT, load_locked_sources,
)

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
MARKER = r"D:\a\_temp\stage01_chunked_native.txt"


class Stage01ChunkedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.locked = load_locked_sources(ROOT)

    @classmethod
    def decode(cls, candidate):
        line = next(s for s in candidate.decode("cp1252").splitlines() if s.startswith(":4=V C "))
        serialized = line.split("'", 2)[1]
        selfcheck = serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕")
        fragments = selfcheck.split(" ⋄ ")
        result = []
        for fragment in fragments:
            fragment = fragment.removeprefix("QAS01FinalEC←")
            if not fragment.startswith("⎕EC ⎕UCS "):
                raise AssertionError("OUTER_FRAGMENT_MISSING_EC")
            result.append("".join(chr(int(n)) for n in fragment[len("⎕EC ⎕UCS "):].split()))
        return serialized, selfcheck, result

    def test_five_files_and_all_95_unique_source_locked_functions(self):
        candidate, receipt = build_stage01_chunked(BASE, ROOT, MARKER)
        self.assertEqual(receipt["source_commit"], SOURCE_COMMIT)
        self.assertEqual(receipt["source_file_count"], 5)
        self.assertEqual(receipt["source_manifest_sha256"], self.locked["manifest"]["manifest_sha256"])
        self.assertEqual(receipt["function_count"], EXPECTED_TOTAL_FUNCTIONS)
        self.assertEqual(receipt["unique_function_count"], EXPECTED_TOTAL_FUNCTIONS)
        self.assertEqual(receipt["function_names"], [b["name"] for b in self.locked["blocks"]])
        self.assertEqual(receipt["chunk_size"], CHUNK_SIZE)
        self.assertEqual(receipt["chunk_count"], 23)
        self.assertEqual(receipt["tail_start"], 90)
        self.assertEqual(receipt["tail_chunk_size"], 1)
        self.assertEqual(receipt["chunk_boundaries"], list(EXPECTED_CHUNK_BOUNDARIES))
        self.assertEqual([x["after"] for x in receipt["chunk_records"]], list(EXPECTED_CHUNK_BOUNDARIES))
        self.assertEqual([x["fx_in_chunk"] for x in receipt["chunk_records"]], [5] * 18 + [1] * 5)
        self.assertLess(receipt["max_chunk_inner_chars"], 65000)
        self.assertEqual(receipt["candidate_sha256"], hashlib.sha256(candidate).hexdigest())
        self.assertFalse(receipt["native_executed"])
        self.assertEqual(receipt["stage01"], "NOT_ACCEPTED")
        self.assertEqual(receipt["status"], "GENERATED_NOT_NATIVE_VALIDATED")

    def test_exact_native_marker_after_original_stage01_test_in_same_ec(self):
        candidate, receipt = build_stage01_chunked(BASE, ROOT, MARKER)
        self.assertEqual(receipt["marker_token"], "APL_GERMAN_STAGE01_NATIVE_PASS_V1|SOURCE="
                         + SOURCE_COMMIT + "|FILES=5|FX=95|TEST=STAGE01_PASS")
        self.assertEqual(receipt["marker_token"], STAGE01_MARKER)
        self.assertEqual(receipt["test_entrypoint"], "RunStage01Tests")
        self.assertEqual(receipt["final_expression"], "SAME_EC_AFTER_TEST")
        _, outer, programs = self.decode(candidate)
        self.assertEqual(len(programs), 25)
        self.assertEqual(outer.count("⎕EC ⎕UCS "), 25)
        self.assertEqual(outer.count("QAS01FinalEC←"), 1)
        final = programs[-2]
        self.assertEqual(final.count("RunStage01Tests"), 1)
        self.assertEqual(final.count("⎕NAPPEND"), 2)
        self.assertTrue(final.startswith("95 Stage01ChunkAssert 0 ⋄ "))
        self.assertLess(final.index("⎕NAPPEND"), final.index("RunStage01Tests"))
        self.assertLess(final.index("RunStage01Tests"), final.rindex("⎕NAPPEND"))
        self.assertIn("QAS01FinalEC[1]", programs[-1])
        self.assertIn("QAS01FinalEC[2]", programs[-1])
        self.assertIn("QAS01FinalEC[3]", programs[-1])
        self.assertEqual(len(STAGE01_MARKER.encode("ascii")), 113)
        self.assertEqual(receipt["final_inner_sha256"], hashlib.sha256(final.encode("utf-8")).hexdigest())
        self.assertEqual(sum(program.count(" Stage01PrefixFix ") for program in programs), 95)
        self.assertEqual(programs[-1].count(" Stage01PrefixFix "), 0)

    def test_every_chunk_has_source_count_and_separate_exact_receipt(self):
        candidate, receipt = build_stage01_chunked(BASE, ROOT, MARKER)
        _, _, programs = self.decode(candidate)
        for index, record in enumerate(receipt["chunk_records"]):
            n = EXPECTED_CHUNK_BOUNDARIES[index]
            previous = EXPECTED_CHUNK_BOUNDARIES[index - 1] if index else 0
            fx_count = n - previous
            with self.subTest(after=n):
                self.assertEqual(record["after"], n)
                self.assertEqual(record["name"], receipt["function_names"][n - 1])
                self.assertEqual(record["token_sha256"], hashlib.sha256(record["token"].encode("ascii")).hexdigest())
                self.assertEqual(record["expected_bytes"], len(record["token"].encode("ascii")))
                self.assertIn("SOURCE=" + SOURCE_COMMIT, record["token"])
                self.assertTrue(record["marker_path"].endswith("_after_" + f"{n:02d}" + ".txt"))
                self.assertEqual(record["inner_sha256"], hashlib.sha256(programs[index].encode("utf-8")).hexdigest())
                self.assertEqual(record["fx_in_chunk"], fx_count)
                self.assertEqual(programs[index].count(" Stage01PrefixFix "), fx_count)
                self.assertIn(f"{n} Stage01ChunkAssert 0", programs[index])
                self.assertEqual(programs[index].count("⎕NAPPEND"), 1)
        self.assertNotIn(MARKER, [r["marker_path"] for r in receipt["chunk_records"]])

    def test_workspace_encoding_reversible_and_ascii_only(self):
        candidate, receipt = build_stage01_chunked(BASE, ROOT, MARKER)
        serialized, outer, _ = self.decode(candidate)
        self.assertTrue(serialized.isascii())
        self.assertNotIn("⋄", serialized)
        self.assertEqual(serialized.count("{diamond}"), 24)
        self.assertEqual(receipt["outer_lx_chars"], len(outer))
        self.assertEqual(receipt["outer_lx_sha256"], hashlib.sha256(outer.encode("utf-8")).hexdigest())
        self.assertIn("0=foo=:3", candidate.decode("cp1252"))
        self.assertNotIn(b"\r\n", candidate)

    def test_last_five_functions_each_have_isolated_native_checkpoint(self):
        candidate, receipt = build_stage01_chunked(BASE, ROOT, MARKER)
        _, _, programs = self.decode(candidate)
        last_five = [r["name"] for r in receipt["chunk_records"][-5:]]
        self.assertEqual(last_five, [
            "AssertTrue", "RunStage01OwnershipTests",
            "RunStage01OracleStateTests", "RunStage01YearTests",
            "RunStage01Tests",
        ])
        self.assertEqual([r["after"] for r in receipt["chunk_records"][-5:]], [91, 92, 93, 94, 95])
        for idx in range(18, 23):
            self.assertEqual(programs[idx].count(" Stage01PrefixFix "), 1)
            self.assertEqual(programs[idx].count("⎕NAPPEND"), 1)
        self.assertTrue(all(len(p) < 65000 for p in programs))

    def test_reproducible_and_original_line_endings_preserved(self):
        a, ra = build_stage01_chunked(BASE, ROOT, MARKER)
        b, rb = build_stage01_chunked(BASE, ROOT, MARKER)
        self.assertEqual(a, b)
        self.assertEqual(ra, rb)
        c, _ = build_stage01_chunked(BASE.replace(b"\n", b"\r\n"), ROOT, MARKER)
        self.assertNotIn(b"\n", c.replace(b"\r\n", b""))


if __name__ == "__main__":
    unittest.main()
