local BigInt = require("bigint")
local Base = require("monster_base")
local DayTagPatch = require("day_tag_patch")
local DistancePatch = require("distance_patch")
local SavePatch = require("save_patch")
local StonePatch = require("stone_patch")
local LegacyStones = require("legacy_stones")
local LegacyHidden = {}

local COEFFICIENTS = {
    {3,4,6,8}, {5,7,10,12}, {7,10,14,16}, {9,13,18,20},
    {11,16,22,24}, {13,19,26,28}, {15,22,30,32}
}
local GRIND_STONE = {"w", "b", "s", "m", "r", "w", "b"}
local STONE_NAMES = {"w", "b", "s", "m", "r"}

local function copySeven(list)
    local result = {}
    for k=1,7 do result[k] = BigInt.from(list[k]) end
    return result
end

local function validateDay(day)
    assert(type(day) == "number" and math.type(day) == "integer",
           "Jou yo dwe antye nan Lua")
end

-- Yon mwa apa: pa enpòte oracle normatif la nan chemen production.
-- Kontè yo soti nan twa kouch PATCH ki egziste deja.
local function getCounts(c, t)
    validateDay(c)
    validateDay(t)
    local action = DayTagPatch.execute(c)
    local target = DayTagPatch.execute(t)
    local distance = DistancePatch.execute(c, t)
    local direction = t < c and 1 or (t > c and 3 or 2)
    return {
        action = action,
        target = target,
        distance = distance,
        connection = BigInt.add(action, target),
        direction = BigInt.from(direction)
    }
end

-- Se sèlman sèt premye ranje tab wòch korije a nou bezwen nan etap sa a.
-- Chak ranje pase reyèlman nan dispatcher STONE_PATCH la.
local function firstSevenStones()
    local rows = {}
    local current = LegacyStones.seed()
    rows[1] = LegacyStones.copy(current)
    for k=2,7 do
        current = StonePatch.execute(k, current)
        rows[k] = LegacyStones.copy(current)
    end
    return rows
end

local function computeDrop(k, counts, stone)
    local coeff = COEFFICIENTS[k]
    local x = BigInt.add(counts.action, BigInt.mulSmall(counts.target, coeff[1]))
    x = BigInt.add(x, BigInt.mulSmall(counts.distance, coeff[2]))
    x = BigInt.add(x, BigInt.mulSmall(counts.connection, coeff[3]))
    x = BigInt.add(x, BigInt.mulSmall(counts.direction, coeff[4]))
    for _, name in ipairs(STONE_NAMES) do x = BigInt.add(x, stone[name]) end
    x = SavePatch.savePatch(x)
    for grind = 1,7 do
        local oldX = x
        x = SavePatch.savePatch(BigInt.add(
            BigInt.add(BigInt.mul(oldX, oldX), BigInt.mulSmall(oldX, 3)),
            BigInt.add(stone[GRIND_STONE[grind]], grind)))
    end
    return x
end

-- DISCOVERY 05: sa yo se sèt valè kòrèk yo nan move plas fizik yo.
-- Nou pa ranje aksè yo: yon moun ki li storage[k] jwenn hidden(8-k).
function LegacyHidden.buildReversedStorage(c, t)
    local counts = getCounts(c, t)
    local stones = firstSevenStones()
    local storage = {}
    for k=1,7 do
        local value = computeDrop(k, counts, stones[k])
        storage[8-k] = value
    end
    return copySeven(storage)
end

function LegacyHidden.oldHiddenAt(storage, k)
    assert(type(k) == "number" and math.type(k) == "integer" and k >= 1 and k <= 7,
           "Endis gout kache a dwe ant 1 ak 7")
    assert(type(storage) == "table", "Depo gout kache a dwe yon tablo")
    -- Erè istorik: aksè a pa konvèti index la selon direksyon depo a.
    return BigInt.from(storage[k])
end

function LegacyHidden.execute(c, t)
    validateDay(c)
    validateDay(t)
    local storage = LegacyHidden.buildReversedStorage(c, t)
    local ctx = Base.MonsterContext.new(c, t)
    ctx.phase = "LEGACY_HIDDEN"
    ctx.mode = "STAGE_10_DISCOVERY_05"
    ctx.status = "LEGACY_HIDDEN_PENDING"
    local manager = Base.MonsterManager.new(ctx)
    manager.dispatcher:register("LEGACY_HIDDEN", function(active, owner)
        local candidate = {
            calculationDayDecimal = tostring(c),
            targetDayDecimal = tostring(t),
            source = "HIDDEN_DROPS_REVERSED_PHYSICAL_STORAGE",
            storageOrder = "HIDDEN_7_TO_HIDDEN_1"
        }
        for k=1,7 do candidate["physical"..k] = tostring(storage[k]) end
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.hidden.calls")
        for k=1,7 do owner.metricsManager:bump("legacy.hidden.physicalSlots") end
        owner.metricsManager:observe("legacy.hidden.firstSlot", active.semanticState.physical1)
        active.diagnostics[#active.diagnostics+1] = {
            code = "BACKWARDS_HIDDEN_STORAGE_WITH_UNMAPPED_ACCESS",
            phase = active.phase,
            firstPhysicalSlot = active.semanticState.physical1
        }
        active.status = "LEGACY_HIDDEN_RETURNED"
        return copySeven(storage)
    end)
    local result = manager.dispatcher:dispatch(ctx, "LEGACY_HIDDEN", manager)
    return result, ctx
end

return LegacyHidden
