#!/usr/bin/env python3
"""Independent Python multiplication oracle and original-FALSE fixture."""

import argparse
import hashlib
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage07_multiply_small_13.false"
M = (1 << 127) - 1
MAX_SMALL = 2147483647
CASES = ((0, 0), (0, MAX_SMALL), (1, 0), (1, 1), (511, 512),
         (-512, 513), (-1, 511), (M, 2), (M, 512), (-M, MAX_SMALL),
         ((1 << 256) - 1, 2), (-(1 << 256), 0),
         ((1 << 192) + 123456, MAX_SMALL))


def cell(n):
    return f"{-n}_" if n < 0 else str(n)


def literal(n, destination):
    assert destination in "suw"
    if -(1 << 31) < n < (1 << 31):
        return [f"z;b:{cell(n)}a;!b;0h;!!{destination}:"]
    digits = []
    value = abs(n)
    while value:
        digits.append(value % 512)
        value //= 512
    digits.reverse()
    out = [f"z;b:{digits[0]}a;!b;0h;!!{destination}:"]
    for digit in digits[1:]:
        out.append(f"z;b:{destination};a;!q;a;!b;14h;!!{destination}:")
        if digit:
            out.append(f"z;b:{digit}a;!b;0h;!!t:")
            out.append(f"z;b:{destination};a;!t;a;!b;9h;!!{destination}:")
    if n < 0:
        out.append(f"z;b:{destination};a;!b;8h;!!{destination}:")
    return out


def build():
    lines = ["{ المرحلة 7: ضرب دقيق بخلية غير سالبة. }",
             '[~["STAGE7_MULTIPLY_SMALL_FAILURE"10,0 0/]?]e:',
             "z;b:512a;!b;0h;!!q: { أساس بناء الأعداد الكبيرة للاختبار. }"]
    cases = []
    for i, (big, small) in enumerate(CASES):
        lines.append(f"{{ حالة {i}: big={big}, small={small}. }}")
        lines.extend(literal(big, "u"))
        lines.append(f"z;b:u;a;!{small}a;!b;d:b;23h;!!v:")
        lines.extend(literal(big, "w"))
        lines.append("z;b:u;a;!w;a;!b;5h;!!0=e;! { قيمة BigInt الأصلية. }")
        lines.append(f"d;g;!u;=e;!d;1+g;!{small}=e;! {{ سجل الوسيطة. }}")
        lines.extend(literal(big * small, "s"))
        lines.append("z;b:v;a;!s;a;!b;5h;!!0=e;! { المخرج الدقيق. }")
        label = f"STAGE7_MULTIPLY_SMALL_CASE_{i:02d}_OK"
        lines.append(f'"{label}"10,')
        cases.append({"index": i, "big": str(big), "small": small,
                      "expected": str(big * small), "label": label})
    lines.extend(('"STAGE7_MULTIPLY_SMALL_13_RESULTS_26_INPUTS_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def invalid(small):
    assert small in (-1, -MAX_SMALL)
    return "\n".join(("{ المرحلة 7: رفض الخلية السالبة. }",
                      "z;b:1a;!b;0h;!!u:",
                      f"z;b:u;a;!{cell(small)}a;!b;23h;!!v:",
                      '"STAGE7_NEGATIVE_WRONGLY_ACCEPTED"10,',
                      "[z;0>][%z;1-z:]#")) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(CASES) == len(set(CASES)) == 13
    rng = random.Random(20261118 ^ 7)
    for _ in range(384):
        big = rng.randrange(-(1 << 320), 1 << 320)
        small = rng.randrange(0, MAX_SMALL + 1)
        result = big * small
        assert result == small * big
        assert result + big == big * (small + 1)
        assert result >= 0 if big >= 0 else result <= 0
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 7,
                      "native_evidence": False, "case_count": 13,
                      "result_assertions": 13, "input_assertions": 26,
                      "seeded_property_pairs": 384, "negative_small": [-1, -MAX_SMALL],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
