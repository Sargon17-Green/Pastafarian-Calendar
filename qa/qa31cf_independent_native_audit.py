#!/usr/bin/env python3
"""QA31CF independent audit: one new original Native trace and strict causal witness."""
import argparse
import copy
import gzip
import hashlib
import json
import shutil
from pathlib import Path

PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
CAP = 50000
OWNER = [19, 1696]
CODE = [1500, 1860]
STATUSES = {"HALT", "STEP_LIMIT", "MULTI_IP", "RUNTIME_ERROR"}


def need(ok, message):
    if not ok:
        raise AssertionError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def verify_source_and_metadata(source, metadata):
    rows = source.splitlines()
    need(git_blob(source) == PIN, "immutable production Git blob")
    need(len(rows) == 2015 and rows[49] == b"", "original source row geometry")
    need(rows[1696] == b"", "owner cell source row must be empty")
    need(len(rows[1860]) == 1531 and rows[1860][1500:1501] == b" "
         and rows[1860][1501:1502] == b">", "dynamic code-cell source bytes")
    owner = metadata.get("cells", {}).get("input_owner", {})
    code = metadata.get("cells", {}).get("dynamic_code_cell", {})
    need(metadata.get("schema") == "qa31cb-source-cell-metadata-v1"
         and metadata.get("project_id") == PROJECT
         and metadata.get("source_git_blob_sha1") == PIN
         and metadata.get("source_line_count_splitlines") == 2015,
         "source-cell metadata provenance")
    need(owner == {
        "coordinate": OWNER, "source_row_length": 0, "source_row_empty": True,
        "source_cell_present_in_source": False, "source_char": None,
        "source_codepoint": None, "initial_funge_space_value": 32
    }, "input-owner source-cell metadata")
    need(code == {
        "coordinate": CODE, "source_row_length": 1531,
        "source_cell_present_in_source": True, "source_char": " ",
        "source_codepoint": 32, "initial_funge_space_value": 32,
        "next_cell_coordinate": [1501, 1860],
        "next_cell_source_char": ">", "next_cell_source_codepoint": 62
    }, "dynamic-code source-cell metadata")
    need(metadata.get("candidate_relation") == "code_value = 56 * g_value + 62"
         and metadata.get("stage1_accepted") is False,
         "source-cell metadata scope")


def int_pair(value):
    return (type(value) is list and len(value) == 2
            and all(type(x) is int for x in value))


def validate_case(receipt, rows, raw, trace_bytes):
    label = "candidate_%03d" % int(receipt.get("input_token", -1))
    token = int(receipt.get("input_token", -1))
    need(token == 100, "input token bounds")
    need(receipt.get("schema") == "qa31cf-natural-input-case-v1"
         and receipt.get("project_id") == PROJECT
         and receipt.get("qa") == "QA31CF"
         and receipt.get("label") == label,
         "case identity/schema")
    need(receipt.get("raw_hex") == raw.hex()
         and receipt.get("raw_sha256") == sha(raw),
         "exact ordinary stdin bytes")
    need(receipt.get("source_git_blob_sha1") == PIN
         and receipt.get("source_modified") is False
         and receipt.get("ip_relocated") is False
         and receipt.get("native_execution_observed") is True,
         "Native/source/no-intervention provenance")
    need(receipt.get("trace_file") == label + ".jsonl.gz"
         and receipt.get("trace_sha256") == sha(trace_bytes),
         "compressed physical trace identity/hash")
    need(type(receipt.get("steps")) is int and 0 < receipt["steps"] <= CAP
         and len(rows) == receipt["steps"],
         "physical STEP count/bound")
    need(receipt.get("status") in STATUSES, "explicit Native termination status")
    need(receipt.get("stage1_accepted") is False
         and receipt.get("global_reachability_proven") is False,
         "Stage1/global-scope flags must remain false")
    need(type(receipt.get("error")) in (str, type(None)), "error field type")
    if receipt["status"] == "HALT":
        need(receipt.get("error") is None and rows[-1].get("next") is None,
             "HALT must have no active next IP")
    elif receipt["status"] == "STEP_LIMIT":
        need(receipt["steps"] == CAP, "step-limit count must equal cap")
    else:
        need(bool(receipt.get("error")), "non-HALT status must carry its reason")

    read_events = []
    stdout_bytes = bytearray()
    owner_events = []
    code_events = []
    fetches = []
    cursor = 0

    for index, row in enumerate(rows, 1):
        need(type(row) is dict and row.get("t") == index,
             "STEP tick continuity at %d" % index)
        need(int_pair(row.get("ip")) and int_pair(row.get("delta"))
             and type(row.get("op")) is int
             and type(row.get("string")) is bool,
             "STEP instruction identity at %d" % index)
        need(type(row.get("pre")) is list and type(row.get("post")) is list
             and all(type(v) is int for v in row["pre"] + row["post"]),
             "STEP TOSS shape at %d" % index)
        need(int_pair(row.get("storage_offset")), "STEP storage offset at %d" % index)
        need(type(row.get("reads")) is list, "STEP reads shape at %d" % index)
        try:
            stdout_delta = bytes.fromhex(row.get("stdout_delta_hex", ""))
        except (TypeError, ValueError):
            raise AssertionError("invalid stdout delta hex at %d" % index)
        stdout_bytes.extend(stdout_delta)

        op = row["op"]
        pre = row["pre"]
        post = row["post"]
        so = row["storage_offset"]
        string_mode = row["string"]
        expected_pg = (not string_mode and op in (ord("p"), ord("g")))
        pg = row.get("pg")
        if expected_pg:
            need(type(pg) is dict, "missing p/g physical receipt at %d" % index)
            arity = 3 if op == ord("p") else 2
            need(pg.get("tick") == index and pg.get("op") == op
                 and pg.get("ip") == row["ip"]
                 and pg.get("storage_offset") == so
                 and pg.get("pre_toss") == pre,
                 "p/g receipt identity at %d" % index)
            if len(pre) >= arity:
                target = [pre[-2] + so[0], pre[-1] + so[1]]
                need(pg.get("target") == target
                     and type(pg.get("cell_before")) is int
                     and type(pg.get("cell_after")) is int,
                     "p/g physical target/cell types at %d" % index)
                if op == ord("p"):
                    need(pg["cell_after"] == pre[-3] and post == pre[:-3],
                         "p physical write/pop semantics at %d" % index)
                else:
                    need(pg["cell_after"] == pg["cell_before"]
                         and pg.get("result") == pg["cell_before"]
                         and post == pre[:-2] + [pg["cell_before"]],
                         "g physical read/push semantics at %d" % index)
                if target == OWNER:
                    owner_events.append(pg)
                if target == CODE:
                    code_events.append(pg)
            else:
                need(pg.get("target") is None
                     and pg.get("cell_before") is None
                     and pg.get("cell_after") is None,
                     "underflow p/g must not claim a physical target")
        else:
            need(pg is None, "unexpected p/g receipt at %d" % index)

        expected_fetch = (not string_mode and row["ip"] == CODE)
        fetch = row.get("fetch")
        if expected_fetch:
            need(type(fetch) is dict and fetch.get("tick") == index
                 and fetch.get("ip") == CODE and fetch.get("op") == op
                 and fetch.get("cell_observed") == op,
                 "dynamic-cell instruction fetch receipt at %d" % index)
            fetches.append(fetch)
        else:
            need(fetch is None, "unexpected dynamic-cell fetch at %d" % index)

        for event in row["reads"]:
            need(type(event) is dict and event.get("t") == index
                 and event.get("ip") == row["ip"]
                 and event.get("method") in ("read", "readline")
                 and type(event.get("start")) is int
                 and type(event.get("end")) is int
                 and type(event.get("stack")) is list
                 and all(type(v) is int for v in event["stack"]),
                 "stdin read-event schema at %d" % index)
            try:
                chunk = bytes.fromhex(event.get("hex", ""))
            except (TypeError, ValueError):
                raise AssertionError("stdin read-event hex at %d" % index)
            start, end = event["start"], event["end"]
            need(start == cursor and end == start + len(chunk)
                 and 0 <= start <= end <= len(raw)
                 and raw[start:end] == chunk,
                 "stdin bytes/offset continuity at %d" % index)
            cursor = end
            read_events.append(event)

        if index < len(rows):
            need(row.get("next") == rows[index].get("ip")
                 and row.get("next_delta") == rows[index].get("delta"),
                 "single-IP physical successor mismatch at %d" % index)

    need(receipt.get("read_events") == read_events,
         "receipt stdin events do not match physical STEP trace")
    need(receipt.get("stdout_hex") == bytes(stdout_bytes).hex(),
         "receipt stdout bytes do not match per-STEP output")
    need(receipt.get("owner_pg_events") == owner_events
         and receipt.get("code_pg_events") == code_events
         and receipt.get("target_fetches") == fetches,
         "targeted p/g/fetch summaries do not match full trace")

    owner_g = [e for e in owner_events if e["op"] == ord("g")
               and e.get("cell_before") is not None]
    code_writes = [e for e in code_events if e["op"] == ord("p")
                   and e.get("target") == CODE]
    formula_checks = []
    for write in code_writes:
        earlier = [g for g in owner_g if g["tick"] < write["tick"]]
        if earlier:
            g = earlier[-1]
            value = write["pre_toss"][-3]
            expected = 56 * g["cell_before"] + 62
            formula_checks.append({
                "g_tick": g["tick"], "g_value": g["cell_before"],
                "p_tick": write["tick"], "code_value": value,
                "expected_code_value": expected, "match": value == expected
            })

    # Strict causal witness: do not infer any step from the prior 900 traces.
    # All IPs, TOSS states, storage offsets, writer order and fetched bytes
    # below come exclusively from this new candidate's physical Native trace.
    physical_by_tick = {row["t"]: row for row in rows}
    def match_pg(ip, opcode, target, value=None):
        return [row["pg"] for row in rows
                if row["ip"] == ip and row["op"] == ord(opcode)
                and not row["string"] and row["pg"] is not None
                and row["pg"]["target"] == target
                and (value is None or
                     (row["pg"]["cell_after"] if opcode == "p"
                      else row["pg"]["result"]) == value)]
    source_puts = match_pg([860, 846], "p", [5, 1691], 2)
    source_gets = match_pg([100, 1057], "g", [5, 1691], 2)
    owner_puts = match_pg([1332, 480], "p", OWNER)
    matched_owner_reads = match_pg([677, 765], "g", OWNER)
    code_puts = match_pg([96, 480], "p", CODE)
    parsed = [r for r in rows if r["ip"] == [4, 0] and
              r["op"] == 62 and r["pre"] == [1, 2, 0, token]]
    gate_valid = False
    source_chain = False
    witness_chain = None
    for src_p in source_puts:
        if not parsed or not any(r["t"] < src_p["tick"] for r in parsed):
            continue
        for src_g in source_gets:
            if src_g["tick"] <= src_p["tick"] or src_g["cell_before"] != 2:
                continue
            base = physical_by_tick[src_g["tick"]]
            stack = list(base["post"])
            if len(stack) < 3:
                continue
            a, u, b = stack[-3:]
            if (a, u, b) != (1, 1, 2):
                continue
            opcodes = ("!", "*", "!", "*")
            expected_stacks = ([a, u, int(b == 0)],
                               [a, u * int(b == 0)],
                               [a, int(u * int(b == 0) == 0)],
                               [a * int(u * int(b == 0) == 0)])
            matched = True
            for offset, (opcode, exp) in enumerate(zip(opcodes, expected_stacks), 1):
                tick = src_g["tick"] + offset
                r = physical_by_tick.get(tick)
                if not (r and r["ip"] == [100, 1057 + offset]
                        and r["op"] == ord(opcode) and not r["string"]
                        and r["post"] == exp):
                    matched = False
                    break
            if not matched:
                continue
            gate_valid = True
            for op in owner_puts:
                if (op["tick"] <= src_g["tick"] + 4 or
                        op["cell_after"] != expected_stacks[-1][-1]):
                    continue
                source_chain = True
                for g in matched_owner_reads:
                    if (g["tick"] <= op["tick"] or g["result"] == 0
                            or g["cell_before"] != op["cell_after"]):
                        continue
                    for put in code_puts:
                        if (put["tick"] <= g["tick"] or
                                put["cell_after"] != 56 * g["result"] + 62):
                            continue
                        for fetch in fetches:
                            if (fetch["tick"] <= put["tick"] or
                                    fetch["op"] != put["cell_after"]):
                                continue
                            preceding = [p for p in code_events
                                         if p["op"] == ord("p")
                                         and put["tick"] < p["tick"] < fetch["tick"]]
                            if preceding:
                                continue
                            witness_chain = {
                                "source_put_tick": src_p["tick"],
                                "source_get_tick": src_g["tick"],
                                "owner_put_tick": op["tick"],
                                "owner_get_tick": g["tick"],
                                "owner_value": g["result"],
                                "code_put_tick": put["tick"],
                                "code_byte": put["cell_after"],
                                "opcode_fetch_tick": fetch["tick"]
                            }
                            break
                        if witness_chain:
                            break
                    if witness_chain:
                        break
                if witness_chain:
                    break
            if witness_chain:
                break
        if witness_chain:
            break
    positive = witness_chain is not None
    negative = False
    for g in owner_g:
        for write in code_writes:
            if write["tick"] <= g["tick"] or len(write["pre_toss"]) < 3:
                continue
            value = write["pre_toss"][-3]
            if (g["cell_before"] == 0 and value == 62 and
                    any(f["tick"] > write["tick"] and f["op"] == 62
                        for f in fetches)):
                negative = True
    if receipt["status"] != "HALT":
        classification = receipt["status"]
    elif positive:
        classification = "BOUNDED_NATURAL_WITNESS"
    elif not source_chain and not gate_valid:
        classification = "EARLY_DIVERGENCE_OR_REJECTION"
    elif not positive and any(g["result"] != 0 for g in matched_owner_reads):
        classification = "NONZERO_OWNER_INCOMPLETE_CODE_FETCH"
    elif negative:
        classification = "FINITE_NEGATIVE_FOR_INPUT"
    else:
        classification = "PARTIAL_OR_DIFFERENT_ROUTE"

    anomaly = (receipt["status"] != "HALT"
               or any(not x["match"] for x in formula_checks))
    return {
        "label": label, "input_token": token, "status": receipt["status"],
        "steps": receipt["steps"], "stdin_reads": len(read_events),
        "stdout_hex": receipt["stdout_hex"],
        "owner_pg_events": len(owner_events),
        "owner_g_reads": len(owner_g), "code_pg_events": len(code_events),
        "code_writes": len(code_writes), "target_fetches": len(fetches),
        "owner_g_values": [e["cell_before"] for e in owner_g],
        "code_values": [e["pre_toss"][-3] for e in code_writes],
        "fetch_opcodes": [e["op"] for e in fetches],
        "formula_checks": formula_checks,
        "classification": classification, "anomaly": anomaly,
        "witness_chain": witness_chain, "gate_valid": gate_valid,
        "second_operand_write_observed": bool(source_puts),
        "second_operand_read_observed": bool(source_gets)
    }



def preserve_frozen_trace(source_path, destination, trace_bytes):
    """Keep Docker-produced boundary evidence without overwriting read-only files."""
    need(not destination.is_symlink(), "archived trace must not be a symlink")
    expected = sha(trace_bytes)
    if destination.exists():
        need(destination.is_file(), "existing archive must be a regular file")
        need(sha(destination.read_bytes()) == expected,
             "existing archived trace differs from audited Native trace")
        return "VERIFIED_EXISTING"
    shutil.copyfile(source_path, destination)
    need(destination.is_file() and not destination.is_symlink()
         and sha(destination.read_bytes()) == expected,
         "new archived trace differs from audited Native trace")
    return "COPIED"


def archive_self_test():
    """Pre-Native regression: new file, read-only duplicate, tamper and symlink."""
    import tempfile
    with tempfile.TemporaryDirectory(prefix="qa31cf-archive-") as root:
        tmp = Path(root)
        source = tmp / "source.gz"
        target = tmp / "target.gz"
        frozen = b"qa31cf-original-native-evidence"
        source.write_bytes(frozen)
        need(preserve_frozen_trace(source, target, frozen) == "COPIED",
             "fresh archive self-test")
        target.chmod(0o444)
        need(preserve_frozen_trace(source, target, frozen) == "VERIFIED_EXISTING",
             "read-only archive self-test")
        target.chmod(0o644)
        target.write_bytes(b"tampered")
        try:
            preserve_frozen_trace(source, target, frozen)
        except AssertionError:
            pass
        else:
            raise AssertionError("tampered frozen trace accepted")
        target.unlink()
        target.symlink_to(source)
        try:
            preserve_frozen_trace(source, target, frozen)
        except AssertionError:
            pass
        else:
            raise AssertionError("symlink frozen trace accepted")
    print("QA31CF_ARCHIVE_PREFLIGHT_PASS new=1 readonly-existing=1 tamper-reject=1 symlink-reject=1")


def hostile_controls(receipt, rows, raw, trace_bytes):
    attacks = [
        ("project_id", lambda r, rs: r.update(project_id="OTHER")),
        ("raw_hex", lambda r, rs: r.update(raw_hex="00")),
        ("raw_sha256", lambda r, rs: r.update(raw_sha256="0" * 64)),
        ("source_git_blob_sha1", lambda r, rs: r.update(source_git_blob_sha1="0" * 40)),
        ("source_modified", lambda r, rs: r.update(source_modified=True)),
        ("ip_relocated", lambda r, rs: r.update(ip_relocated=True)),
        ("native_execution_observed", lambda r, rs: r.update(native_execution_observed=False)),
        ("trace_file", lambda r, rs: r.update(trace_file="../escape.gz")),
        ("trace_sha256", lambda r, rs: r.update(trace_sha256="0" * 64)),
        ("steps", lambda r, rs: r.update(steps=r["steps"] + 1)),
        ("status", lambda r, rs: r.update(status="UNRECOGNIZED")),
        ("read_events", lambda r, rs: r.update(read_events=[{"forged": True}])),
        ("stdout_hex", lambda r, rs: r.update(stdout_hex="zz")),
        ("owner_pg_events", lambda r, rs: r.update(owner_pg_events=[{"forged": True}])),
        ("code_pg_events", lambda r, rs: r.update(code_pg_events=[{"forged": True}])),
        ("target_fetches", lambda r, rs: r.update(target_fetches=[{"forged": True}])),
        ("stage1_accepted", lambda r, rs: r.update(stage1_accepted=True)),
        ("global_reachability_proven", lambda r, rs: r.update(global_reachability_proven=True)),
        ("step_tick", lambda r, rs: rs[0].update(t=0)),
        ("storage_offset", lambda r, rs: rs[0].update(storage_offset=["bad", 0]))
    ]
    results = []
    for name, mutate in attacks:
        forged_receipt = copy.deepcopy(receipt)
        forged_rows = list(rows)
        forged_rows[0] = copy.deepcopy(rows[0])
        mutate(forged_receipt, forged_rows)
        rejected = False
        try:
            validate_case(forged_receipt, forged_rows, raw, trace_bytes)
        except (AssertionError, KeyError, TypeError, ValueError):
            rejected = True
        need(rejected, "independent validator admitted detached hostile: " + name)
        results.append({"mutation": name, "rejected": True})
    need(len(results) == 20, "hostile mutation count")
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--traces", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--metadata", type=Path, required=True)
    args = parser.parse_args()

    source = args.source.read_bytes()
    metadata = json.loads(args.metadata.read_bytes())
    verify_source_and_metadata(source, metadata)
    args.out.mkdir(parents=True, exist_ok=True)

    cases_path = args.out / "qa31cf_cases.jsonl"
    need(cases_path.is_file(), "Native runner receipts are missing")
    receipts = [json.loads(line) for line in cases_path.read_text().splitlines() if line.strip()]
    need(len(receipts) == 1, "exactly one new candidate receipt required")

    counts = {}
    positive_cases = []
    negative_cases = []
    route_divergence = []
    anomalies = []
    total_steps = 0
    total_reads = 0
    total_owner = 0
    total_code = 0
    total_fetches = 0
    best_hostile = None

    audit_path = args.out / "qa31cf_case_audit.jsonl"
    with audit_path.open("w", encoding="utf-8") as audit_file:
        for offset, receipt in enumerate(receipts):
            token = (100,)[offset]
            raw = ("1 2 0 %03d" % token).encode("ascii")
            need(receipt.get("input_token") == token
                 and receipt.get("label") == "candidate_%03d" % token,
                 "one-input candidate identity/coverage")
            trace_name = receipt.get("trace_file")
            need(type(trace_name) is str and Path(trace_name).name == trace_name,
                 "trace path must be a basename")
            trace_path = args.traces / trace_name
            trace_bytes = trace_path.read_bytes()
            need(receipt.get("trace_sha256") == sha(trace_bytes),
                 "trace SHA-256 mismatch for " + trace_name)
            rows = [json.loads(line) for line in gzip.decompress(trace_bytes).splitlines()]
            summary = validate_case(receipt, rows, raw, trace_bytes)
            audit_file.write(json.dumps(summary, sort_keys=True) + "\n")
            counts[summary["classification"]] = counts.get(summary["classification"], 0) + 1
            total_steps += summary["steps"]
            total_reads += summary["stdin_reads"]
            total_owner += summary["owner_pg_events"]
            total_code += summary["code_pg_events"]
            total_fetches += summary["target_fetches"]

            if summary["classification"] == "BOUNDED_NATURAL_WITNESS":
                positive_cases.append(summary["label"])
            elif summary["classification"] == "FINITE_NEGATIVE_FOR_INPUT":
                negative_cases.append(summary["label"])
            elif summary["classification"] == "EARLY_DIVERGENCE_OR_REJECTION":
                route_divergence.append(summary["label"])
            if summary["anomaly"]:
                anomalies.append(summary["label"])
            if True:  # Retain the complete original-source physical trace
                preserve_frozen_trace(trace_path, args.out / trace_name, trace_bytes)

            if best_hostile is None or len(rows) < best_hostile[1]:
                best_hostile = (receipt, len(rows), rows, raw, trace_bytes)

    need(best_hostile is not None, "no Native trace available for hostile controls")
    base_receipt, _, base_rows, base_raw, base_trace = best_hostile
    hostile = hostile_controls(base_receipt, base_rows, base_raw, base_trace)
    hostile_path = args.out / "qa31cf_hostile_results.jsonl"
    hostile_path.write_text("".join(json.dumps(x, sort_keys=True) + "\n" for x in hostile),
                            encoding="utf-8")

    report = {
        "schema": "qa31cf-independent-native-audit-v1",
        "project_id": PROJECT, "qa": "QA31CF",
        "source_git_blob_sha1": PIN,
        "source_cell_metadata_verified": True,
        "original_source_native_cases": 1,
        "new_candidate_inputs": ["1 2 0 100"],
        "expected_cases": 1, "cases": 1,
        "trace_sha256_verified_cases": 1,
        "physical_step_records_verified": total_steps,
        "stdin_read_events_verified": total_reads,
        "owner_cell_pg_events_verified": total_owner,
        "code_cell_pg_events_verified": total_code,
        "dynamic_code_cell_fetches_verified": total_fetches,
        "classification_counts": counts,
        "natural_reachability_cases": positive_cases,
        "finite_negative_cases": negative_cases,
        "route_divergence_cases": route_divergence,
        "anomaly_cases": anomalies,
        "hostile_mutations_rejected": len(hostile),
        "evidence_integrity": "PASS",
        "global_reachability_proven": False,
        "stage1_accepted": False
    }
    (args.out / "qa31cf_audit.json").write_text(
        json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    main()
