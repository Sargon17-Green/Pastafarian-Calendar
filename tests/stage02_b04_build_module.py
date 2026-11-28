#!/usr/bin/env python3
"""Build a temporary QA-augmented selector module without changing the locked source."""
import argparse
import hashlib
import json
import re
from pathlib import Path

EXPECTED_SOURCE_SHA256 = "18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980"
EXPECTED_GIT_BLOB = "e23f013ab96b498b0ac365dbb1b25273c845e790"
EXPECTED_EXPORTS = (
    "test_b04_c1_short_backward_m",
    "test_b04_c2_wide_backward_m_plus_one",
    "test_b04_c3_wide_backward_reject_2m",
    "test_b04_c4_wide_backward_reject_3m",
    "test_b04_c5_c6_parametric",
)


def git_blob_sha(data: bytes) -> str:
    header = b"blob " + str(len(data)).encode("ascii") + b"\0"
    return hashlib.sha1(header + data).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    source_path = root / "tests" / "normative_selector.wat"
    fragment_path = root / "tests" / "stage02_b04_boundary_cases.wat.inc"
    source_bytes = source_path.read_bytes()
    fragment_bytes = fragment_path.read_bytes()

    source_sha256 = hashlib.sha256(source_bytes).hexdigest()
    source_blob = git_blob_sha(source_bytes)
    if source_sha256 != EXPECTED_SOURCE_SHA256:
        raise SystemExit("BASE_SOURCE_SHA256_MISMATCH: " + source_sha256)
    if source_blob != EXPECTED_GIT_BLOB:
        raise SystemExit("BASE_GIT_BLOB_MISMATCH: " + source_blob)

    source = source_bytes.decode("utf-8")
    fragment = fragment_bytes.decode("utf-8").strip()
    if source.count("(module") != 1 or not source.rstrip().endswith(")"):
        raise SystemExit("BASE_MODULE_SHAPE_INVALID")
    if "test_b04_" in source:
        raise SystemExit("B04_EXPORTS_ALREADY_PRESENT_IN_BASE")
    found = tuple(re.findall(r'\(func\s+\(export\s+"([^"]+)"\)', fragment))
    if found != EXPECTED_EXPORTS or len(set(found)) != len(EXPECTED_EXPORTS):
        raise SystemExit("FRAGMENT_EXPORT_SET_MISMATCH: " + repr(found))

    generated = source.rstrip()[:-1] + "\n\n" + fragment + "\n)\n"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(generated, encoding="utf-8", newline="\n")
    payload = {
        "project_id": "PC-BRANCH-WAT-SPANISH",
        "base_git_blob": source_blob,
        "base_source_sha256": source_sha256,
        "fragment_sha256": hashlib.sha256(fragment_bytes).hexdigest(),
        "generated_wat_sha256": hashlib.sha256(generated.encode("utf-8")).hexdigest(),
        "exports": list(found),
        "base_source_modified": False,
    }
    print(json.dumps(payload, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
