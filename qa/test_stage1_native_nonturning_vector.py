#!/usr/bin/env python3
"""QA-only: Native BF98 executed straight instructions cannot rotate the IP.

Synthetic tests run without PyFunge. Optional archive or output folder
replays independent saved Native evidence, never certifying Stage 1.
"""
import copy
import json
import sys
import zipfile
from pathlib import Path
import stage1_native_four_cell_full_postfork_trace_audit as audit


def reject(source, run, name, prefork=False, expected_error=None):
    try:
        audit.verify_run(run, source, require_prefork=prefork)
    except AssertionError as exc:
        if expected_error is not None and expected_error not in str(exc):
            raise AssertionError(
                "Rejected for the wrong reason in " + name + ": " + str(exc)
            ) from exc
        print("EXPECTED_STRAIGHT_VECTOR_REJECTION", name)
        return
    raise AssertionError("Forged nonturning Native IP direction accepted: " + name)


def fixture():
    # End the 514-instruction synthetic path with an executed halt.
    row = b" " * 10 + b"p" + b" " * 9 + b"g" + b" " * 492 + b"@" + b" " * 107
    source = [row]
    trace = [[i + 2, i, 0, 1, 0, row[i], 0] for i in range(514)]
    run = dict(
        status="normal", remaining_ips=0, steps=515,
        gate=dict(step=1, original=0, executed=0),
        complete_postfork_trace=trace,
        first_512_motion=[e[1:5] for e in trace[:512]],
        native_p_history=[dict(tick=12, coordinate=[700, 0], value="7")],
        native_g_history=[dict(tick=22, coordinate=[701, 0],
                               read_before="32", returned="32")],
        total_p_writes=1, total_g_reads=1)
    return source, run


def synthetic():
    source, run = fixture()
    row = bytearray(source[0])
    row[100] = ord("3")
    source = [bytes(row)]
    run["complete_postfork_trace"][100][5] = ord("3")
    audit.verify_run(run, source)
    # Negative control: normal-status metadata cannot excuse a missing executed @.
    no_halt = copy.deepcopy(run)
    no_halt["complete_postfork_trace"][-1][5] = ord(" ")
    no_halt_source = [source[0][:513] + b" " + source[0][514:]]
    reject(no_halt_source, no_halt, "missing_executed_halt",
           expected_error="without executed terminating @")
    altered = copy.deepcopy(run)
    altered["complete_postfork_trace"][101][3:5] = [0, 1]
    altered["first_512_motion"][101] = altered["complete_postfork_trace"][101][1:5]
    reject(source, altered, "digit_spontaneous_turn",
           expected_error="nonturning opcode changed IP direction")

    source, run = fixture()
    row = bytearray(source[0])
    row[200:203] = b'"p"'
    source = [bytes(row)]
    for index, mode in ((200, 0), (201, 1), (202, 1)):
        run["complete_postfork_trace"][index][5:7] = [row[index], mode]
    audit.verify_run(run, source)
    altered = copy.deepcopy(run)
    altered["complete_postfork_trace"][202][3:5] = [0, 1]
    altered["first_512_motion"][202] = altered["complete_postfork_trace"][202][1:5]
    reject(source, altered, "quoted_p_spontaneous_turn",
           expected_error="nonturning opcode changed IP direction")

    source, run = fixture()
    row = bytearray(source[0])
    row[600:602] = b"0|"
    source = [bytes(row)]
    run["steps"] += 1
    run["gate"]["step"] += 1
    for e in run["complete_postfork_trace"]:
        e[0] += 1
    for e in run["native_p_history"] + run["native_g_history"]:
        e["tick"] += 1
    run["complete_prefork_trace"] = [
        [1, 600, 0, 1, 0, ord("0"), 0],
        [2, 601, 0, 1, 0, ord("|"), 0],
    ]
    audit.verify_run(run, source, require_prefork=True)
    altered = copy.deepcopy(run)
    altered["complete_prefork_trace"][1][3:5] = [0, 1]
    reject(source, altered, "prefork_digit_spontaneous_turn", prefork=True,
           expected_error="nonturning opcode changed IP direction")
    print("NATIVE_THREE_STRAIGHT_VECTOR_SYNTHETIC_CONTROLS_PASS")


def historical(path):
    path = Path(path)
    if path.is_dir():
        source = (path / "four_cell_candidate.b98").read_bytes().split(b"\n")
        data = json.loads((path / "native_full_postfork_four_pairs.json").read_text())
    else:
        with zipfile.ZipFile(path) as z:
            if z.testzip() is not None:
                raise AssertionError("Native archive ZIP CRC failure")
            source = z.read("four_cell_candidate.b98").split(b"\n")
            data = json.loads(z.read("native_full_postfork_four_pairs.json"))
    checks = []
    for row in data["records"]:
        for side in ("control", "forced"):
            run = row[side]
            audit.verify_run(run, source, require_gate_anchor=True)
            transitions = sum(audit.straight_instruction(z[5], z[6])
                              for z in run["complete_postfork_trace"][:-1])
            checks.append((row["label"], side, transitions))
    if len(checks) != 8 or min(x[2] for x in checks) <= 0:
        raise AssertionError("Eight real Native nonturning paths not verified")
    sample = copy.deepcopy(data["records"][0]["control"])
    trace = sample["complete_postfork_trace"]
    if trace[515][5] != ord("0"):
        raise AssertionError("Historical actual digit witness changed")
    prior = trace[516][3:5]
    trace[516][3:5] = [prior[1], -prior[0]]
    reject(source, sample, "historical_native_digit_turn",
           expected_error="nonturning opcode changed IP direction")
    print("NATIVE_EIGHT_HISTORICAL_NONTURNING_TRAJECTORIES_PASS",
          sum(x[2] for x in checks))


def cardinal_axis_regression():
    """Cardinal BF98 nonturning steps cannot teleport perpendicular to travel.

    The forged successor retains its original direction and its physical
    opcode byte; without the axis invariant an old auditor accepted it.
    """
    source, run = fixture()
    row = bytearray(source[0])
    row[100] = ord("3")
    source = [bytes(row), bytes(row)]
    run["complete_postfork_trace"][100][5] = ord("3")
    audit.verify_run(run, source)
    sideways = copy.deepcopy(run)
    sideways["complete_postfork_trace"][101][2] = 1
    sideways["first_512_motion"][101] = sideways["complete_postfork_trace"][101][1:5]
    reject(source, sideways, "postfork_digit_perpendicular_teleport",
           expected_error="post-fork nonturning opcode left cardinal travel axis")

    # The same requirement must hold during the recorded Native pre-fork path.
    source, run = fixture()
    row = bytearray(source[0])
    row[600:602] = b"0|"
    source = [bytes(row), bytes(row)]
    run["steps"] += 1
    run["gate"]["step"] += 1
    for event in run["complete_postfork_trace"]:
        event[0] += 1
    for event in run["native_p_history"] + run["native_g_history"]:
        event["tick"] += 1
    run["complete_prefork_trace"] = [
        [1, 600, 0, 1, 0, ord("0"), 0],
        [2, 601, 0, 1, 0, ord("|"), 0],
    ]
    audit.verify_run(run, source, require_prefork=True)
    sideways = copy.deepcopy(run)
    sideways["complete_prefork_trace"][1][2] = 1
    reject(source, sideways, "prefork_digit_perpendicular_teleport",
           prefork=True,
           expected_error="pre-fork nonturning opcode left cardinal travel axis")
    print("NATIVE_CARDINAL_TRAVEL_AXIS_TWO_FALSIFICATIONS_REJECT_PASS")



def fixed_turn_axis_regression():
    # The original verifier checked the new velocity after a fixed cardinal
    # turn, but allowed the next IP to appear on a parallel, distant line.
    # Keep source bytes and the following 313 steps consistent with that
    # forged line, so only the missing turn-axis contract can reject it.
    source, run = fixture()
    row = bytearray(source[0])
    row[200] = ord(">")
    source = [bytes(row), bytes(row)]
    run["complete_postfork_trace"][200][5] = ord(">")
    audit.verify_run(run, source)

    warped = copy.deepcopy(run)
    for entry in warped["complete_postfork_trace"][201:]:
        entry[2] = 1
    warped["first_512_motion"] = [
        entry[1:5] for entry in warped["complete_postfork_trace"][:512]
    ]
    reject(source, warped, "postfork_fixed_east_lateral_teleport",
           expected_error="post-fork fixed turn successor left directed axis")

    # Repeat before the physical | gate. Anchor-free generic replay permits
    # the synthetic gate at either row, but no cardinal > can move between
    # the two rows. Post-fork evidence, p/g receipts and byte provenance
    # remain otherwise unchanged.
    source, run = fixture()
    row = bytearray(source[0])
    row[600:602] = b">|"
    source = [bytes(row), bytes(row)]
    run["steps"] += 1
    run["gate"]["step"] += 1
    for entry in run["complete_postfork_trace"]:
        entry[0] += 1
    for entry in run["native_p_history"] + run["native_g_history"]:
        entry["tick"] += 1
    run["complete_prefork_trace"] = [
        [1, 600, 0, 1, 0, ord(">"), 0],
        [2, 601, 0, 1, 0, ord("|"), 0],
    ]
    audit.verify_run(run, source, require_prefork=True)
    warped = copy.deepcopy(run)
    warped["complete_prefork_trace"][1][2] = 1
    reject(source, warped, "prefork_fixed_east_lateral_teleport",
           prefork=True,
           expected_error="pre-fork fixed turn successor left directed axis")
    print("NATIVE_FIXED_TURN_AXIS_TWO_FORGERIES_REJECT_PASS")


if __name__ == "__main__":
    synthetic()
    fixed_turn_axis_regression()
    cardinal_axis_regression()
    if len(sys.argv) == 2:
        historical(sys.argv[1])
    else:
        print("HISTORICAL_NATIVE_NOT_SUPPLIED_SYNTHETIC_ONLY")
