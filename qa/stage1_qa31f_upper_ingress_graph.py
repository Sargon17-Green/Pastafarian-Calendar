#!/usr/bin/env python3
"""QA31F bounded original-source ingress graph; NOT Native or global reachability."""
import hashlib
import json
from collections import defaultdict
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[1] / "src/interleaved_work_counts.b98"
SOURCE_BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
ENTRY_ROWS = (8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41)
CODES = (0, 9, 10, 13, 32, 47, 48, 49, 57, 58, 65, 255)
COUNTS = (0, 1, 3, 4, 5)
EXPECTED = {
    8: {(10, 11), (10, 17)},
    11: {(10, 14), (10, 44)},
    14: {(10, 5)},
    17: {(10, 20), (10, 44)},
    20: {(10, 5), (10, 23)},
    23: {(10, 26), (10, 44)},
    26: {(10, 5)},
    29: {(10, 32), (10, 38)},
    32: {(10, 35), (10, 44)},
    35: {(10, 38)},
    38: {(10, 41), (10, 44)},
    41: {(4, 0)},
}

def load_rows():
    source = SOURCE.read_bytes()
    digest = hashlib.sha1(b"blob " + str(len(source)).encode() + b"\0" + source).hexdigest()
    assert digest == SOURCE_BLOB, ("original source changed", digest)
    return source.decode("ascii").splitlines()

def evaluate(rows, entry, initial):
    """Evaluate one horizontal standard-entry segment, never a whole input trace."""
    x, y, dx, dy = 10, entry, 1, 0
    stack, memory = [], dict(initial)
    def pop():
        return stack.pop() if stack else 0
    for step in range(1, 550):
        assert 0 <= y < len(rows) and 0 <= x < len(rows[y]), ("bounds", x, y)
        op = rows[y][x]
        if "0" <= op <= "9":
            stack.append(ord(op) - 48)
        elif "a" <= op <= "f":
            stack.append(10 + ord(op) - 97)
        elif op in ("+", "-", "*", chr(96)):
            b, a = pop(), pop()
            stack.append(a+b if op == "+" else a-b if op == "-" else
                         a*b if op == "*" else int(a>b))
        elif op == "!":
            stack.append(int(pop() == 0))
        elif op == "g":
            yy, xx = pop(), pop()
            stack.append(memory.get((xx, yy), 32))
        elif op == "p":
            yy, xx, value = pop(), pop(), pop()
            memory[(xx, yy)] = value
        elif op == "j":
            delta = pop()
            x += dx * delta
            y += dy * delta
        elif op == "x":
            dy, dx = pop(), pop()
        elif op == ">":
            dx, dy = 1, 0
        elif op != " ":
            raise AssertionError(("unexpected opcode", entry, x, y, op))
        x += dx
        y += dy
        if y != entry:
            return (x, y), tuple(stack), step
    raise AssertionError(("step limit", entry))

def initial_memory(c0, q, m):
    return {(0, 49): c0, (1, 49): q, (2, 49): 1, (3, 49): m,
            (10, 49): 1, (11, 49): 2, (12, 49): 3, (13, 49): 4}

def audit(rows):
    observed = defaultdict(set)
    total = 0
    for c0 in CODES:
        for q in COUNTS:
            for m in (0, 1):
                initial = initial_memory(c0, q, m)
                for entry in ENTRY_ROWS:
                    dest, remaining, _ = evaluate(rows, entry, initial)
                    assert dest in EXPECTED[entry], (entry, c0, q, m, dest)
                    if entry == 8:
                        assert dest == ((10, 11) if 48 <= c0 <= 57 else (10, 17))
                    if entry == 11:
                        assert dest == ((10, 44) if q > 3 else (10, 14))
                    if entry == 17:
                        assert dest == ((10, 20) if c0 in (9, 10, 13, 32) else (10, 44))
                    if entry == 20:
                        assert dest == ((10, 23) if m else (10, 5))
                    if entry == 23:
                        assert dest == ((10, 44) if q > 3 else (10, 26))
                    if entry == 41:
                        assert len(remaining) == 4, ("row41 preserved operands", remaining)
                    observed[entry].add(dest)
                    total += 1
    for entry in ENTRY_ROWS:
        assert observed[entry] == EXPECTED[entry], (entry, observed[entry])
    incoming = defaultdict(set)
    for src, destinations in observed.items():
        for x, y in destinations:
            if x == 10:
                incoming[y].add(src)
    assert incoming[14] == {11}, incoming[14]
    assert incoming[23] == {20}, incoming[23]

    # Negative controls: destroy a physical conditional jump and require changed routing.
    mutants = ((11, 113, 0, 4, 0), (20, 89, 32, 0, 1),
               (23, 113, 32, 4, 1))
    rejected = 0
    for entry, jump_x, c0, q, m in mutants:
        assert rows[entry][jump_x] == "j", (entry, jump_x)
        baseline, _, _ = evaluate(rows, entry, initial_memory(c0, q, m))
        damaged = list(rows)
        damaged[entry] = rows[entry][:jump_x] + " " + rows[entry][jump_x+1:]
        try:
            after, _, _ = evaluate(damaged, entry, initial_memory(c0, q, m))
        except AssertionError:
            rejected += 1
        else:
            assert baseline != after, ("mutation not rejected", entry, jump_x)
            rejected += 1
    assert total == 1440 and rejected == 3
    return {
        "kind": "QA31F_SOURCE_PINNED_STANDARD_ENTRY_GRAPH_NOT_NATIVE",
        "source_blob": SOURCE_BLOB,
        "model_segments_checked": total,
        "directed_rows": len(ENTRY_ROWS),
        "hostile_j_mutations_rejected": rejected,
        "incoming_row14_from": [11],
        "incoming_row23_from": [20],
        "row8_can_bypass_row11_to_row17": True,
        "row41_returns_to": [4, 0],
        "row41_preserves_four_stack_operands": True,
        "conditional_only": True,
        "natural_stdin_witness": False,
        "global_ingress_exclusion": False,
        "native_executions_new": 0,
        "stage1_complete": False,
    }

if __name__ == "__main__":
    print(json.dumps(audit(load_rows()), indent=2))
