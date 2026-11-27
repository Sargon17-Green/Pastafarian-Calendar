#!/usr/bin/env python3
"""Native396 bench inputs and independent expected publications.

Host-only. Actual bounded map; no synthetic rank injection. Each case records
signed absolute calculation, 13-byte input, status and 18-byte publication.
A rejected case expects the prior publication, not a fabricated zero result.
"""
from __future__ import annotations
import json
import hashlib
from dataclasses import dataclass
from pathlib import Path
from struct import pack
from test_sm83_stage1_selection_oracle import (
    FOUNDATION, YEAR_MIN, YEAR_MAX, GAP_MIN, YearCandidate, ask, gate_gap,
)
from test_sm83_stage1_year_path_oracle import year5000

MAP_HASH = "d4bc06694ca0389bac5cc856593c527449f059c81971243c0b481b06f198f407"


def actual_map():
    g = {0: FOUNDATION}
    for n in range(1, 513):
        g[n] = g[n-1] + gate_gap(n, True)
        g[-n] = g[1-n] - gate_gap(n, False)
    raw = b"".join(pack("<i", g[i]-FOUNDATION) for i in range(-512, 513))
    assert hashlib.sha256(raw).hexdigest() == MAP_HASH
    assert all(GAP_MIN <= g[i+1]-g[i] <= 963 for i in range(-512, 512))
    return g


def input_bytes(y, direction):
    return pack("<iihhb", y.open_gate, y.close_gate,
                y.open_index, y.close_index, direction)


def oracle(g, c, y, direction):
    """Full-map enumeration + full sort, not the runtime two-pass scan."""
    if direction not in (-1, 1):
        raise ValueError("direction")
    i, j = y.open_index, y.close_index
    if (i not in g or j not in g or j-i < 6 or
        g[i] != y.open_gate or g[j] != y.close_gate or
        not YEAR_MIN <= y.close_gate-y.open_gate <= YEAR_MAX):
        raise ValueError("prior")
    if not g[-512]+YEAR_MAX <= c <= g[512]-YEAR_MAX:
        raise ValueError("calculation horizon")
    a = j if direction == 1 else i
    b = g[a]
    if not g[-512] <= b+direction*YEAR_MAX <= g[512]:
        raise ValueError("directional horizon")
    options = []
    for k in g:
        u,v = (a,k) if direction == 1 else (k,a)
        if v-u >= 6 and YEAR_MIN <= g[v]-g[u] <= YEAR_MAX:
            options.append(YearCandidate(u,v,g[u],g[v]))
    options.sort(key=lambda item: (item.length, item.open_gate))
    if not 1 <= len(options) <= 132:
        raise ValueError("candidate count")
    assert all(x.length < z.length for x,z in zip(options,options[1:]))
    rank = ask(c,b,1,11 if direction == 1 else 12,len(options)).rank
    assert 1 <= rank <= len(options)
    chosen = options[rank-1]
    result = pack("<iihhHHH", chosen.open_gate, chosen.close_gate,
                  chosen.open_index, chosen.close_index, chosen.length,
                  len(options),rank)
    assert len(result) == 18
    assert (chosen.open_gate if direction == 1 else chosen.close_gate) == b
    return chosen,result


@dataclass(frozen=True)
class Vector:
    name: str
    calculation: int
    prior13: bytes
    status: int
    result18: bytes | None
    chained: bool = False


def vectors():
    g = actual_map()
    out = []
    def add(name,c,y,d,*,valid=True,chained=False):
        inp = input_bytes(y,d)
        assert len(inp) == 13
        try:
            z,result = oracle(g,c,y,d)
        except ValueError:
            if valid:
                raise
            out.append(Vector(name,c,inp,2,None))
            return None
        if not valid:
            raise AssertionError("invalid case accepted: "+name)
        out.append(Vector(name,c,inp,0,result,chained))
        return z

    base,_,_ = year5000(FOUNDATION)
    data = json.loads((Path(__file__).parent /
                       "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8"))
    assert data["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    for item in data["vectors"]:
        if item["id"] not in (6,7,10):
            continue
        c,t = item["c"],item["t"]
        y,_,_ = year5000(c)
        step = 0
        while not y.open_gate < t <= y.close_gate:
            d = 1 if t > y.close_gate else -1
            y = add(f"canonical{item['id']}_step{step}",c,y,d,chained=step>0)
            step += 1
            assert step <= 128
        assert step > 0

    for c in (FOUNDATION-1234,FOUNDATION,FOUNDATION+1234):
        y,_,_ = year5000(c)
        for d in (-1,1):
            z = y
            for step in range(4):
                z = add(f"chain_{c}_{d}_{step}",c,z,d,chained=step>0)
            for t in (y.open_gate-1,y.open_gate,y.open_gate+1,
                      y.close_gate-1,y.close_gate,y.close_gate+1):
                # Primitive takes direction, not target. Only boundary-derived
                # calls which actually leave the half-open interval are needed.
                if (d == -1 and t <= y.open_gate) or (d == 1 and t > y.close_gate):
                    add(f"boundary_{c}_{d}_{t}",c,y,d)

    low,high = g[-512]+YEAR_MAX,g[512]-YEAR_MAX
    for d in (-1,1):
        for c in (low,high):
            add(f"calc_edge_{c}_{d}",c,base,d)
        for c in (low-1,high+1,-(1<<31),(1<<31)-1):
            add(f"calc_reject_{c}_{d}",c,base,d,valid=False)

        # Closest map anchor on each side of directional coverage. Find a
        # valid prior on its opposite side by full enumeration.
        allowed = [k for k in g if g[-512] <= g[k]+d*YEAR_MAX <= g[512]]
        edge = max(allowed) if d == 1 else min(allowed)
        for k,valid in ((edge,True),(edge+d,False)):
            priors = []
            for q in g:
                i,j = (q,k) if d == 1 else (k,q)
                if j-i >= 6 and YEAR_MIN <= g[j]-g[i] <= YEAR_MAX:
                    priors.append(YearCandidate(i,j,g[i],g[j]))
            assert priors
            prior = min(priors,key=lambda y:(y.length,y.open_gate))
            add(f"anchor_{d}_{k}",FOUNDATION,prior,d,valid=valid)

        for n,y in enumerate((
            YearCandidate(base.open_index,base.close_index,base.open_gate+1,base.close_gate),
            YearCandidate(base.open_index,base.close_index,base.open_gate,base.close_gate-1),
            YearCandidate(-513,base.close_index,g[-512],base.close_gate),
            YearCandidate(base.open_index,513,base.open_gate,g[512]),
            YearCandidate(0,5,g[0],g[5]),
            YearCandidate(1,-1,g[1],g[-1]),
            YearCandidate(-512,512,g[-512],g[512]),
        )):
            add(f"prior_reject_{d}_{n}",FOUNDATION,y,d,valid=False)
    for d in (0,2,-2,127,-128):
        add(f"direction_reject_{d}",FOUNDATION,base,d,valid=False)
    assert len({v.name for v in out}) == len(out)
    assert sum(v.name.startswith("chain_") for v in out) == 24
    assert sum(v.chained for v in out) >= 18
    return out


if __name__ == "__main__":
    rows = vectors()
    previous = None
    for v in rows:
        if v.status == 0:
            previous = v.result18
        assert previous is not None
        print(json.dumps(dict(name=v.name,c=v.calculation,prior13=v.prior13.hex(),
                              status=v.status,expected18=previous.hex(),
                              chained=v.chained),sort_keys=True))
    print(f"HOST_NATIVE396_VECTORS=PASS valid={sum(v.status==0 for v in rows)} "
          f"invalid={sum(v.status==2 for v in rows)} map_sha256={MAP_HASH} "
          "native=NOT_EXECUTED")
