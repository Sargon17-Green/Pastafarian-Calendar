#!/usr/bin/env python3
"""Read-only, evidence-first bridge: v2 CrashStore -> v127 scope receipts.

Verifies frozen on-disk SQLite chunk registrations, bytes, source-normalized
row digests, deterministic v038 native receipts, and full-year comparison
digests. Does not run F(c,t), claim authentic process identity, or modify
the ledger. Run only on a quiescent copied snapshot after WAL checkpointing.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sqlite3
from typing import Any

from native_execution_receipt_v038 import verify_receipt, canonical as receipt_canonical
from recovery_store import canonical_bytes, sha256 as hash_bytes, validate_plan as validate_recovery
from soak_scope_coverage_v127 import (
    analyze, canonical, digest, parse_json, validate_inventory, validate_plan as validate_scope,
    RESULT_SCHEMA
)
from source_identity_gate_v036 import PROVENANCE_CONTRACT
from year_validator import YearCase, parse_line


def require_file(path: Path) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise ValueError("missing or symlinked immutable evidence: " + path.name)
    return path.read_bytes()


def fresh_json(payload: bytes, *, canonical_expected: bool) -> dict:
    obj = parse_json(payload)
    if canonical_expected and payload != canonical_bytes(obj):
        raise ValueError("receipt or plan bytes are not canonical")
    return obj


def check_sqlite_rows(db: sqlite3.Connection, table: str,
                      allowed: set[tuple], cols: str) -> None:
    rows = db.execute("SELECT " + cols + " FROM " + table).fetchall()
    found = [tuple(r) for r in rows]
    if len(found) != len(set(found)) or set(found) != allowed:
        raise ValueError("SQLite " + table + " contains unexpected/missing committed rows")


def audit(root: Path, inventory: dict, scope: dict) -> tuple[dict, dict]:
    records = validate_inventory(inventory)
    years, included = validate_scope(scope, inventory, records)
    root = root.resolve(strict=True)
    for name in ("chunks", "evidence"):
        d = root / name
        if d.is_symlink() or not d.is_dir():
            raise ValueError("missing/symlinked ledger folder: " + name)
    if any((root / name).exists() for name in
           ("ledger.sqlite-wal", "ledger.sqlite-shm", "run-plan.json.part")):
        raise ValueError("live WAL/shm or uncommitted run plan: snapshot must be frozen")
    plan = fresh_json(require_file(root / "run-plan.json"), canonical_expected=True)
    validate_recovery(plan)
    if plan["contract"] != PROVENANCE_CONTRACT:
        raise ValueError("v1 plan has no native original receipts")
    original_engine_ids = [e["id"] for e in plan["engines"]]
    scoped_ids = [r["engine_id"] for r in included]
    if original_engine_ids != scoped_ids:
        raise ValueError("v127 in-scope engine order differs from immutable v2 source plan")
    if plan["years"] != years:
        raise ValueError("v127 years differ from frozen original ledger plan")
    plan_sha = hash_bytes(canonical_bytes(plan))
    dbpath = root / "ledger.sqlite"
    if dbpath.is_symlink() or not dbpath.is_file():
        raise ValueError("missing or symlinked SQLite ledger")
    db = sqlite3.connect(dbpath.as_uri() + "?mode=ro", uri=True)
    db.execute("PRAGMA query_only=ON")
    db.row_factory = sqlite3.Row
    try:
        db.execute("BEGIN")
        if db.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise ValueError("SQLite integrity check failed")
        row = db.execute("SELECT value FROM meta WHERE key='plan_sha256'").fetchone()
        if row is None or row[0] != plan_sha:
            raise ValueError("SQLite plan digest not identical to frozen plan")
        incident = db.execute("SELECT kind FROM incident LIMIT 1").fetchone()
        if incident is not None:
            raise ValueError("existing ledger incident halts any upstream verified import")
        found_chunks: set[tuple] = set()
        found_receipts: set[tuple] = set()
        expected_comparisons: set[tuple] = set()
        results = []
        for year in years:
            y = year["year"]
            case = YearCase(plan["calculation_day"], y,
                            year["first_target_day"], year["last_target_day"],
                            year["boundary_evidence_sha256"])
            case.validate()
            first = int(case.first_target_day)
            last = int(case.last_target_day)
            total = last - first + 1
            baseline_stream = None
            for index, engine in enumerate(scoped_ids):
                stream = hashlib.sha256()
                combined_receipts = hashlib.sha256()
                missing = False
                for ordinal in range((total + plan["chunk_days"] - 1)//plan["chunk_days"]):
                    lo = first + ordinal * plan["chunk_days"]
                    hi = min(last, lo + plan["chunk_days"] - 1)
                    key = (engine, y, ordinal)
                    identity = canonical_bytes([plan_sha, engine, y, ordinal,str(lo),str(hi)])
                    stem = hash_bytes(identity)
                    norm_path = root / "chunks" / (stem + ".jsonl")
                    raw_path = root / "evidence" / (stem + ".native-stdout")
                    receipt_path = root / "evidence" / (stem + ".native-receipt.json")
                    dbchunk = db.execute(
                        "SELECT first_day,last_day,file_sha256,bytes FROM chunks "
                        "WHERE engine=? AND year=? AND ordinal=?", key).fetchone()
                    dbreceipt = db.execute(
                        "SELECT receipt_sha256,stdout_sha256,stdout_bytes,source_rows "
                        "FROM native_receipts WHERE engine=? AND year=? AND ordinal=?",
                        key).fetchone()
                    if dbchunk is None and dbreceipt is None:
                        if any(p.exists() or p.is_symlink() or
                               p.with_name(p.name + ".part").exists()
                               for p in (norm_path, raw_path, receipt_path)):
                            raise ValueError("orphaned or staged evidence cannot be treated as pending")
                        missing = True
                        continue
                    if dbchunk is None or dbreceipt is None:
                        raise ValueError("chunk and native-receipt SQLite rows disagree")
                    found_chunks.add(key)
                    found_receipts.add(key)
                    if dbchunk["first_day"] != str(lo) or dbchunk["last_day"] != str(hi):
                        raise ValueError("registered chunk boundary differs from immutable plan")
                    for p in (norm_path, raw_path, receipt_path):
                        if p.with_name(p.name + ".part").exists():
                            raise ValueError("ambiguous staged evidence on disk")
                    norm = require_file(norm_path)
                    raw = require_file(raw_path)
                    receipt_bytes = require_file(receipt_path)
                    if (dbchunk["file_sha256"] != hash_bytes(norm) or
                            dbchunk["bytes"] != len(norm)):
                        raise ValueError("normalized file violates committed SQLite checksum")
                    metadata = fresh_json(receipt_bytes, canonical_expected=True)
                    checked = verify_receipt(
                        plan, plan_sha, engine, y, str(lo), str(hi), ordinal,
                        norm, raw, metadata
                    )
                    if ((dbreceipt["receipt_sha256"],dbreceipt["stdout_sha256"],
                         dbreceipt["stdout_bytes"],dbreceipt["source_rows"]) !=
                        (hash_bytes(receipt_bytes), checked["raw_stdout_sha256"],
                         checked["raw_stdout_bytes"],checked["raw_rows"])):
                        raise ValueError("native receipt disagrees with SQLite atomic registration")
                    lines = norm.decode("utf-8").splitlines(keepends=True)
                    if len(lines) != hi - lo + 1:
                        raise ValueError("short/long native normalized chunk")
                    for offset, line in enumerate(lines):
                        # Strict duplicate-key and set-of-fields validation is separate
                        # from v038's raw-line hash binding.
                        def no_duplicates(pairs):
                            data = {}
                            for name, value in pairs:
                                if name in data:
                                    raise ValueError("duplicate native normalized JSON field")
                                data[name] = value
                            return data
                        row_json = json.loads(line, object_pairs_hook=no_duplicates,
                                              parse_constant=lambda _: (_ for _ in ()).throw(
                                                  ValueError("nonfinite numeric literal")))
                        if set(row_json) != {
                            "calculation_day", "target_day", "year", "cutlet_index",
                            "day_in_cutlet", "month_index", "day_in_month",
                            "cutlet_name_raw", "month_name_raw", "source_raw_sha256"
                        }:
                            raise ValueError("normalized record has missing or extra fields")
                        day = parse_line(line, offset+1, case, lo+offset)
                        stream.update(canonical_bytes(day.normalized) + b"\n")
                    combined_receipts.update(bytes.fromhex(hash_bytes(receipt_bytes)))
                if missing:
                    status = "PENDING"
                    result = {"engine_id":engine, "year":y, "status":status,
                              "days":None, "daystream_sha256":None,
                              "native_receipt_sha256":None,
                              "boundary_evidence_sha256":None}
                else:
                    normalized_sha = stream.hexdigest()
                    if baseline_stream is None:
                        baseline_stream = normalized_sha
                    elif normalized_sha != baseline_stream:
                        raise ValueError("first cross-engine full-year stream hash difference")
                    if index:
                        expected_comparisons.add((y, engine))
                        compared = db.execute(
                            "SELECT verified_days,stream_sha256 FROM comparisons "
                            "WHERE year=? AND candidate=?", (y,engine)).fetchone()
                        if (compared is None or compared["verified_days"] != total or
                                compared["stream_sha256"] != normalized_sha):
                            raise ValueError("SQLite year comparison lacks exact complete digest")
                    result = {"engine_id":engine, "year":y, "status":"UPSTREAM_VERIFIED",
                              "days":total, "daystream_sha256":normalized_sha,
                              "native_receipt_sha256":combined_receipts.hexdigest(),
                              "boundary_evidence_sha256":case.boundary_evidence_sha256}
                results.append(result)
        check_sqlite_rows(db, "chunks", found_chunks, "engine,year,ordinal")
        check_sqlite_rows(db, "native_receipts", found_receipts, "engine,year,ordinal")
        check_sqlite_rows(db, "comparisons", expected_comparisons, "year,candidate")
        db.execute("COMMIT")
    except BaseException:
        try:
            db.execute("ROLLBACK")
        except sqlite3.Error:
            pass
        raise
    finally:
        db.close()
    receipts = {"schema":RESULT_SCHEMA,
                "plan_sha256":digest(scope), "engine_years":results}
    coverage = analyze(inventory, scope, receipts)
    return receipts, coverage


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,required=True)
    parser.add_argument("--inventory",type=Path,required=True)
    parser.add_argument("--scope",type=Path,required=True)
    parser.add_argument("--receipts-out",type=Path,required=True)
    parser.add_argument("--coverage-out",type=Path,required=True)
    args = parser.parse_args()
    if args.receipts_out.resolve() == args.coverage_out.resolve():
        raise ValueError("two outputs must have different paths")
    inventory = parse_json(args.inventory.read_bytes())
    scope = parse_json(args.scope.read_bytes())
    receipts, coverage = audit(args.root, inventory, scope)
    # Require both output names to be NEW, never overwrite earlier evidence.
    if args.receipts_out.exists() or args.coverage_out.exists():
        raise FileExistsError("never replace an earlier audit receipt")
    with args.receipts_out.open("xb") as file:
        file.write(canonical(receipts)+b"\n")
    with args.coverage_out.open("xb") as file:
        file.write(canonical(coverage)+b"\n")
    print(json.dumps({"schema":"PASTAFARI_SOAK_READONLY_LEDGER_BRIDGE_V128/1",
                      "status":coverage["status"],"official_soak_10000_pass":False,
                      "official_years_certified":0,
                      "native_process_identity_attested":False,
                      "engine_year_slots":len(receipts["engine_years"])},
                     sort_keys=True))
    return 0 if coverage["status"] == "STRUCTURAL_COMPLETE_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
