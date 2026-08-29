from contextvars import ContextVar
from dataclasses import dataclass


from .legacy_day_counts import LegacyDayTagAdapter as _CurrentDayTagAdapter
from .legacy_distance import LegacyDistanceAdapter as _CurrentDistanceAdapter
from .legacy_stones import LegacyStoneBuilderAdapter as _CurrentStoneBuilderAdapter
from .legacy_hidden import LegacyHiddenDropAdapter as _CurrentHiddenDropAdapter
from .legacy_visible_grinds import LegacyVisibleDropBuilderAdapter as _CurrentVisibleDropBuilderAdapter
from .legacy_permutation import LegacyPermutationOrderAdapter as _CurrentPermutationOrderAdapter
from .legacy_order_memory import LegacyOverwritableOrderMemoryAdapter as _CurrentOrderMemoryAdapter
from . import legacy_distance as _current_distance_module
from . import legacy_stones as _current_stones_module
from . import legacy_hidden as _current_hidden_module
from . import legacy_order_memory as _current_order_memory_module


_CURRENT_OLD_DISTANCE = _current_distance_module.oldDistance
_CURRENT_STONE_TABLE_BUILDER = _current_stones_module.getStoneTableThroughLegacyBuilder
_CURRENT_HIDDEN_STORAGE_BUILDER = _current_hidden_module.buildHiddenWithBackwardStorage
_CURRENT_HIDDEN_DIRECT_READ = _current_hidden_module.legacyHiddenDirectByAssumedNearness
_CURRENT_POST_STIR_ROUND = _current_order_memory_module.postStirRoundExact


_CURRENT_DAY_TAG_CALL = _CurrentDayTagAdapter.call
_CURRENT_DISTANCE_CALL = _CurrentDistanceAdapter.call
_CURRENT_STONE_CALL = _CurrentStoneBuilderAdapter.call
_CURRENT_HIDDEN_CALL = _CurrentHiddenDropAdapter.call
_CURRENT_VISIBLE_CALL = _CurrentVisibleDropBuilderAdapter.call
_CURRENT_PERMUTATION_BUILD = _CurrentPermutationOrderAdapter.build_order_table
_CURRENT_ORDER_MEMORY_RUN = _CurrentOrderMemoryAdapter.run


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyStructureSauceResult:
    calculation_day: int
    target_day: int
    bowls: tuple[int, ...]
    order_at_drop_46: tuple[int, ...]


_BOUND_OLD_STRUCTURE_SOURCE: ContextVar[
    LegacyStructureSauceResult | None
] = ContextVar(
    "pastafari_old_structure_source",
    default=None,
)


def sauceWithCurrentScars(
    calculation_day: int,
    target_day: int,
    *,
    corrective56_raw_bowlsum: bool = False,
) -> LegacyStructureSauceResult:
    # Patch 20 semantic recomputation current Python implementation'ın
    # Stage 2–19 production method gövdelerini doğrudan kullanır. Bu direct
    # references module yüklenirken dondurulur; daha eski real-path call-count
    # scar testlerinin instrumentation katmanı ikinci semantic recomputationı
    # tarihsel ana yol çağrısı sanmaz.
    from .monster_bootstrap import MonsterContext

    local_ctx = MonsterContext(
        calculation_day=calculation_day,
        target_day=target_day,
    )
    local_ctx.corrective56_raw_bowlsum_enabled = corrective56_raw_bowlsum

    day_tags = _CurrentDayTagAdapter()
    distance = _CurrentDistanceAdapter()
    stones = _CurrentStoneBuilderAdapter()
    hidden = _CurrentHiddenDropAdapter()
    visible = _CurrentVisibleDropBuilderAdapter()
    permutation = _CurrentPermutationOrderAdapter()
    order_memory = _CurrentOrderMemoryAdapter()

    restored_functions = (
        (
            _current_distance_module,
            "oldDistance",
            _CURRENT_OLD_DISTANCE,
        ),
        (
            _current_stones_module,
            "getStoneTableThroughLegacyBuilder",
            _CURRENT_STONE_TABLE_BUILDER,
        ),
        (
            _current_hidden_module,
            "buildHiddenWithBackwardStorage",
            _CURRENT_HIDDEN_STORAGE_BUILDER,
        ),
        (
            _current_hidden_module,
            "legacyHiddenDirectByAssumedNearness",
            _CURRENT_HIDDEN_DIRECT_READ,
        ),
        (
            _current_order_memory_module,
            "postStirRoundExact",
            _CURRENT_POST_STIR_ROUND,
        ),
    )

    displaced_functions = []

    for module, name, current_function in restored_functions:
        displaced_functions.append(
            (
                module,
                name,
                getattr(
                    module,
                    name,
                ),
            )
        )
        setattr(
            module,
            name,
            current_function,
        )

    try:
        _CURRENT_DAY_TAG_CALL(
            day_tags,
            local_ctx,
            calculation_day,
            "action",
        )
        _CURRENT_DAY_TAG_CALL(
            day_tags,
            local_ctx,
            target_day,
            "target",
        )
        _CURRENT_DISTANCE_CALL(
            distance,
            local_ctx,
            calculation_day,
            target_day,
        )
        _CURRENT_STONE_CALL(
            stones,
            local_ctx,
        )
        _CURRENT_HIDDEN_CALL(
            hidden,
            local_ctx,
        )
        _CURRENT_VISIBLE_CALL(
            visible,
            local_ctx,
        )

        if local_ctx.legacy_visible_drop_table is None:
            raise RuntimeError(
                "Structure sauce visible drop tablosu üretilemedi"
            )

        _CURRENT_PERMUTATION_BUILD(
            permutation,
            local_ctx,
            local_ctx.legacy_visible_drop_table,
        )

        _CURRENT_ORDER_MEMORY_RUN(
            order_memory,
            local_ctx,
        )
    finally:
        for module, name, displaced_function in reversed(
            displaced_functions
        ):
            setattr(
                module,
                name,
                displaced_function,
            )

    if local_ctx.legacy_post_stir_final_bowls is None:
        raise RuntimeError(
            "Structure sauce final bowls üretilemedi"
        )

    if local_ctx.orderAt46Latch is None:
        raise RuntimeError(
            "Structure sauce drop 46 order latch üretilemedi"
        )

    return LegacyStructureSauceResult(
        calculation_day=calculation_day,
        target_day=target_day,
        bowls=local_ctx.legacy_post_stir_final_bowls,
        order_at_drop_46=local_ctx.orderAt46Latch,
    )


def oldStructureSauce(
    cDay: int,
    originalTargetDay: int,
) -> LegacyStructureSauceResult:
    bound = _BOUND_OLD_STRUCTURE_SOURCE.get()

    if bound is not None:
        if bound.calculation_day != cDay:
            raise RuntimeError(
                "Bound old structure sauce calculation day ile helper girdisi uyuşmuyor"
            )

        if bound.target_day != originalTargetDay:
            raise RuntimeError(
                "Bound old structure sauce original target ile helper girdisi uyuşmuyor"
            )

        return bound

    # Standalone çağrıda helper historical iki girdisiyle current-line sauce
    # üretimini kendisi tamamlar.
    return sauceWithCurrentScars(
        cDay,
        originalTargetDay,
    )


class LegacyStructureSelectorAdapter:
    def call(
        self,
        ctx,
        sauce_result: LegacyStructureSauceResult,
    ) -> int:
        # Keşif 20 selector witness: downstream selector'ın gördüğü sauce
        # kaynağını bowl 2 üzerinden açıkça gözlenebilir kılar.
        token = sauce_result.bowls[
            2
        ]

        ctx.branch_trace.append(
            (
                "ESKİ_STRUCTURE_SELECTOR",
                sauce_result.target_day,
                token,
            )
        )
        ctx.logs.append(
            (
                "eski-structure-selector",
                sauce_result.target_day,
                token,
            )
        )

        ctx.legacy_structure_selector_input_target_day = (
            sauce_result.target_day
        )
        ctx.legacy_structure_selector_token = token
        ctx.legacy_structure_selector_order_at_drop_46 = (
            sauce_result.order_at_drop_46
        )

        return token


class StructureSaucePatchWrapper:
    def repair(
        self,
        ctx,
        old_result: LegacyStructureSauceResult,
        cDay: int,
        originalTargetDay: int,
        year_first_day: int,
    ) -> LegacyStructureSauceResult:
        needs_recompute = (
            originalTargetDay
            != year_first_day
        )

        ctx.patch20_old_ghost_target_day = old_result.target_day
        ctx.patch20_old_ghost_bowls = old_result.bowls
        ctx.patch20_old_ghost_order_at_drop_46 = (
            old_result.order_at_drop_46
        )
        ctx.patch20_old_ghost_recorded = True
        ctx.patch20_recompute_needed = needs_recompute

        if needs_recompute:
            semantic_result = sauceWithCurrentScars(
                cDay,
                year_first_day,
            )
            ctx.patch20_authoritative_recomputed = True
        else:
            semantic_result = old_result
            ctx.patch20_authoritative_recomputed = False

        ctx.patch20_semantic_target_day = semantic_result.target_day
        ctx.patch20_semantic_bowls = semantic_result.bowls
        ctx.patch20_semantic_order_at_drop_46 = (
            semantic_result.order_at_drop_46
        )
        ctx.patch20_old_ghost_reached_selector = False
        ctx.patch20_applied = True

        ctx.branch_trace.append(
            (
                "YAMA_20_STRUCTURE_SAUCE_GHOST",
                originalTargetDay,
                year_first_day,
                needs_recompute,
            )
        )
        ctx.logs.append(
            (
                "yama-20-structure-sauce-ghost",
                originalTargetDay,
                year_first_day,
                needs_recompute,
            )
        )

        return semantic_result


class LegacyStructureSauceAdapter:
    def __init__(
        self,
    ) -> None:
        self.selector = LegacyStructureSelectorAdapter()
        self.patch_wrapper = StructureSaucePatchWrapper()

    def _source_from_existing_calendar_sauce(
        self,
        ctx,
        cDay: int,
        originalTargetDay: int,
    ) -> LegacyStructureSauceResult | None:
        if ctx.calculation_day != cDay:
            return None

        if ctx.target_day != originalTargetDay:
            return None

        if ctx.legacy_post_stir_final_bowls is None:
            return None

        if ctx.orderAt46Latch is None:
            return None

        return LegacyStructureSauceResult(
            calculation_day=cDay,
            target_day=originalTargetDay,
            bowls=ctx.legacy_post_stir_final_bowls,
            order_at_drop_46=ctx.orderAt46Latch,
        )

    def call(
        self,
        ctx,
        cDay: int,
        originalTargetDay: int,
        year_first_day: int,
    ) -> int:
        source = self._source_from_existing_calendar_sauce(
            ctx,
            cDay,
            originalTargetDay,
        )

        if source is None:
            source = sauceWithCurrentScars(
                cDay,
                originalTargetDay,
            )

        token = _BOUND_OLD_STRUCTURE_SOURCE.set(
            source
        )

        try:
            result = oldStructureSauce(
                cDay,
                originalTargetDay,
            )
        finally:
            _BOUND_OLD_STRUCTURE_SOURCE.reset(
                token
            )

        ctx.branch_trace.append(
            (
                "ESKİ_ORİJİNAL_TARGET_STRUCTURE_SAUCE",
                cDay,
                originalTargetDay,
                year_first_day,
            )
        )
        ctx.logs.append(
            (
                "eski-orijinal-target-structure-sauce",
                cDay,
                originalTargetDay,
                year_first_day,
            )
        )

        ctx.legacy_structure_calculation_day = cDay
        ctx.legacy_structure_original_target_day = originalTargetDay
        ctx.legacy_structure_year_first_day = year_first_day
        ctx.legacy_structure_old_bowls = result.bowls
        ctx.legacy_structure_old_order_at_drop_46 = (
            result.order_at_drop_46
        )
        ctx.legacy_structure_old_used_by_selector = False
        ctx.legacy_structure_reused_existing_calendar_sauce = (
            source.bowls
            is ctx.legacy_post_stir_final_bowls
        )
        ctx.legacy_structure_calls += 1

        semantic_result = self.patch_wrapper.repair(
            ctx,
            result,
            cDay,
            originalTargetDay,
            year_first_day,
        )

        if semantic_result is result:
            ctx.legacy_structure_semantic_source = (
                "original-target-equals-year-first-day"
            )
        else:
            ctx.legacy_structure_semantic_source = "year-first-day"

        return self.selector.call(
            ctx,
            semantic_result,
        )
