#!/usr/bin/env python3
"""Independent interval checker: consumes Lua stdout, never executes Lua."""
import re
import sys
import hashlib
from pathlib import Path

def check(txt, radius, seed_path=None):
    if not 6 <= radius <= 96: raise ValueError("invalid radius")
    gates, windows, values, targets = {}, {}, {}, []
    for line in txt.splitlines():
        m = re.fullmatch(r"GATE_INDEX\|index=(-?\d+)\|day=(-?\d+)", line)
        if m:
            i, d = map(int, m.groups())
            if i in gates: raise ValueError("duplicate gate")
            gates[i] = d
            continue
        m = re.fullmatch(r"GATE_WINDOW\|i=(-?\d+)\|j=(-?\d+)\|first=(-?\d+)\|last=(-?\d+)\|length=(\d+)", line)
        if m:
            row = tuple(map(int, m.groups()))
            if row[0] in windows: raise ValueError("duplicate window")
            windows[row[0]] = row
            continue
        if line.startswith("GATE_TARGET|"):
            targets.append(line)
            continue
        if line.startswith("GATE_ADMITTED_WITNESS|"): continue
        if line.startswith(("GATE_", "MIN_SIX_", "SHORT_", "COMPOSITION_", "SCOPE=")):
            key, sep, val = line.partition(": ")
            if not sep: key, sep, val = line.partition("=")
            if not sep or key in values: raise ValueError("malformed/duplicate marker")
            values[key] = val
    if set(gates) != set(range(-radius, radius + 1)): raise ValueError("gate range")
    gaps = [gates[i] - gates[i-1] for i in range(-radius + 1, radius + 1)]
    if not all(42 <= g <= 963 for g in gaps): raise ValueError("gap bounds")
    if set(windows) != set(range(-radius, radius - 5)): raise ValueError("window range")
    lengths = []
    for i in range(-radius, radius - 5):
        d = sum(gates[k] - gates[k-1] for k in range(i+1, i+7))
        if windows[i] != (i, i+6, gates[i], gates[i+6], d): raise ValueError("window arithmetic")
        lengths.append(d)
    expected = {
        "GATE_WINDOW_SCAN": f"{-radius}/{radius}",
        "GATE_WINDOWS_TOTAL": str(len(windows)),
        "MIN_SIX_GAP_WINDOW": str(min(lengths)),
        "SHORT_SIX_GAP_WINDOWS": str(sum(252 <= x <= 1968 for x in lengths)),
        "GATE_TARGET_PROBES": f"{len(targets)}/8",
        "COMPOSITION_NOT_INVOKED": "YES",
        "SCOPE": "RADIUS64_GATE_WINDOW_STATIC_DISCOVERY_ONLY; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN"
    }
    for k, v in expected.items():
        if values.get(k) != v: raise ValueError("marker "+k)
    evals = int(values["GATE_GAP_EVALUATIONS"])
    if radius == 64:
        if seed_path is None: raise ValueError("v4 seed mandatory for radius64")
        raw = Path(seed_path).read_bytes()
        blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
        if blob != "31f3d0d0ec125279d5fba67eb79372a812cb4dd8": raise ValueError("v4 seed git blob lock")
        core = {}
        for line in raw.decode("utf-8").splitlines():
            if not line or line.startswith("#"): continue
            m = re.fullmatch(r"(-?\d+)\s+(-?\d+)", line)
            if not m: raise ValueError("v4 seed row")
            i, day = map(int, m.groups())
            if i in core: raise ValueError("duplicate v4 seed index")
            core[i] = day
        if set(core) != set(range(-40, 41)): raise ValueError("v4 seed range")
        if any(gates[i] != day for i, day in core.items()): raise ValueError("v4 seed mismatch")
        if (values.get("GATE_CORE_SEED") != "-40/40" or
                values.get("GATE_CORE_VERIFIED_RUN") != "44715871183" or
                values.get("GATE_CORE_SEED_BLOB") != blob):
            raise ValueError("v4 provenance markers")
        if not 48 <= evals <= 200: raise ValueError("new gap evaluation budget")
    else:
        if not len(gaps) <= evals <= 200: raise ValueError("gap evaluation budget")
    if len(targets) > 8: raise ValueError("target budget")
    if not targets and (values.get("SHORT_SELECTED_YEAR_INTERVALS") != "0"
                        or values.get("GATE_TARGET_ADMISSION_NONE") != "0/0"):
        raise ValueError("zero-probe admission")
    if targets and not (values.get("GATE_TARGET_ADMISSION_PASS") == "1/1" or
                        values.get("GATE_TARGET_ADMISSION_NONE") == f"0/{len(targets)}"):
        raise ValueError("admission marker")
    return len(gates), len(gaps), len(windows), min(lengths)

def selftest():
    r = 6
    g = {i: (i+6)*100 for i in range(-6,7)}
    lines = [f"GATE_INDEX|index={i}|day={g[i]}" for i in range(-6,7)]
    lines += [f"GATE_WINDOW|i={i}|j={i+6}|first={g[i]}|last={g[i+6]}|length=600" for i in range(-6,1)]
    lines += ["GATE_WINDOW_SCAN: -6/6", "GATE_WINDOWS_TOTAL: 7",
              "MIN_SIX_GAP_WINDOW: 600", "SHORT_SIX_GAP_WINDOWS: 7",
              "GATE_TARGET_PROBES: 0/8", "SHORT_SELECTED_YEAR_INTERVALS: 0",
              "GATE_TARGET_ADMISSION_NONE: 0/0", "GATE_GAP_EVALUATIONS: 12",
              "COMPOSITION_NOT_INVOKED: YES",
              "SCOPE=RADIUS64_GATE_WINDOW_STATIC_DISCOVERY_ONLY; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN"]
    good = "\n".join(lines)
    assert check(good, 6) == (13,12,7,600)
    for bad in [
        good.replace("length=600","length=601",1),
        good.replace("GATE_WINDOWS_TOTAL: 7","GATE_WINDOWS_TOTAL: 8"),
        good.replace("GATE_GAP_EVALUATIONS: 12","GATE_GAP_EVALUATIONS: 201"),
        good.replace("GATE_INDEX|index=0|day=600","GATE_INDEX|index=0|day=599"),
        good.replace("COMPOSITION_NOT_INVOKED: YES","COMPOSITION_NOT_INVOKED: NO"),
        good.replace("GATE_TARGET_ADMISSION_NONE: 0/0","GATE_TARGET_ADMISSION_PASS: 1/1"),
    ]:
        try: check(bad, 6)
        except (ValueError, KeyError): continue
        raise AssertionError("corrupt evidence accepted")
    print("INDEPENDENT_INTERVAL_SELFTEST: 7/7 PASS")

if __name__ == "__main__":
    try:
        if len(sys.argv) == 2 and sys.argv[1] == "--selftest": selftest()
        elif len(sys.argv) in (3, 4):
            seed = sys.argv[3] if len(sys.argv) == 4 else None
            print("INDEPENDENT_INTERVAL_VERIFIER: PASS gates/gaps/windows/min=" +
                  "/".join(map(str,check(Path(sys.argv[1]).read_text(),int(sys.argv[2]),seed))))
        else: raise ValueError("usage: checker.py --selftest OR checker.py stdout.txt radius [v4_seed.tsv]")
    except (ValueError, AssertionError, KeyError) as e:
        print("INDEPENDENT_INTERVAL_VERIFIER: FAIL "+str(e), file=sys.stderr)
        sys.exit(1)
