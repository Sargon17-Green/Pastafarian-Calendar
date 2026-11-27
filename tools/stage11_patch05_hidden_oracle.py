#!/usr/bin/env python3
"""Raw Stage11 arithmetic, mapping and complete coverage, independent of Rust."""
import re
import sys
from pathlib import Path

F = -15055671
M = (1 << 127) - 1
PAIRS = [(F, F), (F-10, F+11), (F+34, F-19), (F-90001, F-90001),
         (F+123456789, F-987654321), (F-1, F+1), (F+1, F-1),
         (F-1, F-1), (F+1, F+1)] + [
             pair for n in (129, 1031)
             for pair in ((-(1 << n), 1 << n), (1 << n, -(1 << n)))]

def save(n):
    return 1 + (n - 1) % M

def tag(day):
    d = day - F
    return 2 * abs(d) + (d >= 0)

def hidden(c, t):
    row = [17, 29, 43, 71, 101]
    a, b = tag(c), tag(t)
    d, s = abs(t-c)+1, a+b
    direction = 1 if t < c else 2 if t == c else 3
    out = [0]
    for k in range(1, 8):
        h = save(a+(2*k+1)*b+(3*k+1)*d+(4*k+2)*s+(4*k+4)*direction+sum(row))
        for j in range(1, 8):
            h = save(h*h+3*h+row[(j-1)%5]+j)
        out.append(h)
        x,y,z,w,v = row
        row = [save(x*x+3*y+k+1), save(y*y+5*z+x),
               save(z*z+7*w+y), save(w*w+11*v+z), save(v*v+13*x+w)]
    return out

PATTERNS = {
    "INPUT": r"STAGE11_INPUT case=(\d+) c=(-?\d+) t=(-?\d+)",
    "STORAGE": r"STAGE11_STORAGE case=(\d+) slot=(\d+) value=(-?\d+)",
    "CELL": r"STAGE11_CELL case=(\d+) k=(\d+) slot=(\d+) corrected=(-?\d+) legacy=(-?\d+)",
}

def require(condition, message):
    if not condition:
        raise ValueError(message)

def expected():
    inputs, slots, cells = {}, {}, {}
    for i, (c,t) in enumerate(PAIRS):
        inputs[i] = (c,t)
        h = hidden(c,t)
        for p in range(8):
            slots[i,p] = (h[0 if p == 0 else 8-p],)
        for k in range(1,8):
            cells[i,k] = (8-k,h[k],h[8-k])
    return inputs, slots, cells

def verify(raw):
    observed = ({}, {}, {})
    for line in raw.splitlines():
        for i, (name, pattern) in enumerate(PATTERNS.items()):
            if not line.startswith("STAGE11_"+name+" "):
                continue
            m = re.fullmatch(pattern, line)
            require(m is not None, "malformed "+name)
            n = tuple(map(int,m.groups()))
            key, value = (n[0], n[1:]) if i == 0 else (n[:2], n[2:])
            require(key not in observed[i], "duplicate "+name+" "+str(key))
            observed[i][key] = value
    for name, actual, wanted in zip(PATTERNS, observed, expected()):
        require(actual.keys() == wanted.keys(), "coverage "+name)
        for key, value in wanted.items():
            require(actual[key] == value, "mismatch "+name+" "+str(key))
    for marker in ("STAGE11_PATCH05_MATRIX=91 STORAGE=104",
                   "STAGE11_PATCH05_GUARDS=PASS", "STAGE11_STRICT_GREEN_K1=PASS"):
        require(raw.splitlines().count(marker) == 1, "missing/duplicate "+marker)
    print("STAGE11_PATCH05_ORACLE=PASS INPUTS=13 CELLS=91 STORAGE=104")

def self_test():
    h = hidden(F,F)
    require(h[1] == 119390830530032782664128530203002080344, "foundation green")
    require(h[7] == 6164285870955721082771365327359496898, "foundation red")
    require(h[1] != h[7], "distinct witness")
    require(len(set(PAIRS)) == 13, "distinct inputs")
    require(tuple(map(len, expected())) == (13,104,91), "coverage")
    print("STAGE11_ORACLE_SELF_TEST=PASS (arithmetic only)")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: stage11_patch05_hidden_oracle.py --self-test|RAW_LOG")
    if sys.argv[1] == "--self-test":
        self_test()
    else:
        verify(Path(sys.argv[1]).read_text(encoding="utf-8"))
