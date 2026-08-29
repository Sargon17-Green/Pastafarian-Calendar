from dataclasses import dataclass

from .legacy_arithmetic import regularMod
from .legacy_selection import (
    LegacyAnswerRing,
    answerAtRing,
    buildAnswerRingFromSauceState,
)


SEAL_MONTH_WEAVING_LEGACY = 32


@dataclass(
    slots=True,
)
class _SemanticStructureWeavingView:
    legacy_post_stir_final_bowls: tuple[int, ...]
    orderAt46Latch: tuple[int, ...]


def wrapMonth(
    month_id: int,
    month_count: int,
) -> int:
    if type(month_id) is not int:
        raise TypeError(
            "Ay kimliği tam sayı olmalıdır"
        )

    if type(month_count) is not int:
        raise TypeError(
            "Ay sayısı tam sayı olmalıdır"
        )

    if month_count < 1:
        raise ValueError(
            "Ay sayısı pozitif olmalıdır"
        )

    return 1 + regularMod(
        month_id - 1,
        month_count,
    )


def legacyChooseEachDaySeparately(
    lengths: tuple[int, ...],
    answer_stream: LegacyAnswerRing,
) -> tuple[int, ...]:
    normalized = tuple(
        lengths
    )

    if not normalized:
        raise ValueError(
            "Legacy gün-gün ay seçimi en az bir ay gerektirir"
        )

    if any(
        type(
            value
        )
        is not int
        for value in normalized
    ):
        raise TypeError(
            "Legacy gün-gün ay seçimi ay uzunluklarını tam sayı gerektirir"
        )

    if any(
        value < 1
        for value in normalized
    ):
        raise ValueError(
            "Legacy gün-gün ay seçimi pozitif ay uzunlukları gerektirir"
        )

    month_count = len(
        normalized
    )
    remaining = list(
        normalized
    )
    ghost: list[int] = []

    for day_position in range(
        1,
        sum(
            normalized
        )
        + 1,
    ):
        month_id = regularMod(
            answerAtRing(
                answer_stream,
                day_position - 1,
            )
            - 1,
            month_count,
        ) + 1

        spins = 0

        while remaining[
            month_id - 1
        ] == 0:
            month_id = wrapMonth(
                month_id + 1,
                month_count,
            )
            spins += 1

            if spins > month_count:
                raise AssertionError(
                    "Legacy gün-gün ay seçimi boş kalan-ay halkasında ilerleyemedi"
                )

        ghost.append(
            month_id
        )
        remaining[
            month_id - 1
        ] -= 1

    if any(
        remaining
    ):
        raise AssertionError(
            "Legacy gün-gün ay seçimi multiplicity artık bıraktı"
        )

    return tuple(
        ghost
    )


def buildMonthWeavingAnswerRing(
    ctx,
) -> LegacyAnswerRing:
    if ctx.patch20_semantic_bowls is None:
        raise RuntimeError(
            "Ay örgüsü answer ring'i için semantic structure bowls hazır olmalıdır"
        )

    if ctx.patch20_semantic_order_at_drop_46 is None:
        raise RuntimeError(
            "Ay örgüsü answer ring'i için semantic drop 46 order hazır olmalıdır"
        )

    view = _SemanticStructureWeavingView(
        legacy_post_stir_final_bowls=(
            ctx.patch20_semantic_bowls
        ),
        orderAt46Latch=(
            ctx.patch20_semantic_order_at_drop_46
        ),
    )

    return buildAnswerRingFromSauceState(
        view,
        4,
        SEAL_MONTH_WEAVING_LEGACY,
    )


class LegacyMonthWeavingAdapter:
    def call(
        self,
        ctx,
        lengths: tuple[int, ...],
    ) -> tuple[int, ...]:
        ring = buildMonthWeavingAnswerRing(
            ctx
        )
        ghost = legacyChooseEachDaySeparately(
            lengths,
            ring,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_GÜN_GÜN_AY_SEÇİMİ",
                lengths,
                ring.first,
                ring.direction_step,
            )
        )
        ctx.logs.append(
            (
                "eski-gün-gün-ay-seçimi",
                lengths,
                ring.first,
                ring.direction_step,
            )
        )

        ctx.legacy_month_weaving_lengths = tuple(
            lengths
        )
        ctx.legacy_month_weaving_answer_first = ring.first
        ctx.legacy_month_weaving_answer_direction_step = (
            ring.direction_step
        )
        ctx.legacy_month_weaving_ghost = ghost
        ctx.legacy_month_weaving_semantic = ghost
        ctx.legacy_month_weaving_calls += 1

        return ghost
