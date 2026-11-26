#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native late-iteration signed-gate interventions on the active production entry."""
from __future__ import print_function
import hashlib
import json
import StringIO
import sys

from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.program import Program
from stage1_native_diverse_geometry import expected_for

ACTIVE_PIN = "7418e1ec5fe88fe5c14b75710dea2d5607527f28"
HELPER_PIN = "bb626658309627704d0cdd2c162a1bdd16e1ad10"
COUNT_REF_PIN = "f941efc793c9eee4accf5d03873f8ed029b16725"
SAVE_REF_PIN = "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44"
ENTER, GATE, PLUS, MINUS, JOIN = (959,1050),(1020,1046),(1021,1046),(1020,1047),(961,1050)
INC, SUM = (43,1702),(53,1704)
CASES = [
    ("later_negative_tens", (0,12345,1,67890), 1, [5,-50,-500,-5000,-50000]),
    ("later_positive_tens", (1,12345,0,67890), 1, [-5,50,500,5000,50000]),
    ("last_positive_ten_thousands", (0,54321,1,9876), 4, [-5,-50,-500,-5000,50000]),
    ("last_negative_ten_thousands", (1,54321,0,9876), 4, [5,50,500,5000,-50000]),
]


def need(ok, reason):
    if not ok:
        raise AssertionError(reason)


def git_blob(data):
    return hashlib.sha1("blob %d\0" % len(data) + data).hexdigest()


def signed_fields(fields, shift):
    result = []
    for flag, magnitude in (fields[:2], fields[2:]):
        value = (-magnitude if flag else magnitude) - shift
        result.extend((int(value < 0), abs(value)))
    return tuple(result)


def run(code, fields, expected_increments, force_index=None):
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
                              "enter_tick": state["ticks"]})
        elif opcode == ord("p") and len(stack) >= 3 and stack[-2:] == list(GATE):
            event = crossings[-1]
            need("write" not in event, "duplicate gate write in one iteration")
            expected_opcode = 118 if event["inc"] < 0 else 62
            need(stack[-3] == expected_opcode, "gate writer selected the wrong signed arm")
            event["write"] = [read(GATE), int(stack[-3])]
            event["write_tick"] = state["ticks"]
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
            if index == force_index:
                opposite = 118 if opcode == 62 else 62
                self.space.put(ip.position, opposite)
                event["forced"] = True
                state["forced_indices"].append(index)
            event["executed"] = chr(read(GATE))
            event["fetch_tick"] = state["ticks"]
        elif pos in (PLUS, MINUS):
            event = crossings[-1]
            wanted_pos = PLUS if event["executed"] == ">" else MINUS
            wanted_opcode = ord("+") if event["executed"] == ">" else ord("-")
            need((pos, opcode) == (wanted_pos, wanted_opcode),
                 "execution did not follow the selected arithmetic arm")
            event["arm"] = chr(opcode)
            event["arm_tick"] = state["ticks"]
        elif pos == JOIN and crossings and "after" not in crossings[-1]:
            event = crossings[-1]
            wanted_sum = event["prior"] + (-event["inc"] if event.get("forced") else event["inc"])
            need(stack == [wanted_sum, 5], "wrong stack at the arithmetic join")
            event["after"] = int(stack[0])
            event["join_tick"] = state["ticks"]
        return original_step()

    program.execute_step = step.__get__(program, program.__class__)
    program.execute()
    need(not program.ips, "Native program did not terminate")
    need(len(crossings) == len(expected_increments) == 5, "wrong number of decimal iterations")
    need(state["gate_fetches"] == 5, "wrong number of physical gate fetches")
    need(state["forced_indices"] == ([] if force_index is None else [force_index]),
         "forced intervention did not occur exactly once at its target index")
    for index, event in enumerate(crossings):
        need(all(key in event for key in ("write_tick", "fetch_tick", "arm_tick", "join_tick", "after")),
             "incomplete gate/join witness")
        need(event["write_tick"] < event["fetch_tick"] < event["arm_tick"] < event["join_tick"],
             "gate write/fetch/arm/join order")
        original_fetch = "v" if event["inc"] < 0 else ">"
        need(event["physical_fetch"] == original_fetch, "physical gate opcode disagrees with increment sign")
        expected_exec = ((">" if original_fetch == "v" else "v")
                         if index == force_index else original_fetch)
        need(event["executed"] == expected_exec, "wrong executed gate opcode")
        need(event["arm"] == ("+" if expected_exec == ">" else "-"), "wrong arithmetic arm")
        if index:
            need(event["prior"] == crossings[index - 1]["after"],
                 "sum accumulator did not carry across decimal iterations")
    return {"fields": list(fields), "output": output.getvalue().split(),
            "ticks": state["ticks"], "route_sha256": route.hexdigest(),
            "forced_index": force_index, "crossings": crossings}


def main():
    source_path, output_path = sys.argv[1:]
    code = open(source_path, "rb").read()
    helper = open("qa/stage1_native_diverse_geometry.py", "rb").read()
    counts_ref = open("reference/work_counts.b98", "rb").read()
    save_ref = open("reference/save.b98", "rb").read()
    need(git_blob(code) == ACTIVE_PIN, "active production source pin")
    need(git_blob(helper) == HELPER_PIN, "independent Native oracle helper pin")
    need(git_blob(counts_ref) == COUNT_REF_PIN and git_blob(save_ref) == SAVE_REF_PIN,
         "independent Befunge reference pins")

    records = []
    for label, fields, force_index, increments in CASES:
        expected = expected_for(*fields)
        need(len(expected) == 7, "independent oracle did not return seven fields")
        healthy = run(code, fields, increments)
        need(healthy["output"] == expected, "healthy active-source/reference mismatch: " + label)
        target_increment = increments[force_index]
        counter_fields = signed_fields(fields, target_increment)
        need(all(counter_fields[i] == fields[i] for i in (0, 2)),
             "counterfactual changed a sign class")
        counter_expected = expected_for(*counter_fields)[:5] + expected[5:]
        mutated = run(code, fields, increments, force_index)
        need(mutated["output"] == counter_expected,
             "late forced-arm output differs from independent counterfactual references: " + label)
        need(mutated["output"][:5] != healthy["output"][:5] and
             mutated["output"][5:] == healthy["output"][5:],
             "causal intervention changed the wrong output partition")
        need(mutated["route_sha256"] != healthy["route_sha256"],
             "forced later gate did not change the physical execution route")
        need(sum(1 for e in mutated["crossings"] if e.get("forced")) == 1,
             "late intervention was not uniquely recorded")
        records.append({
            "case": label, "fields": list(fields), "expected_increments": increments,
            "target_gate_index": force_index, "counterfactual_fields": list(counter_fields),
            "healthy": healthy, "forced_late": mutated,
            "healthy_native_reference": expected,
            "counterfactual_native_reference": counter_expected
        })
        print("QA31CV_LATE_GATE_CASE_PASS", label,
              "target_iteration", force_index, "target_increment", target_increment,
              "seven_fields", len(mutated["output"]))
        sys.stdout.flush()

    result = {
        "schema": "befunge-qa31cv-late-decimal-gate-native-v1",
        "project_id": "PC-BRANCH-BEFUNGE98-KYRGYZ",
        "active_source_git_blob": ACTIVE_PIN,
        "oracle_helper_git_blob": HELPER_PIN,
        "reference_git_blobs": {"work_counts": COUNT_REF_PIN, "save": SAVE_REF_PIN},
        "candidate_native_runs": 8,
        "independent_reference_invocations": 24,
        "late_gate_counterfactuals": 4,
        "cases": records
    }
    with open(output_path, "wb") as stream:
        stream.write(json.dumps(result, sort_keys=True, indent=2) + "\n")
    print("QA31CV_LATE_DECIMAL_GATE_NATIVE_PASS cases=4 candidate_runs=8 "
          "forced_late_iterations=4 reference_invocations=24")


if __name__ == "__main__":
    main()
