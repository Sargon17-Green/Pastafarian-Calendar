from dataclasses import dataclass

from .legacy_selection import (
    LegacyAnswerRing,
    LegacyShortOnlySelectionDispatcher,
)


LEGACY_YEAR_MIN = 252
LEGACY_YEAR_MAX = 5781
REAL_YEAR_MAX_PATCH = 5778
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


class YearMaxPatchWrapper:
    def accept_after_legacy(
        self,
        ctx,
        candidate: LegacyYearCandidate,
    ) -> bool:
        legacy_allowed = legacyYearCandidateAllowed(
            candidate,
        )

        ctx.patch16_filter_evaluations += 1

        if legacy_allowed:
            ctx.patch16_legacy_accepted_lengths = (
                ctx.patch16_legacy_accepted_lengths
                + (
                    candidate.length,
                )
            )

        if not legacy_allowed:
            return False

        if candidate.length > REAL_YEAR_MAX_PATCH:
            ctx.patch16_rejected_overlong_lengths = (
                ctx.patch16_rejected_overlong_lengths
                + (
                    candidate.length,
                )
            )
            return False

        ctx.patch16_semantic_accepted_lengths = (
            ctx.patch16_semantic_accepted_lengths
            + (
                candidate.length,
            )
        )
        return True


class LegacyYearCandidateAdapter:
    def __init__(self) -> None:
        self.selection = LegacyShortOnlySelectionDispatcher()
        self.patch_wrapper = YearMaxPatchWrapper()

    def prepare_for_selection(
        self,
        ctx,
        candidates: tuple[LegacyYearCandidate, ...],
    ) -> tuple[LegacyYearCandidate, ...]:
        accepted: list[LegacyYearCandidate] = []

        ctx.patch16_legacy_accepted_lengths = ()
        ctx.patch16_rejected_overlong_lengths = ()
        ctx.patch16_semantic_accepted_lengths = ()
        ctx.patch16_filter_evaluations = 0
        ctx.patch16_applied = True

        for candidate in candidates:
            if self.patch_wrapper.accept_after_legacy(
                ctx,
                candidate,
            ):
                accepted.append(
                    candidate,
                )

        ctx.branch_trace.append(
            (
                "ESKİ_5781_YIL_ADAYLARI",
                len(candidates),
                len(
                    ctx.patch16_legacy_accepted_lengths
                ),
            )
        )
        ctx.logs.append(
            (
                "eski-5781-yıl-adayları",
                len(candidates),
                len(
                    ctx.patch16_legacy_accepted_lengths
                ),
            )
        )
        ctx.branch_trace.append(
            (
                "YAMA_16_5778_ERKEN_FİLTRE",
                len(
                    ctx.patch16_legacy_accepted_lengths
                ),
                len(accepted),
            )
        )
        ctx.logs.append(
            (
                "yama-16-5778-erken-filtre",
                len(
                    ctx.patch16_legacy_accepted_lengths
                ),
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
