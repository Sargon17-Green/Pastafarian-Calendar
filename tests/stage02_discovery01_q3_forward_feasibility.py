#!/usr/bin/env python3
"""Independent feasibility QA for Stage02 DISCOVERY01, q=3, k=3.

No WAT execution. Checks the mathematical input family of normative_selector.wat:
M=2**127-1, first in [1,M], step in {-1,+1}, ring digits
  a_j = 1 + ((first-1+j*step) % M), x=1+sum((a_j-1)*M**j).
"""

import json


def wide_x(m: int, first: int, step: int) -> int:
    assert m >= 4 and 1 <= first <= m and step in (-1, 1)
    digits = [1 + ((first - 1 + j * step) % m) for j in range(3)]
    return 1 + sum((digit - 1) * (m ** j) for j, digit in enumerate(digits))


def closed_form_forward(m: int, first: int) -> int:
    if first <= m - 2:
        return first * (m * m + m + 1) + m * m
    if first == m - 1:
        return m * m - 1
    return m * m + m


def run() -> dict:
    small_m = (4, 7, 10, 13, 19, 31, 43)
    counts = {}
    examined = 0
    q3_windows = 0
    backward_witnesses = 0
    for m in small_m:
        assert m % 3 == 1
        space = m ** 3
        valid_n = [n for n in range(m * m + 1, space + 1) if space // n == 3]
        assert valid_n, m
        q3_windows += len(valid_n)
        checked_this = 0
        for first in range(1, m + 1):
            x = wide_x(m, first, +1)
            assert x == closed_form_forward(m, first)
            for n in valid_n:
                assert x != 3 * n, (m, first, n)
                checked_this += 1
        counts[str(m)] = {"q3_n_values": len(valid_n),
                          "forward_first_N_pairs": checked_this}
        examined += checked_this
        if m >= 7:
            x = wide_x(m, 1, -1)
            assert x == space - m * m - m + 1
            assert x % 3 == 0
            n = x // 3
            assert n > m * m and space // n == 3 and x == 3 * n
            backward_witnesses += 1

    m = 2 ** 127 - 1
    assert m % 3 == 1
    assert (m * m + m + 1) % 3 == 0
    assert m * m % 3 == 1
    for first in (1, 2, m // 2, m - 2, m - 1, m):
        x = wide_x(m, first, +1)
        assert x == closed_form_forward(m, first)
        if first <= m - 2:
            assert x % 3 == 1
        else:
            assert x < 3 * (m * m + 1)
    x_backward = wide_x(m, 1, -1)
    assert x_backward == m ** 3 - m * m - m + 1
    assert x_backward % 3 == 0
    n_backward = x_backward // 3
    assert n_backward > m * m and (m ** 3) // n_backward == 3
    assert x_backward == 3 * n_backward

    return {
        "project_id": "PC-BRANCH-WAT-SPANISH",
        "test_type": "mathematical_feasibility_not_native",
        "small_M_exhaustive": counts,
        "total_small_M_forward_pairs": examined,
        "q3_n_windows": q3_windows,
        "small_M_backward_equality_witnesses": backward_witnesses,
        "production_M_bits": m.bit_length(),
        "production_forward_q3_limit_equality": "PROVEN_IMPOSSIBLE",
        "production_backward_q3_limit_equality": "WITNESS_VERIFIED",
        "pass": True,
    }


if __name__ == "__main__":
    print(json.dumps(run(), ensure_ascii=False, sort_keys=True, indent=2))
