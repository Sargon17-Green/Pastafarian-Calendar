#!/usr/bin/env python3
"""Stage20 source-independent Python mathematical fixtures for the original FALSE runtime.

No imports from production or the JS oracle. Physical heap handles are allocated
explicitly and all generated expectations are recalculated using Python integers.
Source generation and static QA do not constitute Native execution or acceptance.
"""
import hashlib
import json
from pathlib import Path

PROJECT = "PC-BRANCH-FALSE-ARABIC"
VECTORS = Path("test/stage20_initial_bowls_design_vectors.json")
M = (1 << 127) - 1
COEFFICIENTS = (17, 19, 23, 29, 31, 37)
FINAL = "STAGE20_NATIVE_ALL_CASES_OK"


def literal(value):
    assert isinstance(value, int)
    return str(-value) + "_" if value < 0 else str(value)


def raw_bigint(value):
    assert isinstance(value, int) and value >= 0
    if value == 0:
        return [0, 1, 0]
    digits = []
    while value:
        digits.append(value % 512)
        value //= 512
    return [1, len(digits), *digits]


def compute(counts):
    assert len(counts) == 5
    c, t, d, s, direction = counts
    assert min(counts[:4]) >= 0 and direction in (1, 2, 3)
    return [1 + ((c + i * t + d + s + direction + a * a + i - 1) % M)
            for i, a in enumerate(COEFFICIENTS, 1)]


def cases():
    data = json.loads(VECTORS.read_text(encoding="utf-8"))
    assert data["project_id"] == PROJECT and data["stage"] == 20
    assert len(data["vectors"]) == 13
    result = []
    for record in data["vectors"]:
        counts = list(map(int, record["counts"]))
        expected = list(map(int, record["expected"]))
        assert expected == compute(counts), ("DESIGN_WITNESS_MISMATCH", record["label"])
        result.append((record["label"], counts, expected))
    # Deterministic repeat without assuming identity of newly allocated handles.
    result.append(("replay-zero", result[0][1][:], result[0][2][:]))
    result.append(("replay-multiple-M", result[3][1][:], result[3][2][:]))
    return result


def build_bigint(handle, value):
    return "z;" + handle + ":" + "".join(literal(x) + "a;!" for x in raw_bigint(value))


def bigint_assertions(handle, value, tag):
    expected = raw_bigint(value)
    code = []
    for index, field in enumerate(expected):
        where = handle + ";g;!" if index == 0 else f"{handle};{index}+g;!"
        code.append(f'{where}{literal(field)}=~["{tag}_CELL_{index}_FAIL"0 0/]?')
    return code, len(expected)


def positive(mutant=None):
    code = ["{ Stage20 direct output table fixture; exact original interpreter, independent Python arithmetic. }"]
    labels = []
    checks = 0
    for number, (_label, counts, expected) in enumerate(cases()):
        tag = f"STAGE20_CASE_{number:03d}"
        labels.append(tag + "_OK")
        for variable, value in zip(("u", "v", "w", "t"), counts[:4]):
            code.append(build_bigint(variable, value))
        c, t, d, s, direction = counts
        code.append(f"z;y:5a;!u;a;!v;a;!w;a;!t;a;!{literal(direction)}a;!")
        code.append("z;b:y;a;!b;s:b;37h;!!o:")
        code.append(f'o;g;!6=~["{tag}_OUT_HEADER_FAIL"0 0/]?')
        checks += 1
        code.append(f'o;y;-0=["{tag}_OUT_ALIAS_FAIL"0 0/]?')
        checks += 1
        for index, item in enumerate(expected, 1):
            code.append(f"o;{index}+g;!r:")
            actual = item
            if mutant == "wrong_numeric" and number == 0 and index == 1:
                actual = item + 1
            shape, n = bigint_assertions("r", actual, f"{tag}_OUT_{index}")
            if mutant == "wrong_sign" and number == 0 and index == 1:
                shape[0] = shape[0].replace('1=~', '0=~', 1)
            code.extend(shape)
            checks += n
        code.append(f'y;g;!5=~["{tag}_INPUT_HEADER_FAIL"0 0/]?')
        checks += 1
        for index, variable in enumerate(("u", "v", "w", "t"), 1):
            code.append(f'y;{index}+g;!{variable};-0=~["{tag}_INPUT_HANDLE_{index}_FAIL"0 0/]?')
            shape, n = bigint_assertions(variable, counts[index - 1], f"{tag}_INPUT_{index}")
            code.extend(shape)
            checks += n + 1
        code.append(f'y;5+g;!{literal(direction)}=~["{tag}_INPUT_DIRECTION_FAIL"0 0/]?')
        code.append(f'b;g;!y;-0=~["{tag}_ARGUMENT_FAIL"0 0/]?')
        checks += 2
        code.append(f'"{tag}_OK"10,')
    code.append(f'"{FINAL}"10,')
    code.append("[z;0>][%z;1-z:]#")
    return "\n".join(code) + "\n", labels, checks


def invalid(name):
    assert name in ("header4", "header6", "direction0", "direction4")
    head = 4 if name == "header4" else 6 if name == "header6" else 5
    direction = 0 if name == "direction0" else 4 if name == "direction4" else 1
    code = ["{ Stage20 fully allocated but semantically invalid record control. }"]
    for handle in ("u", "v", "w", "t"):
        code.append(build_bigint(handle, 0))
    code.extend([
        f"z;y:{literal(head)}a;!u;a;!v;a;!w;a;!t;a;!{literal(direction)}a;!",
        "z;b:y;a;!b;s:b;37h;!!o:",
        '"STAGE20_INVALID_ACCEPTED"10,',
        "[z;0>][%z;1-z:]#",
    ])
    return "\n".join(code) + "\n"


def integrity():
    assert compute([0, 0, 0, 0, 1]) == [291, 364, 533, 846, 967, 1376]
    assert compute([M - 291, 0, 0, 0, 1])[0] == M
    program, labels, checks = positive()
    assert len(labels) == 15 and len(set(labels)) == 15
    assert len(set(cases()[i][0] for i in range(15))) == 15
    summary = {
        "project_id": PROJECT, "stage": 20, "cases": len(labels),
        "output_bigints": len(labels) * 6, "assertions": checks,
        "ordered_markers": labels, "final": FINAL,
        "body_sha256": hashlib.sha256(program.encode("utf-8")).hexdigest(),
        "invalid": ["header4", "header6", "direction0", "direction4"],
        "mutants": ["wrong_numeric", "wrong_sign"],
        "native_executed": False, "accepted": False,
    }
    return summary


if __name__ == "__main__":
    print(json.dumps(integrity(), indent=2, sort_keys=True))
