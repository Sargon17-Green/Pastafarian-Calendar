#!/usr/bin/env python3
"""Independent mathematical oracle for FALSE+العربية Stage22 / normative operation 56.

This is a design oracle only. It does not import production code, the Stage21
harness, the normative interpreter, or code from another language branch.
"""
from __future__ import annotations
import itertools
import json
from collections import Counter

M = (1 << 127) - 1
PERMS = list(itertools.permutations(range(1, 7)))
SEED_INITIAL = 0x56002226


def save_exact(value: int) -> int:
    if value <= 0:
        raise ValueError("SAVE input must be positive")
    return 1 + ((value - 1) % M)


def fold_mersenne(value: int) -> int:
    if value <= 0:
        raise ValueError("fold input must be positive")
    while value > M:
        value = (value & M) + (value >> 127)
    return value


def unrank_factoradic(rank: int) -> tuple[int, ...]:
    if not 1 <= rank <= 720:
        raise ValueError("permutation rank outside 1..720")
    remainder = rank - 1
    pool = [1, 2, 3, 4, 5, 6]
    result = []
    for factorial in (120, 24, 6, 2, 1, 1):
        digit, remainder = divmod(remainder, factorial)
        result.append(pool.pop(digit))
    return tuple(result)


def round_exact(bowls: list[int], batch: int):
    """Permutation-table + exact-modulo implementation."""
    old = list(bowls)
    total = save_exact(sum(old) + 6 + 149 * batch)
    rank = 4 + ((total - 4) % 7)
    order = PERMS[rank - 1]
    position = {bowl_id: p for p, bowl_id in enumerate(order, start=1)}
    new = [0] * 6
    for bowl_id in range(1, 7):
        p = position[bowl_id]
        left_id = order[(p - 2) % 6]
        right_id = order[p % 6]
        left = old[left_id - 1]
        right = old[right_id - 1]
        value = (
            old[bowl_id - 1] ** 2
            + 3 * left
            + 5 * right
            + total
            + batch
            + p * p
            + 7 * left * right
        )
        new[bowl_id - 1] = save_exact(value)
    return new, order, total, rank


def round_fold(bowls: list[int], batch: int):
    """Factoradic permutation + Mersenne folding implementation."""
    old = list(bowls)
    total = fold_mersenne(sum(old) + 6 + 149 * batch)
    rank = 4 + ((total - 4) % 7)
    order = unrank_factoradic(rank)
    ring = [old[bowl_id - 1] for bowl_id in order]
    position = {bowl_id: p for p, bowl_id in enumerate(order, start=1)}
    new = [0] * 6
    for bowl_id in range(1, 7):
        p = position[bowl_id]
        left = ring[(p - 2) % 6]
        right = ring[p % 6]
        value = (
            old[bowl_id - 1] ** 2
            + 3 * left
            + 5 * right
            + total
            + batch
            + p * p
            + 7 * left * right
        )
        new[bowl_id - 1] = fold_mersenne(value)
    return new, order, total, rank


def run_exact(initial: list[int]):
    state = list(initial)
    trace = []
    for batch in range(1, 13):
        state, order, total, rank = round_exact(state, batch)
        trace.append({
            "batch": batch,
            "total": str(total),
            "rank": rank,
            "order": list(order),
            "bowls": [str(value) for value in state],
        })
    return state, trace


def xorshift_cases():
    seed = SEED_INITIAL

    def random_bigint():
        nonlocal seed
        value = 0
        for _ in range(4):
            seed ^= (seed << 13) & 0xFFFFFFFF
            seed &= 0xFFFFFFFF
            seed ^= seed >> 17
            seed &= 0xFFFFFFFF
            seed ^= (seed << 5) & 0xFFFFFFFF
            seed &= 0xFFFFFFFF
            value = (value << 32) + seed
        return (value & M) or 1

    return [[random_bigint() for _ in range(6)] for _ in range(384)]


def anchor_cases():
    return [
        [1, 1, 1, 1, 1, 1],
        [M, M, M, M, M, M],
        [2, 3, 5, 7, 11, 13],
        [M, 1, M - 1, 2, 3, M - 2],
        [511, 512, 513, 262143, 262144, M],
        [720, 720, 720, 720, 720, 720],
        [4, 4, 4, 4, 4, 4],
        [1, 2, 3, 4, 5, 6],
        [M - 1, M - 1, M - 1, M - 1, M - 1, M - 1],
        [M, M, M, M, M, M - 1],
        [(1 << 126) + i for i in range(6)],
        [512 ** i for i in range(1, 7)],
        [M // 2, M // 2 + 1, M // 3 + 1, M // 5 + 1, M // 7 + 1, M // 11 + 1],
    ]


def wrong_round(bowls: list[int], batch: int, mutation: str):
    old = list(bowls)
    multiplier = 148 if mutation == "t_offset" else 149
    total = save_exact(sum(old) + 6 + multiplier * batch)
    modulus = 6 if mutation == "rank_mod6" else 7
    rank = 4 + ((total - 4) % modulus)
    order = PERMS[rank - 1]
    position = {bowl_id: p for p, bowl_id in enumerate(order, start=1)}
    new = [0] * 6
    for bowl_id in range(1, 7):
        p = position[bowl_id]
        left_id = order[(p - 2) % 6]
        right_id = order[p % 6]
        left = old[left_id - 1]
        right = old[right_id - 1]
        left_weight, right_weight = (5, 3) if mutation == "swap_neighbor_weights" else (3, 5)
        position_term = 0 if mutation == "omit_p_squared" else p * p
        cross_weight = 6 if mutation == "cross_6LR" else 7
        value = (
            old[bowl_id - 1] ** 2
            + left_weight * left
            + right_weight * right
            + total
            + batch
            + position_term
            + cross_weight * left * right
        )
        new[bowl_id - 1] = save_exact(value)
    return new, order, total, rank


def main():
    cases = anchor_cases() + xorshift_cases()
    assert len(cases) == 397
    assert all(len(case) == 6 and all(1 <= value <= M for value in case) for case in cases)

    transitions = comparisons = range_checks = fold_checks = 0
    immutable_inputs = 0
    rank_counts = Counter()
    digest = 0
    mask64 = (1 << 64) - 1

    for case_index, initial in enumerate(cases):
        original = tuple(initial)
        exact_state = list(initial)
        fold_state = list(initial)
        for batch in range(1, 13):
            exact_next, exact_order, exact_total, exact_rank = round_exact(exact_state, batch)
            fold_next, fold_order, fold_total, fold_rank = round_fold(fold_state, batch)
            assert exact_next == fold_next, (case_index, batch, "state mismatch")
            assert exact_order == fold_order, (case_index, batch, "order mismatch")
            assert exact_total == fold_total, (case_index, batch, "total mismatch")
            assert exact_rank == fold_rank and 4 <= exact_rank <= 10
            rank_counts[exact_rank] += 1
            for value in exact_next:
                assert 1 <= value <= M
                assert fold_mersenne(value) == save_exact(value)
                range_checks += 1
                fold_checks += 1
                comparisons += 1
                digest = (digest * 1099511628211 + value) & mask64
            exact_state = exact_next
            fold_state = fold_next
            transitions += 1
        assert tuple(initial) == original
        immutable_inputs += 1

    for rank in range(1, 721):
        assert unrank_factoradic(rank) == PERMS[rank - 1]

    replay_a = run_exact(cases[2])
    replay_b = run_exact(cases[2])
    assert replay_a == replay_b

    witness_input = anchor_cases()[2]
    expected, expected_order, expected_total, expected_rank = round_exact(witness_input, 1)
    wrong_witnesses = []
    for mutation in ("t_offset", "rank_mod6", "swap_neighbor_weights", "omit_p_squared", "cross_6LR"):
        observed, order, total, rank = wrong_round(witness_input, 1, mutation)
        first = next(index for index, (good, bad) in enumerate(zip(expected, observed)) if good != bad)
        wrong_witnesses.append({
            "mutation": mutation,
            "first_bowl_id": first + 1,
            "expected": str(expected[first]),
            "observed": str(observed[first]),
            "first_mismatch_is_numeric": True,
            "mutated_rank": rank,
            "mutated_order": list(order),
        })
    assert all(item["expected"] != item["observed"] for item in wrong_witnesses)

    result = {
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": 22,
        "status": "DESIGN_ORACLE_PASS_NOT_NATIVE",
        "normative_operation": 56,
        "planned_production_operation": 39,
        "cases": len(cases),
        "anchors": 13,
        "seeded_cases": 384,
        "batches_per_case": 12,
        "transitions": transitions,
        "numeric_comparisons": comparisons,
        "range_checks": range_checks,
        "mersenne_fold_equivalence_checks": fold_checks,
        "immutable_input_checks": immutable_inputs,
        "factoradic_rank_checks": 720,
        "rank_counts": {str(k): rank_counts[k] for k in sorted(rank_counts)},
        "replay_identical": True,
        "rolling_digest": f"0x{digest:016x}",
        "witness": {
            "input_bowls": [str(value) for value in witness_input],
            "first_batch_total": str(expected_total),
            "first_batch_rank": expected_rank,
            "first_batch_order": list(expected_order),
            "first_batch_output": [str(value) for value in expected],
        },
        "wrong_algorithm_witnesses": wrong_witnesses,
        "native_run": "NOT_RUN",
        "production_implementation": "NOT_STARTED",
    }
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
