#!/usr/bin/env python3
"""Generate a temporary, test-only instrumented copy of the v164 GMP package.

This script never edits the production Ada source, invokes GNAT, or executes
an Ada binary.  It is deliberately source-only; the generated copy is for a
separately authorized, bounded native lifecycle run.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import tempfile
from itertools import permutations
from pathlib import Path

SPEC_BLOB_SHA1 = "0b68edf7eddbc33869358bcfcc21e32465fc591e"
BODY_BLOB_SHA1 = "845bd8905943a54e63d6aba0334404a5051fe666"

WITH_ANCHOR = "with GNATCOLL.GMP;\n"
FREE_ANCHOR = "            Free_Row (F.H (I));"
TERMINAL_ANCHOR = (
    "      F.H (F.Month_Count) :=\n"
    "        new Big_Row (0 .. F.Prefix (F.Month_Count));"
)
LOWER_ANCHOR = "            F.H (I) := new Big_Row (0 .. F.Prefix (I));"


def git_blob_sha1(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode("ascii")
    return hashlib.sha1(header + data).hexdigest()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def replace_exact(source: str, anchor: str, replacement: str, label: str) -> str:
    count = source.count(anchor)
    if count != 1:
        raise SystemExit(f"expected exactly one {label} anchor, found {count}")
    return source.replace(anchor, replacement, 1)


ORACLE_FIXTURES = {
    (2,): ("11",),
    (2, 2): ("1122", "1212"),
    (2, 3): ("11222", "12122", "12212"),
    (3, 2): ("11122", "11212", "12112"),
    (3, 3): ("111222", "112122", "112212", "121122", "121212", "122112"),
    (2, 2, 2): ("112233", "112323", "121233", "121323", "123123"),
}


def independent_words(lengths: tuple[int, ...]) -> tuple[str, ...]:
    """Brute-force oracle: sort multiset permutations, then filter ordered ends."""
    multiset = tuple(
        label for label, count in enumerate(lengths, start=1) for _ in range(count)
    )
    words = sorted(set(permutations(multiset)))
    accepted = []
    for word in words:
        first_positions = [word.index(label) for label in range(1, len(lengths) + 1)]
        last_positions = [
            len(word) - 1 - word[::-1].index(label)
            for label in range(1, len(lengths) + 1)
        ]
        if first_positions == sorted(first_positions) and last_positions == sorted(last_positions):
            accepted.append("".join(str(label) for label in word))
    return tuple(accepted)


def check_literal_oracles() -> None:
    for lengths, expected in ORACLE_FIXTURES.items():
        actual = independent_words(lengths)
        if actual != expected:
            raise SystemExit(
                f"independent literal oracle mismatch for {lengths}: "
                f"expected {expected}, got {actual}"
            )


def prepare(root: Path, output: Path) -> dict[str, object]:
    spec_path = root / "src" / "canonical_full_weave_gmp_v164.ads"
    body_path = root / "src" / "canonical_full_weave_gmp_v164.adb"
    test_dir = root / "tests"

    spec_bytes = spec_path.read_bytes()
    body_bytes = body_path.read_bytes()
    spec_sha = git_blob_sha1(spec_bytes)
    body_sha = git_blob_sha1(body_bytes)
    if spec_sha != SPEC_BLOB_SHA1:
        raise SystemExit(
            f"spec source lock mismatch: expected {SPEC_BLOB_SHA1}, got {spec_sha}"
        )
    if body_sha != BODY_BLOB_SHA1:
        raise SystemExit(
            f"body source lock mismatch: expected {BODY_BLOB_SHA1}, got {body_sha}"
        )

    body = body_bytes.decode("utf-8")
    body = replace_exact(
        body,
        WITH_ANCHOR,
        WITH_ANCHOR + "with Issue29_Lifecycle_Probe;\n",
        "probe with-clause",
    )
    body = replace_exact(
        body,
        FREE_ANCHOR,
        FREE_ANCHOR + "\n            Issue29_Lifecycle_Probe.Record_Free;",
        "Finalize Free_Row",
    )
    body = replace_exact(
        body,
        TERMINAL_ANCHOR,
        "      Issue29_Lifecycle_Probe.Before_Terminal_Allocation;\n"
        + TERMINAL_ANCHOR
        + "\n      Issue29_Lifecycle_Probe.Record_Allocation;\n"
        "      Issue29_Lifecycle_Probe.After_Terminal_Allocation;",
        "terminal H allocation",
    )
    body = replace_exact(
        body,
        LOWER_ANCHOR,
        LOWER_ANCHOR
        + "\n            Issue29_Lifecycle_Probe.Record_Allocation;\n"
        "            Issue29_Lifecycle_Probe.After_Lower_Row_Allocation;",
        "lower H row allocation",
    )

    if body.count("Issue29_Lifecycle_Probe.Record_Allocation;") != 2:
        raise SystemExit("instrumentation must count exactly two allocation sites")
    if body.count("Issue29_Lifecycle_Probe.Record_Free;") != 1:
        raise SystemExit("instrumentation must count exactly one Free_Row site")
    for marker in (
        "Before_Terminal_Allocation;",
        "After_Terminal_Allocation;",
        "After_Lower_Row_Allocation;",
    ):
        if body.count("Issue29_Lifecycle_Probe." + marker) != 1:
            raise SystemExit(f"instrumentation site count mismatch: {marker}")

    if output.exists() and any(output.iterdir()):
        raise SystemExit(f"refusing to overwrite non-empty output directory: {output}")
    output.mkdir(parents=True, exist_ok=True)
    src_out = output / "src"
    tests_out = output / "tests"
    src_out.mkdir()
    tests_out.mkdir()

    (src_out / spec_path.name).write_bytes(spec_bytes)
    (src_out / body_path.name).write_text(body, encoding="utf-8", newline="\n")
    for name in (
        "issue29_lifecycle_probe.ads",
        "issue29_lifecycle_probe.adb",
        "issue29_lifecycle_regression.adb",
    ):
        shutil.copyfile(test_dir / name, tests_out / name)

    gpr = (
        'with "gnatcoll_gmp.gpr";\n'
        "project Issue29_Lifecycle_Regression is\n"
        '   for Source_Dirs use ("src", "tests");\n'
        '   for Object_Dir use "obj";\n'
        '   for Exec_Dir use "bin";\n'
        '   for Main use ("issue29_lifecycle_regression.adb");\n'
        "   package Compiler is\n"
        '      for Default_Switches ("Ada") use\n'
        '        ("-gnat2022", "-gnatW8", "-gnata", "-gnatwa", "-gnato");\n'
        "   end Compiler;\n"
        "end Issue29_Lifecycle_Regression;\n"
    )
    (output / "issue29_lifecycle_regression.gpr").write_text(
        gpr, encoding="utf-8", newline="\n"
    )

    generated = {}
    for path in sorted(p for p in output.rglob("*") if p.is_file()):
        rel = path.relative_to(output).as_posix()
        generated[rel] = {
            "bytes": path.stat().st_size,
            "sha256": sha256(path.read_bytes()),
        }
    manifest: dict[str, object] = {
        "schema": "ISSUE29_LIFECYCLE_INSTRUMENTATION/1",
        "locked_source": {
            "spec_git_blob_sha1": spec_sha,
            "body_git_blob_sha1": body_sha,
        },
        "instrumentation_sites": {
            "before_terminal_allocation": 1,
            "after_terminal_allocation": 1,
            "after_lower_row_allocation": 1,
            "allocation_counters": 2,
            "free_row_counter": 1,
        },
        "production_source_modified": False,
        "compile_invoked": False,
        "native_execution_invoked": False,
        "generated_files": generated,
    }
    manifest_bytes = (json.dumps(manifest, indent=2, sort_keys=True) + "\n").encode()
    (output / "manifest.json").write_bytes(manifest_bytes)
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--check",
        action="store_true",
        help="generate in a temporary directory, verify, then remove it",
    )
    mode.add_argument(
        "--output-dir",
        type=Path,
        help="write the temporary instrumented source tree to an empty directory",
    )
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    check_literal_oracles()

    if args.check:
        with tempfile.TemporaryDirectory(prefix="issue29-lifecycle-source-only-") as tmp:
            manifest = prepare(root, Path(tmp) / "generated")
            if manifest["compile_invoked"] or manifest["native_execution_invoked"]:
                raise SystemExit("source-only check unexpectedly claims execution")
        print("ISSUE29_LIFECYCLE_SOURCE_GENERATION=PASS")
        print("ISSUE29_LIFECYCLE_GNAT_COMPILE=NOT_RUN")
        print("ISSUE29_LIFECYCLE_NATIVE=NOT_RUN")
        return 0

    output = args.output_dir.expanduser().resolve()
    manifest = prepare(root, output)
    print(f"Generated source-only lifecycle tree: {output}")
    print(f"Locked spec blob: {manifest['locked_source']['spec_git_blob_sha1']}")
    print(f"Locked body blob: {manifest['locked_source']['body_git_blob_sha1']}")
    print("GNAT compile: NOT_RUN; Native execution: NOT_RUN")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
