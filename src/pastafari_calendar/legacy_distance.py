from .legacy_day_counts import dayTagWithFoundationScar


def oldDistance(calculation_day: int, target_day: int) -> int:
    return abs(
        dayTagWithFoundationScar(calculation_day)
        - dayTagWithFoundationScar(target_day)
    )


class LegacyDistanceAdapter:
    def call(self, ctx, calculation_day: int, target_day: int) -> int:
        ctx.branch_trace.append(
            ("ESKİ_MESAFE", calculation_day, target_day)
        )
        ctx.logs.append(
            ("eski-mesafe", calculation_day, target_day)
        )

        value = oldDistance(calculation_day, target_day)

        ctx.legacy_distance_calculation_day = calculation_day
        ctx.legacy_distance_target_day = target_day
        ctx.legacy_distance_value = value

        return value
