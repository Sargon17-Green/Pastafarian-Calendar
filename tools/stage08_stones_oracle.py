#!/usr/bin/env python3
"""Independent integer oracle and generated FALSE checks for 46 stone rows."""

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage08_stones_46.false"
MODULUS = (1 << 127) - 1


def save(value):
    assert value > 0
    return (value - 1) % MODULUS + 1


def rows():
    result = [(17, 29, 43, 71, 101)]
    for number in range(2, 47):
        a, b, c, d, e = result[-1]
        result.append((save(a * a + 3 * b + number),
                       save(b * b + 5 * c + a),
                       save(c * c + 7 * d + b),
                       save(d * d + 11 * e + c),
                       save(e * e + 13 * a + d)))
    assert len(result) == 46 and all(len(row) == 5 for row in result)
    assert all(0 < value <= MODULUS for row in result for value in row)
    return result


def bigint(value):
    assert value > 0
    digits = []
    while value:
        digits.append(value % 512)
        value //= 512
    return "z;s:1a;!" + str(len(digits)) + "a;!" + "".join(f"{d}a;!" for d in digits)


def build():
    values = rows()
    lines = ["{ المرحلة 8: اختبار كل 230 قيمة عبر قارئ المرحلة 5. }",
             '[~["STAGE8_STONES_FAILURE"10,0 0/]?]e:',
             "z;b:0a;!b;24h;!!q:",
             "q;g;!46=e;!"]
    for index, row in enumerate(values, 1):
        lines.append(f"q;{index}+g;!p:p;g;!5=e;! {{ طول الصف {index}. }}")
        for kind, value in enumerate(row, 1):
            lines.append(f"z;b:q;a;!{index}a;!{kind}a;!b;21h;!!v:")
            lines.append(bigint(value))
            lines.append("z;b:v;a;!s;a;!b;5h;!!0=e;!")
        lines.append(f'"STAGE8_STONES_ROW_{index:02d}_OK"10,')
    for index in (1, 46):
        for kind, value in enumerate(values[index - 1], 1):
            lines.append(f"z;b:q;a;!{index}a;!{kind}a;!b;21h;!!t:")
            lines.append(f"z;b:q;a;!{index}a;!{kind}a;!b;21h;!!v:")
            lines.append("t;v;=e;! { ثبات مقبض الحجر في قراءتين. }")
            lines.append(bigint(value))
            lines.append("z;b:v;a;!s;a;!b;5h;!!0=e;! { قيمة القراءة المتأخرة. }")
    lines.extend(('"STAGE8_STONES_46_ROWS_230_VALUES_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, values = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 8,
                      "native_evidence": False, "row_count": 46,
                      "kind_count": 5, "result_assertions": 240,
                      "replay_assertions": 10, "identity_assertions": 10,
                      "shape_assertions": 47, "modulus": str(MODULUS),
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "rows": [[str(v) for v in row] for row in values]},
                     indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
