#!/usr/bin/env python3
"""Independent integer oracle and deterministic FALSE fixture for Stage 14."""

import stage14_visible_drops_design_oracle as model

FINAL = "STAGE14_VISIBLE_46_COMPLETE"
NEGATIVE = (("short_counts", 4, 46, 7, "E_VISIBLE_COUNTS"),
            ("short_stones", 5, 45, 7, "E_VISIBLE_STONES"),
            ("short_hidden", 5, 46, 6, "E_VISIBLE_HIDDEN"))


def bigint(value, name="s"):
    assert 0 < value <= model.MODULUS
    digits = []
    while value:
        digits.append(value % 512)
        value //= 512
    return (f"z;{name}:1a;!{len(digits)}a;!" +
            "".join(f"{digit}a;!" for digit in digits))


def build(mutant=False):
    record = model.counts(model.REFERENCE_DAY, model.REFERENCE_DAY)
    rows = model.stone_rows()
    hidden = model.hidden_drops(record, rows)
    expected = model.visible_drops(record, rows, hidden)
    lines = ["{ المرحلة 14: نفس اليوم؛ 46 نتيجة، العدد والموضع. }",
             "z;b:0a;!b;24h;!!c:",
             f"z;b:{model.REFERENCE_DAY}a;!b;0h;!!u:",
             "z;b:u;a;!u;a;!b;f;!q:",
             "z;b:q;a;!c;a;!b;29h;!!d:",
             "z;b:q;a;!c;a;!d;a;!b;31h;!!v:",
             'v;g;!46=~["STAGE14_LENGTH_FAILURE"0 0/]?']
    for position, actual in enumerate(expected, 1):
        tested = actual + (1 if mutant and position == 1 else 0)
        lines.extend((bigint(tested),
                      f"v;{position}+g;!d:",
                      f'z;b:d;a;!s;a;!b;5h;!!0=~["STAGE14_VALUE_{position:02d}_FAILURE"0 0/]?',
                      f'"STAGE14_VISIBLE_{position:02d}_OK"10,'))
    lines.extend((f'"{FINAL}"10,', '[z;0>][%z;1-z:]#'))
    cases = [{"position": i, "expected_decimal": str(value),
              "label": f"STAGE14_VISIBLE_{i:02d}_OK"}
             for i, value in enumerate(expected, 1)]
    return "\n".join(lines) + "\n", cases


def invalid(counts, stones, hidden):
    assert (counts, stones, hidden) in [(x[1], x[2], x[3]) for x in NEGATIVE]
    return (f"z;y:{counts}a;!z;w:{stones}a;!z;v:{hidden}a;!\n"
            'z;b:y;a;!w;a;!v;a;!b;31h;!!\n'
            '"STAGE14_INVALID_UNEXPECTED_SUCCESS"10,\n')


if __name__ == "__main__":
    print(build()[0], end="")
