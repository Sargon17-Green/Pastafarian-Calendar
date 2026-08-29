from .legacy_arithmetic import savePatch
from .legacy_bowl_updates import (
    LegacyBowlUpdateAdapter,
)
from .legacy_permutation import patchedOrderFromDrop
from .legacy_pours import LegacyPourAdapter
from .post_stir_bowlsum_detour import rawBowlSumPostStirDetour


def postStirRoundExact(
    stir: int,
    bowls: tuple[int, ...],
) -> tuple[tuple[int, ...], tuple[int, ...], int]:
    if stir < 1 or stir > 12:
        raise ValueError("Sonraki karıştırma numarası 1 ile 12 arasında olmalıdır")

    old = tuple(list(bowls))
    saved_stir_sum = savePatch(
        sum(old[1:7])
        + 149 * stir
    )
    order = patchedOrderFromDrop(
        saved_stir_sum,
    )
    pending = [0] * 7

    position = 1
    while position <= 6:
        bowl_id = order[position - 1]
        prev_id = order[(position - 2) % 6]
        next_id = order[position % 6]

        s = (
            old[bowl_id]
            + 3 * old[prev_id]
            + 5 * old[next_id]
            + saved_stir_sum
            + stir
            + position * position
        )

        pending[bowl_id] = savePatch(
            s * s
            + 7 * old[prev_id] * old[next_id]
        )

        position += 1

    return (
        tuple(pending),
        order,
        saved_stir_sum,
    )


class LegacyOverwritableOrderMemoryAdapter:
    def __init__(self) -> None:
        self.pours = LegacyPourAdapter()
        self.bowl_updates = LegacyBowlUpdateAdapter()

    def run(
        self,
        ctx,
    ) -> tuple[int, ...]:
        if ctx.legacy_visible_drop_table is None:
            raise RuntimeError("Görünür damlalar tam kâse geçişinden önce hazır olmalıdır")
        if ctx.legacy_permutation_order_table is None:
            raise RuntimeError("Permütasyon sıraları tam kâse geçişinden önce hazır olmalıdır")

        bowls = self.pours.ensure_initial_bowls(
            ctx,
        )
        ctx.legacy_overwritable_order_memory = None
        ctx.legacy_order_memory_write_count = 0
        ctx.legacy_order_memory_last_source = None

        i = 1
        while i <= 46:
            pours = self.pours.call_with_bowls(
                ctx,
                i,
                bowls,
            )
            bowls = self.bowl_updates.call(
                ctx,
                i,
                bowls,
                pours,
            )

            # Tarihsel kusurun ilk yarısı: tek bir genel order belleği kullanılır.
            ctx.legacy_overwritable_order_memory = tuple(
                ctx.legacy_permutation_order_table[i]
            )
            ctx.legacy_order_memory_write_count += 1
            ctx.legacy_order_memory_last_source = (
                "drop",
                i,
            )

            i += 1

        ctx.legacy_bowls_after_46_drops = bowls

        # Yama 11: drop 46 order post-stir başlamadan hemen önce
        # ayrı bir latch'e fiziksel clone olarak yalnızca bir kez yazılır.
        if ctx.orderAt46Latch is not None:
            raise RuntimeError("Drop 46 order latch bir çağrıda yalnızca bir kez yazılabilir")

        ctx.orderAt46Latch = tuple(
            list(
                ctx.legacy_permutation_order_table[46]
            )
        )
        ctx.patch11_latch_write_count += 1
        ctx.patch11_latch_source = (
            "drop",
            46,
        )
        ctx.patch11_applied = True

        stir = 1
        while stir <= 12:
            bowls_before_stir = bowls

            # Tarihsel A1 scar kaldırılmaz ve gerçekten yürütülür.
            legacy_wrong_bowls, stir_order, saved_stir_sum = postStirRoundExact(
                stir,
                bowls_before_stir,
            )

            # Düzeltici Aşama 56 spaghetti detour yalnız authoritative final
            # sauce bağlamında açılır. Historical 1–55 ana scar yürüyüşü eski
            # sonucu kullanmayı sürdürür; böylece eski yol fiziksel ve semantik
            # tanık olarak korunur.
            if ctx.corrective56_raw_bowlsum_enabled:
                bowls, corrected_order, raw_bowl_sum, order_number = rawBowlSumPostStirDetour(
                    stir,
                    bowls_before_stir,
                    legacy_wrong_bowls,
                    stir_order,
                    saved_stir_sum,
                )

                ctx.corrective56_post_stir_last_stir = stir
                ctx.corrective56_post_stir_last_raw_bowl_sum = raw_bowl_sum
                ctx.corrective56_post_stir_last_order_number = order_number
                ctx.corrective56_post_stir_last_legacy_wrong_result = legacy_wrong_bowls
                ctx.corrective56_post_stir_last_corrected_result = bowls
                ctx.corrective56_post_stir_applied_count += 1
                ctx.corrective56_post_stir_applied = True
                ctx.branch_trace.append((
                    "DÜZELTİCİ_56_HAM_BOWLSUM_DETOUR",
                    stir,
                    raw_bowl_sum,
                    order_number,
                ))
                ctx.logs.append((
                    "düzeltici-56-ham-bowlsum-detour",
                    stir,
                    raw_bowl_sum,
                    order_number,
                ))
            else:
                bowls = legacy_wrong_bowls
                corrected_order = stir_order
                order_number = saved_stir_sum

            # Tarihsel kusurun ikinci yarısı: drop 46 sırası ayrı tutulmaz,
            # aynı genel order belleği her post-stir sırasında yeniden yazılır.
            ctx.legacy_overwritable_order_memory = tuple(
                corrected_order
            )
            ctx.legacy_order_memory_write_count += 1
            ctx.legacy_order_memory_last_source = (
                "stir",
                stir,
            )
            ctx.legacy_post_stir_last_saved_sum = order_number

            stir += 1

        ctx.legacy_post_stir_final_bowls = bowls
        return bowls

    def query_order(
        self,
        ctx,
    ) -> tuple[int, ...]:
        if ctx.orderAt46Latch is None:
            raise RuntimeError("Drop 46 order latch henüz hazırlanmadı")

        # Yama 11: semantic sorgu yalnızca tek-yazımlı drop 46 latch'i okur.
        return ctx.orderAt46Latch
