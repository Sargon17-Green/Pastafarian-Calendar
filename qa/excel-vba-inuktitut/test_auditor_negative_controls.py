#!/usr/bin/env python3
"""Adversarial fixtures: the Office-free auditor MUST reject broken Stage-1 contracts.
This tests the auditor, not VBA or Excel behavior.
"""
from __future__ import annotations
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent
checker = root / "verify_stage1_vba_office_free.py"
workbook_name = "PC-BRANCH-EXCEL-VBA-INUKTITUT_Stage1_v9_ooxml_structure_fix.xlsx"
mutations = [
    ("formula_guard_missing", "PastafarianExcel.bas", "If cell.HasFormula Then", "If False Then"),
    ("stale_output_not_cleared", "PastafarianExcel.bas", 'sh.Range("E5").ClearContents', "' E5 clear removed"),
    ("formula_case_missing", "Stage1VbaQA.bas", '"reject_formula_day_month",', '"reject_formula_day_month_disabled",'),
    ("workbook_corrupted", workbook_name, None, None),
]
for name, filename, old, new in mutations:
    with tempfile.TemporaryDirectory(prefix="xl_vba_negative_") as tmp:
        base = Path(tmp)
        for p in ["PastafarianExcel.bas", "Stage1VbaQA.bas", workbook_name]:
            shutil.copyfile(root / p, base / p)
        path = base / filename
        if name == "workbook_corrupted":
            with path.open("ab") as fh:
                fh.write(b"corrupted")
        else:
            data = path.read_text(encoding="utf-8")
            assert data.count(old) == 1, (name, data.count(old))
            path.write_text(data.replace(old, new, 1), encoding="utf-8")
        result = subprocess.run([sys.executable, str(checker), "--folder", str(base)], capture_output=True, text=True)
        assert result.returncode != 0, (name, result.stdout, result.stderr)
        assert "FAIL_STATIC" in result.stdout, (name, result.stdout)
        print(f"NEGATIVE_FIXTURE {name}: REJECTED")
print("AUDITOR_NEGATIVE_FIXTURES 4/4 REJECTED")
