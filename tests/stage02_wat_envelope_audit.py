#!/usr/bin/env python3
"""Independent Stage02 WAT domain-envelope audit (static/numeric only; never Native)."""
import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT = "PC-BRANCH-WAT-SPANISH"
SOURCE_SHA = "871f9b70216c16c57abcd552ec6fb0ed1010e305"
WAT_SHA256 = "18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980"
WAT_BLOB = "e23f013ab96b498b0ac365dbb1b25273c845e790"
ARRAYS = "M ONE FIRST CUR N Q R LIMIT SPACE WIDE WEIGHT DIGIT TERM TMP0 TMP1 TMP2 TMP3 SHIFTED RESULT".split()

def ensure(condition, label):
    if not condition:
        raise AssertionError(label)

def inspect(path):
    source_bytes = Path(path).read_bytes()
    ensure(hashlib.sha256(source_bytes).hexdigest() == WAT_SHA256, "WAT_SHA256_MISMATCH")
    blob = hashlib.sha1(b"blob " + str(len(source_bytes)).encode("ascii") + b"\x00" + source_bytes).hexdigest()
    ensure(blob == WAT_BLOB, "WAT_GIT_BLOB_MISMATCH")
    source = source_bytes.decode("utf-8")
    globals_i32 = {key: int(value) for key, value in re.findall(
        r'\(global \$(\w+) i32 \(i32\.const (\d+)\)\)', source)}
    ensure(globals_i32.get("MAXL") == 1100, "LIMB_COUNT_CHANGED")
    ensure(globals_i32.get("CELL") == 4416, "CELL_SIZE_CHANGED")
    ensure('(global $BASE i64 (i64.const 1073741824))' in source, "BASE_CHANGED")
    offsets = [globals_i32[name] for name in ARRAYS]
    ensure(all(b - a == 4416 for a,b in zip(offsets, offsets[1:])), "ARRAY_LAYOUT_CHANGED")
    ensure(4416 >= 4 + 1100 * 4, "ARRAY_OVERLAP")
    ensure(offsets[-1] + 4416 <= 96 * 65536, "MEMORY_BOUNDS")
    ensure('(memory (export "memory") 96)' in source, "MEMORY_DECLARATION_CHANGED")
    tests = re.findall(r'\(func\s+\(export\s+"([^"]+)"\)\s+\(result\s+i32\)', source)
    ensure(len(tests) == 111 and len(set(tests)) == 111, "EXPORT_INVENTORY_CHANGED")
    ensure(all(name.startswith("test_") for name in tests), "NON_TEST_EXPORT")
    k_levels = [int(m.group(1)) for name in tests
                if (m := re.match(r"test_discovery01_k(\d+)_", name))]
    ensure(k_levels and max(k_levels) == 5, "EXPLICIT_K_COVERAGE_CHANGED")
    return {"source_byte_count": len(source_bytes),
            "source_sha256": WAT_SHA256, "source_git_blob": blob,
            "test_exports": len(tests), "highest_named_k": max(k_levels),
            "array_count": len(ARRAYS), "last_array_end": offsets[-1]+4416,
            "memory_bytes": 96*65536, "capacity_bits": 1100*30}

def arithmetic():
    m = (1 << 127) - 1
    n = 47**5778  # Explicit stress input in WAT comment, not independently established legal maximum.
    k, space = 0, 1
    while space < n:
        space *= m
        k += 1
    ensure(k == 253 and space // m < n <= space, "K_MINIMALITY")
    ensure(space < n * m, "SPACE_BOUND")
    q, _ = divmod(space, n)
    ensure(0 < q < m, "QUOTIENT_BOUND")
    limit = q * n
    s_iter = sum(j * pow(m,j) for j in range(k))
    s_closed = (m-k*pow(m,k)+(k-1)*pow(m,k+1)) // (m-1)**2
    ensure(s_iter == s_closed, "INDEPENDENT_ALGEBRA_DISAGREEMENT")
    forward_initial, backward_initial = 1+s_iter, space-s_closed
    ensure(forward_initial <= limit < backward_initial, "DIRECTION_BOUNDARY_CHANGED")
    forward_rank = 1 + ((forward_initial-1) % n)
    backward_rank = 1 + ((limit-1) % n)
    ensure(1 <= forward_rank <= n and backward_rank == n, "RANK_BOUNDARY_CHANGED")
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(100000)
    decimal_sha = lambda x: hashlib.sha256(str(x).encode("ascii")).hexdigest()
    return {"stress_n": "47**5778", "stress_is_verified_legal_maximum": False,
            "M_bits": m.bit_length(), "N_bits": n.bit_length(),
            "k": k, "space_bits": space.bit_length(),
            "M_times_N_bits": (m*n).bit_length(), "q_bits": q.bit_length(),
            "forward_accepted_without_rejection": True,
            "forward_rank_bits": forward_rank.bit_length(),
            "forward_rank_sha256_decimal": decimal_sha(forward_rank),
            "backward_rejected_to_limit": True,
            "backward_rank_equals_N": True,
            "backward_rank_sha256_decimal": decimal_sha(backward_rank),
            "two_algebraic_constructions_agree": True}

def main():
    try:
        a = arithmetic()
        b = inspect(sys.argv[1] if len(sys.argv) > 1 else "tests/normative_selector.wat")
        ensure(a["M_times_N_bits"] <= b["capacity_bits"], "CAPACITY_INSUFFICIENT")
        print(json.dumps({"project": PROJECT, "locked_source": SOURCE_SHA,
              "result": "STATIC_NUMERIC_PASS", "not_native": True,
              "not_stage02_acceptance": True, "source": b, "math": a},
              indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, UnicodeError, AssertionError) as error:
        print(json.dumps({"project": PROJECT, "result": "FAIL",
                          "reason": str(error)}), file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
