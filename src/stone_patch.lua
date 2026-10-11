local BigInt = require("bigint")
local Base = require("monster_base")
local SavePatch = require("save_patch")
local LegacyStones = require("legacy_stones")
local StonePatch = {}

local names = {"w", "b", "s", "m", "r"}
local function overwritten(i, old, garbage)
    -- Kouch sa a pa modifye mutateStonesWrong. Tout senk fòmil li 
    -- ekri sou menm garbage a, men yo LI sèlman valè snapshot old yo.
    garbage.w = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(old.w, old.w),
                                     BigInt.mulSmall(old.b, 3)), i))
    garbage.b = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(old.b, old.b),
                                     BigInt.mulSmall(old.s, 5)), old.w))
    garbage.s = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(old.s, old.s),
                                     BigInt.mulSmall(old.m, 7)), old.b))
    garbage.m = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(old.m, old.m),
                                     BigInt.mulSmall(old.r, 11)), old.s))
    garbage.r = SavePatch.savePatch(BigInt.add(BigInt.add(BigInt.mul(old.r, old.r),
                                     BigInt.mulSmall(old.w, 13)), old.m))
    return garbage
end

-- Kontra PATCH 04 a mande yon apèl reyèl pou legacy sou yon kopi.
function StonePatch.stonePatch(i, stones)
    local old = LegacyStones.copy(stones)
    local garbage = LegacyStones.mutateStonesWrong(i, LegacyStones.copy(old))
    return overwritten(i, old, garbage)
end

function StonePatch.execute(i, stones)
    local old = LegacyStones.copy(stones)
    -- LegacyStones.execute rele mutateStonesWrong toutbon sou kopi li posede a.
    local garbage, context = LegacyStones.execute(i, LegacyStones.copy(old))
    local legacyBeforeOverwrite = LegacyStones.copy(garbage)
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_STONES"
    context.mode = "STAGE_09_PATCH_04"
    context.status = "PATCH_STONES_PENDING"

    manager.dispatcher:register("STONE_PATCH", function(active, owner)
        local fixed = overwritten(i, old, garbage)
        local state = {
            index = i,
            source = "SNAPSHOT_REPLACES_SEQUENTIAL_GARBAGE",
            legacyCallPreserved = true
        }
        for _, name in ipairs(names) do
            state["old" .. string.upper(name)] = tostring(old[name])
            state["garbage" .. string.upper(name)] = tostring(legacyBeforeOverwrite[name])
            state[name] = tostring(fixed[name])
        end
        active:beginSemanticUpdate(state)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("stone.patch.calls")
        owner.metricsManager:bump("stone.patch.legacyCallsPreserved")
        owner.metricsManager:observe("stone.patch.lastBarley", state.b)
        active.diagnostics[#active.diagnostics + 1] = {
            code = "PATCH_04_REPLACE_ALL_STONES_FROM_OLD",
            phase = active.phase,
            legacyBarley = state.garbageB,
            correctedBarley = state.b
        }
        active.status = "PATCH_STONES_RETURNED"
        return LegacyStones.copy(fixed)
    end)

    local result = manager.dispatcher:dispatch(context, "STONE_PATCH", manager)
    return result, context
end

function StonePatch.buildPatchedTable()
    local rows = {}
    local current = LegacyStones.seed()
    rows[1] = LegacyStones.copy(current)
    for i = 2, 46 do
        current = StonePatch.execute(i, current)
        rows[i] = LegacyStones.copy(current)
    end
    return rows
end

return StonePatch
