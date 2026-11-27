#!/usr/bin/env python3
"""Compare exact-source scratch QA against the pinned stride8 parent; never acceptance."""
import hashlib
import json
import math
import os
import pathlib
import sys

PROJECT = "PC-BRANCH-PHP-MALAY"
SOURCE = "cc2cf0b422757a5e7c33218ce30cffa8f99c6786"
BASE_SHA = "9b1150f1b4c34c1f408bdd57c255fcaa4082209f"
BASE = {
    4999: (591.976011697, 224395264, 67368340, 33, 67743,
           "f2a32f7fdf645f6cff53665d1e257eb5053b2e461c1ddbb693e048183bcd7749",
           "bd0f91fedd1a221f8643398973fbc0eab6283528e825c8901dae08718dca640f",
           "170c05dc4fc7273073b1597d9ce232e3c56e4e679dad7560951e529e6cd05e62"),
    5000: (875.773382096, 270532608, 101192560, 44, 97394,
           "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8",
           "160ca5c4a8ee5d0ec29c583a0d7ab91a71d8be4b7dc4c139ebaae066596dcff3",
           "4739e7affa94b8c285f766155b6d479f72c028e62b5448fbfc307e0736770956"),
    # 5001 is censored at 900s; observed partial DP peak is conservative.
    5001: (900.0, 388497408, 179186560, 45, 124263,
           "82cf8a2d71f09f203438bd2abc70e30234c2b2ef0a045e1e45fca8151d6e6cb5",
           "ac8a4fb52a71feaeb71ace720fdd011ae740750cccd13e7a9d3c27582daa6da3",
           None),
}

def require(ok, reason):
    if not ok:
        raise ValueError(reason)

def digest(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()

def records(p):
    return [json.loads(line) for line in p.read_text().splitlines()]

def compare(root, year, sha):
    t, peak, size, rows, cells, count_hash, rank_hash, structure_hash = BASE[year]
    out = dict(year=year, baseline_seconds=t, baseline_timeout=year == 5001,
               baseline_peak_bytes=peak, expected_scratch_bytes=size)
    try:
        require((root / f"{year}.exit").read_text().strip() == "0", "nonzero exit")
        require((root / f"{year}.stderr").read_bytes() == b"", "stderr")
        d = json.loads((root / f"{year}.json").read_text())
        require(d["project_id"] == PROJECT and d["branch_sha"] == sha and
                d["source_commit"] == SOURCE and d["year"] == year and
                d["qa_engine"] == "scratch" and d["stage56_accepted"] is False and
                d["status"] == "PHP_REAL_YEAR_QA_PASS_NOT_STAGE56_ACCEPTANCE", "identity")
        require(d["month_differential"] == "PASS" and d["rank_roundtrip"] == "PASS" and
                d["cutlet_external_semantics"] == "PASS_SOURCE_FREE_ORACLE", "semantics")
        profile = records(root / f"{year}.json.profile.jsonl")
        require(all(x["project_id"] == PROJECT and x["branch_sha"] == sha and
                    x["source_commit"] == SOURCE and x["year"] == year for x in profile), "profile identity")
        for stage, key in (("scratch_provider", "provider_scratch"), ("scratch_roundtrip", "roundtrip_scratch")):
            s = d[key]
            require(s["bytes"] == size <= 268435456 and s["rows"] == rows and
                    type(s["loads"]) is int and s["loads"] > 0, key)
            entries = [x for x in profile if x["stage"] == stage and x["type"] == "end"]
            require(len(entries) == 1 and all(entries[0][k] == s[k] for k in ("bytes", "rows", "loads")), stage)
            out[key] = s
        choice = [x for x in profile if x["stage"] == "month_weaving_choice" and x["type"] == "end"]
        require(len(choice) == 1 and digest(choice[0]["count"]) == count_hash and
                digest(choice[0]["rank"]) == rank_hash, "baseline count/rank choice")
        if structure_hash is not None:
            require(digest(json.dumps(d["structure"], sort_keys=True, separators=(",", ":"), ensure_ascii=False))
                    == structure_hash, "full baseline structure")
        dp = records(root / f"{year}.json.dp.jsonl")
        starts = [x for x in dp if x["event"] == "start"]
        ends = [x for x in dp if x["event"] == "end"]
        ids = {x["id"] for x in starts}
        require(len(starts) == len(ends) == len(ids) == 2 and ids == {x["id"] for x in ends}, "two complete rebuilds")
        require(all(x["event"] in ("start", "row", "end") and x["id"] in ids for x in dp), "DP identity")
        for s in starts:
            rr = [x for x in dp if x["event"] == "row" and x["id"] == s["id"]]
            e = next(x for x in ends if x["id"] == s["id"])
            require(s["start"] == 0 and s["stop"] == rows and s["planned_cells"] == cells and
                    s["checkpoint_reused"] is False and [x["index"] for x in rr] == list(range(rows, -1, -1)) and
                    sum(x["cells"] for x in rr) == e["cells"] == cells and
                    all(x["active_rows"] + x["checkpoint_rows"] <= 8 and x["checkpoint_rows"] == 0 for x in rr), "DP rows/cells")
        seconds, actual_peak = d["total_seconds"], d["peak_bytes"]
        out.update(seconds=seconds, peak_bytes=actual_peak)
        require(type(seconds) in (int, float) and math.isfinite(seconds) and 0 < seconds <= .9*t, "less than 10% improvement")
        require(type(actual_peak) is int and 0 < actual_peak <= min(peak, 536870912), "peak regression")
        out["status"] = "PASS_QA_ONLY"
    except (OSError, ValueError, KeyError, TypeError, StopIteration) as exc:
        out.update(status="REJECT", reason=str(exc))
    return out

def main():
    root = pathlib.Path(sys.argv[1])
    sha = os.environ.get("GITHUB_SHA", "")
    require(len(sha) == 40 and all(c in "0123456789abcdef" for c in sha) and
            (root / "PROJECT_ID.txt").read_text().strip() == PROJECT and
            (root / "SHA.txt").read_text().strip() == sha, "run identity")
    years = [compare(root, y, sha) for y in BASE]
    ok = all(y["status"] == "PASS_QA_ONLY" for y in years)
    report = dict(project_id=PROJECT, branch_sha=sha, source_commit=SOURCE,
                  baseline_sha=BASE_SHA, baseline_run=45954257710, baseline_artifact=15179988531,
                  baseline_zip_sha256="1cbd68ba6717a5b049d8f7c54edcd0ee6b73379739375c226ba3027ae699289a",
                  minimum_fractional_improvement=.10, stage56_accepted=False,
                  status="SCRATCH_COMPARISON_PASS_QA_ONLY" if ok else "SCRATCH_COMPARISON_REJECT", years=years)
    encoded = json.dumps(report, indent=2, allow_nan=False) + "\n"
    (root / "scratch-comparison.json").write_text(encoded)
    print(encoded, end="")
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
