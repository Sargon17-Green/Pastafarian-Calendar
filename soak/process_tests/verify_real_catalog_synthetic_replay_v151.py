#!/usr/bin/env python3
"""Read the THREE pinned historic source blobs; replay only fabricated day rows.

No original converter or original F(c,t) runs. Real 17/47 native names are
inherited exclusively from historical source files validated by v018/v151.
Fixture receipts and binary SHA assertions remain synthetic/unattested.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from native_execution_receipt_v038 import canonical, make_receipt
from soak_raw_bound_year_diff_v149 import SCHEMA as V149_SCHEMA, audit as raw_audit
from soak_source_derived_names_v151 import audit as semantic_audit, extract_names, pinned_lock
from source_identity_gate_v036 import IDENTITY_SCHEMA, PROVENANCE_CONTRACT


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def run(source_root: Path) -> dict:
    lock = pinned_lock()
    catalogs = extract_names(source_root)
    byid = {x["id"]: x for x in lock["engines"]}
    plan = {
        "contract": PROVENANCE_CONTRACT,
        "identity_contract": IDENTITY_SCHEMA,
        "soak_purpose": "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status": "NOT_CERTIFIED",
        "calculation_day": "-15055672", "chunk_days": 2,
        "years": [{
            "year": "5000", "first_target_day": "-15056173",
            "last_target_day": "-15056170",
            "boundary_evidence_sha256": "f" * 64,
        }],
        "engines": []
    }
    for i, eid in enumerate(("REF-41", "REF-24")):
        e, names = byid[eid], catalogs[eid]
        plan["engines"].append({
            "id": eid, "algorithm_id": "synthetic-dispatch-fixture-" + eid,
            "source_sha256": names["source_sha256"],
            # These binary hashes are deliberately MOCK assertions and do NOT
            # attest any original executable.
            "binary_sha256": ("a" if i == 0 else "b") * 64,
            "name_map_sha256": names["catalog_sha256"],
            "provenance": {
                "schema": IDENTITY_SCHEMA, "source_class": "reference",
                "source_commit": e["commit"], "repository": e["repository"],
                "source_path": e["sources"][0]["path"],
                "source_family": "synthetic-run-fixture-" + eid,
                "native_entrypoint": e["entrypoint"],
                "execution_method": "unchanged_reference_Fct",
                "derived_from": None,
                "original_source_sha256": names["source_sha256"]
            }
        })
    manifest = {
        "schema": V149_SCHEMA,
        "year": "5000", "engine_a": "REF-41", "engine_b": "REF-24",
        "bundles": {"REF-41": [], "REF-24": []}
    }

    def make_native(engine: str, idx: int) -> dict:
        names = catalogs[engine]["catalog"]
        t = str(-15056173 + idx)
        if engine == "REF-41":
            return {
                "calculation_day": "-15055672", "target_day": t,
                "native_date_ids": {
                    "year_number": "5000",
                    "cutlet_name_index": 10,
                    "day_in_cutlet": 503 + idx,
                    "month_name_index": 20,
                    "day_in_month": 56 + idx,
                },
                "native_names": {
                    "cutlet": names["cutlets"][9],
                    "month": names["months"][19]
                }
            }
        return {
            "calculation_day": "-15055672", "target_day": t,
            "native_tuple": ["5000", names["cutlets"][9], str(503 + idx),
                             names["months"][19], str(56 + idx)]
        }

    def write_receipt(engine: str, ordinal: int) -> None:
        b = manifest["bundles"][engine][ordinal]
        raw = Path(b["raw_path"]).read_bytes()
        norm = Path(b["normalized_path"]).read_bytes()
        first = -15056173 + ordinal * 2
        receipt = make_receipt(plan, sha(canonical(plan)), engine, "5000",
                               str(first), str(first + 1), ordinal, norm, raw)
        Path(b["receipt_path"]).write_bytes(canonical(receipt) + b"\n")

    with tempfile.TemporaryDirectory(prefix="v151-real-names-only-") as folder:
        base = Path(folder)
        for engine in ("REF-41", "REF-24"):
            for ordinal in range(2):
                work = base / engine / str(ordinal)
                work.mkdir(parents=True)
                b = {
                    "ordinal": ordinal, "raw_path": str(work / "raw.jsonl"),
                    "normalized_path": str(work / "norm.jsonl"),
                    "receipt_path": str(work / "receipt.json")
                }
                manifest["bundles"][engine].append(b)
                raw_lines, norm_lines = [], []
                for idx in (ordinal * 2, ordinal * 2 + 1):
                    source_bytes = canonical(make_native(engine, idx)) + b"\n"
                    raw_lines.append(source_bytes)
                    names = catalogs[engine]["catalog"]
                    row = {
                        "calculation_day": "-15055672",
                        "target_day": str(-15056173 + idx), "year": "5000",
                        "cutlet_index": 10, "day_in_cutlet": 503 + idx,
                        "month_index": 20, "day_in_month": 56 + idx,
                        "cutlet_name_raw": names["cutlets"][9],
                        "month_name_raw": names["months"][19],
                        "source_raw_sha256": sha(source_bytes)
                    }
                    norm_lines.append(canonical(row) + b"\n")
                Path(b["raw_path"]).write_bytes(b"".join(raw_lines))
                Path(b["normalized_path"]).write_bytes(b"".join(norm_lines))
                write_receipt(engine, ordinal)
        good = semantic_audit(plan, manifest, source_root)
        if good.get("status") != "SOURCE_LOCKED_SEMANTIC_EQUAL_UNCERTIFIED" or \
                good.get("source_native_rows_replayed") != 8:
            raise AssertionError("source-derived mock replay failed: " + str(good))
        target_bundle = manifest["bundles"]["REF-24"][0]
        raw_file = Path(target_bundle["raw_path"])
        norm_file = Path(target_bundle["normalized_path"])
        lines = [json.loads(b) for b in raw_file.read_bytes().splitlines()]
        # Alter a source-native month 20 to month 30, then recompute EVERYTHING
        # normally used as the byte-integrity and receipt gate.
        lines[0]["native_tuple"][3] = catalogs["REF-24"]["catalog"]["months"][29]
        new_source = canonical(lines[0]) + b"\n"
        raw_file.write_bytes(b"".join(canonical(line) + b"\n" for line in lines))
        norm = [json.loads(b) for b in norm_file.read_bytes().splitlines()]
        norm[0]["source_raw_sha256"] = sha(new_source)
        norm_file.write_bytes(b"".join(canonical(item) + b"\n" for item in norm))
        write_receipt("REF-24", 0)

        older = raw_audit(plan, manifest)
        if older["status"] != "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED":
            raise AssertionError("v149 previously undetected semantic laundering fixture wrong")
        blocked = semantic_audit(plan, manifest, source_root)
        if blocked["status"] != "INVALID_SOURCE_BOUND_EVIDENCE" or \
                "native raw semantics do not match normalized" not in blocked["error"]:
            raise AssertionError("source-derived semantic replay failed to reject: " + str(blocked))
        return {
            "status": "REAL_SOURCE_CATALOGS_SYNTHETIC_REPLAY_PASS_NOT_NATIVE_CERTIFIED",
            "ref_41_cutlet_10": catalogs["REF-41"]["catalog"]["cutlets"][9],
            "ref_41_month_20": catalogs["REF-41"]["catalog"]["months"][19],
            "ref_24_cutlet_10": catalogs["REF-24"]["catalog"]["cutlets"][9],
            "ref_24_month_20": catalogs["REF-24"]["catalog"]["months"][19],
            "source_code_files_bytes_verified": 3,
            "synthetic_day_pairs_replayed": 4,
            "byte_only_v149_false_positive_reproduced": True,
            "v151_rejected_rehashed_semantic_forgery": True,
            "original_converter_calls": 0,
            "original_soak_years_certified": 0,
            "original_algorithmic_independence_certified": False,
        }


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--sources-root", type=Path, required=True)
    p.add_argument("--report", type=Path, required=True)
    args = p.parse_args()
    result = run(args.sources_root)
    with args.report.open("xb") as f:
        f.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
