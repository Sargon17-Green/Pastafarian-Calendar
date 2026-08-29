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


def correctOpeningGateInterval(
    year: LegacyOpeningGateYear,
    target_day: int,
    previous_year,
) -> tuple[LegacyOpeningGateYear, int]:
    _validateLegacyYear(
        year
    )

    if type(
        target_day
    ) is not int:
        raise TypeError(
            "Opening-gate düzeltme target day tam sayı olmalıdır"
        )

    current = year
    backward_steps = 0

    while target_day <= current.open_day:
        prior = current
        current = previous_year(
            prior
        )
        _validateLegacyYear(
            current
        )

        if current.number != prior.number - 1:
            raise ValueError(
                "Opening-gate düzeltme previousYear tam olarak bir yıl geri gitmelidir"
            )

        if current.close_day != prior.open_day:
            raise ValueError(
                "Opening-gate düzeltme previousYear close gate değeri prior open gate olmalıdır"
            )

        backward_steps += 1

    if not (
        current.open_day
        < target_day
        <= current.close_day
    ):
        raise RuntimeError(
            "Opening-gate düzeltme target day değerini (open,close] içine yerleştiremedi"
        )

    return (
        current,
        backward_steps,
    )


class OpeningGateIntervalPatchWrapper:
    def repair(
        self,
        ctx,
        year: LegacyOpeningGateYear,
        target_day: int,
        previous_year,
        legacy_result: LegacyOpeningGateYear,
    ) -> LegacyOpeningGateYear:
        (
            correct_result,
            backward_steps,
        ) = correctOpeningGateInterval(
            year,
            target_day,
            previous_year,
        )

        same_as_legacy = (
            correct_result
            == legacy_result
        )
        semantic = (
            legacy_result
            if same_as_legacy
            else correct_result
        )

        ctx.branch_trace.append(
            (
                "YAMA_26_OPENING_GATE_AÇIK_SOL_ARALIK",
                year.number,
                target_day,
                legacy_result.number,
                correct_result.number,
                backward_steps,
                same_as_legacy,
            )
        )
        ctx.logs.append(
            (
                "yama-26-opening-gate-açık-sol-aralık",
                year.number,
                target_day,
                legacy_result.number,
                correct_result.number,
                backward_steps,
                same_as_legacy,
            )
        )

        ctx.patch26_legacy_result_number = legacy_result.number
        ctx.patch26_correct_result_number = correct_result.number
        ctx.patch26_correct_result_open_day = correct_result.open_day
        ctx.patch26_correct_result_close_day = correct_result.close_day
        ctx.patch26_backward_steps = backward_steps
        ctx.patch26_open_boundary_hit = (
            target_day
            == year.open_day
        )
        ctx.patch26_same_as_legacy = same_as_legacy
        ctx.patch26_semantic_year_number = semantic.number
        ctx.patch26_applied = True

        ctx.legacy_opening_interval_semantic_year_number = semantic.number

        return semantic


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

        return OpeningGateIntervalPatchWrapper().repair(
            ctx,
            year,
            target_day,
            previous_year,
            result,
        )
