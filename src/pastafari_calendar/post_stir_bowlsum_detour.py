from .legacy_arithmetic import savePatch
from .legacy_permutation import patchedOrderFromDrop


def rawBowlSumPostStirDetour(
    stir: int,
    bowls: tuple[int, ...],
    legacy_wrong_result: tuple[int, ...],
    legacy_order: tuple[int, ...],
    legacy_saved_stir_sum: int,
) -> tuple[tuple[int, ...], tuple[int, ...], int, int]:
    if stir < 1 or stir > 12:
        raise ValueError("Düzeltici karıştırma numarası 1 ile 12 arasında olmalıdır")
    if len(bowls) != 7:
        raise ValueError("Düzeltici kâse kasası 1 tabanlı altı kâse taşımalıdır")
    if len(legacy_order) != 6:
        raise ValueError("Düzeltici karıştırma sırası altı kâse içermelidir")
    if len(legacy_wrong_result) != 7:
        raise ValueError("Eski yanlış karıştırma sonucu 1 tabanlı altı kâse taşımalıdır")

    old = tuple(list(bowls))

    # Düzeltici Aşama 56 spaghetti detour:
    # Eski A1 yolu fiziksel olarak çağrılmıştır ve sonucu ghost olarak buraya gelir.
    # Sıra numarası SAVEdır; fakat u içine giren değer SAVEd sıra numarası değil,
    # karıştırmanın başında altı eski kâsenin ham toplamıdır.
    raw_bowl_sum = sum(old[1:7])
    order_number = savePatch(
        raw_bowl_sum
        + 149 * stir
    )
    corrected_order = patchedOrderFromDrop(
        order_number,
    )

    if order_number != legacy_saved_stir_sum:
        raise RuntimeError("Eski sıra numarası ile düzeltici sıra numarası ayrıştı")
    if corrected_order != legacy_order:
        raise RuntimeError("Eski permütasyon ile düzeltici permütasyon ayrıştı")

    pending = [0] * 7
    position = 1
    while position <= 6:
        bowl_id = corrected_order[position - 1]
        prev_id = corrected_order[(position - 2) % 6]
        next_id = corrected_order[position % 6]

        u = (
            old[bowl_id]
            + 3 * old[prev_id]
            + 5 * old[next_id]
            + raw_bowl_sum
            + stir
            + position * position
        )

        pending[bowl_id] = savePatch(
            u * u
            + 7 * old[prev_id] * old[next_id]
        )
        position += 1

    return (
        tuple(pending),
        corrected_order,
        raw_bowl_sum,
        order_number,
    )
