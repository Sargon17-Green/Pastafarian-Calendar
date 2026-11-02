#!/usr/bin/env python3
"""Read-only provenance gate for the ORIGINAL FALSE+العربية Stage 2 delta.

Does NOT reconstruct Stage 2, extract files, modify the repository, run FALSE,
or establish Stage 2 PASS. Requires Python 3.9+ and the original ZIP.
"""
import argparse
import hashlib
import io
import json
from pathlib import PurePosixPath, Path
import stat
import sys
import unittest
import zipfile

PROJECT_ID = "PC-BRANCH-FALSE-ARABIC"
ARCHIVE_NAME = "FALSE_Arabic_Stage02_DISCOVERY01_UPLOAD_DELTA.zip"
EXPECTED_SHA256 = "6148142e82fd3a90817e2c46b55381f1ba66612abf6ed822ffc5288d24ca56b2"
BASELINE_HEAD = "4d0b099939892144db0677ec33a77efb3fa8865a"
REQUIRED = (
    "src/monster_bootstrap.false",
    "test/stage02_discovery01_tests.false",
    "DEVELOPMENT_STAGE.md",
    "SPAGHETTI_DEVELOPMENT_HISTORY.md",
    "README.md",
    "RUN_STAGE02.md",
    "STAGE_02_EXECUTION_STATUS.txt",
)
MAX_FILE_BYTES = 128 * 1024 * 1024
MAX_TOTAL_BYTES = 512 * 1024 * 1024


class GateError(Exception):
    """The candidate is not proved to be the recorded source archive."""


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def clean_name(info):
    name = info.filename
    if (not name or name.startswith("/") or "\\" in name or ":" in name
            or any(part in ("", ".", "..") for part in name.rstrip("/").split("/"))):
        raise GateError(f"Unsafe ZIP member path: {name!r}")
    if stat.S_IFMT(info.external_attr >> 16) == stat.S_IFLNK:
        raise GateError(f"Symlink forbidden: {name!r}")
    return name.rstrip("/")


def inspect_archive(data, expected_sha=EXPECTED_SHA256):
    actual = sha256(data)
    if actual.lower() != expected_sha.lower():
        raise GateError(f"SHA256 mismatch: observed={actual}; expected={expected_sha}")
    try:
        with zipfile.ZipFile(io.BytesIO(data), "r") as zf:
            files = []
            dirs = []
            for info in zf.infolist():
                name = clean_name(info)
                if info.is_dir():
                    dirs.append(name)
                    continue
                if info.flag_bits & 1:
                    raise GateError(f"Encrypted ZIP member: {name}")
                if info.file_size > MAX_FILE_BYTES:
                    raise GateError(f"ZIP member exceeds {MAX_FILE_BYTES} bytes: {name}")
                files.append((name, info))
            if len(files) != len(REQUIRED):
                raise GateError(f"Expected {len(REQUIRED)} files, found {len(files)}")
            required = set(REQUIRED)
            names = [n for n, _ in files]
            # Only the exact paths or those under one common top-level folder.
            prefixes = [""]
            if names and "/" in names[0]:
                prefixes.append(names[0].split("/", 1)[0] + "/")
            prefix = next((p for p in prefixes if set(n[len(p):] for n in names
                          if n.startswith(p)) == required and
                          all(n.startswith(p) for n in names)), None)
            if prefix is None:
                raise GateError("ZIP member names differ from the 7 recorded paths")
            normalized = [n[len(prefix):] for n in names]
            if len(set(normalized)) != len(REQUIRED):
                raise GateError("Duplicate ZIP member names")
            # Directory entries must be parents of a recorded file.
            allowed_dirs = set()
            for n in names:
                path = PurePosixPath(n)
                for parent in path.parents:
                    if str(parent) != ".":
                        allowed_dirs.add(str(parent))
            if any(d not in allowed_dirs for d in dirs):
                raise GateError("Unrelated ZIP directory present")
            total = sum(info.file_size for _, info in files)
            if total > MAX_TOTAL_BYTES:
                raise GateError(f"Uncompressed archive exceeds {MAX_TOTAL_BYTES} bytes")
            manifest = []
            for original, info in files:
                with zf.open(info) as stream:
                    h = hashlib.sha256()
                    consumed = 0
                    while True:
                        chunk = stream.read(1024 * 1024)
                        if not chunk:
                            break
                        consumed += len(chunk)
                        if consumed > MAX_FILE_BYTES:
                            raise GateError(f"Unexpected oversized content: {original}")
                        h.update(chunk)
                if consumed != info.file_size:
                    raise GateError(f"ZIP length mismatch: {original}")
                manifest.append({"path": original[len(prefix):], "bytes": consumed,
                                 "sha256": h.hexdigest()})
    except (zipfile.BadZipFile, RuntimeError, EOFError, ValueError, OSError) as exc:
        raise GateError(f"ZIP could not be validated: {exc}") from exc
    return {"project_id": PROJECT_ID, "original_archive": ARCHIVE_NAME,
            "sha256": actual, "baseline_head_for_future_diff": BASELINE_HEAD,
            "wrapper": prefix.rstrip("/"), "file_count": len(manifest),
            "status": "ARCHIVE_PROVENANCE_VERIFIED_ONLY_NOT_STAGE2_PASS",
            "files": sorted(manifest, key=lambda x: x["path"])}


class GateTests(unittest.TestCase):
    @staticmethod
    def candidate(paths=REQUIRED, wrapper="", directory=None, symlink=None):
        mem = io.BytesIO()
        with zipfile.ZipFile(mem, "w", compression=zipfile.ZIP_DEFLATED) as z:
            if directory:
                z.writestr(directory.rstrip("/") + "/", b"")
            for path in paths:
                info = zipfile.ZipInfo(wrapper + path)
                if symlink == path:
                    info.create_system = 3
                    info.external_attr = (stat.S_IFLNK | 0o777) << 16
                z.writestr(info, b"fixture:" + path.encode("utf-8"))
        return mem.getvalue()

    def verify_fixture(self, data):
        return inspect_archive(data, sha256(data))

    def test_exact_members(self):
        self.assertEqual(self.verify_fixture(self.candidate())["file_count"], 7)

    def test_one_wrapper(self):
        self.assertEqual(self.verify_fixture(self.candidate(wrapper="stage2/"))["wrapper"], "stage2")

    def test_wrong_hash_rejected(self):
        with self.assertRaisesRegex(GateError, "SHA256 mismatch"):
            inspect_archive(self.candidate(), "0" * 64)

    def test_missing_member(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(paths=REQUIRED[:-1]))

    def test_extra_member(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(paths=REQUIRED + ("extra.txt",)))

    def test_duplicate_member(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(paths=REQUIRED + (REQUIRED[0],)))

    def test_traversal_rejected(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(paths=("../README.md",) + REQUIRED[1:]))

    def test_symlink_rejected(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(symlink="README.md"))

    def test_unrelated_folder_rejected(self):
        with self.assertRaises(GateError):
            self.verify_fixture(self.candidate(directory="random"))

    def test_corrupt_zip_rejected(self):
        with self.assertRaises(GateError):
            self.verify_fixture(b"not a zip")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", nargs="?", type=Path, help="original Stage 2 ZIP")
    parser.add_argument("--self-test", action="store_true", help="run synthetic gate unit tests")
    parser.add_argument("--report", type=Path, help="write JSON evidence (no extraction)")
    args = parser.parse_args(argv)
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(GateTests)
        return 0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1
    if args.archive is None:
        parser.error("provide the original ZIP or --self-test")
    try:
        if args.archive.name != ARCHIVE_NAME:
            raise GateError(f"Archive filename differs from the recorded name: {args.archive.name}")
        result = inspect_archive(args.archive.read_bytes())
        output = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
        if args.report:
            args.report.write_text(output, encoding="utf-8")
        print(output, end="")
        return 0
    except (GateError, OSError) as exc:
        print(f"GATE FAIL: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
