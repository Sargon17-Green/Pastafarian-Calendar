#!/usr/bin/env python3
"""Independent arithmetic oracle for bounded k=3 wide-ring rejection probes.

No WAT runtime is imported or executed. This covers one-step boundary behavior,
not an end-to-end rejection path for a generated three-digit selector sample.
"""

M = (1 << 127) - 1
N = M * M + 1
SPACE = M**3
Q, REM = divmod(SPACE, N)
LIMIT = Q * N


def step(x: int, direction: int) -> int:
    assert 1 <= x <= SPACE and direction in (-1, 1)
    return 1 + ((x - 1 + direction) % SPACE)


def rank(x: int) -> int:
    assert 1 <= x <= LIMIT
    return 1 + ((x - 1) % N)


def main() -> None:
    cases = [
        ("quotient_and_remainder", Q == M - 1 and REM == M * M - M + 1),
        ("limit_formula", LIMIT == (M - 1) * N and SPACE - LIMIT == REM),
        ("l_plus_one_backward", LIMIT < LIMIT + 1 <= SPACE and step(LIMIT + 1, -1) == LIMIT and rank(LIMIT) == N),
        ("space_forward_wrap", SPACE > LIMIT and step(SPACE, 1) == 1 and rank(1) == 1),
        ("one_backward_wrap", step(1, -1) == SPACE and SPACE > LIMIT),
        ("limit_bidirectional", step(LIMIT, 1) == LIMIT + 1 and step(LIMIT + 1, -1) == LIMIT and step(LIMIT, -1) == LIMIT - 1 and rank(LIMIT - 1) == N - 1),
    ]
    for name, ok in cases:
        assert ok, name
        print(f"PASS {name}")
    print(f"ORACLE {len(cases)}/{len(cases)} PASS")


if __name__ == "__main__":
    main()
