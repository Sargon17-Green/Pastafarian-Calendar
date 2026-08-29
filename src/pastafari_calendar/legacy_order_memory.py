from .legacy_arithmetic import savePatch
from .legacy_bowl_updates import (
    LegacyBowlUpdateAdapter,
)
from .legacy_permutation import patchedOrderFromDrop
from .legacy_pours import LegacyPourAdapter


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

        stir = 1
        while stir <= 12:
            bowls, stir_order, saved_stir_sum = postStirRoundExact(
                stir,
                bowls,
            )

            # Tarihsel kusurun ikinci yarısı: drop 46 sırası ayrı tutulmaz,
            # aynı genel order belleği her post-stir sırasında yeniden yazılır.
            ctx.legacy_overwritable_order_memory = tuple(
                stir_order
            )
            ctx.legacy_order_memory_write_count += 1
            ctx.legacy_order_memory_last_source = (
                "stir",
                stir,
            )
            ctx.legacy_post_stir_last_saved_sum = saved_stir_sum

            stir += 1

        ctx.legacy_post_stir_final_bowls = bowls
        return bowls

    def query_order(
        self,
        ctx,
    ) -> tuple[int, ...]:
        if ctx.legacy_overwritable_order_memory is None:
            raise RuntimeError("Eski sorgu order belleği henüz hazırlanmadı")

        # Discovery 11: sorgu katmanı hâlâ son yazılan genel order belleğini okur.
        return ctx.legacy_overwritable_order_memory
