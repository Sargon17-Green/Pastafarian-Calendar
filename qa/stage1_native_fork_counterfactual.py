#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Historical Native PyFunge counterfactual for frozen reflective | routing.

Native Befunge-98 performs every arithmetic operation. Python only substitutes
ONE boolean input operand immediately BEFORE an actually executed native '|'
instruction, leaving the instruction and source byte unchanged. The control
case runs the identical native Program with no substitution. The forced-opposite
case must measurably change results or fail to terminate within an explicit
step limit. No non-Befunge calendar implementation or numerical oracle.
"""
from __future__ import print_function
import StringIO
import sys

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as suite

SOURCE = "qa/interleaved_work_counts_pre_two_valid_w_production.b98"
GATE = (951, 1335)
CASES = ("zero_equal", "foundation_cross", "forward_short", "mixed_small")
STEP_LIMIT = 160000
with open(SOURCE, "rb") as reader:
    CODE = reader.read()

def require(ok, message):
    if not ok:
        raise AssertionError(message)

class NativeBoundedNonTermination(Exception):
    pass

def run_native(raw, opposite):
    stdio = StringIO.StringIO()
    platform = BufferedPlatform([], {}, stdin=StringIO.StringIO(raw),
                                stdout=stdio)
    program = Program(Befunge98, platform=platform)
    program.load_code(CODE)
    program.create_ip()
    bound_step = program.execute_step
    gates = []
    steps = [0]

    def watched_step(self):
        steps[0] += 1
        if steps[0] > STEP_LIMIT:
            raise NativeBoundedNonTermination("Native step budget exceeded")
        if program.ips:
            ip = program.ips[0]
            if tuple(ip.position) == GATE:
                require(program.space.get(ip.position) == ord("|"),
                        "observed fork cell no longer executes native |")
                stack = ip.stack[0]
                require(len(stack) >= 1, "native | reached without operand")
                original = stack[-1]
                original_nonzero = bool(original)
                if opposite:
                    stack[-1] = 0 if original_nonzero else 1
                gates.append((int(original_nonzero), int(bool(stack[-1])),
                              len(stack)))
        return bound_step()

    program.execute_step = watched_step.__get__(program, program.__class__)
    exit_status = "normal"
    try:
        program.execute()
    except NativeBoundedNonTermination:
        exit_status = "step-limit"
    finally:
        del program.execute_step
    return {"stdout": stdio.getvalue().split(), "steps": steps[0],
            "gate_observations": gates, "exit_status": exit_status,
            "live_ips": len(program.ips)}

def main():
    cases = dict((label, (fields, valid)) for label, fields, valid
                 in suite.CASES)
    observed_classes = set()
    for label in CASES:
        fields, valid = cases[label]
        require(valid, "counterfactual requires meaningful valid result")
        raw = " ".join(map(str, fields)) + "\n"
        expected = suite.expected_for(*fields)
        authoritative = suite.native(SOURCE, raw)
        require(authoritative == expected and len(expected) == 7,
                "independent native Befunge reference mismatch " + label)
        control = run_native(raw, False)
        require(control["exit_status"] == "normal" and
                control["stdout"] == expected and control["live_ips"] == 0,
                "unmodified Native Program disagrees with CLI or reference " +
                label + ": " + repr(control))
        require(len(control["gate_observations"]) == 1,
                "unexpected number of Native conditional fork events " +
                label + ": " + repr(control["gate_observations"]))
        cond, untouched, depth = control["gate_observations"][0]
        require(cond == untouched and depth >= 1,
                "sham fork observer accidentally changed the operand")
        observed_classes.add(cond)
        mutant = run_native(raw, True)
        require(len(mutant["gate_observations"]) >= 1,
                "forced-opposite case never encountered the Native | instruction")
        a, b, _ = mutant["gate_observations"][0]
        require(a == cond and b == 1 - cond,
                "counterfactual failed to invert precisely the observed Native condition")
        changed = (mutant["exit_status"] != "normal" or
                   mutant["stdout"] != expected or
                   mutant["live_ips"] != 0)
        require(changed,
                "opposite-branch Native counterfactual is observationally inert: "+
                label)
        print("NATIVE_FORK_OPPOSITE_CONDITION_NON_INERT_PASS", label,
              "original_nonzero", cond, "forced_nonzero", b,
              "normal_control_steps", control["steps"],
              "mutant_steps", mutant["steps"],
              "mutant_status", mutant["exit_status"],
              "mutant_outputs_different", mutant["stdout"] != expected)
        sys.stdout.flush()
    require(observed_classes == set((0,1)),
            "Native controls did not exercise both actual conditional arms")
    print("NATIVE_FROZEN_REFLECTIVE_FORK_CONTROLLED_COUNTERFACTUAL_PASS",
          len(CASES), "cases", "both_native_route_classes", "observed")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; controlled Native gate proof only")

if __name__ == "__main__":
    main()
