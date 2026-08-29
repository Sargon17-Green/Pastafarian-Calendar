FOUNDATION_DAY_OLD = -15055671


def oldDayTag(day: int) -> int:
    return 2 * abs(day - FOUNDATION_DAY_OLD)


def dayTagWithFoundationScar(day: int, legacy_capture=None) -> int:
    # Tarihsel oldDayTag düzeltilmez; yama onun sonucunun üstüne uygulanır.
    n = oldDayTag(day)

    if legacy_capture is not None:
        legacy_capture.append(n)

    if day >= FOUNDATION_DAY_OLD:
        n += 1

    # Bu ikinci koruma, eski kuruluş-günü düzeltmesinin fiziksel yarasıdır.
    # Normal oldDayTag ile ilk dal zaten 1 üretir; yine de kaldırılmaz.
    if day == FOUNDATION_DAY_OLD and n != 1:
        n = 1

    return n


class DayTagPatchWrapper:
    def repair(self, ctx, day: int, role: str) -> int:
        ctx.branch_trace.append(("YAMA_02_GÜN_ETİKETİ", role, day))
        ctx.logs.append(("yama-02-gün-etiketi", role, day))

        legacy_capture = []
        result = dayTagWithFoundationScar(day, legacy_capture)

        if len(legacy_capture) != 1:
            raise RuntimeError("Eski gün etiketi yakalama sayısı bir olmalıdır")

        legacy_value = legacy_capture[0]

        if role == "action":
            ctx.legacy_action_day_tag_input = day
            ctx.legacy_action_day_tag_value = legacy_value
            ctx.patch02_action_day_tag_input = day
            ctx.patch02_action_day_tag_value = result
            ctx.patch02_action_applied = True
        else:
            ctx.legacy_target_day_tag_input = day
            ctx.legacy_target_day_tag_value = legacy_value
            ctx.patch02_target_day_tag_input = day
            ctx.patch02_target_day_tag_value = result
            ctx.patch02_target_applied = True

        if day == FOUNDATION_DAY_OLD:
            ctx.patch02_foundation_guard_seen = True

        return result


class LegacyDayTagAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = DayTagPatchWrapper()

    def call(self, ctx, day: int, role: str) -> int:
        if role not in ("action", "target"):
            raise ValueError("Eski gün etiketi rolü action veya target olmalıdır")

        ctx.branch_trace.append(("ESKİ_GÜN_ETİKETİ", role, day))
        ctx.logs.append(("eski-gün-etiketi", role, day))

        return self.patch_wrapper.repair(ctx, day, role)
