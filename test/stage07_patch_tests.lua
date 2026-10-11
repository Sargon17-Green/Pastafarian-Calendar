local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local BigInt = require("bigint")
local S = require("spaghetti")
local DistancePatch = require("distance_patch")
local LegacyDistance = require("legacy_distance")
local F = -15055671

local cases, replaced, kept = 0, 0, 0
local function check(c, t, label)
    local legacy, originalContext = S.legacyDistanceProbe(c, t)
    local patched, ctx = S.distancePatchProbe(c, t)
    local public = S.distanceSpaghetti(c, t)
    local direct = DistancePatch.distancePatch(c, t)
    local chronological = BigInt.abs(BigInt.sub(BigInt.from(t), BigInt.from(c)))
    local expected = BigInt.add(chronological, 1)
    local changed = BigInt.compare(legacy, chronological) ~= 0
    local tagDiff = LegacyDistance.oldDistance(c, t)

    assert(BigInt.compare(legacy, tagDiff) == 0, label .. ": legacy pa rete menm")
    assert(BigInt.compare(public, expected) == 0, label .. ": rezilta piblik")
    assert(BigInt.compare(patched, expected) == 0, label .. ": rezilta dispatcher")
    assert(BigInt.compare(direct, expected) == 0, label .. ": kouch dirèk")
    assert(BigInt.compare(expected, 1) >= 0, label .. ": distans enklizif negatif")
    if c == t then assert(BigInt.compare(expected, 1) == 0) end
    assert(ctx ~= originalContext and ctx.semanticState ~= originalContext.semanticState)
    assert(ctx.mode == "STAGE_07_PATCH_03" and ctx.phase == "PATCH_DISTANCE")
    assert(ctx.status == "PATCH_DISTANCE_RETURNED")
    assert(ctx.currentHandler == "DISTANCE_PATCH" and ctx.previousHandler == "LEGACY_DISTANCE")
    assert(#ctx.branchTrace == 2 and ctx.branchTrace[1] == "LEGACY_DISTANCE"
           and ctx.branchTrace[2] == "DISTANCE_PATCH")
    assert(ctx.commitToken == 2 and ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    assert(ctx.semanticState.calculationDayDecimal == tostring(c))
    assert(ctx.semanticState.targetDayDecimal == tostring(t))
    assert(ctx.semanticState.legacyDistanceDecimal == tostring(legacy))
    assert(ctx.semanticState.chronologicalDistanceDecimal == tostring(chronological))
    assert(ctx.semanticState.reconciledDistanceDecimal == tostring(chronological))
    assert(ctx.semanticState.resultDecimal == tostring(expected))
    assert(ctx.semanticState.inclusiveUnitAdded == true)
    assert(ctx.semanticState.source == "DISTANCE_PATCH_03")
    assert(ctx.semanticState.correction == (changed and "REPLACE_TAG_DIFFERENCE" or "KEEP_TAG_DIFFERENCE"))
    assert(ctx.metrics["legacy.distance.calls"] == 1)
    assert(ctx.metrics["distance.patch.calls"] == 1)
    assert(ctx.metrics["distance.patch.inclusiveUnits"] == 1)
    assert(ctx.metrics["distance.patch.reconciliations"] == (changed and 1 or nil))
    assert(ctx.metrics["distance.patch.decimalAnswers"][1] == tostring(expected))
    assert(#ctx.diagnostics == 2)
    assert(ctx.diagnostics[1].code == "TAG_DISTANCE_INSTEAD_OF_CHRONOLOGICAL_DISTANCE")
    assert(ctx.diagnostics[2].code ==
          (changed and "PATCH_03_RECONCILE_CHRONOLOGICAL" or "PATCH_03_KEEP_LEGACY"))
    assert(ctx.diagnostics[2].original == tostring(legacy))
    assert(ctx.diagnostics[2].chronological == tostring(chronological))
    assert(ctx.diagnostics[2].reconciled == tostring(chronological))
    assert(ctx.diagnostics[2].corrected == tostring(expected))
    assert(originalContext.commitToken == 1 and originalContext.status == "LEGACY_DISTANCE_RETURNED")
    assert(ctx.nestedTagContexts.calculation ~= ctx.nestedTagContexts.target)
    for _, nested in pairs(ctx.nestedTagContexts) do
        assert(nested.status == "PATCH_DAY_TAG_RETURNED")
        assert(nested.commitToken == 2 and nested.pendingSemanticState == nil)
        assert(#nested.branchTrace == 2 and nested.branchTrace[2] == "DAY_TAG_PATCH")
    end
    if changed then replaced = replaced + 1 else kept = kept + 1 end
    cases = cases + 1
end

-- 49 x 49 jou, toude bò Fondasyon an ak tout konbinezon yo.
for a = -24, 24 do
    for b = -24, 24 do
        check(F + a, F + b, "kadriyaj " .. a .. "," .. b)
    end
end
assert(cases == 2401)

-- 256 lòt pè repwodiktib, kote kalkil ak sib ka byen lwen.
local state = 49333
local function nextOffset()
    state = (state * 48271) % 2147483647
    return (state % 1000001) - 500000
end
for i = 1, 256 do
    local c = F + nextOffset()
    local t = F + nextOffset()
    check(c, t, "pè detèminis " .. i)
    assert(BigInt.compare(S.distanceSpaghetti(c, t), S.distanceSpaghetti(t, c)) == 0,
           "Distans enklizif dwe simetrik")
end

-- Operasyon natif t-c ta debòde isit la; BigInt rete egzak.
local boundaries = {
    {math.mininteger, math.maxinteger},
    {math.maxinteger, math.mininteger},
    {math.mininteger, F}, {F, math.mininteger},
    {math.maxinteger, F}, {F, math.maxinteger},
    {math.mininteger, math.mininteger}, {math.maxinteger, math.maxinteger}
}
for i, pair in ipairs(boundaries) do
    check(pair[1], pair[2], "limit Lua " .. i)
end
assert(cases == 2665)
assert(replaced > 2000 and kept > 0, "Tou de branch konparezon yo dwe kouri")

assert(select("#", S.distanceSpaghetti(F, F)) == 1)
assert(select("#", S.distancePatchProbe(F, F)) == 2)
assert(select("#", S.legacyDistanceProbe(F, F)) == 2)
local _, first = S.distancePatchProbe(F - 1, F + 1)
first.semanticState.resultDecimal = "999"
first.nestedTagContexts.calculation.semanticState.resultDecimal = "999"
first.metrics["legacy.distance.calls"] = 99
first.diagnostics[1].code = "CHANJE"
first.branchTrace[1] = "CHANJE"
local _, second = S.distancePatchProbe(F - 1, F + 1)
assert(second.semanticState.resultDecimal == "3")
assert(second.nestedTagContexts.calculation.semanticState.resultDecimal == "2")
assert(second.metrics["legacy.distance.calls"] == 1)
assert(second.diagnostics[1].code == "TAG_DISTANCE_INSTEAD_OF_CHRONOLOGICAL_DISTANCE")
assert(second.branchTrace[1] == "LEGACY_DISTANCE")

for _, bad in ipairs({"", "1", 1.5, true, {}}) do
    assert(not pcall(S.distanceSpaghetti, bad, F), "Premye jou ilegal aksepte")
    assert(not pcall(S.distanceSpaghetti, F, bad), "Dezyèm jou ilegal aksepte")
    assert(not pcall(S.distancePatchProbe, bad, F))
    assert(not pcall(S.legacyDistanceProbe, F, bad))
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS PATCH 03: " .. cases .. " pè, " .. replaced ..
      " rekonsilyasyon, " .. kept .. " chemen legacy konsève")
