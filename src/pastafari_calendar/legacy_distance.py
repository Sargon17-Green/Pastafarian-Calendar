from .legacy_day_counts import dayTagWithFoundationScar


def oldDistance(calculation_day: int, target_day: int) -> int:
    return abs(
        dayTagWithFoundationScar(calculation_day)
        - dayTagWithFoundationScar(target_day)
    )


def patchedCounts(
    calculation_day: int,
    target_day: int,
    legacy_capture=None,
) -> int:
    legacy = oldDistance(calculation_day, target_day)

    if legacy_capture is not None:
        legacy_capture.append(legacy)

    chronological = abs(target_day - calculation_day)

    if legacy != chronological:
        legacy = chronological

    distance = legacy + 1
    return distance


class DistancePatchWrapper:
    def repair(
        self,
        ctx,
        calculation_day: int,
        target_day: int,
    ) -> int:
        ctx.branch_trace.append(
            (
                "YAMA_03_MESAFE",
                calculation_day,
                target_day,
            )
        )
        ctx.logs.append(
            (
                "yama-03-mesafe",
                calculation_day,
                target_day,
            )
        )

        legacy_capture = []
        result = patchedCounts(
            calculation_day,
            target_day,
            legacy_capture,
        )

        if len(legacy_capture) != 1:
            raise RuntimeError(
                "Eski mesafe yakalama sayısı bir olmalıdır"
            )

        raw_legacy = legacy_capture[0]
        chronological = abs(
            target_day - calculation_day
        )

        ctx.legacy_distance_calculation_day = calculation_day
        ctx.legacy_distance_target_day = target_day
        ctx.legacy_distance_value = raw_legacy
        ctx.patch03_chronological_distance = chronological
        ctx.patch03_distance_value = result
        ctx.patch03_legacy_replaced = (
            raw_legacy != chronological
        )
        ctx.patch03_applied = True

        return result


class LegacyDistanceAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = DistancePatchWrapper()

    def call(
        self,
        ctx,
        calculation_day: int,
        target_day: int,
    ) -> int:
        if not isinstance(calculation_day, int):
            raise TypeError("Eylem günü tam sayı olmalıdır")
        if not isinstance(target_day, int):
            raise TypeError("Hedef günü tam sayı olmalıdır")

        ctx.branch_trace.append(
            ("ESKİ_MESAFE", calculation_day, target_day)
        )
        ctx.logs.append(
            ("eski-mesafe", calculation_day, target_day)
        )

        return self.patch_wrapper.repair(
            ctx,
            calculation_day,
            target_day,
        )
