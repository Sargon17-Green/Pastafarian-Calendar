from dataclasses import dataclass


LEGACY_JUMP_AVERAGE_DAYS = 365


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyYearJumpAnchor:
    number: int
    first_day: int
    open_day: int
    close_day: int

    def __post_init__(
        self,
    ) -> None:
        if self.first_day != self.open_day + 1:
            raise ValueError(
                "Legacy yıl anchor first_day değeri open_day+1 olmalıdır"
            )
        if self.close_day < self.first_day:
            raise ValueError(
                "Legacy yıl anchor aralığı boş olamaz"
            )


def oldJumpGuess(
    anchor: LegacyYearJumpAnchor,
    target_day: int,
) -> int:
    return (
        anchor.number
        + (
            target_day
            - anchor.first_day
        )
        // LEGACY_JUMP_AVERAGE_DAYS
    )


class SequentialYearWalkPatchWrapper:
    def walk(
        self,
        ctx,
        anchor: LegacyYearJumpAnchor,
        target_day: int,
        next_year,
        previous_year,
    ) -> LegacyYearJumpAnchor:
        current = anchor
        visited_numbers = [
            current.number
        ]
        forward_steps = 0
        backward_steps = 0

        while target_day > current.close_day:
            prior = current
            current = next_year(
                prior
            )

            self._require_next_transition(
                prior,
                current,
            )

            forward_steps += 1
            visited_numbers.append(
                current.number
            )

        while target_day <= current.open_day:
            prior = current
            current = previous_year(
                prior
            )

            self._require_previous_transition(
                prior,
                current,
            )

            backward_steps += 1
            visited_numbers.append(
                current.number
            )

        if not (
            current.open_day
            < target_day
            <= current.close_day
        ):
            raise RuntimeError(
                "Hedef gün ardışık yıl yürüyüşü sonunda year interval içine yerleşmedi"
            )

        ctx.branch_trace.append(
            (
                "YAMA_18_YIL_YIL_YÜRÜYÜŞ",
                anchor.number,
                current.number,
                forward_steps,
                backward_steps,
            )
        )
        ctx.logs.append(
            (
                "yama-18-yıl-yıl-yürüyüş",
                anchor.number,
                current.number,
                forward_steps,
                backward_steps,
            )
        )

        ctx.patch18_walk_start_number = anchor.number
        ctx.patch18_walk_target_day = target_day
        ctx.patch18_walk_visited_numbers = tuple(
            visited_numbers
        )
        ctx.patch18_forward_steps = forward_steps
        ctx.patch18_backward_steps = backward_steps
        ctx.patch18_result_number = current.number
        ctx.patch18_result_open_day = current.open_day
        ctx.patch18_result_close_day = current.close_day
        ctx.patch18_applied = True

        return current

    def _require_next_transition(
        self,
        prior: LegacyYearJumpAnchor,
        current: LegacyYearJumpAnchor,
    ) -> None:
        if current.number != prior.number + 1:
            raise ValueError(
                "nextYear tam olarak bir yıl ileri gitmelidir"
            )
        if current.open_day != prior.close_day:
            raise ValueError(
                "nextYear yeni open gate olarak önceki close gate değerini kullanmalıdır"
            )

    def _require_previous_transition(
        self,
        prior: LegacyYearJumpAnchor,
        current: LegacyYearJumpAnchor,
    ) -> None:
        if current.number != prior.number - 1:
            raise ValueError(
                "previousYear tam olarak bir yıl geri gitmelidir"
            )
        if current.close_day != prior.open_day:
            raise ValueError(
                "previousYear yeni close gate olarak önceki open gate değerini kullanmalıdır"
            )


class LegacyYearJumpAdapter:
    def __init__(
        self,
    ) -> None:
        self.patch_wrapper = SequentialYearWalkPatchWrapper()

    def call(
        self,
        ctx,
        anchor: LegacyYearJumpAnchor,
        target_day: int,
        *,
        next_year=None,
        previous_year=None,
    ) -> int:
        if type(target_day) is not int:
            raise TypeError(
                "Hedef gün tam sayı olmalıdır"
            )

        guess = oldJumpGuess(
            anchor,
            target_day,
        )

        ctx.branch_trace.append(
            (
                "ESKİ_365_YIL_SIÇRAMA_TAHMİNİ",
                anchor.number,
                target_day,
                guess,
            )
        )
        ctx.logs.append(
            (
                "eski-365-yıl-sıçrama-tahmini",
                anchor.number,
                target_day,
                guess,
            )
        )

        ctx.legacy_jump_anchor_number = anchor.number
        ctx.legacy_jump_anchor_first_day = anchor.first_day
        ctx.legacy_jump_anchor_open_day = anchor.open_day
        ctx.legacy_jump_anchor_close_day = anchor.close_day
        ctx.legacy_jump_target_day = target_day
        ctx.legacy_jump_guess_number = guess
        ctx.legacy_jump_calls += 1

        resolved_next_year = next_year
        resolved_previous_year = previous_year

        if resolved_next_year is None:
            if (
                target_day
                > anchor.close_day
                and target_day
                != anchor.close_day + 1
            ):
                raise RuntimeError(
                    "Uzak forward hedef için authoritative nextYear sağlayıcısı gerekir"
                )

            resolved_next_year = self._single_boundary_next_year

        if resolved_previous_year is None:
            if target_day < anchor.open_day:
                raise RuntimeError(
                    "Uzak backward hedef için authoritative previousYear sağlayıcısı gerekir"
                )

            resolved_previous_year = self._single_boundary_previous_year

        corrected_year = self.patch_wrapper.walk(
            ctx,
            anchor,
            target_day,
            resolved_next_year,
            resolved_previous_year,
        )

        ctx.legacy_jump_semantic_year_number = corrected_year.number
        ctx.legacy_jump_guess_used_as_semantic = False
        ctx.patch18_legacy_guess_telemetry = guess
        ctx.patch18_guess_ignored_for_semantics = True

        return corrected_year.number

    def _single_boundary_next_year(
        self,
        known: LegacyYearJumpAnchor,
    ) -> LegacyYearJumpAnchor:
        open_day = known.close_day

        return LegacyYearJumpAnchor(
            number=known.number + 1,
            first_day=open_day + 1,
            open_day=open_day,
            close_day=open_day + 1,
        )

    def _single_boundary_previous_year(
        self,
        known: LegacyYearJumpAnchor,
    ) -> LegacyYearJumpAnchor:
        close_day = known.open_day

        return LegacyYearJumpAnchor(
            number=known.number - 1,
            first_day=close_day,
            open_day=close_day - 1,
            close_day=close_day,
        )
