#!/usr/bin/env python3
"""Fail-closed source-closure and receipt contract for unseeded TABLETS research.

No real gate or full-date computation is performed here. A synthetic contract
test, a source-closure audit, and a real date comparison are distinct gates.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
from pathlib import Path

MODULE_BLOBS = {
    "independent_five_field_date": "b5e75a79d38f939331dfc3c81aceb13fd16ef165",
    "independent_year_geometry_oracle": "1be4a5d4374e16119aef1145714a573c57d83b76",
    "independent_sauce_oracle": "ece05c5eae6b4493e9b2a538980738c06c575456",
    "independent_date_combinatorics": "7026631e37dd19274f55cc6ff823d7278d6a6296",
    "independent_month_weaving_oracle": "ade10dc3fae41a3fe1a93cfefcfa6685b2fb86a5",
}
STANDARD_IMPORTS = frozenset({"__future__", "dataclasses", "functools", "itertools",
                              "math", "time", "typing"})
DYNAMIC_CALLS = frozenset({"eval", "exec", "__import__", "compile", "open"})
FORBIDDEN_NAMES = frozenset({"GATE_CHECKPOINTS", "pinned_source",
                             "load_checkpoint", "reference_checkpoint"})
EXPECTED_SYMBOLS = {
    "independent_five_field_date": {"date_from_ledger", "independent_rank",
                                    "independent_signed_gap"},
    "independent_year_geometry_oracle": {"GateLedger", "IndependentYearGeometry"},
    "independent_sauce_oracle": {"evaluate", "gap_from_witness"},
    "independent_date_combinatorics": {"rank_from_sauce", "unrank_cutlet_partition"},
    "independent_month_weaving_oracle": {"IndependentMonthWeavingOracle"},
}
FOUNDATION = -15055671
TARGETS = (-278523, -278522, -278521)
MAX_QUESTIONS = 32768
MAX_SEGMENT = 8192
SOURCE_STATUS = "PASS_TABLETS_SOURCE_CLOSURE_DIAGNOSTIC_NOT_CERTIFIED"
REAL_STATUS = "PASS_REAL_UNSEEDED_FIVE_FIELDS_PINNED_DATE_NOT_COMPARED_NOT_CERTIFIED"


class ContractError(ValueError):
    pass


def git_blob_sha(raw: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()


def _check(condition: bool, code: str) -> None:
    if not condition:
        raise ContractError(code)


def inspect_texts(texts: dict[str, bytes], locks: dict[str, str] = MODULE_BLOBS) -> dict:
    """Audit all five source bytes, nonstandard imports, and reachable local closure.

    Only a fixed allow-list of Python stdlib imports and the other four source
    modules is permitted. This proves a *declared static import boundary*,
    not general dynamic semantic independence.
    """
    _check(set(texts) == set(locks) == set(MODULE_BLOBS), "E_CLOSURE_MODULE_SET")
    graph = {}
    digests = {}
    memoized = []
    for module in sorted(locks):
        raw = texts[module]
        _check(isinstance(raw, bytes), "E_CLOSURE_BYTES")
        _check(git_blob_sha(raw) == locks[module], "E_CLOSURE_BLOB_" + module)
        try:
            tree = ast.parse(raw.decode("utf-8"), filename=module + ".py")
        except (SyntaxError, UnicodeError) as exc:
            raise ContractError("E_CLOSURE_PARSE_" + module) from exc
        local = set()
        symbols = set()
        for node in ast.walk(tree):
            if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                symbols.add(node.name)
            if isinstance(node, ast.Import):
                imports = [alias.name.split(".")[0] for alias in node.names]
            elif isinstance(node, ast.ImportFrom):
                _check(node.level == 0 and node.module is not None,
                       "E_CLOSURE_RELATIVE_IMPORT")
                _check(all(alias.name != "*" for alias in node.names),
                       "E_CLOSURE_STAR_IMPORT")
                imports = [node.module.split(".")[0]]
            else:
                imports = []
            for imported in imports:
                _check(imported in STANDARD_IMPORTS or imported in locks,
                       "E_CLOSURE_IMPORT_" + imported)
                if imported in locks:
                    local.add(imported)
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                _check(node.func.id not in DYNAMIC_CALLS,
                       "E_CLOSURE_DYNAMIC_" + node.func.id)
            if isinstance(node, ast.Name):
                _check(node.id not in FORBIDDEN_NAMES,
                       "E_CLOSURE_SEED_REFERENCE_" + node.id)
            if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)
                    and node.func.id in {"getattr", "setattr", "delattr"}):
                _check(False, "E_CLOSURE_REFLECTION")
            if (isinstance(node, ast.Name) and node.id == "lru_cache"):
                _check(module == "independent_date_combinatorics",
                       "E_CLOSURE_UNDECLARED_CACHE")
                memoized.append(module)
        _check(EXPECTED_SYMBOLS[module] <= symbols,
               "E_CLOSURE_MISSING_SYMBOL_" + module)
        graph[module] = sorted(local)
        digests[module] = hashlib.sha256(raw).hexdigest()
    reached = set()
    pending = ["independent_five_field_date"]
    while pending:
        item = pending.pop()
        if item not in reached:
            reached.add(item)
            pending.extend(graph[item])
    _check(reached == set(locks), "E_CLOSURE_UNREACHABLE")
    _check(memoized == ["independent_date_combinatorics"],
           "E_CLOSURE_CACHE_ATTESTATION")
    manifest = [{"module": name, "git_blob": locks[name],
                 "sha256": digests[name], "imports": graph[name]} for name in sorted(locks)]
    closure_hash = hashlib.sha256(
        json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return {
        "status": SOURCE_STATUS,
        "module_count": len(manifest),
        "module_manifest": manifest,
        "closure_sha256": closure_hash,
        "static_external_checkpoint_imports": 0,
        "process_local_pure_memoization": ["independent_date_combinatorics._count_bounded_compositions"],
        "imported_checkpoint_seeds": False,
        "source_provenance_audit": True,
        "runtime_cache_isolation_proven": False,
        "algorithmic_independence_certified": False,
        "full_date_certified": False,
        "certifiable": False,
    }


def audit_sources(root: Path) -> dict:
    base = root / "soak"
    return inspect_texts({module: (base / (module + ".py")).read_bytes()
                          for module in MODULE_BLOBS})


def _hex_digest(value) -> bool:
    return isinstance(value, str) and len(value) == 64 and all(
        letter in "0123456789abcdef" for letter in value
    )


def validate_real_receipt(receipt: dict) -> dict:
    """Validate shape/accounting only, never turn an old diagnostic into proof."""
    _check(type(receipt) is dict, "E_RECEIPT_TYPE")
    _check(receipt.get("status") == REAL_STATUS, "E_RECEIPT_STATUS")
    _check(receipt.get("targets") == list(TARGETS), "E_RECEIPT_TARGETS")
    _check(receipt.get("cases") == 3 and receipt.get("fields_per_case") == 5,
           "E_RECEIPT_DIMENSION")
    _check(type(receipt.get("segment_limit")) is int and
           1 <= receipt["segment_limit"] <= MAX_SEGMENT, "E_RECEIPT_SEGMENT")
    parts = [receipt.get(k) for k in ("positive_prefix_questions",
                                     "forward_extension_questions", "negative_questions")]
    count = receipt.get("total_unique_gap_questions")
    _check(all(type(value) is int and value >= 0 for value in parts) and
           type(count) is int and 0 < count <= MAX_QUESTIONS and
           sum(parts) == count and parts[0] > 0 and parts[2] > 0,
           "E_RECEIPT_QUESTION_ACCOUNTING")
    rows = receipt.get("rows")
    _check(type(rows) is list and len(rows) == 3, "E_RECEIPT_ROWS")
    for target, row in zip(TARGETS, rows):
        _check(type(row) is dict and type(row.get("day")) is int and
               row["day"] == target, "E_RECEIPT_DAY")
        fields = row.get("five_fields")
        _check(type(fields) is list and len(fields) == 5 and
               all(type(value) is int for value in fields), "E_RECEIPT_TYPED_FIVE")
        year, cutlet, cutlet_day, month, month_day = fields
        _check(year > 0 and 1 <= cutlet <= 17 and cutlet_day >= 1 and
               1 <= month <= 47 and 1 <= month_day <= 123,
               "E_RECEIPT_FIELD_RANGE")
    _check(_hex_digest(receipt.get("signed_transcript_sha256")) and
           _hex_digest(receipt.get("positive_audit_trace_sha256")),
           "E_RECEIPT_TRANSCRIPT")
    for name in ("checkpoint_seed_used", "pinned_date_comparison_performed",
                 "external_cache_independence_certified", "full_date_certified", "certifiable"):
        _check(receipt.get(name) is False, "E_RECEIPT_UNSUPPORTED_CLAIM_" + name)
    _check(receipt.get("production_gate_limit_unchanged") == 8192,
           "E_RECEIPT_PRODUCTION_LIMIT")
    return {"receipt_shape": "PASS_DIAGNOSTIC_ONLY",
            "typed_cells": 15, "unique_questions": count,
            "signed_transcript_sha256": receipt["signed_transcript_sha256"],
            "pinned_date_comparisons_proven_here": 0,
            "full_date_certified": False}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    ap.add_argument("--evidence", type=Path, required=True)
    ap.add_argument("--real-evidence", type=Path)
    args = ap.parse_args(argv)
    report = {"status": "FAIL_TABLETS_SOURCE_CLOSURE", "full_date_certified": False}
    try:
        report = audit_sources(args.root)
        report["origin"] = FOUNDATION
        report["targets"] = list(TARGETS)
        report["max_unique_questions"] = MAX_QUESTIONS
        report["max_questions_per_segment"] = MAX_SEGMENT
        report["unseeded_signed_replay_required"] = True
        report["independent_rank_and_structure_required"] = True
        report["deadline_required_for_real_run"] = True
        if args.real_evidence is not None:
            report["previous_real_receipt"] = validate_real_receipt(
                json.loads(args.real_evidence.read_text(encoding="utf-8")))
        report["real_execution_performed_this_run"] = False
    except (ContractError, OSError, ValueError) as exc:
        report = {"status": "FAIL_TABLETS_SOURCE_CLOSURE",
                  "error_type": type(exc).__name__, "error": str(exc)[:250],
                  "full_date_certified": False, "certifiable": False}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n",
                             encoding="utf-8")
    print(json.dumps({k: v for k, v in report.items() if k != "module_manifest"},
                     sort_keys=True))
    return 0 if report["status"] == SOURCE_STATUS else 2


if __name__ == "__main__":
    raise SystemExit(main())
