#!/usr/bin/env python3
"""Fail-closed same-run paired QA; never Stage56 acceptance."""
import json
import math
import pathlib
import sys

PROJECT = "PC-BRANCH-PHP-MALAY"
SOURCE = "cc2cf0b422757a5e7c33218ce30cffa8f99c6786"
SEMANTIC = ("year_record", "structure", "rank_digits", "count_digits", "rank_sha256",
            "count_sha256", "cutlet_oracle", "reference_sha256", "gates_sha256",
            "scroll_oracle_sha256", "calculation_jdn")

def require(ok, reason):
    if not ok:
        raise ValueError(reason)

def profile(root, year):
    rows = [json.loads(x) for x in (root / f"{year}.json.dp.jsonl").read_text().splitlines()]
    dp = [r for r in rows if r["event"] == "row"]
    require(dp and all(0 <= r["active_rows"] + r["checkpoint_rows"] <= 8 for r in dp), "DP row cap")
    return max(r["process_peak_bytes"] for r in rows)

def result(root, year, sha, mode):
    require((root / "SHA.txt").read_text().strip() == sha and
            (root / "PROJECT_ID.txt").read_text().strip() == PROJECT, "root identity")
    require(not (root / f"{year}.stderr").read_bytes(), "stderr")
    rc = int((root / f"{year}.exit").read_text())
    peak = profile(root, year)
    if mode == "default" and year == 5001 and rc == 124:
        require(not (root / f"{year}.json").exists(), "timeout with final JSON")
        return None, 900.0, peak
    require(rc == 0, "nonzero exit")
    d = json.loads((root / f"{year}.json").read_text())
    require(d["project_id"] == PROJECT and d["branch_sha"] == sha and
            d["source_commit"] == SOURCE and d["year"] == year and
            d["qa_engine"] == mode and d["stage56_accepted"] is False and
            d["status"] == "PHP_REAL_YEAR_QA_PASS_NOT_STAGE56_ACCEPTANCE", "result identity")
    require(d["month_differential"] == "PASS" and d["rank_roundtrip"] == "PASS" and
            d["cutlet_external_semantics"] == "PASS_SOURCE_FREE_ORACLE", "semantic gate")
    t, p = d["total_seconds"], d["peak_bytes"]
    require(math.isfinite(t) and 0 < t <= 900 and 0 < peak <= p <= 536870912, "resource cap")
    return d, t, p

def main():
    base, fused, sha = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
    reports = []
    for year in (4999, 5000, 5001):
        r = {"year": year, "pass": False}
        try:
            a, t, p = result(base, year, sha, "default")
            b, u, q = result(fused, year, sha, "fused")
            r.update(baseline_seconds=t, fused_seconds=u, baseline_peak_bytes=p,
                     fused_peak_bytes=q, baseline_censored=a is None,
                     improvement_lower_bound=1-u/t)
            if a is not None:
                require(all(a[k] == b[k] for k in SEMANTIC), "paired semantic mismatch")
            else:
                # No final default result: require the independently checked
                # source-bound candidate, not fictional full default parity.
                r["semantic_scope"] = "candidate source-bound and roundtrip only; default censored"
            require(q <= p, "peak regression")
            require(u <= 0.9*t and (year != 5001 or u <= 810), "performance threshold")
            r["pass"] = True
        except (OSError, ValueError, KeyError, TypeError) as e:
            r["reason"] = str(e)
        reports.append(r)
    passed = all(r["pass"] for r in reports)
    print(json.dumps({"project_id": PROJECT, "branch_sha": sha, "stage56_accepted": False,
                      "status": "PAIRED_QA_PASS_ONLY" if passed else "PAIRED_QA_REJECT",
                      "years": reports}, indent=2))
    return 0 if passed else 1

if __name__ == "__main__":
    sys.exit(main())
