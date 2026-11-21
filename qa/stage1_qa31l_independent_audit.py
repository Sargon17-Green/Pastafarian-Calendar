#!/usr/bin/env python3
"""QA31L independent Python 3 source/STEP/EOF/p-g/j auditor (not Native execution)."""
import copy
import gzip
import hashlib
import io
import json
import sys
import zipfile
from pathlib import Path

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
RAW = b"0"
LABEL = "single_zero"
TRACE = "qa31g_single_zero.jsonl.gz"
TARGETS = ((0, 49), (1, 49), (3, 49))
CAP = 7000
UNMODELED = {ord("{"), ord("}"), ord("u"), ord("s")}

def need(ok, message):
    if not ok:
        raise AssertionError(message)

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def read_source(path):
    data = Path(path).read_bytes()
    git_sha = hashlib.sha1(b"blob " + str(len(data)).encode("ascii")
                           + b"\0" + data).hexdigest()
    need(git_sha == PIN, "immutable source blob mismatch")
    rows = data.splitlines()
    need(len(rows) > 49, "source row count is unexpectedly short")
    need(cell(rows, 150, 29) == ord("x"), "source at (150,29) != x")
    need(cell(rows, 151, 29) == ord("0"), "source at (151,29) != 0")
    for x, y in TARGETS:
        need(cell(rows, x, y) == 32, "source target is not a blank cell")
    return rows

def cell(rows, x, y):
    return rows[y][x] if 0 <= y < len(rows) and 0 <= x < len(rows[y]) else 32

def read_evidence(folder):
    archive_path = folder / "qa31l-native-evidence.zip"
    archive_bytes = archive_path.read_bytes()
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        need(archive.testzip() is None, "ZIP CRC failed")
        need(set(archive.namelist()) == {"qa31l_receipt.json", TRACE},
             "unexpected ZIP entries")
        receipt_bytes = archive.read("qa31l_receipt.json")
        trace_bytes = archive.read(TRACE)
    need(receipt_bytes == (folder / "qa31l_receipt.json").read_bytes(),
         "ZIP receipt differs from native output")
    need(trace_bytes == (folder / TRACE).read_bytes(),
         "ZIP trace differs from native output")
    receipt = json.loads(receipt_bytes)
    steps = [json.loads(s) for s in gzip.decompress(trace_bytes).splitlines()]
    return receipt, steps, sha256(trace_bytes), sha256(archive_bytes)

def validate(receipt, steps, trace_digest, rows):
    need(receipt.get("schema") == "qa31l-single-zero-original-native-v1",
         "schema")
    need(receipt.get("source_blob") == PIN and
         receipt.get("source_modified") is False and
         receipt.get("ip_relocated") is False and
         receipt.get("stage1_pass") is False and
         receipt.get("global_owner_proven") is False and
         receipt.get("native_model_proven") is False and
         receipt.get("old_cases_rerun") == 0 and
         receipt.get("input_case_count") == 1,
         "source, prior-case, or acceptance scope")
    need(len(receipt.get("cases", [])) == 1, "one native case")
    case = receipt["cases"][0]
    need(case.get("label") == LABEL and case.get("trace") == TRACE,
         "case/trace identity")
    need(case.get("raw_hex") == RAW.hex() and
         case.get("raw_sha256") == sha256(RAW), "raw single-byte input")
    need(case.get("trace_sha256") == trace_digest, "trace digest")
    need(0 < len(steps) <= CAP and case.get("steps") == len(steps),
         "physical STEP count or 7000 cap")
    need(case.get("status") in ("HALT", "STEP_LIMIT", "RUNTIME_ERROR"),
         "native terminal status")
    need((case["status"] == "RUNTIME_ERROR") == (case.get("error") is not None),
         "runtime error receipt")
    need(type(case.get("output")) is list, "output receipt")

    overlay = {}
    writers = {}
    reads = []
    gates = []
    target_events = []
    x_hits = []
    zero_hits = []
    unknown = []
    op_hits = {"p": [], "g": [], "j": []}
    for idx, step in enumerate(steps):
        tick = idx + 1
        need(step.get("t") == tick, "STEP tick continuity")
        ip, delta = step["ip"], step["delta"]
        pre, post = step["pre"], step["post"]
        need(type(ip) is list and type(delta) is list and
             len(ip) == len(delta) == 2 and
             all(type(v) is int for v in ip + delta) and delta != [0, 0],
             "IP/delta or zero direction")
        need(type(pre) is list and type(post) is list and
             all(type(v) is int for v in pre + post),
             "physical stack is not integral")
        if step["string"] is not False:
            unknown.append({"tick": tick, "ip": ip, "reason": "stringmode"})
        x, y = ip
        op = step["op"]
        if not unknown:
            need(op == overlay.get((x, y), cell(rows, x, y)),
                 "source/overlay opcode mismatch")
        if idx:
            prior = steps[idx - 1]
            need(prior.get("next") == ip and prior.get("next_delta") == delta,
                 "IP/delta physical continuity")
            need(prior.get("post") == pre,
                 "physical stack continuity between STEP records")
        if op in UNMODELED:
            unknown.append({"tick": tick, "ip": ip, "opcode": op})
        if ip == [150, 29]:
            x_hits.append(tick)
        if ip == [151, 29]:
            zero_hits.append(tick)

        if op == ord("p") and not unknown:
            need(len(pre) >= 3 and post == pre[:-3], "physical p stack pop")
            xy = (pre[-2], pre[-1])
            value = pre[-3]
            overlay[xy] = value
            op_hits["p"].append(idx)
            if xy in TARGETS:
                prior = writers.get(xy)
                target_events.append({
                    "tick": tick, "kind": "p", "cell": list(xy), "value": value,
                    "previous_writer": prior})
                writers[xy] = {"tick": tick, "value": value, "ip": ip}
        elif op == ord("g") and not unknown:
            need(len(pre) >= 2 and len(post) == len(pre) - 1 and
                 post[:-1] == pre[:-2], "physical g stack")
            xy = (pre[-2], pre[-1])
            value = overlay.get(xy, cell(rows, *xy))
            need(post[-1] == value, "g last-writer/source result mismatch")
            op_hits["g"].append(idx)
            if xy in TARGETS:
                target_events.append({
                    "tick": tick, "kind": "g", "cell": list(xy),
                    "value": value, "last_writer": writers.get(xy)})
        elif op == ord("j") and not unknown:
            value = pre[-1] if pre else 0
            need(post == (pre[:-1] if pre else []), "j stack operand pop")
            need(step.get("next") ==
                 [x + (value + 1) * delta[0], y + (value + 1) * delta[1]],
                 "j successor formula")
            gates.append({"tick": tick, "ip": ip, "operand": value,
                          "next": step["next"]})
            op_hits["j"].append(idx)

        need(type(step.get("reads")) is list, "missing input read events")
        for event in step["reads"]:
            a, b = event["start"], event["end"]
            need(event["t"] == tick and event["ip"] == ip and
                 event["stack"] == pre and
                 event["method"] in ("read", "readline") and
                 type(a) is int and type(b) is int and
                 0 <= a <= b <= len(RAW) and
                 event["hex"] == RAW[a:b].hex(), "read event/raw slice")
            reads.append(event)
    need(reads and case["reads"] == len(reads), "read tally")
    need(reads[0]["ip"] == [13, 5] and
         reads[0]["start"] == 0 and reads[0]["end"] == 1 and
         reads[0]["hex"] == "30", "one natural digit was not read")
    need(all(r["start"] == r["end"] == 1 and r["hex"] == ""
             for r in reads[1:]), "subsequent input was not EOF")
    if case["status"] == "HALT":
        need(steps[-1]["next"] is None and steps[-1]["op"] == ord("@"),
             "HALT terminal STEP")
    if case["status"] == "STEP_LIMIT":
        need(len(steps) == CAP, "STEP_LIMIT without 7000 steps")
    if case["status"] == "RUNTIME_ERROR":
        need("error" in steps[-1], "runtime error terminal STEP")
    return {
        "status": case["status"], "steps": len(steps),
        "input_reads": len(reads), "eof_reads": sum(
            r["start"] == r["end"] == 1 for r in reads),
        "gates": gates, "target_events": target_events,
        "x15029_ticks": x_hits, "zero15129_ticks": zero_hits,
        "coverage_unknown_opcode": unknown,
        "output": case["output"], "op_hits": op_hits,
    }

def adversarial_checks(receipt, steps, digest, rows):
    rejected, unavailable = [], []
    def attempt(name, tweak):
        r = copy.deepcopy(receipt)
        s = copy.deepcopy(steps)
        try:
            tweak(r, s)
            validate(r, s, digest, rows)
        except (AssertionError, KeyError, IndexError, TypeError, ValueError):
            rejected.append(name)
        else:
            raise AssertionError("hostile mutation accepted: " + name)
    attempt("wrong_source_pin", lambda r, s:
            r.__setitem__("source_blob", "0" * 40))
    attempt("wrong_raw_byte", lambda r, s:
            r["cases"][0].__setitem__("raw_hex", "31"))
    attempt("wrong_raw_digest", lambda r, s:
            r["cases"][0].__setitem__("raw_sha256", "0" * 64))
    attempt("deleted_physical_STEP", lambda r, s: s.pop(min(2, len(s)-1)))
    attempt("zero_IP_delta", lambda r, s:
            s[0].__setitem__("delta", [0, 0]))
    attempt("fake_stage1_PASS", lambda r, s:
            r.__setitem__("stage1_pass", True))
    indexes = {
        "altered_p_value": next((i for i, v in enumerate(steps)
                                 if v["op"] == ord("p")), None),
        "altered_g_result": next((i for i, v in enumerate(steps)
                                  if v["op"] == ord("g")), None),
        "forged_j_successor": next((i for i, v in enumerate(steps)
                                    if v["op"] == ord("j")), None),
    }
    for name, i in indexes.items():
        if i is None:
            unavailable.append(name)
            continue
        if name == "altered_p_value":
            attempt(name, lambda r, s, i=i:
                    s[i]["pre"].__setitem__(-3, s[i]["pre"][-3] + 1))
        elif name == "altered_g_result":
            attempt(name, lambda r, s, i=i:
                    s[i]["post"].__setitem__(-1, s[i]["post"][-1] + 1))
        else:
            attempt(name, lambda r, s, i=i:
                    s[i].__setitem__("next", [99999999, 99999999]))
    return rejected, unavailable

def main(source_path, output_path):
    folder = Path(output_path)
    rows = read_source(source_path)
    receipt, steps, digest, archive_digest = read_evidence(folder)
    facts = validate(receipt, steps, digest, rows)
    rejected, unavailable = adversarial_checks(receipt, steps, digest, rows)
    sufficient = len(rejected) >= 8 and not unavailable
    covered = not facts["coverage_unknown_opcode"]
    result = {
        "schema": "qa31l-independent-source-step-v1",
        "source_blob": PIN, "raw_hex": RAW.hex(),
        "raw_sha256": sha256(RAW),
        "compressed_trace_sha256": digest,
        "zip_sha256": archive_digest,
        "zip_crc_pass": True,
        "facts": {k:v for k,v in facts.items() if k != "op_hits"},
        "hostile_rejected": rejected,
        "hostile_unavailable": unavailable,
        "oracle_coverage_complete": covered,
        "hostile_minimum_8_met": sufficient,
        "bounded_evidence_verified": covered and sufficient,
        "stage1_pass": False, "global_owner_proven": False,
        "full_functional_qa_pass": False,
        "geometric_spaghetti_qa_pass": False
    }
    (folder/"qa31l_independent.json").write_text(
        json.dumps(result, sort_keys=True, indent=2) + "\n")
    print("QA31L_SOURCE_ZIP_CRC_AND_TRACE_INTEGRITY_PASS")
    print("QA31L_PHYSICAL_STEPS_VERIFIED", facts["steps"])
    print("QA31L_HOSTILE_MUTATIONS_REJECTED", len(rejected))
    print("QA31L_J_GATES", json.dumps(facts["gates"], sort_keys=True))
    print("QA31L_X_CELL_VISITS", len(facts["x15029_ticks"]))
    print("QA31L_NO_STAGE1_PASS")
    print("QA31L_AUDIT_PASS" if result["bounded_evidence_verified"]
          else "QA31L_ORACLE_COVERAGE_INCOMPLETE")

if __name__ == "__main__":
    need(len(sys.argv) == 3, "usage: audit.py SOURCE OUTPUT_DIR")
    main(sys.argv[1], sys.argv[2])
