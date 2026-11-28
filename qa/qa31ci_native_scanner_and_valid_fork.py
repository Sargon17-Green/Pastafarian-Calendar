"""Cross-check the fresh scanner and the actual arithmetic routes in 17 archived Native runs."""
import argparse
import itertools
import json
import operator
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

from qa31cg_compare import sha256
from qa31ch_scanner_induction import EAST, HANDOFF, READ, SLOTS, Scanner, base, need
from qa31cf_independent_native_audit import PIN, git_blob

ARCHIVE_SHA = "938f4643876db0758e9d068726dbb84bb171c246109f0b52281e08422f52f236"
GATE = (1500, 1750)
SELECT = ("zero_equal", "epoch_forward_one", "epoch_reverse_one")
REGION_RIGHT = 457


def protected(x, y):
    return (y == 0 and 0 <= x < 4 or 1 <= y <= 44 and 0 <= x <= REGION_RIGHT
            or y == 49 and x in SLOTS)


def step_groups(raw):
    step, events = None, []
    for line in raw.splitlines():
        kind, *parts = line.split(b"\t")
        values = tuple(map(int, parts))
        if kind == b"STEP":
            if step is not None:
                yield step, events
            step, events = values, []
        else:
            need(step is not None and values[0] == step[0], "unbound memory event")
            events.append((kind, values[1:]))
    if step is not None:
        yield step, events


def check_source_cell(lines, writes, x, y):
    if (x, y) in writes:
        return writes[x, y]
    if 0 <= y < len(lines) and 0 <= x < len(lines[y]):
        return lines[y][x]
    return 32


def inspect_native(lines, groups, case):
    fields = case["fields"]
    need(len(fields) == 4 and all(type(v) is int for v in fields), "case fields")
    valid = all(sign in (0, 1) and magnitude >= sign for sign, magnitude in (fields[:2], fields[2:]))
    need(valid == case["valid"], "canonical sign/magnitude classification")
    need(groups[0][0][:7] == (1, 1, 0, 0, *EAST, ord("v")), "original entry")
    need(groups[-1][0][6] == ord("@"), "terminal opcode")

    scanner = Scanner(lines)
    prefix = 0

    def observe(model):
        nonlocal prefix
        step, events = groups[prefix]
        tick, ip_id, x, y, dx, dy, op, depth = step
        ip, delta, opcode, before, after = model
        need(tick == prefix + 1 and ip_id == 1 and (ip, delta, opcode, len(before))
             == ((x, y), (dx, dy), op, depth), "physical scanner prefix")
        if op in (ord("p"), ord("g")):
            need(len(events) == 2 and tuple(before[-2:]) == events[0][1][:2], "scanner memory target")
            if op == ord("p"):
                need(before[-3] == events[1][1][-1], "scanner memory write value")
            else:
                need(after[-1] == events[1][1][-1], "scanner memory read value")
        prefix += 1

    # The pinned native collector constructs this exact input including the final LF.
    raw_input = (" ".join(map(str, fields)) + "\n").encode("ascii")
    mem = base(scanner, observe)
    for byte in (*raw_input, None):
        stop, stack, output = scanner.segment(READ, mem, byte, observe)
        if stop != "read":
            break
    need(stop == "handoff" and stack == fields and not output, "lexical handoff")
    handoff = prefix + 1
    need(groups[prefix][0][2:8] == (*HANDOFF, -241, -41, ord(">"), 4), "Native handoff coordinates")

    writes, versions, fetches, gate_writes = {}, {}, [], []
    read_count = write_count = suffix_memory = 0
    for tick, (step, events) in enumerate(groups, 1):
        t, ip_id, x, y, dx, dy, op, depth = step
        need(t == tick and ip_id == 1 and depth >= 0 and (dx, dy) != (0, 0), "physical STEP")
        need((op == ord("@")) == (t == len(groups)), "HALT boundary")
        need(op == check_source_cell(lines, writes, x, y), "live instruction version")
        if t >= handoff:
            need(not protected(x, y) and (t == handoff or (x, y) != HANDOFF), "scanner re-entry")
        if (x, y) == GATE:
            need(GATE in versions and t < len(groups), "missing gate writer / successor")
            sx, sy, sdx, sdy = groups[t][0][2:6]
            fetches.append([t, versions[GATE], op, sx, sy, sdx, sdy])
        if op not in (ord("p"), ord("g")):
            need(not events, "unexpected memory event")
            continue
        if op == ord("p"):
            expected = [b"WRITE_BEFORE", b"WRITE_AFTER"]
        else:
            expected = [b"READ_BEFORE", b"READ_AFTER"]
        need([kind for kind, _ in events] == expected, "memory event pair")
        before, after = events[0][1], events[1][1]
        tx, ty, previous = before[:3]
        need((tx, ty) == after[:2] and previous == check_source_cell(lines, writes, tx, ty),
             "memory/source provenance")
        if t >= handoff:
            need(not protected(tx, ty), "scanner memory access after handoff")
            suffix_memory += 1
        if op == ord("g"):
            need(len(before) == 3 and after == before, "read value")
            read_count += 1
        else:
            need(len(before) == 4 and after == (tx, ty, before[3]), "write value")
            writes[tx, ty], versions[tx, ty] = before[3], t
            if (tx, ty) == GATE:
                gate_writes.append([t, x, y, previous, before[3]])
            write_count += 1
    need(len(case["output"]) == 7 and valid == (case["output"] != ["-1"] * 7), "output family")
    return {"case": case["case"], "valid": valid, "fields": fields, "steps": len(groups),
            "handoff_tick": handoff, "prefix_steps": prefix, "post_handoff_steps_including_entry": len(groups)-prefix,
            "p": write_count, "g": read_count, "post_handoff_pg": suffix_memory,
            "gate_writes": gate_writes, "gate_fetches": fetches, "output": case["output"]}


def compare_valid(cases, routes):
    results = []
    baseline = cases[SELECT[0]]
    for name in SELECT[1:]:
        other = cases[name]
        need(baseline["valid"] and other["valid"] and sum(a != b for a, b in
             zip(baseline["fields"], other["fields"])) == 1, "controlled valid pair")
        a, b = routes[SELECT[0]], routes[name]
        tick = next(i for i, (left, right) in enumerate(itertools.zip_longest(a, b), 1) if left != right)
        need(tick == 11254 and a[tick-1][:4] == b[tick-1][:4] == (*GATE, 165, 377), "first divergence")
        first_write = [11234, 1335, 1354, 32]
        east = [1501, 1750, 1, 0]
        south = [1500, 1751, 0, 1]
        need(baseline["gate_writes"] == [first_write+[62]] and baseline["gate_fetches"] ==
             [[tick, 11234, 62, *east]], "baseline directed fork")
        need(other["gate_writes"] == [first_write+[118], [13560, 1335, 1354, 118, 62]]
             and other["gate_fetches"] == [[tick, 11234, 118, *south], [13580, 13560, 62, *east]],
             "changed and re-executed gate")
        need(baseline["output"] != other["output"], "distinct seven-field output")
        results.append({"pair": [SELECT[0], name], "shared_route_prefix": tick - 1,
                        "first_executed_opcode_difference": tick,
                        "baseline_east_successor": tick + 1, "alternate_east_successor": 13581,
                        "additional_steps_between_gate_fetches": 13580 - tick})
    return results


def upper_vector_lineage(lines, groups, end):
    """Propagate the four incoming stack values through the witnessed upper corridor."""
    anchor = (958, 1325)
    start = next((i for i in range(end - 1, max(-1, end - 128), -1) if groups[i][0][2:4] == anchor), None)
    need(start is not None and groups[start][0][6:8] == (ord("c"), 4), "upper-route symbolic entry")
    need(groups[end][0][2:4] == (1027, 1334) and groups[end+1][0][2:4] == (950, 1335),
         "chained physical x sites")

    # Each form is (constant, coefficients of s0, s1, s2, s3), bottom to top.
    def const(n):
        return (n, 0, 0, 0, 0)

    def scalar(form):
        need(form[1:] == (0, 0, 0, 0), "symbolic scratch address or nonlinear product")
        return form[0]

    stack = [tuple(int(k == i + 1) for k in range(5)) for i in range(4)]
    scratch, scratch_events, vectors = {}, [], []
    for i in range(start, end + 2):
        r, events = groups[i]
        x, y, op, depth = r[2], r[3], chr(r[6]), r[7]
        need(lines[y][x] == r[6] and len(stack) == depth, "upper source and TOSS depth")
        if op in "0123456789abcdef":
            stack.append(const(int(op, 16)))
        elif op in "+-*":
            rhs, lhs = stack.pop(), stack.pop()
            if op == "*":
                if any(rhs[1:]):
                    rhs, lhs = lhs, rhs
                stack.append(tuple(scalar(rhs)*v for v in lhs))
            else:
                fn = operator.add if op == "+" else operator.sub
                stack.append(tuple(map(fn, lhs, rhs)))
        elif op == "\\":
            stack[-2], stack[-1] = stack[-1], stack[-2]
        elif op == ":":
            stack.append(stack[-1])
        elif op in "pg":
            ty, tx = scalar(stack.pop()), scalar(stack.pop())
            need((tx, ty) == (1490, 1600) and events[0][1][:2] == (tx, ty), "upper scratch offset")
            if op == "p":
                scratch[tx, ty] = stack.pop()
            else:
                need((tx, ty) in scratch, "read requires corridor-local writer")
                stack.append(scratch[tx, ty])
            need(scalar(scratch[tx, ty]) == events[1][1][-1] == 12, "upper literal write/read")
            scratch_events.append((x, y, op, r[0]))
        elif op == "x":
            dy, dx = stack.pop(), stack.pop()
            if i >= end:
                vectors.append((dx, dy))
            else:
                need((scalar(dx), scalar(dy)) == groups[i+1][0][4:6], "upper intermediate vector")
        elif op not in "[r>":
            raise ValueError(f"unsupported upper-route instruction {op!r}")

    need([(x, y, op) for x, y, op, _ in scratch_events] == [(986, 1334, "p"), (1015, 1334, "g")],
         "exclusive upper scratch writer and reader")
    need(vectors == [((-77, 0, 0, -1, -1), const(1)), ((0, 0, 1, 0, 0), (0, 0, 0, 1, 1))],
         "upper vector identities")
    dx1, dy1 = groups[end+1][0][4:6]
    dx2, dy2 = groups[end+2][0][4:6]
    total = -77 - dx1
    need(dy1 == 1 and dy2 == total and (dx2, total) == (-1, 0), "physical upper-vector constraint")
    return {"c_tick": groups[start][0][0], "p_tick": scratch_events[0][3], "g_tick": scratch_events[1][3],
            "first_x_tick": groups[end][0][0], "second_x_tick": groups[end+1][0][0]}


class VectorAudit:
    """Find literal arithmetic suffixes that produce both operands of a physical x."""

    def __init__(self, lines):
        self.lines = lines
        self.width = max(map(len, lines))
        self.cache = {}
        self.visits = Counter()
        self.entries = defaultdict(set)
        self.residual = defaultdict(set)
        self.targets = defaultdict(set)
        self.routed = Counter()
        self.dependencies = defaultdict(Counter)
        self.upper = {}
        self.writers = set()
        self.jumps = set()

    def suffix(self, x, y, dx, dy):
        needed, reverse = 2, []
        while True:
            x, y = x - dx, y - dy
            if not (0 <= y < len(self.lines) and 0 <= x < self.width):
                return (), None, "source boundary"
            symbol = self.lines[y][x] if x < len(self.lines[y]) else 32
            if symbol == 32:
                continue
            op = chr(symbol)
            if op in "0123456789abcdef":
                needed -= 1
            elif op in "+*-":
                needed += 1
            else:
                return (), None, f"{op} at ({x},{y})"
            reverse.append((x, y, symbol))
            if needed == 0:
                break
        sequence = tuple(reversed(reverse))
        stack = []
        for _, _, symbol in sequence:
            op = chr(symbol)
            if op in "0123456789abcdef":
                stack.append(int(op, 16))
            else:
                need(len(stack) >= 2, "non-independent vector suffix")
                rhs, lhs = stack.pop(), stack.pop()
                stack.append({"+": operator.add, "*": operator.mul, "-": operator.sub}[op](lhs, rhs))
        need(len(stack) == 2, "vector suffix output")
        return sequence, tuple(stack), None

    def across_turns(self, groups, first, end):
        """Recover both operands along the witnessed source corridor, across turns and k+."""
        need_count = 2
        for j in range(end - 1, first - 1, -1):
            r = groups[j][0]
            x, y, op = r[2], r[3], chr(r[6])
            if not (0 <= y < len(self.lines) and 0 <= x < len(self.lines[y])
                    and self.lines[y][x] == r[6]):
                return f"live instruction at ({x},{y})"
            if op in "0123456789abcdef":
                need_count -= 1
            elif op in "+*-":
                need_count += 1
            elif op in "xwk":
                need_count += 2
            elif op in "j_|$":
                need_count += 1
            elif op == "\\":
                need_count = max(2, need_count)
            elif op in "><^v[]r#":
                pass
            else:
                return f"{op} at ({x},{y})"
            if need_count == 0:
                break
        else:
            return "arithmetic entry"
        stack = []
        for i in range(j, end):
            r = groups[i][0]
            op = chr(r[6])
            if op in "0123456789abcdef":
                stack.append(int(op, 16))
            elif op in "+*-k":
                if op == "k":
                    nxt = groups[i + 1][0]
                    need(stack.pop() == 1 and nxt[2:4] == (r[2] + r[4], r[3] + r[5])
                         and nxt[6] == ord("+"), "physical k1 immediate plus")
                rhs, lhs = stack.pop(), stack.pop()
                if op in "+k":
                    stack.append(lhs + rhs)
                else:
                    stack.append(lhs * rhs if op == "*" else lhs - rhs)
            elif op == "\\":
                stack[-2], stack[-1] = stack[-1], stack[-2]
            elif op in "xw":
                dy, dx = stack.pop(), stack.pop()
                if op == "x":
                    need((dx, dy) == groups[i+1][0][4:6], "intermediate x direction")
            elif op in "j_|$":
                stack.pop()
        need(len(stack) >= 2 and tuple(stack[-2:]) == groups[end+1][0][4:6], "cross-corridor vector")
        return None

    def inspect(self, groups, handoff, case):
        for i in range(handoff - 1, len(groups)):
            step = groups[i][0]
            x, y, dx, dy, op = step[2:7]
            site = x, y
            if op == ord("p"):
                self.writers.add(site)
            if op == ord("j"):
                self.jumps.add(site)
            if op != ord("x"):
                continue
            self.visits[site] += 1
            self.entries[site].add((dx, dy))
            after = groups[i + 1][0]
            self.targets[site].add(after[2:6])
            key = x, y, dx, dy
            if key not in self.cache:
                self.cache[key] = self.suffix(*key)
            seq, vector, reason = self.cache[key]
            if reason:
                self.residual[site].add(reason)
                root = self.across_turns(groups, handoff - 1, i)
                if root is None:
                    self.routed[site] += 1
                else:
                    self.dependencies[site][root] += 1
                    if site == (1027, 1334):
                        need(case not in self.upper, "duplicate upper-route pair")
                        self.upper[case] = upper_vector_lineage(self.lines, groups, i)
                continue
            need(i - len(seq) >= handoff - 1, "suffix before handoff")
            for (actual, _), (sx, sy, code) in zip(groups[i-len(seq):i], seq):
                need(actual[2:7] == (sx, sy, dx, dy, code), "noncanonical vector suffix ingress")
            need(after[4:6] == vector, "source-derived x direction")
            # Straight movement to the next live instruction is handled by the
            # interpreter. These certified exits take one raw displacement.
            need(after[2:4] == (x + vector[0], y + vector[1]), "certified x landing")

    def report(self):
        def static(op):
            return {(x, y) for y, row in enumerate(self.lines) for x, value in enumerate(row)
                    if (y >= 50 or (y == 0 and x >= 4)) and value == ord(op)}
        need(set(self.visits) == static("x") and self.writers == static("p")
             and self.jumps == static("j"), "arithmetic source-site coverage")
        rest = set(self.residual)
        need(rest == {(1027, 1334), (950, 1335), (1471, 100)}, "vector residual set")
        certified = set(self.visits) - rest
        independent_count = sum(self.visits[p] for p in certified) + sum(self.routed.values())
        need(len(self.upper) == 11 and independent_count + 2 * len(self.upper) == sum(self.visits.values()),
             "arithmetic vector accounting")
        return {"observed_static_x_sites": len(self.visits), "observed_static_p_sites": len(self.writers),
                "observed_static_j_sites": len(self.jumps), "x_visits": sum(self.visits.values()),
                "source_suffix_certified_sites": len(certified),
                "source_suffix_matched_visits": sum(self.visits[p] for p in certified),
                "additional_cross_turn_matches": sum(self.routed.values()),
                "stack_independent_observed_visits": independent_count,
                "upper_symbolic_pairs": self.upper,
                "upper_c_entry_variables_bottom_to_top": ["s0", "s1", "s2", "s3"],
                "upper_first_x": ["-77 - (s2 + s3)", "1"],
                "upper_second_x_if_reached": ["s1", "s2 + s3"],
                "residual": [{"site": p, "visits": self.visits[p],
                              "preceding_nonliteral": sorted(self.residual[p]),
                              "cross_turn_matches": self.routed[p], "remaining_boundary": dict(self.dependencies[p]),
                              "incoming_directions": sorted(self.entries[p]),
                              "observed_next_xy_dx_dy": sorted(self.targets[p])} for p in sorted(rest)]}


def test_detached(lines, groups, case):
    # The archive pin is already verified. Exercise the physical checker on
    # consistent before/after pairs so these controls reach the intended check.
    probes = [
        ("missing write", 11234, [], "memory event pair"),
        ("altered live code", 11234,
         [(b"WRITE_BEFORE", (*GATE, 32, 62)), (b"WRITE_AFTER", (*GATE, 62))], "live instruction version"),
        ("post-handoff scanner read", 11178,
         [(b"READ_BEFORE", (1, 49, 4)), (b"READ_AFTER", (1, 49, 4))], "scanner memory access after handoff"),
    ]
    for label, tick, events, reason in probes:
        changed = groups.copy()
        step, original = groups[tick-1]
        need(events != original, "no-op detached probe")
        changed[tick-1] = (step, events)
        try:
            inspect_native(lines, changed, case)
        except ValueError as error:
            need(str(error) == reason, f"unexpected rejection for {label}: {error}")
        else:
            raise ValueError("accepted altered geometry " + label)
    return [probe[0] for probe in probes]


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("geometry_zip", type=Path)
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    source = args.source.read_bytes()
    need(git_blob(source) == PIN, "original source pin")
    lines = source.splitlines()
    need(max(map(len, lines[1:45])) == REGION_RIGHT + 1 and lines[49] == b"", "scanner bounds")
    need(sha256(args.geometry_zip.read_bytes()) == ARCHIVE_SHA, "original ZIP digest")
    cases, routes = {}, {}
    vector_audit = VectorAudit(lines)
    rejected = []
    with zipfile.ZipFile(args.geometry_zip) as z:
        need(z.testzip() is None and len(z.namelist()) == len(set(z.namelist())) == 56, "ZIP CRC and members")
        manifest = json.loads(z.read("diverse_manifest.json"))
        need(manifest["schema"] == "befunge-stage1-diverse-native-v1", "geometry manifest schema")
        for c in manifest["cases"]:
            name = c["case"]
            need(name not in cases and c["trace_file"] == name+".tsv", "unique case identity")
            raw = z.read(c["trace_file"])
            need(sha256(raw) == c["trace_sha256"], "case trace digest")
            need(z.read(name+".out").decode("ascii").split() == c["output"], "archived Native output")
            groups = list(step_groups(raw))
            cases[name] = inspect_native(lines, groups, c)
            cases[name]["trace_sha256"] = c["trace_sha256"]
            vector_audit.inspect(groups, cases[name]["handoff_tick"], name)
            if name in SELECT:
                routes[name] = [step[2:7] for step, _ in groups]
            if name == "epoch_forward_one":
                rejected = test_detached(lines, groups, c)
    need(len(cases) == 17 and sum(c["valid"] for c in cases.values()) == 14, "17-case corpus")
    results = {"schema": "qa31ci-geometry-reentry-and-valid-fork-v1", "source_git_blob": PIN,
               "run": 45271815787, "job": 138033285657, "artifact": 14863959409,
               "zip_sha256": ARCHIVE_SHA, "cases": list(cases.values()), "valid_pairs": compare_valid(cases, routes),
               "post_handoff_scanner_reentries": 0, "post_handoff_scanner_memory_accesses": 0,
               "arithmetic_vector_inventory": vector_audit.report(), "detached_mutations_rejected": rejected,
               "new_native_runs": 0, "stage1_accepted": False}
    args.output.write_text(json.dumps(results, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("QA31CI PASS | 17 physical traces | 2 single-field valid pairs | 0 post-handoff scanner reentries")


if __name__ == "__main__":
    main()
