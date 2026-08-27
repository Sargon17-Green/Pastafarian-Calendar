from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from math import comb, factorial
from pathlib import Path
from typing import Iterable

M = 2**127 - 1
TABLETS_DAY = -278522
FOUNDATION_DAY = -15055671

GATE_GAP_MIN = 42
GATE_GAP_MAX = 963
YEAR_MIN_DAYS = 252
YEAR_MAX_DAYS = 5778
MIN_GATE_GAPS_PER_YEAR = 6
MIN_CUTLETS = 6
MAX_CUTLETS = 17
MIN_MONTHS = 3
MAX_MONTHS = 47
MIN_MONTH_DAYS = 4
MAX_MONTH_DAYS = 123

SEAL_GATE_GAP = 1
SEAL_YEAR_5000 = 10
SEAL_NEXT_YEAR = 11
SEAL_PREVIOUS_YEAR = 12
SEAL_CUTLET_COUNT = 20
SEAL_CUTLET_PARTITION = 21
SEAL_CUTLET_NAMES = 22
SEAL_MONTH_COUNT = 30
SEAL_MONTH_LENGTHS = 31
SEAL_MONTH_WEAVING = 32
SEAL_MONTH_NAMES = 33

WHEAT = 0
BARLEY = 1
SALT = 2
BITTER = 3
RED = 4

HIDDEN_COEFF = (
    None,
    (3, 4, 6, 8),
    (5, 7, 10, 12),
    (7, 10, 14, 16),
    (9, 13, 18, 20),
    (11, 16, 22, 24),
    (13, 19, 26, 28),
    (15, 22, 30, 32),
)

HIDDEN_GRIND_STONE = (
    WHEAT,
    BARLEY,
    SALT,
    BITTER,
    RED,
    WHEAT,
    BARLEY,
)

VISIBLE_GRINDS = (
    (3, 5, 7, 11, WHEAT),
    (5, 7, 11, 13, BARLEY),
    (7, 11, 13, 17, SALT),
    (11, 13, 17, 19, BITTER),
    (13, 17, 19, 23, RED),
    (17, 19, 23, 29, WHEAT),
    (19, 23, 29, 31, BARLEY),
    (23, 29, 31, 37, SALT),
    (29, 31, 37, 41, BITTER),
    (31, 37, 41, 43, RED),
    (37, 41, 43, 47, WHEAT),
)

BOWL_PRIME = (17, 19, 23, 29, 31, 37)
BOWL_STIR_STONE_BY_POSITION = (
    WHEAT,
    BARLEY,
    SALT,
    BITTER,
    RED,
    WHEAT,
)


def regular_mod(x: int, d: int) -> int:
    if d < 1:
        raise ValueError("Bölen en az bir olmalıdır")
    return x % d


def save(x: int) -> int:
    return 1 + regular_mod(x - 1, M)


def ceil_div(a: int, b: int) -> int:
    if a < 0 or b < 1:
        raise ValueError("Tavan bölmesinin girdileri geçersiz")
    return (a + b - 1) // b


def wrap1(position: int, size: int) -> int:
    if size < 1:
        raise ValueError("Sarma boyutu en az bir olmalıdır")
    return regular_mod(position - 1, size) + 1


@dataclass(frozen=True, slots=True)
class WorkCounts:
    action: int
    target: int
    distance: int
    connection: int
    direction: int


def day_count(day: int) -> int:
    if day == FOUNDATION_DAY:
        return 1
    if day > FOUNDATION_DAY:
        return 2 * (day - FOUNDATION_DAY) + 1
    return 2 * (FOUNDATION_DAY - day)


def work_counts(calculation_day: int, target_day: int) -> WorkCounts:
    action = day_count(calculation_day)
    target = day_count(target_day)
    distance = abs(target_day - calculation_day) + 1
    connection = action + target
    if target_day < calculation_day:
        direction = 1
    elif target_day == calculation_day:
        direction = 2
    else:
        direction = 3
    return WorkCounts(action, target, distance, connection, direction)


def build_stones() -> tuple[tuple[int, ...], ...]:
    rows: list[tuple[int, ...]] = [tuple()] * 47
    rows[1] = (17, 29, 43, 71, 101)
    for i in range(2, 47):
        old = rows[i - 1]
        rows[i] = (
            save(old[WHEAT] ** 2 + 3 * old[BARLEY] + i),
            save(old[BARLEY] ** 2 + 5 * old[SALT] + old[WHEAT]),
            save(old[SALT] ** 2 + 7 * old[BITTER] + old[BARLEY]),
            save(old[BITTER] ** 2 + 11 * old[RED] + old[SALT]),
            save(old[RED] ** 2 + 13 * old[WHEAT] + old[BITTER]),
        )
    return tuple(rows)


STONES = build_stones()


def build_hidden_drops(counts: WorkCounts) -> tuple[int, ...]:
    hidden = [0] * 8
    for k in range(1, 8):
        a, b, c, d = HIDDEN_COEFF[k]
        x = (
            counts.action
            + a * counts.target
            + b * counts.distance
            + c * counts.connection
            + d * counts.direction
            + sum(STONES[k])
        )
        x = save(x)
        for grind, kind in enumerate(HIDDEN_GRIND_STONE, start=1):
            old_x = x
            x = save(old_x**2 + 3 * old_x + STONES[k][kind] + grind)
        hidden[k] = x
    return tuple(hidden)


def build_visible_drops(counts: WorkCounts, hidden: tuple[int, ...]) -> tuple[int, ...]:
    timeline: dict[int, int] = {}
    for k in range(1, 8):
        timeline[1 - k] = hidden[k]
    visible = [0] * 47
    for i in range(1, 47):
        prev1 = timeline[i - 1]
        prev3 = timeline[i - 3]
        prev7 = timeline[i - 7]
        x = save(
            STONES[i][WHEAT] * counts.action
            + STONES[i][BARLEY] * counts.target
            + STONES[i][SALT] * counts.distance
            + STONES[i][BITTER] * counts.connection
            + STONES[i][RED] * counts.direction
            + prev1
            + 3 * prev3
            + 5 * prev7
            + i
        )
        for a, b, c, d, kind in VISIBLE_GRINDS:
            old_x = x
            x = save(
                old_x**2
                + a * old_x
                + b * prev1
                + c * prev3
                + d * prev7
                + STONES[i][kind]
            )
        timeline[i] = x
        visible[i] = x
    return tuple(visible)


def permutation_unrank1(rank1: int, items_ascending: Iterable[int]) -> tuple[int, ...]:
    remaining = list(items_ascending)
    if not 1 <= rank1 <= factorial(len(remaining)):
        raise ValueError("Permütasyon derecesi aralık dışında")
    rank0 = rank1 - 1
    result: list[int] = []
    while remaining:
        block = factorial(len(remaining) - 1)
        q, rank0 = divmod(rank0, block)
        result.append(remaining.pop(q))
    return tuple(result)


def bowl_order_from_number(order_number: int) -> tuple[int, ...]:
    if not 1 <= order_number <= 720:
        raise ValueError("Kâse sıra numarası aralık dışında")
    return permutation_unrank1(order_number, (1, 2, 3, 4, 5, 6))


def bowl_order_from_drop(drop_value: int) -> tuple[int, ...]:
    return bowl_order_from_number(regular_mod(drop_value - 1, 720) + 1)


def initial_bowls(counts: WorkCounts) -> tuple[int, ...]:
    bowls = [0] * 7
    for bowl_id in range(1, 7):
        s = (
            counts.action
            + counts.target * bowl_id
            + counts.distance
            + counts.connection
            + counts.direction
            + BOWL_PRIME[bowl_id - 1] ** 2
        )
        bowls[bowl_id] = save(s**2 + bowl_id)
    return tuple(bowls)


@dataclass(frozen=True, slots=True)
class SauceResult:
    bowls: tuple[int, ...]
    order_at_drop_46: tuple[int, ...]


def apply_visible_drops_to_bowls(
    bowls: tuple[int, ...],
    visible: tuple[int, ...],
) -> tuple[tuple[int, ...], tuple[int, ...]]:
    working = bowls
    order_at_46: tuple[int, ...] | None = None
    for i in range(1, 47):
        drop = visible[i]
        order = bowl_order_from_drop(drop)
        old = working
        pour = [0] * 7
        pour[1] = save(drop**2 + STONES[i][WHEAT] * old[order[0]] + 3 * i)
        pour[2] = save(drop**2 + STONES[i][BARLEY] * old[order[1]] + 5 * i)
        pour[3] = save(drop**2 + STONES[i][SALT] * old[order[2]] + 7 * i)
        next_bowls = [0] * 7
        for position in range(1, 7):
            bowl_id = order[position - 1]
            prev_id = order[(position - 2) % 6]
            next_id = order[position % 6]
            kind = BOWL_STIR_STONE_BY_POSITION[position - 1]
            s = (
                old[bowl_id]
                + 2 * old[prev_id]
                + 3 * old[next_id]
                + pour[position]
                + drop
                + STONES[i][kind]
            )
            next_bowls[bowl_id] = save(
                s**2
                + 5 * old[prev_id] * old[next_id]
                + i * position
            )
        working = tuple(next_bowls)
        if i == 46:
            order_at_46 = tuple(order)
    if order_at_46 is None:
        raise AssertionError("Kırk altıncı damla sırası tutulamadı")
    return working, order_at_46


def post_stir12(bowls: tuple[int, ...]) -> tuple[int, ...]:
    working = bowls
    for stir in range(1, 13):
        old = working
        saved_bowl_sum = save(sum(old[1:7]) + 149 * stir)
        order_number = regular_mod(saved_bowl_sum - 1, 720) + 1
        order = bowl_order_from_number(order_number)
        next_bowls = [0] * 7
        for position in range(1, 7):
            bowl_id = order[position - 1]
            prev_id = order[(position - 2) % 6]
            next_id = order[position % 6]
            s = (
                old[bowl_id]
                + 3 * old[prev_id]
                + 5 * old[next_id]
                + saved_bowl_sum
                + stir
                + position**2
            )
            next_bowls[bowl_id] = save(
                s**2 + 7 * old[prev_id] * old[next_id]
            )
        working = tuple(next_bowls)
    return working


def sauce(calculation_day: int, target_day: int) -> SauceResult:
    counts = work_counts(calculation_day, target_day)
    hidden = build_hidden_drops(counts)
    visible = build_visible_drops(counts, hidden)
    bowls = initial_bowls(counts)
    bowls_after, order_at_46 = apply_visible_drops_to_bowls(bowls, visible)
    final_bowls = post_stir12(bowls_after)
    return SauceResult(final_bowls, order_at_46)


@dataclass(frozen=True, slots=True)
class AnswerStream:
    first: int
    direction_step: int


def next_bowl_in_drop46_order(result: SauceResult, queried_bowl_id: int) -> int:
    p = result.order_at_drop_46.index(queried_bowl_id)
    return result.order_at_drop_46[(p + 1) % 6]


def ask_bowl(result: SauceResult, queried_bowl_id: int, seal: int) -> AnswerStream:
    next_id = next_bowl_in_drop46_order(result, queried_bowl_id)
    first = save(
        (result.bowls[queried_bowl_id] + seal + 181) ** 2
        + result.bowls[next_id] * 179
        + seal
    )
    direction_number = save(
        (first + seal + 1 + 193) ** 2
        + first * 193
        + result.bowls[6] * 197
    )
    step = 1 if regular_mod(direction_number, 2) == 1 else -1
    return AnswerStream(first, step)


def answer_at(stream: AnswerStream, k: int) -> int:
    return 1 + regular_mod(stream.first - 1 + stream.direction_step * k, M)


def choose_rank_short(stream: AnswerStream, n: int) -> int:
    if not 1 <= n <= M:
        raise ValueError("Kısa seçim büyüklüğü geçersiz")
    acceptance_limit = (M // n) * n
    k = 0
    while True:
        x = answer_at(stream, k)
        if x <= acceptance_limit:
            return regular_mod(x - 1, n) + 1
        k += 1


def choose_rank_wide(stream: AnswerStream, n: int) -> int:
    if n <= M:
        raise ValueError("Geniş seçim büyüklüğü geçersiz")
    places = 1
    space = M
    while space < n:
        places += 1
        space *= M
    wide = 1
    weight = 1
    for j in range(places):
        wide += (answer_at(stream, j) - 1) * weight
        weight *= M
    acceptance_limit = (space // n) * n
    while wide > acceptance_limit:
        wide = 1 + regular_mod(wide - 1 + stream.direction_step, space)
    return regular_mod(wide - 1, n) + 1


def choose_rank(stream: AnswerStream, n: int) -> int:
    if n < 1:
        raise ValueError("Seçim ailesi boş olamaz")
    if n <= M:
        return choose_rank_short(stream, n)
    return choose_rank_wide(stream, n)


def falling_factorial(n: int, k: int) -> int:
    if not 0 <= k <= n:
        raise ValueError("Düşen faktöriyel girdileri geçersiz")
    result = 1
    for j in range(k):
        result *= n - j
    return result


def unrank_distinct_indices(master_count: int, k: int, rank1: int) -> tuple[int, ...]:
    if not 0 <= k <= master_count:
        raise ValueError("Ayrık ad sayısı geçersiz")
    total = falling_factorial(master_count, k)
    if not 1 <= rank1 <= total:
        raise ValueError("Ayrık ad derecesi aralık dışında")
    remaining = list(range(1, master_count + 1))
    out: list[int] = []
    r = rank1
    for position in range(k):
        suffix_length = k - position - 1
        block = falling_factorial(len(remaining) - 1, suffix_length)
        candidate_position = (r - 1) // block
        r = (r - 1) % block + 1
        out.append(remaining.pop(candidate_position))
    return tuple(out)


class BoundedCompositionFamily:
    def __init__(self, total: int, slots: int, lo: int, hi: int) -> None:
        if total < 0 or slots < 0 or lo < 0 or hi < lo:
            raise ValueError("Sınırlı bileşim girdileri geçersiz")
        self.total = total
        self.slots = slots
        self.lo = lo
        self.hi = hi
        ways = [[0] * (total + 1) for _ in range(slots + 1)]
        ways[0][0] = 1
        for k in range(1, slots + 1):
            window = 0
            prev = ways[k - 1]
            cur = ways[k]
            for s in range(total + 1):
                enter = s - lo
                leave = s - hi - 1
                if enter >= 0:
                    window += prev[enter]
                if leave >= 0:
                    window -= prev[leave]
                cur[s] = window
        self._ways = ways

    def count(self) -> int:
        return self._ways[self.slots][self.total]

    def unrank1(self, rank1: int) -> tuple[int, ...]:
        if not 1 <= rank1 <= self.count():
            raise ValueError("Sınırlı bileşim derecesi aralık dışında")
        rem = self.total
        out: list[int] = []
        for position in range(self.slots):
            slots_after = self.slots - position - 1
            selected = False
            for x in range(self.lo, self.hi + 1):
                rest = rem - x
                block = self._ways[slots_after][rest] if 0 <= rest <= self.total else 0
                if rank1 > block:
                    rank1 -= block
                else:
                    out.append(x)
                    rem = rest
                    selected = True
                    break
            if not selected:
                raise AssertionError("Sınırlı bileşim açılamadı")
        if rem != 0:
            raise AssertionError("Sınırlı bileşim sonunda artık kaldı")
        return tuple(out)


class CutletPartitionFamily:
    def __init__(self, gate_gaps: int, cutlet_count: int, required_boundary: int | None) -> None:
        self.gate_gaps = gate_gaps
        self.cutlet_count = cutlet_count
        self.required_boundary = required_boundary

        @lru_cache(maxsize=None)
        def count(rem: int, slots: int, cumulative: int, hit: bool) -> int:
            if slots == 0:
                if rem != 0:
                    return 0
                if required_boundary is None:
                    return 1
                return 1 if hit else 0
            if rem < slots:
                return 0
            total = 0
            max_x = rem - (slots - 1)
            for x in range(1, max_x + 1):
                next_cumulative = cumulative + x
                next_hit = hit
                if required_boundary is not None and not hit:
                    if next_cumulative == required_boundary:
                        next_hit = True
                    elif next_cumulative > required_boundary:
                        continue
                total += count(rem - x, slots - 1, next_cumulative, next_hit)
            return total

        self._count = count

    def count(self) -> int:
        return self._count(self.gate_gaps, self.cutlet_count, 0, False)

    def unrank1(self, rank1: int) -> tuple[int, ...]:
        if not 1 <= rank1 <= self.count():
            raise ValueError("Köfte bölümü derecesi aralık dışında")
        rem = self.gate_gaps
        slots = self.cutlet_count
        cumulative = 0
        hit = False
        out: list[int] = []
        while slots > 0:
            max_x = rem - (slots - 1)
            selected = False
            for x in range(1, max_x + 1):
                next_cumulative = cumulative + x
                next_hit = hit
                if self.required_boundary is not None and not hit:
                    if next_cumulative == self.required_boundary:
                        next_hit = True
                    elif next_cumulative > self.required_boundary:
                        continue
                block = self._count(
                    rem - x,
                    slots - 1,
                    next_cumulative,
                    next_hit,
                )
                if rank1 > block:
                    rank1 -= block
                else:
                    out.append(x)
                    rem -= x
                    slots -= 1
                    cumulative = next_cumulative
                    hit = next_hit
                    selected = True
                    break
            if not selected:
                raise AssertionError("Köfte bölümü açılamadı")
        return tuple(out)


class MonthWeavingFamily:
    def __init__(self, lengths: Iterable[int]) -> None:
        self.lengths = tuple(int(x) for x in lengths)
        if not self.lengths or any(x < 1 for x in self.lengths):
            raise ValueError("Ay örgüsü uzunlukları pozitif olmalıdır")
        self.month_count = len(self.lengths)
        prefix = [0]
        for n in self.lengths:
            prefix.append(prefix[-1] + n)
        self._prefix = tuple(prefix)
        self._h: list[list[int]] = [[] for _ in range(self.month_count + 1)]
        self._h[self.month_count] = [1] * (prefix[-1] + 1)

        for opened in range(self.month_count - 1, -1, -1):
            n = self.lengths[opened]
            max_x = prefix[opened]
            if n == 1:
                fixed = self._h[opened + 1][0]
                self._h[opened] = [fixed] * (max_x + 1)
                continue

            max_y = prefix[opened + 1] - 1
            weighted_prefix = [0] * (max_y + 1)
            running = 0
            lower = n - 1
            for y in range(max_y + 1):
                if y >= lower:
                    running += comb(y - 1, n - 2) * self._h[opened + 1][y]
                weighted_prefix[y] = running
            row = [0] * (max_x + 1)
            for x in range(max_x + 1):
                row[x] = weighted_prefix[x + n - 1]
            self._h[opened] = row

    def count(self) -> int:
        return self._h[0][0]

    def _state_count(
        self,
        remaining: tuple[int, ...],
        opened: int,
        closed: int,
    ) -> int:
        if opened < closed or opened > self.month_count:
            return 0
        base_count = 1
        base_length = 0
        for index in range(closed, opened):
            n = remaining[index]
            if n <= 0:
                return 0
            if base_length == 0:
                base_length = n
            else:
                base_count *= comb(n + base_length - 1, base_length)
                base_length += n
        if base_length >= len(self._h[opened]):
            raise AssertionError("Örgü durumunun tablosu yetersiz")
        return base_count * self._h[opened][base_length]

    def _moves(
        self,
        remaining: tuple[int, ...],
        opened: int,
        closed: int,
    ):
        for index in range(closed, opened):
            n = remaining[index]
            if n <= 0:
                continue
            if n == 1 and index != closed:
                continue
            next_remaining = list(remaining)
            next_remaining[index] -= 1
            next_closed = closed + 1 if next_remaining[index] == 0 else closed
            yield index + 1, tuple(next_remaining), opened, next_closed

        if opened < self.month_count:
            index = opened
            next_remaining = list(remaining)
            next_remaining[index] -= 1
            next_opened = opened + 1
            next_closed = closed
            if next_remaining[index] == 0:
                if index != closed:
                    raise AssertionError("Yeni ay kapanış sırasını bozdu")
                next_closed += 1
            yield index + 1, tuple(next_remaining), next_opened, next_closed

    def unrank1(self, rank1: int) -> tuple[int, ...]:
        total = self.count()
        if not 1 <= rank1 <= total:
            raise ValueError("Ay örgüsü derecesi aralık dışında")
        remaining = self.lengths
        opened = 0
        closed = 0
        out: list[int] = []
        total_days = sum(self.lengths)

        while len(out) < total_days:
            selected = False
            for month_id, next_remaining, next_opened, next_closed in self._moves(
                remaining,
                opened,
                closed,
            ):
                block = self._state_count(
                    next_remaining,
                    next_opened,
                    next_closed,
                )
                if rank1 > block:
                    rank1 -= block
                else:
                    out.append(month_id)
                    remaining = next_remaining
                    opened = next_opened
                    closed = next_closed
                    selected = True
                    break
            if not selected:
                raise AssertionError("Ay örgüsü derece açma işlemi ilerleyemedi")

        if any(remaining) or opened != self.month_count or closed != self.month_count:
            raise AssertionError("Ay örgüsü son durumu geçersiz")
        return tuple(out)


def brute_weavings(lengths: Iterable[int]) -> tuple[tuple[int, ...], ...]:
    lengths = tuple(lengths)
    remaining = list(lengths)
    out: list[tuple[int, ...]] = []

    def walk(prefix: list[int], opened: int, closed: int) -> None:
        if len(prefix) == sum(lengths):
            out.append(tuple(prefix))
            return
        for index in range(closed, opened):
            n = remaining[index]
            if n <= 0:
                continue
            if n == 1 and index != closed:
                continue
            remaining[index] -= 1
            next_closed = closed + 1 if remaining[index] == 0 else closed
            prefix.append(index + 1)
            walk(prefix, opened, next_closed)
            prefix.pop()
            remaining[index] += 1
        if opened < len(lengths):
            index = opened
            remaining[index] -= 1
            next_closed = closed
            if remaining[index] == 0:
                if index != closed:
                    remaining[index] += 1
                    return
                next_closed += 1
            prefix.append(index + 1)
            walk(prefix, opened + 1, next_closed)
            prefix.pop()
            remaining[index] += 1

    walk([], 0, 0)
    return tuple(sorted(out))


@dataclass(frozen=True, slots=True)
class Year:
    number: int
    open_gate_index: int
    close_gate_index: int
    open_gate_day: int
    close_gate_day: int


class GateTable:
    def __init__(self) -> None:
        self.gates: dict[int, int] = {0: FOUNDATION_DAY}
        self.min_known = 0
        self.max_known = 0

    def _positive_gap(self, n: int) -> int:
        result = sauce(FOUNDATION_DAY, FOUNDATION_DAY + n)
        stream = ask_bowl(result, 1, SEAL_GATE_GAP)
        return 41 + choose_rank(stream, 922)

    def _negative_gap(self, n: int) -> int:
        result = sauce(FOUNDATION_DAY, FOUNDATION_DAY - n)
        stream = ask_bowl(result, 1, SEAL_GATE_GAP)
        return 41 + choose_rank(stream, 922)

    def ensure_index(self, k: int) -> int:
        if k > self.max_known:
            for n in range(self.max_known + 1, k + 1):
                self.gates[n] = self.gates[n - 1] + self._positive_gap(n)
            self.max_known = k
        elif k < self.min_known:
            n = self.min_known - 1
            while n >= k:
                self.gates[n] = self.gates[n + 1] - self._negative_gap(abs(n))
                n -= 1
            self.min_known = k
        return self.gates[k]

    def ensure_cover(self, low_day: int, high_day: int) -> None:
        if low_day > high_day:
            raise ValueError("Kaplama aralığı ters olamaz")
        while self.gates[self.min_known] > low_day:
            self.ensure_index(self.min_known - 1)
        while self.gates[self.max_known] < high_day:
            self.ensure_index(self.max_known + 1)

    def gate_index_at_or_before(self, day: int) -> int:
        self.ensure_cover(day, day)
        lo = self.min_known
        hi = self.max_known
        while lo < hi:
            mid = lo + (hi - lo + 1) // 2
            if self.gates[mid] <= day:
                lo = mid
            else:
                hi = mid - 1
        return lo

    def exact_gate_index(self, day: int) -> int | None:
        i = self.gate_index_at_or_before(day)
        return i if self.gates[i] == day else None


@dataclass(frozen=True, slots=True)
class Cutlet:
    name_index: int
    open_gate_index: int
    close_gate_index: int
    first_day: int
    last_day: int


@dataclass(frozen=True, slots=True)
class YearStructure:
    cutlet_count: int
    cutlet_partition: tuple[int, ...]
    cutlet_name_indices: tuple[int, ...]
    cutlets: tuple[Cutlet, ...]
    month_count: int
    month_lengths: tuple[int, ...]
    month_weaving: tuple[int, ...]
    month_name_indices: tuple[int, ...]


@dataclass(frozen=True, slots=True)
class DateIds:
    year_number: int
    cutlet_name_index: int
    day_in_cutlet: int
    month_name_index: int
    day_in_month: int


@dataclass(frozen=True, slots=True)
class DateResult:
    year_number: int
    cutlet_name: str
    day_in_cutlet: int
    month_name: str
    day_in_month: int


class NormativeCalendar:
    def __init__(self) -> None:
        self.gates = GateTable()

    def _valid_year_pair(self, open_index: int, close_index: int) -> bool:
        if close_index - open_index < MIN_GATE_GAPS_PER_YEAR:
            return False
        length = self.gates.gates[close_index] - self.gates.gates[open_index]
        return YEAR_MIN_DAYS <= length <= YEAR_MAX_DAYS

    def year5000(self, calculation_day: int) -> Year:
        self.gates.ensure_cover(
            calculation_day - YEAR_MAX_DAYS,
            calculation_day + YEAR_MAX_DAYS,
        )
        candidates: list[tuple[int, int]] = []
        for i in range(self.gates.min_known, self.gates.max_known):
            for j in range(i + MIN_GATE_GAPS_PER_YEAR, self.gates.max_known + 1):
                length = self.gates.gates[j] - self.gates.gates[i]
                if length > YEAR_MAX_DAYS:
                    break
                if length < YEAR_MIN_DAYS:
                    continue
                if self.gates.gates[i] < calculation_day <= self.gates.gates[j]:
                    candidates.append((i, j))
        candidates.sort(
            key=lambda pair: (
                self.gates.gates[pair[1]] - self.gates.gates[pair[0]],
                self.gates.gates[pair[0]],
            )
        )
        if not candidates:
            raise AssertionError("Beş bininci yıl için aday bulunamadı")
        result = sauce(calculation_day, calculation_day)
        rank = choose_rank(ask_bowl(result, 1, SEAL_YEAR_5000), len(candidates))
        i, j = candidates[rank - 1]
        return Year(5000, i, j, self.gates.gates[i], self.gates.gates[j])

    def next_year(self, calculation_day: int, known: Year) -> Year:
        open_index = known.close_gate_index
        self.gates.ensure_cover(
            self.gates.gates[open_index],
            self.gates.gates[open_index] + YEAR_MAX_DAYS,
        )
        candidates: list[int] = []
        close_index = open_index + 1
        while True:
            self.gates.ensure_index(close_index)
            length = self.gates.gates[close_index] - self.gates.gates[open_index]
            if length > YEAR_MAX_DAYS:
                break
            if self._valid_year_pair(open_index, close_index):
                candidates.append(close_index)
            close_index += 1
        candidates.sort(key=lambda j: self.gates.gates[j] - self.gates.gates[open_index])
        result = sauce(calculation_day, self.gates.gates[open_index])
        rank = choose_rank(ask_bowl(result, 1, SEAL_NEXT_YEAR), len(candidates))
        close_index = candidates[rank - 1]
        return Year(
            known.number + 1,
            open_index,
            close_index,
            self.gates.gates[open_index],
            self.gates.gates[close_index],
        )

    def previous_year(self, calculation_day: int, known: Year) -> Year:
        close_index = known.open_gate_index
        self.gates.ensure_cover(
            self.gates.gates[close_index] - YEAR_MAX_DAYS,
            self.gates.gates[close_index],
        )
        candidates: list[int] = []
        open_index = close_index - 1
        while True:
            self.gates.ensure_index(open_index)
            length = self.gates.gates[close_index] - self.gates.gates[open_index]
            if length > YEAR_MAX_DAYS:
                break
            if self._valid_year_pair(open_index, close_index):
                candidates.append(open_index)
            open_index -= 1
        candidates.sort(key=lambda i: self.gates.gates[close_index] - self.gates.gates[i])
        result = sauce(calculation_day, self.gates.gates[close_index])
        rank = choose_rank(ask_bowl(result, 1, SEAL_PREVIOUS_YEAR), len(candidates))
        open_index = candidates[rank - 1]
        return Year(
            known.number - 1,
            open_index,
            close_index,
            self.gates.gates[open_index],
            self.gates.gates[close_index],
        )

    def find_target_year(self, calculation_day: int, target_day: int) -> Year:
        year = self.year5000(calculation_day)
        while target_day > year.close_gate_day:
            year = self.next_year(calculation_day, year)
        while target_day <= year.open_gate_day:
            year = self.previous_year(calculation_day, year)
        if not (year.open_gate_day < target_day <= year.close_gate_day):
            raise AssertionError("Hedef gün yıl aralığına yerleşmedi")
        return year

    def choose_cutlet_count(self, result: SauceResult, year: Year) -> int:
        gate_gaps = year.close_gate_index - year.open_gate_index
        candidates = [k for k in range(MIN_CUTLETS, MAX_CUTLETS + 1) if k <= gate_gaps]
        rank = choose_rank(ask_bowl(result, 2, SEAL_CUTLET_COUNT), len(candidates))
        return candidates[rank - 1]

    def choose_cutlet_partition(
        self,
        calculation_day: int,
        result: SauceResult,
        year: Year,
        cutlet_count: int,
    ) -> tuple[int, ...]:
        gate_gaps = year.close_gate_index - year.open_gate_index
        gate_index = self.gates.exact_gate_index(calculation_day)
        if (
            gate_index is not None
            and year.open_gate_index < gate_index < year.close_gate_index
        ):
            required = gate_index - year.open_gate_index
        else:
            required = None
        family = CutletPartitionFamily(gate_gaps, cutlet_count, required)
        rank = choose_rank(ask_bowl(result, 2, SEAL_CUTLET_PARTITION), family.count())
        return family.unrank1(rank)

    def choose_cutlet_names(self, result: SauceResult, cutlet_count: int) -> tuple[int, ...]:
        n = falling_factorial(17, cutlet_count)
        rank = choose_rank(ask_bowl(result, 5, SEAL_CUTLET_NAMES), n)
        return unrank_distinct_indices(17, cutlet_count, rank)

    def materialize_cutlets(
        self,
        year: Year,
        partition: tuple[int, ...],
        names: tuple[int, ...],
    ) -> tuple[Cutlet, ...]:
        cursor = year.open_gate_index
        out: list[Cutlet] = []
        for span, name_index in zip(partition, names):
            open_index = cursor
            close_index = cursor + span
            out.append(
                Cutlet(
                    name_index,
                    open_index,
                    close_index,
                    self.gates.gates[open_index] + 1,
                    self.gates.gates[close_index],
                )
            )
            cursor = close_index
        return tuple(out)

    def choose_month_count(self, result: SauceResult, year: Year) -> int:
        length = year.close_gate_day - year.open_gate_day
        minimum = ceil_div(length, MAX_MONTH_DAYS)
        maximum = min(MAX_MONTHS, length // MIN_MONTH_DAYS)
        if not 3 <= minimum <= maximum <= MAX_MONTHS:
            raise AssertionError("Ay sayısı sınırları geçersiz")
        candidates = list(range(minimum, maximum + 1))
        rank = choose_rank(ask_bowl(result, 3, SEAL_MONTH_COUNT), len(candidates))
        return candidates[rank - 1]

    def choose_month_lengths(
        self,
        result: SauceResult,
        year: Year,
        month_count: int,
    ) -> tuple[int, ...]:
        length = year.close_gate_day - year.open_gate_day
        family = BoundedCompositionFamily(
            length,
            month_count,
            MIN_MONTH_DAYS,
            MAX_MONTH_DAYS,
        )
        rank = choose_rank(ask_bowl(result, 3, SEAL_MONTH_LENGTHS), family.count())
        return family.unrank1(rank)

    def choose_month_weaving(
        self,
        result: SauceResult,
        month_lengths: tuple[int, ...],
    ) -> tuple[int, ...]:
        family = MonthWeavingFamily(month_lengths)
        rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())
        return family.unrank1(rank)

    def choose_month_names(self, result: SauceResult, month_count: int) -> tuple[int, ...]:
        n = falling_factorial(47, month_count)
        rank = choose_rank(ask_bowl(result, 5, SEAL_MONTH_NAMES), n)
        return unrank_distinct_indices(47, month_count, rank)

    def build_year_structure(self, calculation_day: int, year: Year) -> YearStructure:
        first_day = year.open_gate_day + 1
        result = sauce(calculation_day, first_day)
        cutlet_count = self.choose_cutlet_count(result, year)
        partition = self.choose_cutlet_partition(
            calculation_day,
            result,
            year,
            cutlet_count,
        )
        cutlet_names = self.choose_cutlet_names(result, cutlet_count)
        cutlets = self.materialize_cutlets(year, partition, cutlet_names)
        month_count = self.choose_month_count(result, year)
        month_lengths = self.choose_month_lengths(result, year, month_count)
        month_weaving = self.choose_month_weaving(result, month_lengths)
        month_names = self.choose_month_names(result, month_count)
        return YearStructure(
            cutlet_count,
            partition,
            cutlet_names,
            cutlets,
            month_count,
            month_lengths,
            month_weaving,
            month_names,
        )

    def calendar_date_ids(self, calculation_day: int, target_day: int) -> DateIds:
        year = self.find_target_year(calculation_day, target_day)
        structure = self.build_year_structure(calculation_day, year)
        chosen_cutlet: Cutlet | None = None
        for cutlet in structure.cutlets:
            if cutlet.first_day <= target_day <= cutlet.last_day:
                chosen_cutlet = cutlet
                break
        if chosen_cutlet is None:
            raise AssertionError("Hedef gün hiçbir köfteye düşmedi")
        day_in_cutlet = target_day - chosen_cutlet.first_day + 1
        year_offset0 = target_day - (year.open_gate_day + 1)
        month_id = structure.month_weaving[year_offset0]
        month_name_index = structure.month_name_indices[month_id - 1]
        day_in_month = sum(
            1
            for p in range(year_offset0 + 1)
            if structure.month_weaving[p] == month_id
        )
        return DateIds(
            year.number,
            chosen_cutlet.name_index,
            day_in_cutlet,
            month_name_index,
            day_in_month,
        )

    def calendar_date(self, calculation_day: int, target_day: int) -> DateResult:
        from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG

        ids = self.calendar_date_ids(calculation_day, target_day)
        return DateResult(
            ids.year_number,
            SOURCE_LANGUAGE_CATALOG.cutlet_text(ids.cutlet_name_index),
            ids.day_in_cutlet,
            SOURCE_LANGUAGE_CATALOG.month_text(ids.month_name_index),
            ids.day_in_month,
        )


def local_instant_to_discrete_day(instant, geographic_location, ephemeris_model):
    raise NotImplementedError(
        "Zaman tomarı tek bir sayısal efemeris modeli belirlemediği için bu dönüşüm tanımlı değildir"
    )
