from .legacy_arithmetic import savePatch
from .legacy_hidden import countsFromContext
from .legacy_prior import LegacyPriorAdapter


WHEAT = 0
BARLEY = 1
SALT = 2
BITTER = 3
RED = 4

LEGACY_VISIBLE_GRIND_TABLE = (
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

SENTINEL_GRIND_ROW = (0, 0, 0, 0, WHEAT)

GRIND_TABLE_WITH_SENTINEL = (
    SENTINEL_GRIND_ROW,
    *LEGACY_VISIBLE_GRIND_TABLE,
)


def legacyGrindRow(
    table: tuple[tuple[int, int, int, int, int], ...],
    grind: int,
) -> tuple[int, int, int, int, int]:
    if grind < 1 or grind > 11:
        raise ValueError("Görünür damla öğütme indeksi 1 ile 11 arasında olmalıdır")

    # Tarihsel kusur: 1-based grind doğrudan 0-based tablo indeksi sanılır.
    return table[grind]


def applyLegacyVisibleGrinds(
    ctx,
    i: int,
    x: int,
    prev1: int,
    prev3: int,
    prev7: int,
    stones: tuple[tuple[int, ...], ...],
) -> int:
    grind = 1

    while grind <= 11:
        try:
            a, b, c, d, kind = legacyGrindRow(
                GRIND_TABLE_WITH_SENTINEL,
                grind,
            )
        except IndexError:
            ctx.legacy_grind_missing_index = grind
            ctx.legacy_grind_rows_applied = grind - 1
            ctx.warnings.append(
                "Eski görünür öğütme tablosu son 1-based indeksi bulamadı"
            )
            return x

        old_x = x
        x = savePatch(
            old_x * old_x
            + a * old_x
            + b * prev1
            + c * prev3
            + d * prev7
            + stones[i][kind]
        )
        grind += 1

    ctx.legacy_grind_missing_index = None
    ctx.legacy_grind_rows_applied = 11
    ctx.patch07_sentinel_present = True
    ctx.patch07_table_length = len(GRIND_TABLE_WITH_SENTINEL)
    ctx.patch07_applied = True
    return x


class LegacyVisibleDropBuilderAdapter:
    def __init__(self) -> None:
        self.prior = LegacyPriorAdapter()

    def call(self, ctx) -> tuple[int, ...]:
        if ctx.legacy_stone_table is None:
            raise RuntimeError("Taş tablosu görünür damlalardan önce hazır olmalıdır")
        if ctx.legacy_hidden_storage is None:
            raise RuntimeError("Gizli damlalar görünür damlalardan önce hazır olmalıdır")

        counts = countsFromContext(ctx)
        drop_store: dict[int, int] = {}
        visible = [0] * 47

        ctx.branch_trace.append(("ESKİ_GÖRÜNÜR_DAMLALAR",))
        ctx.logs.append(("eski-görünür-damlalar",))

        i = 1
        while i <= 46:
            prev1 = self.prior.call(
                ctx,
                drop_store,
                i,
                1,
            )
            prev3 = self.prior.call(
                ctx,
                drop_store,
                i,
                3,
            )
            prev7 = self.prior.call(
                ctx,
                drop_store,
                i,
                7,
            )

            x = savePatch(
                ctx.legacy_stone_table[i][WHEAT] * counts.action
                + ctx.legacy_stone_table[i][BARLEY] * counts.target
                + ctx.legacy_stone_table[i][SALT] * counts.distance
                + ctx.legacy_stone_table[i][BITTER] * counts.connection
                + ctx.legacy_stone_table[i][RED] * counts.direction
                + prev1
                + 3 * prev3
                + 5 * prev7
                + i
            )

            x = applyLegacyVisibleGrinds(
                ctx,
                i,
                x,
                prev1,
                prev3,
                prev7,
                ctx.legacy_stone_table,
            )

            drop_store[i] = x
            visible[i] = x
            i += 1

        result = tuple(visible)
        ctx.legacy_visible_drop_table = result
        ctx.legacy_visible_drop_count = 46

        return result
