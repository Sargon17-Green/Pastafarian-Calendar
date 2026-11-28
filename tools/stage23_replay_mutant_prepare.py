#!/usr/bin/env python3
"""Prepare bounded Stage23 replay/interleaving and actual mutant programs; not Native."""
import json
import os
from pathlib import Path
import subprocess
import stage23_measure as m
import stage23_differential as d

E = Path("evidence/stage23_replay_mutant_prepare")
BASE_BLOB = "f3e51dabc3c4afc95ad75ea79c572f5024f75a38"
BIG_BLOB = "1e8de1147ba46cd0eb75a47f24673bbd9783946f"
MARKER = 'z;40=~["E_OP57_LAYOUT"0 0/]?'
SWAP = "x;f;!y:"
RETURN = "z;r:2a;!n;a;!o;a;!"
FILES = ("src/bigint.false", "src/monster_bootstrap.false",
         "tools/stage23_measure.py", "tools/stage23_differential.py",
         "tools/preintegration_op57_design_oracle.mjs",
         "tools/stage23_replay_mutant_prepare.py")

def git(*args):
    return subprocess.check_output(["git", *args])

def write_json(path, obj):
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")

def mutated(src, anchor, replacement):
    assert src.count(MARKER) == 1
    before, tail = src.split(MARKER)
    assert tail.count(anchor) == 1
    changed = tail.replace(anchor, replacement, 1)
    assert changed != tail and changed.replace(replacement, anchor, 1) == tail
    return before + MARKER + changed

def first_bowl_marker(expected, wrong):
    good, bad = m.limbs(expected), m.limbs(wrong)
    i = next(i for i, (a, b) in enumerate(zip(good, bad)) if a != b)
    return dict(marker=f"S23_BOWL_1_CELL_{i}", expected=good[i], wrong=bad[i])

def interleave(body):
    # op34 accepts a one-cell rank tuple and preserves caller registers.
    # d/e/l are reserved across the existing op40 fixture; its scratch set
    # is x,y,w,b,o,v,u,t,r,s. m/n/p are reserved for the second cheap call.
    lines = body.splitlines()
    assert lines[0] == "z;x:" and lines[-1] == "[z;0>][%z;1-z:]#"
    assert lines[-2].startswith('z;r:"S23_HEAP_BITS_LSB="')
    checks = 0
    def eq(expr, expected, tag):
        nonlocal checks
        checks += 1
        return expr + str(expected) + '-0=~["S23_INTER_' + tag + '"0 0/]?'
    def table(reg, values, tag):
        return [eq(f"{reg};{i}+g;!", v, f"{tag}_{i}") for i,v in enumerate(values)]
    first = ["k;l:", "z;e:1a;!", "z;m:", "e;34h;!!d:",
             'd;m;<["S23_INTER_FIRST_FRESH"0 0/]?',
             'k;l;-0=~["S23_INTER_FIRST_FRAME"0 0/]?']
    first += table("d", [6,1,2,3,4,5,6], "FIRST_BEFORE")
    last = table("d", [6,1,2,3,4,5,6], "FIRST_AFTER_FULL")
    last += [eq("e;g;!", 1, "FIRST_ARG"),
             'k;l;-0=~["S23_INTER_FULL_FRAME"0 0/]?',
             "z;m:720a;!", "z;n:", "m;34h;!!p:",
             'p;n;<["S23_INTER_SECOND_FRESH"0 0/]?',
             'p;d;= ["S23_INTER_ALIAS"0 0/]?',
             'k;l;-0=~["S23_INTER_SECOND_FRAME"0 0/]?']
    last += table("p", [6,6,5,4,3,2,1], "SECOND")
    last += table("d", [6,1,2,3,4,5,6], "FIRST_AFTER_SECOND")
    last += [eq("m;g;!",720,"SECOND_ARG"), eq("e;g;!",1,"FIRST_ARG_FINAL")]
    return "\n".join(first + lines[:-2] + last + lines[-2:])+"\n", checks+6

def main():
    pin = git("rev-parse","HEAD").decode().strip()
    assert os.environ.get("SOURCE_PIN", pin) == pin
    assert git("rev-parse",pin+":src/monster_bootstrap.false").decode().strip() == BASE_BLOB
    assert git("rev-parse",pin+":src/bigint.false").decode().strip() == BIG_BLOB
    E.mkdir(parents=True, exist_ok=False)
    hashes={}
    for name in FILES:
        data=Path(name).read_bytes()
        assert data==git("show",pin+":"+name)
        p=E/"source"/name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
        hashes[name]=m.sha(data)
    st,rows=d.oracle()
    row=rows[1]
    assert row["pair"]==[-(1<<63),(1<<63)-1]
    body,checks=m.fixture(row)
    inter,extra=interleave(body)
    big=Path("src/bigint.false").read_bytes()
    src=Path("src/monster_bootstrap.false").read_bytes().decode("utf-8")
    assert row["finalBowls"][0]==108913163550045184146698385533806010700
    assert row["returnOrder"]==[6,1,2,3,4,5]
    swapped=d.solve(*reversed(row["pair"]),st)["finalBowls"][0]
    skipped=row["after46"][0]
    assert swapped==117012097572828239447606168473050643501
    assert skipped==43795601943322443886068352038643283602
    specs=[
        ("fresh_replay",src,body,None,checks),
        ("interleaving",src,inter,None,checks+extra),
        ("mutant_swap",mutated(src,SWAP,"z;b:x;1+g;!a;!x;g;!a;!b;f;!y:"),body,
         first_bowl_marker(row["finalBowls"][0],swapped),checks),
        ("mutant_skip_batches_result",mutated(src,RETURN,"z;r:2a;!p;a;!o;a;!"),body,
         first_bowl_marker(row["finalBowls"][0],skipped),checks),
        ("mutant_identity_order",mutated(src,RETURN,"z;b:1a;!b;34h;!!o:"+RETURN),body,
         dict(marker="S23_ORDER_1",expected=6,wrong=1),checks)]
    entries=[]
    for name,prefix,fixture,wrong,count in specs:
        path=E/(name+".false")
        data=big+b"\n"+prefix.encode("utf-8")+b"\n"+fixture.encode("utf-8")
        path.write_bytes(data)
        entries.append(dict(name=name,program_sha256=m.sha(data),
                            bootstrap_sha256=m.sha(prefix.encode("utf-8")),
                            expected_first_numeric_mismatch=wrong,assertions_prepared=count,
                            native_executed=False))
    # Fresh replay runs this exact program twice in isolated processes, not
    # two full calls in one retained heap. Interleaving is a distinct third process.
    write_json(E/"expected.json",row)
    write_json(E/"receipt.json",dict(project_id="PC-BRANCH-FALSE-ARABIC",
        source_pin=pin,runtime_pin=m.RT,source_sha256=hashes,
        timeout_seconds=600,address_space_limit_bytes=m.LIMIT,
        entries=entries,fresh_replay_processes=2,retained_heap_double_full_assessed=False,
        native_executed=False,stage_acceptance=False))
    print(json.dumps(entries,indent=2))

if __name__=="__main__":
    main()
