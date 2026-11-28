#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA31CX: multi-gate corpus; physical hook adapted from accepted QA31CW in this branch."""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import subprocess
import sys
import traceback

from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.program import Program
from stage1_native_diverse_geometry import expected_for, native, REF_COUNTS

ACTIVE_PIN = "7418e1ec5fe88fe5c14b75710dea2d5607527f28"
HELPER_PIN = "bb626658309627704d0cdd2c162a1bdd16e1ad10"
COUNT_REF_PIN = "f941efc793c9eee4accf5d03873f8ed029b16725"
SAVE_REF_PIN = "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"
RUNTIME_PIN = "e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac"
ENTER, GATE, PLUS, MINUS, JOIN = (959,1050),(1020,1046),(1021,1046),(1020,1047),(961,1050)
INC, SUM = (43,1702),(53,1704)
CASES = [
    ("opposed_near", (0,21008,1,10979), [-1,-70,-900,1000,10000], [12,17]),
    ("opposed_mirror", (1,21008,0,10979), [1,70,900,-1000,-10000], [12,17]),
    ("two_zero_digits", (0,50204,1,49804), [0,0,-600,-9000,10000], [3,21]),
    ("two_zero_mirror", (1,50204,0,49804), [0,0,600,9000,-10000], [3,21]),
]

def need(ok, reason):
    if not ok:
        raise AssertionError(reason)

def git_blob(data):
    return hashlib.sha1("blob %d\0" % len(data) + data).hexdigest()

def read(path):
    with open(path, "rb") as stream:
        return stream.read()

def write(path, value):
    with open(path + ".tmp", "wb") as stream:
        stream.write(json.dumps(value, sort_keys=True, indent=2) + "\n")
    os.rename(path + ".tmp", path)

def signed(flag, magnitude):
    return -magnitude if flag else magnitude

def arithmetic(fields):
    c, t = fields[1], fields[3]
    sc, st = 1 - 2 * fields[0], 1 - 2 * fields[2]
    increments = []
    for i in range(5):
        c, dc = divmod(c, 10)
        t, dt = divmod(t, 10)
        increments.append((sc * dc + st * dt) * 10**i)
    need(c == t == 0, "unexpected sixth digit")
    need(sum(increments) == signed(*fields[:2]) + signed(*fields[2:]), "whole-value arithmetic mismatch")
    return increments

def signed_fields(fields, shift):
    result = []
    for flag, magnitude in (fields[:2], fields[2:]):
        value = signed(flag, magnitude) - shift
        result.extend((int(value < 0), abs(value)))
    return tuple(result)

def run(code, fields, expected_increments, force_indices=()):
    need(list(force_indices) == sorted(set(force_indices)) and all(0 <= i < 5 for i in force_indices), "invalid forced index set")
    output = StringIO.StringIO()
    raw = " ".join(map(str, fields)) + "\n"
    program = Program(Befunge98, platform=BufferedPlatform(
        [], {}, stdin=StringIO.StringIO(raw), stdout=output))
    program.load_code(code)
    program.create_ip()
    original_step = program.execute_step
    crossings = []
    state = {"ticks": 0, "gate_fetches": 0, "forced_indices": []}
    route = hashlib.sha256()

    def step(self):
        state["ticks"] += 1
        need(state["ticks"] <= 300000 and len(self.ips) == 1,
             "bounded single-IP execution")
        ip = self.ips[0]
        pos = tuple(ip.position)
        opcode = self.space.get(ip.position)
        stack = list(ip.stack[-1])
        route.update("%d,%d,%d,%d,%d\n" %
                     (pos[0], pos[1], ip.delta[0], ip.delta[1], opcode))

        def read(xy):
            return int(self.space.get(type(ip.position)(xy)))

        if pos == ENTER:
            prior, increment = read(SUM), read(INC)
            index = len(crossings)
            need(index < len(expected_increments), "unexpected extra decimal iteration")
            need(increment == expected_increments[index],
                 "wrong signed weighted digit contribution at iteration %d" % index)
            need(stack == [prior, increment], "ENTER stack is not [prior_sum, signed_increment]")
            crossings.append({"index": index, "prior": prior, "inc": increment,
                              "enter_tick": state["ticks"], "enter_pos": list(pos), "enter_stack": stack})
        elif opcode == ord("p") and len(stack) >= 3 and stack[-2:] == list(GATE):
            event = crossings[-1]
            need("write" not in event, "duplicate gate write in one iteration")
            expected_opcode = 118 if event["inc"] < 0 else 62
            need(stack[-3] == expected_opcode, "gate writer selected the wrong signed arm")
            event["write"] = [read(GATE), int(stack[-3])]
            event["write_tick"] = state["ticks"]
            event["write_pos"] = list(pos)
            event["write_stack"] = stack
            result = original_step()
            need(read(GATE) == event["write"][1], "gate opcode write did not commit")
            return result
        elif pos == GATE:
            index = state["gate_fetches"]
            state["gate_fetches"] += 1
            event = crossings[index]
            need("write" in event and event["write"][1] == opcode,
                 "gate fetch did not consume the just-written opcode")
            need(stack == [event["prior"], abs(event["inc"])],
                 "gate fetch stack is not [prior_sum, absolute_increment]")
            event["physical_fetch"] = chr(opcode)
            if index in force_indices:
                opposite = 118 if opcode == 62 else 62
                self.space.put(ip.position, opposite)
                event["forced"] = True
                state["forced_indices"].append(index)
            event["executed"] = chr(read(GATE))
            event["fetch_tick"] = state["ticks"]
            event["fetch_pos"] = list(pos)
            event["fetch_stack"] = stack
        elif pos in (PLUS, MINUS):
            event = crossings[-1]
            wanted_pos = PLUS if event["executed"] == ">" else MINUS
            wanted_opcode = ord("+") if event["executed"] == ">" else ord("-")
            need((pos, opcode) == (wanted_pos, wanted_opcode),
                 "execution did not follow the selected arithmetic arm")
            event["arm"] = chr(opcode)
            event["arm_tick"] = state["ticks"]
            event["arm_pos"] = list(pos)
            event["arm_stack"] = stack
        elif pos == JOIN and crossings and "after" not in crossings[-1]:
            event = crossings[-1]
            wanted_sum = event["prior"] + (-event["inc"] if event.get("forced") else event["inc"])
            need(stack == [wanted_sum, 5], "wrong stack at the arithmetic join")
            event["after"] = int(stack[0])
            event["join_tick"] = state["ticks"]
            event["join_pos"] = list(pos)
            event["join_stack"] = stack
        return original_step()

    program.execute_step = step.__get__(program, program.__class__)
    program.execute()
    need(not program.ips, "Native program did not terminate")
    need(len(crossings) == len(expected_increments) == 5, "wrong number of decimal iterations")
    need(state["gate_fetches"] == 5, "wrong number of physical gate fetches")
    need(state["forced_indices"] == list(force_indices),
         "forced intervention set mismatch")
    for index, event in enumerate(crossings):
        need(all(key in event for key in ("write_tick", "fetch_tick", "arm_tick", "join_tick", "after")),
             "incomplete gate/join witness")
        need(event["enter_tick"] < event["write_tick"] < event["fetch_tick"] < event["arm_tick"] < event["join_tick"],
             "gate write/fetch/arm/join order")
        original_fetch = "v" if event["inc"] < 0 else ">"
        need(event["physical_fetch"] == original_fetch, "physical gate opcode disagrees with increment sign")
        expected_exec = ((">" if original_fetch == "v" else "v")
                         if index in force_indices else original_fetch)
        need(event["executed"] == expected_exec, "wrong executed gate opcode")
        need(event["arm"] == ("+" if expected_exec == ">" else "-"), "wrong arithmetic arm")
        if not index:
            need(event["prior"] == 0, "nonzero initial accumulator")
        if index:
            need(event["prior"] == crossings[index - 1]["after"],
                 "sum accumulator did not carry across decimal iterations")
    return {"fields": list(fields), "output": output.getvalue().split(),
            "raw_output": output.getvalue(), "ticks": state["ticks"], "route_sha256": route.hexdigest(),
            "forced_indices": list(force_indices), "crossings": crossings}


def run_child(source, fields, increments, force_indices, outdir, label):
    request = {"fields": list(fields), "increments": increments, "forced_indices": list(force_indices)}
    request_path = os.path.join(outdir, label + ".request.json")
    result_path = os.path.join(outdir, label + ".candidate.json")
    write(request_path, request)
    command = ["timeout", "--kill-after=5s", "220s", sys.executable,
               os.path.abspath(__file__), "--candidate", source, request_path, result_path]
    with open(os.path.join(outdir, label + ".candidate.log"), "wb") as log:
        rc = subprocess.call(command, stdout=log, stderr=subprocess.STDOUT)
    need(rc == 0, "candidate exit %d for %s" % (rc, label))
    result = json.loads(read(result_path))
    need(result["fields"] == list(fields) and result["forced_indices"] == list(force_indices), "candidate receipt identity")
    return result

def main(source, outdir, runtime_archive):
    files = [(source, ACTIVE_PIN), ("qa/stage1_native_diverse_geometry.py", HELPER_PIN),
             ("reference/work_counts.b98", COUNT_REF_PIN), ("reference/save.b98", SAVE_REF_PIN)]
    for path, pin in files:
        need(git_blob(read(path)) == pin, "source pin: " + path)
    need(hashlib.sha256(read(runtime_archive)).hexdigest() == RUNTIME_PIN, "runtime pin")
    report = {"schema": "befunge-qa31cx-multi-gate-native-v1",
              "project_id": "PC-BRANCH-BEFUNGE98-KYRGYZ",
              "head_sha": os.environ.get("QA_HEAD_SHA"),
              "source_git_blobs": dict(files), "runtime_archive_sha256": RUNTIME_PIN,
              "status": "IN_PROGRESS", "cases": [], "candidate_native_runs": 0,
              "reference_invocations": 0, "crossings": 0, "nonzero": 0, "zero_sham": 0}
    receipt = os.path.join(outdir, "qa31cx_receipt.json")
    try:
        for label, fields, literal, indices in CASES:
            increments = arithmetic(fields)
            need(increments == literal, "independent decimal arithmetic mismatch: " + label)
            expected = expected_for(*fields)
            report["reference_invocations"] += 3
            write(os.path.join(outdir, label + ".healthy.reference.json"), {"fields": list(fields), "output": expected})
            healthy = run_child(source, fields, increments, [], outdir, label + ".healthy")
            report["candidate_native_runs"] += 1
            report["crossings"] += len(healthy["crossings"])
            need(len(expected) == 7 and healthy["output"] == expected, "healthy independent reference mismatch: " + label)
            record = {"label": label, "fields": list(fields), "increments": increments,
                      "healthy": healthy, "healthy_reference": expected, "interventions": []}
            report["cases"].append(record)
            write(receipt, report)
            for mask in indices:
                selected = [i for i in range(5) if mask & (1 << i)]
                need(len(selected) >= 2, "multi-gate mask must select at least two indices")
                z = sum(increments[i] for i in selected)
                alt = signed_fields(fields, z)
                prefix = native(REF_COUNTS, " ".join(map(str, alt)) + "\n")
                report["reference_invocations"] += 1
                need(len(prefix) == 5, "independent alternate reference shape")
                want = prefix + expected[5:]
                tag = label + ".mask_%d" % mask
                write(os.path.join(outdir, tag + ".reference.json"), {"fields": list(alt), "output": want})
                forced = run_child(source, fields, increments, selected, outdir, tag)
                report["candidate_native_runs"] += 1
                report["crossings"] += len(forced["crossings"])
                need(forced["output"] == want, "forced independent reference mismatch: " + tag)
                delta = [int(a)-int(b) for a,b in zip(forced["output"], healthy["output"])]
                need(delta == [-2*z,-2*z,0,-4*z,0,0,0], "seven-field delta mismatch: " + tag)
                need(forced["route_sha256"] != healthy["route_sha256"], "physical route did not change")
                need([i for i in range(5) if forced["crossings"][i]["arm"] != healthy["crossings"][i]["arm"]] == selected, "physical arm difference set mismatch")
                need([e["index"] for e in forced["crossings"] if e.get("forced")] == selected, "intervention set mismatch")
                total = 0
                for i, contribution in enumerate(increments):
                    total += -contribution if i in selected else contribution
                    need(forced["crossings"][i]["after"] == total, "independent join prefix mismatch")
                need(total == sum(increments)-2*z, "final recurrence mismatch")
                need(forced["output"][5:] == healthy["output"][5:], "SAVE outputs changed")
                report["zero_sham" if z == 0 else "nonzero"] += 1
                record["interventions"].append({"mask": mask, "indices": selected, "z": z, "counterfactual_fields": list(alt),
                    "reference": want, "delta": delta, "candidate": forced})
                write(receipt, report)
                print("QA31CX_CASE_PASS", tag, "z", z, "delta", delta)
                sys.stdout.flush()
        need((len(report["cases"]), report["candidate_native_runs"], report["reference_invocations"],
              report["crossings"], report["nonzero"], report["zero_sham"]) == (4,12,20,60,6,2),
             "aggregate coverage mismatch")
        report["status"] = "PASS"
        write(receipt, report)
        print("QA31CX_SCOPED_NATIVE_PASS 4 healthy 8 forced 60 crossings 6 nonzero 2 zero sham 20 references")
    except Exception:
        report["status"] = "FAIL"
        report["error"] = traceback.format_exc()
        write(receipt, report)
        raise

if __name__ == "__main__":
    if sys.argv[1] == "--candidate":
        source, request_path, result_path = sys.argv[2:]
        request = json.loads(read(request_path))
        code = read(source)
        need(git_blob(code) == ACTIVE_PIN, "child source pin")
        write(result_path, run(code, tuple(request["fields"]), request["increments"], request["forced_indices"]))
    else:
        main(*sys.argv[1:])
