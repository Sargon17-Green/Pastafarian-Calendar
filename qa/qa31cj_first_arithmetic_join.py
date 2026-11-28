"""Prove the first arithmetic join from every fresh, lexically accepted handoff."""
import argparse
import json
import zipfile
from pathlib import Path

from qa31ch_scanner_induction import Affine, HANDOFF, SLOTS, integer, need
from qa31ci_native_scanner_and_valid_fork import ARCHIVE_SHA, step_groups
from qa31cf_independent_native_audit import PIN, git_blob
from qa31cg_compare import ARROWS, sha256
from stage1_native_real_u_operand_audit import check as check_u_interventions

JOIN = (949, 1335)
BRACE, U, CLOSE = (954, 1330), (954, 1328), (954, 1322)
J, C, X1, X2 = (958, 1331), (958, 1325), (1027, 1334), (950, 1335)
OWNER = ((3, 1690), (5, 1691), (7, 1692), (11, 1693))
SCRATCH = (1490, 1600)
U_SHA = "759af313ac10f0646cac0c54eba8fc86a48e383a5b9099b9504824ada31632b4"
CORRECTED_U_SHA = "2a8dc48839e515fb51a755d5c32043c84266f189b187ac829dc22fd7787483d6"


def zero(value):
    if type(value) is int:
        return value == 0
    # All four free variables range over nonnegative integers. Any test
    # which could change its result inside this class must reject the proof.
    if (value.scale > 0 and value.bias > 0) or (value.scale < 0 and value.bias < 0):
        return False
    raise ValueError("undecided symbolic branch")


def spell(v):
    if isinstance(v, Affine):
        return [v.name, v.scale, v.bias]
    return v


def concrete(v, fields):
    if type(v) is int:
        return v
    vals = {"a-2": fields[0] - 2, "b": fields[1], "c": fields[2], "d": fields[3]}
    return vals[v.name] * v.scale + v.bias


def explore(lines, a):
    fields = [a, Affine("b"), Affine("c"), Affine("d")]
    frames = [fields.copy()]
    offset = (0, 0)
    ip, delta = HANDOFF, (-241, -41)
    width, height = max(map(len, lines)), len(lines)
    memory, log, captures = {}, [], {}

    def cell(x, y):
        need(0 <= x < width and 0 <= y < height, "wrap or source escape")
        need(not (y == 49 and x in SLOTS), "depends on earlier scanner state")
        if (x, y) in memory:
            return memory[x, y]
        return lines[y][x] if x < len(lines[y]) else 32

    def pop(stack):
        return stack.pop() if stack else 0

    for _ in range(400):
        op = chr(integer(cell(*ip)))
        stack = frames[-1]
        step = (ip, delta, op, len(stack))
        event = None
        advance = 1
        if ip in (BRACE, U, CLOSE, J, C, X1, X2, JOIN):
            need(ip not in captures, "unexpected revisit of monitored instruction")
            captures[ip] = ([f.copy() for f in frames], offset, delta)
        if ip == JOIN:
            need(op == "3" and delta == (-1, 0) and offset == (0, 0)
                 and len(frames) == 1 and len(stack) == 1, "join state")
            log.append((step, event))
            break
        if op in "0123456789abcdef":
            stack.append(int(op, 16))
        elif op in "+-*":
            r, l = pop(stack), pop(stack)
            if op == "+":
                stack.append(l + r)
            elif op == "-":
                stack.append(l - r)
            else:
                need(type(l) is int or type(r) is int, "nonlinear product")
                stack.append(l * r)
        elif op == "!":
            stack.append(int(zero(pop(stack))))
        elif op == "$":
            pop(stack)
        elif op == ":":
            stack.append(stack[-1] if stack else 0)
        elif op == "\\":
            right, left = pop(stack), pop(stack)
            stack.extend((right, left))
        elif op in ARROWS:
            delta = ARROWS[op]
        elif op in "[]r":
            dx, dy = delta
            delta = {"[": (dy, -dx), "]": (-dy, dx), "r": (-dx, -dy)}[op]
        elif op == "w":
            r, l = integer(pop(stack)), integer(pop(stack))
            dx, dy = delta
            if l < r:
                delta = dy, -dx
            elif l > r:
                delta = -dy, dx
        elif op in "|_":
            is_zero = zero(pop(stack))
            delta = ((0, 1) if is_zero else (0, -1)) if op == "|" else ((1, 0) if is_zero else (-1, 0))
        elif op in "pg":
            y, x = integer(pop(stack)) + offset[1], integer(pop(stack)) + offset[0]
            target = (x, y)
            need(target in (*OWNER, SCRATCH), "unexpected data address")
            previous = cell(x, y)
            if op == "p":
                memory[target] = pop(stack)
            else:
                need(target in memory, "read before source-owned write")
                stack.append(previous)
            event = (op, target, previous, memory[target])
        elif op == "{":
            need(ip == BRACE and pop(stack) == 0 and len(frames) == 1, "begin-block contract")
            stack.extend(offset)
            frames.append([])
            offset = ip[0] + delta[0], ip[1] + delta[1]
        elif op == "u":
            count = integer(pop(stack))
            need(ip == U and count == 3 and len(frames) == 2, "source u count")
            for _ in range(count):
                stack.append(pop(frames[-2]))
        elif op == "}":
            need(ip == CLOSE and pop(stack) == 2 and len(frames) == 2, "end-block contract")
            under = frames[-2]
            old_y, old_x = integer(pop(under)), integer(pop(under))
            offset = old_x, old_y
            right, left = pop(stack), pop(stack)
            under.extend((left, right))
            frames.pop()
        elif op == "j":
            advance += integer(pop(stack))
        elif op == "x":
            dy, dx = integer(pop(stack)), integer(pop(stack))
            delta = dx, dy
        elif op == "#":
            advance = 2
        else:
            raise ValueError(f"unsupported {op!r} at {ip}")
        log.append((step, event))
        dx, dy = delta
        need(delta != (0, 0), "zero delta")
        x, y = ip[0] + dx * advance, ip[1] + dy * advance
        while cell(x, y) == 32:
            x, y = x + dx, y + dy
        ip = x, y
    else:
        raise ValueError("join not reached within source bound")
    need([memory[t] for t in OWNER] == fields, "four independent saved input fields")
    need(set(memory) == set(OWNER) | ({SCRATCH} if X1 in captures else set()), "ownership at join")
    if X1 in captures:
        need(memory[SCRATCH] == 12, "upper scratch value")
    return log, captures


def snapshot(capture):
    frames, offset, delta = capture
    return {"frames": [[spell(v) for v in frame] for frame in frames],
            "offset": list(offset), "incoming_delta": list(delta)}


def prove(lines):
    walks, output = [], {}
    for label, a in (("a=0", 0), ("a=1", 1), ("a>=2", Affine("a-2", 1, 2))):
        log, caps = explore(lines, a)
        upper = label != "a=1"
        need((U in caps) == (label == "a=0") and (C in caps) == upper and (J in caps) == upper
             and (X1 in caps) == upper and X2 in caps, "input route partition")
        if upper:
            prefix = caps[C][0][0]
            need(len(prefix) == 4 and prefix[1:] == [-1, 0, 0], "upper stack invariant")
            need(caps[J][0] == [prefix+[5]], "actual j operand")
            need(caps[X1][0][-1][-2:] == [-77, 1], "first upper physical vector")
        need(caps[X2][0][-1][-2:] == [-1, 0], "last physical vector")
        need(caps[JOIN][0] == [[int(label != "a>=2")]], "canonical first sign at common join")
        if label == "a=0":
            need(caps[U][0] == [[1, 0, 0], [3]], "real stack ordering at u")
        walks.append(log)
        output[label] = {"inclusive_steps": len(log), "watches": {
            f"{key[0]},{key[1]}": snapshot(val) for key, val in caps.items()},
            "private_input_cells": [list(t) for t in OWNER]}
    return walks, output


def compare_geometry(path, walks):
    need(sha256(path.read_bytes()) == ARCHIVE_SHA, "geometry archive pin")
    cases = []
    with zipfile.ZipFile(path) as z:
        need(z.testzip() is None, "geometry CRC")
        for c in json.loads(z.read("diverse_manifest.json"))["cases"]:
            fields = c["fields"]
            walk = walks[min(fields[0], 2)]
            raw = z.read(c["trace_file"])
            need(sha256(raw) == c["trace_sha256"], "native member pin")
            records = step_groups(raw)
            first = next(group for group in records if group[0][2:4] == HANDOFF)
            for i, (model, access) in enumerate(walk):
                row, events = first if i == 0 else next(records)
                ip, delta, op, depth = model
                need(row == (first[0][0]+i, 1, *ip, *delta, ord(op), depth), "native physical step")
                expected = []
                if access:
                    mode, address, old, value = access
                    old, value = concrete(old, fields), concrete(value, fields)
                    if mode == "p":
                        expected = [(b"WRITE_BEFORE", (*address, old, value)), (b"WRITE_AFTER", (*address, value))]
                    else:
                        expected = [(b"READ_BEFORE", (*address, old)), (b"READ_AFTER", (*address, old))]
                need(events == expected, "native memory calibration")
            cases.append([c["case"], len(walk)])
    need(len(cases) == len({c[0] for c in cases}) == 17, "17 distinct calibrations")
    return cases


def audit_legacy_u(path, upper):
    need(sha256(path.read_bytes()) == U_SHA, "u archive pin")
    with zipfile.ZipFile(path) as z:
        need(z.testzip() is None, "u CRC")
        data = json.loads(z.read("u_operand_native_witness.json"))
    need(data["source_git_blob"] == PIN, "u witness source")
    evidence = []
    expected = upper["watches"]["954,1328"]
    for row in data["records"]:
        for change, run in [(0, row["control"])] + [(m["delta"], m["run"]) for m in row["mutants"]]:
            e = run["u_event"]
            pre, live, post = (e[k] for k in ("pre_original", "pre_executed", "post"))
            frames = lambda record: [list(map(int, f)) for f in record["frames"]]
            need(frames(pre) == expected["frames"] and pre["offset"] == expected["offset"] and
                 pre["direction"] == expected["incoming_delta"] and pre["position"] == list(U),
                 "native unmodified block stack")
            need(frames(live) == [[1, 0, change], [3]] and frames(post) == [[], [change, 0, 1]]
                 and e["operand_original"] == 0 and e["operand_executed"] == change,
                 "historical intervention was on SOSS payload")
            evidence.append([row["case"], change, 3])
    need(len(evidence) == 9 and len(set((r[0], r[1]) for r in evidence)) == 9, "legacy u cases")
    return evidence


def audit_corrected_u(path):
    need(sha256(path.read_bytes()) == CORRECTED_U_SHA, "corrected u archive pin")
    with zipfile.ZipFile(path) as archive:
        need(archive.testzip() is None and sorted(archive.namelist()) ==
             ["u_operand_native_audit.json", "u_operand_native_witness.json"], "corrected u archive membership")
        witness = json.loads(archive.read("u_operand_native_witness.json"))
        archived_audit = json.loads(archive.read("u_operand_native_audit.json"))
    measured = check_u_interventions(witness)
    need(measured == archived_audit["measured"] and len(set(archived_audit["falsified_reports_rejected"])) == 12,
         "corrected native audit receipts")
    cases = []
    for row in witness["records"]:
        control = row["control"]
        trials = []
        for variant in row["mutants"]:
            run = variant["run"]
            motions = zip(control["post_u_128_real_motion"], run["post_u_128_real_motion"])
            diff = next(((i, good, changed) for i, (good, changed) in enumerate(motions, 1)
                         if good != changed), None)
            need(diff == (100, [949, 1335, -1, 0], [948, 1335, -2, 0]), "physical first divergence")
            need(run["steps"] == 200001 and run["status"] == "step-limit" and run["ips"] == 1
                 and run["output"] == [], "bounded Native outcome")
            trials.append({"u_count": run["u_event"]["operand_executed"], "first_motion_divergence": diff,
                           "steps_executed": run["steps"] - 1, "live_ips": run["ips"],
                           "output_fields": len(run["output"])})
        cases.append({"case": row["case"], "control_steps": control["steps"], "u_tick": control["u_event"]["tick"],
                      "control_reference_fields": len(row["reference_7"]), "trials": trials})
    return {"run": 45432407974, "job": 138581009012, "artifact": 14939886020,
            "executed_commit": "e2da1629b0c931013e45f919759b6d3bca57eb7f", "zip_sha256": CORRECTED_U_SHA,
            "measured": measured, "cases": cases}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("geometry_zip", type=Path)
    ap.add_argument("u_zip", type=Path)
    ap.add_argument("--corrected-u-zip", type=Path,
                    default=Path(__file__).parent/"evidence/qa31cj/u_operand_native_v2.zip")
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    src = args.source.read_bytes()
    need(git_blob(src) == PIN, "original source pin")
    lines = src.splitlines()
    walks, classes = prove(lines)
    cases = compare_geometry(args.geometry_zip, walks)
    legacy = audit_legacy_u(args.u_zip, classes["a=0"])
    corrected = audit_corrected_u(args.corrected_u_zip)
    tested = []
    for point, old, new, reason in ((U, "u", "$", "wrap or source escape"),
                                    ((954, 1329), "3", "2", "source u count"),
                                    ((958, 1332), "5", "4", "actual j operand")):
        changed = lines.copy()
        x, y = point
        need(changed[y][x] == ord(old), "control is genuine source mutation")
        changed[y] = changed[y][:x] + new.encode() + changed[y][x+1:]
        try:
            prove(changed)
        except ValueError as exc:
            need(reason in str(exc), f"wrong rejection at {point}: {exc}")
        else:
            raise ValueError("accepted changed source")
        tested.append([list(point), old, new, reason])
    out = {"source_git_blob": PIN, "range": "first fresh handoff through first common join inclusive",
           "classes": classes, "native_calibration": cases, "native_steps": sum(n for _, n in cases),
           "geometry_zip_sha256": ARCHIVE_SHA, "historical_u_zip_sha256": U_SHA,
           "historical_u_payload_trials": legacy, "corrected_u_native": corrected,
           "hostile_source_controls": tested, "stage1_accepted": False}
    args.output.write_text(json.dumps(out, indent=2, sort_keys=True)+"\n", encoding="utf-8")
    print("QA31CJ PASS", len(walks), "exhaustive handoff classes;", out["native_steps"], "archived STEPs")


if __name__ == "__main__":
    main()
