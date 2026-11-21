#!/usr/bin/env python3
"""Source-free v162 regression tests of v161 trace parser. NEVER executes F(c,t)."""
from __future__ import annotations
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ANALYZER = Path(__file__).resolve().parents[1] / "runner" / "issue29_analyze_foundation_v161.py"


def fixture_contents() -> dict[str, str]:
    py_weave = [1, 2, 1, 1, 2, 2, 1, 2]
    ada_weave = [1, 2, 1, 2, 1, 2, 1, 2]
    selector = {
        "month_lengths": [4, 4],
        "family_count_hex": "14",
        "global_rank_hex": "9",
        "source_mode": "QA_INSTRUMENTED_COPY_NOT_ORIGINAL",
    }
    py = {
        "source_mode": "QA_INSTRUMENTED_COPY_NOT_ORIGINAL",
        "calculation_day": "-15055671", "target_day": "-15055671",
        "year_open_day": "-15057703", "year_close_day": "-15053459",
        "month_count": 2, "month_lengths": [4, 4],
        "month_weaving": py_weave, "month_name_indices": [20, 30],
        "target_offset0": 2, "month_id": 1, "month_index": 20,
        "day_in_month": 2,
    }
    ada = [
        "V159_ADA_DIAG|source_mode|QA_INSTRUMENTED_COPY_NOT_ORIGINAL",
        "V159_ADA_DIAG|calculation_day|-15055671",
        "V159_ADA_DIAG|target_day|-15055671",
        "V159_ADA_DIAG|year_open_day|-15057703",
        "V159_ADA_DIAG|year_close_day|-15053459",
        "V159_ADA_DIAG|month_count| 2",
        "V159_ADA_DIAG|target_offset0| 2",
        "V159_ADA_DIAG|month_id| 1",
        "V159_ADA_DIAG|month_index| 20",
        "V159_ADA_DIAG|day_in_month| 2",
    ]
    for i, n in enumerate([4, 4], 1):
        ada.append(f"V159_ADA_DIAG|month_length| {i}| {n}")
    for i, n in enumerate([20, 30], 1):
        ada.append(f"V159_ADA_DIAG|month_name| {i}| {n}")
    for i, n in enumerate(ada_weave, 1):
        ada.append(f"W| {i}| {n}")
    return {
        "run-python.stderr": (
            "V159_PY_DIAG|selector|" + json.dumps(selector) + "\n"
            "V159_PY_DIAG|result|" + json.dumps(py) + "\n"
        ),
        "run-python.stdout": "V160_PY_RESULT|5000|10|503|20|2\n",
        "run-ada.stderr": "\n".join(ada) + "\n",
        "run-ada.stdout": "V160_ADA_RESULT| 5000| 10| 503| 20| 2\n",
    }


def execute_fixture(files: dict[str, str]) -> tuple[dict, subprocess.CompletedProcess[str]]:
    with tempfile.TemporaryDirectory() as p:
        root = Path(p)
        for n, v in files.items():
            (root / n).write_text(v, encoding="utf-8")
        output = root / "analysis.json"
        proc = subprocess.run(
            [sys.executable, "-B", str(ANALYZER), str(root), str(output)],
            capture_output=True, text=True, timeout=10, check=False,
        )
        return (json.loads(output.read_text(encoding="utf-8")) if output.exists() else {}), proc


class SourceFreeParserRegression(unittest.TestCase):
    def test_equal_numeric_dates_not_false_divergence(self):
        result, p = execute_fixture(fixture_contents())
        self.assertEqual(p.returncode, 0, p.stderr)
        rows = {x["node"]: x for x in result["comparison"]}
        self.assertIs(rows["year_open_day"]["equal"], True)
        self.assertIs(rows["year_close_day"]["equal"], True)
        self.assertEqual(rows["year_open_day"]["python"]["value"], -15057703)
        self.assertEqual(rows["year_close_day"]["python"]["value"], -15053459)
        self.assertEqual(result["first_unequal_among_observed_nodes"], "month_weaving")
        self.assertEqual(rows["month_weaving"]["first_different_zero_based_position"], 3)
        self.assertIs(result["actual_first_divergent_computation_certified"], False)

    def test_ada_output_whitespace_is_not_a_numeric_mismatch(self):
        result, p = execute_fixture(fixture_contents())
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(result["final_five_fields"]["ada"], [5000, 10, 503, 20, 2])
        self.assertEqual(result["final_five_fields"]["python"], [5000, 10, 503, 20, 2])
        self.assertEqual(result["trace_internal_consistency"], {"python": [], "ada": []})

    def test_missing_ada_trace_is_not_a_success(self):
        fixture = fixture_contents()
        fixture["run-ada.stderr"] = ""
        fixture["run-ada.stdout"] = ""
        result, p = execute_fixture(fixture)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(result["status"], "PARTIAL_OR_FAILED")
        self.assertIsNone(result["final_five_fields"]["ada"])
        self.assertIsNone(result["first_unequal_among_observed_nodes"])


if __name__ == "__main__":
    unittest.main()
