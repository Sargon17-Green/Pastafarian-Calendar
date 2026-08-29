from math import factorial

from .legacy_arithmetic import regularMod


BOWL_IDS = (1, 2, 3, 4, 5, 6)


def oldPermutationUnrank0(
    rank0: int,
    items_ascending=BOWL_IDS,
) -> tuple[int, ...]:
    remaining = list(items_ascending)
    total = factorial(len(remaining))

    if rank0 < 0 or rank0 >= total:
        raise ValueError("Eski sıfır tabanlı permütasyon derecesi aralık dışında")

    result: list[int] = []

    while remaining:
        block = factorial(len(remaining) - 1)
        q, rank0 = divmod(
            rank0,
            block,
        )
        result.append(
            remaining.pop(q)
        )

    return tuple(result)


def legacyOrderFromDropWrong(
    drop_value: int,
) -> tuple[int, ...]:
    one_based = regularMod(
        drop_value - 1,
        720,
    ) + 1

    # Tarihsel kusur: 1-based sıra numarası rank0 sanılarak doğrudan verilir.
    return oldPermutationUnrank0(
        one_based,
    )


def patchedOrderFromDrop(
    drop_value: int,
) -> tuple[int, ...]:
    one_based = regularMod(
        drop_value - 1,
        720,
    ) + 1
    legacy_rank0 = one_based - 1
    return oldPermutationUnrank0(
        legacy_rank0,
    )


class PermutationRankPatchWrapper:
    def repair(
        self,
        ctx,
        drop_index: int,
        drop_value: int,
    ) -> tuple[int, ...]:
        one_based = regularMod(
            drop_value - 1,
            720,
        ) + 1
        legacy_rank0 = one_based - 1

        ctx.branch_trace.append(
            (
                "YAMA_08_PERMÜTASYON_RANKI",
                drop_index,
                one_based,
                legacy_rank0,
            )
        )
        ctx.logs.append(
            (
                "yama-08-permütasyon-rankı",
                drop_index,
                one_based,
                legacy_rank0,
            )
        )

        legacy_wrong = None
        legacy_wrong_error = None

        # Discovery 08 caller scar'ı kaldırılmaz; gerçekten çalıştırılır.
        try:
            legacy_wrong = legacyOrderFromDropWrong(
                drop_value,
            )
        except ValueError as error:
            legacy_wrong_error = str(error)

        corrected = patchedOrderFromDrop(
            drop_value,
        )

        ctx.patch08_drop_index = drop_index
        ctx.patch08_one_based = one_based
        ctx.patch08_legacy_rank0 = legacy_rank0
        ctx.patch08_legacy_wrong_order = legacy_wrong
        ctx.patch08_legacy_wrong_error = legacy_wrong_error
        ctx.patch08_corrected_order = corrected
        ctx.patch08_applied = True

        return corrected


class LegacyPermutationOrderAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = PermutationRankPatchWrapper()

    def order_from_drop(
        self,
        ctx,
        drop_index: int,
        drop_value: int,
    ) -> tuple[int, ...]:
        if drop_index < 1 or drop_index > 46:
            raise ValueError("Görünür damla indeksi 1 ile 46 arasında olmalıdır")

        one_based = regularMod(
            drop_value - 1,
            720,
        ) + 1

        ctx.branch_trace.append(
            (
                "ESKİ_PERMÜTASYON_SIRASI",
                drop_index,
                one_based,
            )
        )
        ctx.logs.append(
            (
                "eski-permütasyon-sırası",
                drop_index,
                one_based,
            )
        )

        ctx.legacy_permutation_last_drop_index = drop_index
        ctx.legacy_permutation_last_drop_value = drop_value
        ctx.legacy_permutation_last_one_based = one_based
        ctx.legacy_permutation_last_order = None

        order = self.patch_wrapper.repair(
            ctx,
            drop_index,
            drop_value,
        )

        ctx.legacy_permutation_last_order = order
        return order

    def build_order_table(
        self,
        ctx,
        visible_drops: tuple[int, ...],
    ) -> tuple[tuple[int, ...], ...]:
        orders: list[tuple[int, ...]] = [tuple()] * 47

        i = 1
        while i <= 46:
            orders[i] = self.order_from_drop(
                ctx,
                i,
                visible_drops[i],
            )
            i += 1

        result = tuple(orders)
        ctx.legacy_permutation_order_table = result
        ctx.legacy_permutation_order_count = 46
        return result
