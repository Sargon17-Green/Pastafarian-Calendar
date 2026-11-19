#!/usr/bin/env python3
"""Fail-closed, read-only scope and coverage gate for multi-engine Soak.

This is NOT an evidence authenticator, algorithmic-independence auditor,
date converter, or production launch controller. Its inputs are untrusted
assertions. A structural PASS never grants scientific soak certification.
It never imports/starts native converters or performs calendar arithmetic.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
from typing import Any

INVENTORY_SCHEMA = "PASTAFARI_SOAK_SOURCE_ROSTER_V127/1"
PLAN_SCHEMA = "PASTAFARI_SOAK_SCOPE_PLAN_V127/1"
RESULT_SCHEMA = "PASTAFARI_SOAK_UPSTREAM_RECEIPTS_V127/1"
VERDICT_SCHEMA = "PASTAFARI_SOAK_SCOPE_COVERAGE_VERDICT_V127/1"
HEX64 = re.compile(r"[0-9a-f]{64}\Z")
IDENT = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.:+-]{0,127}\Z")
SIGNED = re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
KINDS = {"reference", "production_candidate", "triage", "variant", "wrapper"}
DECISIONS = {"IN_SCOPE", "NOT_READY", "DUPLICATE_OF", "EXCLUDED_REVIEWED"}
OUTCOMES = {"UPSTREAM_VERIFIED", "PENDING", "INVALID", "MISMATCH"}


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False, allow_nan=False).encode("utf-8")


def digest(value: Any) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def unique_pairs(pairs: list[tuple[str, Any]]) -> dict:
    out = {}
    for key, value in pairs:
        if key in out:
            raise ValueError("duplicate JSON key: " + key)
        out[key] = value
    return out


def parse_json(content: bytes) -> dict:
    def reject_constant(text: str):
        raise ValueError("non-JSON constant forbidden: " + text)
    result = json.loads(content.decode("utf-8"), object_pairs_hook=unique_pairs,
                        parse_constant=reject_constant)
    if type(result) is not dict:
        raise ValueError("top-level JSON must be an object")
    return result


def exact_keys(obj: Any, keys: set[str], label: str) -> None:
    if type(obj) is not dict or set(obj) != keys:
        raise ValueError(label + " requires exactly " + repr(sorted(keys)))


def ident(value: Any, label: str) -> str:
    if type(value) is not str or not IDENT.fullmatch(value):
        raise ValueError("invalid identifier: " + label)
    return value


def sha(value: Any, label: str) -> str:
    if type(value) is not str or not HEX64.fullmatch(value):
        raise ValueError("missing or malformed SHA-256: " + label)
    return value


def signed(value: Any, label: str) -> int:
    if type(value) is not str or not SIGNED.fullmatch(value):
        raise ValueError("noncanonical signed decimal: " + label)
    return int(value)


def validate_inventory(inventory: dict) -> dict[str, dict]:
    exact_keys(inventory, {"schema", "records"}, "inventory")
    if inventory["schema"] != INVENTORY_SCHEMA:
        raise ValueError("unknown inventory contract")
    rows = inventory["records"]
    if type(rows) is not list or not rows:
        raise ValueError("empty inventory")
    found = {}
    for row in rows:
        exact_keys(row, {"record_id", "engine_id", "algorithm_id",
                         "source_kind"}, "inventory row")
        key = ident(row["record_id"], "record_id")
        ident(row["engine_id"], "engine_id")
        ident(row["algorithm_id"], "algorithm_id")
        if row["source_kind"] not in KINDS:
            raise ValueError("unknown inventory source kind")
        if key in found:
            raise ValueError("repeated inventory record_id")
        found[key] = row
    return found


def validate_plan(plan: dict, inventory: dict, records: dict) -> tuple[list[dict], list[dict]]:
    exact_keys(plan, {"schema", "inventory_sha256", "years", "dispositions",
                      "incident_status", "dispatch_halt", "independence_audit"},
               "scope plan")
    if plan["schema"] != PLAN_SCHEMA or sha(plan["inventory_sha256"], "inventory") != digest(inventory):
        raise ValueError("scope plan does not lock exact inventory contents")
    if plan["incident_status"] not in {"OPEN", "RESOLVED_WITH_REVIEW"}:
        raise ValueError("unknown first-difference incident status")
    if type(plan["dispatch_halt"]) is not bool:
        raise ValueError("dispatch_halt must be a boolean")
    if plan["independence_audit"] not in {"NOT_CERTIFIED", "EXTERNALLY_REVIEWED"}:
        raise ValueError("invalid independence review assertion")
    years = plan["years"]
    if type(years) is not list or not 1 <= len(years) <= 10_000:
        raise ValueError("year plan must contain 1..10000 years")
    last_day = None
    previous_year = None
    seen_years = set()
    for year in years:
        exact_keys(year, {"year", "first_target_day", "last_target_day",
                          "boundary_evidence_sha256"}, "year")
        y = signed(year["year"], "year")
        first = signed(year["first_target_day"], "first_target_day")
        last = signed(year["last_target_day"], "last_target_day")
        sha(year["boundary_evidence_sha256"], "year boundary")
        if y in seen_years or not 1 <= last - first + 1 <= 5_778:
            raise ValueError("duplicate year or invalid full-year extent")
        if previous_year is not None and y != previous_year + 1:
            raise ValueError("nonconsecutive year labels")
        if last_day is not None and first != last_day + 1:
            raise ValueError("gap or overlap between full-year boundaries")
        seen_years.add(y)
        previous_year, last_day = y, last
    dispositions = plan["dispositions"]
    if type(dispositions) is not list:
        raise ValueError("dispositions must be a list")
    by_record = {}
    for item in dispositions:
        exact_keys(item, {"record_id", "decision", "duplicate_of",
                          "review_evidence_sha256"}, "disposition")
        rid = ident(item["record_id"], "disposition.record_id")
        if rid not in records or rid in by_record:
            raise ValueError("unknown or repeated inventory disposition")
        decision = item["decision"]
        if decision not in DECISIONS:
            raise ValueError("unknown disposition")
        target, review = item["duplicate_of"], item["review_evidence_sha256"]
        if decision == "DUPLICATE_OF":
            if type(target) is not str or target == rid:
                raise ValueError("duplicate record lacks distinct target")
            if review is not None:
                raise ValueError("duplicate record must not pretend exclusion review")
        elif decision == "EXCLUDED_REVIEWED":
            if target is not None:
                raise ValueError("reviewed exclusion must not alias another engine")
            sha(review, "reviewed-exclusion evidence")
        elif target is not None or review is not None:
            raise ValueError("unexpected duplicate/review metadata")
        by_record[rid] = item
    if set(by_record) != set(records):
        raise ValueError("inventory incomplete: every roster record needs a disposition")
    included = [records[rid] for rid, item in by_record.items()
                if item["decision"] == "IN_SCOPE"]
    if len(included) < 2:
        raise ValueError("at least two original-source engines must be in scope")
    unique_engines, unique_algorithms = set(), set()
    for row in included:
        if row["source_kind"] not in {"reference", "production_candidate"}:
            raise ValueError("wrapper, variant or triage not accepted as independent source")
        e, a = row["engine_id"], row["algorithm_id"]
        if e in unique_engines or a in unique_algorithms:
            raise ValueError("duplicate engine or algorithm identity in scope")
        unique_engines.add(e)
        unique_algorithms.add(a)
    for rid, item in by_record.items():
        if item["decision"] == "DUPLICATE_OF":
            target = item["duplicate_of"]
            if target not in by_record or by_record[target]["decision"] != "IN_SCOPE":
                raise ValueError("duplicate must point directly to an included source")
            if records[rid]["algorithm_id"] != records[target]["algorithm_id"]:
                raise ValueError("claimed duplicate algorithm lineage differs")
    return years, included


def analyze(inventory: dict, plan: dict, evidence: dict) -> dict:
    records = validate_inventory(inventory)
    years, engines = validate_plan(plan, inventory, records)
    exact_keys(evidence, {"schema", "plan_sha256", "engine_years"}, "receipts")
    if evidence["schema"] != RESULT_SCHEMA or sha(evidence["plan_sha256"], "plan") != digest(plan):
        raise ValueError("upstream receipts are not bound to this exact plan")
    rows = evidence["engine_years"]
    if type(rows) is not list:
        raise ValueError("engine-year receipts must be a list")
    engine_ids = [r["engine_id"] for r in engines]
    allowed = {(e, y["year"]) for e in engine_ids for y in years}
    seen = {}
    for row in rows:
        exact_keys(row, {"engine_id", "year", "status", "days",
                         "daystream_sha256", "native_receipt_sha256",
                         "boundary_evidence_sha256"}, "year receipt")
        key = (ident(row["engine_id"], "receipt engine"), row["year"])
        signed(row["year"], "receipt year")
        if key not in allowed or key in seen:
            raise ValueError("unplanned, duplicate or previously omitted engine/year receipt")
        if row["status"] not in OUTCOMES:
            raise ValueError("unknown upstream verification status")
        if row["status"] == "UPSTREAM_VERIFIED":
            if type(row["days"]) is not int or row["days"] <= 0:
                raise ValueError("invalid complete-day count")
            for field in ("daystream_sha256", "native_receipt_sha256",
                          "boundary_evidence_sha256"):
                sha(row[field], field)
        else:
            if any(row[k] is not None for k in
                   ("days", "daystream_sha256", "native_receipt_sha256",
                    "boundary_evidence_sha256")):
                raise ValueError("unverified slot cannot claim hashes or completion")
        seen[key] = row

    verified_pair_years = 0
    contiguous_years = 0
    first_problem = None
    pending = 0
    invalid = 0
    mismatch = 0
    for y in years:
        year_id = y["year"]
        expected_days = int(y["last_target_day"]) - int(y["first_target_day"]) + 1
        stream_sha = None
        year_ok = True
        for engine in engine_ids:
            key = (engine, year_id)
            item = seen.get(key)
            if item is None or item["status"] == "PENDING":
                pending += 1
                year_ok = False
                if first_problem is None:
                    first_problem = {"type": "MISSING_OR_PENDING", "year": year_id,
                                     "engine": engine}
                continue
            if item["status"] == "INVALID":
                invalid += 1
                year_ok = False
                if first_problem is None:
                    first_problem = {"type": "INVALID", "year": year_id, "engine": engine}
                continue
            if item["status"] == "MISMATCH":
                mismatch += 1
                year_ok = False
                if first_problem is None:
                    first_problem = {"type": "MISMATCH", "year": year_id, "engine": engine}
                continue
            if (item["days"] != expected_days or
                    item["boundary_evidence_sha256"] != y["boundary_evidence_sha256"]):
                invalid += 1
                year_ok = False
                if first_problem is None:
                    first_problem = {"type": "BAD_YEAR_EXTENT_OR_BOUNDARY",
                                     "year": year_id, "engine": engine}
                continue
            if stream_sha is None:
                stream_sha = item["daystream_sha256"]
            elif item["daystream_sha256"] != stream_sha:
                mismatch += 1
                year_ok = False
                if first_problem is None:
                    first_problem = {"type": "DAYSTREAM_HASH_DIFFERENCE",
                                     "year": year_id, "engine": engine}
        if year_ok:
            verified_pair_years += len(engines) - 1
            if contiguous_years == years.index(y):
                contiguous_years += 1

    structural_complete = (not pending and not invalid and not mismatch and
                           len(seen) == len(allowed))
    incident_clear = (plan["incident_status"] == "RESOLVED_WITH_REVIEW" and
                      plan["dispatch_halt"] is False)
    reviewed = plan["independence_audit"] == "EXTERNALLY_REVIEWED"
    eligible = structural_complete and incident_clear and reviewed
    decisions = [d["decision"] for d in plan["dispositions"]]
    return {
        "schema": VERDICT_SCHEMA,
        "status": ("STRUCTURAL_COMPLETE_UNCERTIFIED" if eligible
                   else "INCIDENT_HALT" if not incident_clear
                   else "COVERAGE_INCOMPLETE_OR_UNREVIEWED"),
        "inventory_sha256": digest(inventory),
        "plan_sha256": digest(plan),
        "receipts_sha256": digest(evidence),
        "inventory_record_count": len(records),
        "included_engine_count": len(engines),
        "not_ready_record_count": decisions.count("NOT_READY"),
        "duplicate_record_count": decisions.count("DUPLICATE_OF"),
        "reviewed_exclusion_record_count": decisions.count("EXCLUDED_REVIEWED"),
        "planned_year_count": len(years),
        "ten_thousand_year_target_met": len(years) == 10_000,
        "expected_engine_year_receipts": len(allowed),
        "received_engine_year_receipts": len(seen),
        "missing_or_pending_engine_years": pending,
        "invalid_engine_years": invalid,
        "mismatched_engine_years": mismatch,
        "structurally_equal_engine_year_pairs": verified_pair_years,
        "contiguous_structurally_equal_years": contiguous_years,
        "first_problem": first_problem,
        "structural_coverage_complete": structural_complete,
        "source_independence_externally_reviewed_asserted": reviewed,
        "first_difference_reviewed_and_dispatch_halt_cleared": incident_clear,
        "input_evidence_authenticity_independently_verified": False,
        "raw_native_bytes_independently_revalidated_here": False,
        "original_converter_executed_by_this_gate": False,
        "official_years_certified_by_this_gate": 0,
        "official_soak_10000_pass": False,
    }


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--inventory", required=True, type=Path)
    cli.add_argument("--plan", required=True, type=Path)
    cli.add_argument("--receipts", required=True, type=Path)
    cli.add_argument("--report", type=Path)
    args = cli.parse_args()
    try:
        report = analyze(*[parse_json(p.read_bytes())
                           for p in (args.inventory, args.plan, args.receipts)])
    except (ValueError, OSError, UnicodeError) as exc:
        report = {"schema": VERDICT_SCHEMA, "status": "INVALID_INPUT",
                  "error": str(exc), "official_soak_10000_pass": False,
                  "official_years_certified_by_this_gate": 0}
    data = canonical(report) + b"\n"
    print(data.decode("utf-8"), end="")
    if args.report is not None:
        with args.report.open("xb") as stream:
            stream.write(data)
    return 0 if report["status"] == "STRUCTURAL_COMPLETE_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
