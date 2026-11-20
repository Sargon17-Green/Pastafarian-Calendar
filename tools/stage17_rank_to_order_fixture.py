#!/usr/bin/env python3
"""Stage17 source-independent fixture builder. Does not claim Native execution."""
import hashlib
from pathlib import Path
import stage17_rank_to_order_design_oracle as design
RANKS = tuple(design.ANCHOR_RANKS) + (1, 360)
FINAL = "STAGE17_ORDER_14_ANCHORS_2_REPLAYS_OK"
INVALID = (-1, 0, 721, 722)

def build(mutant=False):
    output = ["{ Stage17: 14 anchors and 2 deterministic replays, 10 checks per case. }"]
    cases = []
    for i, rank in enumerate(RANKS):
        name = f"STAGE17_ORDER_{i:02d}"
        order = list(design.unrank_factoradic(rank))
        cases.append({"label": name + "_OK", "rank": rank, "order": order,
                      "replay": i >= 14})
        checked = order.copy()
        if mutant and i == 0:
            checked[0] = 6
        output += [f"z;b:{rank}a;!b;s:b;34h;!!o:",
                   f'o;g;!6=~["{name}_LENGTH_FAIL"0 0/]?']
        for j, expected in enumerate(checked, 1):
            output.append(f'o;{j}+g;!{expected}=~["{name}_VALUE_{j}_FAIL"0 0/]?')
        output += [f'b;g;!{rank}=~["{name}_INPUT_RANK_FAIL"0 0/]?',
                   f'b;s;-0=~["{name}_INPUT_HANDLE_FAIL"0 0/]?',
                   f'o;b;-0=["{name}_OUTPUT_ALIAS_FAIL"0 0/]?',
                   f'"{name}_OK"10,']
    output += [f'"{FINAL}"10,', '[z;0>][%z;1-z:]#', '']
    return "\n".join(output), cases

def invalid(rank):
    assert rank in INVALID
    return (f'z;b:{rank}a;!b;34h;!!"STAGE17_INVALID_UNEXPECTED_SUCCESS"10,\n'
            '[z;0>][%z;1-z:]#\n')

def main():
    data,cases=build()
    assert len(cases)==16 and sum(x["replay"] for x in cases)==2
    assert data.count('=~["STAGE17_ORDER_')==160
    path=Path("test/stage17_rank_to_order_16.false")
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(data.encode("utf-8"))
    assert build(mutant=True)[0] != data
    print("STAGE17_FIXTURE_STATIC_CASES",len(cases))
    print("STAGE17_FIXTURE_STATIC_CHECKS",160)
    print("STAGE17_FIXTURE_SHA256",hashlib.sha256(data.encode()).hexdigest())
if __name__=="__main__":
    main()
