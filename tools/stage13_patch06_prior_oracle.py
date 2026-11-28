#!/usr/bin/env python3
"""Independent integer replay of PATCH06 raw observations."""
import re
import sys
from pathlib import Path

M = 2**127 - 1
F = -15055671
W = 2**180
PAIRS = [(F,F),(F-1,F),(F,F-1),(F+1,F),(F,F+1),(0,1),(1,0),
         (-W,W),(W,-W),(W,W+1),(W+1,W),(-W,-W),(W,W)]
BACKS = (1, 3, 7)

def require(condition, message):
    if not condition:
        raise ValueError(message)

def save(n):
    return 1 + (n - 1) % M

def tag(n):
    d = n - F
    return 2*d + 1 if d >= 0 else -2*d

def hidden(c, t):
    row = [17, 29, 43, 71, 101]
    a, b = tag(c), tag(t)
    d, z = abs(t-c)+1, 1 if t<c else (2 if t==c else 3)
    out = {}
    for k in range(1, 8):
        h = save(a + (2*k+1)*b + (3*k+1)*d
                 + (4*k+2)*(a+b) + (4*k+4)*z + sum(row))
        for j in range(7):
            h = save(h*h + 3*h + row[j%5] + j+1)
        out[k] = h
        row = [save(row[j]**2 + (3,5,7,11,13)[j]*row[(j+1)%5]
                    + (k+1 if j==0 else row[j-1])) for j in range(5)]
    return out

def replay(raw):
    inputs, prefixes, rows, totals = {}, {}, {}, {}
    patterns = [
        (r"STAGE13_INPUT pair=(\d+) c=(-?\d+) t=(-?\d+)", inputs, 1),
        (r"STAGE13_PREFIX pair=(\d+) i=(\d+) values=([\d,]*)", prefixes, 2),
        (r"STAGE13_RAW pair=(\d+) i=(\d+) back=(\d+) slot=(-?\d+) actual=(MISSING|\d+) expected=(\d+)", rows, 3),
        (r"STAGE13_RAW_TOTAL pair=(\d+) RED=(\d+) CONTROL=(\d+)", totals, 1),
    ]
    for line in raw.splitlines():
        for pattern, store, n in patterns:
            match = re.search(pattern, line)
            if match:
                key = tuple(map(int, match.groups()[:n]))
                require(key not in store, f"duplicate {key}")
                store[key] = match.groups()[n:]
    require(set(inputs)=={(p,) for p in range(13)}, "input coverage")
    require(set(prefixes)=={(p,i) for p in range(13) for i in range(1,47)}, "prefix coverage")
    require(set(rows)=={(p,i,b) for p in range(13) for i in range(1,47) for b in BACKS}, "row coverage")
    require(set(totals)==set(inputs), "total coverage")
    red = control = 0
    for p, (c,t) in enumerate(PAIRS):
        require(tuple(map(int,inputs[p,]))==(c,t), f"input {p}")
        h = hidden(c,t)
        r = g = 0
        for i in range(1,47):
            prefix = [int(x) for x in prefixes[p,i][0].split(",") if x]
            expected_prefix = [M if j%3==0 else 1 if j%3==1 else (p+1)*100+j for j in range(1,i)]
            require(prefix==expected_prefix, f"prefix {p,i}")
            for b in BACKS:
                slot, actual, expected = rows[p,i,b]
                s = i-b
                require(int(slot)==s, f"slot {p,i,b}")
                if s<=0:
                    require(actual==str(h[1-s]) and int(expected)==h[1-s], f"hidden {p,i,b}")
                    r += 1
                else:
                    require(actual==str(prefix[s-1]) and int(expected)==prefix[s-1], f"control {p,i,b}")
                    g += 1
        require((r,g)==(11,127) and tuple(map(int,totals[p,]))==(r,g), f"totals {p}")
        red += r
        control += g
    print(f"STAGE13_PATCH06_ORACLE=PASS INPUTS=13 ROWS={red+control} RED={red} CONTROL={control} PREFIXES=598")

if __name__ == "__main__":
    if len(sys.argv)!=2:
        raise SystemExit("usage: stage13_patch06_prior_oracle.py RAW_STDOUT")
    replay(Path(sys.argv[1]).read_text(encoding="utf-8"))
