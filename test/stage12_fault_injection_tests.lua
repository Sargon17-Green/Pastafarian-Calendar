local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local Prior = require("legacy_prior")
local HiddenPatch = require("hidden_patch")
local S = require("spaghetti")
local F = -15055671
local store = {B.from(139), B.from(227), B.from(311), B.from(419)}
local originalHiddenExecute = HiddenPatch.execute
local originalPrior = Prior.legacyPrior

local function restore()
    HiddenPatch.execute = originalHiddenExecute
    Prior.legacyPrior = originalPrior
end

-- Fè echèk pandan kouch hidden a ap travay; pa gen rezilta pòv ki ta
-- konsève yon komit oubyen yon moso eta pou yon invocation pita.
local trials = 0
for fault = 1, 7 do
    local marker = "INJECTED_HIDDEN_FAILURE_" .. fault
    HiddenPatch.execute = function() error(marker, 0) end
    local ok, err = pcall(Prior.execute, store, F, F, 1, fault)
    restore()
    assert(not ok and tostring(err):find(marker, 1, true),
           "Echèk hidden la pa vizib oubyen li te kache")
    local value, context = S.legacyPriorProbe(store, F, F, 1, fault)
    assert(value == nil and context.status == "LEGACY_PRIOR_MISSING")
    assert(context.commitToken == 1 and context.nestedHiddenContext.commitToken == 2)
    trials = trials + 1
end

-- Fè echèk nan lekti legacy a apre hidden fini, pou verifye
-- handler ki nan dispatcher la pa sèvi ak done demi-valab.
for back = 1, 7 do
    local marker = "INJECTED_PRIOR_FAILURE_" .. back
    Prior.legacyPrior = function() error(marker, 0) end
    local ok, err = pcall(S.legacyPriorProbe, store, F, F, 1, back)
    restore()
    assert(not ok and tostring(err):find(marker, 1, true))
    local value, context = S.legacyPriorProbe(store, F, F, 1, back)
    assert(value == nil and context.semanticState.resultDecimal == "MISSING")
    assert(context.metrics["legacy.prior.calls"] == 1)
    trials = trials + 1
end

-- Olye yon fo validasyon sou yon BigInt ki pa bon, dwe leve yon
-- echèk klè epi kenbe done moun ki rele nou an san modifye.
local malformed = {[1]=B.from(13), [2]="pa-yon-antye"}
assert(not pcall(S.priorSpaghetti, malformed, F, F, 2, 1))
assert(tostring(malformed[1]) == "13" and malformed[2] == "pa-yon-antye")
trials = trials + 1

-- Kontèks dyagnostik ki soti nan yon invocation pa kapab kontamine lòt la.
local result, first = S.legacyPriorProbe(store, F, F, 2, 1)
assert(tostring(result) == "139")
first.semanticState.resultDecimal = "99"
first.nestedHiddenContext.commitToken = 99
first.diagnostics[1].code = "CHANJE"
first.metrics["legacy.prior.calls"] = 99
first.branchTrace[1] = "CHANJE"
local secondResult, second = S.legacyPriorProbe(store, F, F, 2, 1)
assert(tostring(secondResult) == "139")
assert(second.semanticState.resultDecimal == "139")
assert(second.nestedHiddenContext.commitToken == 2)
assert(second.diagnostics[1].code == "VISIBLE_HISTORY_READ")
assert(second.metrics["legacy.prior.calls"] == 1)
assert(second.branchTrace[1] == "LEGACY_PRIOR")

-- Erè indeks yo jwenn yo byen bonè, pa apre yon konvèsyon ki ka debòde.
for _,bad in ipairs({0, -1, 2.5, "1", true, {}}) do
    assert(not pcall(S.priorSpaghetti, store, F, F, bad, 1))
    assert(not pcall(S.priorSpaghetti, store, F, F, 1, bad))
end
restore()
assert(HiddenPatch.execute == originalHiddenExecute and Prior.legacyPrior == originalPrior)
print("PASS rezilyans Stage 12: " .. trials .. " echèk izole, rekiperasyon, eta posede")
