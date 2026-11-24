"""Replay the three QA31CG signed traces against the original live Funge-space.

This is a trace checker for the actually observed instruction set. It accepts no
silent skips, unknown opcodes, alternate k targets, string mode or wraparound.
Calendar outputs are observations. This script is not the calendar oracle.
"""
import argparse
import copy
import itertools
import json
import operator
import zipfile
from collections import Counter
from pathlib import Path

from qa31ce_existing_four_trace_causal_audit import (
    PROJECT, SOURCE_BLOB, first_difference, parse_trace, require, sha256, summarise,
)
from qa31cf_independent_native_audit import verify_source_and_metadata

ARCHIVES = (
    ("cb", "token_100", 14745206712, "ea247b7c907d9cd0e1fb8e211619ff538b99b435dd43bcdaef70f084f6e499be"),
    ("cd", "candidate_100", 14775400606, "a8a48737663cdcfcae6df4c93bc62dde81f02c5159803a7d3484aee7363c9db1"),
    ("cf", "candidate_100", 14865377417, "bc05038212ebd4bf48a62103fc192e0adfd068f0baf9dd9c134fd90200666252"),
)
TOKEN_CELL = (5, 1691)
OWNER = (19, 1696)
CODE = (1500, 1860)
ARROWS = {">": (1, 0), "<": (-1, 0), "v": (0, 1), "^": (0, -1)}
BINARY = {"+": operator.add, "-": operator.sub, "*": operator.mul, chr(96): lambda a, b: int(a > b)}
ROUTE_FIELDS = ("ip", "op", "delta", "next", "next_delta")


def read_archive(path, index, source):
    tag, label, artifact, digest = ARCHIVES[index]
    require(sha256(path.read_bytes()) == digest, "archive SHA-256 " + tag)
    prefix = "qa31" + tag
    manifest_name = prefix + "_artifact_manifest.json"
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        require(len(set(names)) == len(names) and archive.testzip() is None, "ZIP CRC / duplicate member")
        manifest = json.loads(archive.read(manifest_name))
        members = manifest["files"]
        require(manifest["project_id"] == PROJECT and set(members) == set(names) - {manifest_name},
                "manifest membership")
        for name, checksum in members.items():
            require(sha256(archive.read(name)) == checksum, "manifest SHA-256 " + name)
        verify_source_and_metadata(source, json.loads(archive.read("qa31cb_source_cells.json")))
        records = (json.loads(line) for line in archive.read(prefix + "_cases.jsonl").splitlines())
        matching = [r for r in records if r["label"] == label]
        require(len(matching) == 1, "case count " + label)
        receipt = matching[0]
        require(receipt["project_id"] == PROJECT and receipt["qa"] == prefix.upper()
                and receipt["source_git_blob_sha1"] == SOURCE_BLOB and receipt["source_modified"] is False
                and receipt["ip_relocated"] is False and receipt["native_execution_observed"] is True
                and receipt["status"] == "HALT" and receipt["error"] is None, "original Native provenance")
        name = label + ".jsonl.gz"
        require(receipt["trace_file"] == name and receipt["trace_sha256"] == members[name], "trace digest")
        rows = parse_trace(archive, name)
    return rows, receipt, {"artifact": artifact, "sha256": digest, "manifest_count": len(members)}


def replay(rows, receipt, b, source_lines):
    raw = f"1 {b} 0 100".encode("ascii")
    require(receipt["raw_hex"] == raw.hex() and receipt["raw_sha256"] == sha256(raw), "stdin identity")
    require(receipt["steps"] == len(rows) <= 50000, "receipt length")
    memory = {}
    writers = {}
    lineage = []
    pg_count = 0
    fetch_count = 0
    ip, direction = (0, 0), (1, 0)
    stack = []
    output = bytearray()
    read_events = []
    cursor = 0
    opcounts = Counter()
    width = max(map(len, source_lines))
    height = len(source_lines)

    def cell(point):
        if point in memory:
            return memory[point]
        x, y = point
        if 0 <= y < height and 0 <= x < len(source_lines[y]):
            return source_lines[y][x]
        return 32

    def pop():
        return stack.pop() if stack else 0

    for tick, row in enumerate(rows, 1):
        def check(ok, label):
            require(ok, f"{label} at STEP {tick}")

        check(row["t"] == tick and row["ip"] == list(ip) and row["delta"] == list(direction),
              "physical entry")
        check(row["pre"] == stack and row["string"] is False and row["storage_offset"] == [0, 0],
              "physical pre-state")
        value = cell(ip)
        check(value == row["op"], "source/live opcode")
        op = chr(value)
        opcounts[op] += 1
        check((row["pg"] is not None) == (op in "pg"), "p/g presence")
        check((row["fetch"] is not None) == (ip == CODE), "fetch presence")
        if ip == CODE:
            check(row["fetch"] == {"tick": tick, "ip": list(ip), "op": value, "cell_observed": value}
                  and ip in writers, "live code version")
            fetch_count += 1
            lineage.append(("fetch", list(ip), tick, value, writers[ip]))
        pre = stack.copy()
        advance = 1
        reads = []
        emitted = b""
        if op in "0123456789abcdef":
            stack.append(int(op, 16))
        elif op in BINARY:
            rhs, lhs = pop(), pop()
            stack.append(BINARY[op](lhs, rhs))
        elif op in "/%":
            rhs, lhs = pop(), pop()
            # These traces have positive divisors; check the only division ambiguity directly.
            check(rhs > 0 and (op == "%" or lhs % rhs == 0 or lhs >= 0), "division domain")
            stack.append(lhs // rhs if op == "/" else lhs % rhs)
        elif op == "!":
            stack.append(int(pop() == 0))
        elif op == "$":
            pop()
        elif op in ARROWS:
            direction = ARROWS[op]
        elif op == "]":
            dx, dy = direction
            direction = -dy, dx
        elif op == "w":
            rhs, lhs = pop(), pop()
            dx, dy = direction
            if lhs < rhs:
                direction = dy, -dx
            elif lhs > rhs:
                direction = -dy, dx
        elif op in "_|":
            positive = bool(pop())
            if op == "_":
                direction = (-1, 0) if positive else (1, 0)
            else:
                direction = (0, -1) if positive else (0, 1)
        elif op == "x":
            dy, dx = pop(), pop()
            direction = dx, dy
        elif op == "j":
            advance += pop()
        elif op == "#":
            advance = 2
        elif op == "~":
            if cursor in (0, len(raw)):
                reads = [{"t": tick, "ip": list(ip), "stack": pre, "method": "readline",
                          "start": cursor, "end": len(raw), "hex": raw[cursor:].hex()}]
            if cursor < len(raw):
                stack.append(raw[cursor])
                cursor += 1
            else:
                dx, dy = direction
                direction = -dx, -dy
        elif op in "pg":
            y, x = pop(), pop()
            target = x, y
            before = cell(target)
            last = writers.get(target)
            result = None
            if op == "p":
                memory[target] = pop()
                writers[target] = tick
            else:
                result = before
                stack.append(result)
            expected = {"tick": tick, "ip": list(ip), "op": value, "pre_toss": pre,
                        "storage_offset": [0, 0], "target": list(target), "cell_before": before,
                        "cell_after": cell(target), "result": result}
            check(expected == row["pg"], "p/g live memory")
            pg_count += 1
            if target in (TOKEN_CELL, OWNER, CODE):
                lineage.append((op, list(target), tick, cell(target), last))
        elif op == "k":
            dx, dy = direction
            target = ip[0] + dx, ip[1] + dy
            check(pop() == 1 and cell(target) == ord("+"), "observed k target and count")
            stack.append(pop() + pop())
        elif op == ".":
            emitted = f"{pop()} ".encode("ascii")
        elif op == "@":
            check(tick == len(rows) and row["next"] is None and row["next_delta"] is None, "terminal HALT")
        else:
            raise ValueError(f"unsupported executed opcode {op!r} at STEP {tick}")
        check(row["post"] == stack, "opcode stack effect")
        check(row["reads"] == reads, "stdin buffer / EOF")
        check(row["stdout_delta_hex"] == emitted.hex(), "physical output")
        read_events.extend(reads)
        output.extend(emitted)
        if op != "@":
            dx, dy = direction
            x, y = ip[0] + advance * dx, ip[1] + advance * dy
            check((dx, dy) != (0, 0), "zero movement")
            while 0 <= x < width and 0 <= y < height and cell((x, y)) == 32:
                x, y = x + dx, y + dy
            check(0 <= x < width and 0 <= y < height and row["next"] == [x, y]
                  and row["next_delta"] == [dx, dy], "source-derived successor")
            ip = x, y

    check(op == "@" and cursor == len(raw) and len(read_events) == 2
          and receipt["read_events"] == read_events, "HALT / read receipt")
    check(receipt["stdout_hex"] == output.hex(), "stdout receipt")
    for target, field in ((OWNER, "owner_pg_events"), (CODE, "code_pg_events")):
        observed = [r["pg"] for r in rows if r["pg"] and r["pg"]["target"] == list(target)]
        check(receipt[field] == observed, "case memory summary")
    check(receipt["target_fetches"] == [r["fetch"] for r in rows if r["fetch"]], "case fetch summary")
    owner = int(b != 0)
    code = 56 * owner + 62
    chain = [("p", list(TOKEN_CELL), 10664, b, None), ("g", list(TOKEN_CELL), 10900, b, 10664),
             ("p", list(OWNER), 11135, owner, None), ("g", list(TOKEN_CELL), 11332, b, 10664),
             ("g", list(OWNER), 24722, owner, 11135),
             ("p", list(CODE), 24795, code, None), ("fetch", list(CODE), 24823, code, 24795)]
    check(lineage == chain, "last-writer chain")
    result = summarise(rows, b, 100)
    result.update(pg_count=pg_count, fetch_count=fetch_count, last_writer_chain=lineage,
                  storage_offset=[0, 0], stdout=output.decode("ascii"), opcode_counts=dict(opcounts))
    return result


def compare(a, b):
    fields = {"route": ROUTE_FIELDS, "pre_stack": ("pre",), "post_stack": ("post",),
              "input_read": ("reads",), "memory": ("pg",), "output": ("stdout_delta_hex",)}
    return {key: first_difference(a, b, lambda r: tuple(r[k] for k in keys))
            for key, keys in fields.items()}


def hostile_checks(rows, receipt, source_lines):
    # Alter detached physical records after verifying the ZIP, so SHA rejection cannot mask a weak check.
    changes = (
        ("missing write", 2601, "pg", None, "p/g presence"),
        ("wrong stored byte", 2601, "pg.cell_after", 49, "p/g live memory"),
        ("forged gate intermediate", 10902, "post", [1, 2], "opcode stack effect"),
        ("wrong input buffer", 2554, "post", [49], "opcode stack effect"),
        ("wrong EOF direction", 9598, "next_delta", [1, 0], "source-derived successor"),
        ("changed source glyph", 10903, "op", 43, "source/live opcode"),
        ("spliced stack prefix", 10664, "pre", [1, 2, 7, 1691], "physical pre-state"),
        ("shifted owner address", 24722, "pg.target", [20, 1696], "p/g live memory"),
        ("nonzero offset", 24795, "storage_offset", [1, 0], "physical pre-state"),
        ("missing code fetch", 24823, "fetch", None, "fetch presence"),
        ("forged fetched byte", 24823, "op", 62, "source/live opcode"),
        ("forged output", 24844, "stdout_delta_hex", "00", "physical output"),
        ("lost terminal", 24977, "next", [0, 0], "terminal HALT"),
    )
    for name, tick, field, replacement, expected in changes:
        altered = rows.copy()
        row = altered[tick - 1] = copy.deepcopy(rows[tick - 1])
        container, key = (row, field) if "." not in field else (row["pg"], field.split(".")[1])
        require(container[key] != replacement, "no-op control " + name)
        container[key] = replacement
        try:
            replay(altered, receipt, 2, source_lines)
        except AssertionError as error:
            require(str(error) == f"{expected} at STEP {tick}", f"wrong rejection for {name}: {error}")
        else:
            raise AssertionError("accepted detached mutation " + name)
    return [entry[0] for entry in changes]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("archives", nargs=3, type=Path, metavar="ZIP", help="QA31CB, CD, CF, in order")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = args.source.read_bytes()
    lines = source.splitlines()
    traces, cases = [], []
    for b, path in enumerate(args.archives):
        rows, receipt, archive = read_archive(path, b, source)
        cases.append({**archive, **replay(rows, receipt, b, lines)})
        traces.append(rows)
    pairs = {f"{i}/{j}": compare(traces[i], traces[j]) for i, j in itertools.combinations(range(3), 2)}
    require([p["route"] for p in pairs.values()] == [24823, 24823, None]
            and [p["output"] for p in pairs.values()] == [24828, 24828, 24844], "pair differential")
    require(first_difference(traces[1], traces[1][:-1], lambda r: r["ip"]) == len(traces[1]),
            "strict-prefix length control")
    controls = hostile_checks(traces[2], receipt, lines)
    report = {"schema": "qa31cg-original-source-replay-v1", "project_id": PROJECT,
              "source_git_blob": SOURCE_BLOB, "cases": cases, "first_differences": pairs,
              "detached_mutations_rejected": controls, "truncated_pair_rejected_as_equal": True,
              "new_native_runs": 0, "stage1_accepted": False}
    args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"QA31CG PASS | {sum(len(t) for t in traces)} STEPs | "
          f"{sum(c['pg_count'] for c in cases)} p/g | {len(controls)} rejected mutations")


if __name__ == "__main__":
    main()
