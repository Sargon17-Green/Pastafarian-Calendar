#!/usr/bin/env python3
"""Stage22 allocated-record fixtures and bounded original-FALSE execution."""
import hashlib
import itertools
import resource
import subprocess
import time
from pathlib import Path

M = (1 << 127) - 1
PERMS = list(itertools.permutations(range(1, 7)))
E = Path("evidence/stage22_acceptance")
MARKER = "STAGE22_CASE_OK"
LIMIT = 2 * 1024**3
MUTANT_INPUT = [M, 1, M - 1, 2, 3, M - 2]
FILES = (
    "src/bigint.false",
    "src/monster_bootstrap.false",
    "test/normative_reference.false",
    "tools/stage22_batch_bowls_design_oracle.py",
    "evidence/stage22_design_oracle_2026-11-25.json",
    "tools/stage22_native_diagnostic.py",
    "tools/stage22_native_acceptance.py",
    "tools/stage22_offline_audit.py",
    "RUN_STAGE22.md",
    "DEVELOPMENT_STAGE.md",
    ".github/workflows/false-arabic-stage22-acceptance.yml",
    ".github/workflows/canonical-names-lock.yml",
)
OP = b'z;39=~["E_BOWL_BATCH_LAYOUT"'
LOOP = b" 1i:\n [i;13<]["
MUTANTS = {
    "t_offset_149_to_148": (
        (b"z;b:v;a;!149a;!b;23h;!!v:", b"z;b:v;a;!148a;!b;23h;!!v:"),
    ),
    "rank_modulus_7_to_6": (
        (b"z;b:7a;!b;0h;!!v:", b"z;b:6a;!b;0h;!!v:"),
    ),
    "swap_neighbor_weights": (
        (b"z;b:s;a;!3a;!b;23h;!!e:", b"z;b:s;a;!5a;!b;23h;!!e:"),
        (b"z;b:l;a;!5a;!b;23h;!!f:", b"z;b:l;a;!3a;!b;23h;!!f:"),
    ),
    "omit_position_squared": (
        (b"z;b:p;a;!b;0h;!!v:", b"z;b:0a;!b;0h;!!v:"),
    ),
    "cross_weight_7_to_6": (
        (b"z;b:n;a;!7a;!b;23h;!!n:", b"z;b:n;a;!6a;!b;23h;!!n:"),
    ),
}
INVALIDS = {
    "outer_zero": "RECORD_LENGTH",
    "outer_two": "RECORD_LENGTH",
    "bowls5": "BOWLS_LENGTH",
    "bowls7": "BOWLS_LENGTH",
    "sign_zero": "BIG_SIGN",
    "sign_negative": "BIG_SIGN",
    "sign_two": "BIG_SIGN",
    "length_zero": "BIG_LENGTH",
    "length_sixteen": "BIG_LENGTH",
    "digit_negative": "BIG_DIGIT",
    "digit_512": "BIG_DIGIT",
    "digit_negative_high": "BIG_DIGIT",
    "digit_512_high": "BIG_DIGIT",
    "top_zero": "BIG_TOP",
    "zero_value": "BIG_TOP",
    "overflow": "BIG_RANGE",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def literal(n):
    return str(-n) + "_" if n < 0 else str(n)


def limbs(n):
    if n == 0:
        return [1, 1, 0]
    sign = -1 if n < 0 else 1
    n = abs(n)
    digits = []
    while n:
        n, digit = divmod(n, 512)
        digits.append(digit)
    return [sign, len(digits), *digits]


def save_exact(value):
    if value <= 0:
        raise ValueError("SAVE input must be positive")
    return 1 + ((value - 1) % M)


def case(name):
    if name == "ones":
        return [1] * 6
    if name == "witness":
        return [2, 3, 5, 7, 11, 13]
    if name == "boundary":
        return [M, M - 1, 1, 512, 513, M - 5]
    raise ValueError(name)


def oracle(initial, steps):
    state = list(initial)
    trace = []
    for batch in range(1, steps + 1):
        total = save_exact(sum(state) + 6 + 149 * batch)
        rank = 4 + ((total - 4) % 7)
        order = PERMS[rank - 1]
        position = {bowl_id: p for p, bowl_id in enumerate(order, start=1)}
        next_state = [0] * 6
        for bowl_id in range(1, 7):
            p = position[bowl_id]
            left = state[order[(p - 2) % 6] - 1]
            right = state[order[p % 6] - 1]
            value = (
                state[bowl_id - 1] ** 2
                + 3 * left
                + 5 * right
                + total
                + batch
                + p * p
                + 7 * left * right
            )
            next_state[bowl_id - 1] = save_exact(value)
        state = next_state
        trace.append({
            "batch": batch,
            "total": str(total),
            "rank": rank,
            "order": list(order),
            "bowls": list(map(str, state)),
        })
    return state, trace


def mutant_oracle(initial, name):
    state = list(initial)
    batch = 1
    multiplier = 148 if name == "t_offset_149_to_148" else 149
    total = save_exact(sum(state) + 6 + multiplier * batch)
    modulus = 6 if name == "rank_modulus_7_to_6" else 7
    rank = 4 + ((total - 4) % modulus)
    order = PERMS[rank - 1]
    position = {bowl_id: p for p, bowl_id in enumerate(order, start=1)}
    result = [0] * 6
    for bowl_id in range(1, 7):
        p = position[bowl_id]
        left = state[order[(p - 2) % 6] - 1]
        right = state[order[p % 6] - 1]
        if name == "swap_neighbor_weights":
            neighbor_term = 5 * left + 3 * right
        else:
            neighbor_term = 3 * left + 5 * right
        p_squared = 0 if name == "omit_position_squared" else p * p
        cross_weight = 6 if name == "cross_weight_7_to_6" else 7
        value = (
            state[bowl_id - 1] ** 2
            + neighbor_term
            + total
            + batch
            + p_squared
            + cross_weight * left * right
        )
        result[bowl_id - 1] = save_exact(value)
    return result


def mutant_marker(name):
    expected, _ = oracle(MUTANT_INPUT, 1)
    observed = mutant_oracle(MUTANT_INPUT, name)
    for bowl_id, (good, bad) in enumerate(zip(expected, observed), start=1):
        a, b = limbs(good), limbs(bad)
        for cell in range(max(len(a), len(b))):
            av = a[cell] if cell < len(a) else 0
            bv = b[cell] if cell < len(b) else 0
            if av != bv:
                if cell < 2:
                    raise AssertionError(("mutant_is_not_first_numeric_digit", name, bowl_id, cell, good, bad))
                return f"STAGE22_OUT_BOWL_{bowl_id}_CELL_{cell}_FAIL"
    raise AssertionError("undetected mathematical mutant: " + name)


def ptr(index):
    return ("ptr", index)


def expression(value):
    if isinstance(value, tuple):
        return "x;" + str(value[1]) + "+"
    if isinstance(value, str):
        return value
    return literal(value)


def fixture(initial, steps, invalid=None):
    """Allocate all input cells in the FALSE heap; retain addresses for immutability checks."""
    cells = []

    def alloc(values):
        at = len(cells)
        cells.extend(values)
        return ptr(at)

    def big(value, bad=None):
        value_cells = limbs(value)
        if bad == "sign_zero":
            value_cells = [0, 1, 1]
        elif bad == "sign_negative":
            value_cells = [-1, 1, 1]
        elif bad == "sign_two":
            value_cells = [2, 1, 1]
        elif bad == "length_zero":
            value_cells = [1, 0]
        elif bad == "length_sixteen":
            value_cells = [1, 16] + [1] * 16
        elif bad == "digit_negative":
            value_cells = [1, 1, -1]
        elif bad == "digit_512":
            value_cells = [1, 1, 512]
        elif bad == "digit_negative_high":
            value_cells = [1, 2, -1, 1]
        elif bad == "digit_512_high":
            value_cells = [1, 2, 1, 512]
        elif bad == "top_zero":
            value_cells = [1, 2, 1, 0]
        elif bad == "zero_value":
            value_cells = [1, 1, 0]
        elif bad == "overflow":
            value_cells = limbs(M + 1)
        return alloc(value_cells)

    bad_names = {
        "sign_zero", "sign_negative", "sign_two", "length_zero", "length_sixteen",
        "digit_negative", "digit_512", "digit_negative_high", "digit_512_high",
        "top_zero", "zero_value", "overflow"
    }
    bad_big = invalid if invalid in bad_names else None
    bowl_handles = [big(value, bad_big if index == 0 else None) for index, value in enumerate(initial)]
    if invalid == "bowls7":
        bowl_handles.append(big(1))
    bowl_header = 5 if invalid == "bowls5" else 7 if invalid == "bowls7" else 6
    bowl_table = alloc([bowl_header, *bowl_handles])
    outer_header = 0 if invalid == "outer_zero" else 2 if invalid == "outer_two" else 1
    argument = alloc([outer_header, bowl_table])

    lines = [
        "{ Independent Stage22 fixture; every input record and BigInt is allocated. }",
        "z;x:",
    ]
    lines += [expression(value) + "a;!" for value in cells]
    lines += [expression(argument) + "b:", "b;39h;!!o:"]
    if invalid:
        lines += ['"STAGE22_INVALID_ACCEPTED"10,', "[z;0>][%z;1-z:]#"]
        return "\n".join(lines) + "\n", None, 0, {
            "input_bowls": list(map(str, initial)),
            "invalid": invalid,
            "expected_marker": "E_BOWL_BATCH_" + INVALIDS[invalid],
            "input_cells": cells,
            "bowl_handles": bowl_handles,
            "bowl_table": bowl_table,
            "argument": argument,
        }

    expected, _ = oracle(initial, steps)
    checks = 0

    def eq(expr, want, tag):
        nonlocal checks
        lines.append(expr + "r:r;" + expression(want) + '-0=~["' + tag + '"0 0/]?')
        checks += 1

    def neq(expr, want, tag):
        nonlocal checks
        lines.append(expr + "r:r;" + expression(want) + '-0=["' + tag + '"0 0/]?')
        checks += 1

    neq("o;", bowl_table, "STAGE22_OUTPUT_TABLE_ALIASES_INPUT")
    neq("o;", argument, "STAGE22_OUTPUT_TABLE_ALIASES_ARGUMENT")
    eq("o;g;!", 6, "STAGE22_OUTPUT_TABLE_LENGTH_FAIL")
    for bowl_id, value in enumerate(expected, start=1):
        lines.append(f"o;{bowl_id}+g;!t:")
        for input_index, handle in enumerate(bowl_handles, start=1):
            neq("t;", handle, f"STAGE22_OUTPUT_BOWL_{bowl_id}_ALIASES_INPUT_{input_index}")
        for prior_id in range(1, bowl_id):
            neq(f"o;{prior_id}+g;!", "t;", f"STAGE22_OUTPUT_BOWL_{bowl_id}_ALIASES_OUTPUT_{prior_id}")
        for cell, want in enumerate(limbs(value)):
            eq(f"t;{cell}+g;!", want, f"STAGE22_OUT_BOWL_{bowl_id}_CELL_{cell}_FAIL")
    for index, value in enumerate(cells):
        eq(f"x;{index}+g;!", value, f"STAGE22_INPUT_CELL_{index}_FAIL")
    lines += ['"' + MARKER + '"10,', "[z;0>][%z;1-z:]#"]
    record = {
        "input_bowls": list(map(str, initial)),
        "steps": steps,
        "expected_bowls": list(map(str, expected)),
        "expected_limbs": [limbs(value) for value in expected],
        "assertions": checks,
        "input_cells": cells,
        "bowl_handles": bowl_handles,
        "bowl_table": bowl_table,
        "argument": argument,
    }
    return "\n".join(lines) + "\n", expected, checks, record


def instrument(source, steps):
    if steps == 12:
        return source
    if not 1 <= steps < 12:
        raise ValueError(steps)
    assert source.count(LOOP) == 1, "nonunique Stage22 batch loop"
    replacement = b" 1i:\n [i;" + str(steps + 1).encode() + b"<]["
    return source.replace(LOOP, replacement, 1)


def unique_replace(source, old, new):
    assert old != new and source.count(old) == 1, ("NONUNIQUE_SOURCE_MUTATION", old)
    return source.replace(old, new, 1)


def mutate(source, name):
    assert source.count(OP) == 1, "Stage22 operation marker must be unique"
    at = source.index(OP)
    suffix = source[at:]
    for old, new in MUTANTS[name]:
        suffix = unique_replace(suffix, old, new)
    return source[:at] + suffix


def limits():
    resource.setrlimit(resource.RLIMIT_AS, (LIMIT, LIMIT))
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def execute(name, program, seconds, want=MARKER, exitcode=0):
    E.mkdir(parents=True, exist_ok=True)
    path = E / (name + ".false")
    path.write_bytes(program)
    start = time.monotonic()
    try:
        completed = subprocess.run(
            ["upstream/false_int", "-e", str(path)],
            capture_output=True,
            timeout=seconds,
            preexec_fn=limits,
            check=False,
        )
        code, stdout, stderr = completed.returncode, completed.stdout, completed.stderr
    except subprocess.TimeoutExpired as exc:
        code, stdout, stderr = 124, exc.stdout or b"", exc.stderr or b""
    elapsed = time.monotonic() - start
    (E / (name + ".stdout.txt")).write_bytes(stdout)
    (E / (name + ".stderr.txt")).write_bytes(stderr)
    (E / (name + ".exit_code.txt")).write_text(str(code) + "\n")
    normalized = stdout.replace(b"\r", b"").replace(b"\n", b"")
    passed = code == exitcode and normalized == want.encode() and not stderr
    return {
        "exit_code": code,
        "elapsed_seconds": round(elapsed, 3),
        "peak_child_rss_kib_cumulative": resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
        "timeout_seconds": seconds,
        "address_space_limit_bytes": LIMIT,
        "program_sha256": sha(program),
        "stdout_sha256": sha(stdout),
        "stderr_sha256": sha(stderr),
        "passed": passed,
    }


def self_check(source):
    assert len(INVALIDS) == 16 and len(MUTANTS) == 5
    assert source.count(OP) == 1
    durable_return = b"z;r:6a;!y;1+g;!a;!y;2+g;!a;!y;3+g;!a;!y;4+g;!a;!y;5+g;!a;!y;6+g;!a;!"
    assert source.count(durable_return) == 1, "missing durable direct six-bowl return"
    assert b"!y:k;g;!k:z;1-g;!" in source[source.index(OP):], "missing parent-frame restore"
    assert source.count(LOOP) == 1
    assert oracle([1] * 6, 1)[0] == [179, 182, 194, 187, 203, 214]
    assert oracle([2, 3, 5, 7, 11, 13], 1)[0] == [529, 349, 853, 394, 878, 599]
    for name in ("ones", "witness", "boundary"):
        for steps in (1, 6, 12):
            body, expected, checks, record = fixture(case(name), steps)
            assert body.count(MARKER) == 1 and expected and checks > 30
            assert len(record["expected_bowls"]) == 6
            assert body.count('+g;!r:r;t;-0=["STAGE22_OUTPUT_BOWL_') == 15
            instrumented = instrument(source, steps)
            assert (instrumented == source) == (steps == 12)
            if steps < 12:
                expected_loop = b" 1i:\n [i;" + str(steps + 1).encode() + b"<]["
                assert expected_loop in instrumented, ("malformed prefix loop", steps)
    for name in INVALIDS:
        body, expected, checks, record = fixture(case("witness"), 12, invalid=name)
        assert expected is None and checks == 0 and record["expected_marker"].startswith("E_BOWL_BATCH_")
    for name in MUTANTS:
        mutated = mutate(source, name)
        assert mutated != source
        assert instrument(mutated, 1) != source
        assert mutant_marker(name).startswith("STAGE22_OUT_BOWL_1_CELL_")
    print("STAGE22_FIXTURE_AND_MUTATION_SELF_CHECK_PASS")


if __name__ == "__main__":
    import sys
    self_check(Path("src/monster_bootstrap.false").read_bytes())
