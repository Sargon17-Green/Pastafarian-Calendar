#!/usr/bin/env python3
"""Emit a bounded FALSE selector fixture from independent address anchors."""

import argparse
import hashlib
import json
from pathlib import Path

from stage13_visible_predecessor_design_oracle import SELECTED_I, SELECTED_BACK, pick

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage13_visible_predecessor_18.false"
FINAL = "STAGE13_PREDECESSOR_18_HANDLES_18_VALUES_36_SHAPES_VERIFIED"


def big(value, var):
    assert 0 < value < (1 << 31)
    return f"z;b:{value}a;!b;0h;!!{var}:"


def table(var, length, selected, selected_handle="r"):
    return f"z;{var}:{length}a;!" + "".join(
        f"{selected_handle if index == selected else 's'};a;!"
        for index in range(1, length + 1))


def prefix():
    return ['[~["STAGE13_PREDECESSOR_FAILURE"10,0 0/]?]e:',
            big(9999, "s")]


def call(index, back):
    return f"z;b:p;a;!c;a;!{index}a;!{back}a;!b;30h;!!q:"


def build():
    lines = prefix()
    cases = []
    for index in SELECTED_I:
        for back in SELECTED_BACK:
            value, source, position = pick(index, back)
            lines.append(big(value, "r"))
            lines.append(table("c", 7, position if source == "hidden" else 0))
            lines.append(table("p", index-1, position if source == "visible" else 0))
            lines.append(call(index, back))
            lines.append("q;r;=e;! { هوية المقبض. }")
            lines.append("z;b:q;a;!r;a;!b;5h;!!0=e;! { القيمة. }")
            lines.append(f"c;g;!7=e;!p;g;!{index-1}=e;! {{ طول الجدولين. }}")
            label = f"STAGE13_PREDECESSOR_CASE_{index:02d}_{back}_OK"
            lines.append(f'"{label}"10,')
            cases.append({"i": index, "back": back, "expected": value,
                          "source": source, "source_index": position,
                          "label": label})
    lines.extend((f'"{FINAL}"10,', "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


NEGATIVE = (("index_0", 0, 1, 7, 0, "E_VISIBLE_INDEX"),
            ("index_47", 47, 1, 7, 46, "E_VISIBLE_INDEX"),
            ("back_0", 1, 0, 7, 0, "E_VISIBLE_BACK"),
            ("back_8", 1, 8, 7, 0, "E_VISIBLE_BACK"),
            ("prefix_short", 2, 1, 7, 0, "E_VISIBLE_PREFIX"),
            ("hidden_short", 1, 1, 6, 0, "E_HIDDEN_LENGTH"))


def invalid(index, back, hidden_length, prefix_length):
    return "\n".join(prefix() +
                     [table("c", hidden_length, 0),
                      table("p", prefix_length, 0), call(index, back),
                      '"INVALID_UNEXPECTED_SUCCESS"10,']) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(cases) == 18 and len(NEGATIVE) == 6
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 13,
                      "native_evidence": False, "handle_assertions": 18,
                      "value_assertions": 18, "shape_assertions": 36,
                      "negative_cases": [list(item) for item in NEGATIVE],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
