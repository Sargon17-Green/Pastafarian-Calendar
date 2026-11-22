#!/usr/bin/env python3
"""Bound calendar-invoked Choose family sizes from canonical combinatorial rules.

This is a mathematical/structural proof witness, not Native execution and not a
restriction on the generic Choose(N) primitive. No WAT is imported or executed.
"""
import hashlib
import json
import math
import sys
import unittest

PROJECT = "PC-BRANCH-WAT-SPANISH"
M = (1 << 127) - 1
MIN_GATE_GAP = 42
MAX_YEAR_DAYS = 5778
MIN_CUTLETS = 6
MAX_CUTLETS = 17
MAX_MONTHS = 47
LIMB_COUNT = 1100
LIMB_BITS = 30


def fingerprint(n):
    if n < 0:
        raise ValueError("nonnegative only")
    return hashlib.sha256(n.to_bytes(max(1, (n.bit_length() + 7) // 8), "big")).hexdigest()


def canonical_envelope():
    # Every consecutive gate pair is separated by >= 42 days. In any year,
    # there are at most floor(5778/42) gap segments.
    max_gaps = MAX_YEAR_DAYS // MIN_GATE_GAP
    # For an origin candidate (i,j) containing c, each endpoint is in its
    # respective 5778-day half-window about c. An interval of length 5778
    # contains at most floor(5778/42)+1 gates. Squaring is conservative.
    max_endpoint_positions = max_gaps + 1
    families = {
        "origin_year_pairs": max_endpoint_positions ** 2,
        "next_or_previous_year": max_gaps,
        "cutlet_count": MAX_CUTLETS - MIN_CUTLETS + 1,
        # A positive composition of n corresponds to a subset of its n-1
        # internal boundaries. Extra constraints can only decrease count.
        "cutlet_partition": 1 << (max_gaps - 1),
        "cutlet_names": math.factorial(MAX_CUTLETS),
        "month_count": MAX_MONTHS,
        # Every m-part positive composition of Y is one of 2^(Y-1)
        # positive compositions, even before min/max month-day constraints.
        "month_lengths": 1 << (MAX_YEAR_DAYS - 1),
        # A weaving of Y days over m positional month IDs is one of m^Y
        # possible sequences. Canonical opening/closing/count constraints
        # select a subset; Y<=5778 and m<=47.
        "month_weaving": MAX_MONTHS ** MAX_YEAR_DAYS,
        "month_names": math.factorial(MAX_MONTHS),
    }
    upper = MAX_MONTHS ** MAX_YEAR_DAYS
    assert all(0 < n <= upper for n in families.values())
    assert families["month_weaving"] == upper
    # Canonical Choose invocations select among these finite families.
    # Generic primitive Choose(N) is unbounded and is not covered here.
    space, k = M, 1
    while space < upper:
        space *= M
        k += 1
    assert M ** (k - 1) < upper <= M ** k
    assert k == 253
    # Existing WAT layout: 1100 base-2^30 limbs; this proves only a
    # conservative arithmetic capacity envelope, not implementation safety.
    needed = max(space.bit_length(), (M * upper).bit_length())
    assert needed <= LIMB_COUNT * LIMB_BITS
    return {
        "project": PROJECT,
        "scope": "canonical_calendar_family_Choose_invocations_only",
        "canon_rules": ["rule.years", "rule.structure", "rule.family.compositions",
                        "rule.family.weaving", "rule.selection.rank"],
        "source_constant_facts": {"max_year_days": MAX_YEAR_DAYS,
                                  "minimum_gate_gap": MIN_GATE_GAP,
                                  "max_months": MAX_MONTHS,
                                  "max_cutlets": MAX_CUTLETS},
        "max_gaps_per_year": max_gaps,
        "max_endpoint_positions_per_half_window": max_endpoint_positions,
        "family_bounds": {name: {"bits": n.bit_length(), "sha256_uint_be": fingerprint(n),
                                 "fits_global_bound": n <= upper}
                          for name, n in families.items()},
        "upper_bound_expression": "47^5778",
        "upper_bound_bits": upper.bit_length(),
        "upper_bound_sha256_uint_be": fingerprint(upper),
        "upper_bound_is_exact_attainable_family_maximum": False,
        "wide_digits_needed_at_upper_bound": k,
        "space_bits": space.bit_length(),
        "M_times_upper_bound_bits": (M * upper).bit_length(),
        "conservative_limb_requirement": (needed + LIMB_BITS - 1) // LIMB_BITS,
        "limb_capacity": LIMB_COUNT,
        "classification": "STATIC_MATHEMATICAL_ENVELOPE_ONLY",
        "generic_choose_unbounded": True,
        "native_pass": False,
        "stage02_accepted": False,
        "historical_stage02_provenance_verified": False,
    }


class CanonicalEnvelopeTests(unittest.TestCase):
    def test_endpoints(self):
        self.assertEqual(MAX_YEAR_DAYS // MIN_GATE_GAP, 137)
        self.assertEqual((MAX_YEAR_DAYS // MIN_GATE_GAP + 1) ** 2, 19044)

    def test_family_combinatorial_caps(self):
        self.assertLess(math.factorial(47), 47 ** 5778)
        self.assertLess(1 << 5777, 47 ** 5778)
        self.assertLess(1 << 136, 47 ** 5778)

    def test_wide_minimal_k(self):
        upper = 47 ** 5778
        self.assertLess(M ** 252, upper)
        self.assertLessEqual(upper, M ** 253)

    def test_arithmetic_capacity(self):
        report = canonical_envelope()
        self.assertEqual(report["wide_digits_needed_at_upper_bound"], 253)
        self.assertLessEqual(report["conservative_limb_requirement"], 1100)
        self.assertEqual(len(report["family_bounds"]), 9)

    def test_scope_never_overstates_normative_semantics(self):
        report = canonical_envelope()
        self.assertTrue(report["generic_choose_unbounded"])
        self.assertFalse(report["upper_bound_is_exact_attainable_family_maximum"])
        self.assertFalse(report["native_pass"])
        self.assertFalse(report["stage02_accepted"])


def main():
    if sys.argv[1:] == ["--self-test"]:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(CanonicalEnvelopeTests)
        return 0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1
    if sys.argv[1:]:
        print("Usage: python stage02_canonical_family_envelope.py [--self-test]", file=sys.stderr)
        return 2
    print(json.dumps(canonical_envelope(), sort_keys=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
