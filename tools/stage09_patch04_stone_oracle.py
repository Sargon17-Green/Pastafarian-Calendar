#!/usr/bin/env python3
"""Independent arbitrary-precision oracle for Stage09/PATCH04."""
from __future__ import annotations
import re
import sys
from pathlib import Path

M = (1 << 127) - 1
SEED = [17, 29, 43, 71, 101]
FIELDS = ("w", "b", "s", "m", "r")
CORRECTED_RE = re.compile(r"STAGE09_CORRECTED_CELL row=(\d+) field=([wbsmr]) value=(\d+) expected=(\d+) class=(GREEN)")
GARBAGE_RE = re.compile(r"STAGE09_GARBAGE_CELL row=(\d+) field=([wbsmr]) value=(\d+) expected=(\d+) class=(RED|MATCH)")
LEGACY_RE = re.compile(r"STAGE09_LEGACY_CELL row=(\d+) field=([wbsmr]) value=(\d+) expected=(\d+) class=(RED|MATCH)")

def save(x: int) -> int:
    return 1 + ((x - 1) % M)

def snapshot_next(old: list[int], i: int) -> list[int]:
    w,b,s,m,r = old
    return [save(w*w+3*b+i), save(b*b+5*s+w), save(s*s+7*m+b),
            save(m*m+11*r+s), save(r*r+13*w+m)]

def sequential_next(previous: list[int], i: int) -> list[int]:
    x = previous.copy()
    x[0] = save(x[0]*x[0]+3*x[1]+i)
    x[1] = save(x[1]*x[1]+5*x[2]+x[0])
    x[2] = save(x[2]*x[2]+7*x[3]+x[1])
    x[3] = save(x[3]*x[3]+11*x[4]+x[2])
    x[4] = save(x[4]*x[4]+13*x[0]+x[3])
    return x

def tables():
    corrected = [SEED.copy()]
    garbage = [SEED.copy()]
    legacy = [SEED.copy()]
    for i in range(2,47):
        garbage.append(sequential_next(corrected[-1],i))
        corrected.append(snapshot_next(corrected[-1],i))
        legacy.append(sequential_next(legacy[-1],i))
    return corrected,garbage,legacy

def self_test():
    c,g,l=tables()
    assert c[1]==[378,1073,2375,6195,10493]
    assert g[1]==[378,1434,3780,9932,25047]
    assert g[2]==[146106,1309310,6993300,45486748,157489175]
    gr=sum(g[r][k]!=c[r][k] for r in range(1,46) for k in range(5))
    gm=225-gr
    lr=sum(l[r][k]!=c[r][k] for r in range(1,46) for k in range(5))
    lm=225-lr
    assert (gr,gm,lr,lm)==(180,45,224,1)
    sample = "STAGE09_CORRECTED_CELL row=1 field=w value=17 expected=17 class=GREEN"
    match = CORRECTED_RE.fullmatch(sample)
    assert match is not None and match.groups() == ("1", "w", "17", "17", "GREEN")
    parsed = read_cells([sample], CORRECTED_RE, {(1, "w")}, "STAGE09_CORRECTED_CELL")
    assert parsed[(1, "w")] == (17, 17, "GREEN")
    print("STAGE09_PATCH04_ORACLE_SELF_TEST=PASS")

def read_cells(lines, regex, wanted_keys, label):
    parsed={}
    for line in lines:
        if label not in line: continue
        m=regex.fullmatch(line)
        if not m: raise SystemExit(f"malformed {label} line: {line}")
        row,field,value,expected,cls=m.groups()
        key=(int(row),field)
        if key in parsed: raise SystemExit(f"duplicate {label} cell: {key}")
        parsed[key]=(int(value),int(expected),cls)
    if set(parsed)!=wanted_keys:
        raise SystemExit(f"{label} coverage missing={len(wanted_keys-set(parsed))} extra={len(set(parsed)-wanted_keys)}")
    return parsed

def verify(path: Path):
    lines=path.read_text(encoding="utf-8",errors="strict").splitlines()
    corrected,garbage,legacy=tables()
    ckeys={(r,f) for r in range(1,47) for f in FIELDS}
    dkeys={(r,f) for r in range(2,47) for f in FIELDS}
    c=read_cells(lines,CORRECTED_RE,ckeys,"STAGE09_CORRECTED_CELL")
    g=read_cells(lines,GARBAGE_RE,dkeys,"STAGE09_GARBAGE_CELL")
    l=read_cells(lines,LEGACY_RE,dkeys,"STAGE09_LEGACY_CELL")
    for r in range(1,47):
        for k,f in enumerate(FIELDS):
            if c[(r,f)]!=(corrected[r-1][k],corrected[r-1][k],"GREEN"):
                raise SystemExit(f"corrected oracle mismatch row={r} field={f}")
    garbage_red=garbage_match=legacy_red=legacy_match=0
    for r in range(2,47):
        for k,f in enumerate(FIELDS):
            gclass="MATCH" if garbage[r-1][k]==corrected[r-1][k] else "RED"
            lclass="MATCH" if legacy[r-1][k]==corrected[r-1][k] else "RED"
            if g[(r,f)]!=(garbage[r-1][k],garbage[r-1][k],gclass):
                raise SystemExit(f"garbage oracle mismatch row={r} field={f}")
            if l[(r,f)]!=(legacy[r-1][k],corrected[r-1][k],lclass):
                raise SystemExit(f"legacy oracle mismatch row={r} field={f}")
            garbage_red += gclass=="RED"; garbage_match += gclass=="MATCH"
            legacy_red += lclass=="RED"; legacy_match += lclass=="MATCH"
    markers=(
      "STAGE09_CORRECTED_ROWS=46 CELLS=230",
      "STAGE09_CORRECTED_GREEN=230/230",
      "STAGE09_GARBAGE_CAPTURE=PASS ROWS=45 CELLS=225 RED=180 MATCH=45",
      "STAGE09_PRESERVED_DISCOVERY04_RED=224 MATCH=1 UNEXPECTED=0",
      "STAGE09_CALLS=45 GUARDS=5",
      "STAGE09_BOOTSTRAP_ONLY=PASS",
    )
    for marker in markers:
        if marker not in lines: raise SystemExit(f"missing Native marker {marker}")
    if (garbage_red,garbage_match,legacy_red,legacy_match)!=(180,45,224,1):
        raise SystemExit("Stage09 classification changed")
    print("STAGE09_PATCH04_ORACLE=PASS CORRECTED=230/230 GARBAGE=225 RED=180 MATCH=45 LEGACY=225 RED=224 MATCH=1")

if __name__=="__main__":
    if len(sys.argv)==2 and sys.argv[1]=="--self-test": self_test()
    elif len(sys.argv)==2: verify(Path(sys.argv[1]))
    else: raise SystemExit("usage: stage09_patch04_stone_oracle.py --self-test | <native-stdout-file>")
