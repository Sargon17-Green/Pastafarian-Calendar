from dataclasses import dataclass

from .legacy_arithmetic import savePatch


WHEAT = 0
BARLEY = 1
SALT = 2
BITTER = 3
RED = 4

LEGACY_HIDDEN_COEFF_REVERSED = (
    None,
    (15, 22, 30, 32),
    (13, 19, 26, 28),
    (11, 16, 22, 24),
    (9, 13, 18, 20),
    (7, 10, 14, 16),
    (5, 7, 10, 12),
    (3, 4, 6, 8),
)

_HIDDEN_STONE_KIND = (
    None,
    WHEAT,
    BARLEY,
    SALT,
    BITTER,
    RED,
    WHEAT,
    BARLEY,
)


@dataclass(frozen=True, slots=True)
class HiddenCountsSnapshot:
    action: int
    target: int
    distance: int
    connection: int
    direction: int


def coeffForHidden(k: int) -> tuple[int, int, int, int]:
    if k < 1 or k > 7:
        raise ValueError("Gizli damla yakınlık indeksi 1 ile 7 arasında olmalıdır")
    return LEGACY_HIDDEN_COEFF_REVERSED[8 - k]


def hiddenStoneKind(grind: int) -> int:
    if grind < 1 or grind > 7:
        raise ValueError("Gizli damla öğütme indeksi 1 ile 7 arasında olmalıdır")
    return _HIDDEN_STONE_KIND[grind]


def countsFromContext(ctx) -> HiddenCountsSnapshot:
    if ctx.patch02_action_day_tag_value is None:
        raise RuntimeError("Eylem günü etiketi gizli damlalardan önce hazır olmalıdır")
    if ctx.patch02_target_day_tag_value is None:
        raise RuntimeError("Hedef günü etiketi gizli damlalardan önce hazır olmalıdır")
    if ctx.patch03_distance_value is None:
        raise RuntimeError("Mesafe gizli damlalardan önce hazır olmalıdır")

    action = ctx.patch02_action_day_tag_value
    target = ctx.patch02_target_day_tag_value
    distance = ctx.patch03_distance_value
    connection = action + target

    if ctx.target_day < ctx.calculation_day:
        direction = 1
    elif ctx.target_day == ctx.calculation_day:
        direction = 2
    else:
        direction = 3

    return HiddenCountsSnapshot(
        action=action,
        target=target,
        distance=distance,
        connection=connection,
        direction=direction,
    )


def makeHiddenPatched(
    k: int,
    counts: HiddenCountsSnapshot,
    stones: tuple[tuple[int, ...], ...],
) -> int:
    a, b, c, d = coeffForHidden(k)

    x = (
        counts.action
        + a * counts.target
        + b * counts.distance
        + c * counts.connection
        + d * counts.direction
        + sum(stones[k])
    )
    x = savePatch(x)

    grind = 1
    while grind <= 7:
        before_square = x
        x = savePatch(
            before_square * before_square
            + 3 * before_square
            + stones[k][hiddenStoneKind(grind)]
            + grind
        )
        grind += 1

    return x


def buildHiddenWithBackwardStorage(
    counts: HiddenCountsSnapshot,
    stones: tuple[tuple[int, ...], ...],
) -> tuple[int, ...]:
    legacy_hidden = [0] * 8

    k = 1
    while k <= 7:
        legacy_hidden[8 - k] = makeHiddenPatched(
            k,
            counts,
            stones,
        )
        k += 1

    return tuple(legacy_hidden)


def legacyHiddenDirectByAssumedNearness(
    legacy_hidden: tuple[int, ...],
    k: int,
) -> int:
    if k < 1 or k > 7:
        raise ValueError("Gizli damla yakınlık indeksi 1 ile 7 arasında olmalıdır")

    # Tarihsel hata: fiziksel backward storage normal near-ness dizisi sanılır.
    return legacy_hidden[k]


class LegacyHiddenDropAdapter:
    def call(self, ctx) -> tuple[int, ...]:
        if ctx.legacy_stone_table is None:
            raise RuntimeError("Taş tablosu gizli damlalardan önce hazır olmalıdır")

        ctx.branch_trace.append(("ESKİ_GİZLİ_DAMLALAR",))
        ctx.logs.append(("eski-gizli-damlalar",))

        counts = countsFromContext(ctx)
        storage = buildHiddenWithBackwardStorage(
            counts,
            ctx.legacy_stone_table,
        )

        ctx.legacy_hidden_storage = storage
        ctx.legacy_hidden_count = 7

        return storage

    def read_by_nearness(self, ctx, k: int) -> int:
        if ctx.legacy_hidden_storage is None:
            raise RuntimeError("Gizli damla deposu erişimden önce kurulmalıdır")

        ctx.branch_trace.append(("ESKİ_GİZLİ_OKUMA", k))
        value = legacyHiddenDirectByAssumedNearness(
            ctx.legacy_hidden_storage,
            k,
        )

        ctx.legacy_hidden_last_requested_k = k
        ctx.legacy_hidden_last_returned_value = value

        return value
