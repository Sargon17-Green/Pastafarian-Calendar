local BigInt = require("bigint")
local Base = require("monster_base")
local LegacySave = require("legacy_save")
local SavePatch = {}

local M = BigInt.from("170141183460469231731687303715884105727")

-- PATCH 01 sèvi ak ansyen kalkil la; li korije sèlman rès zewo a.
-- oldRemainder dwe rete jan li te ye nan Discovery 01.
function SavePatch.savePatch(value)
    local remainder = LegacySave.oldRemainder(value)
    if remainder:isZero() then
        return BigInt.from(M)
    end
    return remainder
end

-- Kontèks la konsève toude etap yo: LEGACY_SAVE anvan SAVE_PATCH.
-- Oracle normatif la rete nan test/; kòd pwodiksyon sa a pa enpòte li.
function SavePatch.execute(value)
    local input = BigInt.from(value)
    local legacyResult, context = LegacySave.execute(input)
    local manager = Base.MonsterManager.new(context)
    context.phase = "PATCH_SAVE"
    context.mode = "STAGE_03_PATCH_01"
    context.status = "PATCH_PENDING"

    manager.dispatcher:register("SAVE_PATCH", function(active, owner)
        local corrected = SavePatch.savePatch(input)
        local changed = legacyResult:isZero()
        assert(BigInt.compare(corrected, changed and M or legacyResult) == 0,
               "Kouch PATCH 01 la pa koresponn ak kalkil legacy a")
        active:beginSemanticUpdate({
            inputDecimal = tostring(input),
            legacyResultDecimal = tostring(legacyResult),
            resultDecimal = tostring(corrected),
            source = "SAVE_PATCH_01",
            correction = changed and "ZERO_TO_M" or "UNCHANGED"
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("save.patch.calls")
        if changed then owner.metricsManager:bump("save.patch.zeroFixes") end
        owner.metricsManager:observe("save.patch.decimalAnswers", active.semanticState.resultDecimal)
        active.diagnostics[#active.diagnostics + 1] = {
            code = changed and "PATCH_01_ZERO_TO_M" or "PATCH_01_PASSTHROUGH",
            phase = active.phase,
            original = active.semanticState.legacyResultDecimal,
            corrected = active.semanticState.resultDecimal
        }
        active.status = "PATCH_RETURNED"
        return BigInt.from(active.semanticState.resultDecimal)
    end)

    local result = manager.dispatcher:dispatch(context, "SAVE_PATCH", manager)
    return result, context
end

return SavePatch
