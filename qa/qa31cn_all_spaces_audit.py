"""Reconcile physical put counts, final values and all retired-space check sizes in Native receipts."""
import argparse
import hashlib
import json
from pathlib import Path

BASE = {(0,0),(5,0),(10,49),(500,1500),(100,500),(1528,2014)}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def audit(data, legacy, root):
    runs, phases = data["runs"], data["phases"]
    require(len(runs) == 31 and len(phases) == 93 and len(legacy) == 15, "receipt cardinality")
    retired_cells = space_checks = cell_checks = put_count = 0
    sources = set()
    for index, run in enumerate(runs):
        name = run["path"]
        if index < 16:
            original = "qa/interleaved_work_counts_pre_lexical_baseline.b98"
            require(name == (original if index in (5,7,14) else "src/interleaved_work_counts.b98"), "original 16 sources")
        else:
            old = legacy[index-16]
            for key in ("path","input","source_blob","output","native_fresh_cli"):
                require(run[key] == old[key], "legacy row mismatch")
        sources.add(name)
        code = (root/name).read_bytes()
        blob = hashlib.sha1(b"blob "+str(len(code)).encode()+b"\0"+code).hexdigest()
        require(run["ordinal"] == index and run["source_blob"] == blob, "ordinal/source")
        require(run["output"] and run["output"] == run["native_fresh_cli"], "CLI disagreement")
        snap = {tuple(p):v for p,v in run["snapshot"]}
        writes = {tuple(p):(n,v) for p,n,v in run["writes"]}
        require(len(writes) == len(run["writes"]) and len(snap) == len(run["snapshot"]), "duplicate address")
        require(set(snap) == (BASE | set(writes)), "snapshot address set")
        for p,value in snap.items():
            require(len(p) == 2 and all(type(v) is int for v in p) and str(int(value)) == value, "snapshot value")
            if p in writes:
                count, final = writes[p]
                require(type(count) is int and count > 0 and final == value, "last put/snapshot disagreement")
                put_count += count
            else:
                x,y = p
                lines = code.split(b"\n")
                initial = lines[y][x] if 0 <= y < len(lines) and 0 <= x < len(lines[y]) else 32
                require(value == str(initial), "untouched sentinel changed")
        if index >= 16:
            require(set(writes) == set(map(tuple, old["written_addresses"])), "legacy writes")
        for j, phase in enumerate(("before-reset","after-reset","after-execute")):
            check = phases[3*index+j]
            require(check == {"phase":phase,"retired":index,"cells":retired_cells}, "missing prior space/cell comparison")
            space_checks += index
            cell_checks += retired_cells
        retired_cells += len(snap)
    require(sum(path.startswith("src/") for path in sources) == 11 and space_checks == 1395, "source/ownership coverage")
    return {"native_runs":len(runs),"production_sources":11,"archived_sources":1,
            "phase_checks":len(phases),"space_comparisons":space_checks,
            "cell_comparisons":cell_checks,"physical_puts":put_count,"snapshot_cells":retired_cells}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("all_spaces", type=Path)
    parser.add_argument("entrypoints", type=Path)
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()
    print(json.dumps(audit(json.loads(args.all_spaces.read_bytes()),
                           json.loads(args.entrypoints.read_bytes()), args.root), sort_keys=True))
