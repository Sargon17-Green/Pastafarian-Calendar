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


def legacyStableSortByLength(
    candidates: tuple[LegacyYearCandidate, ...],
) -> tuple[LegacyYearCandidate, ...]:
    working = list(
        candidates
    )

    # Tarihsel Year-5000 kusuru: equal-length run input stability ile korunur.
    working.sort(
        key=lambda candidate: candidate.length,
    )

    return tuple(
        working
    )


class Year5000TiePatchWrapper:
    def repair_after_legacy_sort(
        self,
        ctx,
        legacy_sorted: tuple[LegacyYearCandidate, ...],
    ) -> tuple[LegacyYearCandidate, ...]:
        for index in range(
            1,
            len(legacy_sorted),
        ):
            if (
                legacy_sorted[index - 1].length
                > legacy_sorted[index].length
            ):
                raise ValueError(
                    "Tie patch yalnız legacy length sort sonrasındaki family üzerinde çalışabilir"
                )

        working = list(
            legacy_sorted
        )
        run_boundaries: list[tuple[int, int]] = []
        run_before_labels: list[tuple[str, ...]] = []
        run_after_labels: list[tuple[str, ...]] = []

        start = 0

        while start < len(working):
            end = start + 1

            while (
                end < len(working)
                and working[end].length
                == working[start].length
            ):
                end += 1

            if end - start > 1:
                run_boundaries.append(
                    (
                        start,
                        end,
                    )
                )

                run_before_labels.append(
                    tuple(
                        candidate.label
                        for candidate in working[
                            start:end
                        ]
                    )
                )

                run = working[
                    start:end
                ]

                run.sort(
                    key=lambda candidate: candidate.open_day,
                )

                working[
                    start:end
                ] = run

                run_after_labels.append(
                    tuple(
                        candidate.label
                        for candidate in run
                    )
                )

            start = end

        result = tuple(
            working
        )

        ctx.branch_trace.append(
            (
                "YAMA_17_5000_EQUAL_LENGTH_RUN",
                len(run_boundaries),
            )
        )
        ctx.logs.append(
            (
                "yama-17-5000-equal-length-run",
                len(run_boundaries),
            )
        )

        ctx.patch17_legacy_sorted_labels = tuple(
            candidate.label
            for candidate in legacy_sorted
        )
        ctx.patch17_equal_length_run_count = len(
            run_boundaries
        )
        ctx.patch17_run_boundaries = tuple(
            run_boundaries
        )
        ctx.patch17_run_before_labels = tuple(
            run_before_labels
        )
        ctx.patch17_run_after_labels = tuple(
            run_after_labels
        )
        ctx.patch17_corrected_labels = tuple(
            candidate.label
            for candidate in result
        )
        ctx.patch17_corrected_open_days = tuple(
            candidate.open_day
            for candidate in result
        )
        ctx.patch17_applied = True

        return result


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
        self.tie_patch_wrapper = Year5000TiePatchWrapper()

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

    def sort_year5000_candidates_after_filter(
        self,
        ctx,
        calculation_day: int,
        candidates: tuple[LegacyYearCandidate, ...],
    ) -> tuple[LegacyYearCandidate, ...]:
        for candidate in candidates:
            if not (
                candidate.open_day
                < calculation_day
                <= candidate.close_day
            ):
                raise ValueError(
                    "Beş bininci yıl adayı hesaplama gününü içermelidir"
                )
            if candidate.length > REAL_YEAR_MAX_PATCH:
                raise ValueError(
                    "Beş bininci yıl tie yolu yalnız patched candidate family almalıdır"
                )

        legacy_result = legacyStableSortByLength(
            candidates
        )

        ctx.branch_trace.append(
            (
                "ESKİ_5000_STABLE_LENGTH_TIE",
                len(candidates),
            )
        )
        ctx.logs.append(
            (
                "eski-5000-stable-length-tie",
                len(candidates),
            )
        )

        ctx.legacy_year5000_tie_input_labels = tuple(
            candidate.label
            for candidate in candidates
        )
        ctx.legacy_year5000_tie_input_lengths = tuple(
            candidate.length
            for candidate in candidates
        )
        ctx.legacy_year5000_tie_input_open_days = tuple(
            candidate.open_day
            for candidate in candidates
        )
        ctx.legacy_year5000_tie_sorted_labels = tuple(
            candidate.label
            for candidate in legacy_result
        )
        ctx.legacy_year5000_tie_sorted_lengths = tuple(
            candidate.length
            for candidate in legacy_result
        )
        ctx.legacy_year5000_tie_sorted_open_days = tuple(
            candidate.open_day
            for candidate in legacy_result
        )

        return self.tie_patch_wrapper.repair_after_legacy_sort(
            ctx,
            legacy_result,
        )

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
