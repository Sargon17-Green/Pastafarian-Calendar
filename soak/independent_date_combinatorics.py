#!/usr/bin/env python3
"""Independent exact enumerative date primitives for Kotlin+Cymraeg research.

No production Kotlin code, pinned Python source, checkpoint, or external oracle
is imported. Component-level research only, not a full TABLETS date algorithm.
Bounded compositions: inclusion-exclusion; interior boundary: Vandermonde split;
distinct names: Lehmer coordinates; sauce rank: M-ary cyclic selection.
"""
from __future__ import annotations
from functools import lru_cache
from math import comb, perm

MODULUS = (1 << 127) - 1

class DateCombinatoricsError(ValueError):
    pass

def _choose(n: int, k: int) -> int:
    return comb(n, k) if 0 <= k <= n else 0

def count_bounded_compositions(total: int, slots: int, smallest: int, largest: int) -> int:
    """Count ordered tuples with smallest<=x_i<=largest and sum=total."""
    if (any(type(x) is not int for x in (total, slots, smallest, largest))
            or slots < 0 or smallest < 1 or largest < smallest or total < 0
            or slots > 47 or total > 5778):
        raise DateCombinatoricsError("E_BOUNDED_SHAPE")
    # Validate before cache lookup: bools can otherwise alias ints.
    return _count_bounded_compositions(total, slots, smallest, largest)

@lru_cache(maxsize=32000)
def _count_bounded_compositions(total: int, slots: int, smallest: int, largest: int) -> int:
    if slots == 0:
        return int(total == 0)
    excess = total - slots * smallest
    width = largest - smallest + 1
    if excess < 0 or total > slots * largest:
        return 0
    answer = 0
    for excluded in range(min(slots, excess // width) + 1):
        term = _choose(slots, excluded) * _choose(
            excess - excluded * width + slots - 1, slots - 1)
        answer += -term if excluded % 2 else term
    if answer < 0:
        raise DateCombinatoricsError("E_BOUNDED_NEGATIVE")
    return answer

def unrank_bounded_composition(total: int, slots: int, smallest: int,
                               largest: int, rank1: int) -> tuple[int, ...]:
    size = count_bounded_compositions(total, slots, smallest, largest)
    if type(rank1) is not int or not 1 <= rank1 <= size:
        raise DateCombinatoricsError("E_BOUNDED_RANK")
    remaining, rank = total, rank1
    output = []
    for available in range(slots, 0, -1):
        selected = None
        low = max(smallest, remaining - (available - 1) * largest)
        high = min(largest, remaining - (available - 1) * smallest)
        for candidate in range(low, high + 1):
            block = count_bounded_compositions(
                remaining - candidate, available - 1, smallest, largest)
            if rank > block:
                rank -= block
            else:
                selected = candidate
                break
        if selected is None:
            raise DateCombinatoricsError("E_BOUNDED_UNRANK")
        output.append(selected)
        remaining -= selected
    if remaining != 0 or rank != 1:
        raise DateCombinatoricsError("E_BOUNDED_POSTCONDITION")
    return tuple(output)

def count_cutlet_partitions(total_gaps: int, cutlets: int,
                            required_boundary: int | None = None) -> int:
    """Count positive compositions with a mandatory interior prefix if given."""
    if (type(total_gaps) is not int or type(cutlets) is not int
            or not 1 <= total_gaps <= 5778 or not 1 <= cutlets <= 17
            or (required_boundary is not None and
                (type(required_boundary) is not int or
                 not 1 <= required_boundary < total_gaps))):
        raise DateCombinatoricsError("E_CUTLET_SHAPE")
    if total_gaps < cutlets:
        return 0
    if required_boundary is None:
        return _choose(total_gaps - 1, cutlets - 1)
    # A strictly positive composition hits an interior prefix at most once.
    return sum(_choose(required_boundary - 1, left - 1) *
               _choose(total_gaps - required_boundary - 1, cutlets - left - 1)
               for left in range(1, cutlets))

def unrank_cutlet_partition(total_gaps: int, cutlets: int,
                            required_boundary: int | None, rank1: int) -> tuple[int, ...]:
    count = count_cutlet_partitions(total_gaps, cutlets, required_boundary)
    if type(rank1) is not int or not 1 <= rank1 <= count:
        raise DateCombinatoricsError("E_CUTLET_RANK")
    remaining, available, boundary, rank = total_gaps, cutlets, required_boundary, rank1
    out = []
    while available:
        chosen = None
        for amount in range(1, remaining - available + 2):
            if boundary is not None and amount > boundary:
                break
            tail = None if boundary is None or amount == boundary else boundary - amount
            ways = (int(remaining - amount == 0 and tail is None)
                    if available == 1 else
                    (0 if tail is not None and not 1 <= tail < remaining - amount
                     else count_cutlet_partitions(remaining - amount, available - 1, tail)))
            if rank > ways:
                rank -= ways
            else:
                chosen, boundary = amount, tail
                break
        if chosen is None:
            raise DateCombinatoricsError("E_CUTLET_UNRANK")
        out.append(chosen)
        remaining -= chosen
        available -= 1
    if remaining != 0 or boundary is not None or rank != 1:
        raise DateCombinatoricsError("E_CUTLET_POSTCONDITION")
    return tuple(out)

def unrank_distinct_names(pool: int, count: int, rank1: int) -> tuple[int, ...]:
    if (type(pool) is not int or type(count) is not int or
            not 1 <= pool <= 47 or not 0 <= count <= pool):
        raise DateCombinatoricsError("E_NAMES_SHAPE")
    universe = list(range(1, pool + 1))
    family = perm(pool, count)
    if type(rank1) is not int or not 1 <= rank1 <= family:
        raise DateCombinatoricsError("E_NAMES_RANK")
    digits = rank1 - 1
    result = []
    for position in range(count):
        block = perm(pool - position - 1, count - position - 1)
        digit, digits = divmod(digits, block)
        result.append(universe.pop(digit))
    return tuple(result)

def cyclic_rank(first: int, direction: int, modulus: int, size: int) -> int:
    """Exact cyclic rank with algebraic rejection-tail skipping."""
    if (any(type(x) is not int for x in (first, direction, modulus, size))
            or modulus < 2 or not 1 <= first <= modulus or direction not in (-1, 1)
            or not 1 <= size <= modulus ** 256):
        raise DateCombinatoricsError("E_CYCLE_SHAPE")
    width, digits = modulus, 1
    while width < size:
        width *= modulus
        digits += 1
    value, weight = 1, 1
    for offset in range(digits):
        value += ((first - 1 + direction * offset) % modulus) * weight
        weight *= modulus
    accepted_upper = (width // size) * size
    if value > accepted_upper:
        value = 1 if direction == 1 else accepted_upper
    return (value - 1) % size + 1

def rank_from_sauce(witness, bowl: int, seal: int, family_count: int) -> int:
    """Derive a sealed rank from a structurally independent bowl witness."""
    if (type(bowl) is not int or not 1 <= bowl <= 6
            or type(seal) is not int or not 1 <= seal <= 255
            or type(family_count) is not int or family_count < 1):
        raise DateCombinatoricsError("E_SAUCE_RANK_SHAPE")
    order = getattr(witness, "order_at_drop_46", None)
    bowls = getattr(witness, "bowls", None)
    if (type(order) is not tuple or len(order) != 6 or set(order) != set(range(1, 7))
            or type(bowls) is not tuple or len(bowls) != 7
            or any(type(v) is not int or not 1 <= v <= MODULUS for v in bowls[1:])):
        raise DateCombinatoricsError("E_SAUCE_WITNESS")
    neighbor = order[(order.index(bowl) + 1) % 6]
    first = 1 + (((bowls[bowl] + seal + 181) ** 2 +
                  179 * bowls[neighbor] + seal - 1) % MODULUS)
    parity = 1 + (((first + seal + 194) ** 2 + 193 * first +
                   197 * bowls[6] - 1) % MODULUS)
    return cyclic_rank(first, 1 if parity % 2 else -1, MODULUS, family_count)
