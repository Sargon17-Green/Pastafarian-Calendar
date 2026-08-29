M_OLD = 2**127 - 1


def regularMod(x: int, divisor: int) -> int:
    if divisor < 1:
        raise ValueError("Bölen en az bir olmalıdır")
    return x % divisor


def oldRemainder(x: int) -> int:
    return regularMod(x, M_OLD)


def savePatch(x: int) -> int:
    # Tarihsel kusur burada düzeltilmez; eski kalan gerçek biçimiyle çağrılır.
    r = oldRemainder(x)
    if r == 0:
        r = M_OLD
    return r


class SavePatchWrapper:
    def repair(self, ctx, value: int) -> int:
        ctx.branch_trace.append(("YAMA_01_KAYDET", value))
        ctx.logs.append(("yama-01-kaydet", value))
        ctx.patch01_input = value
        result = savePatch(value)
        ctx.patch01_value = result
        ctx.patch01_applied = True
        return result


class LegacyRemainderAdapter:
    def __init__(self) -> None:
        self.patch_wrapper = SavePatchWrapper()

    def call(self, ctx, value: int) -> int:
        ctx.branch_trace.append(("ESKİ_KALAN", value))
        ctx.logs.append(("eski-kalan-çağrısı", value))
        return self.patch_wrapper.repair(ctx, value)
