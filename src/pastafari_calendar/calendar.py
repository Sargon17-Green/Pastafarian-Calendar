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
        local_ctx.phase = "AŞAMA_02_BEKLEME"

    manager.dispatcher.register("GİRİŞ", entry_handler)
    manager.dispatcher.register("ESKİ_KALAN", legacy_remainder_handler)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)

    raise StageNotIntegratedError(
        "Üçüncü aşamada üretim takvim yolu henüz birleştirilmedi"
    )
