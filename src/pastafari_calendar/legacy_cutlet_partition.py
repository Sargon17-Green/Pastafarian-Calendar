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


@dataclass(
    slots=True,
)
class _StructureSauceSelectionView:
    legacy_post_stir_final_bowls: tuple[int, ...]
    orderAt46Latch: tuple[int, ...]


class LegacyAllPositiveCutletPartitionFamily:
    def __init__(
        self,
        gate_gap_count: int,
        cutlet_count: int,
    ) -> None:
        if type(gate_gap_count) is not int:
            raise TypeError(
                "Gate aralığı sayısı tam sayı olmalıdır"
            )

        if type(cutlet_count) is not int:
            raise TypeError(
                "Köfte sayısı tam sayı olmalıdır"
            )

        if gate_gap_count < 1:
            raise ValueError(
                "Gate aralığı sayısı pozitif olmalıdır"
            )

        if (
            cutlet_count < 1
            or cutlet_count > gate_gap_count
        ):
            raise ValueError(
                "Köfte sayısı pozitif olmalı ve gate aralığı sayısını aşmamalıdır"
            )

        self.gate_gap_count = gate_gap_count
        self.cutlet_count = cutlet_count

    def count(
        self,
    ) -> int:
        return comb(
            self.gate_gap_count - 1,
            self.cutlet_count - 1,
        )

    def unrank1(
        self,
        rank1: int,
    ) -> tuple[int, ...]:
        family_count = self.count()

        if not 1 <= rank1 <= family_count:
            raise ValueError(
                "Legacy köfte bölümü derecesi aralık dışında"
            )

        remaining = self.gate_gap_count
        slots = self.cutlet_count
        output: list[int] = []

        while slots > 0:
            if slots == 1:
                output.append(
                    remaining
                )
                remaining = 0
                slots = 0
                break

            max_value = (
                remaining
                - slots
                + 1
            )
            selected = False

            for value in range(
                1,
                max_value + 1,
            ):
                rest = (
                    remaining
                    - value
                )
                block = comb(
                    rest - 1,
                    slots - 2,
                )

                if rank1 > block:
                    rank1 -= block
                    continue

                output.append(
                    value
                )
                remaining = rest
                slots -= 1
                selected = True
                break

            if not selected:
                raise AssertionError(
                    "Legacy köfte bölümü lexicographic olarak açılamadı"
                )

        if remaining != 0:
            raise AssertionError(
                "Legacy köfte bölümü sonunda artık kaldı"
            )

        return tuple(
            output
        )


def legacyCompatibleCutletRank(
    ring: LegacyAnswerRing,
    family_count: int,
) -> int:
    if family_count < 1:
        raise ValueError(
            "Köfte bölümü ailesi boş olamaz"
        )

    if family_count > M_OLD:
        raise ValueError(
            "Köfte bölümü legacy kısa seçim alanını aşıyor"
        )

    limit = (
        M_OLD
        // family_count
    ) * family_count
    offset = 0
    answer = answerAtRing(
        ring,
        offset,
    )

    while answer > limit:
        offset += 1
        answer = answerAtRing(
            ring,
            offset,
        )

    return regularMod(
        answer - 1,
        family_count,
    ) + 1


def buildCutletPartitionAnswerRing(
    ctx,
) -> LegacyAnswerRing:
    if ctx.patch20_semantic_bowls is None:
        raise RuntimeError(
            "Köfte bölümü answer ring'i için semantic structure bowls hazır olmalıdır"
        )

    if ctx.patch20_semantic_order_at_drop_46 is None:
        raise RuntimeError(
            "Köfte bölümü answer ring'i için semantic drop 46 order hazır olmalıdır"
        )

    view = _StructureSauceSelectionView(
        legacy_post_stir_final_bowls=(
            ctx.patch20_semantic_bowls
        ),
        orderAt46Latch=(
            ctx.patch20_semantic_order_at_drop_46
        ),
    )

    return buildAnswerRingFromSauceState(
        view,
        2,
        21,
    )


class LegacyCutletPartitionAdapter:
    def call_with_ring(
        self,
        ctx,
        ring: LegacyAnswerRing,
        gate_gap_count: int,
        cutlet_count: int,
        internal_gate_offset: int | None,
    ) -> tuple[int, ...]:
        if internal_gate_offset is not None:
            if type(internal_gate_offset) is not int:
                raise TypeError(
                    "İç calculation-day gate ofseti tam sayı olmalıdır"
                )

            if not 1 <= internal_gate_offset < gate_gap_count:
                raise ValueError(
                    "İç calculation-day gate ofseti yılın iç gate sınırında olmalıdır"
                )

        family = LegacyAllPositiveCutletPartitionFamily(
            gate_gap_count,
            cutlet_count,
        )
        family_count = family.count()
        selected_rank = legacyCompatibleCutletRank(
            ring,
            family_count,
        )
        selected = family.unrank1(
            selected_rank
        )

        ctx.branch_trace.append(
            (
                "ESKİ_GATE_FİLTRESİZ_KÖFTE_BÖLÜMÜ",
                gate_gap_count,
                cutlet_count,
                internal_gate_offset,
                family_count,
                selected_rank,
            )
        )
        ctx.logs.append(
            (
                "eski-gate-filtresiz-köfte-bölümü",
                gate_gap_count,
                cutlet_count,
                internal_gate_offset,
                family_count,
                selected_rank,
            )
        )

        ctx.legacy_cutlet_gate_gap_count = gate_gap_count
        ctx.legacy_cutlet_count = cutlet_count
        ctx.legacy_cutlet_internal_gate_offset = internal_gate_offset
        ctx.legacy_cutlet_all_positive_family_count = family_count
        ctx.legacy_cutlet_selected_rank = selected_rank
        ctx.legacy_cutlet_selected_partition = selected
        ctx.legacy_cutlet_used_all_positive_family = True
        ctx.legacy_cutlet_internal_gate_was_ignored = (
            internal_gate_offset
            is not None
        )
        ctx.legacy_cutlet_partition_calls += 1

        return selected

    def call(
        self,
        ctx,
        gate_gap_count: int,
        cutlet_count: int,
        internal_gate_offset: int | None,
    ) -> tuple[int, ...]:
        ring = buildCutletPartitionAnswerRing(
            ctx
        )

        ctx.legacy_cutlet_answer_first = ring.first
        ctx.legacy_cutlet_answer_direction_step = ring.direction_step

        return self.call_with_ring(
            ctx,
            ring,
            gate_gap_count,
            cutlet_count,
            internal_gate_offset,
        )
