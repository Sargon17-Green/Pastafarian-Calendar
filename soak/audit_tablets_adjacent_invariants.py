#!/usr/bin/env python3
"""Independent interval and adjacent-day checks of a frozen real TABLETS receipt.

This audits existing CI evidence, not a new real gate replay or certification.
The interval/cutlet implications do not depend on the pinned Python oracle.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

TARGETS = (-278523, -278522, -278521)
RECEIPT_SHA256 = "930fb15171c73f863577b9e811f741b1d6a149cbd5aea1325d486ef5283fc61d"
SOURCE_COMMIT = "71cdac969bc17ef6749f24767f2beebd53f97df2"
PINNED_COMMIT = "7cb12bf355461e5a179e0deadb7365689288bf29"
SOURCE_CLOSURE_SHA256 = "81aea10577986a9ed46dcbf7b79c38954f24fa4de01323a756cd4d43f76ebef5"
TRANSCRIPT_SHA256 = "caaf71076bf738981db4b75af441ae82a8e4341970d24606ffc59bd208f64193"
CANDIDATE_BLOB = "e5c1238c95d9b2a75ff365d2661a758b46fa8add"
PRODUCTION_BRIDGE_BLOB = "3c328abfd40b6fc1edf730e6012b05ad7fcb65d6"
STATUS = "PASS_TABLETS_ADJACENT_RECEIPT_INVARIANTS_NOT_CERTIFIED"
PRIOR_STATUS = "PASS_FRESH_CACHE_FREE_TABLETS_3X5_DIAGNOSTIC_NOT_CERTIFIED"

class AuditError(ValueError):
    pass

def require(condition, code):
    if not condition:
        raise AuditError(code)

def exact_int(v):
    return type(v) is int

def unique_pairs(pairs):
    obj = {}
    for k, v in pairs:
        require(k not in obj, "E_DUPLICATE_KEY")
        obj[k] = v
    return obj

def load_frozen_receipt(path):
    raw = Path(path).read_bytes()
    require(hashlib.sha256(raw).hexdigest() == RECEIPT_SHA256, "E_RECEIPT_BYTES")
    try:
        document = json.loads(raw.decode("utf-8"), object_pairs_hook=unique_pairs)
    except (ValueError, UnicodeError) as exc:
        raise AuditError("E_RECEIPT_JSON") from exc
    return document

def git_blob_sha(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()

def audit_source(root):
    """Provenance pins + the existing static closure checker; no runtime gate work."""
    root = Path(root)
    for rel, want in (
        ("soak/fresh_cache_free_tablets_differential.py", CANDIDATE_BLOB),
        ("soak/Post55ProductionDateBridge.kt", PRODUCTION_BRIDGE_BLOB),
    ):
        require(git_blob_sha((root / rel).read_bytes()) == want, "E_SOURCE_BLOB_" + rel)
    from tablets_unseeded_closure_contract import audit_sources
    closure = audit_sources(root)
    require(closure["closure_sha256"] == SOURCE_CLOSURE_SHA256
            and closure["imported_checkpoint_seeds"] is False
            and closure["algorithmic_independence_certified"] is False,
            "E_CLOSURE_PROVENANCE")
    return closure["closure_sha256"]

def audit_document(d):
    require(type(d) is dict, "E_DOCUMENT_TYPE")
    require(d.get("status") == PRIOR_STATUS
            and d.get("independent_commit") == SOURCE_COMMIT
            and d.get("pinned_commit") == PINNED_COMMIT
            and d.get("source_closure_sha256") == SOURCE_CLOSURE_SHA256
            and d.get("signed_transcript_sha256") == TRANSCRIPT_SHA256
            and exact_int(d.get("signed_gate_questions"))
            and d["signed_gate_questions"] == 29523,
            "E_PROVENANCE")
    for field in ("cache_free", "candidate_cold_isolated", "distinct_git_roots",
                  "pinned_reference_used_only_for_comparison"):
        require(d.get(field) is True, "E_ISOLATION_CLAIM_" + field)
    for field in ("checkpoint_seed_used", "full_date_certified", "certifiable"):
        require(d.get(field) is False, "E_UNSUPPORTED_CLAIM_" + field)
    require(exact_int(d.get("pinned_cold_processes")) and
            d["pinned_cold_processes"] == 3 and
            exact_int(d.get("production_limit_unchanged")) and
            d["production_limit_unchanged"] == 8192 and
            exact_int(d.get("five_field_comparisons")) and
            d["five_field_comparisons"] == 15,
            "E_ACCOUNTING")
    a, b = d.get("candidate_rows"), d.get("pinned_rows")
    require(type(a) is list and type(b) is list and len(a) == len(b) == 3,
            "E_ROW_COUNT")
    parsed = []
    for i, (left, right) in enumerate(zip(a, b)):
        day = TARGETS[i]
        for row in (left, right):
            require(type(row) is dict and exact_int(row.get("day"))
                    and row["day"] == day, "E_ROW_DAY")
            f = row.get("five_fields")
            require(type(f) is list and len(f) == 5 and
                    all(exact_int(x) for x in f) and
                    f[0] >= 1 and 1 <= f[1] <= 17 and f[2] >= 1 and
                    1 <= f[3] <= 47 and 1 <= f[4] <= 123,
                    "E_TYPED_FIVE_FIELDS")
        require(left["five_fields"] == right["five_fields"], "E_PINNED_MISMATCH")
        parsed.append(tuple(left["five_fields"]))

    brackets = d.get("structural_brackets")
    require(type(brackets) is list and len(brackets) == 3, "E_BRACKET_COUNT")
    first = None
    for day, rec in zip(TARGETS, brackets):
        require(type(rec) is dict and
                all(exact_int(rec.get(x)) for x in ("day", "index", "low", "high")) and
                rec["day"] == day and 1 <= rec["index"] <= 29523 and
                42 <= rec["high"] - rec["low"] <= 963 and
                rec["low"] < day <= rec["high"], "E_BRACKET_BOUNDS")
        interval = (rec["index"], rec["low"], rec["high"])
        if first is None:
            first = interval
        require(interval == first, "E_NOT_SAME_GATE_INTERVAL")
    # A cutlet and a year are bounded by gates. Within a single open/closed
    # gate interval, neither can change; day-in-cutlet is an exact day offset.
    for left, right in zip(parsed, parsed[1:]):
        require(right[0] == left[0], "E_YEAR_ROLLOVER_INSIDE_GATE")
        require(right[1] == left[1], "E_CUTLET_ROLLOVER_INSIDE_GATE")
        require(right[2] == left[2] + 1, "E_CUTLET_DAY_STEP")
    return {
        "status": STATUS,
        "source_run": 43767624423,
        "source_artifact": 14183646379,
        "source_receipt_sha256": RECEIPT_SHA256,
        "checked_real_days": list(TARGETS),
        "typed_pinned_comparisons_from_prior_run": 15,
        "independent_interval_checks": 3,
        "independent_adjacent_cutlet_step_checks": 2,
        "gate_interval": {"index": first[0], "low": first[1], "high": first[2]},
        "new_real_gap_computations": 0,
        "new_pinned_processes": 0,
        "full_date_certified": False,
        "algorithmic_independence_certified": False,
        "certifiable": False,
    }

def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--receipt", type=Path, default=Path(__file__).resolve().parent / "evidence" / "tablets-cache-free-3x5-run43767624423.json")
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        doc = load_frozen_receipt(args.receipt)
        report = audit_document(doc)
        report["source_closure_sha256"] = audit_source(Path(__file__).resolve().parent.parent)
    except Exception as exc:
        report = {"status": "FAIL_TABLETS_ADJACENT_RECEIPT_AUDIT",
                  "error_type": type(exc).__name__, "error": str(exc)[-240:],
                  "full_date_certified": False, "certifiable": False}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == STATUS else 2

if __name__ == "__main__":
    raise SystemExit(main())
