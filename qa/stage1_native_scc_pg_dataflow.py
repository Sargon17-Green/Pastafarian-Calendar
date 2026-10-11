#!/usr/bin/env python3
"""Stage-1 source-pinned Native SCC/physical-memory data-flow audit.

Real 17-case PyFunge STEP/READ/WRITE traces were already authenticated by
stage1_native_diverse_geometry_audit.py. This independent algorithm uses
only executed post-handoff IP transitions and measured native memory API
events. Python NEVER computes a calendar, simulates Befunge, or substitutes
an arithmetic oracle. Finite QA only, not geometry acceptance.
"""
from collections import Counter, defaultdict
import hashlib
import json
import tempfile
from pathlib import Path
import sys

BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
LABELS = (
    "zero_equal","foundation_cross","forward_short","reverse_short",
    "mixed_small","positive_negative","negative_positive","large_values",
    "invalid_zero_sign","invalid_big_sign","epoch_forward_one",
    "epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
    "foundation_neighbor_forward","foundation_neighbor_reverse",
    "invalid_target_zero_sign",
)

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def scc(adj):
    """Iterative Kosaraju; no networkx or synthetic source-map edges."""
    vertices = set(adj)
    for destinations in adj.values():
        vertices.update(destinations)
    seen, finished = set(), []
    for start in vertices:
        if start in seen: continue
        seen.add(start)
        stack = [(start, iter(adj.get(start, ())))]
        while stack:
            u, iterator = stack[-1]
            try: v = next(iterator)
            except StopIteration:
                finished.append(u)
                stack.pop()
                continue
            if v not in seen:
                seen.add(v)
                stack.append((v, iter(adj.get(v, ()))))
    reverse = defaultdict(set)
    for u, targets in adj.items():
        for v in targets: reverse[v].add(u)
    seen = set()
    for start in reversed(finished):
        if start in seen: continue
        seen.add(start)
        group, pending = set(), [start]
        while pending:
            u = pending.pop()
            group.add(u)
            for v in reverse.get(u, ()):
                if v not in seen:
                    seen.add(v)
                    pending.append(v)
        if len(group) > 1 or start in adj.get(start, ()):
            yield group

def observe(path):
    edges = defaultdict(set)
    opcode_counts = defaultdict(Counter)
    positions = {}
    read_pending = {}
    write_pending = {}
    # Executed opcode is identified by tick, not historical coordinate:
    # self-modifying code may later execute a different opcode at that cell.
    expected_event = None
    event_completed = False
    reads, writes = [], []
    handoff, previous, last_step, steps = False, None, 0, 0
    with path.open(encoding="ascii") as stream:
        for line in stream:
            fields = line.rstrip("\n").split("\t")
            tag = fields[0]
            need(tag in ("STEP","READ_BEFORE","READ_AFTER",
                         "WRITE_BEFORE","WRITE_AFTER"),
                 "unknown Native TSV event")
            v = tuple(map(int, fields[1:]))
            if tag == "STEP":
                if handoff:
                    need(not read_pending and not write_pending and
                         (expected_event is None or event_completed),
                         "missing native g/p event pair before next STEP")
                need(len(v) == 8 and v[0] == last_step + 1,
                     "noncontiguous physical Native instruction trace")
                last_step = v[0]
                tick, ip, x, y, dx, dy, op, depth = v
                if not handoff:
                    if (x, y, dx, dy) != (5, 0, 1, 0): continue
                    handoff = True
                need((dx,dy) != (0,0) and depth >= 0,
                     "non-progressing Native instruction")
                p = (x,y)
                positions[tick] = p
                expected_event=("READ" if op==ord("g") and depth>=2 else
                                "WRITE" if op==ord("p") and depth>=3 else None)
                event_completed=False
                opcode_counts[p][chr(op) if 32 <= op <= 126 else "?"] += 1
                if previous is not None: edges[previous].add(p)
                previous = p
                steps += 1
            elif handoff:
                need(v and v[0] == last_step and v[0] in positions,
                     "orphaned post-handoff Native read/write")
                tick = v[0]
                if tag == "READ_BEFORE":
                    need(expected_event=="READ" and not event_completed,
                         "Native g event attached to a non-g STEP")
                    need(len(v) == 4 and tick not in read_pending,
                         "broken Native g BEFORE")
                    read_pending[tick] = v
                elif tag == "READ_AFTER":
                    need(len(v) == 4 and read_pending.pop(tick, None) == v
                         and expected_event=="READ" and not event_completed,
                         "Native g physical return mismatch")
                    event_completed=True
                    reads.append((tick, positions[tick], (v[1],v[2]), v[3]))
                elif tag == "WRITE_BEFORE":
                    need(expected_event=="WRITE" and not event_completed,
                         "Native p event attached to a non-p STEP")
                    need(len(v) == 5 and tick not in write_pending,
                         "broken Native p BEFORE")
                    write_pending[tick] = v
                elif tag == "WRITE_AFTER":
                    before = write_pending.pop(tick, None)
                    need(len(v) == 4 and before is not None
                         and v[1:3] == before[1:3] and v[3] == before[4]
                         and expected_event=="WRITE" and not event_completed,
                         "Native p physical store mismatch")
                    event_completed=True
                    writes.append((tick, positions[tick], (v[1],v[2]), v[3]))
    need(handoff and steps >= 7000 and not read_pending and not write_pending,
         "incomplete native arithmetic SCC trace")
    need(expected_event is None or event_completed,
         "missing native g/p event pair at final STEP")
    return edges, opcode_counts, reads, writes, steps

def measure(folder, record):
    label, filename = record["case"], record["trace_file"]
    need(filename == label + ".tsv", "Native manifest path drift")
    raw = (folder / filename).read_bytes()
    need(hashlib.sha256(raw).hexdigest() == record["trace_sha256"],
         "Native signed trace SHA-256 mismatch " + label)
    adj, execution, reads, writes, steps = observe(folder / filename)
    groups = []
    for comp in scc(adj):
        op = Counter()
        for p in comp: op.update(execution.get(p, {}))
        groups.append((comp, op))
    large = [(c,op) for c,op in groups if len(c) >= 1000]
    upper = [(c,op) for c,op in groups
             if len(c) == 2 and op["r"] == 1 and op["["] == 2]
    lower = [(c,op) for c,op in groups
             if len(c) == 18 and op["w"] == 1
             and op["_"] == 1 and op["]"] == 2 and op["x"] == 2]
    need(len(upper) + len(lower) == 1 and len(large) <= 1,
         "executed native cycle fingerprint not observed " + label)
    witness = None
    same_scc_readbacks = 0
    if large:
        comp, opcode = large[0]
        need(len(comp) == 2326 and opcode["p"] >= 10
             and opcode["g"] >= 20 and opcode["x"] >= 60,
             "executed 2D arithmetic SCC lost native p/g/x involvement")
        last = {}
        for tick, kind, evt in sorted([(w[0],0,w) for w in writes] +
                                       [(r[0],1,r) for r in reads]):
            t, active, cell, value = evt
            if kind == 0: last[cell] = (t,active,value)
            elif active in comp and cell in last:
                p_tick, writer, prior = last[cell]
                if writer in comp:
                    need(p_tick < tick and value == prior,
                         "same-SCC Native g did not read most recent p value")
                    same_scc_readbacks += 1
                    if witness is None:
                        witness = {"write_tick":p_tick,"read_tick":tick,
                                   "writer":list(writer),"reader":list(active),
                                   "physical_cell":list(cell),"value":str(value)}
        need(same_scc_readbacks >= 10,
             "arithmetic SCC lacked executed read-after-write causality")
    return {"case":label,"steps":steps,
            "native_trace_sha256":record["trace_sha256"],
            "native_cycle_sizes":sorted([len(c) for c,op in groups],reverse=True),
            "live_arithmetic_scc":bool(large),
            "conditional_cycle":"upper_r_left" if upper else "lower_w_underscore",
            "same_scc_native_p_g_readbacks":same_scc_readbacks,
            "first_concrete_p_g_witness":witness}

def validate(report):
    need(report.get("schema") == "befunge-stage1-native-scc-pg-v1"
         and report.get("production_git_blob") == BLOB
         and report.get("stage1_final_acceptance") is False,
         "Native geometry source or premature acceptance forged")
    rows = report.get("cases")
    need(isinstance(rows,list) and len(rows) == 17
         and tuple(z["case"] for z in rows) == LABELS,
         "Native geometry lacks one of 17 source-pinned traces")
    upper = sum(z["conditional_cycle"] == "upper_r_left" for z in rows)
    lower = sum(z["conditional_cycle"] == "lower_w_underscore" for z in rows)
    large = sum(z["live_arithmetic_scc"] is True for z in rows)
    need((upper,lower,large) == (11,6,14),
         "real cycles no longer show 11 upper/6 lower/14 arithmetic")
    need(all(len(z.get("native_trace_sha256","")) == 64
             and z.get("steps",0) >= 7000
             and (z["same_scc_native_p_g_readbacks"] >= 10
                  and z["first_concrete_p_g_witness"] is not None
                  if z["live_arithmetic_scc"]
                  else z["first_concrete_p_g_witness"] is None)
             for z in rows),
         "Native cycle data flow or digest evidence forged")
    return {"native_cases":17,"upper_reflective_cycles":upper,
            "lower_w_underscore_cycles":lower,
            "arithmetic_p_g_cycles":large,
            "native_same_scc_read_after_write":sum(
                z["same_scc_native_p_g_readbacks"] for z in rows)}

def trace_binding_selftest():
    """Synthetic trace controls for this auditor, NOT Native arithmetic."""
    lines=[
        "STEP\t1\t1\t5\t0\t1\t0\t32\t0",
        "STEP\t2\t1\t10\t10\t1\t0\t103\t2",
        "READ_BEFORE\t2\t30\t40\t32",
        "READ_AFTER\t2\t30\t40\t32",
        "STEP\t3\t1\t11\t10\t1\t0\t112\t3",
        "WRITE_BEFORE\t3\t30\t40\t32\t49",
        "WRITE_AFTER\t3\t30\t40\t49",
        "STEP\t4\t1\t10\t10\t1\t0\t32\t2",
        "STEP\t5\t1\t11\t10\t1\t0\t32\t3",
    ]
    # A coordinate that executed g/p in a prior step cannot authorize
    # a memory event on a *later* non-g/non-p STEP at the same coordinate.
    for t in range(6,7002):
        lines.append("STEP\t%d\t1\t%d\t12\t1\t0\t32\t0" %
                     (t,t+20))
    with tempfile.TemporaryDirectory() as scratch:
        path=Path(scratch)/"synthetic_scc_trace.tsv"
        def run(records):
            path.write_text("\n".join(records)+"\n",encoding="ascii")
            return observe(path)
        adj,op,reads,writes,steps=run(lines)
        need(steps>=7000 and len(reads)==1 and len(writes)==1,
             "clean synthetic g/p trace rejected")
        def reject(name,records,why):
            try:
                run(records)
            except AssertionError as err:
                need(why in str(err),
                     "unexpected rejection %s: %s" % (name,err))
            else:
                raise AssertionError("forged SCC trace accepted: "+name)
        fake_read=lines[:8]+[
            "READ_BEFORE\t4\t30\t40\t49",
            "READ_AFTER\t4\t30\t40\t49"]+lines[8:]
        reject("historical_g_at_same_cell",fake_read,"non-g STEP")
        fake_write=lines[:9]+[
            "WRITE_BEFORE\t5\t31\t40\t32\t50",
            "WRITE_AFTER\t5\t31\t40\t50"]+lines[9:]
        reject("historical_p_at_same_cell",fake_write,"non-p STEP")
        no_read=[r for r in lines
                 if not r.startswith(("READ_BEFORE","READ_AFTER"))]
        reject("missing_g_event_pair",no_read,"missing native g/p event pair")
        no_write=[r for r in lines
                  if not r.startswith(("WRITE_BEFORE","WRITE_AFTER"))]
        reject("missing_p_event_pair",no_write,"missing native g/p event pair")
    print("NATIVE_SCC_STEP_BOUND_G_P_FOUR_SYNTHETIC_NEGATIVES_PASS")

def main(root):
    trace_binding_selftest()
    raw = Path("src/interleaved_work_counts.b98").read_bytes()
    pin = hashlib.sha1(b"blob "+str(len(raw)).encode("ascii")+b"\0"+raw).hexdigest()
    need(pin == BLOB, "Production source Git object changed")
    manifest = json.loads((root/"diverse_manifest.json").read_text("utf-8"))
    need(manifest["schema"] == "befunge-stage1-diverse-native-v1"
         and tuple(z["case"] for z in manifest["cases"]) == LABELS,
         "Native source trace manifest changed")
    result = {"schema":"befunge-stage1-native-scc-pg-v1",
              "production_git_blob":BLOB,"stage1_final_acceptance":False,
              "cases":[measure(root,x) for x in manifest["cases"]]}
    summary = validate(result)
    attacks = []
    def reject(name, fn):
        mutant = json.loads(json.dumps(result))
        fn(mutant)
        try:validate(mutant)
        except AssertionError:
            attacks.append(name)
            return
        raise AssertionError("Native cycle evidence tamper accepted: "+name)
    reject("missing_case",lambda x:x["cases"].pop())
    reject("wrong_source",lambda x:x.__setitem__("production_git_blob","0"*40))
    reject("premature_stage1",lambda x:x.__setitem__("stage1_final_acceptance",True))
    reject("wrong_upper_lower",lambda x:x["cases"][0].__setitem__("conditional_cycle","lower_w_underscore"))
    reject("false_arithmetic_cycle",lambda x:x["cases"][0].__setitem__("live_arithmetic_scc",True))
    reject("zero_dataflow",lambda x:x["cases"][1].__setitem__("same_scc_native_p_g_readbacks",0))
    reject("absent_witness",lambda x:x["cases"][1].__setitem__("first_concrete_p_g_witness",None))
    reject("bad_trace_hash",lambda x:x["cases"][1].__setitem__("native_trace_sha256","bad"))
    need(len(attacks) == 8, "Native SCC tamper control incomplete")
    result["summary"] = summary
    result["adversarial_reports_rejected"] = attacks
    (root/"native_scc_pg_dataflow.json").write_text(
        json.dumps(result,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_17_CASE_SCC_DATAFLOW_PASS",json.dumps(summary,sort_keys=True))
    print("NATIVE_SCC_8_TAMPER_CONTROLS_REJECTED_PASS")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; bounded actual Native geometry only")

if __name__ == "__main__":
    need(len(sys.argv)==2,"usage: native diverse trace folder or --selftest")
    if sys.argv[1]=="--selftest":
        trace_binding_selftest()
    else:
        main(Path(sys.argv[1]))
