#!/usr/bin/env python3
"""Independent representative-caller LRU trace replay, QA only.
JSON object: workload, scope (off/call/session), events, summary.
Events: seq (zero-based), workload, session, call, kind, pre/post [entries, bytes].
Kinds: session_start, call_start, count, reset, call_end, session_end.
Session IDs start at 0, call IDs start at 0 in each session; outside call use null.
Reset reason: call or session. Count adds op (zero-based in call),
remaining, opened, closed, key, status, bits, decimal, digest, cost, victims.
Victims are ordered [key,cost] pairs. Error has null bits/decimal/digest,
zero cost and no victims. All other counts carry canonical decimal result,
including hits, so bit length and SHA256 can be checked independently.
Summary contains counts by status, evictions, resets, peak_entries, peak_bytes.
The schema is a QA protocol, not a production API.
"""
import argparse
from collections import OrderedDict
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ENTRY_CAP = 64
BYTE_CAP = 262144
EVENT_CAP = 20000
STATUSES = ("bypass", "hit", "miss", "oversize", "error")

class AuditError(ValueError):
    pass

def need(condition, message):
    if not condition:
        raise AuditError(message)

def integer(value):
    return type(value) is int and value >= 0

def digest(s):
    return hashlib.sha256(s.encode("ascii")).hexdigest()

def audit(doc):
    workload, scope = doc["workload"], doc["scope"]
    need(workload in ("COLD", "SAME", "MIXED", "INDEPENDENT", "LIFECYCLE", "RESET_CONTROL"), "workload")
    need(scope in ("off", "call", "session"), "scope")
    events = doc["events"]
    need(isinstance(events, list) and 0 < len(events) <= EVENT_CAP, "event bound")
    cache = OrderedDict()
    observed = {}
    seen_control = set()
    stats = dict.fromkeys(STATUSES, 0)
    stats.update(evictions=0, resets=0, peak_entries=0, peak_bytes=0)
    sid, cid, op = -1, -1, 0
    active_session = active_call = call_reset = session_reset = False
    session_calls = []
    total = 0
    def state():
        return [len(cache), total]
    for seq, e in enumerate(events):
        need(type(e["seq"]) is int and e["seq"] == seq and e["workload"] == workload, f"sequence {seq}")
        need(e["pre"] == state(), f"pre-state {seq}")
        kind = e["kind"]
        if kind == "session_start":
            need(not active_session and not cache and total == 0, "session starts dirty")
            sid += 1
            cid = -1
            active_session, session_reset = True, False
        elif kind == "call_start":
            need(active_session and not active_call and not session_reset, "call start")
            cid += 1
            active_call, call_reset, op = True, False, 0
            if scope in ("off", "call"):
                need(not cache and total == 0, "call starts dirty")
        need(type(e["session"]) is int and e["session"] == sid, f"session ID {seq}")
        need(e["call"] == (cid if active_call else None), f"call ID {seq}")
        if kind == "count":
            need(active_call and not call_reset, "count outside live call")
            need(type(e["op"]) is int and e["op"] == op, "operation sequence")
            op += 1
            v, o, c = e["remaining"], e["opened"], e["closed"]
            need(isinstance(v, list) and all(integer(x) for x in v) and integer(o) and integer(c), "key input types")
            key = f"{o}/{c}/" + ",".join(map(str, v))
            need(e["key"] == key, "canonical full key")
            status = e["status"]
            need(status in STATUSES, "status")
            victims = []
            cost = 0
            if status == "error":
                need(e["bits"] is None and e["decimal"] is None and e["digest"] is None, "error result")
                need(key not in cache, "error on cached key")
            else:
                decimal = e["decimal"]
                need(isinstance(decimal, str) and len(decimal) <= 1000000 and re.fullmatch(r"0|[1-9][0-9]*", decimal) is not None, "decimal")
                bits = int(decimal).bit_length()
                value_digest = digest(decimal)
                need(integer(e["bits"]) and e["bits"] == bits and e["digest"] == value_digest, "result digest/bit length")
                value = (bits, value_digest)
                need(observed.get(key, value) == value, "inconsistent result for exact key")
                observed[key] = value
                if workload == "INDEPENDENT":
                    need(key not in seen_control and status != "hit", "no-overlap control")
                    seen_control.add(key)
                if scope == "off":
                    expected = "bypass"
                elif key in cache:
                    expected = "hit"
                    cache.move_to_end(key)
                else:
                    cost = 128 + 2 * len(key) + (bits + 7) // 8
                    if cost > BYTE_CAP:
                        expected = "oversize"
                    else:
                        expected = "miss"
                        while len(cache) >= ENTRY_CAP or total + cost > BYTE_CAP:
                            victim, victim_cost = cache.popitem(last=False)
                            victims.append([victim, victim_cost])
                            total -= victim_cost
                        cache[key] = cost
                        total += cost
                need(status == expected, f"expected {expected}, got {status}")
            need(integer(e["cost"]) and e["cost"] == cost and e["victims"] == victims, "cost/victim order")
            stats[status] += 1
            stats["evictions"] += len(victims)
        elif kind == "reset":
            reason = e["reason"]
            if reason == "call":
                need(active_call and scope == "call" and not call_reset, "call reset")
                call_reset = True
            elif reason == "session":
                need(active_session and not active_call and not session_reset, "session reset")
                session_reset = True
            else:
                raise AuditError("unknown reset reason")
            cache.clear()
            total = 0
            stats["resets"] += 1
        elif kind == "call_end":
            need(active_call and (scope != "call" or call_reset), "missing call reset")
            need(op > 0, "empty call")
            active_call = False
        elif kind == "session_end":
            need(active_session and not active_call and session_reset and not cache and total == 0, "missing session reset")
            session_calls.append(cid + 1)
            active_session = False
        else:
            need(kind in ("session_start", "call_start"), "unknown event")
        need(e["post"] == state() and len(cache) <= ENTRY_CAP and 0 <= total <= BYTE_CAP, f"post-state/bound {seq}")
        stats["peak_entries"] = max(stats["peak_entries"], len(cache))
        stats["peak_bytes"] = max(stats["peak_bytes"], total)
    need(not active_session and not active_call and sid >= 0 and not cache and total == 0, "unclosed lifecycle")
    expected_calls = {"COLD": 1, "SAME": 4, "MIXED": 6, "INDEPENDENT": 8, "RESET_CONTROL": 4}
    if workload in expected_calls:
        need(session_calls == [expected_calls[workload]], "workload call cardinality")
    else:
        need(len(session_calls) >= 2, "lifecycle needs multiple sessions")
    if workload == "INDEPENDENT":
        need(len(seen_control) == 8 and stats["error"] == 0, "eight independent keys")
    need(doc["summary"] == stats, "summary mismatch")
    return stats

def verify_source(root, manifest):
    def git(*args):
        return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()
    locks = manifest["blobs"]
    parent = manifest["source_commit"]
    need(git("rev-parse", parent + "^{tree}") == manifest["source_tree"], "locked tree")
    tracked = git("ls-tree", "-r", "--name-only", "HEAD", "lib").splitlines()
    need(set(tracked) == {p for p in locks if p.startswith("lib/")}, "lib path set")
    for path, sha in locks.items():
        need(git("rev-parse", f"{parent}:{path}") == sha, f"parent blob {path}")
        need(git("rev-parse", f"HEAD:{path}") == sha, f"HEAD blob {path}")
        need(git("hash-object", "--", path) == sha, f"working blob {path}")
    return len(locks)

def fixture():
    # Hand-defined eviction at 65th distinct entry, then hit, then reset.
    events = []
    state = [0, 0]
    def emit(kind, after=None, **extra):
        nonlocal state
        e = dict(seq=len(events), workload="LIFECYCLE", session=0,
                 call=0 if kind in ("call_start", "count", "call_end") else None,
                 kind=kind, pre=state[:], post=(after or state)[:], **extra)
        events.append(e)
        state = e["post"][:]
    emit("session_start")
    emit("call_start")
    costs = [128 + 2 * len(f"0/0/{i}") + 1 for i in range(65)]
    for i in range(65):
        victim = [["0/0/0", costs[0]]] if i == 64 else []
        after = [min(i+1,64), sum(costs[:i+1]) - (costs[0] if i == 64 else 0)]
        emit("count", after, op=i, remaining=[i], opened=0, closed=0, key=f"0/0/{i}",
             status="miss", bits=1, decimal="1", digest=digest("1"), cost=costs[i], victims=victim)
    emit("count", op=65, remaining=[1], opened=0, closed=0, key="0/0/1",
         status="hit", bits=1, decimal="1", digest=digest("1"), cost=0, victims=[])
    peak = state[1]
    emit("call_end")
    emit("reset", [0,0], reason="session")
    emit("session_end")
    # Explicit new session after reset, one miss.
    start = len(events)
    for e in [
        dict(kind="session_start", call=None, pre=[0,0], post=[0,0]),
        dict(kind="call_start", call=0, pre=[0,0], post=[0,0]),
        dict(kind="count", call=0, pre=[0,0], post=[1,costs[1]], op=0, remaining=[1], opened=0, closed=0, key="0/0/1", status="miss", bits=1, decimal="1", digest=digest("1"), cost=costs[1], victims=[]),
        dict(kind="call_end", call=0, pre=[1,costs[1]], post=[1,costs[1]]),
        dict(kind="reset", call=None, pre=[1,costs[1]], post=[0,0], reason="session"),
        dict(kind="session_end", call=None, pre=[0,0], post=[0,0]),
    ]:
        events.append(dict(seq=len(events), workload="LIFECYCLE", session=1, **e))
    return dict(workload="LIFECYCLE", scope="session", events=events,
                summary=dict(bypass=0,hit=1,miss=66,oversize=0,error=0,evictions=1,resets=2,peak_entries=64,peak_bytes=peak))

def self_test():
    original = fixture()
    audit(original)
    mutations = [
        (2,"remaining",[99]), (2,"opened",1), (2,"closed",1),
        (66,"victims",[["0/0/1",139]]), (2,"bits",2), (2,"cost",0),
        (67,"status","miss"), (2,"digest","0"*64), (2,"decimal","2"),
        (69,"reason","call"), (3,"seq",99), (3,"post",[0,0]),
    ]
    for index, key, value in mutations:
        bad = deepcopy(original)
        bad["events"][index][key] = value
        try:
            audit(bad)
        except AuditError:
            continue
        raise AuditError(f"mutation escaped: {index}/{key}")
    bad = deepcopy(original)
    bad["events"].pop(69)
    for i,e in enumerate(bad["events"]):
        e["seq"] = i
    try:
        audit(bad)
    except AuditError:
        pass
    else:
        raise AuditError("missing reset escaped")
    print(json.dumps({"synthetic_valid":1,"mutations_rejected":len(mutations)+1},sort_keys=True))

def main():
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(0)
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--verify-source", type=Path)
    p.add_argument("--manifest", type=Path, default=Path(__file__).with_name("dart_hebrew_representative_source_lock.json"))
    p.add_argument("trace", nargs="*", type=Path)
    a = p.parse_args()
    need(a.self_test or a.verify_source is not None or a.trace, "no operation")
    if a.self_test:
        self_test()
    if a.verify_source is not None:
        print(json.dumps({"locked_blobs":verify_source(a.verify_source, json.loads(a.manifest.read_text(encoding="utf-8")))}))
    for path in a.trace:
        print(json.dumps({"path":str(path),"summary":audit(json.loads(path.read_text(encoding="utf-8")))},sort_keys=True))

if __name__ == "__main__":
    try:
        main()
    except (AuditError, KeyError, TypeError, ValueError, OSError, subprocess.CalledProcessError) as exc:
        print(f"TRACE_AUDIT_FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
