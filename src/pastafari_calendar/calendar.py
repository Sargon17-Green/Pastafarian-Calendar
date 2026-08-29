from .legacy_arithmetic import M_OLD
from .legacy_selection import buildAnswerRingFromSauceState
from .legacy_day_counts import FOUNDATION_DAY_OLD
from .legacy_year_candidates import LegacyYearCandidate
from .legacy_year_jump import LegacyYearJumpAnchor
from .legacy_year_cache import LegacyYearCacheRequest, LegacyYearCacheValue
from .source_language_catalog import SOURCE_LANGUAGE_CATALOG
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
        local_ctx.phase = "ESKİ_YANLI_MODULO_SEÇİM"

    def legacy_biased_selection_handler(local_ctx: MonsterContext) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 13 probe'u gerçek sauce state'inden bowl 1 / seal 21
        # answer ring'ini kurar. N, mevcut ilk cevaptan türetilir;
        # güvenli probe rejection gerekiyorsa tek geri adımda kabul verir; diğer durumlarda N=M_OLD kullanır.
        ring = buildAnswerRingFromSauceState(
            local_ctx,
            1,
            21,
        )
        n = (
            ring.first - 1
            if (
                ring.direction_step == -1
                and ring.first > M_OLD // 2
                and ring.first > 1
            )
            else M_OLD
        )

        manager.legacy_selection.call_with_ring(
            local_ctx,
            ring,
            n,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.selection.probes",
        )
        local_ctx.status = "ESKİ_YANLI_MODULO_SEÇİM_HAZIR"
        local_ctx.phase = "ESKİ_YALNIZ_KISA_GENEL_SEÇİM"

    def legacy_short_only_general_selection_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        ring = buildAnswerRingFromSauceState(
            local_ctx,
            1,
            21,
        )

        manager.legacy_general_selection.call_with_ring(
            local_ctx,
            ring,
            M_OLD + 1,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.selection.wideAttempts",
        )
        local_ctx.status = "ESKİ_YALNIZ_KISA_GENEL_SEÇİM_HAZIR"
        local_ctx.phase = "ESKİ_GATE_SORU_GÜNÜ"

    def legacy_gate_question_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 15: gerçek production yolu negatif gate adımını legacy helper'a verir.
        manager.legacy_gate_question.call(
            local_ctx,
            -1,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.gateQuestion.probes",
        )
        local_ctx.status = "ESKİ_GATE_SORU_GÜNÜ_HAZIR"
        local_ctx.phase = "ESKİ_5781_YIL_ADAYLARI"

    def legacy_year_candidate_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 16 boundary probe ailesi candidate ceiling ve sort girişini
        # gerçek production state-machine üzerinde çalıştırır.
        # Selection çağrısı burada tekrarlanmaz; önceki selection scar call-count
        # sözleşmeleri aynen korunur.
        close_day = FOUNDATION_DAY_OLD
        candidates = tuple(
            LegacyYearCandidate(
                label=f"sınır-{length}",
                length=length,
                open_day=close_day - length,
                close_day=close_day,
                gate_gap_count=6,
            )
            for length in (
                5778,
                5779,
                5780,
                5781,
            )
        )

        manager.legacy_year_candidates.prepare_for_selection(
            local_ctx,
            candidates,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.yearCandidates.probes",
        )
        local_ctx.status = "ESKİ_5781_YIL_ADAYLARI_HAZIR"
        local_ctx.phase = "ESKİ_5000_STABLE_LENGTH_TIE"

    def legacy_year5000_tie_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 17 witness family yalnız equal-length opening-order kusurunu yoklar.
        # Bütün adaylar calculation_day değerini içerir ve Stage 33 ceiling altında kalır.
        tie_length = 5000
        late_open = calculation_day - 100
        middle_open = calculation_day - 200
        early_open = calculation_day - 300

        candidates = (
            LegacyYearCandidate(
                label="5000-geç-açılış",
                length=tie_length,
                open_day=late_open,
                close_day=late_open + tie_length,
                gate_gap_count=6,
            ),
            LegacyYearCandidate(
                label="5000-erken-açılış",
                length=tie_length,
                open_day=early_open,
                close_day=early_open + tie_length,
                gate_gap_count=6,
            ),
            LegacyYearCandidate(
                label="5000-orta-açılış",
                length=tie_length,
                open_day=middle_open,
                close_day=middle_open + tie_length,
                gate_gap_count=6,
            ),
        )

        manager.legacy_year_candidates.sort_year5000_candidates_after_filter(
            local_ctx,
            calculation_day,
            candidates,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.year5000.tieProbes",
        )
        local_ctx.status = "ESKİ_5000_STABLE_LENGTH_TIE_HAZIR"
        local_ctx.phase = "ESKİ_365_YIL_SIÇRAMA_TAHMİNİ"

    def legacy_year_jump_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 18 Year-5000 witness anchor: 5000 günlük yıl Stage 33 ceiling
        # altında kalır. Hedef, close_day sonrasındaki ilk gündür; authoritative
        # ardışık yıl mantığında bu yalnız year 5001 olabilir, fakat legacy /365
        # tahmini doğrudan semantic sayı olarak kullanıldığı için çok ileri sıçrar.
        anchor_open_day = (
            calculation_day
            - 100
        )

        anchor = LegacyYearJumpAnchor(
            number=5000,
            first_day=anchor_open_day + 1,
            open_day=anchor_open_day,
            close_day=anchor_open_day + 5000,
        )

        jump_target_day = (
            anchor.close_day
            + 1
        )

        manager.legacy_year_jump.call(
            local_ctx,
            anchor,
            jump_target_day,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.yearJump.probes",
        )
        local_ctx.status = "ESKİ_365_YIL_SIÇRAMA_TAHMİNİ_HAZIR"
        local_ctx.phase = "ESKİ_YALNIZ_YIL_NUMARASI_CACHE"

    def legacy_year_cache_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.legacy_jump_semantic_year_number is None:
            raise RuntimeError(
                "Year cache başlamadan önce semantic year number hazır olmalıdır"
            )

        if (
            local_ctx.patch18_result_open_day is None
            or local_ctx.patch18_result_close_day is None
        ):
            raise RuntimeError(
                "Year cache başlamadan önce semantic year sınırları hazır olmalıdır"
            )

        year_number = local_ctx.legacy_jump_semantic_year_number
        open_gate = local_ctx.patch18_result_open_day
        close_gate = local_ctx.patch18_result_close_day

        first_request = LegacyYearCacheRequest(
            year_number=year_number,
            calculation_day=calculation_day,
            open_gate=open_gate,
            close_gate=close_gate,
            value=LegacyYearCacheValue(
                token="ilk-yıl-yapısı",
            ),
        )

        second_request = LegacyYearCacheRequest(
            year_number=year_number,
            calculation_day=calculation_day + 1,
            open_gate=open_gate,
            close_gate=close_gate,
            value=LegacyYearCacheValue(
                token="ikinci-yıl-yapısı",
            ),
        )

        manager.legacy_year_cache.lookup_or_store(
            local_ctx,
            first_request,
        )
        reused = manager.legacy_year_cache.lookup_or_store(
            local_ctx,
            second_request,
        )

        # Keşif 19 kusuru: yalnız year.number key stale ilk value'yu döndürür.
        local_ctx.legacy_year_cache_semantic_token = reused.token

        manager.metrics.bump(
            local_ctx,
            "legacy.yearCache.probes",
        )
        local_ctx.status = "ESKİ_YALNIZ_YIL_NUMARASI_CACHE_HAZIR"
        local_ctx.phase = "ESKİ_ORİJİNAL_TARGET_STRUCTURE_SAUCE"

    def legacy_structure_sauce_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.patch18_result_open_day is None:
            raise RuntimeError(
                "Structure sauce başlamadan önce resolved year open gate hazır olmalıdır"
            )

        year_first_day = (
            local_ctx.patch18_result_open_day
            + 1
        )

        manager.legacy_structure_sauce.call(
            local_ctx,
            calculation_day,
            target_day,
            year_first_day,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.structureSauce.probes",
        )
        local_ctx.status = "ESKİ_ORİJİNAL_TARGET_STRUCTURE_SAUCE_HAZIR"
        local_ctx.phase = "ESKİ_GATE_FİLTRESİZ_KÖFTE_BÖLÜMÜ"

    def legacy_cutlet_partition_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 21 witness ailesi: yıl içinde 9 gate aralığı ve 6 köfte vardır.
        # calculation-day gate, opening gate'ten 4 aralık sonra iç gate olarak taşınır.
        # Legacy aile bu bilgiyi kaydeder fakat hiçbir semantic filtre uygulamaz.
        manager.legacy_cutlet_partition.call(
            local_ctx,
            9,
            6,
            4,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.cutletPartition.probes",
        )
        local_ctx.status = "ESKİ_GATE_FİLTRESİZ_KÖFTE_BÖLÜMÜ_HAZIR"
        local_ctx.phase = "ESKİ_TEKRARLI_KÖFTE_ADLARI"

    def legacy_repeated_cutlet_names_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.legacy_cutlet_count is None:
            raise RuntimeError(
                "Köfte adları seçilmeden önce köfte sayısı hazır olmalıdır"
            )

        selected = manager.legacy_repeated_names.call_cutlet_names(
            local_ctx,
            len(
                SOURCE_LANGUAGE_CATALOG.cutlets
            ),
            local_ctx.legacy_cutlet_count,
        )

        local_ctx.legacy_cutlet_name_indices = selected

        manager.metrics.bump(
            local_ctx,
            "legacy.repeatedCutletNames.probes",
        )
        local_ctx.status = "ESKİ_TEKRARLI_KÖFTE_ADLARI_HAZIR"
        local_ctx.phase = "ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ"

    def legacy_month_length_materialization_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 23 için güvenli fakat gerçekçi witness:
        # 300 günlük bir yılın 10 ay uzunluğuna ayrılması.
        # Legacy API "bütün yolların concrete listesi" görünümünü korur.
        # Alt-aile kanıtı materialization başlamadan milyarlarca legal yol
        # bulunduğunu gösterir; safe recovery OOM oluşmadan eski kusuru kaydeder.
        manager.legacy_month_length_materialization.call(
            local_ctx,
            300,
            10,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.monthLengthMaterialization.probes",
        )
        local_ctx.status = "ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ_HAZIR"
        local_ctx.phase = "ESKİ_GÜN_GÜN_AY_SEÇİMİ"

    def legacy_month_weaving_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        # Keşif 24 witness'i bilinçli olarak küçüktür:
        # üç ayın her biri dört gün sürer.
        # Bu, old day-by-day chooser'ın first/last weaving sırasını bozmasını
        # OOM veya dev state olmadan doğrudan görünür kılar.
        manager.legacy_month_weaving.call(
            local_ctx,
            (
                4,
                4,
                4,
            ),
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.monthWeavingDayByDay.probes",
        )
        local_ctx.status = "ESKİ_GÜN_GÜN_AY_SEÇİMİ_HAZIR"
        local_ctx.phase = "ESKİ_AY_GÜNÜ_SÜREKLİYMİŞ_GİBİ"

    def legacy_contiguous_month_day_handler(
        local_ctx: MonsterContext,
    ) -> None:
        manager.validator.require_context_owned(
            local_ctx,
            calculation_day,
            target_day,
        )

        if local_ctx.patch24_semantic_weaving is None:
            raise RuntimeError(
                "Legacy ay-günü tahmini başlamadan önce corrected weaving hazır olmalıdır"
            )

        # Keşif 25 witness'i real path üzerinde yılın dördüncü gününü kullanır.
        # Patch 24 semantic weaving içinde month 1 bu noktada non-contiguous olabilir.
        # Legacy helper yalnız ilk occurrence ile target arasındaki mesafeyi day-in-month sanır.
        manager.legacy_contiguous_month_day.call(
            local_ctx,
            local_ctx.patch24_semantic_weaving,
            4,
        )

        manager.metrics.bump(
            local_ctx,
            "legacy.contiguousMonthDay.probes",
        )
        local_ctx.status = "ESKİ_AY_GÜNÜ_SÜREKLİYMİŞ_GİBİ_HAZIR"
        local_ctx.phase = "AŞAMA_51_BEKLEME"

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
    manager.dispatcher.register("ESKİ_YANLI_MODULO_SEÇİM", legacy_biased_selection_handler)
    manager.dispatcher.register("ESKİ_YALNIZ_KISA_GENEL_SEÇİM", legacy_short_only_general_selection_handler)
    manager.dispatcher.register("ESKİ_GATE_SORU_GÜNÜ", legacy_gate_question_handler)
    manager.dispatcher.register("ESKİ_5781_YIL_ADAYLARI", legacy_year_candidate_handler)
    manager.dispatcher.register("ESKİ_5000_STABLE_LENGTH_TIE", legacy_year5000_tie_handler)
    manager.dispatcher.register("ESKİ_365_YIL_SIÇRAMA_TAHMİNİ", legacy_year_jump_handler)
    manager.dispatcher.register("ESKİ_YALNIZ_YIL_NUMARASI_CACHE", legacy_year_cache_handler)
    manager.dispatcher.register("ESKİ_ORİJİNAL_TARGET_STRUCTURE_SAUCE", legacy_structure_sauce_handler)
    manager.dispatcher.register("ESKİ_GATE_FİLTRESİZ_KÖFTE_BÖLÜMÜ", legacy_cutlet_partition_handler)
    manager.dispatcher.register("ESKİ_TEKRARLI_KÖFTE_ADLARI", legacy_repeated_cutlet_names_handler)
    manager.dispatcher.register("ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ", legacy_month_length_materialization_handler)
    manager.dispatcher.register("ESKİ_GÜN_GÜN_AY_SEÇİMİ", legacy_month_weaving_handler)
    manager.dispatcher.register("ESKİ_AY_GÜNÜ_SÜREKLİYMİŞ_GİBİ", legacy_contiguous_month_day_handler)
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

    # Aşama 39 terminal mesajı önceki regression scar'ı olarak bilerek korunur.
    raise StageNotIntegratedError(
        "Otuz dokuzuncu aşamada üretim takvim yolu henüz birleştirilmedi"
    )
