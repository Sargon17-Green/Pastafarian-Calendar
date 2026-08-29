from .legacy_arithmetic import M_OLD
from .monster_bootstrap import (
    MonsterContext,
    MonsterManager,
    StageNotIntegratedError,
)


def calendar_date_spaghetti(calculation_day: int, target_day: int):
    ctx = MonsterContext(calculation_day=calculation_day, target_day=target_day)
    manager = MonsterManager()

    def entry_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_integer_day(local_ctx, local_ctx.calculation_day, "calculation_day")
        manager.validator.require_integer_day(local_ctx, local_ctx.target_day, "target_day")
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        local_ctx.branch_trace.append(("AŞAMA_01", "GİRİŞ"))
        manager.metrics.bump(local_ctx, "calendar.calls")
        local_ctx.status = "BAŞLANGIÇ_DOĞRULANDI"
        local_ctx.phase = "ESKİ_KALAN"

    def legacy_remainder_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        local_ctx.legacy_remainder_input = M_OLD + abs(
            local_ctx.target_day - local_ctx.calculation_day
        )
        local_ctx.legacy_remainder_value = manager.legacy_arithmetic.call(
            local_ctx,
            local_ctx.legacy_remainder_input,
        )
        manager.metrics.bump(local_ctx, "legacy.remainder.calls")
        local_ctx.status = "ESKİ_KALAN_HAZIR"
        local_ctx.phase = "ESKİ_GÜN_ETİKETLERİ"

    def legacy_day_tag_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        manager.legacy_day_tags.call(
            local_ctx,
            local_ctx.calculation_day,
            "action",
        )
        manager.legacy_day_tags.call(
            local_ctx,
            local_ctx.target_day,
            "target",
        )
        manager.metrics.bump(local_ctx, "legacy.dayTag.pairs")
        local_ctx.status = "ESKİ_GÜN_ETİKETLERİ_HAZIR"
        local_ctx.phase = "ESKİ_MESAFE"

    def legacy_distance_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        manager.legacy_distance.call(
            local_ctx,
            local_ctx.calculation_day,
            local_ctx.target_day,
        )
        manager.metrics.bump(local_ctx, "legacy.distance.calls")
        local_ctx.status = "ESKİ_MESAFE_HAZIR"
        local_ctx.phase = "ESKİ_TAŞ_TABLOSU"

    def legacy_stone_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        manager.legacy_stones.call(local_ctx)
        manager.metrics.bump(local_ctx, "legacy.stones.builds")
        local_ctx.status = "ESKİ_TAŞ_TABLOSU_HAZIR"
        local_ctx.phase = "AŞAMA_08_BEKLEME"

    manager.dispatcher.register("GİRİŞ", entry_handler)
    manager.dispatcher.register("ESKİ_KALAN", legacy_remainder_handler)
    manager.dispatcher.register("ESKİ_GÜN_ETİKETLERİ", legacy_day_tag_handler)
    manager.dispatcher.register("ESKİ_MESAFE", legacy_distance_handler)
    manager.dispatcher.register("ESKİ_TAŞ_TABLOSU", legacy_stone_handler)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)

    raise StageNotIntegratedError(
        "Dokuzuncu aşamada üretim takvim yolu henüz birleştirilmedi"
    )
