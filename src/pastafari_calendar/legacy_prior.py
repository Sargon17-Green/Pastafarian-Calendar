from .legacy_hidden import hiddenByNearness


def legacyPrior(
    drop_store: dict[int, int],
    i: int,
    back: int,
) -> int:
    if back < 1:
        raise ValueError("Geçmiş uzaklığı en az bir olmalıdır")

    # Tarihsel kusur: yalnızca i-back >= 1 olduğunda çalışan görünür depo erişimi.
    return drop_store[i - back]


def priorPatch(
    drop_store: dict[int, int],
    legacy_hidden: tuple[int, ...] | None,
    i: int,
    back: int,
) -> int:
    if back < 1:
        raise ValueError("Geçmiş uzaklığı en az bir olmalıdır")

    slot = i - back

    if slot >= 1:
        return legacyPrior(
            drop_store,
            i,
            back,
        )

    if legacy_hidden is None:
        raise RuntimeError("Gizli damla deposu nonpositive geçmiş erişiminden önce hazır olmalıdır")

    hidden_k = 1 - slot
    return hiddenByNearness(
        legacy_hidden,
        hidden_k,
    )


class PriorPatchWrapper:
    def repair(
        self,
        ctx,
        drop_store: dict[int, int],
        legacy_hidden: tuple[int, ...] | None,
        i: int,
        back: int,
    ) -> int:
        slot = i - back

        ctx.branch_trace.append(
            ("YAMA_06_GEÇMİŞ", i, back, slot)
        )
        ctx.logs.append(
            ("yama-06-geçmiş", i, back, slot)
        )

        result = priorPatch(
            drop_store,
            legacy_hidden,
            i,
            back,
        )

        ctx.patch06_slot = slot
        ctx.patch06_used_hidden = slot <= 0
        ctx.patch06_hidden_k = (
            1 - slot
            if slot <= 0
            else None
        )
        ctx.patch06_value = result
        ctx.patch06_applied = True

        return result


class LegacyPriorAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = PriorPatchWrapper()

    def call(
        self,
        ctx,
        drop_store: dict[int, int],
        i: int,
        back: int,
    ) -> int:
        if i < 1:
            raise ValueError("Görünür damla indeksi en az bir olmalıdır")
        if back < 1:
            raise ValueError("Geçmiş uzaklığı en az bir olmalıdır")

        slot = i - back

        ctx.branch_trace.append(
            ("ESKİ_GEÇMİŞ_OKUMA", i, back, slot)
        )
        ctx.logs.append(
            ("eski-geçmiş-okuma", i, back, slot)
        )

        ctx.legacy_prior_i = i
        ctx.legacy_prior_back = back
        ctx.legacy_prior_slot = slot
        ctx.legacy_prior_value = None

        value = self.patch_wrapper.repair(
            ctx,
            drop_store,
            ctx.legacy_hidden_storage,
            i,
            back,
        )

        ctx.legacy_prior_value = value
        return value
