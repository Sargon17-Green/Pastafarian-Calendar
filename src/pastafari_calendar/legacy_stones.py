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


def getStoneTableThroughLegacyBuilder() -> tuple[tuple[int, ...], ...]:
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
        state = mutateStonesWrong(i, state)
        table[i] = stoneStateAsTuple(cloneStoneState(state))
        i += 1

    return tuple(table)


class LegacyStoneBuilderAdapter:
    def call(self, ctx) -> tuple[tuple[int, ...], ...]:
        ctx.branch_trace.append(("ESKİ_TAŞ_TABLOSU",))
        ctx.logs.append(("eski-taş-tablosu",))

        table = getStoneTableThroughLegacyBuilder()

        ctx.legacy_stone_table = table
        ctx.legacy_stone_rows_built = 46

        return table
