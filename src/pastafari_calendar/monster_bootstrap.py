from dataclasses import dataclass, field
from typing import Any, Callable

from .acceleration_scars import AccelerationScarContext

from .legacy_arithmetic import LegacyRemainderAdapter
from .legacy_day_counts import LegacyDayTagAdapter
from .legacy_distance import LegacyDistanceAdapter
from .legacy_stones import LegacyStoneBuilderAdapter
from .legacy_hidden import LegacyHiddenDropAdapter
from .legacy_prior import LegacyPriorAdapter
from .legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from .legacy_permutation import LegacyPermutationOrderAdapter
from .legacy_pours import LegacyPourAdapter
from .legacy_bowl_updates import LegacyBowlUpdateAdapter
from .legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from .legacy_next_bowl import LegacyNextBowlAdapter
from .legacy_selection import (
    LegacyBiasedSelectionAdapter,
    LegacyShortOnlySelectionDispatcher,
)
from .legacy_gate_question import LegacyGateQuestionAdapter
from .legacy_year_candidates import LegacyYearCandidateAdapter
from .legacy_year_jump import LegacyYearJumpAdapter
from .legacy_year_cache import LegacyYearNumberOnlyCacheMap
from .legacy_structure_sauce import LegacyStructureSauceAdapter
from .legacy_cutlet_partition import LegacyCutletPartitionAdapter
from .legacy_repeated_names import LegacyRepeatedNameGenerator
from .legacy_month_length_materialization import LegacyMonthLengthMaterializationAdapter
from .legacy_month_weaving import LegacyMonthWeavingAdapter
from .legacy_month_day_position import LegacyContiguousMonthDayAdapter
from .legacy_opening_gate_interval import LegacyOpeningGateIntervalAdapter


class MonsterError(RuntimeError):
    pass


class MonsterValidationError(MonsterError):
    pass


class StageNotIntegratedError(MonsterError):
    pass


@dataclass(slots=True)
class MonsterContext:
    calculation_day: int
    target_day: int
    phase: str = "GİRİŞ"
    sub_phase: int = 0
    mode: str = "AŞAMA_01_TARAFSIZ"
    status: str = "YENİ"
    retry_budget: int = 0
    recovery_depth: int = 0
    current_handler: str | None = None
    previous_handler: str | None = None
    branch_trace: list[Any] = field(default_factory=list)
    metrics: dict[str, int] = field(default_factory=dict)
    logs: list[tuple[Any, ...]] = field(default_factory=list)
    diagnostics: list[Any] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    last_error: Exception | None = None
    validation_failures: list[str] = field(default_factory=list)
    legacy_remainder_input: int | None = None
    legacy_remainder_value: int | None = None
    patch01_input: int | None = None
    patch01_value: int | None = None
    patch01_applied: bool = False
    legacy_action_day_tag_input: int | None = None
    legacy_action_day_tag_value: int | None = None
    legacy_target_day_tag_input: int | None = None
    legacy_target_day_tag_value: int | None = None
    patch02_action_day_tag_input: int | None = None
    patch02_action_day_tag_value: int | None = None
    patch02_action_applied: bool = False
    patch02_target_day_tag_input: int | None = None
    patch02_target_day_tag_value: int | None = None
    patch02_target_applied: bool = False
    patch02_foundation_guard_seen: bool = False
    legacy_distance_calculation_day: int | None = None
    legacy_distance_target_day: int | None = None
    legacy_distance_value: int | None = None
    patch03_chronological_distance: int | None = None
    patch03_distance_value: int | None = None
    patch03_legacy_replaced: bool = False
    patch03_applied: bool = False
    legacy_stone_table: tuple[tuple[int, ...], ...] | None = None
    legacy_stone_rows_built: int = 0
    patch04_rows_patched: int = 0
    patch04_last_old_stones: tuple[int, ...] | None = None
    patch04_last_legacy_garbage: tuple[int, ...] | None = None
    patch04_last_committed_stones: tuple[int, ...] | None = None
    legacy_hidden_storage: tuple[int, ...] | None = None
    legacy_hidden_count: int = 0
    legacy_hidden_last_requested_k: int | None = None
    legacy_hidden_last_returned_value: int | None = None
    patch05_requested_k: int | None = None
    patch05_translated_slot: int | None = None
    patch05_legacy_direct_value: int | None = None
    patch05_corrected_value: int | None = None
    patch05_applied: bool = False
    legacy_prior_i: int | None = None
    legacy_prior_back: int | None = None
    legacy_prior_slot: int | None = None
    legacy_prior_value: int | None = None
    legacy_prior_probe_value: int | None = None
    patch06_slot: int | None = None
    patch06_used_hidden: bool = False
    patch06_hidden_k: int | None = None
    patch06_value: int | None = None
    patch06_applied: bool = False
    legacy_visible_drop_table: tuple[int, ...] | None = None
    legacy_visible_drop_count: int = 0
    legacy_grind_rows_applied: int = 0
    legacy_grind_missing_index: int | None = None
    patch07_sentinel_present: bool = False
    patch07_table_length: int = 0
    patch07_applied: bool = False
    legacy_permutation_order_table: tuple[tuple[int, ...], ...] | None = None
    legacy_permutation_order_count: int = 0
    legacy_permutation_last_drop_index: int | None = None
    legacy_permutation_last_drop_value: int | None = None
    legacy_permutation_last_one_based: int | None = None
    legacy_permutation_last_order: tuple[int, ...] | None = None
    legacy_permutation_invalid_one_based: int | None = None
    legacy_permutation_invalid_drop_index: int | None = None
    patch08_drop_index: int | None = None
    patch08_one_based: int | None = None
    patch08_legacy_rank0: int | None = None
    patch08_legacy_wrong_order: tuple[int, ...] | None = None
    patch08_legacy_wrong_error: str | None = None
    patch08_corrected_order: tuple[int, ...] | None = None
    patch08_applied: bool = False
    legacy_initial_bowls: tuple[int, ...] | None = None
    legacy_pour_last_drop_index: int | None = None
    legacy_pour_last_order: tuple[int, ...] | None = None
    legacy_pour_last_values: tuple[int, ...] | None = None
    patch09_drop_index: int | None = None
    patch09_bowl_alias: tuple[int, ...] | None = None
    patch09_legacy_fixed_pours: tuple[int, ...] | None = None
    patch09_corrected_pours: tuple[int, ...] | None = None
    patch09_applied: bool = False
    legacy_bowl_update_last_drop_index: int | None = None
    legacy_bowl_update_last_input: tuple[int, ...] | None = None
    legacy_bowl_update_last_pours: tuple[int, ...] | None = None
    legacy_bowl_update_last_result: tuple[int, ...] | None = None
    patch10_drop_index: int | None = None
    patch10_vaultOld: tuple[int, ...] | None = None
    patch10_pending: tuple[int, ...] | None = None
    patch10_legacy_wrong_result: tuple[int, ...] | None = None
    patch10_corrected_result: tuple[int, ...] | None = None
    patch10_commit_after_six: bool = False
    patch10_applied: bool = False
    legacy_overwritable_order_memory: tuple[int, ...] | None = None
    legacy_order_memory_write_count: int = 0
    legacy_order_memory_last_source: tuple[str, int] | None = None
    legacy_bowls_after_46_drops: tuple[int, ...] | None = None
    legacy_post_stir_last_saved_sum: int | None = None
    legacy_post_stir_final_bowls: tuple[int, ...] | None = None
    corrective56_raw_bowlsum_enabled: bool = False
    corrective56_post_stir_last_stir: int | None = None
    corrective56_post_stir_last_raw_bowl_sum: int | None = None
    corrective56_post_stir_last_order_number: int | None = None
    corrective56_post_stir_last_legacy_wrong_result: tuple[int, ...] | None = None
    corrective56_post_stir_last_corrected_result: tuple[int, ...] | None = None
    corrective56_post_stir_applied_count: int = 0
    corrective56_post_stir_applied: bool = False
    orderAt46Latch: tuple[int, ...] | None = None
    patch11_latch_write_count: int = 0
    patch11_latch_source: tuple[str, int] | None = None
    patch11_applied: bool = False
    legacy_next_bowl_queried_id: int | None = None
    legacy_next_bowl_fixed_result: int | None = None
    patch12_queried_id: int | None = None
    patch12_legacy_diagnostic: int | None = None
    patch12_corrected_result: int | None = None
    patch12_applied: bool = False
    legacy_selection_first_answer: int | None = None
    legacy_selection_direction_step: int | None = None
    legacy_selection_n: int | None = None
    legacy_selection_result: int | None = None
    patch13_limit: int | None = None
    patch13_accepted_offset: int | None = None
    patch13_accepted_answer: int | None = None
    patch13_rejection_count: int = 0
    patch13_legacy_pick_result: int | None = None
    patch13_applied: bool = False
    legacy_general_selection_n: int | None = None
    legacy_general_selection_used_short_path: bool = False
    legacy_general_selection_result: int | None = None
    legacy_wide_selection_unsupported: bool = False
    legacy_wide_selection_error: str | None = None
    patch14_used_wide_path: bool = False
    patch14_places: int | None = None
    patch14_space: int | None = None
    patch14_digits: tuple[int, ...] | None = None
    patch14_initial_wide: int | None = None
    patch14_acceptance_limit: int | None = None
    patch14_rejection_count: int = 0
    patch14_accepted_wide: int | None = None
    patch14_result: int | None = None
    patch14_applied: bool = False
    legacy_gate_signed_step: int | None = None
    legacy_gate_magnitude: int | None = None
    legacy_gate_question_day: int | None = None
    patch15_signed_step: int | None = None
    patch15_legacy_positive_day: int | None = None
    patch15_corrected_day: int | None = None
    patch15_used_negative_detour: bool = False
    patch15_applied: bool = False
    legacy_year_candidate_input_lengths: tuple[int, ...] | None = None
    legacy_year_candidate_lengths_before_sort: tuple[int, ...] | None = None
    legacy_year_candidate_lengths_after_sort: tuple[int, ...] | None = None
    legacy_year_candidate_count_for_selection: int | None = None
    legacy_year_candidate_selected_rank: int | None = None
    legacy_year_candidate_selected_label: str | None = None
    legacy_year_candidate_selected_length: int | None = None
    patch16_legacy_accepted_lengths: tuple[int, ...] | None = None
    patch16_rejected_overlong_lengths: tuple[int, ...] | None = None
    patch16_semantic_accepted_lengths: tuple[int, ...] | None = None
    patch16_filter_evaluations: int = 0
    patch16_applied: bool = False
    legacy_year5000_tie_input_labels: tuple[str, ...] | None = None
    legacy_year5000_tie_input_lengths: tuple[int, ...] | None = None
    legacy_year5000_tie_input_open_days: tuple[int, ...] | None = None
    legacy_year5000_tie_sorted_labels: tuple[str, ...] | None = None
    legacy_year5000_tie_sorted_lengths: tuple[int, ...] | None = None
    legacy_year5000_tie_sorted_open_days: tuple[int, ...] | None = None
    patch17_legacy_sorted_labels: tuple[str, ...] | None = None
    patch17_equal_length_run_count: int = 0
    patch17_run_boundaries: tuple[tuple[int, int], ...] | None = None
    patch17_run_before_labels: tuple[tuple[str, ...], ...] | None = None
    patch17_run_after_labels: tuple[tuple[str, ...], ...] | None = None
    patch17_corrected_labels: tuple[str, ...] | None = None
    patch17_corrected_open_days: tuple[int, ...] | None = None
    patch17_applied: bool = False
    legacy_jump_anchor_number: int | None = None
    legacy_jump_anchor_first_day: int | None = None
    legacy_jump_anchor_open_day: int | None = None
    legacy_jump_anchor_close_day: int | None = None
    legacy_jump_target_day: int | None = None
    legacy_jump_guess_number: int | None = None
    legacy_jump_semantic_year_number: int | None = None
    legacy_jump_guess_used_as_semantic: bool = False
    legacy_jump_calls: int = 0
    patch18_legacy_guess_telemetry: int | None = None
    patch18_guess_ignored_for_semantics: bool = False
    patch18_walk_start_number: int | None = None
    patch18_walk_target_day: int | None = None
    patch18_walk_visited_numbers: tuple[int, ...] | None = None
    patch18_forward_steps: int = 0
    patch18_backward_steps: int = 0
    patch18_result_number: int | None = None
    patch18_result_open_day: int | None = None
    patch18_result_close_day: int | None = None
    patch18_applied: bool = False
    legacy_year_cache_last_year_number: int | None = None
    legacy_year_cache_last_calculation_day: int | None = None
    legacy_year_cache_last_open_gate: int | None = None
    legacy_year_cache_last_close_gate: int | None = None
    legacy_year_cache_last_hit: bool | None = None
    legacy_year_cache_last_returned_token: str | None = None
    legacy_year_cache_map_keys: tuple[int, ...] | None = None
    legacy_year_cache_hit_count: int = 0
    legacy_year_cache_miss_count: int = 0
    legacy_year_cache_semantic_token: str | None = None
    patch19_legacy_key_hit: bool = False
    patch19_calculation_day_match: bool = False
    patch19_open_gate_match: bool = False
    patch19_close_gate_match: bool = False
    patch19_all_guards_match: bool = False
    patch19_last_written_calculation_day_fingerprint: int | None = None
    patch19_last_written_open_gate: int | None = None
    patch19_last_written_close_gate: int | None = None
    patch19_last_written_token: str | None = None
    patch19_applied: bool = False
    legacy_structure_calculation_day: int | None = None
    legacy_structure_original_target_day: int | None = None
    legacy_structure_year_first_day: int | None = None
    legacy_structure_old_bowls: tuple[int, ...] | None = None
    legacy_structure_old_order_at_drop_46: tuple[int, ...] | None = None
    legacy_structure_old_used_by_selector: bool = False
    legacy_structure_semantic_source: str | None = None
    legacy_structure_reused_existing_calendar_sauce: bool = False
    legacy_structure_selector_input_target_day: int | None = None
    legacy_structure_selector_token: int | None = None
    legacy_structure_selector_order_at_drop_46: tuple[int, ...] | None = None
    legacy_structure_calls: int = 0
    patch20_old_ghost_target_day: int | None = None
    patch20_old_ghost_bowls: tuple[int, ...] | None = None
    patch20_old_ghost_order_at_drop_46: tuple[int, ...] | None = None
    patch20_old_ghost_recorded: bool = False
    patch20_recompute_needed: bool = False
    patch20_authoritative_recomputed: bool = False
    patch20_semantic_target_day: int | None = None
    patch20_semantic_bowls: tuple[int, ...] | None = None
    patch20_semantic_order_at_drop_46: tuple[int, ...] | None = None
    patch20_old_ghost_reached_selector: bool = False
    patch20_applied: bool = False
    legacy_cutlet_gate_gap_count: int | None = None
    legacy_cutlet_count: int | None = None
    legacy_cutlet_internal_gate_offset: int | None = None
    legacy_cutlet_all_positive_family_count: int | None = None
    legacy_cutlet_selected_rank: int | None = None
    legacy_cutlet_selected_partition: tuple[int, ...] | None = None
    legacy_cutlet_used_all_positive_family: bool = False
    legacy_cutlet_internal_gate_was_ignored: bool = False
    legacy_cutlet_answer_first: int | None = None
    legacy_cutlet_answer_direction_step: int | None = None
    legacy_cutlet_partition_calls: int = 0
    patch21_legacy_selected_partition: tuple[int, ...] | None = None
    patch21_required_boundary: int | None = None
    patch21_filter_applied: bool = False
    patch21_filtered_family_count: int | None = None
    patch21_semantic_selected_rank: int | None = None
    patch21_semantic_partition: tuple[int, ...] | None = None
    patch21_boundary_hit: bool = False
    patch21_applied: bool = False
    legacy_name_source_kind: str | None = None
    legacy_name_master_count: int | None = None
    legacy_name_item_count: int | None = None
    legacy_name_family_count: int | None = None
    legacy_name_selected_rank: int | None = None
    legacy_name_candidate_indices: tuple[int, ...] | None = None
    legacy_name_candidate_has_repeats: bool = False
    legacy_name_semantic_indices: tuple[int, ...] | None = None
    legacy_name_answer_first: int | None = None
    legacy_name_answer_direction_step: int | None = None
    legacy_name_generation_calls: int = 0
    legacy_cutlet_name_indices: tuple[int, ...] | None = None
    patch22_bad_indices: tuple[int, ...] | None = None
    patch22_distinct_family_count: int | None = None
    patch22_correct_rank: int | None = None
    patch22_correct_indices: tuple[int, ...] | None = None
    patch22_bad_equals_correct: bool = False
    patch22_returned_bad: bool = False
    patch22_semantic_indices: tuple[int, ...] | None = None
    patch22_applied: bool = False
    legacy_month_length_total_days: int | None = None
    legacy_month_length_month_count: int | None = None
    legacy_month_length_lower_bound: int | None = None
    legacy_month_length_prefix_low: int | None = None
    legacy_month_length_prefix_high: int | None = None
    legacy_month_length_materialization_blocked: bool = False
    legacy_month_length_materialized_count: int | None = None
    legacy_month_length_concrete_ways: tuple[tuple[int, ...], ...] | None = None
    legacy_month_length_materialization_calls: int = 0
    patch23_legacy_materialization_blocked: bool = False
    patch23_legacy_concrete_count: int | None = None
    patch23_virtual_backend_active: bool = False
    patch23_exact_count: int | None = None
    patch23_semantic_blocked: bool = False
    patch23_applied: bool = False
    legacy_month_weaving_lengths: tuple[int, ...] | None = None
    legacy_month_weaving_answer_first: int | None = None
    legacy_month_weaving_answer_direction_step: int | None = None
    legacy_month_weaving_ghost: tuple[int, ...] | None = None
    legacy_month_weaving_semantic: tuple[int, ...] | None = None
    legacy_month_weaving_calls: int = 0
    patch24_ghost: tuple[int, ...] | None = None
    patch24_legal_family_count: int | None = None
    patch24_wanted_rank: int | None = None
    patch24_correct_weaving: tuple[int, ...] | None = None
    patch24_ghost_equals_correct: bool = False
    patch24_returned_ghost: bool = False
    patch24_semantic_weaving: tuple[int, ...] | None = None
    patch24_applied: bool = False
    legacy_month_day_target_position: int | None = None
    legacy_month_day_month_id: int | None = None
    legacy_month_day_first_position: int | None = None
    legacy_month_day_guessed_day: int | None = None
    legacy_month_day_semantic_day: int | None = None
    legacy_month_day_calls: int = 0
    patch25_wrong_guess: int | None = None
    patch25_correct_day_in_month: int | None = None
    patch25_overwrite_needed: bool = False
    patch25_semantic_day_in_month: int | None = None
    patch25_applied: bool = False
    legacy_opening_interval_anchor_number: int | None = None
    legacy_opening_interval_anchor_open_day: int | None = None
    legacy_opening_interval_anchor_close_day: int | None = None
    legacy_opening_interval_target_day: int | None = None
    legacy_opening_interval_backward_steps: int = 0
    legacy_opening_interval_result_number: int | None = None
    legacy_opening_interval_result_open_day: int | None = None
    legacy_opening_interval_result_close_day: int | None = None
    legacy_opening_interval_closed_open_assumption: bool = False
    legacy_opening_interval_semantic_year_number: int | None = None
    legacy_opening_interval_calls: int = 0
    patch26_legacy_result_number: int | None = None
    patch26_correct_result_number: int | None = None
    patch26_correct_result_open_day: int | None = None
    patch26_correct_result_close_day: int | None = None
    patch26_backward_steps: int = 0
    patch26_open_boundary_hit: bool = False
    patch26_same_as_legacy: bool = False
    patch26_semantic_year_number: int | None = None
    patch26_applied: bool = False
    integration_started: bool = False
    integration_completed: bool = False
    integration_status: str = "BEKLEMEDE"
    integration_program_counter: str = "BEKLEMEDE"
    integration_commit_token: int = 0
    integration_retry_count: int = 0
    integration_gate_retry_count: int = 0
    integration_mode: str = "AUTHORITATIVE"
    integration_compatibility_flags: tuple[str, ...] = ()
    integration_hook_calls: int = 0
    integration_old_snapshot: Any = None
    integration_pending_snapshot: Any = None
    integration_rollback_snapshot: Any = None
    integration_last_committed_phase: str = "BAŞLANGIÇ"
    integration_gate_cache_hits: int = 0
    integration_gate_cache_misses: int = 0
    integration_gate_questions: int = 0
    integration_gate_last_signed_index: int | None = None
    integration_gate_last_question_day: int | None = None
    integration_gate_last_gap: int | None = None
    integration_year_legacy_5781_accepted: int = 0
    integration_year_rejected_5779_5781: int = 0
    integration_year5000_candidate_count: int = 0
    integration_year5000_selected_rank: int | None = None
    integration_year5000_open_day: int | None = None
    integration_year5000_close_day: int | None = None
    integration_legacy_jump_guess: int | None = None
    integration_year_walk_visited: tuple[int, ...] | None = None
    integration_target_year_number: int | None = None
    integration_target_year_open_day: int | None = None
    integration_target_year_close_day: int | None = None
    integration_year_cache_hits: int = 0
    integration_year_cache_misses: int = 0
    integration_year_cache_guard_rejections: int = 0
    integration_year_cache_guard_valid: bool = False
    integration_structure_ghost_target_day: int | None = None
    integration_structure_semantic_target_day: int | None = None
    integration_structure_recomputed: bool = False
    integration_cutlet_raw_partition: tuple[int, ...] | None = None
    integration_cutlet_required_boundary: int | None = None
    integration_cutlet_semantic_partition: tuple[int, ...] | None = None
    integration_cutlet_raw_name_indices: tuple[int, ...] | None = None
    integration_cutlet_name_indices: tuple[int, ...] | None = None
    integration_month_weaving_ghost: tuple[int, ...] | None = None
    integration_month_weaving_semantic: tuple[int, ...] | None = None
    integration_month_raw_name_indices: tuple[int, ...] | None = None
    integration_month_name_indices: tuple[int, ...] | None = None
    integration_structure: Any = None
    integration_month_day_legacy_guess: int | None = None
    integration_month_day_occurrence_count: int | None = None
    integration_result_five: Any = None
    integration_exact_five_fields: bool = False
    integration_stage39_terminal_scar: str | None = None
    acceleration_scars: AccelerationScarContext = field(default_factory=AccelerationScarContext)


class BaseMetrics:
    def bump(self, ctx: MonsterContext, key: str) -> None:
        ctx.metrics[key] = ctx.metrics.get(key, 0) + 1


class BaseValidator:
    def require_integer_day(self, ctx: MonsterContext, value: Any, field_name: str) -> None:
        if type(value) is not int:
            message = f"{field_name} tam sayı olmalıdır"
            ctx.validation_failures.append(message)
            raise MonsterValidationError(message)

    def require_context_owned(self, ctx: MonsterContext, calculation_day: int, target_day: int) -> None:
        if ctx.calculation_day != calculation_day or ctx.target_day != target_day:
            message = "Çağrı bağlamının sahipliği bozuldu"
            ctx.validation_failures.append(message)
            raise MonsterValidationError(message)


class BaseErrorWrapper:
    def wrap(self, ctx: MonsterContext, error: Exception, phase: str) -> MonsterError:
        wrapped = MonsterError(f"{phase} aşamasında hata: {error}")
        ctx.last_error = wrapped
        return wrapped


class BaseDispatcher:
    def __init__(self) -> None:
        self._handlers: dict[str, Callable[[MonsterContext], None]] = {}

    def register(self, phase: str, handler: Callable[[MonsterContext], None]) -> None:
        if phase in self._handlers:
            raise MonsterValidationError("Aynı aşama için iki temel işleyici kaydedilemez")
        self._handlers[phase] = handler

    def dispatch(self, ctx: MonsterContext) -> None:
        handler = self._handlers.get(ctx.phase)
        if handler is None:
            raise MonsterValidationError("Temel dağıtıcı bilinmeyen bir aşama gördü")
        ctx.previous_handler = ctx.current_handler
        ctx.current_handler = handler.__name__
        handler(ctx)


class MonsterManager:
    def __init__(self) -> None:
        self.metrics = BaseMetrics()
        self.validator = BaseValidator()
        self.error_wrapper = BaseErrorWrapper()
        self.dispatcher = BaseDispatcher()
        self.legacy_arithmetic = LegacyRemainderAdapter()
        self.legacy_day_tags = LegacyDayTagAdapter()
        self.legacy_distance = LegacyDistanceAdapter()
        self.legacy_stones = LegacyStoneBuilderAdapter()
        self.legacy_hidden = LegacyHiddenDropAdapter()
        self.legacy_prior = LegacyPriorAdapter()
        self.legacy_visible_drops = LegacyVisibleDropBuilderAdapter()
        self.legacy_permutation = LegacyPermutationOrderAdapter()
        self.legacy_pours = LegacyPourAdapter()
        self.legacy_bowl_updates = LegacyBowlUpdateAdapter()
        self.legacy_order_memory = LegacyOverwritableOrderMemoryAdapter()
        self.legacy_next_bowl = LegacyNextBowlAdapter()
        self.legacy_selection = LegacyBiasedSelectionAdapter()
        self.legacy_general_selection = LegacyShortOnlySelectionDispatcher()
        self.legacy_gate_question = LegacyGateQuestionAdapter()
        self.legacy_year_candidates = LegacyYearCandidateAdapter()
        self.legacy_year_jump = LegacyYearJumpAdapter()
        self.legacy_year_cache = LegacyYearNumberOnlyCacheMap()
        self.legacy_structure_sauce = LegacyStructureSauceAdapter()
        self.legacy_cutlet_partition = LegacyCutletPartitionAdapter()
        self.legacy_repeated_names = LegacyRepeatedNameGenerator()
        self.legacy_month_length_materialization = LegacyMonthLengthMaterializationAdapter()
        self.legacy_month_weaving = LegacyMonthWeavingAdapter()
        self.legacy_contiguous_month_day = LegacyContiguousMonthDayAdapter()
        self.legacy_opening_gate_interval = LegacyOpeningGateIntervalAdapter()
