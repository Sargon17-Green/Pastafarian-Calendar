local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local S = require("spaghetti")
local F = -15055671

local checks = {
    {"SELF", F, F, "0", "1", "1"},
    {"BEFORE_NEIGHBORS", F - 1, F - 2, "2", "2", "4"},
    {"AFTER_NEIGHBORS", F + 1, F + 2, "2", "3", "5"},
    {"ACROSS", F - 1, F + 1, "1", "2", "3"},
    {"LONG_BEFORE", F - 5, F - 2, "6", "10", "4"},
    {"LONG_AFTER", F + 2, F + 5, "6", "5", "11"},
    {"REVERSE_CROSS", F + 1, F - 1, "1", "3", "2"}
}
assert(select("#", S.distanceSpaghetti(F, F)) == 1)
assert(select("#", S.legacyDistanceProbe(F, F)) == 2)
for _, item in ipairs(checks) do
    local name, c, t, expected, firstTag, lastTag = table.unpack(item)
    local result, ctx = S.legacyDistanceProbe(c, t)
    assert(tostring(result) == expected, name .. ": move distans istorik la")
    assert(tostring(S.distanceSpaghetti(c, t)) == expected, name .. ": wout pwodiksyon pa aktive")
    assert(ctx.phase == "LEGACY_DISTANCE" and ctx.mode == "STAGE_06_DISCOVERY_03")
    assert(ctx.status == "LEGACY_DISTANCE_RETURNED" and ctx.currentHandler == "LEGACY_DISTANCE")
    assert(ctx.commitToken == 1 and ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    assert(#ctx.branchTrace == 1 and ctx.branchTrace[1] == "LEGACY_DISTANCE")
    assert(ctx.metrics["legacy.distance.calls"] == 1)
    assert(ctx.metrics["legacy.distance.decimalAnswers"][1] == expected)
    assert(ctx.semanticState.calculationDayDecimal == tostring(c))
    assert(ctx.semanticState.targetDayDecimal == tostring(t))
    assert(ctx.semanticState.calculationTagDecimal == firstTag)
    assert(ctx.semanticState.targetTagDecimal == lastTag)
    assert(ctx.semanticState.resultDecimal == expected)
    assert(ctx.semanticState.source == "ABS_PATCHED_DAY_TAG_DIFFERENCE")
    assert(#ctx.diagnostics == 1 and ctx.diagnostics[1].code ==
           "TAG_DISTANCE_INSTEAD_OF_CHRONOLOGICAL_DISTANCE")
    assert(ctx.nestedTagContexts.calculation ~= ctx.nestedTagContexts.target)
    for _, nested in pairs(ctx.nestedTagContexts) do
        assert(nested.status == "PATCH_DAY_TAG_RETURNED")
        assert(nested.mode == "STAGE_05_PATCH_02")
        assert(nested.commitToken == 2 and nested.pendingSemanticState == nil)
        assert(#nested.branchTrace == 2 and nested.branchTrace[1] == "LEGACY_DAY_TAG" and
               nested.branchTrace[2] == "DAY_TAG_PATCH")
    end
    print("TRACE " .. name .. " tags=" .. firstTag .. "," .. lastTag .. " legacy=" .. expected)
end

local _, first = S.legacyDistanceProbe(F - 1, F + 1)
local _, next = S.legacyDistanceProbe(F - 2, F)
first.semanticState.resultDecimal = "999"
first.metrics["legacy.distance.calls"] = 100
first.diagnostics[1].code = "CHANJE"
first.nestedTagContexts.calculation.semanticState.resultDecimal = "888"
first.nestedTagContexts.target.branchTrace[1] = "CHANJE"
assert(next.semanticState.resultDecimal == "3")
assert(next.metrics["legacy.distance.calls"] == 1)
assert(next.diagnostics[1].code == "TAG_DISTANCE_INSTEAD_OF_CHRONOLOGICAL_DISTANCE")
assert(next.nestedTagContexts.calculation.semanticState.resultDecimal == "4")
assert(next.nestedTagContexts.target.branchTrace[1] == "LEGACY_DAY_TAG")
for _, bad in ipairs({"", "1", 1.5, true, {}}) do
    assert(not pcall(S.distanceSpaghetti, bad, F))
    assert(not pcall(S.distanceSpaghetti, F, bad))
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS tras Stage 6: 7 ka, de wout tag aktyèl, izolasyon ak dispatcher")
