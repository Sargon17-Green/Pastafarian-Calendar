"""QA31CH: inductive check of the fresh lexical scanner in the frozen 2D source.

Follow actual source bytes from (0,0) to a repeatable reader boundary, parser
rejection or handoff. Values of completed fields and the decimal accumulator
are free integer variables. No calendar arithmetic or post-handoff code runs.
"""
import argparse
import json
from collections import Counter, deque
from dataclasses import dataclass, replace
from pathlib import Path

from qa31cg_compare import ARCHIVES, read_archive
from qa31cf_independent_native_audit import PIN, git_blob

START = (0, 0)
READ = (11, 5)       # immediately after the east-pointing entry glyph at (10,5)
HANDOFF = (4, 0)
SITES = {(286, 5), (235, 23), (235, 32)}
SLOTS = (0, 1, 2, 3, 10, 11, 12, 13)
SPACE = (9, 10, 13, 32)
NO_INPUT = object()
EAST = (1, 0)


class ProofError(ValueError):
    pass


def need(condition, why):
    if not condition:
        raise ProofError(why)


@dataclass(frozen=True)
class Affine:
    """A single free integer, scaled and translated. Unsupported algebra fails closed."""
    name: str
    scale: int = 1
    bias: int = 0

    def __add__(self, other):
        if type(other) is int:
            return replace(self, bias=self.bias + other)
        need(isinstance(other, Affine) and self.name == other.name, "mixed symbolic sum")
        return linear(self.name, self.scale + other.scale, self.bias + other.bias)

    __radd__ = __add__

    def __mul__(self, other):
        need(type(other) is int, "nonlinear symbolic product")
        return linear(self.name, self.scale * other, self.bias * other)

    __rmul__ = __mul__

    def __sub__(self, other):
        return self + other * -1

    def __rsub__(self, other):
        return other + self * -1


def linear(name, scale, bias):
    return Affine(name, scale, bias) if scale else bias


def integer(value):
    need(type(value) is int, "symbolic control, address, output or delta")
    return value


def native_payload(row):
    return (tuple(row["ip"]), tuple(row["delta"]), row["op"], tuple(row["pre"]), tuple(row["post"]))


class Scanner:
    handoff = HANDOFF
    handoff_delta = (-241, -41)

    def __init__(self, source_lines):
        self.lines = source_lines
        self.visited = set()
        self.put_cells = set()
        self.max_steps = 0
        self.moves = {}

    def next_ip(self, x, y, dx, dy, count):
        # Only elide ordinary blank cells. Reject any path requiring wrap or
        # executing non-scanner space. Source and scratch are strictly disjoint.
        key = x, y, dx, dy, count
        if key not in self.moves:
            need((dx, dy) != (0, 0), "stationary scanner IP")
            x, y = x + count * dx, y + count * dy
            while 0 <= y <= 44 and 0 <= x < len(self.lines[y]) and self.lines[y][x] == 32:
                x, y = x + dx, y + dy
            need(0 <= y <= 44 and 0 <= x < len(self.lines[y]), "escaped scanner source ray")
            self.moves[key] = x, y
        return self.moves[key]

    def segment(self, entry, memory, byte, observe=None):
        x, y = entry
        dx, dy = EAST
        stack, outputs = [], []
        reads = 0
        for steps in range(1, 4097):
            ip = (x, y)
            self.visited.add(ip)
            opcode = self.lines[y][x]
            op = chr(opcode)
            if observe is not None:
                before, incoming = tuple(stack), (dx, dy)
            count = 1
            # The frozen scanner never underflows. A changed source cannot obtain
            # an accidental zero from an unmodelled stack prefix.
            if op in "0123456789abcdef":
                stack.append(int(op, 16))
            elif op in "+-*" or opcode == 96:
                need(len(stack) >= 2, "stack underflow")
                b, a = stack.pop(), stack.pop()
                if op == "+":
                    stack.append(a + b)
                elif op == "-":
                    stack.append(a - b)
                elif op == "*":
                    stack.append(a * b)
                else:
                    stack.append(int(integer(a) > integer(b)))
            elif op == "!":
                need(bool(stack), "stack underflow")
                stack.append(int(integer(stack.pop()) == 0))
            elif op in "gp":
                need(len(stack) >= (3 if op == "p" else 2), "stack underflow")
                yy, xx = integer(stack.pop()), integer(stack.pop())
                need(yy == 49 and xx in SLOTS, "unowned memory access")
                if op == "p":
                    memory[xx] = stack.pop()
                    self.put_cells.add((xx, yy))
                else:
                    stack.append(memory[xx])
            elif op == "j":
                need(bool(stack), "stack underflow")
                count += integer(stack.pop())
            elif op == "x":
                need(len(stack) >= 2, "stack underflow")
                dy, dx = integer(stack.pop()), integer(stack.pop())
            elif op == ">":
                dx, dy = EAST
            elif op == "v":
                dx, dy = 0, 1
            elif op == "#":
                count = 2
            elif op == "~":
                need(byte is not NO_INPUT and reads == 0, "unexpected input instruction")
                reads += 1
                if byte is None:
                    dx, dy = -dx, -dy
                else:
                    need(type(byte) is int and 0 <= byte <= 255, "input outside byte alphabet")
                    stack.append(byte)
            elif op == ".":
                need(bool(stack), "stack underflow")
                outputs.append(integer(stack.pop()))
            elif op != "@":
                raise ProofError(f"unsupported scanner opcode {op!r} at {ip}")

            if observe is not None:
                observe((ip, incoming, opcode, before, tuple(stack)))
            if op == "@":
                stop = "reject"
                break
            x, y = self.next_ip(x, y, dx, dy, count)
            if (x, y) == READ:
                need((dx, dy) == EAST, "reader boundary orientation")
                stop = "read"
                break
            if (x, y) == self.handoff:
                need((dx, dy) == self.handoff_delta, "handoff direction")
                stop = "handoff"
                break
        else:
            raise ProofError("scanner segment exceeded 4096 instructions")
        self.max_steps = max(self.max_steps, steps)
        need(reads == int(byte is not NO_INPUT), "input consumption")
        return stop, stack, outputs


def entered(q, pending):
    # Giving old byte and all token slots distinct arbitrary values also covers
    # blank/default values and detects accidental dependence on a stale token.
    cells = {0: Affine("last byte"), 1: q, 2: Affine("acc") if pending else 0, 3: pending}
    cells.update({10 + i: Affine(f"token {i}") for i in range(4)})
    return cells


def base(scanner, observe=None):
    # All eight physical scratch cells occupy an initially empty source row.
    need(scanner.lines[49] == b"", "initial scratch row")
    mem = dict.fromkeys(SLOTS, 32)
    stop, stack, out = scanner.segment(START, mem, NO_INPUT, observe)
    need((stop, stack, out) == ("read", [], [])
         and mem == {0: 0, 1: 0, 2: 0, 3: 0, 10: 32, 11: 32, 12: 32, 13: 32},
         "fresh entry initialization")
    return mem


def grammar(cells, byte):
    """Independent four-field lexical spec; sign/magnitude validation is downstream."""
    q, m = cells[1], cells[3]
    expected = cells.copy()
    if byte is not None:
        expected[0] = byte
        if 48 <= byte <= 57 and q < 4:
            expected[2], expected[3] = 10 * cells[2] + (byte - 48), 1
            return "read", expected, [], []
        if byte not in SPACE:
            return "reject", None, [], [-1] * 7
    if m:
        need(q < 4, "inadmissible grammar state")
        expected[10 + q], expected[1] = cells[2], q + 1
        if byte is not None:
            expected[2], expected[3] = 0, 0
    if byte is not None:
        return "read", expected, [], []
    if expected[1] == 4:
        return "handoff", expected, [expected[i] for i in range(10, 14)], []
    return "reject", None, [], [-1] * 7


def transition(scanner, q, m, byte):
    mem = entered(q, m)
    expected_stop, expected_cells, expected_stack, expected_stdout = grammar(mem, byte)
    stop, stack, out = scanner.segment(READ, mem, byte)
    need(stop == expected_stop, "lexical exit")
    need(stack == expected_stack, "exit stack / token order")
    need(out == expected_stdout, "exit output")
    if expected_cells is not None:
        need(mem == expected_cells, "scratch transfer")
    return stop, (mem[1], mem[3])


def prove(scanner):
    initial = base(scanner)
    states = {(initial[1], initial[3])}
    queue = deque(states)
    counts = Counter()
    while queue:
        q, m = queue.popleft()
        for byte in (*range(256), None):
            stop, successor = transition(scanner, q, m, byte)
            counts[stop] += 1
            if stop == "read" and successor not in states:
                states.add(successor)
                queue.append(successor)
    need(states == {(q, m) for q in range(5) for m in (0, 1) if q + m <= 4},
         "inductive state closure")
    need(scanner.visited.isdisjoint(SITES), "old frontier physically reachable in first scan")
    need(scanner.put_cells == {(x, 49) for x in SLOTS}, "write footprint")
    return {"states": sorted(states), "transitions": sum(counts.values()), "exits": dict(counts),
            "max_segment_instructions": scanner.max_steps, "distinct_executed_cells": len(scanner.visited),
            "all_write_targets": sorted(scanner.put_cells), "excluded_scanner_sites": sorted(SITES)}


def calibrate(lines, rows, raw):
    scanner = Scanner(lines)
    index = 0

    def observe(step):
        nonlocal index
        need(index < len(rows) and step == native_payload(rows[index]), f"Native prefix mismatch at {index + 1}")
        index += 1

    mem = base(scanner, observe)
    for value in (*raw, None):
        stop, stack, output = scanner.segment(READ, mem, value, observe)
        if stop != "read":
            break
    need(stop == "handoff" and output == [] and rows[index]["ip"] == list(HANDOFF)
         and rows[index]["pre"] == stack and rows[index]["delta"] == [-241, -41], "Native handoff")
    return index


def mutant_checks(lines):
    # Bypass the outer blob lock only for these detached one-byte source mutations.
    cases = [
        ("EOF reflect path", 12, 5, "v", ">", 3, 1, None, "unexpected input instruction"),
        ("reject fourth token", 78, 11, "3", "2", 3, 0, 48, "lexical exit"),
        ("decimal multiply", 81, 14, "*", "+", 0, 1, 55, "scratch transfer"),
        ("drop separator reset", 344, 26, "p", "g", 1, 1, 32, "exit stack / token order"),
        ("allow bad pending count", 78, 32, "3", "2", 3, 1, None, "lexical exit"),
        ("duplicate second output token", 78, 41, "1", "0", 3, 1, None, "exit stack / token order"),
        ("change rejection value", 33, 44, "-", "+", 0, 0, 255, "exit output"),
    ]
    for label, x, y, old, new, q, m, byte, expected in cases:
        mutant = lines.copy()
        row = bytearray(lines[y])
        need(row[x] == ord(old) and old != new, "invalid mutant anchor " + label)
        row[x] = ord(new)
        mutant[y] = bytes(row)
        try:
            transition(Scanner(mutant), q, m, byte)
        except ProofError as error:
            need(str(error) == expected, f"wrong rejection for {label}: {error}")
        else:
            raise ProofError("accepted source mutation " + label)
    return [item[0] for item in cases]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("archives", nargs=3, type=Path, metavar="ZIP", help="QA31CB, CD, CF")
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    source = args.source.read_bytes()
    need(git_blob(source) == PIN, "source Git blob")
    lines = source.splitlines()
    result = prove(Scanner(lines))
    result["detached_source_mutations_rejected"] = mutant_checks(lines)
    prefix_steps = {}
    for i, archive in enumerate(args.archives):
        rows, receipt, _ = read_archive(archive, i, source)
        raw = f"1 {i} 0 100".encode("ascii")
        need(receipt["raw_hex"] == raw.hex() and receipt["steps"] == len(rows), "calibration input")
        prefix_steps[str(ARCHIVES[i][2])] = calibrate(lines, rows, raw)
    result.update(schema="qa31ch-inductive-fresh-scanner-v1", source_git_blob=PIN,
                  native_prefix_steps=prefix_steps, new_native_runs=0, stage1_accepted=False,
                  scope="original fresh entry through rejection or first arithmetic handoff")
    args.output.write_text(json.dumps(result, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(f"QA31CH PASS | {result['transitions']} abstract transitions | "
          f"{sum(prefix_steps.values())} archived prefix STEPs | {len(SITES)} excluded scanner sites")


if __name__ == "__main__":
    main()
