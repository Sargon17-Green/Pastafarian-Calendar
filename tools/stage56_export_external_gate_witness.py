#!/usr/bin/env python3
"""Stage56 QA-only external gate witnesses; never a PHP production attestation.

Reads the canonical Python implementation from a clean exact-commit checkout,
checks a separately pinned external reference JSON, and records every gate
position needed by the opt-in PHP provider for years 4999/5000/5001.
The Python implementation and its own output are NOT an independent oracle.
"""
from __future__ import annotations

import argparse
import hashlib
import hmac
import importlib.util
import json
from pathlib import Path
import re
import sys

from stage56_export_external_canonical_reference import (
    CANONICAL_REPO, JS_REFERENCE, PROJECT, PROVIDER,
    atomic_write, canonical_bytes, git, source_binding,
)

STATUS = "EXTERNAL_GATE_WITNESS_QA_ONLY_NOT_PHP_PRODUCTION"
SOURCE_COMMIT = "cc2cf0b422757a5e7c33218ce30cffa8f99c6786"
ORIGINS = {
    f"https://github.com/{CANONICAL_REPO}",
    f"https://github.com/{CANONICAL_REPO}.git",
    f"git@github.com:{CANONICAL_REPO}.git",
}


def validate_reference(reference: object, commit: str, calculation_jdn: int,
                       source_digest: str) -> list[dict]:
    if not isinstance(reference, dict) or reference.get("project_id") != PROJECT or \
            reference.get("status") != "EXTERNAL_REFERENCE_NOT_PHP_PROVIDER":
        raise ValueError("reference identity or source type mismatch")
    source = reference.get("source")
    if not isinstance(source, dict) or source.get("kind") != "external_canonical_reference" or \
            source.get("source_commit") != commit:
        raise ValueError("reference source commit mismatch")
    provider = source.get("provider")
    if not isinstance(provider, dict) or provider.get("path") != PROVIDER or \
            provider.get("sha256") != source_digest:
        raise ValueError("reference source bytes mismatch")
    if reference.get("calculation_jdn") != calculation_jdn or \
            not isinstance(calculation_jdn, int) or isinstance(calculation_jdn, bool):
        raise ValueError("reference calculation day mismatch")
    anchor = reference.get("year5000_anchor")
    years = reference.get("years")
    if not isinstance(anchor, dict) or anchor.get("number") != 5000 or \
            anchor.get("calculation_jdn") != calculation_jdn or \
            not isinstance(years, list) or len(years) != 3 or \
            [x.get("number") for x in years if isinstance(x, dict)] != [4999, 5000, 5001]:
        raise ValueError("reference contextual anchor/years mismatch")
    if source.get("anchor_sha256") != hashlib.sha256(canonical_bytes(anchor)).hexdigest():
        raise ValueError("reference anchor digest mismatch")
    return years


def assemble_years(state: object, engine: object, reference: dict,
                   calculation_jdn: int) -> tuple[dict, list[dict], dict[str, int]]:
    anchor_year = state.get_year_5000()
    originals = [state.previous_year(anchor_year), anchor_year,
                 state.next_year(anchor_year)]
    expected = reference["years"]
    anchor = reference["year5000_anchor"]
    if anchor.get("open_gate_index") != anchor_year.open_index or \
            anchor.get("close_gate_index") != anchor_year.close_index or \
            anchor.get("open_gate_day") != anchor_year.start_jdn - 1:
        raise ValueError("contextual Year5000 anchor differs")
    result: list[dict] = []
    gates: dict[str, int] = {}
    for y, r, number in zip(originals, expected, (4999, 5000, 5001), strict=True):
        if y.number != number or r.get("number") != number or \
                r.get("open_gate_day") != y.start_jdn - 1 or \
                r.get("close_gate_day") != y.end_jdn:
            raise ValueError("external year boundary differs")
        if not (6 <= y.close_index - y.open_index <= 137) or \
                not (252 <= y.end_jdn - y.start_jdn + 1 <= 5778):
            raise ValueError("year interval violates bounded provider contract")
        structure = state.get_structure(y)
        if r.get("month_lengths") != list(structure.month_lengths) or \
                r.get("month_weaving") != [m + 1 for m in structure.month_weave]:
            raise ValueError("reference structure differs from executed canonical source")
        for index in range(y.open_index, y.close_index + 1):
            day = engine.gate_position(index)
            key = str(index)
            if key in gates and gates[key] != day:
                raise ValueError("overlapping gate witness mismatch")
            gates[key] = day
        if gates[str(y.open_index)] != y.start_jdn - 1 or \
                gates[str(y.close_index)] != y.end_jdn:
            raise ValueError("gate witness does not match year endpoints")
        result.append({"number": number, "openGateIndex": y.open_index,
                       "closeGateIndex": y.close_index,
                       "openGateDay": y.start_jdn - 1,
                       "closeGateDay": y.end_jdn})
    for earlier, later in zip(result, result[1:]):
        if earlier["closeGateIndex"] != later["openGateIndex"] or \
                earlier["closeGateDay"] != later["openGateDay"]:
            raise ValueError("adjacent canonical years do not share a gate")
    if not (result[1]["openGateDay"] < calculation_jdn <= result[1]["closeGateDay"]):
        raise ValueError("calculation day is outside contextual Year5000")
    return result[1], result, gates


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--canonical-repo", type=Path, required=True)
    ap.add_argument("--source-commit", required=True)
    ap.add_argument("--calculation-jdn", type=int, required=True)
    ap.add_argument("--reference", type=Path, required=True)
    ap.add_argument("--reference-sha256", required=True)
    ap.add_argument("--output", type=Path, required=True)
    args = ap.parse_args()
    if args.source_commit != SOURCE_COMMIT or \
            not re.fullmatch(r"[a-f0-9]{64}", args.reference_sha256):
        raise ValueError("unapproved source commit or reference SHA")
    root = args.canonical_repo.resolve(strict=True)
    reference_path = args.reference.resolve(strict=True)
    output = args.output.resolve()
    if any(root == p or root in p.parents for p in (reference_path, output)):
        raise ValueError("inputs/outputs must be outside the canonical checkout")
    if git(root, "remote", "get-url", "origin").decode().strip() not in ORIGINS:
        raise ValueError("unexpected canonical source repository origin")
    if git(root, "rev-parse", "HEAD").decode().strip() != SOURCE_COMMIT:
        raise ValueError("canonical source checkout HEAD mismatch")
    if git(root, "status", "--porcelain", "--untracked-files=all").strip():
        raise ValueError("canonical source checkout is not clean")
    provider = source_binding(root, SOURCE_COMMIT, PROVIDER)
    js = source_binding(root, SOURCE_COMMIT, JS_REFERENCE)
    data = reference_path.read_bytes()
    if not hmac.compare_digest(
            hashlib.sha256(data).hexdigest(), args.reference_sha256):
        raise ValueError("external reference JSON SHA mismatch")
    reference = json.loads(data)
    validate_reference(reference, SOURCE_COMMIT, args.calculation_jdn,
                       provider["sha256"])
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location(
        "stage56_bound_external_gate_source", root / PROVIDER)
    if spec is None or spec.loader is None:
        raise ValueError("canonical Python source cannot load")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    anchor, years, positions = assemble_years(
        mod.CalculationState(args.calculation_jdn), mod, reference,
        args.calculation_jdn)
    if git(root, "status", "--porcelain", "--untracked-files=all").strip():
        raise ValueError("canonical checkout changed during source execution")
    document = {
        "project_id": PROJECT, "status": STATUS,
        "calculation_jdn": args.calculation_jdn,
        "source_commit": SOURCE_COMMIT,
        "reference_sha256": args.reference_sha256,
        "source_provider": provider,
        "source_js_reference": js,
        "year5000_anchor": anchor,
        "years": years,
        "gate_positions": positions,
        "independent_scroll_oracle": "NOT_ASSESSED_HERE",
        "php_production_export": "NOT_GENERATED_HERE",
    }
    encoded = canonical_bytes(document)
    atomic_write(output, encoded)
    atomic_write(output.with_suffix(output.suffix + ".sha256"),
                 f"{hashlib.sha256(encoded).hexdigest()}  {output.name}\n".encode())
    print(json.dumps({"status": STATUS, "source_commit": SOURCE_COMMIT,
                      "year_numbers": [r["number"] for r in years],
                      "gates": len(positions),
                      "sha256": hashlib.sha256(encoded).hexdigest()}, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, KeyError, TypeError, RuntimeError) as exc:
        print("STAGE56_GATE_WITNESS_REJECTED: " + str(exc), file=sys.stderr)
        raise SystemExit(2)
