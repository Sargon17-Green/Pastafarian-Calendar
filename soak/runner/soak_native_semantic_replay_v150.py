#!/usr/bin/env python3
"""v150 independent raw/native-to-normalized semantic replay for a planned year.

Builds ON the v149 hash-bound whole-year gate and the earlier v018 source-native
decoder, but never runs any date converter. Explicit, self-declared profile
metadata cannot attest actual original source lineage or OS process identity.
All results are uncertified, with the original Soak dispatch halt retained.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from native_execution_receipt_v038 import canonical
from native_raw_pair_gate_v018 import EvidenceError, verify_pair
from soak_raw_bound_year_diff_v149 import audit as audit_v149, file_bytes
from soak_scope_coverage_v127 import parse_json

SCHEMA = "PASTAFARI_SOAK_NATIVE_SEMANTIC_REPLAY_V150/1"
CODECS = {
    "SOURCE_NATIVE_JSON_IDS_V018": "REF-41",
    "SOURCE_NATIVE_JSON_NAMED_TUPLE_V018": "REF-24",
}
FIVE = ("year", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month")
REPORT_STATES = {
    "TECHNICAL_EQUAL_RAW_BOUND_UNCERTIFIED": "SEMANTICALLY_EQUAL_UNCERTIFIED",
    "FIRST_NUMERIC_DIFFERENCE": "SEMANTICALLY_REPLAYED_FIRST_DIFFERENCE",
}


def require(condition: bool, detail: str) -> None:
    if not condition:
        raise ValueError(detail)


def validate_profiles(plan: dict, manifest: dict, profiles: dict) -> dict:
    """Never treat self-declared mappings as independently verified source."""
    require(type(profiles) is dict and set(profiles) == {"schema", "engines"}
            and profiles["schema"] == SCHEMA, "semantic profile schema missing")
    expected = {manifest["engine_a"], manifest["engine_b"]}
    entries = profiles["engines"]
    require(type(entries) is list and len(entries) == 2,
            "exactly two decoder profiles are required")
    descriptors = {e["id"]: e for e in plan["engines"]}
    result = {}
    for p in entries:
        require(type(p) is dict and set(p) == {
            "engine_id", "codec", "source_sha256", "source_commit",
            "cutlet_names", "month_names", "source_mapping_independently_attested"
        }, "decoder profile has invalid fields")
        e = p["engine_id"]
        require(type(e) is str and e in expected and e not in result,
                "decoder profile missing, duplicate or not for selected engine")
        require(p["codec"] in CODECS, "native raw format unsupported; must block")
        require(p["source_mapping_independently_attested"] is False,
                "self-reported profile cannot attest original source mappings")
        require(p["source_sha256"] == descriptors[e]["source_sha256"] and
                p["source_commit"] == descriptors[e]["provenance"]["source_commit"],
                "decoder profile not bound to declared source commit and SHA")
        groups = (p["cutlet_names"], p["month_names"])
        require(all(type(g) is list for g in groups) and
                [len(g) for g in groups] == [17, 47],
                "native names require all 17 cutlet and 47 month labels")
        for names in groups:
            require(all(type(n) is str and n and n.strip() == n and
                        "\x00" not in n and "\r" not in n and "\n" not in n
                        for n in names) and len(set(names)) == len(names),
                    "native name catalog has missing, repeated or invalid labels")
        maps = {"cutlets": p["cutlet_names"], "months": p["month_names"]}
        require(hashlib.sha256(canonical(maps)).hexdigest() ==
                descriptors[e]["name_map_sha256"],
                "native language map bytes not tied to plan name_map_sha256")
        result[e] = {
            "codec": CODECS[p["codec"]],
            "cutlets": {name: i + 1 for i, name in enumerate(p["cutlet_names"])},
            "months": {name: i + 1 for i, name in enumerate(p["month_names"])},
            "profile_sha256": hashlib.sha256(canonical(p)).hexdigest(),
        }
    require(set(result) == expected, "not all selected engines have native decoders")
    return result


def replay(plan: dict, manifest: dict, profiles: dict) -> dict:
    """Re-evaluate v149 and then replay every source-native row semantically.

    The caller supplies exact native raw and normalized files. Bytes read
    twice are compared to the v149 hashes to catch evidence changing between
    phases. All outputs explicitly deny original execution attestation.
    """
    fixed = {
        "schema": SCHEMA,
        "halt_new_native_soak_dispatch": True,
        "original_converters_executed": 0,
        "original_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "native_source_lineage_attested": False,
        "native_process_execution_attested": False,
        "native_name_maps_independently_attested": False,
        "official_soak_10000_pass": False,
    }
    try:
        v149 = audit_v149(plan, manifest)
        require(v149.get("status") in REPORT_STATES,
                "v149 raw-byte / receipt / complete-year gate blocked: " +
                str(v149.get("error", v149.get("status"))))
        decoders = validate_profiles(plan, manifest, profiles)
        reports = {a["engine_id"]: a for a in v149["raw_evidence_receipts"]}
        require(set(reports) == set(decoders),
                "upstream v149 receipt inventory lacks either engine")
        calc = plan["calculation_day"]
        seen: set[tuple[int, int]] = set()
        rows_total = 0
        for engine in (manifest["engine_a"], manifest["engine_b"]):
            cfg = decoders[engine]
            evidence = reports[engine]["chunks"]
            bundles = manifest["bundles"][engine]
            require(len(evidence) == len(bundles),
                    "upstream receipt inventory changed")
            global_row = 0
            for bundle, receipt in zip(bundles, evidence):
                require(bundle["ordinal"] == receipt["ordinal"],
                        "chunk number changed between audit phases")
                raw = file_bytes(bundle["raw_path"], 64 * 1024 * 1024, seen)
                normalized = file_bytes(bundle["normalized_path"], 64 * 1024 * 1024, seen)
                rb = file_bytes(bundle["receipt_path"], 256 * 1024, seen)
                require(hashlib.sha256(raw).hexdigest() ==
                        receipt["raw_stdout_sha256"] and
                        hashlib.sha256(normalized).hexdigest() ==
                        receipt["normalized_chunk_sha256"] and
                        hashlib.sha256(rb).hexdigest() ==
                        receipt["receipt_sha256"],
                        "evidence changed between v149 receipt check and semantic replay")
                raw_lines = raw.splitlines(keepends=True)
                norm_lines = normalized.splitlines(keepends=True)
                require(len(raw_lines) == len(norm_lines),
                        "raw/normalized semantic row count changed")
                first = int(receipt["first_target_day"])
                for offset, (raw_line, norm_line) in enumerate(zip(raw_lines, norm_lines)):
                    global_row += 1
                    try:
                        verify_pair(
                            cfg["codec"], raw_line, norm_line,
                            cfg["cutlets"], cfg["months"], calc, str(first + offset)
                        )
                    except (ValueError, TypeError, KeyError, UnicodeError) as exc:
                        raise ValueError(
                            f"engine {engine} row {global_row}: "
                            "native raw semantics do not match normalized output: " +
                            str(exc)
                        ) from exc
                rows_total += len(raw_lines)
            require(global_row == reports[engine]["raw_bound_rows"],
                    "semantic replay did not cover entire engine year")
        require(rows_total == 2 * v149["total_day_pairs"],
                "semantic replay did not cover both full years")
        return {
            **fixed, "status": REPORT_STATES[v149["status"]],
            "v149_upstream_status": v149["status"],
            "year": v149["year"],
            "engine_a": manifest["engine_a"],
            "engine_b": manifest["engine_b"],
            "semantic_rows_checked": rows_total,
            "semantic_day_pairs_checked": v149["total_day_pairs"],
            "native_profile_sha256": {
                engine: cfg["profile_sha256"] for engine, cfg in decoders.items()
            },
            "first_numeric_difference": v149.get("first_numeric_field_difference"),
            "first_mismatch_target_day": v149.get("first_mismatch_target_day"),
            "all_source_to_normalized_fields_replayed": True,
            "native_source_mapping_supported_only_for_two_v018_codecs": True,
            "official_native_soak_certification": False,
        }
    except (ValueError, TypeError, OSError, UnicodeError, KeyError) as exc:
        return {**fixed, "status": "INVALID_SEMANTIC_EVIDENCE",
                "error": str(exc), "all_source_to_normalized_fields_replayed": False,
                "semantic_day_pairs_checked": 0}


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--plan", type=Path, required=True)
    cli.add_argument("--evidence-manifest", type=Path, required=True)
    cli.add_argument("--decoder-profiles", type=Path, required=True)
    cli.add_argument("--report", type=Path, required=True)
    args = cli.parse_args()
    try:
        result = replay(
            parse_json(args.plan.read_bytes()),
            parse_json(args.evidence_manifest.read_bytes()),
            parse_json(args.decoder_profiles.read_bytes())
        )
    except (ValueError, OSError, UnicodeError) as exc:
        result = {"schema": SCHEMA, "status": "INVALID_SEMANTIC_EVIDENCE",
                  "error": str(exc), "halt_new_native_soak_dispatch": True,
                  "original_converters_executed": 0,
                  "original_years_certified": 0,
                  "official_soak_10000_pass": False}
    with args.report.open("xb") as output:
        output.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    # The return code signals usable informational evidence only.
    return 0 if result["status"] in (
        "SEMANTICALLY_EQUAL_UNCERTIFIED",
        "SEMANTICALLY_REPLAYED_FIRST_DIFFERENCE"
    ) else 2


if __name__ == "__main__":
    raise SystemExit(main())
