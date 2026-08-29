from dataclasses import dataclass

from .legacy_arithmetic import (
    M_OLD,
    regularMod,
    savePatch,
)
from .legacy_next_bowl import latchedCircularSuccessor


@dataclass(frozen=True, slots=True)
class LegacyAnswerRing:
    first: int
    direction_step: int


def buildAnswerRingFromSauceState(
    ctx,
    queried_bowl_id: int,
    seal: int,
) -> LegacyAnswerRing:
    if ctx.legacy_post_stir_final_bowls is None:
        raise RuntimeError("Son kâseler answer ring kurulmadan önce hazır olmalıdır")
    if ctx.orderAt46Latch is None:
        raise RuntimeError("Drop 46 order latch answer ring kurulmadan önce hazır olmalıdır")
    if queried_bowl_id < 1 or queried_bowl_id > 6:
        raise ValueError("Sorgulanan kâse ID değeri 1 ile 6 arasında olmalıdır")

    next_id = latchedCircularSuccessor(
        ctx.orderAt46Latch,
        queried_bowl_id,
    )
    bowls = ctx.legacy_post_stir_final_bowls

    first = savePatch(
        (
            bowls[queried_bowl_id]
            + seal
            + 181
        )
        ** 2
        + bowls[next_id] * 179
        + seal
    )

    direction_number = savePatch(
        (
            first
            + seal
            + 1
            + 193
        )
        ** 2
        + first * 193
        + bowls[6] * 197
    )

    direction_step = (
        1
        if regularMod(
            direction_number,
            2,
        )
        == 1
        else -1
    )

    return LegacyAnswerRing(
        first=first,
        direction_step=direction_step,
    )


def answerAtRing(
    ring: LegacyAnswerRing,
    k: int,
) -> int:
    if k < 0:
        raise ValueError("Answer ring indeksi negatif olamaz")

    return 1 + regularMod(
        ring.first
        - 1
        + ring.direction_step * k,
        M_OLD,
    )


def biasedLegacyPick(
    x: int,
    n: int,
) -> int:
    if x < 1 or x > M_OLD:
        raise ValueError("Legacy seçim cevabı 1 ile M arasında olmalıdır")
    if n < 1 or n > M_OLD:
        raise ValueError("Legacy kısa seçim büyüklüğü 1 ile M arasında olmalıdır")

    # Tarihsel kusur: rejection yapılmadan doğrudan modulo uygulanır.
    return regularMod(
        x - 1,
        n,
    ) + 1


class LegacyBiasedSelectionAdapter:
    def call_with_ring(
        self,
        ctx,
        ring: LegacyAnswerRing,
        n: int,
    ) -> int:
        x = answerAtRing(
            ring,
            0,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_YANLI_MODULO_SEÇİM",
                x,
                n,
            )
        )
        ctx.logs.append(
            (
                "eski-yanlı-modulo-seçim",
                x,
                n,
            )
        )

        # Discovery 13: biased helper rejection olmadan hemen çağrılır.
        result = biasedLegacyPick(
            x,
            n,
        )

        ctx.legacy_selection_first_answer = x
        ctx.legacy_selection_direction_step = ring.direction_step
        ctx.legacy_selection_n = n
        ctx.legacy_selection_result = result

        return result

    def call(
        self,
        ctx,
        queried_bowl_id: int,
        seal: int,
        n: int,
    ) -> int:
        ring = buildAnswerRingFromSauceState(
            ctx,
            queried_bowl_id,
            seal,
        )
        return self.call_with_ring(
            ctx,
            ring,
            n,
        )
