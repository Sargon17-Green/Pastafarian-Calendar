def oldNextBowlFixedName(
    queried_id: int,
) -> int:
    if queried_id < 1 or queried_id > 6:
        raise ValueError("Sorgulanan kâse ID değeri 1 ile 6 arasında olmalıdır")

    # Tarihsel kusur: "sonraki kâse" current order position yerine
    # fiziksel/isimsel sabit ID halkası sanılır.
    if queried_id == 6:
        return 1

    return queried_id + 1


def latchedCircularSuccessor(
    order_at_46_latch: tuple[int, ...],
    queried_id: int,
) -> int:
    if len(order_at_46_latch) != 6:
        raise ValueError("Drop 46 order latch tam olarak altı kâse ID içermelidir")

    position = 0
    found = False

    while position < 6:
        if order_at_46_latch[position] == queried_id:
            found = True
            break
        position += 1

    if not found:
        raise ValueError("Sorgulanan kâse ID drop 46 order latch içinde bulunamadı")

    return order_at_46_latch[
        (position + 1) % 6
    ]


class NextBowlPatchWrapper:
    def repair(
        self,
        ctx,
        queried_id: int,
    ) -> int:
        if ctx.orderAt46Latch is None:
            raise RuntimeError("Drop 46 order latch sonraki kâse sorgusundan önce hazır olmalıdır")

        ctx.branch_trace.append(
            (
                "YAMA_12_LATCH_SONRAKİ_KÂSE",
                queried_id,
            )
        )
        ctx.logs.append(
            (
                "yama-12-latch-sonraki-kâse",
                queried_id,
            )
        )

        # Discovery 12 fixed-ID helper scar'ı korunur ve diagnostic olarak gerçekten çağrılır.
        legacy_diagnostic = oldNextBowlFixedName(
            queried_id,
        )

        corrected = latchedCircularSuccessor(
            ctx.orderAt46Latch,
            queried_id,
        )

        ctx.patch12_queried_id = queried_id
        ctx.patch12_legacy_diagnostic = legacy_diagnostic
        ctx.patch12_corrected_result = corrected
        ctx.patch12_applied = True

        return corrected


class LegacyNextBowlAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = NextBowlPatchWrapper()

    def call(
        self,
        ctx,
        queried_id: int,
    ) -> int:
        if ctx.orderAt46Latch is None:
            raise RuntimeError("Drop 46 order latch sonraki kâse sorgusundan önce hazır olmalıdır")

        ctx.branch_trace.append(
            (
                "ESKİ_SABİT_ID_SONRAKİ_KÂSE",
                queried_id,
            )
        )
        ctx.logs.append(
            (
                "eski-sabit-id-sonraki-kâse",
                queried_id,
            )
        )

        result = self.patch_wrapper.repair(
            ctx,
            queried_id,
        )

        ctx.legacy_next_bowl_queried_id = queried_id
        ctx.legacy_next_bowl_fixed_result = (
            ctx.patch12_legacy_diagnostic
        )

        return result
