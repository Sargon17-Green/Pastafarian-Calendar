local BigInt = require("bigint")
local Base = require("monster_base")
local DayTagPatch = require("day_tag_patch")
local LegacyDistance = {}

-- Sipozisyon istorik la: distans ant de nimewo jou ta egal distans jou yo.
-- Nimewo jou yo sòti nan chemen PATCH 02 pwodiksyon an, pa nan oracle tès la.
function LegacyDistance.oldDistance(calculationDay, targetDay, trace)
    local firstTag, firstContext = DayTagPatch.execute(calculationDay)
    local secondTag, secondContext = DayTagPatch.execute(targetDay)
    if trace ~= nil then
        assert(type(trace) == "table", "Tras kalkil la dwe yon tablo")
        trace.calculationTagDecimal = tostring(firstTag)
        trace.targetTagDecimal = tostring(secondTag)
        trace.calculationContext = firstContext
        trace.targetContext = secondContext
    end
    return BigInt.abs(BigInt.sub(firstTag, secondTag))
end

function LegacyDistance.execute(calculationDay, targetDay)
    local trace = {}
    -- Rezilta sa a soti nan oldDistance li menm: nou pa rekreye erè a nan tès.
    local wrong = LegacyDistance.oldDistance(calculationDay, targetDay, trace)
    local context = Base.MonsterContext.new(calculationDay, targetDay)
    context.phase = "LEGACY_DISTANCE"
    context.mode = "STAGE_06_DISCOVERY_03"
    context.status = "PREPARING_LEGACY_DISTANCE"
    context.nestedTagContexts = {
        calculation = trace.calculationContext,
        target = trace.targetContext
    }
    local manager = Base.MonsterManager.new(context)

    manager.dispatcher:register("LEGACY_DISTANCE", function(active, owner)
        active:beginSemanticUpdate({
            calculationDayDecimal = tostring(calculationDay),
            targetDayDecimal = tostring(targetDay),
            calculationTagDecimal = trace.calculationTagDecimal,
            targetTagDecimal = trace.targetTagDecimal,
            resultDecimal = tostring(wrong),
            source = "ABS_PATCHED_DAY_TAG_DIFFERENCE"
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.distance.calls")
        owner.metricsManager:observe("legacy.distance.decimalAnswers", active.semanticState.resultDecimal)
        active.status = "LEGACY_DISTANCE_RETURNED"
        active.diagnostics[#active.diagnostics + 1] = {
            code = "TAG_DISTANCE_INSTEAD_OF_CHRONOLOGICAL_DISTANCE",
            phase = active.phase,
            calculationTag = active.semanticState.calculationTagDecimal,
            targetTag = active.semanticState.targetTagDecimal
        }
        return BigInt.from(active.semanticState.resultDecimal)
    end)

    local result = manager.dispatcher:dispatch(context, "LEGACY_DISTANCE", manager)
    return result, context
end

return LegacyDistance
