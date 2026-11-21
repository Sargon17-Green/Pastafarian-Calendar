#!/usr/bin/env python3
"""v153: static source-to-v017-adapter check-only admission path witnesses.

Requires the two original transport adapter files at pinned Git blob bytes,
and the three exact historical reference source files validated by v151/v152.
The check-only path is inspected but NOT executed. This cannot prove native
process execution, top-level imported module safety, date correctness,
algorithm independence, or original full-year Soak readiness.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
from pathlib import Path
import re

from native_execution_receipt_v038 import canonical
from native_raw_pair_gate_v018 import git_blob
from soak_static_name_output_path_v152 import inspect as inspect_static_names

SCHEMA = "PASTAFARI_SOAK_STATIC_ADAPTER_ADMISSION_V153/1"
WRAPPER_GIT_BLOBS = {
    "REF-41": ("pilot_python_transport_v017.py",
               "8ef48bb40f1ae85dce4f137bdd15ef645aa149c9"),
    "REF-24": ("pilot_javascript_transport_v017.cjs",
               "3c91d2895a3b873d1402e2c254fd32bc5f93aeeb"),
}
RESOURCE_ADMISSION = "PASTAFARI_SOAK_RESOURCE_ADMITTED"
NO_PROCESS_SCOPE = "NO_ORIGINAL_PROCESS_STARTED_NO_NATIVE_DATE_CALLED"


def require(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def _function(tree: ast.Module, name: str) -> ast.FunctionDef:
    nodes = [v for v in tree.body
             if isinstance(v, (ast.FunctionDef, ast.AsyncFunctionDef))
             and v.name == name]
    require(len(nodes) == 1 and type(nodes[0]) is ast.FunctionDef,
            "missing, duplicate or async Python " + name)
    return nodes[0]


def _has_exact_test(node: ast.If, expr: str) -> bool:
    return ast.dump(node.test, include_attributes=False) == ast.dump(
        ast.parse(expr, mode="eval").body, include_attributes=False)


def check_python_wrapper(source: str) -> dict:
    tree = ast.parse(source)
    main = _function(tree, "main")
    _function(tree, "load_source")
    _function(tree, "produce")
    checks = [
        (name, token) for name, token in (
            ("source_sha", "(len(data), sha(data), blob(data))"),
            ("sha_claim", '(item["bytes"], item["sha256"], item["git_blob_sha1"])'),
            ("source_loader", "module_spec.loader.exec_module(module)"),
            ("original_class", "module.NormativeCalendar"),
            ("original_date_calculation", "cal.calendar_date_ids(c, t)"),
            ("raw_output_sha", '"source_raw_sha256": sha(raw_line)'),
            ("source_lock", 'pilot_two_engine_source_locks_v001.json'),
        ) if token not in source
    ]
    require(not checks, "Python source/adapter binding missing: " + str(checks))
    body = main.body
    checkonly = [
        i for i, v in enumerate(body)
        if type(v) is ast.If and _has_exact_test(v, "a.check_only")
    ]
    require(len(checkonly) == 1, "Python check-only condition absent or shadowed")
    idx = checkonly[0]
    only = body[idx]
    require(any(type(x) is ast.Return
                and type(x.value) is ast.Constant
                and x.value.value == 0 for x in only.body),
            "Python check-only branch does not return before date work")
    require(not any(isinstance(x, ast.Call)
                    and (isinstance(x.func, ast.Name) and x.func.id == "produce"
                         or isinstance(x.func, ast.Attribute)
                         and x.func.attr in ("calendar_date_ids", "calendar_date"))
                    for x in ast.walk(only)),
            "Python check-only branch attempts native date computation")
    admission = [
        i for i, v in enumerate(body)
        if type(v) is ast.If
        and RESOURCE_ADMISSION in (ast.get_source_segment(source, v.test) or "")
    ]
    require(len(admission) == 1 and idx < admission[0],
            "Python resource admission not after check-only return")
    branch = body[admission[0]]
    require(any(isinstance(x, ast.Raise) for x in branch.body),
            "Python missing-resource path fails to abort")
    before = ast.Module(body=body[:admission[0]+1], type_ignores=[])
    require(not any(isinstance(v, ast.Call) and (
                        isinstance(v.func, ast.Name) and v.func.id == "produce" or
                        isinstance(v.func, ast.Attribute) and
                        v.func.attr in ("calendar_date_ids", "calendar_date"))
                    for v in ast.walk(before)),
            "Python original date call occurs before resource admission")
    after = ast.Module(body=body[admission[0]+1:], type_ignores=[])
    require(any(isinstance(v, ast.Call) and
                isinstance(v.func, ast.Name) and v.func.id == "produce"
                for v in ast.walk(after)),
            "Python native producer is not reachable only after admission")
    require(source.find('module, engine, source = load_source(') >= 0,
            "Python source lock not loaded before check-only decision")
    return {
        "engine_id": "REF-41",
        "adapter": "pilot_python_transport_v017.py",
        "static_check_only_guard_precedes_resource_admission": True,
        "static_native_producer_after_resource_admission": True,
        "static_original_name_binding": True,
        "dynamic_original_execution_attested": False,
    }


def check_javascript_wrapper(source: str) -> dict:
    require(source.count("function loadSource(") == 1
            and source.count("function produce(") == 1
            and source.count("function main() {") == 1,
            "JavaScript source loader/producer/main not uniquely declared")
    required = (
        "pilot_two_engine_source_locks_v001.json",
        "hash(data) !== item.sha256",
        "gitBlob(data) !== item.git_blob_sha1",
        "const native = require(engineFile);",
        "const lang = require(catalogFile);",
        "lang.SourceLanguageCatalog !== native.SourceLanguageCatalog",
        "const tuple = entry.native.calendarDate(c, t);",
        "entry.indexFromNative('cutlet', cutletName)",
        "entry.indexFromNative('month', monthName)",
        "source_raw_sha256: hash(rawLine)",
        "const entry = loadSource(path.resolve(args['sources-root']));",
        "if (process.env.PASTAFARI_SOAK_RESOURCE_ADMITTED !== '1')",
        "const [rawLine, normLine] = produce(entry, c, t);",
        "if (require.main === module)",
    )
    require(all(x in source for x in required),
            "JavaScript adapter lacks pinned source, raw name or resource guard binding")
    start = source.index("function main() {")
    end = source.index("module.exports = Object.freeze(", start)
    main = source[start:end]
    only = "if (args['check-only']) {"
    admission = "if (process.env.PASTAFARI_SOAK_RESOURCE_ADMITTED !== '1')"
    require(main.count(only) == 1 and main.count(admission) == 1,
            "JavaScript check-only or resource guard missing/duplicated")
    i = main.index(only)
    j = main.index(admission)
    require(i < j, "JavaScript check-only must return before resource admission")
    pre = main[:j]
    checkblock = pre[i:]
    require("converter_calls: 0" in checkblock and
            re.search(r"\breturn;", checkblock) is not None and
            "SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY" in checkblock,
            "JavaScript check-only path no longer zero-date return")
    require("produce(entry" not in pre and
            ".calendarDate(" not in pre,
            "JavaScript original date call appears before resource admission")
    require(main.find("const [rawLine, normLine] = produce(entry, c, t);") > j,
            "JavaScript producer not guarded by resource admission")
    return {
        "engine_id": "REF-24",
        "adapter": "pilot_javascript_transport_v017.cjs",
        "static_check_only_guard_precedes_resource_admission": True,
        "static_native_producer_after_resource_admission": True,
        "static_original_name_binding": True,
        "dynamic_original_execution_attested": False,
    }


def inspect(sources_root: Path, coordinator_root: Path | None = None) -> dict:
    fixed = {
        "schema": SCHEMA,
        "status": "INVALID_STATIC_ADMISSION_EVIDENCE",
        "halt_new_native_soak_dispatch": True,
        "original_converters_executed": 0,
        "source_processes_started": 0,
        "original_full_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "source_module_import_top_level_safe_not_proven": True,
        "native_execution_proven": False,
        "dynamic_loader_behavior_proven": False,
        "original_calendar_correctness_proven": False,
        "official_10000_year_soak_pass": False,
    }
    try:
        upstream = inspect_static_names(sources_root)
        require(upstream.get("status") ==
                "SOURCE_LOCKED_NATIVE_NAME_OUTPUT_CALLSITES_WITNESSED_UNCERTIFIED",
                "v152 real source byte lock/callsite gate failed: " +
                str(upstream.get("error", upstream.get("status"))))
        root = (coordinator_root if coordinator_root is not None
                else Path(__file__).resolve().parent)
        code = {}
        for e, (file, lock) in WRAPPER_GIT_BLOBS.items():
            fp = root / file
            require(not fp.is_symlink() and fp.is_file(),
                    "transport adapter not a regular non-symlink file")
            data = fp.read_bytes()
            require(git_blob(data) == lock,
                    "pinned transport adapter Git blob differs: " + e)
            code[e] = data.decode("utf-8")
        py = check_python_wrapper(code["REF-41"])
        js = check_javascript_wrapper(code["REF-24"])
        return {
            **fixed,
            "status": "PINNED_ADAPTER_STATIC_CHECKONLY_PATHS_VERIFIED_UNCERTIFIED",
            "verified_historical_reference_source_files": 3,
            "pinned_adapter_git_blob_sha1": {
                e: lock for e, (_, lock) in WRAPPER_GIT_BLOBS.items()
            },
            "source_historical_catalog_sha256": {
                e: v["catalog_sha256"] for e, v
                in upstream["source_derived_catalogs"].items()
            },
            "static_adapter_witnesses": [py, js],
            "scope": NO_PROCESS_SCOPE,
        }
    except (OSError, ValueError, TypeError, KeyError, SyntaxError,
            UnicodeError, AttributeError, IndexError) as exc:
        return {**fixed, "error": str(exc)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = inspect(args.sources_root)
    with args.report.open("xb") as out:
        out.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] == \
        "PINNED_ADAPTER_STATIC_CHECKONLY_PATHS_VERIFIED_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
