#!/usr/bin/env python3
"""QA31K: source-pinned last-writer/reader audit of signed QA31G and QA31J Native traces."""
import argparse
import gzip
import hashlib
import io
import json
import zipfile
from pathlib import Path

SOURCE_PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
QA31G_ZIP_SHA = "e74e4ad35d5653ffd1610827e1351fce62552b0912dc78430908cc288f4e1161"
QA31J_ZIP_SHA = "57c185ab238602574d45d1a2e9ba58431e1ae567ec2fcb184baaaa89e5a57a37"
TARGETS = ((0, 49), (1, 49), (3, 49))
QA31G_CASES = {
    "empty": ("", 776, "qa31g_empty.jsonl.gz"),
    "digit": ("31", 2046, "qa31g_digit.jsonl.gz"),
    "digit_space": ("3120", 3038, "qa31g_digit_space.jsonl.gz"),
}
QA31J_CASES = {
    "digit_lf": ("310a", 3038, "qa31g_digit_lf.jsonl.gz"),
    "digit_tab": ("3109", 3038, "qa31g_digit_tab.jsonl.gz"),
}
CONTROL_OPS = {
    "j": ord("j"), "g": ord("g"), "p": ord("p"),
    "{": ord("{"), "}": ord("}"), "u": ord("u"),
    "_": ord("_"), "|": ord("|"), "#": ord("#"),
    "[": ord("["), "]": ord("]"), "w": ord("w"),
    "^": ord("^"), "<": ord("<"), ">": ord(">"), "v": ord("v"),
}


def need(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def git_blob_sha(data):
    header = b"blob " + str(len(data)).encode("ascii") + b"\0"
    return hashlib.sha1(header + data).hexdigest()


def source_cell(rows, x, y):
    if x < 0 or y < 0 or y >= len(rows) or x >= len(rows[y]):
        return 32
    return rows[y][x]


def read_source(path):
    data = Path(path).read_bytes()
    actual = git_blob_sha(data)
    need(actual == SOURCE_PIN, "immutable production source blob mismatch: " + actual)
    rows = data.splitlines()
    need(len(rows) == 2016, "original source line count changed")
    for x, y in TARGETS:
        need(source_cell(rows, x, y) == 32, "target FungeSpace cell is not ASCII space")
    need(len(rows[49]) == 0, "row 49 is no longer an empty source row")
    return rows


def read_zip(path, expected_sha, expected_names, label):
    data = Path(path).read_bytes()
    actual = sha256(data)
    need(actual == expected_sha, label + " ZIP SHA256 mismatch: " + actual)
    with zipfile.ZipFile(io.BytesIO(data), "r") as archive:
        need(archive.testzip() is None, label + " ZIP CRC failure")
        names = set(archive.namelist())
        need(names == expected_names,
             label + " ZIP entry set mismatch: " + repr(sorted(names)))
        contents = {name: archive.read(name) for name in names}
    return contents


def validate_trace(case, raw, rows, label):
    trace_name = case["trace"]
    compressed = case["_zip"][trace_name]
    need(sha256(compressed) == case["trace_sha256"],
         label + " compressed trace digest mismatch")
    lines = gzip.decompress(compressed).splitlines()
    records = [json.loads(line) for line in lines]
    need(len(records) == case["steps"] and len(records) > 0,
         label + " physical STEP count")
    need(case["status"] == "HALT" and case["error"] is None,
         label + " native terminal receipt")
    need(case["output"] == ["-1"] * 7, label + " output receipt")
    need(case["raw_hex"] == raw.hex(), label + " raw stdin hex")
    need(case["raw_sha256"] == sha256(raw), label + " raw stdin digest")
    need(case["reads"] == (1 if len(raw) == 0 else 2),
         label + " stdin read count")

    overlay = {}
    last_writer = {}
    target_events = {coord: [] for coord in TARGETS}
    input_reads = []
    gates = []
    visited = set()

    for index, step in enumerate(records):
        tick = index + 1
        need(step["t"] == tick, label + " non-sequential STEP tick")
        ip = step["ip"]
        delta = step["delta"]
        pre = step["pre"]
        post = step["post"]
        need(type(ip) is list and len(ip) == 2 and
             type(delta) is list and len(delta) == 2 and
             all(type(v) is int for v in ip + delta) and delta != [0, 0],
             label + " invalid IP/delta")
        need(type(pre) is list and type(post) is list and
             all(type(v) is int for v in pre + post),
             label + " invalid physical stack")
        need(step["string"] is False, label + " unexpected string mode")
        x, y = ip
        visited.add((x, y))
        expected_op = overlay.get((x, y), source_cell(rows, x, y))
        need(step["op"] == expected_op,
             label + " source/overlay opcode mismatch at " + repr((x, y)))

        if index:
            previous = records[index - 1]
            need(previous["next"] == ip and previous["next_delta"] == delta,
                 label + " IP continuity failure")

        op = step["op"]
        need(op not in (ord("{"), ord("}"), ord("u"), ord("s")),
             label + " entered an opcode outside this bounded oracle")

        if op == ord("p"):
            need(len(pre) >= 3 and post == pre[:-3],
                 label + " physical p stack semantics")
            coord = (pre[-2], pre[-1])
            value = pre[-3]
            if coord in TARGETS:
                previous_writer = last_writer.get(coord)
                target_events[coord].append({
                    "tick": tick, "kind": "write", "cell": list(coord),
                    "value": value, "ip": ip,
                    "previous_writer_tick": previous_writer["tick"] if previous_writer else None,
                    "previous_writer_value": previous_writer["value"] if previous_writer else source_cell(rows, *coord),
                })
                last_writer[coord] = {
                    "tick": tick, "value": value, "ip": ip,
                }
            overlay[coord] = value

        elif op == ord("g"):
            need(len(pre) >= 2 and len(post) == len(pre) - 1 and
                 post[:-1] == pre[:-2],
                 label + " physical g stack semantics")
            coord = (pre[-2], pre[-1])
            value = overlay.get(coord, source_cell(rows, *coord))
            need(post[-1] == value,
                 label + " g returned a value other than the last physical writer")
            if coord in TARGETS:
                writer = last_writer.get(coord)
                target_events[coord].append({
                    "tick": tick, "kind": "read", "cell": list(coord),
                    "value": value, "ip": ip,
                    "last_writer_tick": writer["tick"] if writer else None,
                    "last_writer_value": writer["value"] if writer else source_cell(rows, *coord),
                    "last_writer_ip": writer["ip"] if writer else None,
                })

        if op == ord("j") and ip in ([89, 29], [113, 32]):
            operand = pre[-1] if pre else 0
            need(post == (pre[:-1] if pre else []),
                 label + " j operand pop")
            expected_next = [
                x + (operand + 1) * delta[0],
                y + (operand + 1) * delta[1],
            ]
            need(step["next"] == expected_next, label + " j successor")
            gates.append({
                "tick": tick, "ip": ip, "operand": operand,
                "next": step["next"],
            })

        events = step.get("reads")
        need(type(events) is list, label + " missing stdin event list")
        for event in events:
            start, end = event["start"], event["end"]
            need(event["t"] == tick and event["ip"] == ip and
                 event["stack"] == pre and
                 event["method"] in ("read", "readline") and
                 type(start) is int and type(end) is int and
                 0 <= start <= end <= len(raw) and
                 event["hex"] == raw[start:end].hex(),
                 label + " stdin event does not match original bytes")
            input_reads.append(event)

    need(len(input_reads) == case["reads"], label + " stdin event tally")
    need(input_reads[0]["ip"] == [13, 5] and
         input_reads[0]["start"] == 0 and
         input_reads[0]["end"] == len(raw) and
         input_reads[0]["hex"] == raw.hex(),
         label + " first natural stdin read")
    for event in input_reads[1:]:
        need(event["start"] == event["end"] == len(raw) and event["hex"] == "",
             label + " later read was not EOF")
    need(records[-1]["next"] is None and records[-1]["op"] == ord("@"),
         label + " HALT opcode/receipt")

    return {
        "records": records,
        "visited": visited,
        "target_events": target_events,
        "gates": gates,
        "input_reads": input_reads,
        "summary": {
            "status": case["status"], "steps": len(records),
            "stdin_reads": len(input_reads), "gates": gates,
            "output": case["output"],
        },
    }


def load_bundle(kind, contents, rows):
    if kind == "QA31G":
        receipt_name = "qa31g_receipt.json"
        independent_name = "qa31g_independent.json"
        expected = QA31G_CASES
        need(set(contents[receipt_name] is not None for _ in [0]),
             "QA31G receipt missing")
    else:
        receipt_name = "qa31j_receipt.json"
        independent_name = "qa31j_independent.json"
        expected = QA31J_CASES

    receipt = json.loads(contents[receipt_name].decode("utf-8"))
    independent = json.loads(contents[independent_name].decode("utf-8"))
    need(receipt["source_blob"] == SOURCE_PIN and
         receipt["source_modified"] is False and
         receipt["ip_relocated"] is False and
         receipt["stage1_pass"] is False,
         kind + " source/scope receipt")
    need(independent["source_blob"] == SOURCE_PIN and
         independent["stage1_pass"] is False,
         kind + " independent receipt scope")

    if kind == "QA31G":
        need(receipt["schema"] == "qa31g-original-native-eof-v1" and
             receipt["native_expected_model_proven"] is False,
             "QA31G schema/model scope")
        need(independent["schema"] == "qa31g-independent-v1" and
             independent["cases_verified"] == 3 and
             independent["forgeries_rejected"] == 5,
             "QA31G independent auditor summary")
    else:
        need(receipt["schema"] == "qa31j-unseen-native-v1" and
             receipt["original_qa31g_cases_rerun"] == 0 and
             receipt["new_native_cases"] == 2,
             "QA31J schema/no-duplicate scope")
        need(independent["schema"] == "qa31j-independent-byte-frontier-v1" and
             independent["native_new_cases"] == 2 and
             independent["physical_steps_checked"] == 6076 and
             len(independent["mutations_rejected"]) == 8 and
             independent["global_owner_proven"] is False,
             "QA31J independent auditor summary")

    case_specs = {case["label"]: case for case in receipt["cases"]}
    need(set(case_specs) == set(expected), kind + " case labels")
    results = {}
    for label, (raw_hex, steps, trace_name) in expected.items():
        case = dict(case_specs[label])
        need(case["trace"] == trace_name and case["steps"] == steps,
             kind + "/" + label + " receipt scope")
        case["_zip"] = contents
        raw = bytes.fromhex(raw_hex)
        results[kind + "/" + label] = validate_trace(
            case, raw, rows, kind + "/" + label
        )
    return results


def pair_comparison(cases):
    a = cases["QA31J/digit_lf"]["records"]
    b = cases["QA31J/digit_tab"]["records"]
    need(len(a) == len(b) == 3038, "QA31J pair length")
    route_equal = all(
        x["ip"] == y["ip"] and x["op"] == y["op"] and x["next"] == y["next"]
        for x, y in zip(a, b)
    )
    need(route_equal, "QA31J pair instruction route diverged")
    state_differences = [
        i for i, (x, y) in enumerate(zip(a, b), 1)
        if x["pre"] != y["pre"] or x["post"] != y["post"]
    ]
    g_differences = [
        {"tick": i, "ip": x["ip"], "lf": x["post"][-1], "tab": y["post"][-1]}
        for i, (x, y) in enumerate(zip(a, b), 1)
        if x["op"] == y["op"] == ord("g") and x["post"][-1] != y["post"][-1]
    ]
    p_differences = [
        {"tick": i, "ip": x["ip"], "lf": x["pre"][-3:], "tab": y["pre"][-3:]}
        for i, (x, y) in enumerate(zip(a, b), 1)
        if x["op"] == y["op"] == ord("p") and x["pre"][-3:] != y["pre"][-3:]
    ]
    need(len(state_differences) == 252, "QA31J physical stack-difference count")
    need(len(g_differences) == 7, "QA31J differing g-read count")
    need(len(p_differences) == 1 and
         p_differences[0]["tick"] == 1179 and
         p_differences[0]["ip"] == [60, 5] and
         p_differences[0]["lf"] == [10, 0, 49] and
         p_differences[0]["tab"] == [9, 0, 49],
         "QA31J input-dependent p writer")
    need(a[-1]["op"] == ord("@") and b[-1]["op"] == ord("@"),
         "QA31J pair terminal opcodes")
    return {
        "route_equal": route_equal,
        "steps_per_case": len(a),
        "state_difference_ticks": state_differences,
        "state_difference_count": len(state_differences),
        "g_read_differences": g_differences,
        "g_read_difference_count": len(g_differences),
        "p_write_differences": p_differences,
        "p_write_difference_count": len(p_differences),
    }


def source_frontier(rows, cases):
    visited = set()
    for result in cases.values():
        visited.update(result["visited"])
    summary = {}
    for label, opcode in CONTROL_OPS.items():
        all_positions = []
        for y, row in enumerate(rows):
            for x, value in enumerate(row):
                if value == opcode:
                    all_positions.append((x, y))
        seen = [coord for coord in all_positions if coord in visited]
        unseen = [coord for coord in all_positions if coord not in visited]
        summary[label] = {
            "source_cells": len(all_positions),
            "visited_by_signed_traces": len(seen),
            "unvisited_by_signed_traces": len(unseen),
            "unvisited_coordinates": [list(c) for c in unseen[:100]],
        }
    cluster = []
    cluster_ops = set(CONTROL_OPS.values())
    for y, row in enumerate(rows):
        if not 1318 <= y <= 1338:
            continue
        for x, value in enumerate(row):
            if 940 <= x <= 970 and value in cluster_ops and (x, y) not in visited:
                cluster.append({
                    "x": x, "y": y, "opcode": chr(value),
                })
    need(summary["j"]["unvisited_coordinates"] == [[958, 1331]],
         "original-source unvisited j frontier changed")
    return {
        "unique_visited_ip_positions": len(visited),
        "opcode_counts": summary,
        "remote_control_cluster_unvisited": cluster,
        "interpretation": (
            "The one unvisited source j cell is (958,1331). The nearby remote "
            "control cluster is not reached by any of these five signed Native traces. "
            "This is a source frontier candidate, not a reachability proof."
        ),
    }


def compact_events(events):
    parts = []
    for event in events:
        cell = tuple(event["cell"])
        if event["kind"] == "write":
            parts.append(
                "W{}={}@{};".format(event["tick"], event["value"], tuple(event["ip"]))
            )
        else:
            parts.append(
                "R{}={}@{}<-W{};".format(
                    event["tick"], event["value"], tuple(event["ip"]),
                    event["last_writer_tick"]
                )
            )
    return " ".join(parts) if parts else "—"


def make_markdown(report):
    lines = [
        "# QA31K — signed last-writer/reader ownership audit",
        "",
        "PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ",
        "Branch: qa-befunge98-stage1-order-isolation-20261008",
        "Source blob: " + SOURCE_PIN,
        "",
        "## Exact inputs and artifact provenance",
        "",
        "| Bundle | SHA-256 | Cases | Physical STEPs |",
        "|---|---|---:|---:|",
        "| QA31G | " + QA31G_ZIP_SHA + " | 3 | 5,860 |",
        "| QA31J | " + QA31J_ZIP_SHA + " | 2 | 6,076 |",
        "",
        "Both ZIP CRCs, all five compressed trace digests, source pin, per-STEP "
        "source/overlay opcode, IP continuity, p/g stack semantics, exact stdin "
        "read slices and HALT receipts were independently checked.",
        "",
        "## QA31J paired Native comparison",
        "",
        "- All 3,038 IP positions, opcode bytes and next-IP positions agree.",
        "- " + str(report["qa31j_pair"]["state_difference_count"]) +
        " STEP records have different physical pre/post stacks.",
        "- " + str(report["qa31j_pair"]["g_read_difference_count"]) +
        " g reads differ; " + str(report["qa31j_pair"]["p_write_difference_count"]) +
        " p write differs.",
        "- The differing p is tick 1179 at (60,5): LF writes 10 to (0,49), "
        "TAB writes 9 to (0,49).",
        "",
        "## Target-cell last-writer/reader histories",
        "",
    ]
    for cell in ("(0, 49)", "(1, 49)", "(3, 49)"):
        lines.extend(["### " + cell, ""])
        for case_key, result in report["_case_results"].items():
            events = result["target_events"][tuple(map(int, cell.strip("()").split(",")))]
            if events:
                lines.append("- **" + case_key + ":** " + compact_events(events))
        lines.append("")
    lines.extend([
        "## Historical control gates",
        "",
    ])
    for case_key, result in report["_case_results"].items():
        if result["gates"]:
            gate_text = ", ".join(
                "j{} tick {} operand {} -> {}".format(
                    tuple(g["ip"]), g["tick"], g["operand"], g["next"]
                )
                for g in result["gates"]
            )
            lines.append("- **" + case_key + ":** " + gate_text)
    lines.extend([
        "",
        "## Original-source control frontier",
        "",
        "- Unique IP positions seen across the five signed traces: " +
        str(report["source_frontier"]["unique_visited_ip_positions"]) + ".",
        "- Source j instructions: " +
        str(report["source_frontier"]["opcode_counts"]["j"]["visited_by_signed_traces"]) +
        " visited; " +
        str(report["source_frontier"]["opcode_counts"]["j"]["unvisited_by_signed_traces"]) +
        " unvisited, at (958,1331).",
        "- Source g instructions: " +
        str(report["source_frontier"]["opcode_counts"]["g"]["visited_by_signed_traces"]) +
        " visited; " +
        str(report["source_frontier"]["opcode_counts"]["g"]["unvisited_by_signed_traces"]) +
        " unvisited.",
        "- Source p instructions: " +
        str(report["source_frontier"]["opcode_counts"]["p"]["visited_by_signed_traces"]) +
        " visited; " +
        str(report["source_frontier"]["opcode_counts"]["p"]["unvisited_by_signed_traces"]) +
        " unvisited.",
        "- Remote unvisited control cells near x=940..970, y=1318..1338: " +
        ", ".join(
            "({},{}):{}".format(c["x"], c["y"], c["opcode"])
            for c in report["source_frontier"]["remote_control_cluster_unvisited"]
        ) + ".",
        "",
        "These coordinates are not shown reachable. The new inputs change a data "
        "value read from (0,49), but do not change the observed control route.",
        "",
        "## Scope and verdict",
        "",
        "- QA31G and QA31J Native executions were not repeated; their signed artifacts "
        "were re-audited offline.",
        "- Production source and instruction pointer were not modified.",
        "- Global source ownership, FULL_FUNCTIONAL_QA_PASS, "
        "GEOMETRIC_SPAGHETTI_QA_PASS and Stage 1 acceptance remain unproven.",
        "- No Stage 2, main, merge or publication action was taken.",
        "",
        "QA31K_AUDIT_PASS = bounded last-writer/reader audit only; NOT Stage 1 PASS.",
        "",
    ])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("qa31g_zip")
    parser.add_argument("qa31j_zip")
    parser.add_argument("--output-dir", default="qa31k-output")
    args = parser.parse_args()

    rows = read_source(args.source)
    qa31g_names = {
        "audit.log", "native.log", "qa31g_digit.jsonl.gz",
        "qa31g_digit_space.jsonl.gz", "qa31g_empty.jsonl.gz",
        "qa31g_receipt.json", "qa31g_independent.json",
    }
    qa31j_names = {
        "audit.log", "native.log", "qa31g_digit_lf.jsonl.gz",
        "qa31g_digit_tab.jsonl.gz", "qa31j_independent.json",
        "qa31j_receipt.json",
    }
    qa31g = read_zip(args.qa31g_zip, QA31G_ZIP_SHA, qa31g_names, "QA31G")
    qa31j = read_zip(args.qa31j_zip, QA31J_ZIP_SHA, qa31j_names, "QA31J")
    cases = {}
    cases.update(load_bundle("QA31G", qa31g, rows))
    cases.update(load_bundle("QA31J", qa31j, rows))
    pair = pair_comparison(cases)
    frontier = source_frontier(rows, cases)

    target_report = {}
    for coord in TARGETS:
        key = "({}, {})".format(coord[0], coord[1])
        target_report[key] = {
            "source_initial_value": source_cell(rows, *coord),
            "per_case": {
                case_key: result["target_events"][coord]
                for case_key, result in cases.items()
                if result["target_events"][coord]
            },
        }

    summaries = {case_key: result["summary"] for case_key, result in cases.items()}
    report = {
        "schema": "qa31k-last-writer-reader-v1",
        "source_blob": SOURCE_PIN,
        "artifact_sha256": {"QA31G": QA31G_ZIP_SHA, "QA31J": QA31J_ZIP_SHA},
        "artifact_crc": {"QA31G": "PASS", "QA31J": "PASS"},
        "cases": summaries,
        "target_cells": target_report,
        "qa31j_pair": pair,
        "source_frontier": frontier,
        "global_owner_proven": False,
        "full_functional_qa_pass": False,
        "geometric_spaghetti_qa_pass": False,
        "stage1_pass": False,
        "_case_results": cases,
    }
    markdown = make_markdown(report)
    report.pop("_case_results")
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "qa31k_report.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (output_dir / "QA31K_LAST_WRITER_READER_OWNERSHIP_2026-10-31.md").write_text(
        markdown, encoding="utf-8"
    )
    log = [
        "QA31K_SOURCE_PIN_PASS " + SOURCE_PIN,
        "QA31K_ARTIFACT_SHA_CRC_PASS 2/2",
        "QA31K_SIGNED_CASES_PASS 5",
        "QA31K_PHYSICAL_STEPS_PASS 11936",
        "QA31K_TARGET_CELLS_PASS 3",
        "QA31K_QA31J_ROUTE_EQUAL 3038/3038",
        "QA31K_QA31J_STACK_DIFFERENCES 252",
        "QA31K_QA31J_G_READ_DIFFERENCES 7",
        "QA31K_QA31J_P_WRITE_DIFFERENCES 1",
        "QA31K_UNVISITED_SOURCE_J 1 at (958,1331)",
        "QA31K_NO_STAGE1_PASS",
        "QA31K_AUDIT_PASS",
    ]
    (output_dir / "audit.log").write_text("\n".join(log) + "\n", encoding="utf-8")
    print("\n".join(log))


if __name__ == "__main__":
    main()
