#!/usr/bin/env python3
"""Stage21 bounded Native gate; green is NOT independent stage acceptance."""
import itertools
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import stage21_native_diagnostic as d

E = Path("evidence/stage21_acceptance")
MARKER = d.MARKER
HIST = "evidence/stage21_measurement_offline_audit_2026-11-25.json"
SELF = "tools/stage21_native_acceptance.py"
WORKFLOW = ".github/workflows/false-arabic-stage21-acceptance.yml"
CALLER = ".github/workflows/canonical-names-lock.yml"
LOCKED = (*d.FILES, HIST, SELF, WORKFLOW, CALLER)
ANCHOR = b'1i:\n [i;47<][\n  w;i;+g;!t:'
OP = b'z;38=~["E_BOWL_UPDATE_LAYOUT"'
INVALIDS = {
    "bowls5":"BOWLS_LENGTH","bowls7":"BOWLS_LENGTH",
    "visible45":"VISIBLE_LENGTH","visible47":"VISIBLE_LENGTH",
    "stones45":"STONES_LENGTH","stones47":"STONES_LENGTH",
    "row4":"ROW_LENGTH","row6":"ROW_LENGTH",
    "zero_sign":"BIG_SIGN","negative_sign":"BIG_SIGN",
    "digit512":"BIG_DIGIT","digit_negative":"BIG_DIGIT",
    "top_zero":"BIG_TOP","overflow":"BIG_RANGE",
    "length0":"BIG_LENGTH","length16":"BIG_LENGTH",
}
# Each mutation changes only the op38 suffix, never the production checkout.
MUTANTS = {
    "old_neighbors": (
        (b'o;j;+g;!j:y;j;+g;!s:',b'y;j;+g;!s:'),
        (b'o;j;+g;!j:y;j;+g;!l:',b'y;j;+g;!l:')),
    "swap_neighbors": (
        (b'z;b:s;a;!2a;!b;23h;!!e:',b'z;b:s;a;!3a;!b;23h;!!e:'),
        (b'z;b:l;a;!3a;!b;23h;!!e:',b'z;b:l;a;!2a;!b;23h;!!e:')),
    "cross_weight": ((b'z;b:e;a;!5a;!b;23h;!!e:',b'z;b:e;a;!4a;!b;23h;!!e:'),),
    "aux_offset": ((b'i;p;2*1+*a;',b'i;p;2*2+*a;'),),
    "aux_stone": ((b'z;b:m;a;!e;a;!b;14h;!!e:',b'z;b:m;a;!m;a;!b;14h;!!e:'),),
}

def unique_replace(data, old, new):
    assert old != new and data.count(old) == 1, ("NONUNIQUE_MUTATION",old)
    return data.replace(old,new,1)

def instrument(src, steps):
    if steps == 46:
        return src
    assert 1 <= steps < 46
    return unique_replace(src,ANCHOR,ANCHOR.replace(b'47<',str(steps+1).encode()+b'<'))

def mutate(src, name):
    assert src.count(OP) == 1
    at = src.index(OP)
    suffix = src[at:]
    for old,new in MUTANTS[name]:
        suffix = unique_replace(suffix,old,new)
    return src[:at]+suffix

def mutated_first(name):
    # ID-indexed independent prediction of the first differing output.
    b,ds,ss = d.case("reverse")
    t = ds[0]
    s = ss[0]
    order = tuple(itertools.permutations(range(6)))[(t-1)%720]
    out = []
    for bid,x in enumerate(b):
        p = order.index(bid)
        lp,rp = (p-1)%6,(p+1)%6
        l,r = (b[lp],b[rp]) if name=="old_neighbors" else (b[order[lp]],b[order[rp]])
        aux = 2 if p>=3 else 1+(t*t+x*(x if name=="aux_stone" else s[p])+2*p+3+(name=="aux_offset")-1)%d.M
        weighted = 3*l+2*r if name=="swap_neighbors" else 2*l+3*r
        cross = 4 if name=="cross_weight" else 5
        out.append(1+(x*x+weighted+aux+t+s[(0,1,2,3,4,0)[p]]+cross*l*r+p+1-1)%d.M)
    return out

def expected_mutant_marker(name):
    original,_ = d.oracle(d.case("reverse"),1)
    changed = mutated_first(name)
    assert changed != original
    for j,(want,got) in enumerate(zip(original,changed),1):
        for k,(a,b) in enumerate(zip(d.limbs(want),d.limbs(got))):
            if a!=b:
                assert k>=2, ("NOT_NUMERIC_LIMB_WITNESS",name,j,k)
                return f"STAGE21_OUT_BOWL_{j}_CELL_{k}_FAIL"
    raise AssertionError(name)

def records():
    return [("full_reverse","reverse",46),("full_boundary","boundary",46),
            ("step02_reverse","reverse",2),("step23_boundary","boundary",23),
            ("step45_reverse","reverse",45),("replay_reverse","reverse",46)]

def self_check(src):
    for label,name,steps in records():
        body,expected,checks=d.fixture(d.case(name),steps)
        assert body.count(MARKER)==1 and checks>1000 and len(expected["bowls"])==6
        assert (instrument(src,steps)==src)==(steps==46)
    for name in INVALIDS:
        body,expected,checks=d.fixture(d.case("reverse"),46,invalid=name)
        assert "STAGE21_INVALID_ACCEPTED" in body and expected is None and checks==0
    for name in MUTANTS:
        assert mutate(src,name)!=src
        assert re.fullmatch(r"STAGE21_OUT_BOWL_[1-6]_CELL_\d+_FAIL",expected_mutant_marker(name))
    print("STAGE21_ACCEPTANCE_FIXTURE_SELF_CHECK_PASS")

def main():
    src=Path("src/monster_bootstrap.false").read_bytes()
    self_check(src)
    if "--self-check" in sys.argv:
        return
    E.mkdir(parents=True,exist_ok=True)
    d.E=E
    pin=os.environ["SOURCE_PIN"]
    runtime=os.environ["RUNTIME_PIN"]
    assert runtime=="eb3135565a8670cced3f6bbca4dbf7b014c45634"
    assert subprocess.check_output(["git","rev-parse","HEAD"]).decode().strip()==pin
    assert (E/"source_observed.txt").read_text().strip()==pin
    assert (E/"runtime_observed.txt").read_text().strip()==runtime
    assert (E/"compiler_exit_code.txt").read_text().strip()=="0"
    assert (E/"preflight.txt").read_text().strip()=="ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    blobs={}
    for path in LOCKED:
        actual=Path(path).read_bytes()
        assert actual==subprocess.check_output(["git","show",f"{pin}:{path}"]),path
        blobs[path]=actual
    hist=json.loads(blobs[HIST])
    assert hist["run_id"]==45511710172 and hist["artifact"]["id"]==14975561849
    assert hist["runtime_pin"]==runtime
    for path in ("src/bigint.false","src/monster_bootstrap.false"):
        assert subprocess.check_output(["git","rev-parse",f"{pin}:{path}"]).decode().strip()==hist["offline_audit"]["verified_git_blobs"][path]
    prefix=lambda source: blobs["src/bigint.false"]+b"\n"+source+b"\n"
    report={"stage":21,"project_id":"PC-BRANCH-FALSE-ARABIC","source_pin":pin,
            "runtime_pin":runtime,"run_id":os.getenv("GITHUB_RUN_ID"),
            "source_sha256":{p:d.sha(v) for p,v in blobs.items()},
            "production_prefix_sha256":d.sha(prefix(src)),
            "historical_full_ones":hist,"positive":{},"invalid":{},"mutants":{},
            "native_gate_passed":False,"independent_offline_audit":False,
            "stage21_accepted":False,"physical_pointer_safety_assessed":False}
    def persist():
        (E/"evidence.json").write_text(json.dumps(report,indent=2,sort_keys=True)+"\n")
    def run(group,label,q,steps,source,seconds,invalid=None,want=MARKER,exitcode=0,changes=None):
        body,expected,checks=d.fixture(q,steps,invalid=invalid)
        record={"input":{"bowls":list(map(str,q[0])),"visible":list(map(str,q[1])),
                         "stones":[list(map(str,row)) for row in q[2]]},
                "steps":steps,"instrumented":steps!=46,"expected":expected,
                "assertions":checks,"expected_marker":want,"expected_exit":exitcode,
                "invalid":invalid,"source_mutations":changes,
                "prefix_sha256":d.sha(prefix(source))}
        (E/(label+".fixture.json")).write_text(json.dumps(record,indent=2)+"\n")
        observation=d.execute(label,prefix(source)+body.encode(),seconds,want,exitcode)
        out=(E/(label+".stdout.txt")).read_bytes().replace(b"\r",b"").replace(b"\n",b"")
        err=(E/(label+".stderr.txt")).read_bytes()
        if exitcode:
            # Require the exact fixture/domain marker, not a parse error or timeout.
            observation["passed"]=(observation["exit_code"]==1 and
                out==want.encode() and MARKER.encode() not in out and
                b"STAGE21_INVALID_ACCEPTED" not in out)
        report[group][label]={"record":record,**observation}
        persist()
        return observation["passed"]
    persist()
    for label,name,steps in records():
        run("positive",label,d.case(name),steps,instrument(src,steps),600)
    for name,reason in INVALIDS.items():
        run("invalid","invalid_"+name,d.case("reverse"),46,src,30,
            invalid=name,want="E_BOWL_UPDATE_"+reason,exitcode=1)
    for name,pairs in MUTANTS.items():
        changes=[[old.decode(),new.decode()] for old,new in pairs]
        run("mutants","mutant_"+name,d.case("reverse"),1,
            instrument(mutate(src,name),1),180,
            want=expected_mutant_marker(name),exitcode=1,changes=changes)
    # Replay must be byte-identical to the original fixture and output.
    replay=all((E/("full_reverse"+ext)).read_bytes()==(E/("replay_reverse"+ext)).read_bytes()
               for ext in (".false",".stdout.txt",".stderr.txt",".exit_code.txt",".fixture.json"))
    report["replay_byte_identical"]=replay
    report["native_gate_passed"]=replay and all(
        x["passed"] for group in ("positive","invalid","mutants") for x in report[group].values())
    persist()
    print("STAGE21_BOUNDED_NATIVE_GATE_"+("PASS" if report["native_gate_passed"] else "FAIL"))
    if not report["native_gate_passed"]:
        sys.exit(1)

if __name__=="__main__":
    main()
