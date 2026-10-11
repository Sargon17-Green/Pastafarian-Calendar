local BigInt = require("bigint")
local Base = require("monster_base")
local LegacySave = {}

-- Premye sipozisyon istorik la: yon rès òdinè ta sifi kòm SAVE.
-- Stage 2 kite sipozisyon sa a egzakteman jan li ye; pa gen koreksyon.
local M = BigInt.from("170141183460469231731687303715884105727")

function LegacySave.oldRemainder(value)
    return BigInt.mod(BigInt.from(value), M)
end

function LegacySave.execute(value)
    local input = BigInt.from(value)
    local context = Base.MonsterContext.new(0, 0)
    context.phase = "LEGACY_SAVE"
    context.mode = "STAGE_02_DISCOVERY_01"
    context.status = "PREPARING_LEGACY"
    local manager = Base.MonsterManager.new(context)

    manager.dispatcher:register("LEGACY_SAVE", function(active, owner)
        local wrong = LegacySave.oldRemainder(input)
        -- Eta semantik la pran chèn desimal pou konsève valè egzak la
        -- menm lè kopi tranzaksyon an pa konsève metatab BigInt la.
        active:beginSemanticUpdate({
            inputDecimal = tostring(input),
            resultDecimal = tostring(wrong),
            source = "REGULAR_MOD"
        })
        owner.validationManager:requirePendingState(active)
        active:commitSemanticUpdate()
        owner.validationManager:requireNoPendingState(active)
        owner.metricsManager:bump("legacy.save.calls")
        owner.metricsManager:observe("legacy.save.decimalAnswers", active.semanticState.resultDecimal)
        active.status = "LEGACY_RETURNED"
        active.diagnostics[#active.diagnostics + 1] = {
            code = "REGULAR_MOD_INSTEAD_OF_SAVE",
            phase = active.phase,
            source = active.semanticState.source
        }
        return BigInt.from(active.semanticState.resultDecimal)
    end)

    local result = manager.dispatcher:dispatch(context, "LEGACY_SAVE", manager)
    return result, context
end

return LegacySave
