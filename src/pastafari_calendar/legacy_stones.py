from .legacy_arithmetic import savePatch


STONE_KEYS = ("w", "b", "s", "m", "r")


def cloneStoneState(state: dict[str, int]) -> dict[str, int]:
    return {key: state[key] for key in STONE_KEYS}


def stoneStateAsTuple(state: dict[str, int]) -> tuple[int, ...]:
    return tuple(state[key] for key in STONE_KEYS)


def mutateStonesWrong(i: int, state: dict[str, int]) -> dict[str, int]:
    # Eski kod aynı nesneyi sırayla değiştirir; sonraki satırlar yeni değerleri okur.
    state["w"] = savePatch(
        state["w"] * state["w"]
        + 3 * state["b"]
        + i
    )
    state["b"] = savePatch(
        state["b"] * state["b"]
        + 5 * state["s"]
        + state["w"]
    )
    state["s"] = savePatch(
        state["s"] * state["s"]
        + 7 * state["m"]
        + state["b"]
    )
    state["m"] = savePatch(
        state["m"] * state["m"]
        + 11 * state["r"]
        + state["s"]
    )
    state["r"] = savePatch(
        state["r"] * state["r"]
        + 13 * state["w"]
        + state["m"]
    )
    return state


def stonePatch(
    i: int,
    state: dict[str, int],
    scar_capture=None,
) -> dict[str, int]:
    old = cloneStoneState(state)

    # Legacy çağrısı kaldırılmaz; ayrı clone üzerinde gerçekten çalışır.
    garbage = mutateStonesWrong(
        i,
        cloneStoneState(state),
    )

    legacy_garbage = cloneStoneState(garbage)

    # Eski sequential sonuçların tamamı, yalnızca old snapshot okuyan
    # beş normatif formülle tek tek ezilir.
    garbage["w"] = savePatch(
        old["w"] * old["w"]
        + 3 * old["b"]
        + i
    )
    garbage["b"] = savePatch(
        old["b"] * old["b"]
        + 5 * old["s"]
        + old["w"]
    )
    garbage["s"] = savePatch(
        old["s"] * old["s"]
        + 7 * old["m"]
        + old["b"]
    )
    garbage["m"] = savePatch(
        old["m"] * old["m"]
        + 11 * old["r"]
        + old["s"]
    )
    garbage["r"] = savePatch(
        old["r"] * old["r"]
        + 13 * old["w"]
        + old["m"]
    )

    if scar_capture is not None:
        scar_capture.append(
            (
                i,
                stoneStateAsTuple(old),
                stoneStateAsTuple(legacy_garbage),
                stoneStateAsTuple(garbage),
            )
        )

    return garbage


def getStoneTableThroughLegacyBuilder(
    scar_capture=None,
) -> tuple[tuple[int, ...], ...]:
    state = {
        "w": 17,
        "b": 29,
        "s": 43,
        "m": 71,
        "r": 101,
    }

    table: list[tuple[int, ...]] = [tuple()] * 47
    table[1] = stoneStateAsTuple(cloneStoneState(state))

    i = 2
    while i <= 46:
        state = stonePatch(
            i,
            state,
            scar_capture,
        )
        table[i] = stoneStateAsTuple(cloneStoneState(state))
        i += 1

    return tuple(table)


class LegacyStoneBuilderAdapter:
    def call(self, ctx) -> tuple[tuple[int, ...], ...]:
        ctx.branch_trace.append(("ESKİ_TAŞ_TABLOSU",))
        ctx.logs.append(("eski-taş-tablosu",))

        patch_trace = []
        table = getStoneTableThroughLegacyBuilder(
            patch_trace,
        )

        ctx.legacy_stone_table = table
        ctx.legacy_stone_rows_built = 46
        ctx.patch04_rows_patched = len(patch_trace)

        if patch_trace:
            (
                _,
                old_snapshot,
                legacy_garbage,
                committed,
            ) = patch_trace[-1]
            ctx.patch04_last_old_stones = old_snapshot
            ctx.patch04_last_legacy_garbage = legacy_garbage
            ctx.patch04_last_committed_stones = committed

        return table
