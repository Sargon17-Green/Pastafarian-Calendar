#!/usr/bin/env python3
"""QA31F: offline cross-audit of signed QA20 STEP and prior QA30B FungeSpace.put events.

Usage: python qa/stage1_qa31f_qa30b_live_put_lineage.py SHARD0 SHARD1 SHARD2 SHARD3 QA30B_ZIP
SHA-pinned historical artifacts only. No Befunge execution or global reachability proof.
"""
import argparse
import gzip
import hashlib
import json
import pathlib
import zipfile

SHAS = {
    0: "0487e7b6c65134a69d6ac7b313d332e6cb5c966b9fea0124ae60a28d45f11076",
    1: "0d39bebd0e2b28976f77a38f8f1c0113ec8ad5d2de08f53415179277135bf5ea",
    2: "d511c5cbde86b850224851d27ddc994e5689019c0af93aea9d5c5df92f33f16c",
    3: "d792e4ce459769124d9055f47dc2773a44a487f260ff2302ada8371ed4450c07",
}
QA30B_ZIP_SHA = "dd84fea04224066bb60849c3d250df7f3059c630bea9bdf768300a5b7bcb0997"
QA30B_DATA_SHA = "54006c8f886c67967c6f98b618a1ee6f7c87d8cdb4e902fd533e292433cb029d"
QA30B_AUDIT_SHA = "528a415cb1a12c6f2224d27b6858cdf8622d6cca9644b9e7f36234b111442460"
SOURCE_BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"


def need(condition, message):
    if not condition:
        raise AssertionError(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def guard_no_offset_rebase(trace, first_put_tick, before_gate_tick):
    """Conservatively reject offset/stack-stack controls before a signed gate read.

    Ticks are 1-based inclusive for first_put and exclusive for before_gate.
    This is a finite, opcode-only guard, not a global source-ownership proof.
    """
    need(1 <= first_put_tick < before_gate_tick <= len(trace),
         "bad signed put/g tick bounds")
    window = trace[first_put_tick - 1:before_gate_tick - 1]
    need(all(s[0] == first_put_tick + i for i, s in enumerate(window)),
         "nonsequential signed pre-g trace")
    need(not any(s[6] == 0 and s[5] in (ord("{"), ord("}"), ord("u"))
                 for s in window),
         "storage-offset or stack-stack control before gate")


def audit(shards, qa30b_zip):
    by_shard = {}
    for name in shards:
        path = pathlib.Path(name)
        raw = path.read_bytes()
        with zipfile.ZipFile(path) as z:
            need(z.testzip() is None, "QA20 CRC mismatch")
            m = json.loads(z.read("qa20_manifest.json"))
        shard = m["shard"]
        need(shard in SHAS and digest(raw) == SHAS[shard], "QA20 ZIP SHA mismatch")
        need(shard not in by_shard and m["source_git_blob"] == SOURCE_BLOB,
             "QA20 duplicate shard or source mismatch")
        by_shard[shard] = (path, m)
    need(len(by_shard) == 4, "missing QA20 shard")
    path = pathlib.Path(qa30b_zip)
    need(digest(path.read_bytes()) == QA30B_ZIP_SHA, "QA30B ZIP SHA mismatch")
    with zipfile.ZipFile(path) as z:
        need(z.testzip() is None, "QA30B CRC mismatch")
        data = z.read("qa30b_live_source_frontier.json")
        independent = z.read("qa30b_independent_audit.json")
    need(digest(data) == QA30B_DATA_SHA and digest(independent) == QA30B_AUDIT_SHA,
         "QA30B inner JSON SHA mismatch")
    report, review = json.loads(data), json.loads(independent)
    need(report["production_git_blob"] == SOURCE_BLOB
         and report["original_programs_replayed"] == 2
         and report["original_native_steps_replayed"] == 18859
         and report["no_forced_ip_relocation"] and not report["native_program_bytes_modified"]
         and not report["stage1_complete"], "QA30B provenance mismatch")
    need(review["original_steps_replayed"] == 18859
         and review["negative_controls_rejected"] == 41
         and not review["stage1_complete"], "QA30B independent review mismatch")
    need({r["label"] for r in report["records"]} == {"invalid00", "invalid18"},
         "QA30B case selection mismatch")
    observed = {}
    for r in report["records"]:
        label = r["label"]
        path, manifest = by_shard[r["original_shard"]]
        with zipfile.ZipFile(path) as z:
            rec = next(x for x in manifest["records"] if x["label"] == label)
            blob = z.read(rec["path"])
        need(digest(blob) == rec["compressed_trace_sha256"]
             == r["qa20_original_gzip_sha256"], "signed QA20 STEP digest mismatch")
        trace = [tuple(map(int, line.split(b"\t")))
                 for line in gzip.decompress(blob).splitlines()]
        need(len(trace) == rec["steps"] == r["original_signed_steps"],
             "signed QA20 STEP count mismatch")
        puts = r["all_real_native_put_events"]
        expected_ticks = [s[0] for s in trace if s[5] == ord("p") and s[6] == 0]
        need([e["tick"] for e in puts] == expected_ticks
             and len(puts) == r["real_native_put_calls"],
             "not all original physical p instructions have matching put event")
        ownership = {}
        for e in puts:
            tick, coordinate = e["tick"], tuple(e["coordinate"])
            step = trace[tick - 1]
            need(step[0] == tick and step[5] == ord("p") and step[6] == 0,
                 "put event does not match signed Native STEP")
            if coordinate in ownership:
                need(e["before"] == ownership[coordinate], "broken put value chronology")
            ownership[coordinate] = e["after"]
        g = [s[0] for s in trace if s[1:3] == (57, 29) and s[5] == ord("g") and s[6] == 0]
        j = [s[0] for s in trace if s[1:3] == (89, 29) and s[5] == ord("j") and s[6] == 0]
        need(len(g) == len(j) == 1 and g[0] < j[0], "pre-gate physical route mismatch")
        writes = [e for e in puts if e["coordinate"] == [3, 49]]
        need(bool(writes) and (writes[0]["tick"], writes[0]["before"],
                               writes[0]["after"]) == (242, 32, 0),
             "original memory gate initial zero put mismatch")
        guard_no_offset_rebase(trace, writes[0]["tick"], g[0])
        previous = [e for e in writes if e["tick"] < g[0]]
        need(bool(previous) and previous[-1]["after"] == 0
             and not any(g[0] <= e["tick"] < j[0] for e in writes),
             "last pre-gate original memory value is not zero")
        need(trace[j[0]][1:3] == (90, 29), "original j did not follow zero route")
        sequence = [(e["tick"], trace[e["tick"] - 1][1:3],
                     e["before"], e["after"]) for e in writes]
        if label == "invalid00":
            need(len(sequence) == 9
                 and [x[1] for x in sequence] ==
                 [(202, 2), (248, 14), (344, 26), (248, 14), (344, 26),
                  (248, 14), (344, 26), (248, 14), (344, 26)]
                 and [x[3] for x in sequence] == [0, 1, 0, 1, 0, 1, 0, 1, 0]
                 and previous[-1]["tick"] == 9290
                 and j[0] - previous[-1]["tick"] == 172,
                 "invalid00 actual 0/1 dynamic write ancestry mismatch")
        else:
            need(len(sequence) == 1 and sequence[0][1] == (202, 2),
                 "invalid18 startup-only route mismatch")
        observed[label] = {
            "steps": len(trace),
            "recorded_put_events": len(puts),
            "g_57_29_tick": g[0],
            "j_89_29_tick": j[0],
            "physical_writes_to_3_49": sequence,
            "last_recorded_value_before_g": previous[-1]["after"],
        }
    need(sum(x["recorded_put_events"] for x in observed.values()) == 73,
         "QA30B aggregate put count mismatch")
    return {
        "schema": "qa31f-qa30b-pinned-real-put-lineage-v1",
        "source_blob": SOURCE_BLOB,
        "observed_original_native_cases": 2,
        "observed_original_native_steps": 18859,
        "recorded_original_put_events": 73,
        "historical_independent_negative_controls": 41,
        "new_native_executions": 0,
        "finite_lineage": observed,
        "naturally_reached_m1_at_j_proven": False,
        "global_unreachability_proven": False,
        "stage1_complete": False,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shards", nargs=4, help="Four original QA20 ZIPs, any order")
    parser.add_argument("qa30b", help="Prior QA30B original Native artifact ZIP")
    args = parser.parse_args()
    print(json.dumps(audit(args.shards, args.qa30b), indent=2))


if __name__ == "__main__":
    main()
