FOUNDATION_DAY_OLD = -15055671


def oldDayTag(day: int) -> int:
    return 2 * abs(day - FOUNDATION_DAY_OLD)


class LegacyDayTagAdapter:
    def call(self, ctx, day: int, role: str) -> int:
        if role not in ("action", "target"):
            raise ValueError("Eski gün etiketi rolü action veya target olmalıdır")

        ctx.branch_trace.append(("ESKİ_GÜN_ETİKETİ", role, day))
        ctx.logs.append(("eski-gün-etiketi", role, day))

        value = oldDayTag(day)

        if role == "action":
            ctx.legacy_action_day_tag_input = day
            ctx.legacy_action_day_tag_value = value
        else:
            ctx.legacy_target_day_tag_input = day
            ctx.legacy_target_day_tag_value = value

        return value
