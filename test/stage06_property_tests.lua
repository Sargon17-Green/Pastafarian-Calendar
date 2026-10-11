local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local Old = require("legacy_distance")
local F = O.FOUNDATION_DAY
local total, diverged = 0, 0
local function check(c, t, label, checkOracle)
    local old, ctx = S.legacyDistanceProbe(c, t)
    local public = S.distanceSpaghetti(c, t)
    local direct = Old.oldDistance(c, t)
    local left = S.dayTagSpaghetti(c)
    local right = S.dayTagSpaghetti(t)
    local tagDifference = B.abs(B.sub(left, right))
    local chronological = B.add(B.abs(B.sub(B.from(t), B.from(c))), 1)
    assert(B.compare(old, direct) == 0 and B.compare(old, tagDifference) == 0,
           label .. ": move diferans tag yo")
    assert(B.compare(public, old) == 0, label .. ": wout pwodiksyon an pa pase nan legacy")
    assert(B.compare(old, 0) >= 0, label .. ": distans negatif")
    assert(ctx.commitToken == 1 and ctx.status == "LEGACY_DISTANCE_RETURNED")
    assert(ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    assert(ctx.semanticState.calculationTagDecimal == tostring(left))
    assert(ctx.semanticState.targetTagDecimal == tostring(right))
    assert(ctx.semanticState.resultDecimal == tostring(old))
    if checkOracle then
        assert(B.compare(left, O.dayCount(c)) == 0, label .. ": tag kalkil la pa normatif")
        assert(B.compare(right, O.dayCount(t)) == 0, label .. ": tag sib la pa normatif")
    end
    if c == t then
        assert(old:isZero() and B.compare(chronological, 1) == 0, label .. ": menm jou")
    end
    if B.compare(old, chronological) ~= 0 then diverged = diverged + 1 end
    total = total + 1
    return old
end

-- Kadriyaj konplè sou 37 x 37 pè jou ozalantou Fondasyon an.
for c = -18, 18 do
    for t = -18, 18 do
        check(F + c, F + t, "kadriyaj " .. c .. "," .. t, true)
    end
end
assert(total == 1369)

-- 256 pè detèminis pou verifye distans ki pa vwazen yo.
local state = 15427
local function nextOffset()
    state = (state * 48271) % 2147483647
    return (state % 100001) - 50000
end
for index = 1, 256 do
    local c = F + nextOffset()
    local t = F + nextOffset()
    local first = check(c, t, "echantiyon " .. index, true)
    assert(B.compare(first, S.distanceSpaghetti(t, c)) == 0,
           "Diferans absoli a pa simetrik")
end

-- Pa fè soustraksyon natif Lua ant mininteger ak maxinteger.
local boundary = {
    {math.mininteger, math.maxinteger},
    {math.maxinteger, math.mininteger},
    {math.mininteger, F}, {F, math.mininteger},
    {math.maxinteger, F}, {F, math.maxinteger},
    {math.mininteger, math.mininteger},
    {math.maxinteger, math.maxinteger}
}
for i, pair in ipairs(boundary) do
    check(pair[1], pair[2], "limit Lua " .. i, false)
end
assert(total == 1633)
assert(diverged > 1000, "Pifò ka yo ta dwe montre defo istorik la")
print("PASS pwopriyete Stage 6: " .. total .. " pè jou, " .. diverged ..
      " diferans istorik, 8 limit antye Lua")
