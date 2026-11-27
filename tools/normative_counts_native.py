#!/usr/bin/env python3
"""Normative operations 37/38: independent integer and raw-cell Native regression.
No historical fixture is changed; no integration or stage acceptance is claimed.
"""
import hashlib
import json
import os
from pathlib import Path
import random
import resource
import subprocess

EPOCH = -15055671
M = (1 << 127) - 1
ROOT = Path("evidence/normative_counts")
BASE = Path("src/bigint.false").read_bytes() + b"\n" + Path("src/monster_bootstrap.false").read_bytes() + b"\n"
OLD_EPOCH = b"z;b:15055671a;!b;0h;!!s:"
NEW_EPOCH = b"z;b:15055671_a;!b;0h;!!s:"
OLD_DIR = b"1t:r;0>[2t:]?r;0<[3t:]?"
NEW_DIR = b"2t:r;0>[3t:]?r;0<[1t:]?"
REFERENCE_BLOB = "3e9acc012bedf83294a6ec3cccb081a069556b5b"

def day(d):
    offset = d - EPOCH
    return 2 * offset + 1 if offset >= 0 else -2 * offset

def counts(c, t):
    a, b = day(c), day(t)
    return (a, b, abs(t-c)+1, a+b, 2+(t>c)-(t<c))

def raw(n):
    sign = (n > 0) - (n < 0)
    n = abs(n)
    digits = []
    while n:
        n, digit = divmod(n, 512)
        digits.append(digit)
    return [sign, len(digits) or 1, *(digits or [0])]

def cell(n):
    return str(abs(n)) + ("_" if n < 0 else "")

def fixture(c, t):
    lines = ['[~["NORM_COUNTS_MISMATCH"10,0 0/]?]e:']
    def allocate(name, n):
        lines.append("z;" + name + ":")
        lines.extend(cell(x)+"a;!" for x in raw(n))
    def check(name, n):
        for i, x in enumerate(raw(n)):
            lines.append(f"{name};{i}+g;!{cell(x)}=e;!")
    allocate("d", c)
    allocate("v", t)
    lines.append("z;b:d;a;!v;a;!b;f;!l:")
    lines.append("l;g;!5=e;!")
    for index, expected in enumerate(counts(c,t)[:4], 1):
        lines.append(f"l;{index}+g;!y:")
        check("y", expected)
    lines.append(f"l;5+g;!{counts(c,t)[4]}=e;!")
    check("d", c)
    check("v", t)
    lines.extend(['"NORM_COUNTS_OK"10,', '[z;0>][%z;1-z:]#'])
    return ("\n".join(lines)+"\n").encode()

def digest(data):
    return hashlib.sha256(data).hexdigest()

def limit():
    cap = 2 * 1024**3
    resource.setrlimit(resource.RLIMIT_AS, (cap, cap))
    resource.setrlimit(resource.RLIMIT_CPU, (25, 25))

def execute(name, base, c, t, negative=False):
    data = base + fixture(c,t)
    p = ROOT / (name+".false")
    p.write_bytes(data)
    with (ROOT/(name+".stdout")).open("wb") as out, (ROOT/(name+".stderr")).open("wb") as err:
        try:
            result = subprocess.run(["upstream/false_int","-e",str(p)], stdout=out, stderr=err,
                                    timeout=30, preexec_fn=limit)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 124
    (ROOT/(name+".exit")).write_text(str(code)+"\n")
    stdout = (ROOT/(name+".stdout")).read_bytes()
    stderr = (ROOT/(name+".stderr")).read_bytes()
    if negative:
        ok = code == 1 and stdout == b"NORM_COUNTS_MISMATCH\n" and b"division by zero" in stderr.lower()
    else:
        ok = code == 0 and stdout == b"NORM_COUNTS_OK\n" and not stderr
    return dict(name=name,c=str(c),t=str(t),expected=list(map(str,counts(c,t))),negative=negative,
                code=code,pass_gate=ok,program_sha256=digest(data),
                stdout_sha256=digest(stdout),stderr_sha256=digest(stderr))

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    pin=os.environ["SOURCE_PIN"]
    assert subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()==pin
    assert subprocess.check_output(["git","rev-parse",pin+":test/normative_reference.false"],text=True).strip()==REFERENCE_BLOB
    for path in ("src/bigint.false","src/monster_bootstrap.false","test/normative_reference.false",
                 "tools/normative_counts_native.py",".github/workflows/false-arabic-normative-counts.yml"):
        data=Path(path).read_bytes()
        assert data==subprocess.check_output(["git","show",pin+":"+path])
        dest=ROOT/"source"/path
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(data)
    assert BASE.count(NEW_EPOCH)==BASE.count(NEW_DIR)==1
    assert OLD_EPOCH not in BASE and OLD_DIR not in BASE
    assert counts(EPOCH,EPOCH)==(1,1,1,2,2)
    assert counts(EPOCH-1,EPOCH)==(2,1,2,3,3)
    assert counts(EPOCH,EPOCH-1)==(1,2,2,3,1)
    assert counts(EPOCH,EPOCH+1)==(1,3,2,4,3)
    rng=random.Random(20261127)
    for _ in range(384):
        a,b=(rng.randrange(-(1<<192),1<<192) for _ in range(2))
        x,y=counts(a,b),counts(b,a)
        assert x[:2]==y[:2][::-1] and x[2:4]==y[2:4] and x[4]+y[4]==4
    pairs=[(EPOCH,EPOCH),(EPOCH-1,EPOCH),(EPOCH,EPOCH-1),(EPOCH,EPOCH+1),
           (EPOCH+1,EPOCH),(EPOCH-2,EPOCH+2),(EPOCH+2,EPOCH-2),(0,-1),(-1,0),
           (15055671,15055671),(EPOCH-M,EPOCH+M),(EPOCH+M,EPOCH-M),
           (EPOCH+M,EPOCH+M),(-(1<<192),1<<192)]
    rows=[execute("case_%02d"%i,BASE,c,t) for i,(c,t) in enumerate(pairs)]
    rows.append(execute("old_epoch",BASE.replace(NEW_EPOCH,OLD_EPOCH),EPOCH,EPOCH,True))
    rows.append(execute("old_direction",BASE.replace(NEW_DIR,OLD_DIR),EPOCH,EPOCH,True))
    receipt=dict(project_id="PC-BRANCH-FALSE-ARABIC",source_pin=pin,reference_blob=REFERENCE_BLOB,
                 runtime_pin=os.environ["RUNTIME_PIN"],oracle_properties=384,cases=rows,
                 native_gate_pass=all(r["pass_gate"] for r in rows),stage_acceptance=False)
    (ROOT/"receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
    print(json.dumps(receipt))
    if not receipt["native_gate_pass"]:
        raise SystemExit(1)

if __name__=="__main__":
    main()
