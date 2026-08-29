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

    @property
    def exposed_count(
        self,
    ) -> int | None:
        if self.concrete_ways is None:
            return None

        return len(
            self.concrete_ways
        )


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
            blocked = False
        except LegacyMaterializationTooLargeError:
            concrete = None
            blocked = True

        ctx.branch_trace.append(
            (
                "ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ",
                total_days,
                month_count,
                proof.lower_bound,
                blocked,
            )
        )
        ctx.logs.append(
            (
                "eski-ay-uzunluğu-tüm-yollar-listesi",
                total_days,
                month_count,
                proof.lower_bound,
                blocked,
            )
        )

        ctx.legacy_month_length_total_days = total_days
        ctx.legacy_month_length_month_count = month_count
        ctx.legacy_month_length_lower_bound = proof.lower_bound
        ctx.legacy_month_length_prefix_low = proof.prefix_low
        ctx.legacy_month_length_prefix_high = proof.prefix_high
        ctx.legacy_month_length_materialization_blocked = blocked
        ctx.legacy_month_length_materialized_count = (
            None
            if concrete is None
            else len(
                concrete
            )
        )
        ctx.legacy_month_length_concrete_ways = concrete
        ctx.legacy_month_length_materialization_calls += 1

        return LegacyMaterializationAttempt(
            total_days=total_days,
            month_count=month_count,
            proof=proof,
            blocked=blocked,
            concrete_ways=concrete,
        )
