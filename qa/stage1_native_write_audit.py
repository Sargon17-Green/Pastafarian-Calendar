#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Read-only audit of actual PyFunge-98 instruction and Funge-space traces.

This does not execute calendar arithmetic, calculate expected date values,
or stand in for the independent Befunge-98 oracle.
"""
import collections
import json
import sys

def require(condition, message):
    if not condition:
        raise AssertionError(message)

def inspect_trace(path, required_gate_replays):
    steps = 0
    step_ids = set()
    visited = set()
    directions = set()
    opcounts = collections.Counter()
    records = {}
    pending = {}
    executed_modified_writes = set()
    write_counts = 0
    effective_changes = 0
    with open(path, "r", encoding="utf-8") as stream:
        for raw in stream:
            if not raw.strip():
                continue
            parts = raw.strip().split("\t")
            tag = parts[0]
            try:
                vals = [int(v) for v in parts[1:]]
            except ValueError as exc:
                raise AssertionError("malformed trace numbers: %s: %s" %
                                     (path, exc))
            if tag == "STEP":
                require(len(vals) == 8, "bad STEP shape")
                tick, ip, x, y, dx, dy, opcode, depth = vals
                steps += 1
                require(tick == steps, "non-monotone step sequence")
                require(depth >= 0, "invalid stack depth")
                require(opcode >= 0, "invalid executed opcode")
                step_ids.add(ip)
                visited.add((x, y))
                directions.add((dx, dy))
                opcounts[opcode] += 1
                position = (x, y)
                if position in pending:
                    write_tick, newval, was_changed = pending[position]
                    if tick > write_tick:
                        require(opcode == newval,
                                "executable cell differs from latest native write")
                        if was_changed:
                            executed_modified_writes.add((write_tick, position))
                        del pending[position]
                records[tick] = {"opcode": opcode}
            elif tag == "WRITE_BEFORE":
                require(len(vals) == 5, "bad WRITE_BEFORE shape")
                tick, x, y, previous, proposed = vals
                require(tick in records and records[tick]["opcode"] == ord("p"),
                        "write not tied to executed p")
                require("write" not in records[tick], "duplicate write")
                records[tick]["write"] = ((x, y), previous, proposed)
            elif tag == "WRITE_AFTER":
                require(len(vals) == 4, "bad WRITE_AFTER shape")
                tick, x, y, actual = vals
                require(tick in records and "write" in records[tick],
                        "after event without preceding before")
                target, old, proposed = records[tick]["write"]
                require(target == (x, y), "write target changed")
                require(actual == proposed, "native p did not store proposed value")
                require("complete" not in records[tick], "duplicate WRITE_AFTER")
                records[tick]["complete"] = True
                changed = actual != old
                effective_changes += int(changed)
                write_counts += 1
                pending[(x, y)] = (tick, actual, changed)
            elif tag == "INSUFFICIENT_P_STACK":
                raise AssertionError("cannot audit native p with insufficient stack")
            else:
                raise AssertionError("unknown trace event: " + tag)
    require(steps > 0, "no executed native instructions")
    require(len(step_ids) == 1, "multiple IPs need a separate ownership proof")
    require(write_counts == opcounts[ord("p")],
            "missing or unpaired p write observations")
    require(all("complete" in v for v in records.values() if "write" in v),
            "unfinished p write")
    require(write_counts >= 1, "no observed mutable Funge-space")
    require(effective_changes >= 1, "no actual mutations")
    require(len(executed_modified_writes) >= required_gate_replays,
            "insufficient executed changed code gates")
    require(opcounts[ord("x")] >= 1, "no executed dynamic vector x")
    for vector in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        require(vector in directions, "missing cardinal instruction direction")
    return {
        "executed_steps": steps,
        "unique_coordinates": len(visited),
        "revisits": steps - len(visited),
        "ip_count": len(step_ids),
        "p_writes": write_counts,
        "changed_writes": effective_changes,
        "changed_writes_executed_later": len(executed_modified_writes),
        "dynamic_x": opcounts[ord("x")],
        "distinct_directions": len(directions)
    }

if __name__ == "__main__":
    require(len(sys.argv) == 3,
            "usage: stage1_native_write_audit.py VALID_TRACE INVALID_TRACE")
    valid = inspect_trace(sys.argv[1], 10)
    invalid = inspect_trace(sys.argv[2], 4)
    print("NATIVE_FUNGE_WRITE_AUDIT_PASS", json.dumps(
        {"valid": valid, "invalid": invalid}, sort_keys=True))
    print("SCOPE: per-process, single-IP write/read/execute coherence only;")
    print("interpreter-instance reuse and cross-instance shared Funge-space remain UNPROVEN")
