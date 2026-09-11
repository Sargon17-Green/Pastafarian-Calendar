"""HISTORICAL — SUPERSEDED.

Bu modül, 2026-09-11 öncesinde yanlışlıkla kanonik kabul edilen raw-sum
post-stir varyantını yalnız regresyon-mutantı olarak saklar. Üretim yolu bu modülü
import etmez. Kanonik kural, ``R = SAVE(sum(oldBowls) + 149*r)`` değerini hem
permütasyon hem de ``u`` içindeki ek terim olarak kullanır.
"""

from .legacy_arithmetic import savePatch
from .legacy_permutation import patchedOrderFromDrop


def rawSumMutantPostStir(
    stir: int,
    bowls: tuple[int, ...],
) -> tuple[tuple[int, ...], tuple[int, ...], int, int]:
    """Yalnız test için kasıtlı olarak yanlış raw-sum mutantını çalıştırır."""
    if stir < 1 or stir > 12:
        raise ValueError("Mutant karıştırma numarası 1 ile 12 arasında olmalıdır")
    if len(bowls) != 7:
        raise ValueError("Mutant kâse kasası 1 tabanlı altı kâse taşımalıdır")

    old = tuple(bowls)
    raw_bowl_sum = sum(old[1:7])
    order_number = savePatch(raw_bowl_sum + 149 * stir)
    order = patchedOrderFromDrop(order_number)
    pending = [0] * 7

    for position in range(1, 7):
        bowl_id = order[position - 1]
        prev_id = order[(position - 2) % 6]
        next_id = order[position % 6]
        u = (
            old[bowl_id]
            + 3 * old[prev_id]
            + 5 * old[next_id]
            + raw_bowl_sum  # INTENTIONAL MUTANT: canonical term is order_number/R.
            + stir
            + position * position
        )
        pending[bowl_id] = savePatch(
            u * u
            + 7 * old[prev_id] * old[next_id]
        )

    return tuple(pending), order, raw_bowl_sum, order_number


# Tarihsel ad, eski raporları okuyabilmek için yalnız test-mutantı alias'ı olarak
# tutulur. Üretim kodunun bunu çağırması yasaktır.
rawBowlSumPostStirDetour = rawSumMutantPostStir
