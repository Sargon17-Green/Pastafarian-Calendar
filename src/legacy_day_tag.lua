local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyDayTag = {}

local FOUNDATION = -15055671
local FOUNDATION_BIG = BigInt.from(FOUNDATION)

-- Erè istorik Discovery 02: n te sipoze de fwa distans ak Jou Fondasyon an.
-- Kòd sa a pa ajoute inite ki manke pou jou Fondasyon an oswa jou apre li.
function LegacyDayTag.oldDayTag(day)
    assert(type(day) == "number" and math.type(day) == "integer",
           "Jou a dwe yon nonb antye Lua")
    local distance = BigInt.abs(BigInt.sub(BigInt.from(day), FOUNDATION_BIG))
    return BigInt.mulSmall(distance, 2)
end

function LegacyDayTag.execute(day)
    local oldResult = LegacyDayTag.oldDayTag(day)
    local context = Base.MonsterContext.new(day, day)
    context.phase = "LEGACY_DAY_TAG"
    context.mode = "STAGE_04_DISCOVERY_02"
    context.status = "PREPARING_LEGACY_DAY_TAG"
    local manager = Base.MonsterManager.new(context)

    manager.dispatcher:register("LEGACY_DAY_TAG", function(active, owner)
        active:beginSemanticUpdate({
            inputDayDecimal = tostring(day),
            foundationDecimal = tostring(FOUNDATION),
            resultDecimal = tostring(oldResult),
            source = "TWICE_ABSOLUTE_FOUNDATION_DISTANCE"
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.daytag.calls")
        owner.metricsManager:observe("legacy.daytag.decimalAnswers", active.semanticState.resultDecimal)
        active.status = "LEGACY_DAY_TAG_RETURNED"
        active.diagnostics[#active.diagnostics + 1] = {
            code = "EVEN_DAY_TAG_ON_FOUNDATION_AND_AFTER",
            phase = active.phase,
            source = active.semanticState.source
        }
        return BigInt.from(active.semanticState.resultDecimal)
    end)
    local answer = manager.dispatcher:dispatch(context, "LEGACY_DAY_TAG", manager)
    return answer, context
end

return LegacyDayTag
