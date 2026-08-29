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
        local_ctx.phase = "ESKİ_GİZLİ_DAMLALAR"

    def legacy_hidden_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )
        manager.legacy_hidden.call(local_ctx)

        # Discovery 05'in gerçek yanlış erişimi: hidden1 sanılarak doğrudan slot 1 okunur.
        manager.legacy_hidden.read_by_nearness(
            local_ctx,
            1,
        )

        manager.metrics.bump(local_ctx, "legacy.hidden.builds")
        local_ctx.status = "ESKİ_GİZLİ_DAMLALAR_HAZIR"
        local_ctx.phase = "ESKİ_GÖRÜNÜR_GEÇMİŞ"

    def legacy_prior_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Discovery 06 sırasında visible-drop hesabı henüz kurulmaz.
        # Bu probe, legacyPrior'ın gerçek state-machine yolunda çalıştığını kanıtlar.
        probe_store = {
            1: local_ctx.patch05_corrected_value
            if local_ctx.patch05_corrected_value is not None
            else 0
        }
        local_ctx.legacy_prior_probe_value = manager.legacy_prior.call(
            local_ctx,
            probe_store,
            2,
            1,
        )

        manager.metrics.bump(local_ctx, "legacy.prior.probes")
        local_ctx.status = "ESKİ_GÖRÜNÜR_GEÇMİŞ_HAZIR"
        local_ctx.phase = "ESKİ_GÖRÜNÜR_DAMLALAR"

    def legacy_visible_drop_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        manager.legacy_visible_drops.call(local_ctx)

        manager.metrics.bump(local_ctx, "legacy.visibleDrop.builds")
        local_ctx.status = "ESKİ_GÖRÜNÜR_DAMLALAR_HAZIR"
        local_ctx.phase = "ESKİ_PERMÜTASYON_SIRALARI"

    def legacy_permutation_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.legacy_visible_drop_table is None:
            raise RuntimeError(
                "Görünür damlalar permütasyon sıralarından önce hazır olmalıdır"
            )

        manager.legacy_permutation.build_order_table(
            local_ctx,
            local_ctx.legacy_visible_drop_table,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.permutation.orderTables",
        )
        local_ctx.status = "ESKİ_PERMÜTASYON_SIRALARI_HAZIR"
        local_ctx.phase = "ESKİ_SABİT_KÂSE_POURS"

    def legacy_pour_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        manager.legacy_pours.call(
            local_ctx,
            1,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.pour.probes",
        )
        local_ctx.status = "ESKİ_SABİT_KÂSE_POURS_HAZIR"
        local_ctx.phase = "ESKİ_YERİNDE_KÂSE_GÜNCELLEME"

    def legacy_bowl_update_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.legacy_initial_bowls is None:
            raise RuntimeError(
                "Başlangıç kâseleri yerinde güncellemeden önce hazır olmalıdır"
            )
        if local_ctx.legacy_pour_last_values is None:
            raise RuntimeError(
                "Pour değerleri yerinde güncellemeden önce hazır olmalıdır"
            )

        manager.legacy_bowl_updates.call(
            local_ctx,
            1,
            local_ctx.legacy_initial_bowls,
            local_ctx.legacy_pour_last_values,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.bowlUpdate.probes",
        )
        local_ctx.status = "ESKİ_YERİNDE_KÂSE_GÜNCELLEME_HAZIR"
        local_ctx.phase = "ESKİ_YAZILABİLİR_ORDER_HAFIZASI"

    def legacy_order_memory_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        manager.legacy_order_memory.run(
            local_ctx,
        )

        # Discovery 11 semantic query yolu latch yerine son yazılan belleği okur.
        manager.legacy_order_memory.query_order(
            local_ctx,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.orderMemory.fullPasses",
        )
        local_ctx.status = "ESKİ_YAZILABİLİR_ORDER_HAFIZASI_HAZIR"
        local_ctx.phase = "ESKİ_SABİT_ID_SONRAKİ_KÂSE"

    def legacy_next_bowl_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.orderAt46Latch is None:
            raise RuntimeError(
                "Drop 46 order latch sonraki kâse probe'undan önce hazır olmalıdır"
            )

        # Discovery 12 production probe, latch içindeki gerçek bir queried ID kullanır.
        queried_id = local_ctx.orderAt46Latch[3]

        manager.legacy_next_bowl.call(
            local_ctx,
            queried_id,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.nextBowl.probes",
        )
        local_ctx.status = "ESKİ_SABİT_ID_SONRAKİ_KÂSE_HAZIR"
        local_ctx.phase = "AŞAMA_24_BEKLEME"

    manager.dispatcher.register("GİRİŞ", entry_handler)
    manager.dispatcher.register("ESKİ_KALAN", legacy_remainder_handler)
    manager.dispatcher.register("ESKİ_GÜN_ETİKETLERİ", legacy_day_tag_handler)
    manager.dispatcher.register("ESKİ_MESAFE", legacy_distance_handler)
    manager.dispatcher.register("ESKİ_TAŞ_TABLOSU", legacy_stone_handler)
    manager.dispatcher.register("ESKİ_GİZLİ_DAMLALAR", legacy_hidden_handler)
    manager.dispatcher.register("ESKİ_GÖRÜNÜR_GEÇMİŞ", legacy_prior_handler)
    manager.dispatcher.register("ESKİ_GÖRÜNÜR_DAMLALAR", legacy_visible_drop_handler)
    manager.dispatcher.register("ESKİ_PERMÜTASYON_SIRALARI", legacy_permutation_handler)
    manager.dispatcher.register("ESKİ_SABİT_KÂSE_POURS", legacy_pour_handler)
    manager.dispatcher.register("ESKİ_YERİNDE_KÂSE_GÜNCELLEME", legacy_bowl_update_handler)
    manager.dispatcher.register("ESKİ_YAZILABİLİR_ORDER_HAFIZASI", legacy_order_memory_handler)
    manager.dispatcher.register("ESKİ_SABİT_ID_SONRAKİ_KÂSE", legacy_next_bowl_handler)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)
    manager.dispatcher.dispatch(ctx)

    raise StageNotIntegratedError(
        "Yirmi beşinci aşamada üretim takvim yolu henüz birleştirilmedi"
    )
