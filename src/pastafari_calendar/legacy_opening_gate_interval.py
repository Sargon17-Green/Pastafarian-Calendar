from dataclasses import dataclass


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyOpeningGateYear:
    number: int
    open_day: int
    close_day: int


def _validateLegacyYear(
    year: LegacyOpeningGateYear,
) -> None:
    if type(
        year.number
    ) is not int:
        raise TypeError(
            "Legacy opening-gate yıl numarası tam sayı olmalıdır"
        )

    if type(
        year.open_day
    ) is not int:
        raise TypeError(
            "Legacy opening-gate open day tam sayı olmalıdır"
        )

    if type(
        year.close_day
    ) is not int:
        raise TypeError(
            "Legacy opening-gate close day tam sayı olmalıdır"
        )

    if year.open_day >= year.close_day:
        raise ValueError(
            "Legacy opening-gate yıl aralığı artan olmalıdır"
        )


def legacyClosedOpeningContains(
    year: LegacyOpeningGateYear,
    target_day: int,
) -> bool:
    _validateLegacyYear(
        year
    )

    if type(
        target_day
    ) is not int:
        raise TypeError(
            "Legacy opening-gate target day tam sayı olmalıdır"
        )

    return (
        year.open_day
        <= target_day
        <= year.close_day
    )


def legacyFindYearClosedOpeningInterval(
    year: LegacyOpeningGateYear,
    target_day: int,
    previous_year,
) -> LegacyOpeningGateYear:
    _validateLegacyYear(
        year
    )

    if type(
        target_day
    ) is not int:
        raise TypeError(
            "Legacy opening-gate target day tam sayı olmalıdır"
        )

    current = year

    while target_day < current.open_day:
        prior = current
        current = previous_year(
            prior
        )
        _validateLegacyYear(
            current
        )

        if current.number != prior.number - 1:
            raise ValueError(
                "Legacy opening-gate previousYear tam olarak bir yıl geri gitmelidir"
            )

        if current.close_day != prior.open_day:
            raise ValueError(
                "Legacy opening-gate previousYear close gate değeri prior open gate olmalıdır"
            )

    if not legacyClosedOpeningContains(
        current,
        target_day,
    ):
        raise RuntimeError(
            "Legacy kapalı-opening yıl araması target day değerini [open,close] içine yerleştiremedi"
        )

    return current


class LegacyOpeningGateIntervalAdapter:
    def call(
        self,
        ctx,
        year: LegacyOpeningGateYear,
        target_day: int,
        previous_year,
    ) -> LegacyOpeningGateYear:
        backward_steps = 0

        def counted_previous(
            known: LegacyOpeningGateYear,
        ) -> LegacyOpeningGateYear:
            nonlocal backward_steps
            backward_steps += 1

            return previous_year(
                known
            )

        result = legacyFindYearClosedOpeningInterval(
            year,
            target_day,
            counted_previous,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_KAPALI_OPENING_GATE_YIL_ARALIĞI",
                year.number,
                year.open_day,
                year.close_day,
                target_day,
                result.number,
                backward_steps,
            )
        )
        ctx.logs.append(
            (
                "eski-kapalı-opening-gate-yıl-aralığı",
                year.number,
                year.open_day,
                year.close_day,
                target_day,
                result.number,
                backward_steps,
            )
        )

        ctx.legacy_opening_interval_anchor_number = year.number
        ctx.legacy_opening_interval_anchor_open_day = year.open_day
        ctx.legacy_opening_interval_anchor_close_day = year.close_day
        ctx.legacy_opening_interval_target_day = target_day
        ctx.legacy_opening_interval_backward_steps = backward_steps
        ctx.legacy_opening_interval_result_number = result.number
        ctx.legacy_opening_interval_result_open_day = result.open_day
        ctx.legacy_opening_interval_result_close_day = result.close_day
        ctx.legacy_opening_interval_closed_open_assumption = True
        ctx.legacy_opening_interval_semantic_year_number = result.number
        ctx.legacy_opening_interval_calls += 1

        return result
