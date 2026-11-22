#!/usr/bin/env python3
"""Stage02 candidate-bound arithmetic; never certifies a normative maximum or Native PASS.

This independent Python integer oracle does not import or execute WAT implementation code.
Input: --power BASE^EXP or --decimal-file PATH. Output: canonical JSON report.
"""
import argparse
import hashlib
import json
import re
import sys
import unittest
from pathlib import Path

PROJECT = "PC-BRANCH-WAT-SPANISH"
M = (1 << 127) - 1
LIMB_BITS = 30
LIMB_COUNT = 1100
CAPACITY_BITS = LIMB_BITS * LIMB_COUNT
MAX_INPUT_BITS = 100000


def digest_integer(n):
    """Unambiguous unsigned big-endian representation (zero is one zero byte)."""
    raw = n.to_bytes(max(1, (n.bit_length() + 7) // 8), "big")
    return hashlib.sha256(raw).hexdigest()


def measure(n):
    if not isinstance(n, int) or n <= 0 or n.bit_length() > MAX_INPUT_BITS:
        raise ValueError("N must be a positive integer of at most 100000 bits")
    k, space = 1, M
    while space < n:
        space *= M
        k += 1
    q, rem = divmod(space, n)
    limit = q * n
    assert M ** (k - 1) < n <= space or (k == 1 and n <= M)
    assert 1 <= q and 0 <= rem < n and limit <= space < limit + n
    if k > 1:
        assert 1 <= q < M
    mn = M * n
    needed = max(space.bit_length(), mn.bit_length())
    return {
        "N_bits": n.bit_length(), "N_sha256_uint_be": digest_integer(n),
        "route": "short" if n <= M else "wide", "k": k,
        "space_bits": space.bit_length(), "M_times_N_bits": mn.bit_length(),
        "q_bits": q.bit_length(), "limit_bits": limit.bit_length(),
        "capacity_bits": CAPACITY_BITS,
        "arithmetic_envelope_fits": needed <= CAPACITY_BITS,
        "limbs_required": (needed + LIMB_BITS - 1) // LIMB_BITS,
        "limit_accepts_exactly_q_blocks": limit == q*n and limit+n > space,
    }


def parse_power(expression):
    match = re.fullmatch(r"([1-9][0-9]*)\^([0-9]+)", expression)
    if not match:
        raise ValueError("Expected --power BASE^EXP with nonnegative integer EXP")
    base, exp = map(int, match.groups())
    if exp > 100000 or base.bit_length() * exp > MAX_INPUT_BITS * 2:
        raise ValueError("Power exceeds preflight input limits")
    n = pow(base, exp)
    if n.bit_length() > MAX_INPUT_BITS:
        raise ValueError("Candidate exceeds preflight bit limit")
    return n


def parse_decimal_file(path):
    data = Path(path).read_text(encoding="ascii").strip()
    if len(data) > 31000 or not re.fullmatch(r"[1-9][0-9]*", data):
        raise ValueError("Expected unsigned positive decimal file (<= 31000 digits)")
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(50000)
    return int(data)


def preflight(n, label):
    scenarios = {"candidate_minus_one": n-1, "candidate": n,
                 "candidate_plus_one": n+1,
                 "short_to_wide_at_M": M,
                 "short_to_wide_after_M": M+1}
    k = measure(n)["k"]
    if k > 1:
        boundary = pow(M, k-1)
        scenarios["lower_k_threshold"] = boundary
        scenarios["after_lower_k_threshold"] = boundary+1
    boundary = pow(M, k)
    scenarios["upper_k_threshold"] = boundary
    scenarios["after_upper_k_threshold"] = boundary+1
    checked = {key: measure(value) for key, value in scenarios.items() if value > 0}
    return {
        "project": PROJECT, "input_label": label,
        "classification": "STATIC_NUMERIC_CANDIDATE_ONLY",
        "normative_maximum_approved": False,
        "native_or_differential_pass": False,
        "stage02_accepted": False,
        "source_policy_verified": False,
        "input_N_sha256_uint_be": digest_integer(n),
        "scenario_count": len(checked), "scenarios": checked,
    }


class TestBoundaryOracle(unittest.TestCase):
    def test_short_wide_transition(self):
        self.assertEqual(measure(M)["route"], "short")
        self.assertEqual(measure(M)["k"], 1)
        self.assertEqual(measure(M+1)["route"], "wide")
        self.assertEqual(measure(M+1)["k"], 2)

    def test_large_k_transition(self):
        self.assertEqual(measure(M**252)["k"], 252)
        self.assertEqual(measure(M**252+1)["k"], 253)
        self.assertEqual(measure(M**253)["k"], 253)
        self.assertEqual(measure(M**253+1)["k"], 254)

    def test_division_invariants(self):
        for n in (1, 2, M-1, M, M+1, 2*M, 3*M, pow(47,5778)):
            result = measure(n)
            self.assertTrue(result["limit_accepts_exactly_q_blocks"])
            self.assertTrue(result["arithmetic_envelope_fits"])
        self.assertEqual(measure(pow(47,5778))["k"], 253)

    def test_unapproved_even_when_capacity_fits(self):
        result = preflight(pow(47,5778), "47^5778")
        self.assertFalse(result["normative_maximum_approved"])
        self.assertFalse(result["stage02_accepted"])
        self.assertEqual(result["scenario_count"], 9)

    def test_reject_invalid(self):
        for value in (0, -1, 1 << 100001):
            with self.assertRaises(ValueError):
                measure(value)
        for expression in ("2**3", "0^1", "10^-2", "__import__('os')"):
            with self.assertRaises(ValueError):
                parse_power(expression)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--power", help="Positive integer power BASE^EXP, e.g. 47^5778")
    group.add_argument("--decimal-file", type=Path, help="ASCII file holding positive N")
    args = parser.parse_args(argv)
    try:
        n = parse_power(args.power) if args.power else parse_decimal_file(args.decimal_file)
        output = preflight(n, args.power or "decimal-file-input")
        print(json.dumps(output, ensure_ascii=False, sort_keys=True, indent=2))
        return 0
    except (OSError, UnicodeError, ValueError, AssertionError) as exc:
        print(json.dumps({"project": PROJECT, "result": "FAIL", "reason": str(exc)}), file=sys.stderr)
        return 1

if __name__ == "__main__":
    if "--self-test" in sys.argv:
        sys.argv.remove("--self-test")
        unittest.main()
    else:
        raise SystemExit(main())
