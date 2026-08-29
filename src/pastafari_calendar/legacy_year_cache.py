from dataclasses import dataclass


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyYearCacheValue:
    token: str


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyYearCacheRequest:
    year_number: int
    calculation_day: int
    open_gate: int
    close_gate: int
    value: LegacyYearCacheValue

    def __post_init__(
        self,
    ) -> None:
        if self.close_gate <= self.open_gate:
            raise ValueError(
                "Legacy yıl cache isteğinde close gate open gate sonrasında olmalıdır"
            )


class LegacyYearNumberOnlyCacheMap:
    def __init__(
        self,
    ) -> None:
        self._map: dict[int, LegacyYearCacheValue] = {}

    def lookup_or_store(
        self,
        ctx,
        request: LegacyYearCacheRequest,
    ) -> LegacyYearCacheValue:
        key = request.year_number

        if key in self._map:
            result = self._map[key]
            hit = True
            ctx.legacy_year_cache_hit_count += 1
        else:
            self._map[key] = request.value
            result = request.value
            hit = False
            ctx.legacy_year_cache_miss_count += 1

        ctx.branch_trace.append(
            (
                "ESKİ_YALNIZ_YIL_NUMARASI_CACHE",
                request.year_number,
                hit,
            )
        )
        ctx.logs.append(
            (
                "eski-yalnız-yıl-numarası-cache",
                request.year_number,
                hit,
            )
        )

        ctx.legacy_year_cache_last_year_number = request.year_number
        ctx.legacy_year_cache_last_calculation_day = request.calculation_day
        ctx.legacy_year_cache_last_open_gate = request.open_gate
        ctx.legacy_year_cache_last_close_gate = request.close_gate
        ctx.legacy_year_cache_last_hit = hit
        ctx.legacy_year_cache_last_returned_token = result.token
        ctx.legacy_year_cache_map_keys = tuple(sorted(self._map))

        return result

    def raw_keys(
        self,
    ) -> tuple[int, ...]:
        return tuple(sorted(self._map))
