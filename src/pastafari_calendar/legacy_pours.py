from .legacy_arithmetic import savePatch
from .legacy_hidden import countsFromContext


WHEAT = 0
BARLEY = 1
SALT = 2

BOWL_PRIME = (
    None,
    17,
    19,
    23,
    29,
    31,
    37,
)


def initialBowlsThroughOldFactory(
    counts,
) -> tuple[int, ...]:
    bowls = [0] * 7

    bowl_id = 1
    while bowl_id <= 6:
        prime = BOWL_PRIME[bowl_id]
        temp = (
            counts.action
            + counts.target * bowl_id
            + counts.distance
            + counts.connection
            + counts.direction
            + prime * prime
        )
        bowls[bowl_id] = savePatch(
            temp * temp
            + bowl_id
        )
        bowl_id += 1

    return tuple(bowls)


def legacyFixedBowlPours(
    i: int,
    drop: int,
    stones: tuple[tuple[int, ...], ...],
    old_bowls: tuple[int, ...],
) -> tuple[int, ...]:
    if i < 1 or i > 46:
        raise ValueError("Görünür damla indeksi 1 ile 46 arasında olmalıdır")

    pour = [0] * 7

    # Tarihsel kusur: eski kod position 1,2,3 yerine sabit bowl ID 1,2,3 okur.
    pour[1] = savePatch(
        drop * drop
        + stones[i][WHEAT] * old_bowls[1]
        + 3 * i
    )
    pour[2] = savePatch(
        drop * drop
        + stones[i][BARLEY] * old_bowls[2]
        + 5 * i
    )
    pour[3] = savePatch(
        drop * drop
        + stones[i][SALT] * old_bowls[3]
        + 7 * i
    )

    return tuple(pour)


class LegacyPourAdapter:
    def ensure_initial_bowls(
        self,
        ctx,
    ) -> tuple[int, ...]:
        if ctx.legacy_initial_bowls is None:
            counts = countsFromContext(ctx)
            ctx.legacy_initial_bowls = initialBowlsThroughOldFactory(
                counts,
            )

        return ctx.legacy_initial_bowls

    def call(
        self,
        ctx,
        i: int,
    ) -> tuple[int, ...]:
        if ctx.legacy_stone_table is None:
            raise RuntimeError("Taş tablosu legacy pour erişiminden önce hazır olmalıdır")
        if ctx.legacy_visible_drop_table is None:
            raise RuntimeError("Görünür damlalar legacy pour erişiminden önce hazır olmalıdır")
        if ctx.legacy_permutation_order_table is None:
            raise RuntimeError("Permütasyon sıraları legacy pour erişiminden önce hazır olmalıdır")

        old_bowls = self.ensure_initial_bowls(
            ctx,
        )
        drop = ctx.legacy_visible_drop_table[i]
        order = ctx.legacy_permutation_order_table[i]

        ctx.branch_trace.append(
            (
                "ESKİ_SABİT_KÂSE_POURS",
                i,
                order,
            )
        )
        ctx.logs.append(
            (
                "eski-sabit-kâse-pours",
                i,
                order,
            )
        )

        pours = legacyFixedBowlPours(
            i,
            drop,
            ctx.legacy_stone_table,
            old_bowls,
        )

        ctx.legacy_pour_last_drop_index = i
        ctx.legacy_pour_last_order = order
        ctx.legacy_pour_last_values = pours

        return pours
