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


@dataclass(
    frozen=True,
    slots=True,
)
class GuardedYearCacheEntry:
    calculationDayFingerprint: int
    openGate: int
    closeGate: int
    value: LegacyYearCacheValue


def legacyYearNumberOnlyLookup(
    cache_map: dict[int, GuardedYearCacheEntry],
    year_number: int,
) -> GuardedYearCacheEntry | None:
    # Tarihsel scar: lookup hâlâ yalnız year.number key değerine bakar.
    return cache_map.get(
        year_number
    )


class YearCacheActionGuardPatchWrapper:
    def cacheGetWithActionGuard(
        self,
        ctx,
        cache_map: dict[int, GuardedYearCacheEntry],
        request: LegacyYearCacheRequest,
    ) -> LegacyYearCacheValue | None:
        entry = legacyYearNumberOnlyLookup(
            cache_map,
            request.year_number,
        )

        legacy_key_hit = (
            entry is not None
        )

        calculation_day_match = (
            legacy_key_hit
            and entry.calculationDayFingerprint
            == request.calculation_day
        )

        open_gate_match = (
            legacy_key_hit
            and entry.openGate
            == request.open_gate
        )

        close_gate_match = (
            legacy_key_hit
            and entry.closeGate
            == request.close_gate
        )

        all_guards_match = (
            calculation_day_match
            and open_gate_match
            and close_gate_match
        )

        ctx.patch19_legacy_key_hit = legacy_key_hit
        ctx.patch19_calculation_day_match = calculation_day_match
        ctx.patch19_open_gate_match = open_gate_match
        ctx.patch19_close_gate_match = close_gate_match
        ctx.patch19_all_guards_match = all_guards_match

        if not legacy_key_hit:
            return None

        if not calculation_day_match:
            return None

        if not open_gate_match:
            return None

        if not close_gate_match:
            return None

        return entry.value

    def cachePutWithGuard(
        self,
        ctx,
        cache_map: dict[int, GuardedYearCacheEntry],
        request: LegacyYearCacheRequest,
    ) -> None:
        cache_map[
            request.year_number
        ] = GuardedYearCacheEntry(
            calculationDayFingerprint=request.calculation_day,
            openGate=request.open_gate,
            closeGate=request.close_gate,
            value=request.value,
        )

        ctx.patch19_last_written_calculation_day_fingerprint = (
            request.calculation_day
        )
        ctx.patch19_last_written_open_gate = request.open_gate
        ctx.patch19_last_written_close_gate = request.close_gate
        ctx.patch19_last_written_token = request.value.token
        ctx.patch19_applied = True


class LegacyYearNumberOnlyCacheMap:
    def __init__(
        self,
    ) -> None:
        self._map: dict[
            int,
            GuardedYearCacheEntry,
        ] = {}
        self.patch_wrapper = YearCacheActionGuardPatchWrapper()

    def lookup_or_store(
        self,
        ctx,
        request: LegacyYearCacheRequest,
    ) -> LegacyYearCacheValue:
        key = request.year_number

        result = self.patch_wrapper.cacheGetWithActionGuard(
            ctx,
            self._map,
            request,
        )

        if result is not None:
            hit = True
            ctx.legacy_year_cache_hit_count += 1
        else:
            hit = False
            ctx.legacy_year_cache_miss_count += 1

            self.patch_wrapper.cachePutWithGuard(
                ctx,
                self._map,
                request,
            )

            result = request.value

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
        ctx.legacy_year_cache_map_keys = tuple(
            sorted(
                self._map
            )
        )

        return result

    def raw_keys(
        self,
    ) -> tuple[int, ...]:
        return tuple(
            sorted(
                self._map
            )
        )

    def raw_entry(
        self,
        year_number: int,
    ) -> GuardedYearCacheEntry | None:
        return legacyYearNumberOnlyLookup(
            self._map,
            year_number,
        )
