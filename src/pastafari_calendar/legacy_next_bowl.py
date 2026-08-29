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


class LegacyNextBowlAdapter:
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

        result = oldNextBowlFixedName(
            queried_id,
        )

        ctx.legacy_next_bowl_queried_id = queried_id
        ctx.legacy_next_bowl_fixed_result = result

        return result
