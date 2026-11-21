#!/usr/bin/env python3
"""Generate a full-capacity k=259 WAT witness; this is stress QA, not a legal-domain claim."""
from __future__ import annotations
import hashlib, json, os, pathlib, platform, struct, sys

PROJECT = "PC-BRANCH-WAT-SPANISH"
SOURCE_COMMIT = "871f9b70216c16c57abcd552ec6fb0ed1010e305"
SOURCE_SHA256 = "18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980"
SOURCE_BLOB = "e23f013ab96b498b0ac365dbb1b25273c845e790"
BASE_LIMB = 1 << 30
MAXL = 1100
CELL = 4416
CAPACITY_BITS = MAXL * 30
MEMORY_BYTES = 96 * 65536
N_OFFSET = 83200
RESULT_OFFSET = 145024
EXPECTED_FORWARD_OFFSET = RESULT_OFFSET + CELL
EXPECTED_BACKWARD_OFFSET = EXPECTED_FORWARD_OFFSET + CELL
EXPECTED_N_OFFSET = EXPECTED_BACKWARD_OFFSET + CELL
EVIDENCE = pathlib.Path("evidence/wat-k259-capacity-edge")
SOURCE = pathlib.Path("tests/normative_selector.wat")


def ensure(ok: bool, label: str) -> None:
    if not ok:
        raise AssertionError(label)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\x00" + data).hexdigest()


def limbs(n: int) -> list[int]:
    ensure(n >= 0, "NEGATIVE_NATURAL")
    out = []
    while n:
        out.append(n % BASE_LIMB)
        n //= BASE_LIMB
    if not out:
        out.append(0)
    ensure(len(out) <= MAXL, "LIMB_CAPACITY_EXCEEDED")
    return out


def cell(n: int) -> bytes:
    words = limbs(n)
    return struct.pack("<I", len(words)) + b"".join(struct.pack("<I", w) for w in words)


def wat_string(raw: bytes) -> str:
    return "".join("\\%02x" % b for b in raw)


def main() -> None:
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(100000)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    raw = SOURCE.read_bytes()
    ensure(len(raw) == 94201, "SOURCE_BYTE_COUNT_CHANGED")
    ensure(sha256(raw) == SOURCE_SHA256, "SOURCE_SHA256_MISMATCH")
    ensure(git_blob(raw) == SOURCE_BLOB, "SOURCE_GIT_BLOB_MISMATCH")
    source = raw.decode("utf-8")
    ensure(source.encode("utf-8") == raw, "SOURCE_UTF8_ROUNDTRIP")
    for marker in (
        '(memory (export "memory") 96)',
        '(global $MAXL i32 (i32.const 1100))',
        '(global $CELL i32 (i32.const 4416))',
        '(global $N i32 (i32.const 83200))',
        '(global $RESULT i32 (i32.const 145024))',
        '(func $choose_wide ', '(func $choose ',
    ):
        ensure(marker in source, "SOURCE_LAYOUT_CHANGED:" + marker)
    ensure("(data " not in source, "UNEXPECTED_SOURCE_DATA_SEGMENT")

    m = (1 << 127) - 1
    capacity = 1 << CAPACITY_BITS
    n = (capacity - 1) // m
    ensure(m * n <= capacity - 1, "CAPACITY_BOUND_NOT_MET")
    ensure(m * (n + 1) >= capacity, "N_NOT_MAXIMAL_FOR_CAPACITY")
    k, space = 0, 1
    while space < n:
        space *= m
        k += 1
    ensure(k == 259 and space // m < n <= space, "K259_MINIMALITY")
    ensure(space < m * n, "WIDE_SPACE_NOT_BELOW_MN")
    q, remainder = divmod(space, n)
    ensure(0 < q < m, "QUOTIENT_OUT_OF_RANGE")
    limit = q * n
    weighted_iter = sum(j * pow(m, j) for j in range(k))
    numerator = m - k * space + (k - 1) * space * m
    denominator = (m - 1) ** 2
    ensure(numerator % denominator == 0, "CLOSED_FORM_NOT_INTEGER")
    weighted_closed = numerator // denominator
    ensure(weighted_iter == weighted_closed, "INDEPENDENT_ORACLES_DISAGREE")
    forward_initial = 1 + weighted_iter
    backward_initial = space - weighted_iter
    ensure(forward_initial <= limit, "FORWARD_CASE_NOT_ACCEPTED_AT_FIRST_VALUE")
    ensure(backward_initial > limit, "BACKWARD_CASE_DOES_NOT_REJECT_TO_LIMIT")
    forward = 1 + ((forward_initial - 1) % n)
    backward = 1 + ((limit - 1) % n)
    ensure(backward == n, "BACKWARD_RANK_NOT_N")

    n_cell, f_cell, b_cell = cell(n), cell(forward), cell(backward)
    for name, data in (("N", n_cell), ("FORWARD", f_cell), ("BACKWARD", b_cell)):
        ensure(len(data) <= CELL, name + "_CELL_OVERFLOW")
    ensure(EXPECTED_FORWARD_OFFSET == 149440 and EXPECTED_BACKWARD_OFFSET == 153856 and EXPECTED_N_OFFSET == 158272,
           "QA_MEMORY_LAYOUT_CHANGED")
    ensure(EXPECTED_N_OFFSET + CELL <= MEMORY_BYTES, "QA_DATA_OUTSIDE_MEMORY")
    ensure(len(limbs(n)) == 1096 and len(limbs(space)) == 1097 and len(limbs(m*n)) == 1100,
           "CAPACITY_LIMB_COUNTS_CHANGED")

    globals_add = "\n".join((
        "  (global $QA_EXPECTED_FWD i32 (i32.const 149440))",
        "  (global $QA_EXPECTED_BWD i32 (i32.const 153856))",
        "  (global $QA_EXPECTED_N i32 (i32.const 158272))",
        "",
    ))
    tail_add = "\n".join((
        f'  (data (i32.const {N_OFFSET}) "{wat_string(n_cell)}")',
        f'  (data (i32.const {EXPECTED_FORWARD_OFFSET}) "{wat_string(f_cell)}")',
        f'  (data (i32.const {EXPECTED_BACKWARD_OFFSET}) "{wat_string(b_cell)}")',
        f'  (data (i32.const {EXPECTED_N_OFFSET}) "{wat_string(n_cell)}")',
        '  (func (export "qa_k259_capacity_forward") (result i32)',
        '    (call $init_constants)',
        '    (call $copy (global.get $FIRST) (global.get $ONE))',
        '    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $RESULT))',
        '    (i32.and',
        '      (i32.eqz (call $cmp (global.get $RESULT) (global.get $QA_EXPECTED_FWD)))',
        '      (i32.eqz (call $cmp (global.get $N) (global.get $QA_EXPECTED_N)))))',
        '  (func (export "qa_k259_capacity_backward") (result i32)',
        '    (call $init_constants)',
        '    (call $copy (global.get $FIRST) (global.get $M))',
        '    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $RESULT))',
        '    (i32.and',
        '      (i32.eqz (call $cmp (global.get $RESULT) (global.get $QA_EXPECTED_BWD)))',
        '      (i32.eqz (call $cmp (global.get $N) (global.get $QA_EXPECTED_N)))))',
        "",
    ))
    module_marker = "(module\n"
    ensure(source.startswith(module_marker), "MODULE_HEADER_CHANGED")
    prefixed = source[:len(module_marker)] + globals_add + source[len(module_marker):]
    close = prefixed.rfind(")")
    ensure(close >= 0 and prefixed[close+1:].strip() == "", "MODULE_END_CHANGED")
    instrumented = prefixed[:close] + tail_add + prefixed[close:]
    ensure(instrumented.replace(globals_add, "", 1).replace(tail_add, "", 1) == source,
           "NORMATIVE_SOURCE_CHANGED_BY_INSTRUMENTATION")
    instrumented_bytes = instrumented.encode("utf-8")

    (EVIDENCE / "source.wat").write_bytes(raw)
    (EVIDENCE / "instrumented.wat").write_bytes(instrumented_bytes)
    (EVIDENCE / "instrumentation-only.diff.txt").write_text(
        "[QA globals after module header]\n" + globals_add +
        "\n[QA data segments and exports before module end]\n" + tail_add,
        encoding="utf-8")
    (EVIDENCE / "oracle.json").write_text(json.dumps({
        "capacity_bits": CAPACITY_BITS,
        "capacity_decimal": str(capacity),
        "N_max_for_MN_below_capacity_decimal": str(n),
        "M_decimal": str(m),
        "N_bits": n.bit_length(),
        "N_limbs": len(limbs(n)),
        "k_minimal": k,
        "space_bits": space.bit_length(),
        "space_limbs": len(limbs(space)),
        "M_times_N_bits": (m*n).bit_length(),
        "M_times_N_limbs": len(limbs(m*n)),
        "M_times_N_less_than_2_pow_33000": m*n < capacity,
        "N_plus_one_exceeds_capacity_bound": m*(n+1) >= capacity,
        "quotient_bits": q.bit_length(),
        "remainder_bits": remainder.bit_length(),
        "weighted_iterative_equals_closed_form": True,
        "forward_initial_le_limit": forward_initial <= limit,
        "backward_initial_gt_limit": backward_initial > limit,
        "forward_expected_decimal": str(forward),
        "backward_expected_decimal": str(backward),
        "forward_expected_sha256_decimal": sha256(str(forward).encode("ascii")),
        "backward_expected_sha256_decimal": sha256(str(backward).encode("ascii")),
        "legal_domain_max_verified": False,
        "capacity_edge_stress_only": True,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    manifest = {
        "project": PROJECT,
        "gate": "CAPACITY_EDGE_K259_STRESS_ONLY",
        "sourceCommit": SOURCE_COMMIT,
        "sourceSha256": SOURCE_SHA256,
        "sourceGitBlob": SOURCE_BLOB,
        "sourceBytes": len(raw),
        "qaCommit": os.environ.get("GITHUB_SHA", "LOCAL_PREFLIGHT"),
        "runId": os.environ.get("GITHUB_RUN_ID", "LOCAL_PREFLIGHT"),
        "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", "LOCAL_PREFLIGHT"),
        "python": sys.version.split()[0],
        "platform": platform.platform(),
        "capacityBits": CAPACITY_BITS,
        "NBits": n.bit_length(),
        "NLimbs": len(limbs(n)),
        "minimalK": k,
        "spaceBits": space.bit_length(),
        "spaceLimbs": len(limbs(space)),
        "MNBits": (m*n).bit_length(),
        "MNLimbs": len(limbs(m*n)),
        "forwardExpectedLimbs": len(limbs(forward)),
        "backwardExpectedLimbs": len(limbs(backward)),
        "oracleIndependentOfWAT": True,
        "normativeSourceModified": False,
        "legalDomainMaxVerified": False,
        "stage02Accepted": False,
    }
    (EVIDENCE / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "project": PROJECT,
        "result": "CAPACITY_EDGE_K259_ORACLE_READY",
        "minimal_k": k,
        "N_bits": n.bit_length(),
        "N_limbs": len(limbs(n)),
        "space_bits": space.bit_length(),
        "space_limbs": len(limbs(space)),
        "MN_bits": (m*n).bit_length(),
        "MN_limbs": len(limbs(m*n)),
        "forward_expected_limbs": len(limbs(forward)),
        "backward_expected_limbs": len(limbs(backward)),
        "forward_sha256_decimal": sha256(str(forward).encode("ascii")),
        "backward_sha256_decimal": sha256(str(backward).encode("ascii")),
        "source_git_blob": git_blob(raw),
        "instrumented_wat_sha256": sha256(instrumented_bytes),
        "legal_domain_max_verified": False,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"K259_CAPACITY_PREPARE_FAILED: {exc}", file=sys.stderr)
        raise
