def _validateWeavingAndTarget(
    weaving: tuple[int, ...],
    target_position: int,
) -> None:
    if not weaving:
        raise ValueError(
            "Legacy ay-günü tahmini boş weaving kabul etmez"
        )

    if any(
        type(
            month_id
        )
        is not int
        for month_id in weaving
    ):
        raise TypeError(
            "Legacy ay-günü tahmini monthId değerlerini tam sayı gerektirir"
        )

    if any(
        month_id < 1
        for month_id in weaving
    ):
        raise ValueError(
            "Legacy ay-günü tahmini pozitif monthId değerleri gerektirir"
        )

    if type(target_position) is not int:
        raise TypeError(
            "Legacy ay-günü target position tam sayı olmalıdır"
        )

    if not 1 <= target_position <= len(
        weaving
    ):
        raise ValueError(
            "Legacy ay-günü target position weaving dışında"
        )


def oldContiguousMonthDayGuess(
    weaving: tuple[int, ...],
    target_position: int,
) -> int:
    _validateWeavingAndTarget(
        weaving,
        target_position,
    )

    month_id = weaving[
        target_position - 1
    ]
    first_position = (
        weaving.index(
            month_id
        )
        + 1
    )

    return (
        target_position
        - first_position
        + 1
    )


def countMonthOccurrencesThroughTarget(
    weaving: tuple[int, ...],
    target_position: int,
) -> int:
    _validateWeavingAndTarget(
        weaving,
        target_position,
    )

    month_id = weaving[
        target_position - 1
    ]

    return sum(
        1
        for seen_month_id in weaving[
            :target_position
        ]
        if seen_month_id == month_id
    )


class MonthDayOccurrencePatchWrapper:
    def repair(
        self,
        ctx,
        weaving: tuple[int, ...],
        target_position: int,
        wrong_guess: int,
    ) -> int:
        correct_day_in_month = countMonthOccurrencesThroughTarget(
            weaving,
            target_position,
        )

        ctx.branch_trace.append(
            (
                "YAMA_25_AY_OCCURRENCE_SAYIMI",
                target_position,
                weaving[
                    target_position - 1
                ],
                wrong_guess,
                correct_day_in_month,
            )
        )
        ctx.logs.append(
            (
                "yama-25-ay-occurrence-sayımı",
                target_position,
                weaving[
                    target_position - 1
                ],
                wrong_guess,
                correct_day_in_month,
            )
        )

        ctx.patch25_wrong_guess = wrong_guess
        ctx.patch25_correct_day_in_month = correct_day_in_month
        ctx.patch25_overwrite_needed = (
            wrong_guess
            != correct_day_in_month
        )
        ctx.patch25_semantic_day_in_month = correct_day_in_month
        ctx.patch25_applied = True

        ctx.legacy_month_day_semantic_day = correct_day_in_month

        return correct_day_in_month


class LegacyContiguousMonthDayAdapter:
    def call(
        self,
        ctx,
        weaving: tuple[int, ...],
        target_position: int,
    ) -> int:
        normalized = tuple(
            weaving
        )

        _validateWeavingAndTarget(
            normalized,
            target_position,
        )

        month_id = normalized[
            target_position - 1
        ]
        first_position = (
            normalized.index(
                month_id
            )
            + 1
        )

        guessed_day = oldContiguousMonthDayGuess(
            normalized,
            target_position,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_AY_GÜNÜ_SÜREKLİYMİŞ_GİBİ",
                target_position,
                month_id,
                first_position,
                guessed_day,
            )
        )
        ctx.logs.append(
            (
                "eski-ay-günü-sürekliymiş-gibi",
                target_position,
                month_id,
                first_position,
                guessed_day,
            )
        )

        ctx.legacy_month_day_target_position = target_position
        ctx.legacy_month_day_month_id = month_id
        ctx.legacy_month_day_first_position = first_position
        ctx.legacy_month_day_guessed_day = guessed_day
        ctx.legacy_month_day_semantic_day = guessed_day
        ctx.legacy_month_day_calls += 1

        return MonthDayOccurrencePatchWrapper().repair(
            ctx,
            normalized,
            target_position,
            guessed_day,
        )
