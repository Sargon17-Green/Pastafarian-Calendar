from contextvars import ContextVar
from dataclasses import dataclass


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
) -> LegacyStructureSauceResult:
    # Bu standalone core yalnız doğrudan structure-sauce üretimi gerektiğinde
    # current Python implementation'ın kendi adapter zincirini yeniden çalıştırır.
    from .monster_bootstrap import MonsterContext
    from .legacy_day_counts import LegacyDayTagAdapter
    from .legacy_distance import LegacyDistanceAdapter
    from .legacy_stones import LegacyStoneBuilderAdapter
    from .legacy_hidden import LegacyHiddenDropAdapter
    from .legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
    from .legacy_permutation import LegacyPermutationOrderAdapter
    from .legacy_order_memory import LegacyOverwritableOrderMemoryAdapter

    local_ctx = MonsterContext(
        calculation_day=calculation_day,
        target_day=target_day,
    )

    day_tags = LegacyDayTagAdapter()
    distance = LegacyDistanceAdapter()
    stones = LegacyStoneBuilderAdapter()
    hidden = LegacyHiddenDropAdapter()
    visible = LegacyVisibleDropBuilderAdapter()
    permutation = LegacyPermutationOrderAdapter()
    order_memory = LegacyOverwritableOrderMemoryAdapter()

    day_tags.call(
        local_ctx,
        calculation_day,
        "action",
    )
    day_tags.call(
        local_ctx,
        target_day,
        "target",
    )
    distance.call(
        local_ctx,
        calculation_day,
        target_day,
    )
    stones.call(
        local_ctx
    )
    hidden.call(
        local_ctx
    )
    visible.call(
        local_ctx
    )

    if local_ctx.legacy_visible_drop_table is None:
        raise RuntimeError(
            "Structure sauce visible drop tablosu üretilemedi"
        )

    permutation.build_order_table(
        local_ctx,
        local_ctx.legacy_visible_drop_table,
    )

    order_memory.run(
        local_ctx
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


class LegacyStructureSauceAdapter:
    def __init__(
        self,
    ) -> None:
        self.selector = LegacyStructureSelectorAdapter()

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
        ctx.legacy_structure_old_used_by_selector = True
        ctx.legacy_structure_semantic_source = "original-target"
        ctx.legacy_structure_reused_existing_calendar_sauce = (
            source.bowls
            is ctx.legacy_post_stir_final_bowls
        )
        ctx.legacy_structure_calls += 1

        return self.selector.call(
            ctx,
            result,
        )
