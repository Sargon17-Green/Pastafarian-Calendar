#!/usr/bin/env python3
"""v152: static source-locked name-return callsite witnesses for REF-41/24.

Source files MUST first pass the v151 SHA-256 + Git blob + exact lock checks.
This checks source text/AST only, without importing or running either engine,
and cannot prove dynamic callgraph reachability, process provenance, algorithm
independence, or calendar correctness. Unsupported engines fail closed.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
from pathlib import Path
import re

from native_execution_receipt_v038 import canonical
from soak_source_derived_names_v151 import extract_names, pinned_lock, PATH_FOLDER
from soak_scope_coverage_v127 import parse_json

SCHEMA = "PASTAFARI_SOAK_STATIC_NAME_OUTPUT_PATH_V152/1"

PY_RETURN = """class NormativeCalendar:
    def calendar_date(self, calculation_day: int, target_day: int) -> DateResult:
        ids = self.calendar_date_ids(calculation_day, target_day)
        return DateResult(
            ids.year_number,
            FROZEN_CUTLET_NAMES[ids.cutlet_name_index - 1],
            ids.day_in_cutlet,
            FROZEN_MONTH_NAMES[ids.month_name_index - 1],
            ids.day_in_month,
        )
"""
PY_TEMPLATE = ast.parse(PY_RETURN).body[0].body[0]
JS_IMPORT = "const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');"
JS_EXPORT = "module.exports = Object.freeze({"
JS_RETURN = re.compile(
    r"return\s+Object\.freeze\(\[\s*"
    r"year\.number\s*,\s*"
    r"textByCanonicalIndex\('cutlet',\s*chosenCutlet\.nameIndex\)\s*,\s*"
    r"dayInCutlet\s*,\s*"
    r"textByCanonicalIndex\('month',\s*monthNameIndex\)\s*,\s*"
    r"dayInMonth\s*\]\);",
    re.MULTILINE
)


def require(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def python_return_witness(source: str) -> dict:
    """Verify the exact native named date function AST (not date calculation)."""
    tree = ast.parse(source)
    classes = [n for n in tree.body
               if isinstance(n, ast.ClassDef) and n.name == "NormativeCalendar"]
    require(len(classes) == 1, "Python native NormativeCalendar class not unique")
    cls = classes[0]
    methods = [n for n in cls.body if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))]
    named = [n for n in methods if n.name == "calendar_date"]
    ids = [n for n in methods if n.name == "calendar_date_ids"]
    require(len(named) == 1 and len(ids) == 1,
            "Python native date-name and index functions not unique")
    require(type(named[0]) is ast.FunctionDef,
            "Python native calendar_date is not synchronous")
    require(ast.dump(named[0], include_attributes=False) ==
            ast.dump(PY_TEMPLATE, include_attributes=False),
            "Python named date function does not bind return positions to pinned native name tables")
    return {
        "engine_id": "REF-41",
        "method": "NormativeCalendar.calendar_date",
        "index_method": "NormativeCalendar.calendar_date_ids",
        "cutlet_lookup": "FROZEN_CUTLET_NAMES[ids.cutlet_name_index - 1]",
        "month_lookup": "FROZEN_MONTH_NAMES[ids.month_name_index - 1]",
        "field_order": ["year", "cutlet_native_name", "day_in_cutlet",
                        "month_native_name", "day_in_month"],
        "ast_callsite_witness": True,
    }


def js_return_witness(engine_source: str, catalog_source: str) -> dict:
    """Check exact source callsite and frozen catalog lookup path, not runtime."""
    require(engine_source.count("function calendarDate(") == 1,
            "JavaScript date function not unique")
    require(engine_source.count(JS_IMPORT) == 1,
            "JavaScript named source catalog import not unique")
    require(engine_source.count(JS_EXPORT) == 1 and
            re.search(r"\bcalendarDate\b", engine_source.split(JS_EXPORT, 1)[1])
            is not None, "JavaScript date function not exported")
    # This is a pinned-source lexical witness, not a general JavaScript AST
    # analyzer. v151 must authenticate ALL THREE exact source file bytes.
    start = engine_source.index("function calendarDate(")
    end = engine_source.index(JS_EXPORT, start)
    body = engine_source[start:end]
    require(len(JS_RETURN.findall(body)) == 1 and
            body.count("return Object.freeze([") == 1,
            "JavaScript native date tuple names not sourced via pinned catalog")
    require(catalog_source.count("function textByCanonicalIndex(") == 1,
            "JavaScript native catalog lookup function not unique")
    require(catalog_source.count("const SourceLanguageCatalog = Object.freeze({") == 1,
            "JavaScript frozen source catalog not unique")
    catbody = catalog_source.split("function textByCanonicalIndex(", 1)[1]
    require(catbody.count("return rows[canonicalIndex - 1].text;") == 1
            and "SourceLanguageCatalog.cutlets" in catbody
            and "SourceLanguageCatalog.months" in catbody
            and "module.exports = Object.freeze({ SourceLanguageCatalog, textByCanonicalIndex });"
            in catbody,
            "JavaScript text lookup not linked to frozen native catalog")
    return {
        "engine_id": "REF-24",
        "method": "calendarDate(calculationDay,targetDay)",
        "cutlet_lookup": "textByCanonicalIndex('cutlet', chosenCutlet.nameIndex)",
        "month_lookup": "textByCanonicalIndex('month', monthNameIndex)",
        "catalog_getter": "textByCanonicalIndex",
        "field_order": ["year", "cutlet_native_name", "day_in_cutlet",
                        "month_native_name", "day_in_month"],
        "source_callsite_lexical_witness": True,
    }


def inspect(source_root: Path) -> dict:
    fixed = {
        "schema": SCHEMA, "original_converters_executed": 0,
        "original_full_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "halt_new_native_soak_dispatch": True,
        "original_source_execution_attested": False,
        "calendar_correctness_attested": False,
        "algorithmic_independence_attested": False,
        "dynamic_control_flow_proven": False,
        "official_10000_year_soak_pass": False,
    }
    try:
        lock = pinned_lock()
        maps = extract_names(source_root)
        source = {}
        for e in lock["engines"]:
            folder = PATH_FOLDER[e["id"]]
            for f in e["sources"]:
                path = source_root / folder / e["commit"] / f["path"]
                data = path.read_bytes()
                require(len(data) == f["bytes"] and
                        hashlib.sha256(data).hexdigest() == f["sha256"],
                        "source bytes changed between v151 extraction and v152 callsite verification")
                source[e["id"], f["path"]] = data.decode("utf-8")
        py = python_return_witness(source["REF-41", "tests/normative_reference.py"])
        js = js_return_witness(source["REF-24", "tests/normative-reference.js"],
                               source["REF-24", "src/source-language-catalog.js"])
        require(set(maps) == {"REF-41", "REF-24"} and
                len(maps["REF-41"]["catalog"]["cutlets"]) ==
                len(maps["REF-24"]["catalog"]["cutlets"]) == 17 and
                len(maps["REF-41"]["catalog"]["months"]) ==
                len(maps["REF-24"]["catalog"]["months"]) == 47,
                "v151 source map extraction not complete")
        return {
            **fixed,
            "status": "SOURCE_LOCKED_NATIVE_NAME_OUTPUT_CALLSITES_WITNESSED_UNCERTIFIED",
            "source_files_sha256_and_git_blob_verified": 3,
            "source_derived_catalogs": {
                e: {"catalog_sha256": x["catalog_sha256"], "source_commit": x["source_commit"],
                    "cutlet_count": len(x["catalog"]["cutlets"]),
                    "month_count": len(x["catalog"]["months"])}
                for e, x in maps.items()
            },
            "static_output_paths": [py, js],
            "witness_scope": "ONE_PINNED_PYTHON_METHOD_AST_AND_ONE_PINNED_JS_LEXICAL_CALLSITE",
        }
    except (OSError, ValueError, UnicodeError, KeyError, TypeError, SyntaxError,
            IndexError, AttributeError) as exc:
        return {**fixed, "status": "INVALID_STATIC_SOURCE_CALLSITE_EVIDENCE",
                "error": str(exc)}


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--sources-root", type=Path, required=True)
    cli.add_argument("--report", type=Path, required=True)
    args = cli.parse_args()
    result = inspect(args.sources_root)
    with args.report.open("xb") as out:
        out.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] == \
        "SOURCE_LOCKED_NATIVE_NAME_OUTPUT_CALLSITES_WITNESSED_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
