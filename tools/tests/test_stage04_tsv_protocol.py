"""Stage04 TSV protocol regression tests; only the verifier's input contract is tested."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from stage04_cross_runtime_diff import load_rust_rows


class TestStage04TsvProtocol(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / "rust.tsv"
        self.lines = ["index\tday\toracle\tcandidate"]
        self.lines.extend(f"{i}\t{i}\t1\t1" for i in range(15))

    def load(self):
        self.path.write_text("\n".join(self.lines) + "\n", encoding="utf-8")
        return load_rust_rows(self.path)

    def test_valid_fifteen_row_protocol(self):
        self.assertEqual(len(self.load()), 15)

    def test_rejects_unlisted_fifth_data_field(self):
        self.lines[1] += "\tUNDECLARED"
        with self.assertRaises(ValueError):
            self.load()

    def test_rejects_missing_data_field(self):
        self.lines[1] = "0\t0\t1"
        with self.assertRaises(ValueError):
            self.load()

    def test_rejects_blank_data_field(self):
        self.lines[1] = "0\t0\t1\t"
        with self.assertRaises(ValueError):
            self.load()

    def test_rejects_extra_header_column(self):
        self.lines[0] += "\textra"
        with self.assertRaises(ValueError):
            self.load()

    def test_rejects_fourteen_rows(self):
        self.lines.pop()
        with self.assertRaises(ValueError):
            self.load()


if __name__ == "__main__":
    unittest.main()
