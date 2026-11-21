#!/usr/bin/env python3
"""Finite pinned-source EOF reflection study. Not Native or Stage1 acceptance."""
import json
from stage1_qa31f_ascii_prefix_lineage import source

CASES = {
    b"": (319, 462, 0, None, None, 859, 0, 0),
    b"0": (1236, 1379, 61, 1544, 1844, 2241, 1, 1),
    b"1": (1236, 1379, 61, 1544, 1844, 2241, 1, 1),
    b"9": (1236, 1379, 61, 1544, 1844, 2241, 1, 1),
    b"1 ": (2777, 2920, 0, None, None, 3317, 2, 1),
    b"1 1 ": (5235, 5378, 0, None, None, 5775, 4, 2),
}

def simulate(rows, data):
    width = max(map(len, rows))
    x = y = 0
    vx, vy = 1, 0
    stack, overlay, events = [], {}, []
    consumed = 0

    def pop():
        return stack.pop() if stack else 0

    def cell(px, py):
        if (px, py) in overlay:
            return overlay[px, py]
        return ord(rows[py][px]) if 0 <= py < len(rows) and 0 <= px < len(rows[py]) else 32

    for step in range(7000):
        assert 0 <= x < width and 0 <= y < len(rows), ("escaped bounded model", x, y)
        op = chr(cell(x, y))
        if "0" <= op <= "9":
            stack.append(ord(op) - 48)
        elif "a" <= op <= "f":
            stack.append(ord(op) - 87)
        elif op in "+-*" + chr(96):
            b, a = pop(), pop()
            stack.append(a+b if op == "+" else a-b if op == "-" else a*b if op == "*" else int(a > b))
        elif op == "!":
            stack.append(int(pop() == 0))
        elif op == "g":
            py, px = pop(), pop()
            stack.append(cell(px, py))
        elif op == "p":
            py, px, value = pop(), pop(), pop()
            overlay[px, py] = value
            if (x, y) == (248, 35):
                events.append(("p35", step, px, py, value))
        elif op == "j":
            jump = pop()
            if (x, y) == (89, 29):
                events.append(("j29", step, jump, cell(1, 49), cell(3, 49)))
            elif (x, y) == (113, 32):
                events.append(("j32", step, jump, cell(1, 49), cell(3, 49)))
            x += vx*jump
            y += vy*jump
        elif op == "x":
            vy, vx = pop(), pop()
        elif op == "#":
            x += vx
            y += vy
        elif op == "~":
            if consumed == len(data):
                events.append(("eof", step, x, y, vx, vy, cell(1, 49), cell(3, 49)))
                vx, vy = -vx, -vy
            else:
                stack.append(data[consumed])
                consumed += 1
        elif op == ">":
            vx, vy = 1, 0
        elif op == "<":
            vx, vy = -1, 0
        elif op == "v":
            vx, vy = 0, 1
        elif op == "^":
            vx, vy = 0, -1
        elif op == ".":
            pop()
        elif op == "@":
            return dict(step=step, consumed=consumed, q=cell(1, 49), m=cell(3, 49), events=events)
        elif op != " ":
            raise AssertionError(("unexpected opcode", op, x, y, step))
        x += vx
        y += vy
    raise AssertionError("7000-step source-model cap exceeded")

def check(rows, payload):
    eof_at, j29_at, j29_val, j32_at, p35_at, halt_at, read_count, q_final = CASES[payload]
    got = simulate(rows, payload)
    events = got["events"]
    eof = [e for e in events if e[0] == "eof"]
    j29 = [e for e in events if e[0] == "j29"]
    j32 = [e for e in events if e[0] == "j32"]
    p35 = [e for e in events if e[0] == "p35"]
    assert len(eof) == len(j29) == 1, (payload, events)
    assert eof[0][1:6] == (eof_at, 13, 5, 1, 0), (payload, eof)
    assert j29[0][1:3] == (j29_at, j29_val), (payload, j29)
    assert eof[0][-1] == j29[0][-1] == int(len(payload) == 1), (payload, events)
    assert ([e[1] for e in j32], [e[1] for e in p35]) == (
        [] if j32_at is None else [j32_at],
        [] if p35_at is None else [p35_at],
    ), (payload, events)
    assert (got["step"], got["consumed"], got["q"]) == (halt_at, read_count, q_final), got
    if p35:
        assert p35[0][2:] == (1, 49, 1), p35
        assert j32[0][2:] == (0, 0, 1), j32
    return got

def main():
    original = source()  # Verifies git blob 560d6aa5807a7f766213a33835cce85eab0fa40c.
    for (x, y), opcode in {(13, 5): "~", (12, 5): "v", (248, 14): "p",
                           (89, 29): "j", (113, 32): "j", (248, 35): "p"}.items():
        assert original[y][x] == opcode, (x, y)
    checked = {payload.decode("ascii"): check(original, payload) for payload in CASES}
    rejected = 0
    for x, y in ((12, 5), (248, 14), (89, 29), (248, 35)):
        mutated = list(original)
        mutated[y] = original[y][:x] + " " + original[y][x + 1:]
        try:
            check(mutated, b"1")
        except (AssertionError, ValueError, IndexError):
            rejected += 1
        else:
            raise AssertionError(("mutation was not detected", x, y))
    assert rejected == 4
    print(json.dumps({"kind": "source_pinned_eof_reflection_NOT_NATIVE",
                      "original_blob": "560d6aa5807a7f766213a33835cce85eab0fa40c",
                      "prefixes_tested": len(checked),
                      "mutations_rejected": rejected,
                      "single_digit_eof_row29_m1": True,
                      "single_digit_eof_row32_row35": True,
                      "native_eof_verified": False,
                      "stage1_pass": False,
                      "observations": checked}, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
