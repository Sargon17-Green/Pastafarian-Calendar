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


class LegacyYearJumpAdapter:
    def call(
        self,
        ctx,
        anchor: LegacyYearJumpAnchor,
        target_day: int,
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

        # Keşif 18 kusuru: telemetry olarak kalması gereken tahmin
        # henüz doğrudan semantic target year number olarak kullanılır.
        ctx.legacy_jump_semantic_year_number = guess
        ctx.legacy_jump_guess_used_as_semantic = True
        ctx.legacy_jump_calls += 1

        return guess
