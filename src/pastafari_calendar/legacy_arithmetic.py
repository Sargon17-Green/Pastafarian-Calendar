M_OLD = 2**127 - 1


def regularMod(x: int, divisor: int) -> int:
    if divisor < 1:
        raise ValueError("Bölen en az bir olmalıdır")
    return x % divisor


def oldRemainder(x: int) -> int:
    return regularMod(x, M_OLD)


class LegacyRemainderAdapter:
    def call(self, ctx, value: int) -> int:
        ctx.branch_trace.append(("ESKİ_KALAN", value))
        ctx.logs.append(("eski-kalan-çağrısı", value))
        return oldRemainder(value)
