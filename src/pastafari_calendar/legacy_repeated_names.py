from dataclasses import dataclass

from .legacy_arithmetic import (
    M_OLD,
    regularMod,
)
from .legacy_selection import (
    LegacyAnswerRing,
    answerAtRing,
    buildAnswerRingFromSauceState,
)


@dataclass(
    slots=True,
)
class _SemanticStructureNameView:
    legacy_post_stir_final_bowls: tuple[int, ...]
    orderAt46Latch: tuple[int, ...]


def legacyRepeatedNameFamilyCount(
    master_count: int,
    item_count: int,
) -> int:
    if type(master_count) is not int:
        raise TypeError(
            "Legacy ad havuzu boyutu tam sayı olmalıdır"
        )

    if type(item_count) is not int:
        raise TypeError(
            "Legacy ad sayısı tam sayı olmalıdır"
        )

    if master_count < 1:
        raise ValueError(
            "Legacy ad havuzu boş olamaz"
        )

    if item_count < 1:
        raise ValueError(
            "Legacy ad sayısı pozitif olmalıdır"
        )

    return master_count ** item_count


def legacyRepeatedNameUnrank1(
    master_count: int,
    item_count: int,
    rank1: int,
) -> tuple[int, ...]:
    family_count = legacyRepeatedNameFamilyCount(
        master_count,
        item_count,
    )

    if not 1 <= rank1 <= family_count:
        raise ValueError(
            "Legacy tekrarlı ad derecesi aralık dışında"
        )

    rank0 = rank1 - 1
    output: list[int] = []

    for position in range(
        item_count
    ):
        suffix_length = (
            item_count
            - position
            - 1
        )
        block = (
            master_count
            ** suffix_length
        )
        candidate0, rank0 = divmod(
            rank0,
            block,
        )
        output.append(
            candidate0 + 1
        )

    return tuple(
        output
    )


def compatibleRepeatedNameRank(
    ring: LegacyAnswerRing,
    family_count: int,
) -> int:
    if family_count < 1:
        raise ValueError(
            "Legacy ad ailesi boş olamaz"
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


def buildCutletNameAnswerRing(
    ctx,
) -> LegacyAnswerRing:
    if ctx.patch20_semantic_bowls is None:
        raise RuntimeError(
            "Köfte adları answer ring'i için semantic structure bowls hazır olmalıdır"
        )

    if ctx.patch20_semantic_order_at_drop_46 is None:
        raise RuntimeError(
            "Köfte adları answer ring'i için semantic drop 46 order hazır olmalıdır"
        )

    view = _SemanticStructureNameView(
        legacy_post_stir_final_bowls=(
            ctx.patch20_semantic_bowls
        ),
        orderAt46Latch=(
            ctx.patch20_semantic_order_at_drop_46
        ),
    )

    return buildAnswerRingFromSauceState(
        view,
        5,
        22,
    )


class LegacyRepeatedNameGenerator:
    def call_with_ring(
        self,
        ctx,
        ring: LegacyAnswerRing,
        master_count: int,
        item_count: int,
        source_kind: str,
    ) -> tuple[int, ...]:
        family_count = legacyRepeatedNameFamilyCount(
            master_count,
            item_count,
        )
        selected_rank = compatibleRepeatedNameRank(
            ring,
            family_count,
        )
        candidate = legacyRepeatedNameUnrank1(
            master_count,
            item_count,
            selected_rank,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_TEKRARLI_AD_ÜRETECİ",
                source_kind,
                master_count,
                item_count,
                family_count,
                selected_rank,
            )
        )
        ctx.logs.append(
            (
                "eski-tekrarlı-ad-üreteci",
                source_kind,
                master_count,
                item_count,
                family_count,
                selected_rank,
            )
        )

        ctx.legacy_name_source_kind = source_kind
        ctx.legacy_name_master_count = master_count
        ctx.legacy_name_item_count = item_count
        ctx.legacy_name_family_count = family_count
        ctx.legacy_name_selected_rank = selected_rank
        ctx.legacy_name_candidate_indices = candidate
        ctx.legacy_name_candidate_has_repeats = (
            len(
                set(
                    candidate
                )
            )
            != len(
                candidate
            )
        )
        ctx.legacy_name_semantic_indices = candidate
        ctx.legacy_name_generation_calls += 1

        return candidate

    def call_cutlet_names(
        self,
        ctx,
        master_count: int,
        item_count: int,
    ) -> tuple[int, ...]:
        ring = buildCutletNameAnswerRing(
            ctx
        )

        ctx.legacy_name_answer_first = ring.first
        ctx.legacy_name_answer_direction_step = (
            ring.direction_step
        )

        return self.call_with_ring(
            ctx,
            ring,
            master_count,
            item_count,
            "köfte",
        )
