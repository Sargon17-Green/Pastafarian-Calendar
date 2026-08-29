from .legacy_arithmetic import savePatch


WHEAT = 0
BARLEY = 1
SALT = 2
BITTER = 3
RED = 4

BOWL_STIR_STONE_BY_POSITION = (
    WHEAT,
    BARLEY,
    SALT,
    BITTER,
    RED,
    WHEAT,
)


def legacyInPlaceBowlUpdateWrong(
    i: int,
    drop: int,
    order: tuple[int, ...],
    pours: tuple[int, ...],
    stones: tuple[tuple[int, ...], ...],
    bowls: tuple[int, ...],
) -> tuple[int, ...]:
    if len(order) != 6:
        raise ValueError("Kâse sırası tam olarak altı konum içermelidir")

    working = list(bowls)

    position = 1
    while position <= 6:
        bowl_id = order[position - 1]
        prev_id = order[(position - 2) % 6]
        next_id = order[position % 6]
        kind = BOWL_STIR_STONE_BY_POSITION[position - 1]

        # Tarihsel kusur: bütün okumalar aynı anda güncellenen working listesinden yapılır.
        s = (
            working[bowl_id]
            + 2 * working[prev_id]
            + 3 * working[next_id]
            + pours[position]
            + drop
            + stones[i][kind]
        )

        working[bowl_id] = savePatch(
            s * s
            + 5 * working[prev_id] * working[next_id]
            + i * position
        )

        position += 1

    return tuple(working)


def snapshotBowlUpdatePatched(
    i: int,
    drop: int,
    order: tuple[int, ...],
    pours: tuple[int, ...],
    stones: tuple[tuple[int, ...], ...],
    bowls: tuple[int, ...],
) -> tuple[int, ...]:
    if len(order) != 6:
        raise ValueError("Kâse sırası tam olarak altı konum içermelidir")

    vaultOld = tuple(list(bowls))
    pending = [0] * 7

    position = 1
    while position <= 6:
        bowl_id = order[position - 1]
        prev_id = order[(position - 2) % 6]
        next_id = order[position % 6]
        kind = BOWL_STIR_STONE_BY_POSITION[position - 1]

        s = (
            vaultOld[bowl_id]
            + 2 * vaultOld[prev_id]
            + 3 * vaultOld[next_id]
            + pours[position]
            + drop
            + stones[i][kind]
        )

        pending[bowl_id] = savePatch(
            s * s
            + 5 * vaultOld[prev_id] * vaultOld[next_id]
            + i * position
        )
        position += 1

    return tuple(pending)


class BowlMutationPatchWrapper:
    def repair(
        self,
        ctx,
        i: int,
        drop: int,
        order: tuple[int, ...],
        pours: tuple[int, ...],
        stones: tuple[tuple[int, ...], ...],
        bowls: tuple[int, ...],
    ) -> tuple[int, ...]:
        ctx.branch_trace.append(("YAMA_10_KÂSE_SNAPSHOT", i, order))
        ctx.logs.append(("yama-10-kâse-snapshot", i, order))

        # Discovery 10 in-place scar'ı kaldırılmaz; gerçekten çalıştırılır.
        legacy_wrong = legacyInPlaceBowlUpdateWrong(
            i,
            drop,
            order,
            pours,
            stones,
            bowls,
        )

        vaultOld = tuple(list(bowls))
        corrected = snapshotBowlUpdatePatched(
            i,
            drop,
            order,
            pours,
            stones,
            bowls,
        )
        pending = corrected

        ctx.patch10_drop_index = i
        ctx.patch10_vaultOld = vaultOld
        ctx.patch10_pending = pending
        ctx.patch10_legacy_wrong_result = legacy_wrong
        ctx.patch10_corrected_result = corrected
        ctx.patch10_commit_after_six = True
        ctx.patch10_applied = True

        return corrected


class LegacyBowlUpdateAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = BowlMutationPatchWrapper()

    def call(
        self,
        ctx,
        i: int,
        bowls: tuple[int, ...],
        pours: tuple[int, ...],
    ) -> tuple[int, ...]:
        if ctx.legacy_stone_table is None:
            raise RuntimeError("Taş tablosu kâse güncellemesinden önce hazır olmalıdır")
        if ctx.legacy_visible_drop_table is None:
            raise RuntimeError("Görünür damlalar kâse güncellemesinden önce hazır olmalıdır")
        if ctx.legacy_permutation_order_table is None:
            raise RuntimeError("Permütasyon sıraları kâse güncellemesinden önce hazır olmalıdır")

        drop = ctx.legacy_visible_drop_table[i]
        order = ctx.legacy_permutation_order_table[i]

        ctx.branch_trace.append(("ESKİ_YERİNDE_KÂSE_GÜNCELLEME", i, order))
        ctx.logs.append(("eski-yerinde-kâse-güncelleme", i, order))

        result = self.patch_wrapper.repair(
            ctx,
            i,
            drop,
            order,
            pours,
            ctx.legacy_stone_table,
            bowls,
        )

        ctx.legacy_bowl_update_last_drop_index = i
        ctx.legacy_bowl_update_last_input = bowls
        ctx.legacy_bowl_update_last_pours = pours
        ctx.legacy_bowl_update_last_result = result
        return result
