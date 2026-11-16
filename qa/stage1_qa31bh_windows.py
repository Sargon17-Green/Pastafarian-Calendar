"""QA31BH. Audit archived PyFunge STEPs without invoking the interpreter."""
import argparse
import gzip
import hashlib
import io
import json
import zipfile
import base64
import csv
import zlib
from collections import Counter
from stage1_qa31bh_lineage import analyze, negative_controls
from pathlib import Path

SOURCE = "560d6aa5807a7f766213a33835cce85eab0fa40c"
AI = "9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49"
BC = "2e4c4809c73438359900e3f54bc616c21282fed83a4784228965da2b8b3b3a77"
SHARDS = (
    (13257568625, "5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553"),
    (13257143122, "375cdf0e4fd88edbadd096fc7876d5fecde3e08364903222b2f85924d0803c2f"),
    (13255923675, "9e71ecd677e9a16f748836ebf567413f27802554ed86d80c9c11376ab3ab396a"),
    (13257900770, "19196d6b0a0e37e6ce0703baff330e1d4a004669862d48be3adb6a19a1828458"),
    (13258005544, "83de475f9fc295d16c353e92e8c3a565686f53ecb936bc3666af59a7752f7f45"),
    (13256499233, "180d394a9aacf11d1b9a381f7997e252ee6dc1e6c772823d2f1698f9085186d0"),
    (13256873940, "1eda4ea3bfcb6f305499444752b4c269318ac40cf17f09fce979d3e7e8b30f14"),
    (13257484076, "b54d244fcd45d38a4c7f8c99a490d32bfe55ff17de43b33a8239ec5fbf1dfa38"),
)
TARGET = [43, 1702]
SELECTOR = [1500, 1750]
FIRST_X = [1500, 1778]
LANDING = [575, 195]
SECOND_X = [540, 195]
START = [575, 670]
BOUNDARY = 1024
LIMIT = 1536


def check(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def source_cell(rows, address):
    x, y = address
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x]
    return 32


def executed(event, char):
    return not event["string"] and event["op"] == ord(char)


def event_pointer(event):
    return [event["t"], event["ip"], event["pre"][-3]]


def verify_chain(events, source):
    written = {}
    writers = {}
    owners = {}
    previous = None
    for tick, ev in enumerate(events, 1):
        check(ev["t"] == tick and not ev.get("error"), f"physical tick {tick}")
        if previous is not None:
            check((previous["next"], previous["next_delta"], previous["post"]) ==
                  (ev["ip"], ev["delta"], ev["pre"]), f"physical continuity {tick}")
        ip = tuple(ev["ip"])
        cell = written.get(ip, source_cell(source, ip))
        check(ev["op"] == cell, f"original source/overlay opcode {tick}")
        pre, post = ev["pre"], ev["post"]
        if executed(ev, "p"):
            check(len(pre) >= 3 and post == pre[:-3], f"physical p stack {tick}")
            address = tuple(pre[-2:])
            owners[tick] = writers.get(address)
            writers[address] = event_pointer(ev)
            written[address] = pre[-3]
        elif executed(ev, "g"):
            check(len(pre) >= 2, f"physical g args {tick}")
            address = tuple(pre[-2:])
            owners[tick] = writers.get(address)
            value = written.get(address, source_cell(source, address))
            check(post == pre[:-2] + [value], f"physical g memory {tick}")
        previous = ev
    check(previous is not None and previous["next"] is None and
          previous["next_delta"] is None, "signed final HALT")
    return owners


def forward_keys(events):
    starts = []
    for index, selector in enumerate(events):
        if selector["ip"] != SELECTOR or not executed(selector, "v"):
            continue
        check(index >= 20, "selector write before trace start")
        writer = events[index-20]
        check(executed(writer, "p") and writer["ip"] == [1335, 1354] and
              writer["pre"][-3:] == [118, *SELECTOR], "signed selector writer")
        k = index + 28
        first = events[k]
        check(executed(first, "x") and first["ip"] == FIRST_X and
              first["next"] == LANDING, "QA31BC first x")
        last = k + 36
        for distance, ev in enumerate(events[k+1:last+1]):
            check(ev["ip"] == [575-distance, 195], "QA31BD leftward corridor")
        check(last < len(events) and executed(events[last], "x") and
              events[last]["ip"] == SECOND_X and events[last]["next"] == START,
              "QA31BD second x")
        starts.append((index, last))
    return starts


def reverse_keys(events):
    result = []
    for k in range(len(events)-1, -1, -1):
        second = events[k]
        if second["string"] or second["op"] != 120 or second["ip"] != [540, 195]:
            continue
        if second["next"] != [575, 670]:
            continue
        first = next((i for i in range(k-1, max(-1, k-80), -1)
                      if events[i]["op"] == 120 and not events[i]["string"]), None)
        if first is None or events[first]["ip"] != [1500, 1778]:
            continue
        sel = next((i for i in range(first-1, max(-1, first-55), -1)
                    if events[i]["ip"] == [1500, 1750]), None)
        check(sel is not None and events[sel]["op"] == 118 and
              not events[sel]["string"] and events[first]["next"] == [575, 195],
              "reverse signed selector ancestry")
        result.append((sel, k))
    return sorted(result)


def dump(path, obj):
    path.write_text(json.dumps(obj, separators=(",", ":"), sort_keys=True) + "\n",
                    encoding="utf-8")


def archive_check(data, expected):
    check(sha(data) == expected, "ZIP SHA-256 mismatch")
    archive = zipfile.ZipFile(io.BytesIO(data))
    names = archive.namelist()
    check(len(names) == len(set(names)) and archive.testzip() is None, "ZIP name/CRC")
    return archive


def from_wrappers(ai_path, bc_path):
    """Use the exact original package and the separately pinned QA31BC index."""
    with archive_check(ai_path.read_bytes(), AI) as ai, archive_check(bc_path.read_bytes(), BC) as bc:
        index = json.loads(bc.read("qa31bc_full_original_selector_routes.json"))
        check(index["source_git_blob"] == SOURCE and index["original_signed_archive_sha256"] == AI,
              "independent QA31BC index pins")
        refs = {(r["shard"], r["trace_sha256"]): r for r in index["per_case"]}
        check(len(refs) == len(index["per_case"]) == 200, "QA31BC signed case set")
        mid = ai.read("QA31AH_BEFUNGE98_KYRGYZ_ORIGINAL_29_UPSTREAM_PREFIX_20261106.zip")
        with archive_check(mid, "4c17deae595262dcbcb8863da005810f60288c483273e32b3b2955b9fb13e271") as ah:
            inner = ah.read("QA31Y_BEFUNGE98_KYRGYZ_FULL_EVIDENCE_20261104.zip")
        with archive_check(inner, "1c97b51823ed98b3d333fcb2d0b35d72f7546b04ed8e86c5adebe3aca5703e8a") as y:
            for n in range(8):
                yield n, y.read(f"QA31V_SHARD{n}.zip"), refs
        check(not refs, "unconsumed QA31BC trace references")


def relative_event(ev, second_t):
    return None if ev is None else [ev["t"]-second_t, ev["ip"], ev["op"]]


def reverse_owner(events, tick, xy):
    for i in range(tick-2, -1, -1):
        e = events[i]
        if e["op"] == 112 and not e["string"] and e["pre"][-2:] == xy:
            return [e["t"], e["ip"], e["pre"][-3]]
    return None


def load_shard(data, shard, source, out, all_cases, evidence, refs):
    totals, channels, compact = evidence["counts"], evidence["channels"], evidence["compact"]
    with archive_check(data, SHARDS[shard][1]) as ar:
        by_base = {Path(name).name: name for name in ar.namelist()}
        check(len(by_base) == len(ar.namelist()), "duplicate archive basenames")
        receipt = json.loads(ar.read(by_base["qa31v_receipt.json"]))
        check(receipt["source_blob"] == SOURCE and receipt["shard"] == shard
              and receipt["source_modified"] is False and receipt["ip_relocated"] is False
              and receipt["schema"] == "qa31v-original-native-two-byte-v1"
              and len(receipt["cases"]) == 25, "original shard receipt")
        digits = list(range(48, 58))
        pairs = [(x, y) for x in digits for y in digits+[0,9,10,13,32,255]]
        pairs += [(x, y) for x in (9,10,13,32) for y in digits]
        for pos, rec in enumerate(receipt["cases"]):
            x, y = pairs[25*shard+pos]
            label = f"pair_{x:02x}_{y:02x}"
            raw = b"1 0 0 0" + bytes((x,y))
            check(rec["label"] == label and label not in all_cases and
                  rec["raw_hex"] == raw.hex() and rec["raw_sha256"] == sha(raw) and
                  rec["trace"] == "qa31g_" + label + ".jsonl.gz" and
                  rec["status"] == "HALT" and rec["error"] is None and
                  0 < rec["steps"] <= 25000, "original case identity")
            compressed = ar.read(by_base[rec["trace"]])
            digest = sha(compressed)
            check(digest == rec["trace_sha256"], "compressed original trace SHA")
            if refs is not None:
                meta = refs.pop((shard,digest))
                check(Path(meta["trace"]).name == rec["trace"] and meta["steps"] == rec["steps"],
                      "QA31BC per-case original trace identity")
            with gzip.GzipFile(fileobj=io.BytesIO(compressed)) as stream:
                events = [json.loads(line) for line in stream]
            check(len(events) == rec["steps"] and executed(events[-1], "@"), "original HALT")
            owners = verify_chain(events, source)
            keys = forward_keys(events)
            check(keys == reverse_keys(events), "selector-first / second-x-first witness keys")
            windows = []
            for sel, k in keys:
                t = events[k]["t"]
                end = min(k+LIMIT+1, len(events))
                prefix = events[k+1:k+BOUNDARY+1]
                check(len(prefix) == BOUNDARY, "previous QA31BG boundary")
                matches = [e for e in prefix if executed(e,"g") and e["ip"] == [174,195]
                           and e["pre"][-2:] == TARGET]
                check(len(matches) == 1, "unique second g43 root")
                root = matches[0]
                owner = owners[root["t"]]
                check(owner is not None and owner[1] == [962,480] and owner[2] == root["post"][-1]
                      and owner == reverse_owner(events, root["t"], TARGET), "physical root writer")
                segment = events[root["t"]-1:end]
                boundary_t = t+BOUNDARY
                window = analyze(segment, boundary_t)
                for gate in window["gates"]:
                    if gate["op"] in ("g","p"):
                        prior = owners[gate["t"]]
                        independently = reverse_owner(events, gate["t"], gate["operands"][-2:])
                        check(independently == prior, "physical memory writer disagreement")
                        gate["previous_physical_writer"] = prior
                        if prior is not None and gate["op"] == "g":
                            check(prior[2] == events[gate["t"]-1]["post"][-1], "physical read value")
                        totals["physical_owner_comparisons"] += 1
                    totals["physical_"+gate["op"]] += 1
                    if any(gate["dependent"]):
                        totals["dependent_"+gate["op"]] += 1
                    if gate["conditional_changed"] and gate["op"] in ("x","j","_","|"):
                        totals["conditional_changed_branches"] += 1
                    if any(gate["dependent"]) or (gate["op"] in ("p","g") and gate["conditional_changed"]):
                        channel = str((gate["op"],gate["ip"],gate["operands"][-2:] if gate["op"] in ("p","g") else None,gate["dependent"]))
                        channels["dependent_gate"][channel] += 1
                first = relative_event(window["first_consumer"],t)
                sink = relative_event(window["first_dependent_gate"],t)
                end_slots = window["final_dependent_slots"]
                window.update(selector_t=events[sel]["t"], second_x_t=t, root_writer=owner,
                              root_t=root["t"], end_t=events[end-1]["t"], extension_steps=end-(k+BOUNDARY+1))
                windows.append(window)
                for kind, val in (("first_consumer",first),("first_dependent_gate",sink),
                                  ("final_live_slots",len(end_slots)),("divergence",window["divergence"] is not None)):
                    channels[kind][json.dumps(val,separators=(",",":"))] += 1
                totals.update(windows=1, extension_steps=window["extension_steps"],
                              early_halt=int(end < k+LIMIT+1), oracle_agreements=1)
                compact.append([label,digest,t,root["t"],boundary_t,window["boundary_slot"],
                                json.dumps(first,separators=(",",":")),json.dumps(sink,separators=(",",":")),
                                window["end_t"],len(end_slots),sha(json.dumps(window,sort_keys=True,separators=(",",":")).encode())])
                if not evidence["hostile"]:
                    evidence["hostile"].extend(negative_controls(segment, boundary_t, window))
            all_cases.add(label)
            dump(out / (label+".json"),dict(shard=shard,label=label,raw_hex=raw.hex(),raw_sha256=sha(raw),
                trace_sha256=digest,case_steps=len(events),windows=windows))
            totals.update(cases=1, steps=len(events))
    print("QA31BH_SHARD",shard,dict(totals),flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact-ids", action="store_true")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--archives", nargs=2, type=Path, metavar=("QA31AI_ZIP","QA31BC_ZIP"))
    modes.add_argument("--shards", type=Path)
    parser.add_argument("--out", type=Path, default=Path("bh-evidence"))
    args = parser.parse_args()
    if args.artifact_ids:
        print("\n".join(str(i) for i, _ in SHARDS))
        return
    if not (args.archives or args.shards):
        parser.error("supply --archives AI.zip BC.zip or --shards DIRECTORY")
    args.out.mkdir(parents=True, exist_ok=False)
    raw = Path("src/interleaved_work_counts.b98").read_bytes()
    check(hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest() == SOURCE,
          "original Befunge source blob")
    source = raw.splitlines()
    fixture = json.loads(Path("qa/QA31BC_ORIGINAL_SELECTOR_PORTABLE_FIXTURE_2026-11-08.json").read_text())
    check(fixture["source_git_blob"] == SOURCE and fixture["original_signed_archive_sha256"] == AI
          and fixture["original_selector_values"]["118"] == 225, "QA31BC cohort fixture")
    counts, cases = Counter(), set()
    evidence = dict(counts=counts,hostile=[],compact=[],channels={key:Counter() for key in
        ("first_consumer","first_dependent_gate","dependent_gate","final_live_slots","divergence")})
    parts = (from_wrappers(*args.archives) if args.archives else
             ((n,(args.shards / f"{aid}.zip").read_bytes(),None) for n,(aid,_) in enumerate(SHARDS)))
    for n, data, refs in parts:
        load_shard(data,n,source,args.out,cases,evidence,refs)
    check((counts["cases"],counts["steps"],counts["windows"],counts["oracle_agreements"]) ==
          (200,3628390,225,225), "original QA31AI+BC corpus")
    check(len(evidence["hostile"]) >= 12, "hostile control minimum")
    ledger = args.out/"witnesses.csv"
    with ledger.open("w",newline="",encoding="utf-8") as fp:
        writer = csv.writer(fp,lineterminator="\n")
        writer.writerow(["case","trace_sha256","second_x_t","second_g43_t","boundary_t","slot_from_bottom",
                         "first_consumer_relative","first_dependent_gate_relative","end_t",
                         "live_end_slots","window_record_sha256"])
        writer.writerows(evidence["compact"])
    summary = dict(project="PC-BRANCH-BEFUNGE98-KYRGYZ",source_blob=SOURCE,
        original_run=41689861481,shard_ids_and_hashes=SHARDS, old_bound=BOUNDARY,bound=LIMIT,
        counts=dict(counts),channels=evidence["channels"],hostile=evidence["hostile"],
        ledger_sha256=sha(ledger.read_bytes()),input_route="QA31AI+QA31BC archives" if args.archives
        else "original constituent QA31V GitHub ZIPs + committed QA31BC cohort fixture",
        new_native=0,stage1_pass=False)
    dump(args.out/"summary.json",summary)
    manifest = {p.name:sha(p.read_bytes()) for p in sorted(args.out.iterdir()) if p.is_file()}
    dump(args.out/"SHA256.json",manifest)
    print("QA31BH_SUMMARY",json.dumps(summary,separators=(",",":")),flush=True)
    # Allow the compact cohort ledger to be preserved separately from expiring Actions artifacts.
    encoded = base64.b64encode(zlib.compress(ledger.read_bytes(),9)).decode("ascii")
    for start in range(0,len(encoded),1600):
        print("QA31BH_LEDGER",start,encoded[start:start+1600])

if __name__ == "__main__":
    main()
