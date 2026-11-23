#!/usr/bin/env python3
"""Independent Python-int oracle for SM83 Native392 bowl-answer A0 and direction."""
from __future__ import annotations
import json
from pathlib import Path
from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce
from test_sm83_stage1_bowls_abi import pairs72
from test_sm83_stage1_selection_oracle import bowl_answer_flow
ROOT = Path(__file__).resolve().parents[1]

def independent(bowls, order, bowl, z):
    assert tuple(sorted(order)) == (1,2,3,4,5,6)
    successor = dict(zip(order,order[1:]+order[:1]))[bowl]
    x=(pow(bowls[bowl-1]+z+181,2,M)+179*bowls[successor-1]+z-1)%M+1
    d=(pow(x+z+194,2,M)+193*x+197*bowls[5]-1)%M+1
    return x, (1 if d%2 else -1)

def main():
    src=(ROOT/"src/runtime/calendar_bowl_answer.asm").read_text()
    boot=(ROOT/"src/boot.asm").read_text()
    make=(ROOT/"Makefile").read_text()
    wf=(ROOT/".github/workflows/canonical-names-lock.yml").read_text()
    for phrase in ("CalendarBowlAnswerA0Direction::","wCalendarBowlOrderAt46",
                   "wCalendarAnswerA0Scratch","wCalendarAnswerDirectionScratch",
                   "call CalendarOrdinalValidate","call Mul128x128",
                   "call SaveWide256","call Save127","ld a, 179","ld a, 193","ld a, 197"):
        assert phrase in src,phrase
    assert 'INCLUDE "src/runtime/calendar_bowl_answer.asm"' in boot
    assert "STAGE1_ANSWER_FLOW_NATIVE_BENCH" in boot
    assert "build/calendar_bowl_answer.gb" in make
    assert "dmg-bowl-answer-native:" in wf
    fixture=json.loads((ROOT/"tests/fixtures/sm83_stage1_canonical_vectors.json").read_text())
    total=0
    wrong_successor=0
    canonical={}
    for c,t in pairs72(fixture):
        sauce=compute_sauce(c,t)
        for b in range(1,7):
            for z in (10,11,12):
                x,d=independent(sauce.bowls,sauce.order_at_46,b,z)
                flow=bowl_answer_flow(sauce,b,z)
                assert (x,d)==(flow.first,flow.step)
                wrong=(pow(sauce.bowls[b-1]+z+181,2,M)+179*sauce.bowls[b%6]+z-1)%M+1
                wrong_successor+=x!=wrong
                if c==FOUNDATION and t==FOUNDATION: canonical[b,z]=(x,d)
                total+=1
    assert total==72*6*3 and wrong_successor>0
    expected={(1,10):("0c6c8121da308925a2da405d4a491c38",1),
              (1,11):("abcdb55a7e61a599c7080559efcc571a",-1),
              (6,12):("d0e39c5ce6a31044c08e4ca5d880176c",-1),
              (4,12):("b11ae66b81ee806d27d965511b7a9239",1)}
    for key,(hexle,sign) in expected.items():
        assert canonical[key]==(int.from_bytes(bytes.fromhex(hexle),"little"),sign)
    print(f"HOST_STAGE1_BOWL_ANSWER=PASS pairs=72 queries={total} "
          f"numeric_successor_mutants_rejected={wrong_successor} "
          "foundation_four=PASS native392=CI_REQUIRED",flush=True)

if __name__=="__main__":
    main()
