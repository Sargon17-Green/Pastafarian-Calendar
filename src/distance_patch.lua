local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyDistance = require("legacy_distance")
local DistancePatch = {}

-- PATCH 03 pa efase ansyen kalkil la. Li konpare valè ki soti nan
-- oldDistance avèk distans kwonolojik la, epi sèlman apre sa li ajoute 1.
local function reconcile(legacy, calculationDay, targetDay)
    local chronological = BigInt.abs(BigInt.sub(BigInt.from(targetDay), BigInt.from(calculationDay)))
    local reconciled = legacy
    local differed = BigInt.compare(reconciled, chronological) ~= 0
    if differed then
        reconciled = chronological
    end
    local distance = BigInt.add(reconciled, 1)
    return distance, chronological, reconciled, differed
end

-- Pwen antre dirèk la toujou rele chemen legacy aktyèl la anvan koreksyon.
function DistancePatch.distancePatch(calculationDay, targetDay)
    local legacy = LegacyDistance.execute(calculationDay, targetDay)
    local distance = reconcile(legacy, calculationDay, targetDay)
    return distance
end

-- Menm kontèks la kenbe yon handler LEGACY_DISTANCE ak handler DISTANCE_PATCH.
-- Oracle normatif la rete nan test/; pa gen kopi oracle nan production.
function DistancePatch.execute(calculationDay, targetDay)
    local legacy, context = LegacyDistance.execute(calculationDay, targetDay)
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_DISTANCE"
    context.mode = "STAGE_07_PATCH_03"
    context.status = "PATCH_DISTANCE_PENDING"

    manager.dispatcher:register("DISTANCE_PATCH", function(active, owner)
        local corrected, chronological, reconciled, differed =
            reconcile(legacy, calculationDay, targetDay)
        assert(BigInt.compare(corrected, BigInt.add(reconciled, 1)) == 0,
               "PATCH 03 pa ajoute yon inite a")
        active:beginSemanticUpdate({
            calculationDayDecimal = tostring(calculationDay),
            targetDayDecimal = tostring(targetDay),
            calculationTagDecimal = active.semanticState.calculationTagDecimal,
            targetTagDecimal = active.semanticState.targetTagDecimal,
            legacyDistanceDecimal = tostring(legacy),
            chronologicalDistanceDecimal = tostring(chronological),
            reconciledDistanceDecimal = tostring(reconciled),
            resultDecimal = tostring(corrected),
            source = "DISTANCE_PATCH_03",
            correction = differed and "REPLACE_TAG_DIFFERENCE" or "KEEP_TAG_DIFFERENCE",
            inclusiveUnitAdded = true
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("distance.patch.calls")
        if differed then owner.metricsManager:bump("distance.patch.reconciliations") end
        owner.metricsManager:bump("distance.patch.inclusiveUnits")
        owner.metricsManager:observe("distance.patch.decimalAnswers", active.semanticState.resultDecimal)
        active.diagnostics[#active.diagnostics + 1] = {
            code = differed and "PATCH_03_RECONCILE_CHRONOLOGICAL" or "PATCH_03_KEEP_LEGACY",
            phase = active.phase,
            original = active.semanticState.legacyDistanceDecimal,
            chronological = active.semanticState.chronologicalDistanceDecimal,
            reconciled = active.semanticState.reconciledDistanceDecimal,
            corrected = active.semanticState.resultDecimal
        }
        active.status = "PATCH_DISTANCE_RETURNED"
        return BigInt.from(active.semanticState.resultDecimal)
    end)

    local result = manager.dispatcher:dispatch(context, "DISTANCE_PATCH", manager)
    return result, context
end

return DistancePatch
