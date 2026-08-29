from dataclasses import dataclass
from functools import lru_cache
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


class FilteredLegacyCutletPartitionFamily:
    def __init__(
        self,
        gate_gap_count: int,
        cutlet_count: int,
        required_boundary: int | None,
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

        if required_boundary is not None:
            if type(required_boundary) is not int:
                raise TypeError(
                    "Gerekli iç gate sınırı tam sayı olmalıdır"
                )

            if not 1 <= required_boundary < gate_gap_count:
                raise ValueError(
                    "Gerekli iç gate sınırı yılın içinde olmalıdır"
                )

        self.gate_gap_count = gate_gap_count
        self.cutlet_count = cutlet_count
        self.required_boundary = required_boundary

        @lru_cache(
            maxsize=None,
        )
        def count_state(
            remaining: int,
            slots: int,
            cumulative: int,
            hit: bool,
        ) -> int:
            if slots == 0:
                if remaining != 0:
                    return 0

                if required_boundary is None:
                    return 1

                return (
                    1
                    if hit
                    else 0
                )

            if remaining < slots:
                return 0

            total = 0
            max_value = (
                remaining
                - slots
                + 1
            )

            for value in range(
                1,
                max_value + 1,
            ):
                next_cumulative = (
                    cumulative
                    + value
                )
                next_hit = hit

                if (
                    required_boundary is not None
                    and not hit
                ):
                    if next_cumulative == required_boundary:
                        next_hit = True
                    elif next_cumulative > required_boundary:
                        continue

                total += count_state(
                    remaining - value,
                    slots - 1,
                    next_cumulative,
                    next_hit,
                )

            return total

        self._count_state = count_state

    def count(
        self,
    ) -> int:
        return self._count_state(
            self.gate_gap_count,
            self.cutlet_count,
            0,
            False,
        )

    def unrank1(
        self,
        rank1: int,
    ) -> tuple[int, ...]:
        family_count = self.count()

        if not 1 <= rank1 <= family_count:
            raise ValueError(
                "Filtreli köfte bölümü derecesi aralık dışında"
            )

        remaining = self.gate_gap_count
        slots = self.cutlet_count
        cumulative = 0
        hit = False
        output: list[int] = []

        while slots > 0:
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
                next_cumulative = (
                    cumulative
                    + value
                )
                next_hit = hit

                if (
                    self.required_boundary is not None
                    and not hit
                ):
                    if next_cumulative == self.required_boundary:
                        next_hit = True
                    elif next_cumulative > self.required_boundary:
                        continue

                block = self._count_state(
                    remaining - value,
                    slots - 1,
                    next_cumulative,
                    next_hit,
                )

                if rank1 > block:
                    rank1 -= block
                    continue

                output.append(
                    value
                )
                remaining -= value
                slots -= 1
                cumulative = next_cumulative
                hit = next_hit
                selected = True
                break

            if not selected:
                raise AssertionError(
                    "Filtreli köfte bölümü lexicographic olarak açılamadı"
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


def currentCompatibleCutletRank(
    ring: LegacyAnswerRing,
    family_count: int,
) -> int:
    if family_count < 1:
        raise ValueError(
            "Filtreli köfte bölümü ailesi boş olamaz"
        )

    if family_count <= M_OLD:
        return legacyCompatibleCutletRank(
            ring,
            family_count,
        )

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


class CutletPartitionGatePatchWrapper:
    def repair(
        self,
        ctx,
        ring: LegacyAnswerRing,
        gate_gap_count: int,
        cutlet_count: int,
        internal_gate_offset: int | None,
        legacy_selected: tuple[int, ...],
    ) -> tuple[int, ...]:
        ctx.patch21_legacy_selected_partition = legacy_selected
        ctx.patch21_required_boundary = internal_gate_offset

        if internal_gate_offset is None:
            ctx.patch21_filter_applied = False
            ctx.patch21_filtered_family_count = (
                ctx.legacy_cutlet_all_positive_family_count
            )
            ctx.patch21_semantic_selected_rank = (
                ctx.legacy_cutlet_selected_rank
            )
            ctx.patch21_semantic_partition = legacy_selected
            ctx.patch21_boundary_hit = False
            ctx.patch21_applied = True

            return legacy_selected

        filtered_family = FilteredLegacyCutletPartitionFamily(
            gate_gap_count,
            cutlet_count,
            internal_gate_offset,
        )
        filtered_count = filtered_family.count()

        selected_rank = currentCompatibleCutletRank(
            ring,
            filtered_count,
        )
        semantic_partition = filtered_family.unrank1(
            selected_rank
        )

        cumulative = 0
        boundary_hit = False

        for value in semantic_partition[
            :-1
        ]:
            cumulative += value

            if cumulative == internal_gate_offset:
                boundary_hit = True
                break

        if not boundary_hit:
            raise AssertionError(
                "Patch 21 semantic köfte bölümü gerekli iç gate sınırını vurmadı"
            )

        ctx.branch_trace.append(
            (
                "YAMA_21_INTERNAL_GATE_KÖFTE_FİLTRESİ",
                gate_gap_count,
                cutlet_count,
                internal_gate_offset,
                filtered_count,
                selected_rank,
            )
        )
        ctx.logs.append(
            (
                "yama-21-internal-gate-köfte-filtresi",
                gate_gap_count,
                cutlet_count,
                internal_gate_offset,
                filtered_count,
                selected_rank,
            )
        )

        ctx.patch21_filter_applied = True
        ctx.patch21_filtered_family_count = filtered_count
        ctx.patch21_semantic_selected_rank = selected_rank
        ctx.patch21_semantic_partition = semantic_partition
        ctx.patch21_boundary_hit = boundary_hit
        ctx.patch21_applied = True

        return semantic_partition


class LegacyCutletPartitionAdapter:
    def __init__(
        self,
    ) -> None:
        self.patch_wrapper = CutletPartitionGatePatchWrapper()

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

        legacy_selected = self.call_with_ring(
            ctx,
            ring,
            gate_gap_count,
            cutlet_count,
            internal_gate_offset,
        )

        return self.patch_wrapper.repair(
            ctx,
            ring,
            gate_gap_count,
            cutlet_count,
            internal_gate_offset,
            legacy_selected,
        )
