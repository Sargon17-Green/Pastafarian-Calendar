#!/usr/bin/env python3
"""Stage56 B5: verify an exact-SHA PHP Native preflight evidence ZIP.

This only authenticates bytes against an OUT-OF-BAND pinned ZIP SHA-256.
It never attests the Year5000 anchor, production provider or actual-year profiling.
"""
from __future__ import annotations

import hashlib
import io
import pathlib
import re
import sys
import tempfile
import zipfile

PROJECT = b"PC-BRANCH-PHP-MALAY\n"
FILES = frozenset({
    "PROJECT_ID.txt", "SHA.txt", "php-version.txt", "exit.txt",
    "lint-profiler.txt", "lint-preflight.txt", "lint-cli.txt",
    "stdout.txt", "stderr.txt", "cli-stdout.txt", "cli-stderr.txt",
})
OUT_PREFLIGHT = b"STAGE56_B5_PREFLIGHT checks=16 synthetic_structure_only=YES provenance=NOT_VERIFIED status=PASS\n"
OUT_CLI = b"STAGE56_B5_CLI_NEGATIVE checks=12 real_year_profiles=0 provenance=NOT_VERIFIED status=PASS\n"
EXITS = b"lint_profiler=0\nlint_preflight=0\nlint_cli=0\nexit=0\ncli_exit=0\n"
LINT = {
    "lint-profiler.txt": b"No syntax errors detected in tests/stage56_actual_year_profile.php\n",
    "lint-preflight.txt": b"No syntax errors detected in tests/stage56_actual_year_profile_preflight_tests.php\n",
    "lint-cli.txt": b"No syntax errors detected in tests/stage56_actual_year_profile_cli_contract_tests.php\n",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def verify(data: bytes, source_sha: str, zip_sha: str) -> None:
    if re.fullmatch(r"[a-f0-9]{40}", source_sha) is None or re.fullmatch(r"[a-f0-9]{64}", zip_sha) is None:
        raise ValueError("PIN_FORMAT")
    if sha256(data) != zip_sha:
        raise ValueError("ZIP_SHA_MISMATCH")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        infos = archive.infolist()
        names = [i.filename for i in infos]
        if len(names) != len(FILES) or set(names) != FILES:
            raise ValueError("MEMBER_SET_OR_DUPLICATE")
        if any(i.file_size > 4096 or i.is_dir() for i in infos):
            raise ValueError("MEMBER_SIZE_OR_DIR")
        if archive.testzip() is not None:
            raise ValueError("ZIP_CRC")
        parts = {name: archive.read(name) for name in FILES}
    if parts["PROJECT_ID.txt"] != PROJECT or parts["SHA.txt"] != (source_sha + "\n").encode():
        raise ValueError("SOURCE_IDENTITY")
    if not parts["php-version.txt"].startswith(b"PHP 8.3."):
        raise ValueError("NATIVE_PHP_VERSION")
    if parts["exit.txt"] != EXITS:
        raise ValueError("EXIT_VALUES")
    if parts["stdout.txt"] != OUT_PREFLIGHT or parts["cli-stdout.txt"] != OUT_CLI:
        raise ValueError("TEST_COUNTERS")
    if parts["stderr.txt"] or parts["cli-stderr.txt"]:
        raise ValueError("NONEMPTY_STDERR")
    for filename, expected in LINT.items():
        if parts[filename] != expected:
            raise ValueError("LINT_LOG:" + filename)


def make_zip(parts: dict[str, bytes]) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(parts):
            archive.writestr(name, parts[name])
    return buffer.getvalue()


def self_test() -> None:
    sha = "a" * 40
    sample = {
        "PROJECT_ID.txt": PROJECT, "SHA.txt": (sha + "\n").encode(),
        "php-version.txt": b"PHP 8.3.37 (cli) (NTS)\n",
        "exit.txt": EXITS, "stdout.txt": OUT_PREFLIGHT,
        "cli-stdout.txt": OUT_CLI, "stderr.txt": b"", "cli-stderr.txt": b"",
        **LINT,
    }
    good = make_zip(sample)
    verify(good, sha, sha256(good))
    checks = 1
    cases = [
        (sample, sha, "0" * 64),
        ({**sample, "SHA.txt": b"b" * 40 + b"\n"}, sha, None),
        ({**sample, "exit.txt": EXITS.replace(b"cli_exit=0", b"cli_exit=1")}, sha, None),
        ({**sample, "stderr.txt": b"error\n"}, sha, None),
        ({**sample, "stdout.txt": OUT_PREFLIGHT.replace(b"checks=16", b"checks=15")}, sha, None),
        ({**sample, "extra.txt": b"unexpected"}, sha, None),
        ({**sample, "php-version.txt": b"PHP 8.4.24 (cli)\n"}, sha, None),
        ({**sample, "lint-cli.txt": b"syntax failure\n"}, sha, None),
    ]
    for parts, expected_source, forced_digest in cases:
        payload = make_zip(parts)
        try:
            verify(payload, expected_source, forced_digest or sha256(payload))
        except ValueError:
            checks += 1
        else:
            raise AssertionError("NEGATIVE_CASE_ACCEPTED_" + str(checks))
    if checks != 9:
        raise AssertionError("TEST_COUNT")
    print("STAGE56_B5_AUDITOR_SELF_TEST checks=9 synthetic_only=YES status=PASS")


def main(argv: list[str]) -> int:
    try:
        if len(argv) == 2 and argv[1] == "--self-test":
            self_test()
        elif len(argv) == 4:
            zip_path = pathlib.Path(argv[1])
            verify(zip_path.read_bytes(), argv[2], argv[3])
            print("STAGE56_B5_ARTIFACT_AUDIT files=11 structural=16 cli_negative=12 "
                  "source_sha_matched=YES zip_sha_matched=YES actual_year_profiles=0 "
                  "source_provenance=NOT_VERIFIED status=PASS")
        else:
            print("usage: python3 stage56_b5_artifact_audit.py --self-test | ZIP SOURCE_SHA ZIP_SHA256", file=sys.stderr)
            return 2
    except (ValueError, OSError, zipfile.BadZipFile, AssertionError) as exc:
        print("STAGE56_B5_ARTIFACT_AUDIT_FAIL: " + str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
