#!/usr/bin/env python3
"""Independent Stage 16 fixture generator from positional Python list slicing.

This oracle does NOT parse/call normative_reference.false or calculate via op33.
Missing-field tests use negative sentinels in two allocated tuple cells.
Physically truncated tuples are OUT OF SCOPE for this untagged memory layout.
"""
import json
from pathlib import Path

FINAL = "STAGE16_REMOVE_12_PLUS_TWO_REPLAYS_OK"
DESIGN = Path("evidence/stage16_sequence_remove_design_oracle_2026-11-19.json")

def cases():
    doc = json.loads(DESIGN.read_text(encoding="utf-8"))
    assert doc["project_id"] == "PC-BRANCH-FALSE-ARABIC" and doc["native_anchor_cases"] == 12
    items = doc["anchors"]
    for item in items:
        seq, pos = item["sequence"], item["position"]
        assert 1 <= len(seq) <= 6 and 1 <= pos <= len(seq)
        assert item["chosen"] == seq[pos-1]
        assert item["remaining"] == seq[:pos-1] + seq[pos:]
    return items + [items[0], items[-1]]

def check(name, expected, expression):
    return f'{expression}{expected}=~["{name}_FAIL"0 0/]?'

def build(mutant=False):
    lines = ["{ Stage 16: 12 anchors plus two deterministic replays; immutable input and output shape. }"]
    oracle_cases = []
    for ix, item in enumerate(cases()):
        key = f"STAGE16_REMOVE_{ix:02d}"
        seq, pos = item["sequence"], item["position"]
        n = len(seq)
        result = item["chosen"] + (1 if ix == 0 and mutant else 0)
        lines.append("z;s:" + str(n) + "a;!" + "".join(f"{v}a;!" for v in seq))
        lines.append(f"z;b:s;a;!{pos}a;!b;33h;!!o:")
        lines.append(check(key+"_RESULT", result, "o;g;!"))
        lines.append("o;1+g;!t:")
        lines.append(check(key+"_LENGTH", n-1, "t;g;!"))
        for j, v in enumerate(item["remaining"], 1):
            lines.append(check(key+f"_REMAIN_{j}", v, f"t;{j}+g;!"))
        lines.append(check(key+"_INPUT_LENGTH", n, "s;g;!"))
        for j, v in enumerate(seq, 1):
            lines.append(check(key+f"_INPUT_{j}", v, f"s;{j}+g;!"))
        lines.append(check(key+"_SOURCE_HANDLE", 0, "b;g;!s;-"))
        lines.append(check(key+"_POSITION_IDENTITY", pos, "b;1+g;!"))
        lines.append(f'"{key}_OK"10,')
        oracle_cases.append(dict(label=key+"_OK", position=pos, sequence=seq, chosen=item["chosen"],
                                 remaining=item["remaining"], replay=(ix>=12)))
    lines += [f'"{FINAL}"10,', '[z;0>][%z;1-z:]#']
    return "\n".join(lines)+"\n", oracle_cases

def invalid(kind):
    if kind == "zero_length":
        return 'z;s:0a;!z;b:s;a;!1a;!b;33h;!!\n'
    if kind == "seven_length":
        return 'z;s:7a;!1a;!2a;!3a;!4a;!5a;!6a;!1a;!z;b:s;a;!1a;!b;33h;!!\n'
    if kind == "zero_position":
        return 'z;s:2a;!1a;!2a;!z;b:s;a;!0a;!b;33h;!!\n'
    if kind == "high_position":
        return 'z;s:2a;!1a;!2a;!z;b:s;a;!3a;!b;33h;!!\n'
    if kind == "missing_sequence_sentinel":
        return 'z;b:1_a;!1a;!b;33h;!!\n'
    if kind == "missing_position_sentinel":
        return 'z;s:2a;!1a;!2a;!z;b:s;a;!1_a;!b;33h;!!\n'
    if kind == "missing_sequence_negative2":
        return 'z;b:2_a;!1a;!b;33h;!!\n'
    if kind == "missing_position_negative2":
        return 'z;s:2a;!1a;!2a;!z;b:s;a;!2_a;!b;33h;!!\n'
    if kind == "missing_sequence_negative7":
        return 'z;b:7_a;!1a;!b;33h;!!\n'
    if kind == "missing_position_negative7":
        return 'z;s:2a;!1a;!2a;!z;b:s;a;!7_a;!b;33h;!!\n'
    raise ValueError(kind)

NEGATIVE_MARKERS = {
    "zero_length": "E_REMOVE_LENGTH",
    "seven_length": "E_REMOVE_LENGTH",
    "zero_position": "E_REMOVE_POSITION",
    "high_position": "E_REMOVE_POSITION",
    "missing_sequence_sentinel": "E_REMOVE_MISSING_SEQUENCE",
    "missing_position_sentinel": "E_REMOVE_MISSING_POSITION",
    "missing_sequence_negative2": "E_REMOVE_MISSING_SEQUENCE",
    "missing_position_negative2": "E_REMOVE_MISSING_POSITION",
    "missing_sequence_negative7": "E_REMOVE_MISSING_SEQUENCE",
    "missing_position_negative7": "E_REMOVE_MISSING_POSITION",
}

if __name__ == "__main__":
    print(build()[0], end="")
