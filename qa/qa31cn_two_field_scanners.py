"""Verify the complete fresh scanner and the untouched body of each two-token candidate."""
import argparse
import json
from collections import Counter
from pathlib import Path

from qa31cf_independent_native_audit import git_blob
from qa31ch_scanner_induction import READ, SLOTS, SPACE, Scanner, base, entered, need

SPECS = {
    "day_count": ("4f25f514f7b6362105dfff77db6f36769efe36c3", "ccff205ce45fe267433950ca994ec5aaa49c0352", 1),
    "save": ("dd6f10aa196e3a9523ee786e4ba41a91f303d199", "f99b49cef13a1a036fa43e675cb68bf56f3b03e5", 1),
    "interleaved_day_save": ("4da7c9af6d5b52a42f3fc7679c42eec0e51fc6dc", "04212ba0681f583524fb9f5553b075d8a0794d58", 2),
}


class TwoFieldScanner(Scanner):
    handoff = (2, 0)
    handoff_delta = (-243, -41)


def expected(cells, byte, width):
    done, pending = cells[1], cells[3]
    rejects = ("reject", None, [], [-1] * width)
    next_cells = cells.copy()
    if byte is not None:
        next_cells[0] = byte
        if 48 <= byte <= 57 and done < 2:
            next_cells[2] = 10 * cells[2] + (byte - 48)
            next_cells[3] = 1
            return "read", next_cells, [], []
        if byte not in SPACE:
            return rejects
    if pending:
        next_cells[10 + done] = cells[2]
        next_cells[1] = done + 1
        if byte is not None:
            next_cells[2] = next_cells[3] = 0
    if byte is not None:
        return "read", next_cells, [], []
    if next_cells[1] == 2:
        return "handoff", next_cells, [next_cells[10], next_cells[11]], []
    return rejects


def prove(original, candidate, width):
    old = original.split(b"\n")
    rows = candidate.split(b"\n")
    need(old[0][:3] == b">&&" and rows[0][:3] == b"v >", "entry glyphs")
    need(old[0][3:] == rows[0][3:] and old[45:] == rows[45:], "arithmetic body changed")
    need(not any(old[1:45]), "old body overlaps scanner")
    scanner = TwoFieldScanner(rows)
    base(scanner)
    todo = [(0, 0)]
    seen = set()
    exits = Counter()
    while todo:
        state = todo.pop()
        if state in seen:
            continue
        seen.add(state)
        for byte in (*range(256), None):
            cells = entered(*state)
            mode, wanted, stack, output = expected(cells, byte, width)
            stop, actual_stack, actual_out = scanner.segment(READ, cells, byte)
            need((stop, actual_stack, actual_out) == (mode, stack, output), "scanner exit")
            if wanted is not None:
                need(cells == wanted, "scanner memory transfer")
            if stop == "read" and (cells[1], cells[3]) not in seen:
                todo.append((cells[1], cells[3]))
            exits[stop] += 1
    need(seen == {(0,0),(0,1),(1,0),(1,1),(2,0)}, "incomplete inductive closure")
    need(scanner.put_cells == {(x,49) for x in SLOTS[:6]}, "incorrect write footprint")
    return {"states": sorted(seen), "transitions": sum(exits.values()), "exits": dict(exits),
            "scanner_write_cells": sorted(scanner.put_cells),
            "distinct_executed_scanner_cells": len(scanner.visited)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("originals", type=Path)
    parser.add_argument("candidates", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    report = {}
    for name, (before, after, width) in SPECS.items():
        original = (args.originals / (name + ".b98")).read_bytes()
        candidate = (args.candidates / (name + ".b98")).read_bytes()
        need((git_blob(original), git_blob(candidate)) == (before, after), "Befunge source identity")
        report[name] = dict(prove(original, candidate, width), original=before, candidate=after)
    args.output.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n")
    print("Two-field candidate scanners: 3 x 1,285 transitions.")


if __name__ == "__main__":
    main()
