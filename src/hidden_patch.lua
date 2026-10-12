local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyHidden = require("legacy_hidden")
local HiddenPatch = {}

local function requireHiddenIndex(k)
    assert(type(k) == "number" and math.type(k) == "integer" and k >= 1 and k <= 7,
           "Endis gout kache a dwe yon antye ant 1 ak 7")
end

-- PATCH 05: depo fizik la RETE nan sans hidden7 ... hidden1.
-- Se lekti lojik la sèlman ki chanje. Pa ranvèse ni reekri depo a.
function HiddenPatch.hiddenByNearness(storage, k)
    requireHiddenIndex(k)
    return LegacyHidden.oldHiddenAt(storage, 8-k)
end

function HiddenPatch.execute(calculationDay, targetDay)
    -- Rele tout kalkil ak depo legacy a san ranplase yo.
    local physical, context = LegacyHidden.execute(calculationDay, targetDay)
    local preserved = {}
    for k=1,7 do preserved[k] = BigInt.from(physical[k]) end
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_HIDDEN"
    context.mode = "STAGE_11_PATCH_05"
    context.status = "PATCH_HIDDEN_PENDING"

    manager.dispatcher:register("HIDDEN_PATCH", function(active, owner)
        local logical = {}
        local candidate = {
            calculationDayDecimal = tostring(calculationDay),
            targetDayDecimal = tostring(targetDay),
            source = "INDEX_TRANSLATION_8_MINUS_K",
            storageOrder = "HIDDEN_7_TO_HIDDEN_1",
            mappingApplied = true
        }
        for k=1,7 do
            -- oldHiddenAt la toujou rete jan li te ye: nou bay li endis fizik la.
            local value = HiddenPatch.hiddenByNearness(preserved, k)
            logical[k] = BigInt.from(value)
            candidate["physical" .. k] = tostring(preserved[k])
            candidate["hidden" .. k] = tostring(value)
        end
        active:beginSemanticUpdate(candidate)
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("hidden.patch.calls")
        for k=1,7 do owner.metricsManager:bump("hidden.patch.indexTranslations") end
        owner.metricsManager:observe("hidden.patch.nearest", active.semanticState.hidden1)
        active.diagnostics[#active.diagnostics + 1] = {
            code = "PATCH_05_MAP_8_MINUS_K",
            phase = active.phase,
            firstPhysicalSlot = active.semanticState.physical1,
            firstLogicalDrop = active.semanticState.hidden1,
            physicalOrderPreserved = true
        }
        active.status = "PATCH_HIDDEN_RETURNED"
        return logical
    end)

    local result = manager.dispatcher:dispatch(context, "HIDDEN_PATCH", manager)
    return result, context
end

return HiddenPatch
