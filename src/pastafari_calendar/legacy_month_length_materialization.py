from dataclasses import dataclass


MIN_MONTH_DAYS_LEGACY = 4
MAX_MONTH_DAYS_LEGACY = 123
LEGACY_SAFE_MATERIALIZED_WAYS_CAP = 100_000


class LegacyMaterializationTooLargeError(RuntimeError):
    pass


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyHugeFamilyProof:
    total_days: int
    month_count: int
    prefix_low: int
    prefix_high: int
    independent_prefix_positions: int
    lower_bound: int


@dataclass(
    frozen=True,
    slots=True,
)
class LegacyMaterializationAttempt:
    total_days: int
    month_count: int
    proof: LegacyHugeFamilyProof
    blocked: bool
    concrete_ways: tuple[tuple[int, ...], ...] | None
    virtual_backend: "VirtualLegacyList | None" = None

    @property
    def exposed_count(
        self,
    ) -> int | None:
        if self.virtual_backend is not None:
            return self.virtual_backend.count()

        if self.concrete_ways is None:
            return None

        return len(
            self.concrete_ways
        )

    def itemAt1(
        self,
        rank1: int,
    ) -> tuple[int, ...]:
        if self.virtual_backend is not None:
            return self.virtual_backend.itemAt1(
                rank1
            )

        if self.concrete_ways is None:
            raise RuntimeError(
                "Legacy bütün-yollar görünümü herhangi bir backend taşımıyor"
            )

        if not 1 <= rank1 <= len(
            self.concrete_ways
        ):
            raise ValueError(
                "Legacy bütün-yollar derecesi aralık dışında"
            )

        return self.concrete_ways[
            rank1 - 1
        ]


def _ceil_div_nonnegative(
    numerator: int,
    denominator: int,
) -> int:
    if numerator <= 0:
        return 0

    return (
        numerator
        + denominator
        - 1
    ) // denominator


def proveLegacyMonthLengthFamilyLowerBound(
    total_days: int,
    month_count: int,
    minimum: int = MIN_MONTH_DAYS_LEGACY,
    maximum: int = MAX_MONTH_DAYS_LEGACY,
) -> LegacyHugeFamilyProof:
    if type(total_days) is not int:
        raise TypeError(
            "Toplam yıl günü tam sayı olmalıdır"
        )

    if type(month_count) is not int:
        raise TypeError(
            "Ay sayısı tam sayı olmalıdır"
        )

    if not 1 <= month_count:
        raise ValueError(
            "Ay sayısı pozitif olmalıdır"
        )

    if not 0 <= minimum <= maximum:
        raise ValueError(
            "Ay uzunluğu sınırları geçersiz"
        )

    if month_count == 1:
        legal = (
            minimum
            <= total_days
            <= maximum
        )

        return LegacyHugeFamilyProof(
            total_days=total_days,
            month_count=month_count,
            prefix_low=total_days,
            prefix_high=total_days,
            independent_prefix_positions=0,
            lower_bound=(
                1
                if legal
                else 0
            ),
        )

    prefix_positions = (
        month_count
        - 1
    )

    prefix_low = max(
        minimum,
        _ceil_div_nonnegative(
            total_days
            - maximum,
            prefix_positions,
        ),
    )
    prefix_high = min(
        maximum,
        (
            total_days
            - minimum
        ) // prefix_positions,
    )

    if prefix_low > prefix_high:
        lower_bound = 0
    else:
        lower_bound = (
            prefix_high
            - prefix_low
            + 1
        ) ** prefix_positions

    return LegacyHugeFamilyProof(
        total_days=total_days,
        month_count=month_count,
        prefix_low=prefix_low,
        prefix_high=prefix_high,
        independent_prefix_positions=prefix_positions,
        lower_bound=lower_bound,
    )


class LegacyAllMonthLengthWaysAPI:
    def __init__(
        self,
        safe_cap: int = LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
    ) -> None:
        if type(safe_cap) is not int:
            raise TypeError(
                "Legacy materialization güvenlik sınırı tam sayı olmalıdır"
            )

        if safe_cap < 1:
            raise ValueError(
                "Legacy materialization güvenlik sınırı pozitif olmalıdır"
            )

        self.safe_cap = safe_cap

    def list_all_ways(
        self,
        total_days: int,
        month_count: int,
        minimum: int = MIN_MONTH_DAYS_LEGACY,
        maximum: int = MAX_MONTH_DAYS_LEGACY,
    ) -> tuple[tuple[int, ...], ...]:
        proof = proveLegacyMonthLengthFamilyLowerBound(
            total_days,
            month_count,
            minimum,
            maximum,
        )

        if proof.lower_bound > self.safe_cap:
            raise LegacyMaterializationTooLargeError(
                "Legacy API bütün ay-uzunluğu yollarını concrete list olarak "
                "materialize etmek zorunda kalacağı için güvenli sınırı aşıyor"
            )

        remaining = total_days
        prefix: list[int] = []
        out: list[tuple[int, ...]] = []

        def walk(
            slots_left: int,
            rem: int,
        ) -> None:
            if len(out) > self.safe_cap:
                raise LegacyMaterializationTooLargeError(
                    "Legacy concrete ay-uzunluğu listesi güvenli sınırı aştı"
                )

            if slots_left == 0:
                if rem == 0:
                    out.append(
                        tuple(
                            prefix
                        )
                    )
                return

            minimum_rest = (
                minimum
                * (
                    slots_left
                    - 1
                )
            )
            maximum_rest = (
                maximum
                * (
                    slots_left
                    - 1
                )
            )

            start = max(
                minimum,
                rem
                - maximum_rest,
            )
            stop = min(
                maximum,
                rem
                - minimum_rest,
            )

            for value in range(
                start,
                stop + 1,
            ):
                prefix.append(
                    value
                )
                walk(
                    slots_left - 1,
                    rem - value,
                )
                prefix.pop()

        walk(
            month_count,
            remaining,
        )

        if len(out) > self.safe_cap:
            raise LegacyMaterializationTooLargeError(
                "Legacy concrete ay-uzunluğu listesi güvenli sınırı aştı"
            )

        return tuple(
            out
        )



class VirtualLegacyList:
    def __init__(
        self,
        total_days: int,
        month_count: int,
        minimum: int = MIN_MONTH_DAYS_LEGACY,
        maximum: int = MAX_MONTH_DAYS_LEGACY,
    ) -> None:
        if type(total_days) is not int:
            raise TypeError(
                "Sanal legacy list toplam gün sayısı tam sayı olmalıdır"
            )

        if type(month_count) is not int:
            raise TypeError(
                "Sanal legacy list ay sayısı tam sayı olmalıdır"
            )

        if total_days < 0:
            raise ValueError(
                "Sanal legacy list toplam gün sayısı negatif olamaz"
            )

        if month_count < 0:
            raise ValueError(
                "Sanal legacy list ay sayısı negatif olamaz"
            )

        if not 0 <= minimum <= maximum:
            raise ValueError(
                "Sanal legacy list ay uzunluğu sınırları geçersiz"
            )

        self.total_days = total_days
        self.month_count = month_count
        self.minimum = minimum
        self.maximum = maximum

        ways = [
            [
                0
            ]
            * (
                total_days
                + 1
            )
            for _ in range(
                month_count
                + 1
            )
        ]
        ways[0][0] = 1

        for slots in range(
            1,
            month_count + 1,
        ):
            window = 0
            previous = ways[
                slots - 1
            ]
            current = ways[
                slots
            ]

            for subtotal in range(
                total_days + 1
            ):
                enter = (
                    subtotal
                    - minimum
                )
                leave = (
                    subtotal
                    - maximum
                    - 1
                )

                if enter >= 0:
                    window += previous[
                        enter
                    ]

                if leave >= 0:
                    window -= previous[
                        leave
                    ]

                current[
                    subtotal
                ] = window

        self._ways = ways

    def count(
        self,
    ) -> int:
        return self._ways[
            self.month_count
        ][
            self.total_days
        ]

    def itemAt1(
        self,
        rank1: int,
    ) -> tuple[int, ...]:
        if type(rank1) is not int:
            raise TypeError(
                "Sanal legacy list derecesi tam sayı olmalıdır"
            )

        family_count = self.count()

        if not 1 <= rank1 <= family_count:
            raise ValueError(
                "Sanal legacy list derecesi aralık dışında"
            )

        remaining = self.total_days
        output: list[int] = []

        for position in range(
            self.month_count
        ):
            slots_after = (
                self.month_count
                - position
                - 1
            )
            selected = False

            for value in range(
                self.minimum,
                self.maximum + 1,
            ):
                rest = (
                    remaining
                    - value
                )

                if (
                    rest < 0
                    or rest > self.total_days
                ):
                    block = 0
                else:
                    block = self._ways[
                        slots_after
                    ][
                        rest
                    ]

                if rank1 > block:
                    rank1 -= block
                    continue

                output.append(
                    value
                )
                remaining = rest
                selected = True
                break

            if not selected:
                raise AssertionError(
                    "Sanal legacy list lexicographic unrank ilerleyemedi"
                )

        if remaining != 0:
            raise AssertionError(
                "Sanal legacy list unrank sonunda artık gün kaldı"
            )

        return tuple(
            output
        )


class MonthLengthVirtualPatchWrapper:
    def repair(
        self,
        ctx,
        total_days: int,
        month_count: int,
        proof: LegacyHugeFamilyProof,
        legacy_blocked: bool,
        legacy_concrete: tuple[tuple[int, ...], ...] | None,
    ) -> LegacyMaterializationAttempt:
        virtual_backend = VirtualLegacyList(
            total_days,
            month_count,
        )
        exact_count = virtual_backend.count()

        ctx.branch_trace.append(
            (
                "YAMA_23_SANAL_LEGACY_LIST",
                total_days,
                month_count,
                exact_count,
                legacy_blocked,
            )
        )
        ctx.logs.append(
            (
                "yama-23-sanal-legacy-list",
                total_days,
                month_count,
                exact_count,
                legacy_blocked,
            )
        )

        ctx.patch23_legacy_materialization_blocked = legacy_blocked
        ctx.patch23_legacy_concrete_count = (
            None
            if legacy_concrete is None
            else len(
                legacy_concrete
            )
        )
        ctx.patch23_virtual_backend_active = True
        ctx.patch23_exact_count = exact_count
        ctx.patch23_semantic_blocked = False
        ctx.patch23_applied = True

        return LegacyMaterializationAttempt(
            total_days=total_days,
            month_count=month_count,
            proof=proof,
            blocked=False,
            concrete_ways=legacy_concrete,
            virtual_backend=virtual_backend,
        )


class LegacyMonthLengthMaterializationAdapter:
    def __init__(
        self,
    ) -> None:
        self.api = LegacyAllMonthLengthWaysAPI()

    def call(
        self,
        ctx,
        total_days: int,
        month_count: int,
    ) -> LegacyMaterializationAttempt:
        proof = proveLegacyMonthLengthFamilyLowerBound(
            total_days,
            month_count,
        )

        try:
            concrete = self.api.list_all_ways(
                total_days,
                month_count,
            )
            legacy_blocked = False
        except LegacyMaterializationTooLargeError:
            concrete = None
            legacy_blocked = True

        ctx.branch_trace.append(
            (
                "ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ",
                total_days,
                month_count,
                proof.lower_bound,
                legacy_blocked,
            )
        )
        ctx.logs.append(
            (
                "eski-ay-uzunluğu-tüm-yollar-listesi",
                total_days,
                month_count,
                proof.lower_bound,
                legacy_blocked,
            )
        )

        ctx.legacy_month_length_total_days = total_days
        ctx.legacy_month_length_month_count = month_count
        ctx.legacy_month_length_lower_bound = proof.lower_bound
        ctx.legacy_month_length_prefix_low = proof.prefix_low
        ctx.legacy_month_length_prefix_high = proof.prefix_high
        ctx.legacy_month_length_materialization_blocked = (
            legacy_blocked
        )
        ctx.legacy_month_length_materialized_count = (
            None
            if concrete is None
            else len(
                concrete
            )
        )
        ctx.legacy_month_length_concrete_ways = concrete
        ctx.legacy_month_length_materialization_calls += 1

        return MonthLengthVirtualPatchWrapper().repair(
            ctx,
            total_days,
            month_count,
            proof,
            legacy_blocked,
            concrete,
        )
