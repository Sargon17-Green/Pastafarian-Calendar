local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local M = O.M

local cases = {
    {name = "M", value = M, expectedWrong = "0", mustDiffer = true},
    {name = "2M", value = M * B.from(2), expectedWrong = "0", mustDiffer = true},
    {name = "3M", value = M * B.from(3), expectedWrong = "0", mustDiffer = true},
    {name = "M+1", value = M + B.from(1), expectedWrong = "1", mustDiffer = false},
    {name = "0", value = B.from(0), expectedWrong = "0", mustDiffer = true},
    {name = "-M", value = -M, expectedWrong = "0", mustDiffer = true}
}

local count = 0
for _, case in ipairs(cases) do
    local wrong, context = S.legacySaveProbe(case.value)
    local authoritative = S.saveSpaghetti(case.value)
    local norm = O.SAVE(case.value)
    assert(B.compare(authoritative, wrong) == 0, "Stage 2 dwe pase nan legacy a")
    assert(tostring(wrong) == case.expectedWrong, case.name .. ": move rès legacy a")
    assert((B.compare(wrong, norm) ~= 0) == case.mustDiffer, case.name .. ": move diferans lan")
    assert(context.status == "LEGACY_RETURNED")
    assert(context.mode == "STAGE_02_DISCOVERY_01")
    assert(context.currentHandler == "LEGACY_SAVE")
    assert(context.metrics["legacy.save.calls"] == 1)
    assert(context.commitToken == 1)
    assert(context.pendingSemanticState == nil and context.rollbackSnapshot == nil)
    assert(context.semanticState.resultDecimal == tostring(wrong))
    assert(context.semanticState.inputDecimal == tostring(case.value))
    assert(#context.branchTrace == 1 and context.branchTrace[1] == "LEGACY_SAVE")
    assert(#context.diagnostics == 1 and context.diagnostics[1].code == "REGULAR_MOD_INSTEAD_OF_SAVE")
    count = count + 1
    print("TRACE " .. case.name .. " legacy=" .. tostring(wrong) .. " normative=" .. tostring(norm) ..
        (case.mustDiffer and " DIVERGENCE" or " MATCH"))
end

local first, firstContext = S.legacySaveProbe(M)
local second, secondContext = S.legacySaveProbe(M + B.from(1))
assert(firstContext ~= secondContext and firstContext.semanticState ~= secondContext.semanticState)
assert(tostring(first) == "0" and tostring(second) == "1")
assert(firstContext.metrics["legacy.save.calls"] == 1)
assert(secondContext.metrics["legacy.save.calls"] == 1)
assert(not pcall(S.legacySaveProbe, "pa-yon-antye"))
assert(count == 6)
print("PASS tras Stage 2: diferans lan izole nan rès modulo òdinè a")
