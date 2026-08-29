from dataclasses import dataclass
from math import comb, gcd

from .legacy_arithmetic import (
    M_OLD,
    regularMod,
    savePatch,
)
from .legacy_next_bowl import latchedCircularSuccessor
from .legacy_selection import (
    LegacyAnswerRing,
    answerAtRing,
    biasedLegacyPick,
)
from .legacy_structure_sauce import (
    LegacyStructureSauceResult,
    sauceWithCurrentScars,
)
from .legacy_cutlet_partition import (
    LegacyAllPositiveCutletPartitionFamily,
    FilteredLegacyCutletPartitionFamily,
)
from .legacy_repeated_names import (
    fallingFactorialDistinct,
    legacyRepeatedNameFamilyCount,
    legacyRepeatedNameUnrank1,
    partialPermutationUnrank,
)
from .legacy_month_length_materialization import VirtualLegacyList
from .legacy_month_weaving import (
    LegalMonthWeavingDP,
    legacyChooseEachDaySeparately,
)
from .legacy_month_day_position import oldContiguousMonthDayGuess
from .source_language_catalog import SOURCE_LANGUAGE_CATALOG


FOUNDATION_DAY_INTEGRATED = -15055671
GATE_GAP_CHOICES = 922
GATE_GAP_BASE = 41
YEAR_MIN_DAYS_INTEGRATED = 252
LEGACY_YEAR_MAX_INTEGRATED = 5781
YEAR_MAX_DAYS_INTEGRATED = 5778
MIN_GATE_GAPS_PER_YEAR_INTEGRATED = 6
MIN_CUTLETS_INTEGRATED = 6
MAX_CUTLETS_INTEGRATED = 17
MIN_MONTHS_INTEGRATED = 3
MAX_MONTHS_INTEGRATED = 47
MIN_MONTH_DAYS_INTEGRATED = 4
MAX_MONTH_DAYS_INTEGRATED = 123

SEAL_GATE_GAP_INTEGRATED = 1
SEAL_YEAR_5000_INTEGRATED = 10
SEAL_NEXT_YEAR_INTEGRATED = 11
SEAL_PREVIOUS_YEAR_INTEGRATED = 12
SEAL_CUTLET_COUNT_INTEGRATED = 20
SEAL_CUTLET_PARTITION_INTEGRATED = 21
SEAL_CUTLET_NAMES_INTEGRATED = 22
SEAL_MONTH_COUNT_INTEGRATED = 30
SEAL_MONTH_LENGTHS_INTEGRATED = 31
SEAL_MONTH_WEAVING_INTEGRATED = 32
SEAL_MONTH_NAMES_INTEGRATED = 33


@dataclass(
    frozen=True,
    slots=True,
)
class IntegratedYear:
    number: int
    open_gate_index: int
    close_gate_index: int
    open_gate_day: int
    close_gate_day: int


@dataclass(
    frozen=True,
    slots=True,
)
class IntegratedCutlet:
    name_index: int
    open_gate_index: int
    close_gate_index: int
    first_day: int
    last_day: int


@dataclass(
    frozen=True,
    slots=True,
)
class IntegratedYearStructure:
    cutlet_count: int
    cutlet_partition: tuple[int, ...]
    cutlet_name_indices: tuple[int, ...]
    cutlets: tuple[IntegratedCutlet, ...]
    month_count: int
    month_lengths: tuple[int, ...]
    month_weaving: tuple[int, ...]
    month_name_indices: tuple[int, ...]


@dataclass(
    frozen=True,
    slots=True,
)
class SpaghettiDateResult:
    year_number: int
    cutlet_name: str
    day_in_cutlet: int
    month_name: str
    day_in_month: int


@dataclass(
    frozen=True,
    slots=True,
)
class _IntegratedCandidate:
    open_index: int
    close_index: int
    open_day: int
    close_day: int
    length: int

    @property
    def gate_gap_count(
        self,
    ) -> int:
        return (
            self.close_index
            - self.open_index
        )


def sauceWithScars(
    calculation_day: int,
    target_day: int,
) -> LegacyStructureSauceResult:
    return sauceWithCurrentScars(
        calculation_day,
        target_day,
        corrective56_raw_bowlsum=True,
    )


def _ringFromSauce(
    result: LegacyStructureSauceResult,
    queried_bowl_id: int,
    seal: int,
) -> LegacyAnswerRing:
    if not 1 <= queried_bowl_id <= 6:
        raise ValueError(
            "Entegrasyon kâse sorgusu 1 ile 6 arasında olmalıdır"
        )

    next_id = latchedCircularSuccessor(
        result.order_at_drop_46,
        queried_bowl_id,
    )
    bowls = result.bowls

    first = savePatch(
        (
            bowls[
                queried_bowl_id
            ]
            + seal
            + 181
        )
        ** 2
        + bowls[
            next_id
        ]
        * 179
        + seal
    )

    direction_number = savePatch(
        (
            first
            + seal
            + 1
            + 193
        )
        ** 2
        + first
        * 193
        + bowls[
            6
        ]
        * 197
    )

    direction_step = (
        1
        if regularMod(
            direction_number,
            2,
        )
        == 1
        else -1
    )

    return LegacyAnswerRing(
        first=first,
        direction_step=direction_step,
    )


def _chooseIntegratedRank(
    ring: LegacyAnswerRing,
    family_count: int,
) -> int:
    if family_count < 1:
        raise ValueError(
            "Entegrasyon seçim ailesi boş olamaz"
        )

    if family_count <= M_OLD:
        limit = (
            M_OLD
            // family_count
        ) * family_count
        offset = 0
        answer = answerAtRing(
            ring,
            offset,
        )

        while answer > limit:
            offset += 1
            answer = answerAtRing(
                ring,
                offset,
            )

        return biasedLegacyPick(
            answer,
            family_count,
        )

    places = 1
    space = M_OLD

    while space < family_count:
        places += 1
        space *= M_OLD

    wide = 1
    weight = 1

    for position in range(
        places
    ):
        wide += (
            answerAtRing(
                ring,
                position,
            )
            - 1
        ) * weight
        weight *= M_OLD

    acceptance_limit = (
        space
        // family_count
    ) * family_count

    while wide > acceptance_limit:
        wide = 1 + regularMod(
            wide
            - 1
            + ring.direction_step,
            space,
        )

    return regularMod(
        wide - 1,
        family_count,
    ) + 1


def _ceilDiv(
    numerator: int,
    denominator: int,
) -> int:
    return (
        numerator
        + denominator
        - 1
    ) // denominator


def _legacyRepeatedUnrankLocal(
    master_count: int,
    item_count: int,
    rank1: int,
) -> tuple[int, ...]:
    family_count = (
        master_count
        ** item_count
    )

    if not 1 <= rank1 <= family_count:
        raise ValueError(
            "Entegrasyon legacy tekrarlı ad derecesi aralık dışında"
        )

    rank0 = (
        rank1
        - 1
    )
    output = [
        1
    ] * item_count

    for position in range(
        item_count - 1,
        -1,
        -1,
    ):
        output[
            position
        ] = (
            rank0
            % master_count
        ) + 1
        rank0 //= master_count

    return tuple(
        output
    )


def _legacyDayByDayWeavingLocal(
    lengths: tuple[int, ...],
    ring: LegacyAnswerRing,
) -> tuple[int, ...]:
    remaining = list(
        lengths
    )
    month_count = len(
        lengths
    )
    output: list[int] = []

    for day_position in range(
        1,
        sum(
            lengths
        )
        + 1,
    ):
        month_id = regularMod(
            answerAtRing(
                ring,
                day_position - 1,
            )
            - 1,
            month_count,
        ) + 1
        spins = 0

        while remaining[
            month_id - 1
        ] == 0:
            month_id = 1 + regularMod(
                month_id,
                month_count,
            )
            spins += 1

            if spins > month_count:
                raise AssertionError(
                    "Entegrasyon legacy ay ghost'u kalan ay bulamadı"
                )

        output.append(
            month_id
        )
        remaining[
            month_id - 1
        ] -= 1

    if any(
        remaining
    ):
        raise AssertionError(
            "Entegrasyon legacy ay ghost'u multiplicity artığı bıraktı"
        )

    return tuple(
        output
    )


def _activeInterleavingCoefficient(
    remaining: tuple[int, ...],
    opened: int,
    closed: int,
) -> int:
    coefficient = 1
    accumulated = 0

    for index in range(
        closed,
        opened,
    ):
        value = remaining[
            index
        ]

        if value <= 0:
            return 0

        if accumulated == 0:
            accumulated = value
            continue

        coefficient *= comb(
            value
            + accumulated
            - 1,
            accumulated,
        )
        accumulated += value

    return coefficient


def integratedDPUnrankLegalWeaving(
    backend: LegalMonthWeavingDP,
    rank1: int,
) -> tuple[int, ...]:
    total = backend.count()

    if type(
        rank1
    ) is not int:
        raise TypeError(
            "Entegrasyon legal weaving derecesi tam sayı olmalıdır"
        )

    if not 1 <= rank1 <= total:
        raise ValueError(
            "Entegrasyon legal weaving derecesi aralık dışında"
        )

    remaining = backend.lengths
    opened = 0
    closed = 0
    coefficient = 1
    output: list[int] = []
    total_days = sum(
        backend.lengths
    )

    while len(
        output
    ) < total_days:
        active_total = sum(
            remaining[
                closed:opened
            ]
        )
        selected = False

        if opened > closed:
            prefix_sums: dict[
                int,
                int,
            ] = {}
            running = 0

            for index in range(
                closed,
                opened,
            ):
                running += remaining[
                    index
                ]
                prefix_sums[
                    index
                ] = running

            suffix_num: dict[
                int,
                int,
            ] = {}
            suffix_den: dict[
                int,
                int,
            ] = {}
            numerator = 1
            denominator = 1

            for index in range(
                opened - 1,
                closed - 1,
                -1,
            ):
                suffix_num[
                    index
                ] = numerator
                suffix_den[
                    index
                ] = denominator

                if index > closed:
                    previous_prefix = prefix_sums[
                        index - 1
                    ]
                    current_prefix = prefix_sums[
                        index
                    ]
                    numerator *= previous_prefix
                    denominator *= (
                        current_prefix
                        - 1
                    )
                    common = gcd(
                        numerator,
                        denominator,
                    )

                    if common > 1:
                        numerator //= common
                        denominator //= common

            candidate_coefficients: list[
                tuple[
                    int,
                    int,
                ]
            ] = []

            for index in range(
                closed,
                opened,
            ):
                value = remaining[
                    index
                ]

                if value <= 0:
                    continue

                if (
                    value == 1
                    and index != closed
                ):
                    continue

                if (
                    value == 1
                    and index == closed
                ):
                    next_remaining = list(
                        remaining
                    )
                    next_remaining[
                        index
                    ] = 0
                    next_coefficient = _activeInterleavingCoefficient(
                        tuple(
                            next_remaining
                        ),
                        opened,
                        closed + 1,
                    )
                else:
                    ratio_num = suffix_num[
                        index
                    ]
                    ratio_den = suffix_den[
                        index
                    ]

                    if index > closed:
                        ratio_num *= (
                            value - 1
                        )
                        ratio_den *= (
                            prefix_sums[
                                index
                            ]
                            - 1
                        )

                    common = gcd(
                        ratio_num,
                        ratio_den,
                    )

                    if common > 1:
                        ratio_num //= common
                        ratio_den //= common

                    product = (
                        coefficient
                        * ratio_num
                    )

                    if (
                        product
                        % ratio_den
                        != 0
                    ):
                        raise AssertionError(
                            "Entegrasyon weaving coefficient oranı tam bölünmedi"
                        )

                    next_coefficient = (
                        product
                        // ratio_den
                    )

                candidate_coefficients.append(
                    (
                        index,
                        next_coefficient,
                    )
                )

            suffix_count = backend._h[
                opened
            ][
                active_total - 1
            ]
            quotient, remainder = divmod(
                rank1 - 1,
                suffix_count,
            )
            cumulative = 0

            for (
                index,
                next_coefficient,
            ) in candidate_coefficients:
                next_cumulative = (
                    cumulative
                    + next_coefficient
                )

                if quotient < next_cumulative:
                    rank1 = (
                        (
                            quotient
                            - cumulative
                        )
                        * suffix_count
                        + remainder
                        + 1
                    )
                    next_remaining = list(
                        remaining
                    )
                    next_remaining[
                        index
                    ] -= 1
                    next_closed = (
                        closed + 1
                        if next_remaining[
                            index
                        ]
                        == 0
                        else closed
                    )
                    output.append(
                        index + 1
                    )
                    remaining = tuple(
                        next_remaining
                    )
                    closed = next_closed
                    coefficient = next_coefficient
                    selected = True
                    break

                cumulative = next_cumulative

            if selected:
                continue

            active_block = (
                cumulative
                * suffix_count
            )
            rank1 -= active_block

        if opened >= backend.month_count:
            raise AssertionError(
                "Entegrasyon legal weaving yeni ay açmadan ilerleyemedi"
            )

        index = opened
        month_length = remaining[
            index
        ]

        if month_length <= 0:
            raise AssertionError(
                "Entegrasyon legal weaving yeni ay uzunluğu geçersiz"
            )

        next_remaining = list(
            remaining
        )
        next_remaining[
            index
        ] -= 1
        next_opened = (
            opened + 1
        )
        next_closed = closed

        if next_remaining[
            index
        ] == 0:
            if index != closed:
                raise AssertionError(
                    "Entegrasyon legal weaving yeni ay kapanış sırasını bozdu"
                )

            next_closed += 1
            next_coefficient = _activeInterleavingCoefficient(
                tuple(
                    next_remaining
                ),
                next_opened,
                next_closed,
            )
        else:
            next_coefficient = (
                coefficient
                * comb(
                    active_total
                    + month_length
                    - 2,
                    month_length
                    - 2,
                )
            )

        output.append(
            index + 1
        )
        remaining = tuple(
            next_remaining
        )
        opened = next_opened
        closed = next_closed
        coefficient = next_coefficient

    if (
        any(
            remaining
        )
        or opened != backend.month_count
        or closed != backend.month_count
    ):
        raise AssertionError(
            "Entegrasyon legal weaving final state geçersiz"
        )

    return tuple(
        output
    )


class IntegratedGateCache:
    def __init__(
        self,
        ctx,
    ) -> None:
        self.ctx = ctx
        self.gates: dict[
            int,
            int,
        ] = {
            0: FOUNDATION_DAY_INTEGRATED,
        }
        self.min_known = 0
        self.max_known = 0

    def _gap(
        self,
        signed_index: int,
    ) -> int:
        magnitude = abs(
            signed_index
        )
        question_day = (
            FOUNDATION_DAY_INTEGRATED
            + magnitude
            if signed_index > 0
            else FOUNDATION_DAY_INTEGRATED
            - magnitude
        )
        retry_budget = 1

        while True:
            try:
                sauce_result = sauceWithScars(
                    FOUNDATION_DAY_INTEGRATED,
                    question_day,
                )
                ring = _ringFromSauce(
                    sauce_result,
                    1,
                    SEAL_GATE_GAP_INTEGRATED,
                )
                rank = _chooseIntegratedRank(
                    ring,
                    GATE_GAP_CHOICES,
                )
                gap = (
                    GATE_GAP_BASE
                    + rank
                )
                break
            except AssertionError:
                if retry_budget <= 0:
                    raise

                retry_budget -= 1
                self.ctx.integration_gate_retry_count += 1

        self.ctx.integration_gate_questions += 1
        self.ctx.integration_gate_last_signed_index = signed_index
        self.ctx.integration_gate_last_question_day = question_day
        self.ctx.integration_gate_last_gap = gap

        return gap

    def ensure_index(
        self,
        index: int,
    ) -> int:
        cached = self.gates.get(
            index
        )

        if cached is not None:
            self.ctx.integration_gate_cache_hits += 1
            return cached

        self.ctx.integration_gate_cache_misses += 1

        if index > self.max_known:
            current = (
                self.max_known
                + 1
            )

            while current <= index:
                self.gates[
                    current
                ] = (
                    self.gates[
                        current - 1
                    ]
                    + self._gap(
                        current
                    )
                )
                self.max_known = current
                current += 1

        elif index < self.min_known:
            current = (
                self.min_known
                - 1
            )

            while current >= index:
                self.gates[
                    current
                ] = (
                    self.gates[
                        current + 1
                    ]
                    - self._gap(
                        current
                    )
                )
                self.min_known = current
                current -= 1

        return self.gates[
            index
        ]

    def ensure_cover(
        self,
        low_day: int,
        high_day: int,
    ) -> None:
        if low_day > high_day:
            raise ValueError(
                "Entegrasyon gate kaplama aralığı ters olamaz"
            )

        while self.gates[
            self.min_known
        ] > low_day:
            self.ensure_index(
                self.min_known - 1
            )

        while self.gates[
            self.max_known
        ] < high_day:
            self.ensure_index(
                self.max_known + 1
            )

    def exact_gate_index(
        self,
        day: int,
    ) -> int | None:
        self.ensure_cover(
            day,
            day,
        )
        lo = self.min_known
        hi = self.max_known

        while lo < hi:
            mid = (
                lo
                + (
                    hi
                    - lo
                    + 1
                )
                // 2
            )

            if self.gates[
                mid
            ] <= day:
                lo = mid
            else:
                hi = mid - 1

        return (
            lo
            if self.gates[
                lo
            ]
            == day
            else None
        )


class FinalSpaghettiIntegrationManager:
    def __init__(
        self,
        ctx,
    ) -> None:
        self.ctx = ctx
        self.gates = IntegratedGateCache(
            ctx
        )
        self._year_cache: dict[
            int,
            tuple[
                int,
                int,
                int,
                IntegratedYear,
            ],
        ] = {}
        self._hooks: dict[
            str,
            list,
        ] = {
            "year": [],
            "structure": [],
            "result": [],
        }
        self._hooks[
            "result"
        ].append(
            self._validateFiveFieldHook
        )
        self.ctx.integration_compatibility_flags = (
            "LEGACY_SCARS_AKTİF",
            "PATCH_DETOURLARI_AKTİF",
            "GÖZLEMLENEBİLİRLİK_SEMANTİK_DEĞİL",
        )

    @staticmethod
    def _validateFiveFieldHook(
        value,
    ) -> None:
        fields = getattr(
            value,
            "__dataclass_fields__",
            None,
        )

        if fields is None:
            raise AssertionError(
                "Entegrasyon result hook dataclass sonucu bekler"
            )

        if len(
            fields
        ) != 5:
            raise AssertionError(
                "Entegrasyon result hook tam beş alan bekler"
            )

    def _fireHooks(
        self,
        name: str,
        value,
    ) -> None:
        for hook in tuple(
            self._hooks[
                name
            ]
        ):
            hook(
                value
            )
            self.ctx.integration_hook_calls += 1

    def _rawCandidatesContaining(
        self,
        calculation_day: int,
    ) -> tuple[_IntegratedCandidate, ...]:
        self.gates.ensure_cover(
            calculation_day
            - LEGACY_YEAR_MAX_INTEGRATED,
            calculation_day
            + LEGACY_YEAR_MAX_INTEGRATED,
        )
        output: list[
            _IntegratedCandidate
        ] = []

        for open_index in range(
            self.gates.min_known,
            self.gates.max_known,
        ):
            close_index = (
                open_index
                + MIN_GATE_GAPS_PER_YEAR_INTEGRATED
            )

            while close_index <= self.gates.max_known:
                open_day = self.gates.gates[
                    open_index
                ]
                close_day = self.gates.gates[
                    close_index
                ]
                length = (
                    close_day
                    - open_day
                )

                if length > LEGACY_YEAR_MAX_INTEGRATED:
                    break

                if (
                    length
                    >= YEAR_MIN_DAYS_INTEGRATED
                    and open_day
                    < calculation_day
                    <= close_day
                ):
                    output.append(
                        _IntegratedCandidate(
                            open_index=open_index,
                            close_index=close_index,
                            open_day=open_day,
                            close_day=close_day,
                            length=length,
                        )
                    )

                close_index += 1

        return tuple(
            output
        )

    def _late5778FilterAndSort5000(
        self,
        candidates: tuple[
            _IntegratedCandidate,
            ...,
        ],
    ) -> tuple[_IntegratedCandidate, ...]:
        legacy_accepted = tuple(
            candidate
            for candidate in candidates
            if (
                candidate.gate_gap_count
                >= MIN_GATE_GAPS_PER_YEAR_INTEGRATED
                and YEAR_MIN_DAYS_INTEGRATED
                <= candidate.length
                <= LEGACY_YEAR_MAX_INTEGRATED
            )
        )

        patched = [
            candidate
            for candidate in legacy_accepted
            if candidate.length
            <= YEAR_MAX_DAYS_INTEGRATED
        ]

        self.ctx.integration_year_legacy_5781_accepted = len(
            legacy_accepted
        )
        self.ctx.integration_year_rejected_5779_5781 = (
            len(
                legacy_accepted
            )
            - len(
                patched
            )
        )

        patched.sort(
            key=lambda candidate: candidate.length,
        )

        start = 0

        while start < len(
            patched
        ):
            end = (
                start
                + 1
            )

            while (
                end
                < len(
                    patched
                )
                and patched[
                    end
                ].length
                == patched[
                    start
                ].length
            ):
                end += 1

            if end - start > 1:
                run = patched[
                    start:end
                ]
                run.sort(
                    key=lambda candidate: candidate.open_day,
                )
                patched[
                    start:end
                ] = run

            start = end

        return tuple(
            patched
        )

    def year5000(
        self,
        calculation_day: int,
    ) -> IntegratedYear:
        raw = self._rawCandidatesContaining(
            calculation_day
        )
        candidates = self._late5778FilterAndSort5000(
            raw
        )

        if not candidates:
            raise AssertionError(
                "Entegrasyon beş bininci yıl adayı bulamadı"
            )

        sauce_result = sauceWithScars(
            calculation_day,
            calculation_day,
        )
        ring = _ringFromSauce(
            sauce_result,
            1,
            SEAL_YEAR_5000_INTEGRATED,
        )
        rank = _chooseIntegratedRank(
            ring,
            len(
                candidates
            ),
        )
        selected = candidates[
            rank - 1
        ]

        self.ctx.integration_year5000_candidate_count = len(
            candidates
        )
        self.ctx.integration_year5000_selected_rank = rank
        self.ctx.integration_year5000_open_day = selected.open_day
        self.ctx.integration_year5000_close_day = selected.close_day

        return IntegratedYear(
            number=5000,
            open_gate_index=selected.open_index,
            close_gate_index=selected.close_index,
            open_gate_day=selected.open_day,
            close_gate_day=selected.close_day,
        )

    def _nextYear(
        self,
        calculation_day: int,
        known: IntegratedYear,
    ) -> IntegratedYear:
        open_index = known.close_gate_index
        self.gates.ensure_cover(
            self.gates.gates[
                open_index
            ],
            self.gates.gates[
                open_index
            ]
            + LEGACY_YEAR_MAX_INTEGRATED,
        )

        raw: list[
            _IntegratedCandidate
        ] = []
        close_index = (
            open_index
            + 1
        )

        while True:
            self.gates.ensure_index(
                close_index
            )
            open_day = self.gates.gates[
                open_index
            ]
            close_day = self.gates.gates[
                close_index
            ]
            length = (
                close_day
                - open_day
            )

            if length > LEGACY_YEAR_MAX_INTEGRATED:
                break

            raw.append(
                _IntegratedCandidate(
                    open_index=open_index,
                    close_index=close_index,
                    open_day=open_day,
                    close_day=close_day,
                    length=length,
                )
            )
            close_index += 1

        legacy = [
            candidate
            for candidate in raw
            if (
                candidate.gate_gap_count
                >= MIN_GATE_GAPS_PER_YEAR_INTEGRATED
                and YEAR_MIN_DAYS_INTEGRATED
                <= candidate.length
                <= LEGACY_YEAR_MAX_INTEGRATED
            )
        ]
        patched = [
            candidate
            for candidate in legacy
            if candidate.length
            <= YEAR_MAX_DAYS_INTEGRATED
        ]
        patched.sort(
            key=lambda candidate: candidate.length,
        )

        if not patched:
            raise AssertionError(
                "Entegrasyon next-year adayı bulamadı"
            )

        sauce_result = sauceWithScars(
            calculation_day,
            self.gates.gates[
                open_index
            ],
        )
        ring = _ringFromSauce(
            sauce_result,
            1,
            SEAL_NEXT_YEAR_INTEGRATED,
        )
        rank = _chooseIntegratedRank(
            ring,
            len(
                patched
            ),
        )
        selected = patched[
            rank - 1
        ]

        return IntegratedYear(
            number=known.number + 1,
            open_gate_index=selected.open_index,
            close_gate_index=selected.close_index,
            open_gate_day=selected.open_day,
            close_gate_day=selected.close_day,
        )

    def _previousYear(
        self,
        calculation_day: int,
        known: IntegratedYear,
    ) -> IntegratedYear:
        close_index = known.open_gate_index
        self.gates.ensure_cover(
            self.gates.gates[
                close_index
            ]
            - LEGACY_YEAR_MAX_INTEGRATED,
            self.gates.gates[
                close_index
            ],
        )

        raw: list[
            _IntegratedCandidate
        ] = []
        open_index = (
            close_index
            - 1
        )

        while True:
            self.gates.ensure_index(
                open_index
            )
            open_day = self.gates.gates[
                open_index
            ]
            close_day = self.gates.gates[
                close_index
            ]
            length = (
                close_day
                - open_day
            )

            if length > LEGACY_YEAR_MAX_INTEGRATED:
                break

            raw.append(
                _IntegratedCandidate(
                    open_index=open_index,
                    close_index=close_index,
                    open_day=open_day,
                    close_day=close_day,
                    length=length,
                )
            )
            open_index -= 1

        legacy = [
            candidate
            for candidate in raw
            if (
                candidate.gate_gap_count
                >= MIN_GATE_GAPS_PER_YEAR_INTEGRATED
                and YEAR_MIN_DAYS_INTEGRATED
                <= candidate.length
                <= LEGACY_YEAR_MAX_INTEGRATED
            )
        ]
        patched = [
            candidate
            for candidate in legacy
            if candidate.length
            <= YEAR_MAX_DAYS_INTEGRATED
        ]
        patched.sort(
            key=lambda candidate: candidate.length,
        )

        if not patched:
            raise AssertionError(
                "Entegrasyon previous-year adayı bulamadı"
            )

        sauce_result = sauceWithScars(
            calculation_day,
            self.gates.gates[
                close_index
            ],
        )
        ring = _ringFromSauce(
            sauce_result,
            1,
            SEAL_PREVIOUS_YEAR_INTEGRATED,
        )
        rank = _chooseIntegratedRank(
            ring,
            len(
                patched
            ),
        )
        selected = patched[
            rank - 1
        ]

        return IntegratedYear(
            number=known.number - 1,
            open_gate_index=selected.open_index,
            close_gate_index=selected.close_index,
            open_gate_day=selected.open_day,
            close_gate_day=selected.close_day,
        )

    def findTargetYear(
        self,
        calculation_day: int,
        target_day: int,
    ) -> IntegratedYear:
        current = self.year5000(
            calculation_day
        )
        visited = [
            current.number
        ]
        legacy_guess = (
            current.number
            + (
                target_day
                - (
                    current.open_gate_day
                    + 1
                )
            )
            // 365
        )
        self.ctx.integration_legacy_jump_guess = legacy_guess

        while target_day > current.close_gate_day:
            current = self._nextYear(
                calculation_day,
                current,
            )
            visited.append(
                current.number
            )

        while target_day <= current.open_gate_day:
            current = self._previousYear(
                calculation_day,
                current,
            )
            visited.append(
                current.number
            )

        if not (
            current.open_gate_day
            < target_day
            <= current.close_gate_day
        ):
            raise AssertionError(
                "Entegrasyon target day değerini (open,close] year interval içine yerleştiremedi"
            )

        self.ctx.integration_year_walk_visited = tuple(
            visited
        )
        self.ctx.integration_target_year_number = current.number
        self.ctx.integration_target_year_open_day = current.open_gate_day
        self.ctx.integration_target_year_close_day = current.close_gate_day
        self._fireHooks(
            "year",
            current,
        )

        return current

    def _guardedYearCacheRoundTrip(
        self,
        calculation_day: int,
        year: IntegratedYear,
    ) -> IntegratedYear:
        key = year.number
        old_entry = self._year_cache.get(
            key
        )
        legacy_key_hit = (
            old_entry
            is not None
        )
        guard_match = (
            legacy_key_hit
            and old_entry[
                0
            ]
            == calculation_day
            and old_entry[
                1
            ]
            == year.open_gate_day
            and old_entry[
                2
            ]
            == year.close_gate_day
        )

        if guard_match:
            self.ctx.integration_year_cache_hits += 1
            return old_entry[
                3
            ]

        if legacy_key_hit:
            self.ctx.integration_year_cache_guard_rejections += 1

        self.ctx.integration_year_cache_misses += 1
        self._year_cache[
            key
        ] = (
            calculation_day,
            year.open_gate_day,
            year.close_gate_day,
            year,
        )

        second = self._year_cache[
            key
        ]

        if not (
            second[
                0
            ]
            == calculation_day
            and second[
                1
            ]
            == year.open_gate_day
            and second[
                2
            ]
            == year.close_gate_day
        ):
            raise AssertionError(
                "Entegrasyon guarded year cache commit doğrulaması başarısız"
            )

        self.ctx.integration_year_cache_hits += 1
        self.ctx.integration_year_cache_guard_valid = True

        return second[
            3
        ]

    def buildStructure(
        self,
        calculation_day: int,
        original_target_day: int,
        year: IntegratedYear,
    ) -> IntegratedYearStructure:
        first_day = (
            year.open_gate_day
            + 1
        )

        if (
            self.ctx.legacy_post_stir_final_bowls is None
            or self.ctx.orderAt46Latch is None
        ):
            original_sauce = sauceWithScars(
                calculation_day,
                original_target_day,
            )
        else:
            original_sauce = LegacyStructureSauceResult(
                calculation_day=calculation_day,
                target_day=original_target_day,
                bowls=self.ctx.legacy_post_stir_final_bowls,
                order_at_drop_46=self.ctx.orderAt46Latch,
            )

        # Düzeltici Aşama 56: historical context sauce yalnız ghost olarak kalır.
        # Hedef zaten yılın ilk günü olsa bile authoritative structure, raw-bowlSum
        # post-stir detour'u açık yeni sauce üzerinden yeniden üretilir.
        semantic_sauce = sauceWithScars(
            calculation_day,
            first_day,
        )
        self.ctx.branch_trace.append((
            "DÜZELTİCİ_56_STRUCTURE_SAUCE_RECOMPUTE",
            original_target_day,
            first_day,
        ))
        self.ctx.logs.append((
            "düzeltici-56-structure-sauce-recompute",
            original_target_day,
            first_day,
        ))

        self.ctx.integration_structure_ghost_target_day = (
            original_sauce.target_day
        )
        self.ctx.integration_structure_semantic_target_day = (
            semantic_sauce.target_day
        )
        self.ctx.integration_structure_recomputed = (
            semantic_sauce
            is not original_sauce
        )

        gate_gaps = (
            year.close_gate_index
            - year.open_gate_index
        )
        cutlet_candidates = tuple(
            count
            for count in range(
                MIN_CUTLETS_INTEGRATED,
                MAX_CUTLETS_INTEGRATED
                + 1,
            )
            if count <= gate_gaps
        )

        cutlet_count_ring = _ringFromSauce(
            semantic_sauce,
            2,
            SEAL_CUTLET_COUNT_INTEGRATED,
        )
        cutlet_count_rank = _chooseIntegratedRank(
            cutlet_count_ring,
            len(
                cutlet_candidates
            ),
        )
        cutlet_count = cutlet_candidates[
            cutlet_count_rank
            - 1
        ]

        exact_gate = self.gates.exact_gate_index(
            calculation_day
        )
        required_boundary = (
            exact_gate
            - year.open_gate_index
            if (
                exact_gate is not None
                and year.open_gate_index
                < exact_gate
                < year.close_gate_index
            )
            else None
        )

        partition_ring = _ringFromSauce(
            semantic_sauce,
            2,
            SEAL_CUTLET_PARTITION_INTEGRATED,
        )
        raw_partition_family = LegacyAllPositiveCutletPartitionFamily(
            gate_gaps,
            cutlet_count,
        )
        raw_partition_rank = _chooseIntegratedRank(
            partition_ring,
            raw_partition_family.count(),
        )
        raw_partition = raw_partition_family.unrank1(
            raw_partition_rank
        )

        filtered_partition_family = FilteredLegacyCutletPartitionFamily(
            gate_gaps,
            cutlet_count,
            required_boundary,
        )
        filtered_partition_rank = _chooseIntegratedRank(
            partition_ring,
            filtered_partition_family.count(),
        )
        cutlet_partition = filtered_partition_family.unrank1(
            filtered_partition_rank
        )

        self.ctx.integration_cutlet_raw_partition = raw_partition
        self.ctx.integration_cutlet_required_boundary = required_boundary
        self.ctx.integration_cutlet_semantic_partition = cutlet_partition

        cutlet_name_ring = _ringFromSauce(
            semantic_sauce,
            5,
            SEAL_CUTLET_NAMES_INTEGRATED,
        )
        raw_cutlet_name_count = legacyRepeatedNameFamilyCount(
            17,
            cutlet_count,
        )
        raw_cutlet_name_rank = _chooseIntegratedRank(
            cutlet_name_ring,
            raw_cutlet_name_count,
        )
        raw_cutlet_names = legacyRepeatedNameUnrank1(
            17,
            cutlet_count,
            raw_cutlet_name_rank,
        )
        distinct_cutlet_count = fallingFactorialDistinct(
            17,
            cutlet_count,
        )
        distinct_cutlet_rank = _chooseIntegratedRank(
            cutlet_name_ring,
            distinct_cutlet_count,
        )
        correct_cutlet_names = partialPermutationUnrank(
            17,
            cutlet_count,
            distinct_cutlet_rank,
        )
        cutlet_names = (
            raw_cutlet_names
            if raw_cutlet_names
            == correct_cutlet_names
            else correct_cutlet_names
        )

        self.ctx.integration_cutlet_raw_name_indices = raw_cutlet_names
        self.ctx.integration_cutlet_name_indices = cutlet_names

        cursor = year.open_gate_index
        cutlets: list[
            IntegratedCutlet
        ] = []

        for span, name_index in zip(
            cutlet_partition,
            cutlet_names,
        ):
            open_index = cursor
            close_index = (
                cursor
                + span
            )
            cutlets.append(
                IntegratedCutlet(
                    name_index=name_index,
                    open_gate_index=open_index,
                    close_gate_index=close_index,
                    first_day=self.gates.gates[
                        open_index
                    ]
                    + 1,
                    last_day=self.gates.gates[
                        close_index
                    ],
                )
            )
            cursor = close_index

        year_length = (
            year.close_gate_day
            - year.open_gate_day
        )
        minimum_months = _ceilDiv(
            year_length,
            MAX_MONTH_DAYS_INTEGRATED,
        )
        maximum_months = min(
            MAX_MONTHS_INTEGRATED,
            year_length
            // MIN_MONTH_DAYS_INTEGRATED,
        )
        month_candidates = tuple(
            range(
                minimum_months,
                maximum_months
                + 1,
            )
        )

        if not (
            MIN_MONTHS_INTEGRATED
            <= minimum_months
            <= maximum_months
            <= MAX_MONTHS_INTEGRATED
        ):
            raise AssertionError(
                "Entegrasyon ay sayısı sınırları geçersiz"
            )

        month_count_ring = _ringFromSauce(
            semantic_sauce,
            3,
            SEAL_MONTH_COUNT_INTEGRATED,
        )
        month_count_rank = _chooseIntegratedRank(
            month_count_ring,
            len(
                month_candidates
            ),
        )
        month_count = month_candidates[
            month_count_rank
            - 1
        ]

        virtual_lengths = VirtualLegacyList(
            year_length,
            month_count,
            MIN_MONTH_DAYS_INTEGRATED,
            MAX_MONTH_DAYS_INTEGRATED,
        )
        month_length_ring = _ringFromSauce(
            semantic_sauce,
            3,
            SEAL_MONTH_LENGTHS_INTEGRATED,
        )
        month_length_rank = _chooseIntegratedRank(
            month_length_ring,
            virtual_lengths.count(),
        )
        month_lengths = virtual_lengths.itemAt1(
            month_length_rank
        )

        weaving_ring = _ringFromSauce(
            semantic_sauce,
            4,
            SEAL_MONTH_WEAVING_INTEGRATED,
        )
        raw_weaving = legacyChooseEachDaySeparately(
            month_lengths,
            weaving_ring,
        )
        legal_weaving = LegalMonthWeavingDP(
            month_lengths
        )
        weaving_rank = _chooseIntegratedRank(
            weaving_ring,
            legal_weaving.count(),
        )
        correct_weaving = integratedDPUnrankLegalWeaving(
            legal_weaving,
            weaving_rank,
        )
        month_weaving = (
            raw_weaving
            if raw_weaving
            == correct_weaving
            else correct_weaving
        )

        self.ctx.integration_month_weaving_ghost = raw_weaving
        self.ctx.integration_month_weaving_semantic = month_weaving

        month_name_ring = _ringFromSauce(
            semantic_sauce,
            5,
            SEAL_MONTH_NAMES_INTEGRATED,
        )
        raw_month_name_count = legacyRepeatedNameFamilyCount(
            47,
            month_count,
        )
        raw_month_name_rank = _chooseIntegratedRank(
            month_name_ring,
            raw_month_name_count,
        )
        raw_month_names = legacyRepeatedNameUnrank1(
            47,
            month_count,
            raw_month_name_rank,
        )
        distinct_month_name_count = fallingFactorialDistinct(
            47,
            month_count,
        )
        distinct_month_name_rank = _chooseIntegratedRank(
            month_name_ring,
            distinct_month_name_count,
        )
        correct_month_names = partialPermutationUnrank(
            47,
            month_count,
            distinct_month_name_rank,
        )
        month_names = (
            raw_month_names
            if raw_month_names
            == correct_month_names
            else correct_month_names
        )

        self.ctx.integration_month_raw_name_indices = raw_month_names
        self.ctx.integration_month_name_indices = month_names

        structure = IntegratedYearStructure(
            cutlet_count=cutlet_count,
            cutlet_partition=cutlet_partition,
            cutlet_name_indices=cutlet_names,
            cutlets=tuple(
                cutlets
            ),
            month_count=month_count,
            month_lengths=month_lengths,
            month_weaving=month_weaving,
            month_name_indices=month_names,
        )

        self.ctx.integration_structure = structure
        self._fireHooks(
            "structure",
            structure,
        )

        return structure

    def execute(
        self,
        calculation_day: int,
        target_day: int,
    ) -> SpaghettiDateResult:
        if type(
            calculation_day
        ) is not int:
            raise TypeError(
                "Entegrasyon calculation day tam sayı olmalıdır"
            )

        if type(
            target_day
        ) is not int:
            raise TypeError(
                "Entegrasyon target day tam sayı olmalıdır"
            )

        self.ctx.integration_started = True
        self.ctx.integration_mode = "AUTHORITATIVE"
        self.ctx.integration_program_counter = "YIL_5000"
        self.ctx.integration_commit_token += 1
        retry_budget = 1
        committed_phase = "BAŞLANGIÇ"
        year = None
        structure = None
        self.ctx.integration_old_snapshot = (
            "BAŞLANGIÇ",
            None,
            None,
        )
        self.ctx.integration_pending_snapshot = None
        self.ctx.integration_rollback_snapshot = None
        self.ctx.integration_last_committed_phase = committed_phase

        while self.ctx.integration_program_counter != "BİTTİ":
            try:
                if self.ctx.integration_program_counter == "YIL_5000":
                    year = self.findTargetYear(
                        calculation_day,
                        target_day,
                    )
                    self.ctx.integration_pending_snapshot = (
                        "YIL",
                        year,
                        None,
                    )
                    committed_phase = "YIL"
                    self.ctx.integration_old_snapshot = (
                        self.ctx.integration_pending_snapshot
                    )
                    self.ctx.integration_pending_snapshot = None
                    self.ctx.integration_last_committed_phase = committed_phase
                    self.ctx.integration_commit_token += 1
                    self.ctx.integration_program_counter = "CACHE"
                    continue

                if self.ctx.integration_program_counter == "CACHE":
                    if year is None:
                        raise AssertionError(
                            "Entegrasyon cache aşamasında year yok"
                        )

                    year = self._guardedYearCacheRoundTrip(
                        calculation_day,
                        year,
                    )
                    self.ctx.integration_pending_snapshot = (
                        "CACHE",
                        year,
                        None,
                    )
                    committed_phase = "CACHE"
                    self.ctx.integration_old_snapshot = (
                        self.ctx.integration_pending_snapshot
                    )
                    self.ctx.integration_pending_snapshot = None
                    self.ctx.integration_last_committed_phase = committed_phase
                    self.ctx.integration_commit_token += 1
                    self.ctx.integration_program_counter = "YAPI"
                    continue

                if self.ctx.integration_program_counter == "YAPI":
                    if year is None:
                        raise AssertionError(
                            "Entegrasyon yapı aşamasında year yok"
                        )

                    structure = self.buildStructure(
                        calculation_day,
                        target_day,
                        year,
                    )
                    self.ctx.integration_pending_snapshot = (
                        "YAPI",
                        year,
                        structure,
                    )
                    committed_phase = "YAPI"
                    self.ctx.integration_old_snapshot = (
                        self.ctx.integration_pending_snapshot
                    )
                    self.ctx.integration_pending_snapshot = None
                    self.ctx.integration_last_committed_phase = committed_phase
                    self.ctx.integration_commit_token += 1
                    self.ctx.integration_program_counter = "SONUÇ"
                    continue

                if self.ctx.integration_program_counter == "SONUÇ":
                    if (
                        year is None
                        or structure is None
                    ):
                        raise AssertionError(
                            "Entegrasyon sonuç aşamasında semantic state eksik"
                        )

                    chosen_cutlet = None

                    for cutlet in structure.cutlets:
                        if (
                            cutlet.first_day
                            <= target_day
                            <= cutlet.last_day
                        ):
                            chosen_cutlet = cutlet
                            break

                    if chosen_cutlet is None:
                        raise AssertionError(
                            "Entegrasyon target day hiçbir köfteye düşmedi"
                        )

                    day_in_cutlet = (
                        target_day
                        - chosen_cutlet.first_day
                        + 1
                    )
                    year_offset0 = (
                        target_day
                        - (
                            year.open_gate_day
                            + 1
                        )
                    )
                    month_id = structure.month_weaving[
                        year_offset0
                    ]
                    month_name_index = structure.month_name_indices[
                        month_id - 1
                    ]

                    legacy_contiguous_guess = oldContiguousMonthDayGuess(
                        structure.month_weaving,
                        year_offset0 + 1,
                    )
                    day_in_month = sum(
                        1
                        for seen_month_id in structure.month_weaving[
                            :year_offset0
                            + 1
                        ]
                        if seen_month_id
                        == month_id
                    )

                    self.ctx.integration_month_day_legacy_guess = (
                        legacy_contiguous_guess
                    )
                    self.ctx.integration_month_day_occurrence_count = (
                        day_in_month
                    )

                    result = SpaghettiDateResult(
                        year_number=year.number,
                        cutlet_name=SOURCE_LANGUAGE_CATALOG.cutlet_text(
                            chosen_cutlet.name_index
                        ),
                        day_in_cutlet=day_in_cutlet,
                        month_name=SOURCE_LANGUAGE_CATALOG.month_text(
                            month_name_index
                        ),
                        day_in_month=day_in_month,
                    )

                    if len(
                        result.__dataclass_fields__
                    ) != 5:
                        raise AssertionError(
                            "Entegrasyon final sonucu tam beş alan taşımıyor"
                        )

                    self.ctx.integration_result_five = result
                    self.ctx.integration_exact_five_fields = True
                    self.ctx.integration_program_counter = "BİTTİ"
                    self.ctx.integration_completed = True
                    self.ctx.integration_status = "GREEN"
                    self._fireHooks(
                        "result",
                        result,
                    )
                    return result

                raise AssertionError(
                    "Entegrasyon program counter bilinmeyen aşamada"
                )

            except AssertionError:
                self.ctx.integration_rollback_snapshot = (
                    self.ctx.integration_old_snapshot
                )
                self.ctx.integration_pending_snapshot = None

                if retry_budget <= 0:
                    self.ctx.integration_status = "FAILED"
                    raise

                retry_budget -= 1
                self.ctx.integration_retry_count += 1

                if committed_phase == "BAŞLANGIÇ":
                    self.ctx.integration_program_counter = "YIL_5000"
                    year = None
                    structure = None
                elif committed_phase == "YIL":
                    self.ctx.integration_program_counter = "CACHE"
                    structure = None
                elif committed_phase == "CACHE":
                    self.ctx.integration_program_counter = "YAPI"
                    structure = None
                elif committed_phase == "YAPI":
                    self.ctx.integration_program_counter = "SONUÇ"
                else:
                    self.ctx.integration_status = "FAILED"
                    raise

        raise AssertionError(
            "Entegrasyon sonuç üretmeden state machine'den çıktı"
        )
