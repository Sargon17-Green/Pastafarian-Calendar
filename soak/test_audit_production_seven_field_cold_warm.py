#!/usr/bin/env python3
"""Synthetic mutation tests for the multi-process evidence aggregation contract."""
import copy
import unittest

from audit_production_seven_field_unseeded import FOUNDATION, TARGETS, ORDER_NAMES, target_orders, expected_indices
from audit_production_seven_field_cold_warm import (
    ColdWarmError, inspect_records, verify_workers, digest, PROJECT_ID, BRANCH,
)
SHA = "a" * 40


def fixture():
    edges = tuple(FOUNDATION + n for n in (-301, -300, -299, 399, 400, 401))
    targets = TARGETS + edges
    orders = target_orders(targets)
    rows = []
    matches = []
    metric_rows = ["order\ttarget\texpanded_gate_count"]
    for name, order in zip(ORDER_NAMES, orders):
        for t in order:
            row = [FOUNDATION, t, 5000, 7, 24, 12, 3]
            rows.append("\t".join(map(str, row)))
            matches.append({"target": t, "production_seven": row,
                            "oracle_five": row[2:], "equal": True})
            metric_rows.append(f"{name}\t{t}\t23")
    stdout = "\n".join(rows) + "\n"
    gap_text = "".join(f"{i}\t42\n" for i in expected_indices())
    metrics = "\n".join(metric_rows) + "\n"
    report = {
        "status": "PASS_BOUNDED_UNSEEDED_THREE_ORDER_YEAR_EDGE_NOT_CERTIFIED",
        "project_id": PROJECT_ID, "branch": BRANCH,
        "source": {"git_sha": SHA, "jar_sha256": "b" * 64},
        "production_calls": 33, "production_columns": 7,
        "distinct_targets": 11, "order_count": 3,
        "independent_five_field_comparisons": 165,
        "signed_gate_gap_questions": 560, "production_gate_metric_count": 33,
        "production_configured_gate_limit": 8192,
        "production_gate_metric_max_allowed": 16385,
        "mismatches": 0, "single_jvm_session": True,
        "order_invariance_verified": True, "production_actual_gate_count_exposed": True,
        "production_gate_metric_order_invariant": True,
        "checkpoint_seed_used": False, "pinned_reference_used": False,
        "shared_cross_branch_fixture_used": False, "full_date_certified": False,
        "tablets_certified": False, "global_algorithmic_independence_certified": False,
        "certifiable": False, "elapsed_seconds": 100,
        "production_stdout_sha256": digest(stdout.encode()),
        "signed_gate_gap_sha256": digest(gap_text.encode()),
        "production_gate_metric_sha256": digest(metrics.encode()),
        "target_offsets": [t - FOUNDATION for t in targets],
        "year5000_edges": list(edges),
        "year5000_open_close": [FOUNDATION - 300, FOUNDATION + 400],
        "matches": matches,
        "production_expanded_gate_counts": [
            {"target": t, "expanded_gate_count": 23} for t in targets],
    }
    return report, stdout, gap_text, metrics


class ColdWarmProtocolTests(unittest.TestCase):
    def test_three_clean_worker_evidence_bundles(self):
        args = fixture()
        entry = inspect_records(*args, SHA)
        counts = verify_workers([copy.deepcopy(entry) for _ in range(3)])
        self.assertEqual((counts["jvm_sessions"], counts["seven_column_rows"],
                          counts["five_field_comparisons"], counts["independent_signed_gaps"]),
                         (3, 99, 495, 1680))

    def test_worker_source_sha_mismatch_rejected(self):
        args = list(fixture())
        args[0]["source"]["git_sha"] = "c" * 40
        with self.assertRaisesRegex(ColdWarmError, "E_WORKER_SHA"):
            inspect_records(*args, SHA)

    def test_stdout_row_corruption_rejected(self):
        args = list(fixture())
        args[1] = args[1].replace("\t5000\t7\t24\t12\t3", "\t5000\t7\t24\t12\t4", 1)
        args[0]["production_stdout_sha256"] = digest(args[1].encode())
        with self.assertRaisesRegex(ColdWarmError, "E_MATCH_EVIDENCE"):
            inspect_records(*args, SHA)

    def test_metrics_order_drift_rejected_even_with_updated_digest(self):
        args = list(fixture())
        args[3] = args[3].replace("\t23\n", "\t24\n", 1)
        args[0]["production_gate_metric_sha256"] = digest(args[3].encode())
        with self.assertRaisesRegex(ColdWarmError, "E_METRIC_STATE_DRIFT"):
            inspect_records(*args, SHA)

    def test_gap_index_swap_rejected_even_with_updated_digest(self):
        args = list(fixture())
        lines = args[2].splitlines()
        lines[0], lines[1] = lines[1], lines[0]
        args[2] = "\n".join(lines) + "\n"
        args[0]["signed_gate_gap_sha256"] = digest(args[2].encode())
        with self.assertRaisesRegex(ValueError, "E_UNSEEDED_SIGNED_TRACE"):
            inspect_records(*args, SHA)

    def test_cross_process_output_drift_rejected(self):
        entry = inspect_records(*fixture(), SHA)
        changed = copy.deepcopy(entry)
        changed["seven"][TARGETS[0]] = (1, 2, 3)
        with self.assertRaisesRegex(ColdWarmError, "E_CROSS_PROCESS_seven"):
            verify_workers([entry, changed, entry])

    def test_two_workers_is_not_three(self):
        entry = inspect_records(*fixture(), SHA)
        with self.assertRaisesRegex(ColdWarmError, "E_WORKER_GROUP_COUNT"):
            verify_workers([entry, entry])

    def test_worker_scope_flags_fail_closed(self):
        args = list(fixture())
        args[0]["full_date_certified"] = True
        with self.assertRaisesRegex(ColdWarmError, "E_WORKER_SCOPE"):
            inspect_records(*args, SHA)


if __name__ == "__main__":
    unittest.main()
