#!/usr/bin/env python3
"""Audits one original, immutable SQL+Tamil Slice25 phase-profile ZIP.

No PostgreSQL call, source modification, new oracle, or native PASS is implied.
Exit 0 means that the *failure evidence* is internally consistent, not that
Slice25 or the instrumented calendar date passed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from collections import Counter, defaultdict
from pathlib import Path

PROJECT = "PC-BRANCH-SQL-TAMIL"
TESTED_SHA = "59e139f56502721228e2fc5b0fa97ca72fbd1140"
ARTIFACT_SHA256 = "616889c1b0beb9a62e8e43869cce0b19ee97388c065c4afdb1d04e91c0ef8b90"
CASE = "prev_3_prev_middle"
EXPECTED_COUNTS = {"target_year": 1, "sauce": 1, "bowl_round": 46,
                   "order": 46, "stone": 414, "save": 414,
                   "post_stir_round": 12, "post_chain": 1}
SOURCE_BLOBS = {5: "f465b466d4a00e24baa689561725a12e5478bf55",
                6: "2cc67c27b1f5e0c2f22537e479e42956a5711b9e",
                8: "68a7d99c7cddd1a5b47ef4ef9dc189ab08c53da6",
                10: "c5c6be7c02c255382ae7c317bfbf17138a12788c",
                13: "d4044e6a4f2f2ae94795233dd3aa14a7d7edaf9e",
                18: "c204a314972b22a4a38f06a02c2fe1bd5bde7acf",
                26: "faac634a06aee59354de207eb088e4e9996034fa",
                27: "748d4bc1f7754f003c29a42a1756f26e08c1669b"}
PATTERN = re.compile(r"NOTICE:\s+SQL_TAMIL_PROFILE_(ENTER|EXIT)=([a-z_]+):(.+)$")


def require(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def scan(text: str) -> dict:
    counts = {"ENTER": Counter(), "EXIT": Counter()}
    duration = defaultdict(list)
    last = None
    for line in text.splitlines():
        found = PATTERN.search(line)
        if not found:
            continue
        kind, name, tag = found.groups()
        counts[kind][name] += 1
        last = {"action": kind, "phase": name, "detail": tag}
        if kind == "EXIT":
            try:
                value = float(tag.rsplit(":", 1)[1])
            except (ValueError, IndexError):
                raise ValueError("malformed phase duration") from None
            require(value >= 0 and value < 720000, "duration outside bounded statement")
            duration[name].append(value)
    require(dict(counts["ENTER"]) == EXPECTED_COUNTS, "missing/extra ENTER notices")
    require(dict(counts["EXIT"]) == EXPECTED_COUNTS, "missing/extra EXIT notices")
    require("canceling statement due to statement timeout" in text,
            "expected timeout error missing")
    for frame in ('SQL function "visible_drops" statement 1',
                  'SQL function "negative_gate_gap" statement 1',
                  "pastafari_sql_tamil.qa_phase_calendar_date(numeric,numeric)"):
        require(frame in text, f"missing SQL call-stack frame: {frame}")
    for forbidden in (f"SLICE25_QA_PHASE_GREEN=native:{CASE}",
                      f"SLICE25_NATIVE_FIELD_PASS={CASE}.",
                      f"SLICE25_QA_PHASE_FIELD_PASS={CASE}."):
        require(forbidden not in text, "unexpected success marker in failed case")
    result = {
        "outcome": "BOUNDED_NATIVE_TIMEOUT_NOT_PASS",
        "last_completed_phase": last,
        "phase_counts": {k: dict(sorted(v.items())) for k, v in counts.items()},
        "elapsed_ms": {name: {"count": len(values), "sum": round(sum(values), 3),
                               "min": round(min(values), 3), "max": round(max(values), 3)}
                       for name, values in sorted(duration.items())},
        "five_field_oracle": "NOT_REACHED",
        "original_equivalence": "NOT_RUN",
        "slice25_acceptance": "NOT_ACCEPTED",
    }
    return result


def audit(path: Path) -> dict:
    raw = path.read_bytes()
    require(hashlib.sha256(raw).hexdigest() == ARTIFACT_SHA256,
            "original ZIP SHA256 differs from GitHub/upload evidence")
    with zipfile.ZipFile(path) as z:
        require(z.testzip() is None, "original ZIP CRC failed")
        names = z.namelist()
        require(len(names) == len(set(names)), "duplicate ZIP members")
        require(all(not n.startswith("/") and ".." not in Path(n).parts for n in names),
                "unsafe member name")
        required = ("versions.txt", "postgres-phase.txt", "source-sha256.txt",
                    "production-blobs.txt", "test.sql", "original.sql",
                    "phase-overrides.sql", "static.txt", "oracle-audit.txt")
        require(all(n in names for n in required), "missing original evidence member")
        read = lambda name: z.read(name).decode("utf-8")
        version = read("versions.txt")
        for line in (f"PROJECT_ID={PROJECT}", f"GITHUB_SHA={TESTED_SHA}",
                     "BRANCH=SQL+தமிழ்", f"CASE={CASE}",
                     "CALC=-15055671", "TARGET=-15072356",
                     "postgres (PostgreSQL) 17.12"):
            require(line in version, f"version/fixture mismatch: {line}")
        hashes = {}
        for line in read("source-sha256.txt").splitlines():
            found = re.fullmatch(r"([0-9a-f]{64})\s+(.+)", line)
            require(found is not None, "malformed source manifest")
            hashes[found.group(2)] = found.group(1)
        for name in ("test.sql", "original.sql", "phase-overrides.sql"):
            key = "phase-evidence/" + name
            require(hashlib.sha256(z.read(name)).hexdigest() == hashes.get(key),
                    f"generated SQL integrity mismatch: {name}")
        blobs = read("production-blobs.txt").splitlines()
        require(len(blobs) == 28, "production file-count lock failed")
        for index, expected in SOURCE_BLOBS.items():
            require(blobs[index] == expected, f"Git blob lock mismatched sql/{index:02d}")
        require("SLICE25_GENERATOR_PREFLIGHT=87/87 PASS" in read("oracle-audit.txt"),
                "locked independent corpus generator audit absent")
        require("SLICE25_QA_PHASE_STATIC_LOCK=7/7 PASS" in read("static.txt"),
                "QA transform static source lock absent")
        result = scan(read("postgres-phase.txt"))
    result.update({"project_id": PROJECT, "tested_sha": TESTED_SHA,
                   "job_id": 136919794548, "run_id": 44928511225,
                   "artifact_id": 14718837632, "original_zip_sha256": ARTIFACT_SHA256,
                   "zip_crc": "PASS", "verified_generated_sql": 3,
                   "verified_production_blob_locks": len(SOURCE_BLOBS)})
    return result


def self_test() -> None:
    sample = "\n".join(
        [f"NOTICE: SQL_TAMIL_PROFILE_ENTER={k}:tag:2026-11-21 00:00:00+00\n"
         f"NOTICE: SQL_TAMIL_PROFILE_EXIT={k}:tag:1.250"
         for k, n in EXPECTED_COUNTS.items() for _ in range(n)]
    ) + ('\nERROR: canceling statement due to statement timeout\n'
         'SQL function "visible_drops" statement 1\n'
         'SQL function "negative_gate_gap" statement 1\n'
         'PL/pgSQL function pastafari_sql_tamil.qa_phase_calendar_date(numeric,numeric) line 87\n')
    result = scan(sample)
    require(result["phase_counts"]["ENTER"]["stone"] == 414, "self test count")
    for tamper in (sample.replace("EXIT=save", "EXIT=other", 1),
                   sample.replace("negative_gate_gap", "other", 1),
                   sample + f"SLICE25_QA_PHASE_GREEN=native:{CASE}\n"):
        try:
            scan(tamper)
        except ValueError:
            pass
        else:
            raise AssertionError("tampered evidence passed")
    print("SQL_TAMIL_TIMEOUT_EVIDENCE_SELFTEST=4/4 PASS")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    require(args.self_test or args.archive is not None, "choose --self-test/--archive")
    if args.self_test:
        self_test()
    if args.archive is not None:
        result = audit(args.archive)
        output = json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
        if args.output:
            args.output.write_text(output, encoding="utf-8")
        print(output, end="")


if __name__ == "__main__":
    main()
