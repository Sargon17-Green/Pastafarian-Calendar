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


class SelectionRejectionPatchWrapper:
    def repair(
        self,
        ctx,
        ring: LegacyAnswerRing,
        n: int,
    ) -> int:
        if n < 1 or n > M_OLD:
            raise ValueError("Kısa seçim büyüklüğü 1 ile M arasında olmalıdır")

        limit = (M_OLD // n) * n
        offset = 0
        x = answerAtRing(
            ring,
            offset,
        )

        ctx.branch_trace.append(
            (
                "YAMA_13_REJECTION",
                x,
                n,
                limit,
            )
        )
        ctx.logs.append(
            (
                "yama-13-rejection",
                x,
                n,
                limit,
            )
        )

        while x > limit:
            offset += 1
            x = answerAtRing(
                ring,
                offset,
            )

        # Tarihsel helper yalnız accepted answer bulunduktan sonra çağrılır.
        result = biasedLegacyPick(
            x,
            n,
        )

        ctx.patch13_limit = limit
        ctx.patch13_accepted_offset = offset
        ctx.patch13_accepted_answer = x
        ctx.patch13_rejection_count = offset
        ctx.patch13_legacy_pick_result = result
        ctx.patch13_applied = True

        return result


class LegacyBiasedSelectionAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = SelectionRejectionPatchWrapper()

    def call_with_ring(
        self,
        ctx,
        ring: LegacyAnswerRing,
        n: int,
    ) -> int:
        first = answerAtRing(
            ring,
            0,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_YANLI_MODULO_SEÇİM",
                first,
                n,
            )
        )
        ctx.logs.append(
            (
                "eski-yanlı-modulo-seçim",
                first,
                n,
            )
        )

        result = self.patch_wrapper.repair(
            ctx,
            ring,
            n,
        )

        ctx.legacy_selection_first_answer = first
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


def wideDetour(
    ctx,
    ring: LegacyAnswerRing,
    n: int,
) -> int:
    if n <= M_OLD:
        raise ValueError("Geniş seçim büyüklüğü M değerinden büyük olmalıdır")

    places = 1
    space = M_OLD

    while space < n:
        places += 1
        space *= M_OLD

    digits: list[int] = []
    wide = 1
    weight = 1

    j = 0
    while j < places:
        digit = answerAtRing(
            ring,
            j,
        ) - 1
        digits.append(
            digit,
        )
        wide += digit * weight
        weight *= M_OLD
        j += 1

    initial_wide = wide
    acceptance_limit = (
        space // n
    ) * n
    rejection_count = 0

    while wide > acceptance_limit:
        wide = 1 + regularMod(
            wide
            - 1
            + ring.direction_step,
            space,
        )
        rejection_count += 1

    result = regularMod(
        wide - 1,
        n,
    ) + 1

    ctx.patch14_places = places
    ctx.patch14_space = space
    ctx.patch14_digits = tuple(digits)
    ctx.patch14_initial_wide = initial_wide
    ctx.patch14_acceptance_limit = acceptance_limit
    ctx.patch14_rejection_count = rejection_count
    ctx.patch14_accepted_wide = wide
    ctx.patch14_result = result
    ctx.patch14_applied = True

    return result


class WideSelectionPatchWrapper:
    def __init__(
        self,
        short_adapter: LegacyBiasedSelectionAdapter,
    ) -> None:
        self.short_adapter = short_adapter

    def repair(
        self,
        ctx,
        ring: LegacyAnswerRing,
        n: int,
    ) -> int:
        if n < 1:
            raise ValueError("Seçim ailesi boş olamaz")

        if n <= M_OLD:
            ctx.patch14_used_wide_path = False
            return self.short_adapter.call_with_ring(
                ctx,
                ring,
                n,
            )

        # Discovery 14 scar'ı fiziksel olarak korunur:
        # wide input önce eski short-only varsayıma gerçekten çarptırılır.
        try:
            self.short_adapter.call_with_ring(
                ctx,
                ring,
                n,
            )
        except ValueError as exc:
            ctx.legacy_wide_selection_unsupported = True
            ctx.legacy_wide_selection_error = str(exc)

        ctx.patch14_used_wide_path = True
        return wideDetour(
            ctx,
            ring,
            n,
        )


class LegacyShortOnlySelectionDispatcher:
    def __init__(self) -> None:
        self.short_adapter = LegacyBiasedSelectionAdapter()
        self.patch_wrapper = WideSelectionPatchWrapper(
            self.short_adapter,
        )

    def call_with_ring(
        self,
        ctx,
        ring: LegacyAnswerRing,
        n: int,
    ) -> int:
        ctx.branch_trace.append(
            (
                "ESKİ_YALNIZ_KISA_SEÇİM",
                n,
            )
        )
        ctx.logs.append(
            (
                "eski-yalnız-kısa-seçim",
                n,
            )
        )

        ctx.legacy_general_selection_n = n
        ctx.legacy_general_selection_used_short_path = True

        result = self.patch_wrapper.repair(
            ctx,
            ring,
            n,
        )

        ctx.legacy_general_selection_result = result

        if n <= M_OLD:
            ctx.legacy_wide_selection_unsupported = False
            ctx.legacy_wide_selection_error = None

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
