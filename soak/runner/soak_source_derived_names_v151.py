#!/usr/bin/env python3
"""v151 source-derived name maps for exactly two historically SHA-locked references.

This gate parses immutable source BYTES; it does not execute date converters.
Real source mappings are checked against the existing pilot source lock, and
v150 is replayed using derived (not self-supplied) profiles. This is a limited
source-byte authenticity test, NOT original-execution or independent-algorithm
certification. Unsupported engines fail closed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import native_raw_pair_gate_v018 as pilot
from native_execution_receipt_v038 import canonical
import soak_native_semantic_replay_v150 as semantic
from soak_scope_coverage_v127 import parse_json

SCHEMA = "PASTAFARI_SOAK_SOURCE_DERIVED_NAMES_V151/1"
LOCK_PATH = Path(__file__).resolve().parents[1] / "control/pilot_two_engine_source_locks_v001.json"
LOCK_GIT_BLOB_SHA1 = "db03a1c5a367c252fb07ba74c78cb7b2948048d5"
EXPECTED_IDS = frozenset(("REF-41", "REF-24"))
SOURCE_CODEC = {"REF-41": "SOURCE_NATIVE_JSON_IDS_V018",
                "REF-24": "SOURCE_NATIVE_JSON_NAMED_TUPLE_V018"}
SOURCE_FILES = {
    "REF-41": ("tests/normative_reference.py",),
    "REF-24": ("tests/normative-reference.js", "src/source-language-catalog.js"),
}
PATH_FOLDER = {"REF-41": "Python-Turkce", "REF-24": "JavaScript-Interlingue"}


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def unique(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result = {}
    for k, v in pairs:
        require(k not in result, "duplicate source-lock JSON key: " + k)
        result[k] = v
    return result


def reject_constant(name: str) -> None:
    raise ValueError("invalid JSON constant in source lock: " + name)


def pinned_lock() -> dict:
    """Exact committed lock bytes, independent of any incoming profile."""
    data = LOCK_PATH.read_bytes()
    require(pilot.git_blob(data) == LOCK_GIT_BLOB_SHA1,
            "pilot source-lock file bytes changed")
    lock = json.loads(data.decode("utf-8"), object_pairs_hook=unique,
                      parse_constant=reject_constant)
    require(type(lock) is dict
            and lock.get("schema") == "PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1"
            and lock.get("immutable") is True
            and lock.get("main_changes_permitted") is False
            and lock.get("converter_execution") is False
            and lock.get("full_year_run") is False
            and lock.get("semantics_validated") is False
            and lock.get("syntactic_only") is True,
            "pilot lock safety/certification contract changed")
    engines = lock.get("engines")
    require(type(engines) is list and len(engines) == 2
            and {x["id"] for x in engines} == EXPECTED_IDS,
            "pilot source lock must list exactly two known references")
    for e in engines:
        require(e["repository"] == "Sargon17-Green/Pastafarian-Calendar"
                and type(e["sources"]) is list
                and tuple(x["path"] for x in e["sources"]) == SOURCE_FILES[e["id"]],
                "pilot source lock changed engine, repository or paths")
    return lock


def extract_names(source_root: Path) -> dict[str, dict]:
    """Strict existing SHA256+Git blob verifier before AST/JS catalog parsing."""
    lock = pinned_lock()
    original_pilot_lock = pilot.LOCK
    # v018's source reader uses its module-global lock path. This v151 lock
    # is checked first against the committed Git blob to prevent reassignment.
    require(original_pilot_lock.resolve() == LOCK_PATH.resolve(),
            "source reader lock path unexpectedly redirected")
    result = {}
    for e in lock["engines"]:
        eid = e["id"]
        verified, source = pilot.verify_locked_sources(source_root, eid)
        require(verified == e, "source reader returned a different locked engine")
        maps = pilot.name_maps(eid, source)
        catalogs = []
        for mp, count in zip(maps, (17, 47)):
            by_index = [None] * count
            for name, index in mp.items():
                require(type(index) is int and 1 <= index <= count
                        and by_index[index - 1] is None,
                        "source catalog index invalid/duplicate")
                by_index[index - 1] = name
            require(all(type(name) is str and name and name.strip() == name
                        and "\n" not in name and "\r" not in name and "\x00" not in name
                        for name in by_index),
                    "source catalog contains empty/invalid label")
            catalogs.append(by_index)
        payload = {"cutlets": catalogs[0], "months": catalogs[1]}
        result[eid] = {
            "engine_id": eid,
            "source_commit": e["commit"],
            "source_sha256": e["sources"][0]["sha256"],
            "source_file_sha256": {
                x["path"]: x["sha256"] for x in e["sources"]
            },
            "source_file_git_blob_sha1": {
                x["path"]: x["git_blob_sha1"] for x in e["sources"]
            },
            "catalog": payload,
            "catalog_sha256": hashlib.sha256(canonical(payload)).hexdigest(),
            "codec": SOURCE_CODEC[eid],
            "scope": "EXACT_PINNED_PILOT_REFERENCES_ONLY_NOT_INDEPENDENCE_CERTIFIED",
        }
    return result


def source_profiles(plan: dict, manifest: dict, names: dict) -> dict:
    require(type(manifest) is dict
            and manifest.get("engine_a") in EXPECTED_IDS
            and manifest.get("engine_b") in EXPECTED_IDS
            and manifest["engine_a"] != manifest["engine_b"],
            "only the two pinned reference-engine IDs are supported")
    engines = {e["id"]: e for e in plan["engines"]}
    require(EXPECTED_IDS.issubset(engines),
            "source-bound test requires both reference engine descriptors")
    lock = pinned_lock()
    byid = {e["id"]: e for e in lock["engines"]}
    profiles = []
    for eid in (manifest["engine_a"], manifest["engine_b"]):
        d, locked, src = engines[eid], byid[eid], names[eid]
        prov = d["provenance"]
        require(d["source_sha256"] == src["source_sha256"]
                and d["name_map_sha256"] == src["catalog_sha256"]
                and prov["original_source_sha256"] == src["source_sha256"]
                and prov["source_commit"] == locked["commit"]
                and prov["repository"] == locked["repository"]
                and prov["source_path"] == SOURCE_FILES[eid][0]
                and prov["native_entrypoint"] == locked["entrypoint"]
                and prov["source_class"] == "reference"
                and prov["execution_method"] == "unchanged_reference_Fct"
                and prov["derived_from"] is None,
                "plan source or native names not bound to the pinned original reference file")
        profiles.append({
            "engine_id": eid, "codec": SOURCE_CODEC[eid],
            "source_sha256": src["source_sha256"],
            "source_commit": locked["commit"],
            "cutlet_names": src["catalog"]["cutlets"],
            "month_names": src["catalog"]["months"],
            "source_mapping_independently_attested": False,
        })
    return {"schema": semantic.SCHEMA, "engines": profiles}


def audit(plan: dict, manifest: dict, source_root: Path,
          supplied_profiles: dict | None = None) -> dict:
    fixed = {
        "schema": SCHEMA,
        "halt_new_native_soak_dispatch": True,
        "original_converters_executed": 0,
        "original_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "original_process_execution_attested": False,
        "original_algorithmic_independence_attested": False,
        "original_calendar_correctness_attested": False,
        "official_soak_10000_pass": False,
    }
    try:
        names = extract_names(source_root)
        profiles = source_profiles(plan, manifest, names)
        if supplied_profiles is not None:
            require(canonical(supplied_profiles) == canonical(profiles),
                    "supplied semantic profile differs from source-derived maps")
        verdict = semantic.replay(plan, manifest, profiles)
        allowed = {
            "SEMANTICALLY_EQUAL_UNCERTIFIED": "SOURCE_LOCKED_SEMANTIC_EQUAL_UNCERTIFIED",
            "SEMANTICALLY_REPLAYED_FIRST_DIFFERENCE":
                "SOURCE_LOCKED_REPLAYED_FIRST_DIFFERENCE_UNCERTIFIED",
        }
        require(verdict["status"] in allowed,
                "source-locked semantic replay rejected: " +
                str(verdict.get("error", verdict["status"])))
        return {
            **fixed, "status": allowed[verdict["status"]],
            "source_lock_git_blob_sha1": LOCK_GIT_BLOB_SHA1,
            "source_catalogs": names,
            "source_code_files_bytes_verified": 3,
            "source_native_rows_replayed": verdict["semantic_rows_checked"],
            "source_native_day_pairs_checked": verdict["semantic_day_pairs_checked"],
            "first_numeric_difference": verdict.get("first_numeric_difference"),
            "first_mismatch_target_day": verdict.get("first_mismatch_target_day"),
            "native_dictionary_derived_from_verified_source_bytes": True,
            "real_process_execution_proven": False,
        }
    except (OSError, ValueError, UnicodeError, SyntaxError, TypeError, KeyError,
            IndexError, AttributeError) as exc:
        return {**fixed, "status": "INVALID_SOURCE_BOUND_EVIDENCE",
                "error": str(exc),
                "native_dictionary_derived_from_verified_source_bytes": False}


def source_only(source_root: Path) -> dict:
    """Usable with real GitHub pinned source bytes, without running any F(c,t)."""
    fixed = {"schema": SCHEMA, "original_converters_executed": 0,
             "original_years_certified": 0, "official_soak_10000_pass": False,
             "halt_new_native_soak_dispatch": True,
             "independent_original_algorithms_certified": 0}
    try:
        names = extract_names(source_root)
        return {**fixed, "status": "PINNED_SOURCE_CATALOG_BYTES_VERIFIED_UNCERTIFIED",
                "source_lock_git_blob_sha1": LOCK_GIT_BLOB_SHA1,
                "source_code_files_bytes_verified": 3,
                "source_catalogs": names}
    except (OSError, ValueError, UnicodeError, SyntaxError, TypeError, KeyError,
            IndexError, AttributeError) as exc:
        return {**fixed, "status": "INVALID_SOURCE_BOUND_EVIDENCE",
                "error": str(exc)}


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--sources-root", type=Path, required=True)
    cli.add_argument("--plan", type=Path)
    cli.add_argument("--evidence-manifest", type=Path)
    cli.add_argument("--user-profiles", type=Path)
    cli.add_argument("--report", type=Path, required=True)
    args = cli.parse_args()
    try:
        if args.plan is None and args.evidence_manifest is None and args.user_profiles is None:
            result = source_only(args.sources_root)
            allowed = {"PINNED_SOURCE_CATALOG_BYTES_VERIFIED_UNCERTIFIED"}
        else:
            require(args.plan is not None and args.evidence_manifest is not None,
                    "source-bound comparison needs both plan and manifest")
            result = audit(
                parse_json(args.plan.read_bytes()),
                parse_json(args.evidence_manifest.read_bytes()),
                args.sources_root,
                parse_json(args.user_profiles.read_bytes())
                if args.user_profiles is not None else None
            )
            allowed = {"SOURCE_LOCKED_SEMANTIC_EQUAL_UNCERTIFIED",
                       "SOURCE_LOCKED_REPLAYED_FIRST_DIFFERENCE_UNCERTIFIED"}
    except (OSError, ValueError, TypeError, UnicodeError, KeyError) as exc:
        result = {"schema": SCHEMA, "status": "INVALID_SOURCE_BOUND_EVIDENCE",
                  "error": str(exc), "original_converters_executed": 0,
                  "original_years_certified": 0, "official_soak_10000_pass": False,
                  "halt_new_native_soak_dispatch": True}
        allowed = set()
    with args.report.open("xb") as f:
        f.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] in allowed else 2


if __name__ == "__main__":
    raise SystemExit(main())
