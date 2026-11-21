#!/usr/bin/env python3
"""v154: exact-source import/require-time initialization inventory, no F(c,t).

v153 verifies historical three source files and two v017 transport adapters
are pinned. This gate identifies module-level precomputation and imported
decorator execution which occurs BEFORE check-only returns, even though no
calendar date F(c,t) is calculated. Source-level static observation is NOT a
performance measurement, an import side-effect safety proof, or provenance of
a live operating-system process. No native module or adapter is imported.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import json
from pathlib import Path
import re

from native_execution_receipt_v038 import canonical
from soak_source_derived_names_v151 import pinned_lock, PATH_FOLDER
from soak_static_adapter_admission_v153 import inspect as inspect_adapter

SCHEMA = "PASTAFARI_SOAK_IMPORT_TIME_INIT_INVENTORY_V154/1"
PY_ALLOWED_IMPORTS = frozenset({
    "__future__", "dataclasses", "functools", "math", "pathlib", "typing"
})
JS_DIRECT_REQUIRE = "const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');"
PY_INITIALIZER = "build_stones"
JS_INITIALIZER = "buildStones"
PY_LOOP = re.compile(r"\bfor\s+i\s+in\s+range\(\s*2\s*,\s*47\s*\)\s*:")
JS_LOOP = re.compile(r"\bfor\s*\(\s*let\s+i\s*=\s*2\s*;\s*i\s*<=\s*46\s*;\s*i\s*\+=\s*1\s*\)")
JS_ENGINE_ASSIGN = "const STONES = buildStones();"
JS_CATALOG_CUTLETS = "const CUTLETS = Object.freeze(["
JS_CATALOG_MONTHS = "const MONTHS = Object.freeze(["


def need(ok: bool, detail: str) -> None:
    if not ok:
        raise ValueError(detail)


def _call_name(node: ast.AST) -> str | None:
    if type(node) is ast.Call and type(node.func) is ast.Name:
        return node.func.id
    return None


def python_import_inventory(source: str) -> dict:
    tree = ast.parse(source)
    imports, immediate, decorators, declarations = [], [], [], []
    for node in tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom)):
            if isinstance(node, ast.Import):
                names = [x.name.split(".")[0] for x in node.names]
            else:
                names = [(node.module or "").split(".")[0]]
            need(all(n in PY_ALLOWED_IMPORTS for n in names),
                 "unapproved Python top-level import")
            imports.extend(names)
        elif type(node) is ast.Assign:
            need(len(node.targets) == 1 and type(node.targets[0]) is ast.Name,
                 "unsupported Python top-level assignment target")
            var = node.targets[0].id
            if type(node.value) is ast.Call:
                immediate.append((var, _call_name(node.value)))
            elif type(node.value) in (ast.Tuple, ast.List, ast.Constant, ast.UnaryOp,
                                      ast.BinOp):
                # These expression families can contain nested calls; require
                # an actual pure call-free literal/arithmetic expression.
                need(not any(isinstance(x, (ast.Call, ast.Attribute, ast.Subscript,
                                           ast.NamedExpr, ast.Await,
                                           ast.ListComp, ast.DictComp,
                                           ast.SetComp, ast.GeneratorExp))
                             for x in ast.walk(node.value)),
                     "unexpected effectful Python global initializer")
            else:
                raise ValueError("unexpected Python global initializer shape: " + var)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            declarations.append(node.name)
            need(not node.decorator_list,
                 "unexpected Python top-level function decorator")
            need(not node.args.defaults and
                 not any(x is not None for x in node.args.kw_defaults),
                 "unexpected Python function definition-time defaults")
        elif isinstance(node, ast.ClassDef):
            declarations.append(node.name)
            for decorator in node.decorator_list:
                need(type(decorator) is ast.Call and
                     _call_name(decorator) == "dataclass" and
                     set(k.arg for k in decorator.keywords) == {"frozen", "slots"} and
                     all(type(k.value) is ast.Constant and
                         k.value.value is True for k in decorator.keywords),
                     "unreviewed Python class decorator invoked on import")
                decorators.append("dataclass(frozen=True, slots=True)")
            need(not node.bases and not node.keywords,
                 "unexpected Python class base/metaclass code at import")
            # Body is executed at class definition, not after. Reject explicit
            # unsafe statement types; method implementation is not run now.
            for entry in node.body:
                need(type(entry) in (ast.Expr, ast.Assign, ast.AnnAssign,
                                     ast.FunctionDef, ast.Pass),
                     "unexpected Python class body initializer")
                if type(entry) is ast.Expr:
                    need(type(entry.value) is ast.Constant and
                         type(entry.value.value) is str,
                         "unexpected Python class-body expression call")
                if type(entry) in (ast.Assign, ast.AnnAssign):
                    expr = entry.value
                    if expr is not None:
                        need(not any(isinstance(x, (ast.Call, ast.Await,
                                                  ast.NamedExpr, ast.ListComp,
                                                  ast.DictComp, ast.GeneratorExp))
                                     for x in ast.walk(expr)),
                             "Python class field executes extra initialization")
                if type(entry) is ast.FunctionDef:
                    need(not entry.decorator_list,
                         "Python class method decorator executes at import")
                    need(not entry.args.defaults and
                         not any(x is not None for x in entry.args.kw_defaults),
                         "Python method default expression executes at import")
        elif isinstance(node, ast.Expr):
            need(type(node.value) is ast.Constant and
                 type(node.value.value) is str,
                 "Python top-level expression executes at import")
        else:
            raise ValueError("unreviewed Python module-level AST node: " +
                             type(node).__name__)
    need(immediate == [("STONES", PY_INITIALIZER)],
         "Python top-level eager native initialization changed")
    functions = [x for x in tree.body
                 if type(x) is ast.FunctionDef and x.name == PY_INITIALIZER]
    need(len(functions) == 1, "Python precomputation function absent or duplicated")
    def_body = ast.get_source_segment(source, functions[0]) or ""
    need(PY_LOOP.search(def_body) is not None and
         "return tuple(rows)" in def_body and
         def_body.count("save(") == 5,
         "Python native precomputation loop changed from expected five words / 45 iterations")
    return {
        "engine_id": "REF-41",
        "source_import_allowlist": sorted(set(imports)),
        "module_level_eager_calls": ["STONES = build_stones()"],
        "immediate_native_precomputation_iterations_in_source": 45,
        "dataclass_decorator_calls_on_import": len(decorators),
        "module_import_work_is_zero": False,
        "original_native_calendar_Fct_calls_observed": 0,
        "import_side_effect_freedom_proven": False,
    }


def js_engine_import_inventory(source: str) -> dict:
    need(source.count(JS_DIRECT_REQUIRE) == 1,
         "JavaScript source import not exactly pinned catalog dependency")
    need(len(re.findall(r"\brequire\s*\(", source)) == 1,
         "new JavaScript CommonJS dependencies may execute during require")
    need(source.count(JS_ENGINE_ASSIGN) == 1,
         "JavaScript original STONES eager precomputation changed")
    function = re.search(
        r"function\s+buildStones\s*\(\s*\)\s*\{([\s\S]*?)\n\}\s*\n"
        r"const\s+STONES\s*=\s*buildStones\(\)\s*;", source
    )
    need(function is not None and JS_LOOP.search(function.group(1)) is not None
         and "return Object.freeze(stone);" in function.group(1),
         "JavaScript native precomputation is not the exact 45-iteration loop")
    need(source.count("function calendarDate(") == 1,
         "JavaScript original date computation closure changed")
    before_date = source.split("function calendarDate(", 1)[0]
    need("calendarDate(" not in before_date,
         "unexpected JS native Fct call or declaration before date function")
    need(source.count("const SourceLanguageCatalog = Object.freeze(") == 0,
         "unexpected duplicate catalog declaration in native engine source")
    return {
        "engine_id": "REF-24",
        "commonjs_source_dependencies": ["../src/source-language-catalog"],
        "module_level_eager_calls": ["const STONES = buildStones()"],
        "immediate_native_precomputation_iterations_in_source": 45,
        "additional_object_freeze_initializers_present": True,
        "module_import_work_is_zero": False,
        "original_native_calendar_Fct_calls_observed": 0,
        "import_side_effect_freedom_proven": False,
    }


def js_catalog_import_inventory(source: str) -> dict:
    need(source.count(JS_CATALOG_CUTLETS) == 1
         and source.count(JS_CATALOG_MONTHS) == 1
         and source.count("const SourceLanguageCatalog = Object.freeze({") == 1,
         "native catalog top-level frozen arrays changed")
    need("require(" not in source and
         "import(" not in source and
         "eval(" not in source and
         "child_process" not in source,
         "new JS native catalog module initialization dependency detected")
    need("module.exports = Object.freeze({ SourceLanguageCatalog, textByCanonicalIndex });" in source,
         "native language catalog exported object changed")
    return {
        "engine_id": "REF-24",
        "source_file": "src/source-language-catalog.js",
        "module_level_frozen_name_arrays": 2,
        "module_import_work_is_zero": False,
        "import_side_effect_freedom_proven": False,
    }


def inspect(source_root: Path) -> dict:
    fixed = {
        "schema": SCHEMA,
        "halt_new_native_soak_dispatch": True,
        "original_converters_executed": 0,
        "original_full_years_certified": 0,
        "independent_original_algorithms_certified": 0,
        "native_processes_started": 0,
        "module_import_side_effect_freedom_attested": False,
        "runtime_resource_bounds_attested": False,
        "official_10000_year_soak_pass": False,
    }
    try:
        v153 = inspect_adapter(source_root)
        need(v153.get("status") ==
             "PINNED_ADAPTER_STATIC_CHECKONLY_PATHS_VERIFIED_UNCERTIFIED",
             "v153 pinned adapter/source check failed: " +
             str(v153.get("error", v153.get("status"))))
        pin = pinned_lock()
        files = {}
        for engine in pin["engines"]:
            for desc in engine["sources"]:
                p = (source_root / ("Python-Turkce" if engine["id"] == "REF-41"
                     else "JavaScript-Interlingue") /
                     engine["commit"] / desc["path"])
                data = p.read_bytes()
                need(hashlib.sha256(data).hexdigest() == desc["sha256"] and
                     len(data) == desc["bytes"],
                     "pinned source changed during import-time inventory")
                files[(engine["id"], desc["path"])] = data.decode("utf-8")
        python = python_import_inventory(files["REF-41", "tests/normative_reference.py"])
        js = js_engine_import_inventory(files["REF-24", "tests/normative-reference.js"])
        catalog = js_catalog_import_inventory(files["REF-24", "src/source-language-catalog.js"])
        return {
            **fixed,
            "status": "PINNED_MODULE_INITIALIZATION_WORK_IDENTIFIED_UNCERTIFIED",
            "original_reference_source_files_verified": 3,
            "original_adapter_files_verified": 2,
            "eager_stones_initializations_before_checkonly": 2,
            "python_module": python,
            "javascript_engine_module": js,
            "javascript_catalog_module": catalog,
            "scientific_correction": "ZERO_FCT_CALLS_DOES_NOT_MEAN_ZERO_IMPORT_TIME_COMPUTATION",
            "source_native_initialization_witnesses_only": True,
        }
    except (ValueError, OSError, TypeError, SyntaxError,
            UnicodeError, KeyError, AttributeError, IndexError) as exc:
        return {**fixed, "status": "INVALID_IMPORT_TIME_SOURCE_EVIDENCE",
                "error": str(exc)}


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--sources-root", type=Path, required=True)
    cli.add_argument("--report", type=Path, required=True)
    args = cli.parse_args()
    result = inspect(args.sources_root)
    with args.report.open("xb") as f:
        f.write(canonical(result) + b"\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] == \
        "PINNED_MODULE_INITIALIZATION_WORK_IDENTIFIED_UNCERTIFIED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
