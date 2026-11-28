"""From the proved first join, derive validity and the first executed mutable arrow."""
import argparse
import itertools
import json
from pathlib import Path
from zipfile import ZipFile

from qa31cg_compare import ARROWS, sha256
from qa31ch_scanner_induction import Affine, SLOTS, Scanner, integer, need, prove as prove_scanner
from qa31cf_independent_native_audit import PIN, git_blob
from qa31ci_native_scanner_and_valid_fork import ARCHIVE_SHA, GATE, step_groups
from qa31cj_first_arithmetic_join import JOIN, OWNER, SCRATCH, explore, zero

VALID = (19, 1696)
SIGNS = ((13, 1694), (17, 1695))
MAGS = ((23, 1697), (29, 1698))
FIXED = {(31, 1699): 1, (53, 1704): 0, (59, 1705): 0, (61, 1706): 0, (67, 1707): 0}
TARGETS = {*OWNER, VALID, *SIGNS, *MAGS, *FIXED, GATE}
WRITER = (1335, 1354)


def class_fields(keys):
    fields = []
    for name, key, threshold in zip("abcd", keys, (2, 1, 2, 1)):
        fields.append(Affine(name, 1, threshold) if key == threshold else key)
    return fields


def specialize(value, actual):
    if type(value) is int:
        return value
    index = "abcd".index(value.name)
    threshold = (2, 1, 2, 1)[index]
    return value.scale * (actual[index] - threshold) + value.bias


def walk(lines, keys, moves):
    fields = class_fields(keys)
    a, b, c, d = fields
    sa, mb, sc, md = keys
    start_flag = int(sa < 2)
    owner_expected = int(sa < 2 and sc < 2 and (sa == 0 or mb != 0) and (sc == 0 or md != 0))
    expected_arrow = ord("v" if mb or md else ">")
    stack = [start_flag]
    memory = dict(zip(OWNER, fields))
    last = dict.fromkeys(OWNER, "before join")
    width, height = max(map(len, lines)), len(lines)
    ip, delta = JOIN, (-1, 0)
    log, stores = [], []

    def cell(point):
        x, y = point
        need(0 <= x < width and 0 <= y < height, "source escape or wrap")
        need(point != SCRATCH and not (y == 49 and x in SLOTS), "depends on previous scratch")
        if point in memory:
            return memory[point]
        return lines[y][x] if x < len(lines[y]) else 32

    def next_ip(point, vector):
        # Shares only geometrical candidates. Any writable or earlier-owned
        # cell intersected by a ray must be read at the actual program version.
        key = point, vector
        cached = moves.get(key)
        if cached is not None:
            return cached
        dx, dy = vector
        need(vector != (0, 0), "stationary IP")
        x, y = point
        cacheable = True
        while True:
            x, y = x+dx, y+dy
            if (x, y) in TARGETS:
                cacheable = False
            value = integer(cell((x, y)))
            if value != 32:
                break
        if cacheable:
            moves[key] = (x, y)
        return x, y

    for tick in range(1200):
        op = chr(integer(cell(ip)))
        step = (ip, delta, op, len(stack))
        event = None
        if ip == GATE:
            need(last.get(GATE) == 1017 and ord(op) == expected_arrow, "first live gate opcode")
            need(op in ARROWS, "executed direction opcode")
            successor = next_ip(ip, ARROWS[op])
            need(successor == ((1500, 1751) if mb or md else (1501, 1750)), "first gate successor")
            log.append((step, event))
            break
        if op in "0123456789abcdef":
            stack.append(int(op, 16))
        elif op in "+-*":
            r, l = stack.pop(), stack.pop()
            if op == "+":
                stack.append(l+r)
            elif op == "-":
                stack.append(l-r)
            else:
                need(type(r) is int or type(l) is int, "unexpected nonlinear product")
                stack.append(l*r)
        elif op == "!":
            stack.append(int(zero(stack.pop())))
        elif op in "pg":
            y, x = integer(stack.pop()), integer(stack.pop())
            target = x, y
            need(target in TARGETS, "unexpected memory owner")
            old = cell(target)
            if op == "p":
                need(target not in last, "overwriting an existing owner")
                memory[target] = stack.pop()
                stores.append((target, ip, tick))
                last[target] = tick
            else:
                need(target in last, "unbound memory read")
                stack.append(memory[target])
            event = (op, target, old, memory[target])
        elif op in ARROWS:
            delta = ARROWS[op]
        elif op == "x":
            dy, dx = integer(stack.pop()), integer(stack.pop())
            delta = dx, dy
        else:
            raise ValueError(f"unsupported source instruction {ip} {op!r}")
        log.append((step, event))
        ip = next_ip(ip, delta)
    else:
        raise ValueError("first mutable gate absent within proof bound")
    need([memory[k] for k in OWNER] == fields and memory[VALID] == owner_expected, "canonical validity owner")
    need([memory[k] for k in SIGNS] == [1-2*a, 1-2*c] and [memory[k] for k in MAGS] == [b, d],
         "sign and magnitude owners")
    need(all(memory[k] == v for k,v in FIXED.items()) and set(memory) == TARGETS, "remaining private owners")
    need(len(log) == 1038 and len(stores) == 11 and stores[-1] == (GATE, WRITER, 1017)
         and sum(e is not None and e[0] == "g" for _,e in log) == 12, "first gate trace shape")
    return log, successor, stores


def audit_native(path, models):
    need(sha256(path.read_bytes()) == ARCHIVE_SHA, "geometry archive pin")
    cases = []
    with ZipFile(path) as archive:
        need(archive.testzip() is None, "geometry CRC")
        for case in json.loads(archive.read("diverse_manifest.json"))["cases"]:
            fields = case["fields"]
            key = tuple(min(v,k) for v,k in zip(fields, (2,1,2,1)))
            log, successor, _ = models[key]
            raw = archive.read(case["trace_file"])
            need(sha256(raw) == case["trace_sha256"], "native trace pin")
            records = step_groups(raw)
            first = next(g for g in records if g[0][2:4] == JOIN)
            for i, ((ip, delta, op, depth), event) in enumerate(log):
                s, events = first if i == 0 else next(records)
                need(s == (first[0][0]+i, 1, *ip, *delta, ord(op), depth), "native physical instruction")
                expected = []
                if event:
                    mode, address, previous, now = event
                    previous, now = specialize(previous, fields), specialize(now, fields)
                    if mode == "p":
                        expected = [(b"WRITE_BEFORE", (*address, previous, now)), (b"WRITE_AFTER", (*address, now))]
                    else:
                        expected = [(b"READ_BEFORE", (*address, previous)), (b"READ_AFTER", (*address, previous))]
                need(events == expected, "native memory versions")
            last = next(records)[0]
            need(last[:6] == (first[0][0]+len(log), 1, *successor, *ARROWS[log[-1][0][2]]),
                 "native executed-arrow successor")
            cases.append([case["case"], list(key), first[0][0], last[0]])
    need(len({row[0] for row in cases}) == len(cases) == 17, "case count")
    return cases


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("geometry_zip", nargs="?", type=Path,
                    help="also calibrate against the original 17 Native traces")
    ap.add_argument("--output", type=Path, required=True)
    args = ap.parse_args()
    raw = args.source.read_bytes()
    need(git_blob(raw) == PIN, "production source pin")
    lines = raw.splitlines()
    scanner = prove_scanner(Scanner(lines))
    # Re-establish the seed used in this proof directly from CJ at the same source.
    for key, first in enumerate((0, 1, Affine("a-2", 1, 2))):
        _, captures = explore(lines, first)
        need(captures[JOIN] == ([[int(key < 2)]], (0,0), (-1,0)), "fresh join premise")
    moves, models, classes = {}, {}, []
    for key in itertools.product(range(3), range(2), range(3), range(2)):
        log, successor, stores = models[key] = walk(lines, key, moves)
        owner = next(event[-1] for _, event in log if event and event[:2] == ("p", VALID))
        classes.append({"minimum_fields": key, "validity_owner": owner, "fetched": log[-1][0][2],
                        "successor": successor})
    base = models[(0,0,0,0)][0]
    for log, _, _ in models.values():
        need([s for s,_ in base[:-1]] == [s for s,_ in log[:-1]], "shared route before live fetch")
    cases = audit_native(args.geometry_zip, models) if args.geometry_zip is not None else []
    controls = []
    for (x,y), old, new, reason in (((199,1335),"!","1","first live gate opcode"),
                                    ((1234,670),"!","1","canonical validity owner")):
        changed = lines.copy()
        need(changed[y][x] == ord(old), "source mutation site")
        changed[y] = changed[y][:x] + new.encode() + changed[y][x+1:]
        try:
            for key in models:
                walk(changed, key, {})
        except (ValueError, IndexError) as exc:
            need(str(exc) == reason, f"unexpected control rejection: {exc}")
        else:
            raise ValueError("accepted corrupted source")
        controls.append([x,y,old,new,reason])
    result = {"source_git_blob": PIN, "fresh_scanner": scanner, "classes": classes,
              "geometry_sha256": ARCHIVE_SHA if cases else None,
              "scope": "source proof plus archived Native calibration" if cases else "source proof only",
              "first_gate": GATE, "first_writer": WRITER, "write_step_from_join_zero_based": 1017,
              "fetch_step_from_join_zero_based": 1037, "corridor_steps_including_successor": len(base)+1,
              "native_calibration": cases, "native_steps_including_successors": len(cases)*(len(base)+1),
              "writes_at_zero_based_ticks": models[(0,0,0,0)][2],
              "validity_owner": VALID, "canonical_ranges": ["0,1,>=2","0,>=1","0,1,>=2","0,>=1"],
              "control_rejections": controls, "stage1_accepted": False}
    args.output.write_text(json.dumps(result, sort_keys=True, indent=2)+"\n", encoding="utf-8")
    print("QA31CK PASS", len(models), "exhaustive classes;", result["native_steps_including_successors"],
          "physical Native STEPs including successors")


if __name__ == "__main__":
    main()
