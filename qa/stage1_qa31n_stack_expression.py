#!/usr/bin/env python3
"""QA31N: independently replay three original signed finite gate expressions.

No interpreter run. SHA-pinned QA31L Native artifact is the only dynamic input.
Models only the bounded post-g arithmetic subtraces; never a whole-program oracle.
"""
import argparse
import copy
import json
from pathlib import Path


# (source row, g tick, j tick, observed p last writer, read address, read value)
GATES = ((29, 1229, 1254, 1082, (3, 49), 1),
         (32, 1349, 1398, 146, (1, 49), 0),
         (38, 1779, 1829, 1684, (1, 49), 1))


def need(condition, why):
    if not condition:
        raise AssertionError(why)


def const(x):
    return ("c", x)


def calc(op, values):
    if op in ("+", "-", "*", ">"):
        need(len(values) >= 2, "binary underflow")
        b = values.pop()
        a = values.pop()
        x, y = a[0], b[0]
        if op == "+":
            v = x + y
        elif op == "-":
            v = x - y
        elif op == "*":
            v = x * y
        else:
            v = int(x > y)
        left, right = a[1], b[1]
        if left[0] == right[0] == "c":
            expr = const(v)
        elif op == "+" and left == const(0):
            expr = right
        elif op == "+" and right == const(0):
            expr = left
        elif op == "-" and right == const(0):
            expr = left
        elif op == "*" and (left == const(0) or right == const(0)):
            expr = const(0)
        elif op == "*" and left == const(1):
            expr = right
        elif op == "*" and right == const(1):
            expr = left
        else:
            expr = ({"+": "add", "-": "sub", "*": "mul", ">": "gt"}[op], left, right)
        values.append((v, expr))
    else:
        need(op == "!" and values, "unary underflow")
        a = values.pop()
        v = int(a[0] == 0)
        expr = const(v) if a[1][0] == "c" else ("not", a[1])
        values.append((v, expr))


def replay_one(steps, row, read_tick, j_tick, writer, address, value):
    g = steps[read_tick - 1]
    need(g["t"] == read_tick and g["ip"] == [57, row] and g["op"] == ord("g"),
         "wrong signed read or source row")
    need(g["pre"][-2:] == list(address) and g["post"] == [value],
         "wrong g address/value or unexpected residual stack")
    state = [(value, ("g", read_tick))]
    covered = 0
    for tick in range(read_tick + 1, j_tick + 1):
        s = steps[tick - 1]
        need(s["t"] == tick and s["ip"][1] == row and not s["string"],
             "row/tick/stringmode outside bounded scope")
        need(s["pre"] == [v for v, _ in state], "signed pre-stack != arithmetic replay")
        c = chr(s["op"])
        if c in "0123456789abcdef":
            state.append((int(c, 16), const(int(c, 16))))
        elif c in "+-*`!":
            calc(">" if c == "`" else c, state)
        elif c == "j":
            need(tick == j_tick and len(state) == 1, "unanticipated gate/stack shape")
            n, expr = state.pop()
            need(s["next"] == [s["ip"][0] + (n + 1) * s["delta"][0],
                                row + (n + 1) * s["delta"][1]], "j successor")
        else:
            raise AssertionError("unmodeled arithmetic opcode at %d: %r" % (tick, c))
        need(s["post"] == [v for v, _ in state], "arithmetic post-stack mismatch at %d" % tick)
        covered += 1
    need(not state, "gate must consume its one result")
    return {"row": row, "reader_tick": read_tick, "writer_tick": writer,
            "cell": list(address), "read_value": value, "j_tick": j_tick,
            "j_operand": n, "expression": expr, "post_g_steps": covered,
            "j_successor": steps[j_tick - 1]["next"]}


def expressions(steps):
    need(len(steps) == 2046, "original STEP count")
    results = [replay_one(steps, *g) for g in GATES]
    expected = (("mul", ("g", 1229), const(61)),
                ("mul", ("gt", ("g", 1349), const(3)), const(61)),
                ("mul", ("not", ("sub", ("g", 1779), const(4))), const(61)))
    for r, expr in zip(results, expected):
        need(r["expression"] == expr, "unexpected source-derived expression at row %d" % r["row"])
    need([r["j_operand"] for r in results] == [61, 0, 0], "observed gate vector")
    need([r["j_successor"] for r in results] == [[151, 29], [114, 32], [115, 38]],
         "three physical successors")
    return results


def negative_controls(steps):
    mutations = [
        (1229, "post", -1, 0), (1349, "post", -1, 1),
        (1779, "post", -1, 0),
        (1253, "op", None, ord("+")),
        (1373, "op", None, ord("-")),
        (1397, "op", None, ord("+")),
        (1803, "op", None, ord("+")),
        (1804, "op", None, ord("0")),
        (1828, "op", None, ord("+")),
        (1829, "next", 0, 176),
        (1254, "pre", -1, 60),
        (1398, "post", None, [1]),
        (1826, "post", -1, 60),
    ]
    rejected = 0
    for tick, field, index, bad in mutations:
        altered = copy.deepcopy(steps)
        if index is None:
            altered[tick - 1][field] = bad
        else:
            altered[tick - 1][field][index] = bad
        try:
            expressions(altered)
        except (AssertionError, IndexError, KeyError, TypeError, ValueError):
            rejected += 1
        else:
            raise AssertionError("hostile expression mutation escaped at %d" % tick)
    need(rejected == len(mutations) == 13, "hostile mutation count")
    return rejected


def audit(steps, rows):
    from stage1_qa31m_signed_owner_route import check as source_owner_check
    owner = source_owner_check(steps, rows)  # Source + p/g integrity of all 2046 signed STEPs.
    r = expressions(steps)  # Separate arithmetic oracle for the three dynamic expressions.
    reads = {v["tick"]: v for v in owner["reads"]}
    for rec in r:
        event = reads[rec["reader_tick"]]
        need(event["owner_kind"] == "p" and
             event["owner_tick"] == rec["writer_tick"] and
             event["value"] == rec["read_value"] and
             event["cell"] == rec["cell"], "p->g ownership is not source grounded")
    rejected = negative_controls(steps)
    return {"schema": "qa31n-source-pinned-stack-expression-v1",
            "project_id": "PC-BRANCH-BEFUNGE98-KYRGYZ",
            "original_native_steps": len(steps),
            "original_native_artifact_id": 13057227833,
            "new_native_cases": 0,
            "expression_replay_steps": sum(q["post_g_steps"] for q in r),
            "gate_table": r, "expression_hostile_rejected": rejected,
            "prior_qa31m_source_owner_scope": {"p": owner["p_count"],
                         "g": owner["g_count"], "j": owner["j_count"], "x": owner["x_count"]},
            "global_source_reachability_proven": False,
            "full_functional_qa_pass": False,
            "geometric_spaghetti_qa_pass": False, "stage1_pass": False}


def main():
    p = argparse.ArgumentParser()
    p.add_argument("original_source")
    p.add_argument("original_actions_zip")
    p.add_argument("--out", default="qa31n_expression.json")
    a = p.parse_args()
    from stage1_qa31m_original_native_route_audit import load_signed
    from stage1_qa31m_signed_owner_route import source as pinned_source
    rows = pinned_source(a.original_source)
    steps = load_signed(Path(a.original_actions_zip).read_bytes())
    report = audit(steps, rows)
    Path(a.out).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print("QA31N_EXPRESSION_PROVENANCE_PASS")
    print("QA31N_GATES_61_0_0")
    print("QA31N_HOSTILE_13_OF_13")
    print("QA31N_NO_NATIVE_NO_STAGE1_PASS")


if __name__ == "__main__":
    main()