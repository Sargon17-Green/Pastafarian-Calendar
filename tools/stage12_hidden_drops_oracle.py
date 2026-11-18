#!/usr/bin/env python3
"""Generated FALSE fixture for independently derived hidden drop anchors."""

import argparse
import hashlib
import json
from pathlib import Path

from stage12_hidden_drops_design_oracle import PAIRS, drops, stones, work_counts

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage12_hidden_drops_21.false"


def literal(value, variable):
    assert value > 0 and variable in "uvwtsp"
    digits = []
    while value:
        digits.append(value % 512)
        value //= 512
    return f"z;{variable}:1a;!{len(digits)}a;!" + "".join(f"{digit}a;!" for digit in digits)


def build():
    rows = stones()
    lines = ["{ المرحلة 12: 3 حالات × 7 قطرات؛ مصدر الإنتاج لا يحمّل المرجع. }",
             '[~["STAGE12_HIDDEN_DROPS_FAILURE"10,0 0/]?]e:',
             "z;b:0a;!b;24h;!!c: { حجارة المرحلة 8 مرة واحدة. }"]
    cases = []
    for index, (calculation, target) in enumerate(PAIRS):
        counts = work_counts(calculation, target)
        result = drops(counts, rows)
        for value, var in zip(counts[:4], "uvwt"):
            lines.append(literal(value, var))
        lines.append(f"z;y:5a;!u;a;!v;a;!w;a;!t;a;!{counts[4]}a;!")
        lines.append("z;b:y;a;!c;a;!b;29h;!!q:")
        lines.append("q;g;!7=e;! { طول جدول القطرات. }")
        for offset, (var, value) in enumerate(zip("uvwt", counts[:4]), 1):
            lines.append(f"y;{offset}+g;!{var};=e;! {{ ثبات مقبض العدد {value}. }}")
        lines.append(f"y;5+g;!{counts[4]}=e;! {{ ثبات الاتجاه. }}")
        for kind, value in enumerate(result, 1):
            lines.append(f"q;{kind}+g;!r:")
            lines.append(literal(value, "s"))
            lines.append("z;b:r;a;!s;a;!b;5h;!!0=e;!")
            label = f"STAGE12_HIDDEN_CASE_{index:02d}_{kind}_OK"
            lines.append(f'"{label}"10,')
        for kind in (1, 7):
            lines.append(f"q;{kind}+g;!r:")
            lines.append(literal(result[kind - 1], "s"))
            lines.append("z;b:r;a;!s;a;!b;5h;!!0=e;! { قراءة חוזרת. }")
        cases.append({"index": index, "calculation": str(calculation),
                      "target": str(target), "counts": [str(x) for x in counts],
                      "drops": [str(x) for x in result]})
    lines.extend(('"STAGE12_HIDDEN_21_RESULTS_15_INPUTS_6_REPLAYS_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(cases) == 3 and all(len(c["drops"]) == 7 for c in cases)
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 12,
                      "native_evidence": False, "anchor_pairs": 3,
                      "result_assertions": 21, "input_assertions": 15,
                      "shape_assertions": 3, "replay_assertions": 6,
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
