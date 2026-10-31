#!/usr/bin/env python3
"""QA31F: bounded original-source incoming edge at x(235,23); NOT Native."""
import hashlib
import json
from pathlib import Path

BLOB_SHA = "560d6aa5807a7f766213a33835cce85eab0fa40c"
SOURCE = Path(__file__).resolve().parents[1] / "src" / "interleaved_work_counts.b98"
TARGETS = {(10, 5), (10, 26), (10, 44)}
OPCODES = {20: {10: ">", 57: "g", 89: "j", 150: "x", 211: "x"},
           23: {10: ">", 57: "g", 81: chr(96), 113: "j", 174: "x", 235: "x"}}


def verify_source_shape(rows):
    for y, cells in OPCODES.items():
        for x, expected in cells.items():
            assert len(rows[y]) > x and rows[y][x] == expected, (
                "source opcode changed", x, y, expected)


def run_model(rows, counter3, counter1):
    """Counterfactual entry (10,20), empty stack, zero offset, static code."""
    x, y, dx, dy = 10, 20, 1, 0
    stack, events = [], []

    def pop():
        return stack.pop() if stack else 0

    for tick in range(1, 500):
        assert y in (20, 23) and 0 <= x < len(rows[y]), (
            "unexpected execution path", x, y, counter3, counter1)
        ch = rows[y][x]
        if "0" <= ch <= "9":
            stack.append(int(ch))
        elif ch == "a":
            stack.append(10)
        elif ch in "+-*" or ch == chr(96):
            b, a = pop(), pop()
            stack.append(a + b if ch == "+" else
                         a - b if ch == "-" else
                         a * b if ch == "*" else int(a > b))
        elif ch == "g":
            py, px = pop(), pop()
            key = (px, py)
            assert key in ((3, 49), (1, 49)), ("unexpected read", key)
            value = counter3 if key == (3, 49) else counter1
            stack.append(value)
            events.append(["g", x, y, px, py, value])
        elif ch == "j":
            n = pop()
            events.append(["j", x, y, n])
            x += dx * n
            y += dy * n
        elif ch == "x":
            vy, vx = pop(), pop()
            events.append(["x", x, y, vx, vy])
            dx, dy = vx, vy
        elif ch == ">":
            dx, dy = 1, 0
        elif ch == " ":
            pass
        else:
            raise AssertionError(("unsupported opcode", x, y, ch))
        x, y = x + dx, y + dy
        if (x, y) in TARGETS:
            assert not stack, ("unexpected residual stack", stack)
            return {"exit": [x, y], "ticks": tick, "events": events}
    raise AssertionError("model exceeded bounded step count")


def expected_case(m, q):
    if m == 0:
        return ([10, 5], 141,
                [["g", 57, 20, 3, 49, 0], ["j", 89, 20, 0],
                 ["x", 150, 20, -140, -15]])
    route235 = q > 3
    return ([10, 44] if route235 else [10, 26], 306,
            [["g", 57, 20, 3, 49, 1], ["j", 89, 20, 61],
             ["x", 211, 20, -201, 3],
             ["g", 57, 23, 1, 49, q],
             ["j", 113, 23, 61 if route235 else 0],
             ["x", 235 if route235 else 174, 23,
              -225 if route235 else -164, 21 if route235 else 3]])


def audit(original):
    sha = hashlib.sha1(b"blob " + str(len(original)).encode("ascii") +
                       b"\0" + original).hexdigest()
    assert sha == BLOB_SHA, ("original source blob mismatch", sha)
    rows = original.decode("ascii").splitlines()
    verify_source_shape(rows)
    reached235 = 0
    for m in (0, 1):
        for q in range(10):
            result = run_model(rows, m, q)
            target, steps, events = expected_case(m, q)
            assert result == {"exit": target, "ticks": steps, "events": events}, (
                "conditional route mismatch", m, q, result)
            reached235 += int(any(e[:3] == ["x", 235, 23] for e in events))
    # Three hostile original-opcode mutations must be rejected.
    for y, x in ((20, 89), (23, 113), (23, 235)):
        damaged = rows.copy()
        line = list(damaged[y])
        line[x] = " "
        damaged[y] = "".join(line)
        try:
            verify_source_shape(damaged)
        except AssertionError:
            pass
        else:
            raise AssertionError(("tampered source accepted", x, y))
    return {
        "kind": "source_pinned_bounded_two_gate_model_NOT_NATIVE",
        "source_blob": BLOB_SHA, "cases_passed": 20,
        "source_tamper_guards_rejected": 3, "conditional_x23523_cases": reached235,
        "required_state": "counter(3,49)=1 AND counter(1,49)>3",
        "natural_input_witness": False, "new_native_runs": 0,
        "global_reachability_or_ownership_proved": False,
        "stage1_complete": False
    }


if __name__ == "__main__":
    print(json.dumps(audit(SOURCE.read_bytes()), indent=2))
