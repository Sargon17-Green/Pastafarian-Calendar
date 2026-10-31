#!/usr/bin/env python3
"""Independent, bounded structural sauce evaluator for Kotlin post-55 research.

No imports or intermediate results from the implementation under comparison.
Separate representations: simultaneous vector recurrences, direct offset-indexed
history, lexicographic permutation enumeration and immutable bowl rounds.
This oracle is diagnostic only, never full-date certification.
"""
from __future__ import annotations
from dataclasses import dataclass
from itertools import permutations
from time import monotonic

FOUNDATION = -15055671
MODULUS = (1 << 127) - 1
_ORDERS = tuple(permutations(range(1, 7)))
_VISIBLE = (
    (3, 5, 7, 11, 0), (5, 7, 11, 13, 1), (7, 11, 13, 17, 2),
    (11, 13, 17, 19, 3), (13, 17, 19, 23, 4), (17, 19, 23, 29, 0),
    (19, 23, 29, 31, 1), (23, 29, 31, 37, 2), (29, 31, 37, 41, 3),
    (31, 37, 41, 43, 4), (37, 41, 43, 47, 0),
)
_HIDDEN_COEFF = ((3, 4, 6, 8), (5, 7, 10, 12), (7, 10, 14, 16),
                 (9, 13, 18, 20), (11, 16, 22, 24),
                 (13, 19, 26, 28), (15, 22, 30, 32))
_HIDDEN_KIND = (0, 1, 2, 3, 4, 0, 1)
_BOWL_PRIME = (17, 19, 23, 29, 31, 37)
_BOWL_STONE = (0, 1, 2, 3, 4, 0)


class SauceOracleError(ValueError):
    pass


@dataclass(frozen=True)
class SauceWitness:
    bowls: tuple[int, ...]
    order_at_drop_46: tuple[int, ...]
    stone_46: tuple[int, ...]
    hidden_by_nearness: tuple[int, ...]
    visible_46: int
    bowls_after_drops: tuple[int, ...]
    post_stir_12: tuple[int, ...]
    independent_sauce: bool = True
    certified: bool = False


def _save(number: int) -> int:
    # The wrap point is M, not zero. No call to legacy savePatch.
    return 1 + ((number - 1) % MODULUS)


def _order_from_rank(number: int) -> tuple[int, ...]:
    # Exhaustive lexicographic list of 720 permutations, not factoradic unranking.
    return _ORDERS[(number - 1) % 720]


def evaluate(calculation_day: int, target_day: int, *, deadline: float | None = None) -> SauceWitness:
    if type(calculation_day) is not int or type(target_day) is not int:
        raise SauceOracleError('E_SAUCE_INPUT')

    def check() -> None:
        if deadline is not None and monotonic() >= deadline:
            raise SauceOracleError('E_SAUCE_DEADLINE')

    check()
    tag = lambda day: 2 * abs(day - FOUNDATION) + int(day >= FOUNDATION)
    action, target = tag(calculation_day), tag(target_day)
    distance = abs(calculation_day - target_day) + 1
    connection = action + target
    direction = 1 if target_day < calculation_day else 2 if target_day == calculation_day else 3
    counts = (action, target, distance, connection, direction)

    # Jacobi-style simultaneous state transition, never in-place updates.
    stones: dict[int, tuple[int, ...]] = {1: (17, 29, 43, 71, 101)}
    factors = (3, 5, 7, 11, 13)
    for i in range(2, 47):
        check()
        old = stones[i - 1]
        stones[i] = tuple(_save(old[j] ** 2 + factors[j] * old[(j + 1) % 5]
                                + (i if j == 0 else old[j - 1])) for j in range(5))

    # Hidden drops use a direct nearness dictionary, not reversed storage.
    hidden = {}
    for k, (a, b, c, d) in enumerate(_HIDDEN_COEFF, 1):
        check()
        x = _save(action + a*target + b*distance + c*connection + d*direction + sum(stones[k]))
        for grind, kind in enumerate(_HIDDEN_KIND, 1):
            x = _save(x*x + 3*x + stones[k][kind] + grind)
        hidden[k] = x

    # Offsets below one address hidden drops; positive offsets address visible.
    drops: dict[int, int] = {}
    for i in range(1, 47):
        check()
        prev = tuple(drops[i - back] if i > back else hidden[1 + back - i]
                     for back in (1, 3, 7))
        x = _save(sum(a*b for a, b in zip(stones[i], counts))
                  + prev[0] + 3*prev[1] + 5*prev[2] + i)
        for a, b, c, d, kind in _VISIBLE:
            x = _save(x*x + a*x + b*prev[0] + c*prev[1]
                      + d*prev[2] + stones[i][kind])
        drops[i] = x
    drop_orders = {i: _order_from_rank(drops[i]) for i in range(1, 47)}
    latch = drop_orders[46]

    bowls: dict[int, int] = {}
    for id_, prime in enumerate(_BOWL_PRIME, 1):
        temp = action + target*id_ + distance + connection + direction + prime**2
        bowls[id_] = _save(temp**2 + id_)

    for i in range(1, 47):
        check()
        old = bowls
        order = drop_orders[i]
        pours = {}
        for pos in (1, 2, 3):
            pours[pos] = _save(drops[i]**2 + stones[i][pos-1]*old[order[pos-1]]
                               + (2*pos + 1)*i)
        fresh = {}
        for off, id_ in enumerate(order):
            previous_id = order[(off - 1) % 6]
            next_id = order[(off + 1) % 6]
            position = off + 1
            s = (old[id_] + 2*old[previous_id] + 3*old[next_id]
                 + pours.get(position, 0) + drops[i] + stones[i][_BOWL_STONE[off]])
            fresh[id_] = _save(s*s + 5*old[previous_id]*old[next_id] + i*position)
        bowls = fresh
    after_drops = (0,) + tuple(bowls[i] for i in range(1, 7))

    for stir in range(1, 13):
        check()
        old = bowls
        saved_sum = _save(sum(old.values()) + 149*stir)
        order = _order_from_rank(saved_sum)
        fresh = {}
        for off, id_ in enumerate(order):
            prev_id, next_id = order[(off - 1) % 6], order[(off + 1) % 6]
            s = (old[id_] + 3*old[prev_id] + 5*old[next_id]
                 + saved_sum + stir + (off+1)**2)
            fresh[id_] = _save(s*s + 7*old[prev_id]*old[next_id])
        bowls = fresh
    final = (0,) + tuple(bowls[i] for i in range(1, 7))
    return SauceWitness(final, latch, stones[46],
                        tuple(hidden[i] for i in range(1, 8)), drops[46],
                        after_drops, final)


def gap_from_witness(witness: SauceWitness) -> int:
    """Independent rejection-sampling result from structural oracle state."""
    if not isinstance(witness, SauceWitness) or not witness.independent_sauce:
        raise SauceOracleError('E_SAUCE_WITNESS')
    order = witness.order_at_drop_46
    if len(order) != 6 or set(order) != set(range(1, 7)):
        raise SauceOracleError('E_SAUCE_LATCH')
    next_to_one = order[(order.index(1) + 1) % 6]
    bowls = witness.bowls
    if len(bowls) != 7 or any(type(x) is not int or not 1 <= x <= MODULUS for x in bowls[1:]):
        raise SauceOracleError('E_SAUCE_BOWLS')
    first = _save((bowls[1] + 182)**2 + 179*bowls[next_to_one] + 1)
    parity = _save((first + 195)**2 + 193*first + 197*bowls[6])
    accepted_limit = (MODULUS // 922) * 922
    direction = 1 if parity % 2 else -1
    accepted = first if first <= accepted_limit else (1 if direction == 1 else accepted_limit)
    return 42 + ((accepted - 1) % 922)
