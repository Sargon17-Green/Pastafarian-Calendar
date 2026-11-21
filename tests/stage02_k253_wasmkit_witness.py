#!/usr/bin/env python3
"""Build a WasmKit-only k=253 witness from the locked normative WAT source.

The independent Python oracle computes the exact expected natural numbers,
then embeds their canonical base-2^30 limbs into QA-only data segments. The
instrumented exports return i32(1) only when the original WAT selector's full
result exactly equals the independent oracle. The normative source is never
modified or rewritten in the repository.
"""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import platform
import struct
import sys

PROJECT = "PC-BRANCH-WAT-SPANISH"
LOCKED_COMMIT = "871f9b70216c16c57abcd552ec6fb0ed1010e305"
WAT_SHA256 = "18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980"
WAT_BLOB = "e23f013ab96b498b0ac365dbb1b25273c845e790"
EXPECTED_FORWARD_SHA = "82908b318fb3f8d991bdbec92b2ac2c51f96e093b806ef979df084974f08e6a5"
EXPECTED_BACKWARD_SHA = "3b8e337f6d91ec378519cd6dcc489d920f171c13910556889b56775697d18631"
BASE = 1 << 30
MAX_LIMBS = 1100
CELL_BYTES = 4416
MEMORY_BYTES = 96 * 65536
N_OFFSET = 83200
RESULT_OFFSET = 145024
EXPECTED_FORWARD_OFFSET = RESULT_OFFSET + CELL_BYTES
EXPECTED_BACKWARD_OFFSET = EXPECTED_FORWARD_OFFSET + CELL_BYTES
EXPECTED_N_OFFSET = EXPECTED_BACKWARD_OFFSET + CELL_BYTES
EVIDENCE = pathlib.Path("evidence/wat-k253-wasmkit")
SOURCE = pathlib.Path("tests/normative_selector.wat")


def ensure(condition: bool, label: str) -> None:
    if not condition:
        raise AssertionError(label)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    header = b"blob " + str(len(data)).encode("ascii") + b"\x00"
    return hashlib.sha1(header + data).hexdigest()


def to_limbs(value: int) -> list[int]:
    ensure(value >= 0, "NEGATIVE_NATURAL")
    out: list[int] = []
    while value:
        out.append(value % BASE)
        value //= BASE
    if not out:
        out.append(0)
    ensure(len(out) <= MAX_LIMBS, "LIMB_CAPACITY_EXCEEDED")
    return out


def encode_cell(value: int) -> bytes:
    words = to_limbs(value)
    return struct.pack("<I", len(words)) + b"".join(struct.pack("<I", x) for x in words)


def wat_bytes(data: bytes) -> str:
    return "".join("\\%02x" % b for b in data)


def main() -> None:
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(100000)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    raw = SOURCE.read_bytes()
    ensure(len(raw) == 94201, "SOURCE_BYTE_COUNT_CHANGED")
    ensure(sha256(raw) == WAT_SHA256, "SOURCE_SHA256_MISMATCH")
    ensure(git_blob(raw) == WAT_BLOB, "SOURCE_GIT_BLOB_MISMATCH")
    source = raw.decode("utf-8")
    ensure(source.encode("utf-8") == raw, "SOURCE_UTF8_ROUNDTRIP")
    for sentinel in (
        '(memory (export "memory") 96)',
        '(global $MAXL i32 (i32.const 1100))',
        '(global $CELL i32 (i32.const 4416))',
        '(global $N i32 (i32.const 83200))',
        '(global $RESULT i32 (i32.const 145024))',
        '(func $choose_wide ',
        '(func $choose ',
    ):
        ensure(sentinel in source, "SOURCE_LAYOUT_SENTINEL:" + sentinel)
    ensure("(data " not in source, "UNEXPECTED_EXISTING_DATA_SEGMENT")
    ensure("qa_k253_wasmkit_forward" not in source
           and "qa_k253_wasmkit_backward" not in source,
           "QA_EXPORT_ALREADY_PRESENT")

    m = (1 << 127) - 1
    n = 47 ** 5778
    k, space = 0, 1
    while space < n:
        space *= m
        k += 1
    ensure(k == 253 and space // m < n <= space, "K253_MINIMALITY")
    ensure(space < n * m, "SPACE_LT_N_TIMES_M")
    q, remainder = divmod(space, n)
    ensure(remainder >= 0 and 0 < q < m, "QUOTIENT_BOUND")
    limit = q * n

    weighted_iterative = sum(j * pow(m, j) for j in range(k))
    numerator = m - k * space + (k - 1) * space * m
    denominator = (m - 1) ** 2
    ensure(numerator % denominator == 0, "CLOSED_FORM_NOT_INTEGER")
    weighted_closed = numerator // denominator
    ensure(weighted_iterative == weighted_closed, "INDEPENDENT_FORMULAS_DISAGREE")

    forward_initial = 1 + weighted_iterative
    backward_initial = space - weighted_iterative
    ensure(forward_initial <= limit, "FORWARD_CASE_WOULD_REJECT")
    ensure(backward_initial > limit, "BACKWARD_CASE_WOULD_NOT_REJECT")
    forward = 1 + ((forward_initial - 1) % n)
    backward = 1 + ((limit - 1) % n)
    ensure(backward == n, "BACKWARD_LIMIT_RANK_NOT_N")
    forward_sha = sha256(str(forward).encode("ascii"))
    backward_sha = sha256(str(backward).encode("ascii"))
    ensure(forward_sha == EXPECTED_FORWARD_SHA, "FORWARD_ORACLE_HASH_MISMATCH")
    ensure(backward_sha == EXPECTED_BACKWARD_SHA, "BACKWARD_ORACLE_HASH_MISMATCH")

    n_cell = encode_cell(n)
    forward_cell = encode_cell(forward)
    backward_cell = encode_cell(backward)
    ensure(len(n_cell) <= CELL_BYTES, "N_CELL_OVERFLOW")
    ensure(len(forward_cell) <= CELL_BYTES, "FORWARD_EXPECTED_CELL_OVERFLOW")
    ensure(len(backward_cell) <= CELL_BYTES, "BACKWARD_EXPECTED_CELL_OVERFLOW")
    ensure(N_OFFSET + CELL_BYTES == 87616, "N_CELL_LAYOUT_CHANGED")
    ensure(EXPECTED_FORWARD_OFFSET == 149440, "EXPECTED_FORWARD_OFFSET_CHANGED")
    ensure(EXPECTED_BACKWARD_OFFSET == 153856, "EXPECTED_BACKWARD_OFFSET_CHANGED")
    ensure(EXPECTED_N_OFFSET == 158272, "EXPECTED_N_OFFSET_CHANGED")
    ensure(EXPECTED_N_OFFSET + CELL_BYTES <= MEMORY_BYTES,
           "EXPECTED_CELLS_OUTSIDE_MEMORY")

    global_addition = "\n".join((
        "  (global $QA_EXPECTED_FWD i32 (i32.const 149440))",
        "  (global $QA_EXPECTED_BWD i32 (i32.const 153856))",
        "  (global $QA_EXPECTED_N i32 (i32.const 158272))",
        "",
    ))
    tail_addition = "\n".join((
        f'  (data (i32.const {N_OFFSET}) "{wat_bytes(n_cell)}")',
        f'  (data (i32.const {EXPECTED_FORWARD_OFFSET}) "{wat_bytes(forward_cell)}")',
        f'  (data (i32.const {EXPECTED_BACKWARD_OFFSET}) "{wat_bytes(backward_cell)}")',
        f'  (data (i32.const {EXPECTED_N_OFFSET}) "{wat_bytes(n_cell)}")',
        '  (func (export "qa_k253_wasmkit_forward") (result i32)',
        '    (call $init_constants)',
        '    (call $copy (global.get $FIRST) (global.get $ONE))',
        '    (call $choose (global.get $FIRST) (i32.const 1)',
        '      (global.get $N) (global.get $RESULT))',
        '    (i32.and',
        '      (i32.eqz (call $cmp (global.get $RESULT) (global.get $QA_EXPECTED_FWD)))',
        '      (i32.eqz (call $cmp (global.get $N) (global.get $QA_EXPECTED_N)))))',
        '  (func (export "qa_k253_wasmkit_backward") (result i32)',
        '    (call $init_constants)',
        '    (call $copy (global.get $FIRST) (global.get $M))',
        '    (call $choose (global.get $FIRST) (i32.const -1)',
        '      (global.get $N) (global.get $RESULT))',
        '    (i32.and',
        '      (i32.eqz (call $cmp (global.get $RESULT) (global.get $QA_EXPECTED_BWD)))',
        '      (i32.eqz (call $cmp (global.get $N) (global.get $QA_EXPECTED_N)))))',
        "",
    ))
    module_marker = "(module\n"
    ensure(source.startswith(module_marker), "MODULE_PREFIX_CHANGED")
    global_position = len(module_marker)
    prefixed = source[:global_position] + global_addition + source[global_position:]
    close = prefixed.rfind(")")
    ensure(close >= 0 and prefixed[close + 1:].strip() == "", "NO_UNIQUE_MODULE_END")
    instrumented = prefixed[:close] + tail_addition + prefixed[close:]
    restored = instrumented.replace(global_addition, "", 1).replace(tail_addition, "", 1)
    ensure(restored == source, "INSTRUMENTATION_CHANGED_NORMATIVE_SOURCE")
    addition = ("[GLOBALS INSERTED AFTER MODULE HEADER]\n" + global_addition
                + "\n[DATA AND EXPORTS APPENDED BEFORE MODULE END]\n" + tail_addition)

    (EVIDENCE / "source.wat").write_bytes(raw)
    (EVIDENCE / "instrumentation-only.diff.txt").write_text(addition, encoding="utf-8")
    instrumented_bytes = instrumented.encode("utf-8")
    (EVIDENCE / "instrumented.wat").write_bytes(instrumented_bytes)
    (EVIDENCE / "oracle.json").write_text(json.dumps({
        "N_decimal": str(n),
        "minimal_k": k,
        "space_decimal": str(space),
        "limit_decimal": str(limit),
        "forward_initial_decimal": str(forward_initial),
        "backward_initial_decimal": str(backward_initial),
        "forward_expected_decimal": str(forward),
        "backward_expected_decimal": str(backward),
        "forward_expected_sha256_decimal": forward_sha,
        "backward_expected_sha256_decimal": backward_sha,
        "independent_iterative_and_closed_form_agree": True,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    manifest = {
        "project": PROJECT,
        "gate": "WASMKIT_K253_FULL_LIMB_DIFFERENTIAL_ONLY",
        "sourceCommit": LOCKED_COMMIT,
        "sourceSha256": WAT_SHA256,
        "sourceGitBlob": WAT_BLOB,
        "sourceBytes": len(raw),
        "qaCommit": os.environ.get("GITHUB_SHA", "LOCAL_PREFLIGHT"),
        "runId": os.environ.get("GITHUB_RUN_ID", "LOCAL_PREFLIGHT"),
        "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", "LOCAL_PREFLIGHT"),
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "N_bits": n.bit_length(),
        "N_limbs": len(to_limbs(n)),
        "M_bits": m.bit_length(),
        "minimalK": k,
        "spaceBits": space.bit_length(),
        "M_times_N_bits": (m * n).bit_length(),
        "quotientBits": q.bit_length(),
        "forwardExpectedLimbs": len(to_limbs(forward)),
        "backwardExpectedLimbs": len(to_limbs(backward)),
        "forwardExpectedSha256Decimal": forward_sha,
        "backwardExpectedSha256Decimal": backward_sha,
        "oracleIndependentOfWAT": True,
        "normativeSourceModified": False,
        "stage02Accepted": False,
    }
    (EVIDENCE / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps({
        "project": PROJECT,
        "result": "PYTHON_ORACLE_AND_INSTRUMENTATION_READY",
        "minimal_k": k,
        "N_bits": n.bit_length(),
        "space_bits": space.bit_length(),
        "forward_limbs": len(to_limbs(forward)),
        "backward_limbs": len(to_limbs(backward)),
        "forward_sha256_decimal": forward_sha,
        "backward_sha256_decimal": backward_sha,
        "source_git_blob": git_blob(raw),
        "instrumented_wat_sha256": sha256(instrumented_bytes),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"K253_WASMKIT_PREPARE_FAILED: {exc}", file=sys.stderr)
        raise
