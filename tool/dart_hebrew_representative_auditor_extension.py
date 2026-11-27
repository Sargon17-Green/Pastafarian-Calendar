#!/usr/bin/env python3
"""Additional synthetic protocol tests, not Dart counter or Native evidence."""
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
from dart_hebrew_representative_lru_audit import audit, AuditError

MANIFEST = Path(__file__).with_name("dart_hebrew_representative_frozen_manifest.json")
MANIFEST_SHA = "e931141175945f3ef0c7273f5d5fdf2acc9bd81cecee6af361e6453ef40b08a4"

class Trace:
    def __init__(self, workload, scope):
        self.workload, self.scope = workload, scope
        self.events, self.state = [], [0, 0]
        self.sid, self.cid, self.op = -1, None, 0
        self.stats = dict(bypass=0, hit=0, miss=0, oversize=0, error=0,
                          evictions=0, resets=0, peak_entries=0, peak_bytes=0)

    def emit(self, kind, after=None, **kw):
        post = self.state[:] if after is None else after[:]
        self.events.append(dict(seq=len(self.events), workload=self.workload,
            session=self.sid, call=self.cid, kind=kind, pre=self.state[:],
            post=post, **kw))
        self.state = post
        self.stats["peak_entries"] = max(self.stats["peak_entries"], post[0])
        self.stats["peak_bytes"] = max(self.stats["peak_bytes"], post[1])

    def start(self):
        self.sid += 1
        self.next_call = 0
        self.emit("session_start")

    def call(self):
        self.cid = self.next_call
        self.next_call += 1
        self.op = 0
        self.emit("call_start")

    def count(self, vector, status, after, victims=(), opened=0, closed=0):
        key = f"{opened}/{closed}/" + ",".join(map(str, vector))
        error = status == "error"
        cost = 128 + 2 * len(key) + 1 if status in ("miss", "oversize") else 0
        self.emit("count", after, op=self.op, remaining=vector, opened=opened,
            closed=closed, key=key, status=status, bits=None if error else 1,
            decimal=None if error else "1",
            digest=None if error else sha256(b"1").hexdigest(), cost=cost,
            victims=list(victims))
        self.stats[status] += 1
        self.stats["evictions"] += len(victims)
        self.op += 1
        return [key, cost]

    def reset(self, reason):
        self.emit("reset", [0, 0], reason=reason)
        self.stats["resets"] += 1

    def end_call(self):
        self.emit("call_end")
        self.cid = None

    def end(self):
        self.reset("session")
        self.emit("session_end")

    def doc(self):
        return dict(workload=self.workload, scope=self.scope,
                    events=self.events, summary=self.stats)

def keycost(vector):
    # Expected fixture arithmetic; no replay or cache simulation.
    return 128 + 2 * len("0/0/" + ",".join(map(str, vector))) + 1

def byte_fixture():
    t = Trace("LIFECYCLE", "session")
    t.start()
    t.call()
    vectors = [[123] * 10000 + [i] for i in range(3)]
    cost = keycost(vectors[0])
    assert 3 * cost < 262144
    entries = [t.count(v, "miss", [i + 1, (i + 1) * cost])
               for i, v in enumerate(vectors)]
    # Touch first: second and third become the oldest two.
    t.count(vectors[0], "hit", [3, 3 * cost])
    big = [123] * 20000 + [4]
    bcost = keycost(big)
    assert 2 * cost + bcost > 262144 >= cost + bcost
    t.count(big, "miss", [2, cost + bcost], entries[1:])
    oversized = [123] * 33000 + [5]
    assert keycost(oversized) > 262144
    t.count(oversized, "oversize", [2, cost + bcost])
    t.count([1], "error", [2, cost + bcost], closed=1)
    t.end_call()
    t.end()
    t.start()
    t.call()
    t.count(vectors[0], "miss", [1, cost])
    t.end_call()
    t.end()
    return t.doc()

def independent_fixture(repeat=False):
    t = Trace("INDEPENDENT", "session")
    t.start()
    cost = keycost([100, 100, 100])
    for i in range(8):
        t.call()
        if repeat and i == 7:
            t.count([100, 100, 100], "hit", [7, 7 * cost])
        else:
            t.count([100 + i, 100, 100], "miss", [i + 1, (i + 1) * cost])
        t.end_call()
    t.end()
    return t.doc()

def call_fixture():
    t = Trace("LIFECYCLE", "call")
    for _ in range(2):
        t.start()
        t.call()
        t.count([2], "miss", [1, keycost([2])])
        t.count([1], "error", [1, keycost([2])], closed=1)
        t.reset("call")
        t.end_call()
        t.end()
    return t.doc()

def rejected(doc, label):
    try:
        audit(doc)
    except AuditError:
        return label
    raise RuntimeError("mutation accepted: " + label)

def main():
    if sha256(MANIFEST.read_bytes()).hexdigest() != MANIFEST_SHA:
        raise RuntimeError("frozen manifest hash mismatch")
    byte, control, call = byte_fixture(), independent_fixture(), call_fixture()
    for doc in (byte, control, call):
        audit(doc)
    labels = [rejected(independent_fixture(True), "no-overlap hit")]
    for kind, status, field, value, label in (
        ("count", "miss", "victims", [], "missing byte-cap victims"),
        ("count", "oversize", "status", "miss", "oversize insertion"),
        ("count", "error", "cost", 1, "invalid input insertion"),
    ):
        bad = deepcopy(byte)
        event = next(e for e in bad["events"] if e["kind"] == kind
                     and e["status"] == status
                     and (label != "missing byte-cap victims" or e["victims"]))
        event[field] = value
        labels.append(rejected(bad, label))
    bad = deepcopy(byte)
    next(e for e in bad["events"] if e.get("victims"))["victims"].reverse()
    labels.append(rejected(bad, "reversed multi-victim order"))
    bad = deepcopy(call)
    next(e for e in bad["events"] if e.get("reason") == "call")["reason"] = "session"
    labels.append(rejected(bad, "missing call-finally reset"))
    print(json.dumps(dict(synthetic_valid=3, mutations_rejected=len(labels),
                          labels=labels, manifest_sha256=MANIFEST_SHA)))

if __name__ == "__main__":
    main()
