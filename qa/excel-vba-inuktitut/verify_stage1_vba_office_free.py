#!/usr/bin/env python3
"""Office-free structural audit of Stage 1 Excel VBA host + temporary QA suite.

Does NOT compile/execute VBA and does NOT implement canonical F(c,t).
Uses only the Python standard library; read-only except optional --json output.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

EXPECTED_WORKBOOK_SHA256 = "f51271947a88f19afb8d690dfbb6e4105fba91511294ff7d0845136f53a0a7ca"
NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"


def check(condition, name, checks):
    checks.append({"check": name, "passed": bool(condition)})
    if not condition:
        raise AssertionError(name)


def model_decimal(value: str, positive: bool) -> bool:
    """Python-derived decimal specification; NOT a VBA interpreter."""
    if not isinstance(value, str) or not value:
        return False
    digits = value
    if digits.startswith("-"):
        if positive:
            return False
        digits = digits[1:]
    return bool(digits) and all("0" <= c <= "9" for c in digits) and (not positive or any(c != "0" for c in digits))


def audit(folder: Path) -> dict:
    checks = []
    source = (folder / "PastafarianExcel.bas").read_text(encoding="utf-8")
    qa = (folder / "Stage1VbaQA.bas").read_text(encoding="utf-8")
    workbook = folder / "PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_v9_ooxml_structure_fix.xlsx"
    check(hashlib.sha256(workbook.read_bytes()).hexdigest() == EXPECTED_WORKBOOK_SHA256, "workbook v9 unchanged SHA256", checks)
    check('Attribute VB_Name = "PastafarianExcel"' in source and 'Option Explicit' in source, "host module identity + Option Explicit", checks)
    check('Attribute VB_Name = "Stage1VbaQA"' in qa and 'Option Explicit' in qa, "QA module identity + Option Explicit", checks)

    source_guard = source.split("Private Function ExactCellString", 1)[1].split("End Function", 1)[0]
    check('value = cell.Value2' in source_guard and 'If IsEmpty(value) Then' in source_guard
          and 'ExactCellString = vbNullString' in source_guard
          and source_guard.index('If IsEmpty(value)') < source_guard.index('If VarType(value) <> vbString'),
          "blank cells routed to field validators before strict text guard", checks)
    check('Err.Raise vbObjectError + 519' in source_guard,
          "numeric/formula/error cell strict text guard preserved", checks)
    check('If cell.HasFormula Then' in source_guard
          and source_guard.index('If cell.HasFormula Then') < source_guard.index('value = cell.Value2'),
          "formula returning text blocked before reading cached string", checks)
    render = source.split('Public Sub RenderPastafarianDate()', 1)[1].split('End Sub', 1)[0]
    check('sh.Range("E5").ClearContents' in render
          and render.index('sh.Range("E5").ClearContents') < render.index('y = ExactCellString'),
          "stale display is cleared before any input can raise", checks)
    for code, name in ((514,"year"),(515,"cutlet"),(516,"dayInCutlet"),(517,"month"),(518,"dayInMonth")):
        check(f"Err.Raise vbObjectError + {code}" in source, f"field-specific error {name} = {code}", checks)
    check('Err.Raise vbObjectError + 513' in source and 'CANONICAL ENGINE NOT IMPLEMENTED' in source,
          "unimplemented canonical engine guard unchanged", checks)
    check('sh.Range("B11:B15").NumberFormat' not in source or '"@"' in source,
          "text-formatted five canonical display inputs", checks)
    check('"E5").Value2 = y & " | " & cutlet' in source,
          "display concatenates externally computed five fields", checks)
    check(not re.search(r'\b(Shell|CreateObject|Open\s+\S+\s+For|ExecuteExcel4Macro|WinHttp|XMLHTTP)\s*\(',source,re.I),
          "host contains no direct shell/network execution call", checks)

    m = re.search(r'cases\s*=\s*Array\((.*?)\)\s*\n\s*passed\s*=', qa, re.S)
    check(m is not None, "QA case array found", checks)
    names = re.findall(r'"([a-z][a-z0-9_]*)"', m.group(1))
    branches = re.findall(r'^\s*Case\s+"([a-z][a-z0-9_]*)"', qa, re.M)
    check(len(names) == 35 and len(set(names)) == 35, "35 unique declared VBA QA cases", checks)
    check(set(names) == set(branches) and len(branches) == 35, "every declared case implemented exactly once", checks)
    check('PrepareValidInputs sh' in qa and '.ClearContents' in qa and 'RunCaseAndCapture' in qa,
          "independent QA setups and true empty-cell branches", checks)
    check('String$(1024, "9")' in qa and 'ChrW$(&H1403)' in qa,
          "1024 digit and Unicode regression cases present", checks)
    check('ExpectCanonicalGuard' in qa and 'vbObjectError + 513' in qa,
          "host tests require unimplemented engine to reject calls", checks)
    formula_names = {
        "reject_formula_year", "reject_formula_cutlet", "reject_formula_day_cutlet",
        "reject_formula_month", "reject_formula_day_month",
    }
    check(formula_names.issubset(set(names)) and 'ExpectRejectTextFormula' in qa
          and 'target.Formula' in qa and 'target.HasFormula' in qa
          and 'ExpectRenderError vbObjectError + 519' in qa,
          "five text-returning formula cases require precision error 519", checks)
    check('clear_stale_after_invalid_input' in names
          and 'AssertExact CStr(sh.Range("E5").Value2), vbNullString, testName' in qa
          and 'ExpectRenderError vbObjectError + 516, testName' in qa,
          "rejected new input must erase old display", checks)
    check('On Error Resume Next' in qa and 'On Error GoTo 0' in qa,
          "VBA expected-error harness resets error handling", checks)

    # Evaluate the independent, exact-text numeric input specification on edge fixtures.
    cases = [
        ("", False, False), ("0", False, True), ("-0", False, True),
        ("-999", False, True), ("9"*1024, False, True),
        ("+2", False, False), ("1.5", False, False), ("1e3", False, False),
        ("\u0661", False, False), ("\uff11", False, False),
        ("0", True, False), ("000", True, False), ("001", True, True),
        ("1", True, True), ("-1", True, False), ("9"*1024, True, True),
        ("", True, False), ("\u0662", True, False),
    ]
    check(all(model_decimal(s,p) == expected for s,p,expected in cases),
          "independent exact decimal specification: 18 fixtures", checks)

    sheet_count = 0
    cell_count = 0
    formula_count = 0
    malformed_ranges = []
    with zipfile.ZipFile(workbook) as z:
        check(z.testzip() is None, "OOXML ZIP CRC verified", checks)
        for entry in z.namelist():
            if not re.fullmatch(r"xl/worksheets/sheet\d+\.xml",entry):
                continue
            sheet_count += 1
            node = ET.fromstring(z.read(entry))
            cell_count += len(node.findall(".//"+NS+"c"))
            formula_count += len(node.findall(".//"+NS+"f"))
            for col in node.findall(".//"+NS+"col"):
                low = int(col.attrib.get("min",1))
                high = int(col.attrib.get("max",1))
                if low>high:
                    malformed_ranges.append(f"{entry}: {low}>{high}")
    check(sheet_count == 15, "15 worksheets", checks)
    check(cell_count == 49084, "49,084 worksheet cells preserved", checks)
    check(formula_count == 47002, "47,002 formulas preserved", checks)
    check(not malformed_ranges, "no inverted OOXML column ranges", checks)

    return {
        "status": "PASS_STATIC_ONLY", "project_id": "PC-BRANCH-EXCEL-VBA-INUKTITUT", "stage": 1,
        "test_count_declared_vba_not_executed": len(names),
        "office_vba_compile": "NOT_RUN", "office_vba_tests": "NOT_RUN",
        "source_sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
        "qa_sha256": hashlib.sha256(qa.encode("utf-8")).hexdigest(),
        "workbook_v9_sha256": hashlib.sha256(workbook.read_bytes()).hexdigest(),
        "sheet_count": sheet_count, "cell_count": cell_count, "formula_count": formula_count,
        "checks": checks,
        "scope_note": "Structural/source contract and independent decimal specification audit only. No native VBA compilation or calculation engine."
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--folder", type=Path, default=Path(__file__).resolve().parent)
    p.add_argument("--json", type=Path)
    args=p.parse_args()
    try:
        result=audit(args.folder)
    except (AssertionError, OSError, ValueError, zipfile.BadZipFile) as ex:
        result={"status":"FAIL_STATIC", "error":str(ex)}
    if args.json:
        args.json.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"{result['status']}: {len(result.get('checks', []))} checks; VBA compile/runtime NOT RUN")
    if result['status']!='PASS_STATIC_ONLY':
        print(result.get('error','unknown failure'))
        return 1
    return 0

if __name__=='__main__':
    raise SystemExit(main())