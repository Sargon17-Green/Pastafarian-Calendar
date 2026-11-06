#!/usr/bin/env python3
"""SQL+தமிழ் Slice24: independent structure-composition feasibility oracle.

Does not import, query, or copy SQL implementations or normative fixtures.
Synthetic records establish structural laws only, NOT PG17 native golden values.
Run: python3 sql/test/140_stage02_year_structure_preflight.py --self-test
"""
from __future__ import annotations
import argparse
import hashlib
import json
from collections import Counter
from dataclasses import dataclass, replace
from typing import NamedTuple


class Year(NamedTuple):
    year_number: int
    open_gate_index: int
    close_gate_index: int
    open_gate_day: int
    close_gate_day: int


@dataclass(frozen=True)
class Structure:
    year_data: Year
    cutlet_count: int
    cutlet_partition: tuple[int, ...]
    cutlet_name_indices: tuple[int, ...]
    month_count: int
    month_lengths: tuple[int, ...]
    month_weaving: tuple[int, ...]
    month_name_indices: tuple[int, ...]


FIELD_ORDER = (
    'year_data', 'cutlet_count', 'cutlet_partition', 'cutlet_name_indices',
    'month_count', 'month_lengths', 'month_weaving', 'month_name_indices'
)


class InvalidStructure(ValueError):
    pass


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise InvalidStructure(reason)


def structural_oracle(s: Structure) -> None:
    """Independent, type-and-cardinality validation of one *complete* record."""
    require(tuple(s.__dataclass_fields__) == FIELD_ORDER, 'field_order')
    y = s.year_data
    require(isinstance(y, Year) and len(y) == 5, 'year_rec_type')
    require(all(type(x) is int for x in y), 'year_rec_integer')
    g = y.close_gate_index - y.open_gate_index
    d = y.close_gate_day - y.open_gate_day
    require(g >= 6 and 252 <= d <= 5778 and 42 * g <= d <= 963 * g, 'year_bounds')
    require(type(s.cutlet_count) is int and 6 <= s.cutlet_count <= min(g, 17), 'cutlet_count')
    require(len(s.cutlet_partition) == s.cutlet_count and
            all(type(x) is int and x > 0 for x in s.cutlet_partition) and
            sum(s.cutlet_partition) == g, 'cutlet_partition')
    require(len(s.cutlet_name_indices) == s.cutlet_count and
            len(set(s.cutlet_name_indices)) == s.cutlet_count and
            all(type(x) is int and 1 <= x <= 17 for x in s.cutlet_name_indices), 'cutlet_names')
    lo = (d + 122) // 123
    hi = min(47, d // 4)
    require(type(s.month_count) is int and lo <= s.month_count <= hi, 'month_count')
    require(len(s.month_lengths) == s.month_count and
            all(type(x) is int and 4 <= x <= 123 for x in s.month_lengths) and
            sum(s.month_lengths) == d, 'month_lengths')
    require(len(s.month_weaving) == d and
            all(type(x) is int and 1 <= x <= s.month_count for x in s.month_weaving), 'month_weaving_domain')
    counts = Counter(s.month_weaving)
    require(all(counts[i] == length for i, length in enumerate(s.month_lengths, 1)), 'month_weaving_multiplicity')
    require(len(s.month_name_indices) == s.month_count and
            len(set(s.month_name_indices)) == s.month_count and
            all(type(x) is int and 1 <= x <= 47 for x in s.month_name_indices), 'month_names')


def balanced_parts(total: int, count: int, minimum: int, maximum: int) -> tuple[int, ...]:
    require(count > 0 and minimum * count <= total <= maximum * count, 'parts_feasibility')
    parts = [minimum] * count
    remainder = total - minimum * count
    for i in range(count):
        take = min(maximum - minimum, remainder)
        parts[i] += take
        remainder -= take
    require(remainder == 0, 'parts_remainder')
    return tuple(parts)


def construct_synthetic(year_number: int, g: int, d: int, k: int, m: int) -> Structure:
    """Independent constituent records, not outputs of production selectors."""
    year = Year(year_number, 1000 + year_number * 100, 1000 + year_number * 100 + g,
                -15055671 + year_number * 6000, -15055671 + year_number * 6000 + d)
    cutlets = balanced_parts(g, k, 1, g)
    months = balanced_parts(d, m, 4, 123)
    remaining = list(months)
    weaving = []
    while any(remaining):
        for idx in range(m):
            if remaining[idx] > 0:
                weaving.append(idx + 1)
                remaining[idx] -= 1
    # Name choices are fixed independent input arrays, not inferred from any SQL run.
    return Structure(year, k, cutlets, tuple(range(17, 17-k, -1)),
                     m, months, tuple(weaving), tuple(range(m, 0, -1)))


CASES = (
    # Shape coverage: shortest year, 6/17 cutlets, 3/47 months, max days.
    (5000, 6, 252, 6, 3),
    (5001, 7, 294, 7, 3),
    (5002, 8, 480, 6, 5),
    (5003, 9, 738, 8, 7),
    (5004, 11, 1353, 9, 12),
    (5005, 13, 2460, 11, 20),
    (5006, 17, 4491, 17, 37),
    (5007, 17, 5778, 17, 47),
)


def full_payload(s: Structure) -> dict:
    return {field: list(getattr(s, field)) if field != 'year_data' and isinstance(getattr(s, field), tuple)
            else list(s.year_data) if field == 'year_data' else getattr(s, field)
            for field in FIELD_ORDER}


def self_test() -> None:
    structural_checks = 0
    mutation_checks = 0
    fixtures = []
    for label, args in enumerate(CASES, 1):
        s = construct_synthetic(*args)
        structural_oracle(s)
        structural_checks += 1
        digest = hashlib.sha256(json.dumps(full_payload(s), separators=(',', ':')).encode()).hexdigest()
        fixtures.append((f'synthetic_{label}', args[2], args[4], digest))
        changes = (
            replace(s, cutlet_count=s.cutlet_count + 1),
            replace(s, cutlet_partition=s.cutlet_partition[:-1]),
            replace(s, cutlet_name_indices=(1,) * s.cutlet_count),
            replace(s, month_count=s.month_count + 1),
            replace(s, month_lengths=s.month_lengths[:-1]),
            replace(s, month_weaving=s.month_weaving[:-1]),
            replace(s, month_name_indices=(1,) * s.month_count),
            replace(s, year_data=s.year_data._replace(close_gate_day=s.year_data.open_gate_day + 251)),
        )
        for bad in changes:
            try:
                structural_oracle(bad)
            except InvalidStructure:
                mutation_checks += 1
            else:
                raise AssertionError('mutation wrongly accepted')
    # Independent exact small-domain feasibility sweep (no SQL and no random data).
    exhaustive = 0
    for g in range(6, 12):
        for d in (252, 294, 360, 492):
            if not 42*g <= d <= 963*g:
                continue
            for k in range(6, min(17, g)+1):
                for m in range((d + 122)//123, min(7, d//4)+1):
                    structural_oracle(construct_synthetic(6000 + exhaustive, g, d, k, m))
                    exhaustive += 1
    assert structural_checks == 8 and mutation_checks == 64 and exhaustive > 0
    print('slice24_synthetic_full_records=8 PASS')
    print('slice24_negative_mutations=64 PASS')
    print(f'slice24_exhaustive_small_compositions={exhaustive} PASS')
    print('slice24_provenance=synthetic_only; not_runtime_year_inputs; not_native_pg17')
    for label, d, m, digest in fixtures:
        print(f'{label}: day_count={d}, month_count={m}, record_sha256={digest}')


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--self-test', action='store_true', required=True)
    p.parse_args()
    self_test()