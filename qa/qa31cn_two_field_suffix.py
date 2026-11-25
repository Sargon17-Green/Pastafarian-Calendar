"""Prove all three BF98 arithmetic bodies isolated from the replacement readers.

Both grids start the suffix at (3,0) with the same two nonnegative integers.
Their initial differences are exactly the changed source cells and scanner
scratch. Reject any fetch, skipped blank, get or put that may touch one of
those cells. This proves stepwise equivalence, including outputs and halting
behaviour, without assuming calendar equations or enumerating input values.
"""
import argparse
import json
from collections import deque
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from qa31cn_two_field_scanners import SPECS
from qa31cf_independent_native_audit import git_blob

ANY = None
CAP = 4
ARROWS = {ord(">"):(1,0), ord("<"):(-1,0), ord("^"):(0,-1), ord("v"):(0,1)}

@dataclass(frozen=True)
class HalfLine:
    bound: int
    upwards: bool


@lru_cache(maxsize=4096)
def singleton(value):
    return frozenset((value,))


def join(left, right):
    if left == right:
        return left
    if left is ANY or right is ANY or isinstance(left,HalfLine) or isinstance(right,HalfLine):
        return ANY
    union = left | right
    return union if len(union) <= CAP else ANY


def arithmetic(op, a, b):
    if op == 96 and (a is ANY or b is ANY):
        return frozenset((0,1))
    if op == ord("*") and singleton(0) in (a,b):
        return singleton(0)
    if a is ANY or b is ANY:
        return ANY
    if isinstance(a,HalfLine) or isinstance(b,HalfLine):
        if isinstance(a,HalfLine) and isinstance(b,HalfLine):
            return frozenset((0,1)) if op == 96 else ANY
        line, fixed, first = (a,b,True) if isinstance(a,HalfLine) else (b,a,False)
        if len(fixed) != 1:
            return frozenset((0,1)) if op == 96 else ANY
        n = next(iter(fixed))
        if op == ord("+"): return HalfLine(line.bound+n, line.upwards)
        if op == ord("-"):
            return HalfLine(line.bound-n, line.upwards) if first else HalfLine(n-line.bound,not line.upwards)
        if op == ord("*"): return HalfLine(line.bound*n, line.upwards == (n>0))
        if op == 96:
            edge = line.bound>n if first else n>line.bound
            if (first == line.upwards) == edge:
                return singleton(int(edge))
            return frozenset((0,1))
        return ANY
    result = set()
    for x in a:
        for y in b:
            if op == ord("+"): value = x + y
            elif op == ord("-"): value = x - y
            elif op == ord("*"): value = x * y
            elif op == 96: value = int(x > y)
            elif x < 0 or y <= 0: return ANY
            elif op == ord("/"): value = x // y
            else: value = x % y
            result.add(value)
    return frozenset(result) if len(result) <= CAP else ANY


def prove(before, after, sign):
    old, new = before.split(b"\n"), after.split(b"\n")
    if len(old) != len(new) or max(map(len,old)) != max(map(len,new)):
        raise ValueError("source envelope changed")
    width, height = max(map(len,old)), len(old)
    reserved = {(x,49) for x in (0,1,2,3,10,11)}
    for y,(a,b) in enumerate(zip(old,new)):
        if a != b:
            width_y = max(len(a),len(b))
            reserved.update((x,y) for x,(i,j) in enumerate(zip(a.ljust(width_y),b.ljust(width_y))) if i != j)

    def default(p):
        x,y = p
        if p in reserved:
            raise ValueError("arithmetic can touch reader at %r"%(p,))
        if not (0 <= y < height and 0 <= x < width):
            raise ValueError("off-grid access %r"%(p,))
        return singleton(old[y][x] if x < len(old[y]) else 32)

    states, pending = {}, deque()
    fetched, reads, writes, gates, halts = set(),set(),set(),set(),set()

    def enqueue(p, delta, stack, mem):
        if len(stack)>64 or len(states)>300000 or delta == (0,0):
            raise ValueError("unbounded control state")
        key = (p,delta,len(stack))
        previous = states.get(key)
        if previous is not None:
            prev_stack, prev_mem = previous
            stack = tuple(join(a,b) for a,b in zip(stack,prev_stack))
            if prev_mem != mem:
                mem = {a:join(prev_mem.get(a,default(a)), mem.get(a,default(a)))
                       for a in prev_mem.keys() | mem.keys()}
            if (stack,mem) == previous:
                return
        states[key] = (stack,mem)
        pending.append(key)

    enqueue((3,0),(1,0),(sign,ANY),{})
    while pending:
        key = pending.popleft()
        pos, direction, _ = key
        stack, memory = states[key]
        options = memory.get(pos,default(pos))
        if options is ANY or isinstance(options,HalfLine):
            raise ValueError("unbounded executed byte at %r"%(pos,))
        fetched.add(pos)
        if pos in memory:
            gates.add(pos)
        for op in options:
            args, mem, deltas = list(stack), memory, (direction,)
            def pop():
                return args.pop() if args else singleton(0)
            if op == 32:
                pass
            elif op in b"0123456789abcdef":
                args.append(singleton(int(chr(op),16)))
            elif op in b"+-*/%`":
                b, a = pop(), pop()
                args.append(arithmetic(op,a,b))
            elif op == ord("!"):
                a = pop()
                if isinstance(a,HalfLine):
                    excludes_zero = a.bound>0 if a.upwards else a.bound<0
                    args.append(singleton(0) if excludes_zero else frozenset((0,1)))
                else:
                    args.append(frozenset((0,1)) if a is ANY else frozenset(int(x == 0) for x in a))
            elif op in ARROWS:
                deltas = (ARROWS[op],)
            elif op == ord("x"):
                ys, xs = pop(), pop()
                if not isinstance(xs,frozenset) or not isinstance(ys,frozenset):
                    raise ValueError("unbounded movement operand")
                deltas = tuple((x,y) for x in xs for y in ys)
            elif op in b"pg":
                ys, xs = pop(), pop()
                if not isinstance(xs,frozenset) or not isinstance(ys,frozenset) or len(xs) != 1 or len(ys) != 1:
                    raise ValueError("unresolved physical address")
                address = (next(iter(xs)), next(iter(ys)))
                prior = mem.get(address,default(address))
                if op == ord("p"):
                    mem = mem.copy()
                    mem[address] = pop()
                    writes.add(address)
                else:
                    args.append(prior)
                    reads.add(address)
            elif op == ord("."):
                pop()
            elif op == ord("@"):
                halts.add(pos)
                continue
            else:
                raise ValueError("unmodelled opcode %r at %r"%(op,pos))
            for dx,dy in deltas:
                enqueue((pos[0]+dx,pos[1]+dy),(dx,dy),tuple(args),mem)
    if not halts or not reads or not writes or not gates:
        raise ValueError("incomplete control or ownership coverage")
    return {"abstract_control_states":len(states),"possible_fetched_coordinates_including_blanks":len(fetched),
            "possible_read_cells":sorted(reads),"possible_write_cells":sorted(writes),
            "possible_executed_written_cells":sorted(gates),"possible_halts":sorted(halts),
            "reserved_cells":len(reserved),"possible_contacts_with_reserved_cells":0}


def footprint_controls(before, after):
    def change_entry(source, prefix):
        row, tail = source.split(b"\n",1)
        return row[:3]+prefix+row[3+len(prefix):]+b"\n"+tail
    rejected = []
    for label,code in (("fetch",b"v"),("read",b"a77*g"),("write",b"a77*p")):
        try:
            prove(change_entry(before,code),change_entry(after,code),singleton(0))
        except ValueError as exc:
            if "can touch reader" not in str(exc):
                raise
            rejected.append(label)
        else:
            raise ValueError("deliberate reader alias escaped: "+label)
    return rejected


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("originals",type=Path)
    p.add_argument("candidates",type=Path)
    p.add_argument("output",type=Path)
    args = p.parse_args()
    result = {}
    for name,(old_sha,new_sha,_) in SPECS.items():
        a = (args.originals/(name+".b98")).read_bytes()
        b = (args.candidates/(name+".b98")).read_bytes()
        if (git_blob(a),git_blob(b)) != (old_sha,new_sha):
            raise ValueError("source pin")
        result[name] = {label:prove(a,b,sgn) for label,sgn in
                        (("zero",singleton(0)),("one",singleton(1)),("at_least_two",HalfLine(2,True)))}
        if len(set.union(*(set(map(tuple,r["possible_halts"])) for r in result[name].values()))) != 2:
            raise ValueError("expected both halt sites")
        result[name]["rejected_alias_controls"] = footprint_controls(a,b)
    args.output.write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("All nine source/sign classes exclude the replacement reader and its scratch through both halts.")
