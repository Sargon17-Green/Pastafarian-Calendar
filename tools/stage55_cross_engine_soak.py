#!/usr/bin/env python3
"""Bounded projection soak. Shared metadata; independent projection, not rank."""
import hashlib
import itertools
import json
import os
import random
import sys
from pathlib import Path
import stage55_full_year_projection_oracle as oracle

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/stage55_year5000_appendix_a_metadata.json"
MIDDLE = ROOT / "tests/fixtures/stage55_year5000_middle_word.json"
OUT = ROOT / "logs/stage55_soak"
LABELS = ("LOW_NEIGHBOR", "HIGH_NEIGHBOR", "CUTLET_SWAPS", "SEED17", "SEED2718", "SEED65537")
def digest(b):
    return hashlib.sha256(b).hexdigest()
def dump(path, obj):
    path.write_text(json.dumps(obj, sort_keys=True, indent=2) + "\n", encoding="utf-8")
def require(ok, msg):
    if not ok:
        raise ValueError(msg)
def neighbor(word, target, lengths, max_distance=None):
    for distance in range(len(word)-1):
        if max_distance is not None and distance > max_distance:
            break
        for i in ((target,) if not distance else (target-distance, target+distance)):
            if not 0 <= i < len(word)-1 or word[i] == word[i+1]:
                continue
            w = word.copy()
            w[i], w[i+1] = w[i+1], w[i]
            try:
                oracle.valid_word(w, lengths)
            except ValueError:
                continue
            return w, i+1
    raise ValueError("no legal adjacent swap near target")
def seeded(lengths, seed):
    rng = random.Random(seed)
    remaining = lengths.copy()
    opened = closed = 0
    w = []
    for _ in range(sum(lengths)):
        choices = [j for j, n in enumerate(remaining) if n
                   and (n != lengths[j] or j == opened)
                   and (n != 1 or j == closed)]
        require(bool(choices), "empty legal choice set")
        # Explicit random() stream; stable choice mapping, no rejection sampling.
        j = choices[int(rng.random()*len(choices))]
        opened += int(remaining[j] == lengths[j])
        closed += int(remaining[j] == 1)
        remaining[j] -= 1
        w.append(j+1)
    oracle.valid_word(w, lengths)
    return w
def prepare():
    d, fsha = oracle.fixture_data(FIXTURE)
    lengths = d["month_lengths"]
    first = oracle.greedy_edge(lengths, False)
    last = oracle.greedy_edge(lengths, True)
    middle = json.loads(MIDDLE.read_text(encoding="utf-8"))
    oracle.valid_word(middle, lengths)
    low, lp = neighbor(first, 0, lengths)
    high, hp = neighbor(last, len(last)-2, lengths)
    boundary = middle.copy()
    swaps = []
    for end in list(itertools.accumulate(d["cutlet_day_lengths"]))[:-1]:
        boundary, pos = neighbor(boundary, end-1, lengths, 16)
        swaps.append({"cutlet_end": end, "swap_left_position": pos})
    words = [low, high, boundary] + [seeded(lengths, n) for n in (17,2718,65537)]
    require(len({tuple(w) for w in words+[first,last,middle]}) == 9, "duplicate or old case")
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {"project_id": oracle.PROJECT_ID, "scope": "PATCH25_PROJECTION_ONLY",
                "fixture_sha256": fsha, "tiny_controls": oracle.tiny_exhaustive_controls(),
                "edge_swaps": [lp,hp], "cutlet_swaps": swaps, "cases": {},
                "native_rank_verified": False, "metadata_independently_derived": False,
                "final_stage_accepted": False}
    for label, word in zip(LABELS, words):
        oracle.valid_word(word, lengths)
        raw = (json.dumps(word,separators=(",",":"))+"\n").encode("ascii")
        (OUT / (label+".json")).write_bytes(raw)
        csv = oracle.csv_bytes(word,d)
        require(csv.count(b"\n")==4245, "wrong rows")
        (OUT / (label+"_PY.csv")).write_bytes(csv)
        manifest["cases"][label] = {"word_sha256":digest(raw),"csv_sha256":digest(csv),
                                    "rows":4244,"bytes":len(csv)}
        print("PY_CASE",label,digest(raw),digest(csv))
    dump(OUT/"input_manifest.json",manifest)
    print("SOAK_PYTHON_PREPARED CASES=6 ROWS=4244")
def verify():
    manifest = json.loads((OUT/"input_manifest.json").read_text())
    expected = set()
    for label in LABELS:
        row = manifest["cases"][label]
        ref = (OUT/(label+"_PY.csv")).read_bytes()
        require(digest(ref)==row["csv_sha256"],"oracle digest changed")
        require(digest((OUT/(label+".json")).read_bytes())==row["word_sha256"],"word digest changed")
        native = []
        for session in (1,2):
            for trial in (1,2):
                name=f"{label}_S{session}_R{trial}.csv"
                expected.add(name)
                raw=(OUT/name).read_bytes()
                require(raw==ref, "byte mismatch "+name)
                native.append({"file":name,"sha256":digest(raw),"bytes":len(raw)})
        row["native"]=native
    require({p.name for p in OUT.glob("*_S*_R*.csv")}==expected,"missing or extra native output")
    for session in (1,2):
        log=(OUT/f"native_S{session}.log").read_text()
        require(f"SOAK_NATIVE_SESSION_PASS SESSION={session} CASES=12 NEGATIVE=24" in log,"native session marker")
        require(log.count("SOAK_NATIVE_CASE_PASS")==12,"case log count")
    manifest.update(source_commit=os.environ["GITHUB_SHA"],run_id=os.environ["GITHUB_RUN_ID"],
                    bytewise=True,native_cases=24,negative_positions=[0,4245],negative_checks=48)
    dump(OUT/"differential.json",manifest)
    print("SOAK_DIFFERENTIAL_PASS CASES=6 NATIVE_RUNS=24 ROWS=101856 BYTEWISE=YES")
if __name__ == "__main__":
    if sys.argv[1:] == ["prepare"]:
        prepare()
    elif sys.argv[1:] == ["verify"]:
        verify()
    else:
        raise SystemExit("usage: prepare | verify")
