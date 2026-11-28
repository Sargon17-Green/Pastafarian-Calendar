#!/usr/bin/env python3
"""Independent BigInt oracle for B04 C1-C6 using literal ring transitions.

This file deliberately imports no selector implementation, WAT fixture, or
oracle from another branch. It reconstructs the base-M digit stream, walks
the finite ring one transition at a time, and computes the accepted rank.
"""
import json

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
M = (1 << 127) - 1
U = M * M

CASES = (
    {"id": "C1", "n": M, "first": M, "step": -1,
     "export": "test_b04_c1_short_backward_m", "check_space": False},
    {"id": "C2", "n": M + 1, "first": M, "step": -1,
     "export": "test_b04_c2_wide_backward_m_plus_one", "check_space": True},
    {"id": "C3", "n": 2 * M, "first": 1, "step": -1,
     "export": "test_b04_c3_wide_backward_reject_2m", "check_space": True},
    {"id": "C4", "n": 3 * M, "first": 1, "step": -1,
     "export": "test_b04_c4_wide_backward_reject_3m", "check_space": True},
    {"id": "C5", "n": 2 * M, "first": M - 1, "step": 1,
     "export": "test_b04_c5_c6_parametric", "check_space": True},
    {"id": "C6", "n": 3 * M, "first": M - 1, "step": 1,
     "export": "test_b04_c5_c6_parametric", "check_space": True},
)


def ring_successor(value: int, step: int, modulus: int) -> int:
    if step == 1:
        return 1 if value == modulus else value + 1
    if step == -1:
        return modulus if value == 1 else value - 1
    raise ValueError("step must be -1 or +1")


def derive(case: dict) -> dict:
    n = case["n"]
    first = case["first"]
    step = case["step"]
    if n <= 0 or not (1 <= first <= M) or step not in (-1, 1):
        raise ValueError("invalid test input")

    k = 1
    space = M
    while space < n:
        space *= M
        k += 1
    if k > 2:
        raise AssertionError("B04 candidate unexpectedly exceeds k=2")
    if not (M ** (k - 1) < n <= space):
        raise AssertionError("k is not minimal")

    digits = []
    response = first
    for _ in range(k):
        digits.append(response)
        response = ring_successor(response, step, M)

    initial_x = 1
    weight = 1
    for digit in digits:
        initial_x += (digit - 1) * weight
        weight *= M
    if weight != space:
        raise AssertionError("digit-space mismatch")

    quotient, remainder = divmod(space, n)
    limit = quotient * n
    candidate = initial_x
    rejected = 0
    while candidate > limit:
        candidate = ring_successor(candidate, step, space)
        rejected += 1
        if rejected > 2:
            raise AssertionError("candidate exceeded the authorized two-step bound")

    result = ((candidate - 1) % n) + 1
    if not (1 <= result <= n):
        raise AssertionError("result outside [1,N]")

    return {
        "id": case["id"],
        "export": case["export"],
        "n": str(n),
        "first": str(first),
        "step": step,
        "k": k,
        "space": str(space),
        "q": str(quotient),
        "remainder": str(remainder),
        "limit": str(limit),
        "initial_x": str(initial_x),
        "accepted": str(candidate),
        "rejections": rejected,
        "result": str(result),
        "check_space": case["check_space"],
    }


def expected_formulae() -> dict:
    return {
        "C1": {"k": 1, "q": 1, "space": M, "limit": M,
               "initial_x": M, "accepted": M, "rejections": 0, "result": M},
        "C2": {"k": 2, "q": M - 1, "space": U, "limit": U - 1,
               "initial_x": U - M, "accepted": U - M,
               "rejections": 0, "result": 2},
        "C3": {"k": 2, "q": (M - 1) // 2, "space": U, "limit": U - M,
               "initial_x": U - M + 1, "accepted": U - M,
               "rejections": 1, "result": 2 * M},
        "C4": {"k": 2, "q": (M - 1) // 3, "space": U, "limit": U - M,
               "initial_x": U - M + 1, "accepted": U - M,
               "rejections": 1, "result": 3 * M},
        "C5": {"k": 2, "q": (M - 1) // 2, "space": U, "limit": U - M,
               "initial_x": U - 1, "accepted": 1,
               "rejections": 2, "result": 1},
        "C6": {"k": 2, "q": (M - 1) // 3, "space": U, "limit": U - M,
               "initial_x": U - 1, "accepted": 1,
               "rejections": 2, "result": 1},
    }


def main() -> None:
    derived = [derive(case) for case in CASES]
    expected = expected_formulae()
    for item in derived:
        for key, value in expected[item["id"]].items():
            actual = int(item[key]) if isinstance(item[key], str) else item[key]
            if actual != value:
                raise AssertionError(
                    item["id"] + ": " + key + " expected " + str(value)
                    + " but derived " + str(actual)
                )

    by_id = {item["id"]: item for item in derived}
    if by_id["C3"]["initial_x"] != by_id["C4"]["initial_x"]:
        raise AssertionError("C3/C4 shared boundary witness diverged")
    if by_id["C3"]["limit"] != by_id["C4"]["limit"]:
        raise AssertionError("C3/C4 shared limit diverged")
    if by_id["C3"]["result"] == by_id["C4"]["result"]:
        raise AssertionError("C3/C4 must distinguish N=2M from N=3M")
    if by_id["C5"]["initial_x"] != by_id["C6"]["initial_x"]:
        raise AssertionError("C5/C6 shared wrap witness diverged")
    if by_id["C5"]["q"] == by_id["C6"]["q"]:
        raise AssertionError("C5/C6 must exercise distinct quotients")
    if by_id["C5"]["limit"] != by_id["C6"]["limit"]:
        raise AssertionError("C5/C6 shared exact limit diverged")

    payload = {
        "project_id": PROJECT_ID,
        "oracle": "independent_bigint_literal_ring_walk",
        "M": str(M),
        "U": str(U),
        "cases": derived,
        "checks": {
            "case_count": len(derived),
            "max_literal_rejections": max(x["rejections"] for x in derived),
            "C3_C4_same_x_and_limit_distinct_result": True,
            "C5_C6_same_wrap_witness_distinct_q": True,
            "native_executed": False,
            "stage02_accepted": False,
        },
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()
