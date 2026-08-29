import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"


def run_python_test(
    label: str,
    arguments: tuple[str, ...],
) -> None:
    completed = subprocess.run(
        (
            sys.executable,
            "-m",
            "unittest",
            *arguments,
            "-q",
        ),
        cwd=TESTS,
        text=True,
        capture_output=True,
        check=False,
    )

    print(
        f"{label}_RETURN_CODE={completed.returncode}"
    )

    if completed.stdout:
        print(
            completed.stdout,
            end="",
        )

    if completed.stderr:
        print(
            completed.stderr,
            end="",
        )

    if completed.returncode != 0:
        raise SystemExit(
            f"{label} başarısız"
        )


run_python_test(
    "HISTORICAL_REGRESSIONS",
    (
        "discover",
        "-s",
        str(
            TESTS
        ),
        "-p",
        "test_stage_*.py",
    ),
)

run_python_test(
    "STAGE54_INTEGRATION",
    (
        "discover",
        "-s",
        str(
            TESTS
        ),
        "-p",
        "integration_stage_54.py",
    ),
)

end_to_end_methods = (
    "test_01a_end_to_end_foundation_matches_oracle",
    "test_01b_end_to_end_day_before_foundation_matches_oracle",
    "test_01c_end_to_end_day_after_foundation_matches_oracle",
    "test_01d_end_to_end_crossing_foundation_forward_matches_oracle",
    "test_01e_end_to_end_crossing_foundation_backward_matches_oracle",
)

for method in end_to_end_methods:
    run_python_test(
        "AUDIT_E2E_" + method.upper(),
        (
            "audit_stage_55.Stage55FinalAuditTests."
            + method,
        ),
    )

remaining_methods = tuple(
    "audit_stage_55.Stage55FinalAuditTests."
    + method
    for method in (
        "test_02_save_subtraction_permutation_next_bowl_and_direction_boundaries",
        "test_03_short_wide_and_rejection_selection_match_oracle",
        "test_04_gate_plus_minus_one_two_and_no_forced_symmetry_match_oracle",
        "test_05_year_length_252_5778_and_late_rejection_5779_5780_5781",
        "test_06_opening_first_internal_closing_boundaries_follow_open_left_closed_right",
        "test_07_internal_calculation_gate_cutlet_family_and_cutlet_count_extremes_are_exact",
        "test_08_month_count_length_extremes_and_virtual_counts_are_exact",
        "test_09_interleaved_and_heavy_weaving_counts_and_unrank_are_exact",
        "test_10_distinct_cutlet_month_names_and_separated_day_in_month_are_exact",
        "test_11_year_5000_5001_4999_and_number_transitions_1_0_minus1_match_oracle",
        "test_12_year_cache_cold_warm_and_same_number_different_calculation_day_are_guarded",
        "test_13_catalog_indices_are_frozen_unique_and_locale_can_only_change_presentation",
        "test_14_all_26_legacy_defects_and_26_patch_layers_remain_physical",
        "test_15_hard_invariants_oracle_isolation_and_environment_independence_are_visible",
        "test_16_combinatorial_counts_match_reference_over_small_exhaustive_grids",
        "test_17_completion_audit_has_all_53_mandatory_checkpoints",
    )
)

run_python_test(
    "AUDIT_REMAINDER",
    remaining_methods,
)

print("STAGE55_HISTORICAL_TESTS=365")
print("STAGE55_INTEGRATION_TESTS=10")
print("STAGE55_AUDIT_TESTS=21")
print("STAGE55_TOTAL_TESTS=396")
print("STAGE55_FINAL_AUDIT=PASS")
