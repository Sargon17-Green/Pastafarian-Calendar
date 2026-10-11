local BigInt = require("bigint")
local Base = require("monster_base")
local LegacyDayTag = require("legacy_day_tag")
local DayTagPatch = {}

local FOUNDATION = -15055671

-- PATCH 02: konsève ansyen kalkil la; ajoute parite ki te manke a.
-- Dezyèm guard Fondasyon an rete menm si premye kondisyon an ta sifi.
function DayTagPatch.dayTagWithFoundationScar(day)
    local n = LegacyDayTag.oldDayTag(day)
    if day >= FOUNDATION then
        n = BigInt.add(n, 1)
    end
    if day == FOUNDATION and BigInt.compare(n, 1) ~= 0 then
        n = BigInt.from(1)
    end
    return n
end

-- Nou kenbe de handler diferan nan yon sèl kontèks semantik:
-- LEGACY_DAY_TAG -> DAY_TAG_PATCH; oracle a pa sèvi nan production.
function DayTagPatch.execute(day)
    local original, context = LegacyDayTag.execute(day)
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_DAY_TAG"
    context.mode = "STAGE_05_PATCH_02"
    context.status = "PATCH_DAY_TAG_PENDING"

    manager.dispatcher:register("DAY_TAG_PATCH", function(active, owner)
        local corrected = DayTagPatch.dayTagWithFoundationScar(day)
        local requiresOdd = day >= FOUNDATION
        local expected = requiresOdd and BigInt.add(original, 1) or original
        assert(BigInt.compare(corrected, expected) == 0,
               "Kouch PATCH 02 pa swiv valè legacy a")
        active:beginSemanticUpdate({
            inputDayDecimal = tostring(day),
            foundationDecimal = tostring(FOUNDATION),
            legacyResultDecimal = tostring(original),
            resultDecimal = tostring(corrected),
            source = "DAY_TAG_PATCH_02",
            correction = requiresOdd and "ODD_PARITY" or "UNCHANGED",
            foundationGuard = day == FOUNDATION
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("daytag.patch.calls")
        if requiresOdd then owner.metricsManager:bump("daytag.patch.oddCorrections") end
        if day == FOUNDATION then owner.metricsManager:bump("daytag.patch.foundationGuardChecks") end
        owner.metricsManager:observe("daytag.patch.decimalAnswers", active.semanticState.resultDecimal)
        active.diagnostics[#active.diagnostics + 1] = {
            code = requiresOdd and "PATCH_02_ADD_ODD_PARITY" or "PATCH_02_PASSTHROUGH",
            phase = active.phase,
            original = active.semanticState.legacyResultDecimal,
            corrected = active.semanticState.resultDecimal,
            foundationGuardPresent = true
        }
        active.status = "PATCH_DAY_TAG_RETURNED"
        return BigInt.from(active.semanticState.resultDecimal)
    end)

    local result = manager.dispatcher:dispatch(context, "DAY_TAG_PATCH", manager)
    return result, context
end

return DayTagPatch
