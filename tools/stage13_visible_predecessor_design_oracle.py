#!/usr/bin/env python3
"""Independent address oracle for the visible-predecessor selector."""

import json

SELECTED_I = (1, 2, 3, 7, 8, 46)
SELECTED_BACK = (1, 3, 7)


def pick(index, back):
    assert 1 <= index <= 46 and 1 <= back <= 7
    visible = tuple(10000 + n for n in range(1, index))
    hidden = tuple(20000 + n for n in range(1, 8))
    position = index - back
    if position > 0:
        return visible[position - 1], "visible", position
    return hidden[-position], "hidden", 1-position


def main():
    full = [pick(i, back) for i in range(1,47) for back in range(1,8)]
    assert len(full) == 322
    anchors = [{"i": i, "back": back, "expected": pick(i,back)[0],
                "source": pick(i,back)[1], "source_index": pick(i,back)[2]}
               for i in SELECTED_I for back in SELECTED_BACK]
    assert len(anchors) == 18
    assert any(a["source"] == "hidden" for a in anchors)
    assert any(a["source"] == "visible" for a in anchors)
    assert any(a["i"]-a["back"] == 0 for a in anchors)
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC",
                      "stage": 13, "status": "DESIGN_ONLY", "native_evidence": False,
                      "python_domain_pairs": len(full), "native_anchor_count": len(anchors),
                      "anchors": anchors}, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
