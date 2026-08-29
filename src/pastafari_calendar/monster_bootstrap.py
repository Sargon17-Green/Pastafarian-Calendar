from dataclasses import dataclass, field
from typing import Any, Callable

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
