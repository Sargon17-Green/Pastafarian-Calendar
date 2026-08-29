def legacyPrior(
    drop_store: dict[int, int],
    i: int,
    back: int,
) -> int:
    if back < 1:
        raise ValueError("Geçmiş uzaklığı en az bir olmalıdır")

    # Tarihsel kusur: yalnızca i-back >= 1 olduğunda çalışan görünür depo erişimi.
    return drop_store[i - back]


class LegacyPriorAdapter:
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

        value = legacyPrior(
            drop_store,
            i,
            back,
        )

        ctx.legacy_prior_value = value
        return value
