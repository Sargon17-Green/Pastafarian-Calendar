from dataclasses import dataclass
from math import comb

from .legacy_arithmetic import (
    M_OLD,
    regularMod,
)
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


class LegalMonthWeavingDP:
    def __init__(
        self,
        lengths: tuple[int, ...],
    ) -> None:
        normalized = tuple(
            lengths
        )

        if not normalized:
            raise ValueError(
                "Legal ay örgüsü en az bir ay gerektirir"
            )

        if any(
            type(
                value
            )
            is not int
            for value in normalized
        ):
            raise TypeError(
                "Legal ay örgüsü uzunlukları tam sayı olmalıdır"
            )

        if any(
            value < 1
            for value in normalized
        ):
            raise ValueError(
                "Legal ay örgüsü uzunlukları pozitif olmalıdır"
            )

        self.lengths = normalized
        self.month_count = len(
            normalized
        )

        prefix = [
            0
        ]

        for value in normalized:
            prefix.append(
                prefix[
                    -1
                ]
                + value
            )

        self._prefix = tuple(
            prefix
        )
        self._h: list[list[int]] = [
            []
            for _ in range(
                self.month_count
                + 1
            )
        ]
        self._h[
            self.month_count
        ] = [
            1
        ] * (
            prefix[
                -1
            ]
            + 1
        )

        for opened in range(
            self.month_count - 1,
            -1,
            -1,
        ):
            month_length = self.lengths[
                opened
            ]
            max_x = prefix[
                opened
            ]

            if month_length == 1:
                fixed = self._h[
                    opened + 1
                ][
                    0
                ]
                self._h[
                    opened
                ] = [
                    fixed
                ] * (
                    max_x
                    + 1
                )
                continue

            max_y = (
                prefix[
                    opened + 1
                ]
                - 1
            )
            weighted_prefix = [
                0
            ] * (
                max_y
                + 1
            )
            running = 0
            lower = (
                month_length
                - 1
            )

            for y in range(
                max_y + 1
            ):
                if y >= lower:
                    running += (
                        comb(
                            y - 1,
                            month_length - 2,
                        )
                        * self._h[
                            opened + 1
                        ][
                            y
                        ]
                    )

                weighted_prefix[
                    y
                ] = running

            row = [
                0
            ] * (
                max_x
                + 1
            )

            for x in range(
                max_x + 1
            ):
                row[
                    x
                ] = weighted_prefix[
                    x
                    + month_length
                    - 1
                ]

            self._h[
                opened
            ] = row

    def count(
        self,
    ) -> int:
        return self._h[
            0
        ][
            0
        ]

    def state_count(
        self,
        remaining: tuple[int, ...],
        opened: int,
        closed: int,
    ) -> int:
        if (
            opened < closed
            or opened > self.month_count
        ):
            return 0

        base_count = 1
        base_length = 0

        for index in range(
            closed,
            opened,
        ):
            value = remaining[
                index
            ]

            if value <= 0:
                return 0

            if base_length == 0:
                base_length = value
            else:
                base_count *= comb(
                    value
                    + base_length
                    - 1,
                    base_length,
                )
                base_length += value

        if base_length >= len(
            self._h[
                opened
            ]
        ):
            raise AssertionError(
                "Legal ay örgüsü DP state tablosu yetersiz"
            )

        return (
            base_count
            * self._h[
                opened
            ][
                base_length
            ]
        )

    def moves(
        self,
        remaining: tuple[int, ...],
        opened: int,
        closed: int,
    ):
        for index in range(
            closed,
            opened,
        ):
            value = remaining[
                index
            ]

            if value <= 0:
                continue

            if (
                value == 1
                and index != closed
            ):
                continue

            next_remaining = list(
                remaining
            )
            next_remaining[
                index
            ] -= 1
            next_closed = (
                closed + 1
                if next_remaining[
                    index
                ] == 0
                else closed
            )

            yield (
                index + 1,
                tuple(
                    next_remaining
                ),
                opened,
                next_closed,
            )

        if opened < self.month_count:
            index = opened
            next_remaining = list(
                remaining
            )
            next_remaining[
                index
            ] -= 1
            next_opened = (
                opened + 1
            )
            next_closed = closed

            if next_remaining[
                index
            ] == 0:
                if index != closed:
                    raise AssertionError(
                        "Yeni ay legal kapanış sırasını bozdu"
                    )

                next_closed += 1

            yield (
                index + 1,
                tuple(
                    next_remaining
                ),
                next_opened,
                next_closed,
            )

    def unrank1(
        self,
        rank1: int,
    ) -> tuple[int, ...]:
        total = self.count()

        if type(rank1) is not int:
            raise TypeError(
                "Legal ay örgüsü derecesi tam sayı olmalıdır"
            )

        if not 1 <= rank1 <= total:
            raise ValueError(
                "Legal ay örgüsü derecesi aralık dışında"
            )

        remaining = self.lengths
        opened = 0
        closed = 0
        output: list[int] = []
        total_days = sum(
            self.lengths
        )

        while len(
            output
        ) < total_days:
            selected = False

            for (
                month_id,
                next_remaining,
                next_opened,
                next_closed,
            ) in self.moves(
                remaining,
                opened,
                closed,
            ):
                block = self.state_count(
                    next_remaining,
                    next_opened,
                    next_closed,
                )

                if rank1 > block:
                    rank1 -= block
                    continue

                output.append(
                    month_id
                )
                remaining = next_remaining
                opened = next_opened
                closed = next_closed
                selected = True
                break

            if not selected:
                raise AssertionError(
                    "Legal ay örgüsü lexicographic unrank ilerleyemedi"
                )

        if (
            any(
                remaining
            )
            or opened != self.month_count
            or closed != self.month_count
        ):
            raise AssertionError(
                "Legal ay örgüsü final state geçersiz"
            )

        return tuple(
            output
        )


def compatibleMonthWeavingRank(
    ring: LegacyAnswerRing,
    family_count: int,
) -> int:
    if type(family_count) is not int:
        raise TypeError(
            "Ay örgüsü family count tam sayı olmalıdır"
        )

    if family_count < 1:
        raise ValueError(
            "Ay örgüsü family count pozitif olmalıdır"
        )

    if family_count <= M_OLD:
        acceptance_limit = (
            M_OLD
            // family_count
        ) * family_count
        offset = 0
        answer = answerAtRing(
            ring,
            offset,
        )

        while answer > acceptance_limit:
            offset += 1
            answer = answerAtRing(
                ring,
                offset,
            )

        return regularMod(
            answer - 1,
            family_count,
        ) + 1

    places = 1
    space = M_OLD

    while space < family_count:
        places += 1
        space *= M_OLD

    wide = 1
    weight = 1

    for position in range(
        places
    ):
        wide += (
            answerAtRing(
                ring,
                position,
            )
            - 1
        ) * weight
        weight *= M_OLD

    acceptance_limit = (
        space
        // family_count
    ) * family_count

    while wide > acceptance_limit:
        wide = 1 + regularMod(
            wide
            - 1
            + ring.direction_step,
            space,
        )

    return regularMod(
        wide - 1,
        family_count,
    ) + 1


def DPUnrankLegalWeaving(
    lengths: tuple[int, ...],
    rank1: int,
) -> tuple[int, ...]:
    return LegalMonthWeavingDP(
        lengths
    ).unrank1(
        rank1
    )


class MonthWeavingPatchWrapper:
    def repair(
        self,
        ctx,
        lengths: tuple[int, ...],
        ring: LegacyAnswerRing,
        ghost: tuple[int, ...],
    ) -> tuple[int, ...]:
        legal_family = LegalMonthWeavingDP(
            lengths
        )
        legal_count = legal_family.count()
        wantedRank = compatibleMonthWeavingRank(
            ring,
            legal_count,
        )
        correct_weaving = legal_family.unrank1(
            wantedRank
        )
        ghost_matches_correct = (
            ghost
            == correct_weaving
        )
        semantic = (
            ghost
            if ghost_matches_correct
            else correct_weaving
        )

        ctx.branch_trace.append(
            (
                "YAMA_24_LEGAL_AY_ÖRGÜSÜ",
                lengths,
                legal_count,
                wantedRank,
                ghost_matches_correct,
            )
        )
        ctx.logs.append(
            (
                "yama-24-legal-ay-örgüsü",
                lengths,
                legal_count,
                wantedRank,
                ghost_matches_correct,
            )
        )

        ctx.patch24_ghost = ghost
        ctx.patch24_legal_family_count = legal_count
        ctx.patch24_wanted_rank = wantedRank
        ctx.patch24_correct_weaving = correct_weaving
        ctx.patch24_ghost_equals_correct = ghost_matches_correct
        ctx.patch24_returned_ghost = ghost_matches_correct
        ctx.patch24_semantic_weaving = semantic
        ctx.patch24_applied = True

        ctx.legacy_month_weaving_semantic = semantic

        return semantic


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

        return MonthWeavingPatchWrapper().repair(
            ctx,
            tuple(
                lengths
            ),
            ring,
            ghost,
        )
