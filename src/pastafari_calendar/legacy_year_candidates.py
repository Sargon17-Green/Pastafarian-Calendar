from dataclasses import dataclass

from .legacy_selection import (
    LegacyAnswerRing,
    LegacyShortOnlySelectionDispatcher,
)


LEGACY_YEAR_MIN = 252
LEGACY_YEAR_MAX = 5781
LEGACY_MIN_GATE_GAPS_PER_YEAR = 6


@dataclass(frozen=True, slots=True)
class LegacyYearCandidate:
    label: str
    length: int
    open_day: int
    close_day: int
    gate_gap_count: int


def legacyYearCandidateAllowed(
    candidate: LegacyYearCandidate,
) -> bool:
    if candidate.close_day - candidate.open_day != candidate.length:
        raise ValueError("Legacy yıl adayının gün uzunluğu sınır günleriyle uyuşmalıdır")

    return (
        candidate.gate_gap_count >= LEGACY_MIN_GATE_GAPS_PER_YEAR
        and LEGACY_YEAR_MIN <= candidate.length <= LEGACY_YEAR_MAX
    )


class LegacyYearCandidateAdapter:
    def __init__(self) -> None:
        self.selection = LegacyShortOnlySelectionDispatcher()

    def prepare_for_selection(
        self,
        ctx,
        candidates: tuple[LegacyYearCandidate, ...],
    ) -> tuple[LegacyYearCandidate, ...]:
        accepted: list[LegacyYearCandidate] = []

        for candidate in candidates:
            if legacyYearCandidateAllowed(
                candidate,
            ):
                accepted.append(
                    candidate,
                )

        ctx.branch_trace.append(
            (
                "ESKİ_5781_YIL_ADAYLARI",
                len(candidates),
                len(accepted),
            )
        )
        ctx.logs.append(
            (
                "eski-5781-yıl-adayları",
                len(candidates),
                len(accepted),
            )
        )

        ctx.legacy_year_candidate_input_lengths = tuple(
            candidate.length
            for candidate in candidates
        )
        ctx.legacy_year_candidate_lengths_before_sort = tuple(
            candidate.length
            for candidate in accepted
        )

        # Tarihsel akışın mevcut sıralaması: yalnız uzunluğa göre stable sort.
        # Eşit uzunluk davranışı bu aşamanın konusu değildir.
        accepted.sort(
            key=lambda candidate: candidate.length,
        )

        result = tuple(
            accepted
        )

        ctx.legacy_year_candidate_lengths_after_sort = tuple(
            candidate.length
            for candidate in result
        )
        ctx.legacy_year_candidate_count_for_selection = len(
            result
        )

        return result

    def select(
        self,
        ctx,
        ring: LegacyAnswerRing,
        candidates: tuple[LegacyYearCandidate, ...],
    ) -> LegacyYearCandidate:
        prepared = self.prepare_for_selection(
            ctx,
            candidates,
        )

        if not prepared:
            raise RuntimeError("Legacy yıl aday ailesi boş kaldı")

        rank = self.selection.call_with_ring(
            ctx,
            ring,
            len(prepared),
        )

        selected = prepared[
            rank - 1
        ]

        ctx.legacy_year_candidate_selected_rank = rank
        ctx.legacy_year_candidate_selected_label = selected.label
        ctx.legacy_year_candidate_selected_length = selected.length

        return selected
