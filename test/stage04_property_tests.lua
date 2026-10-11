local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local Old = require("legacy_day_tag")
local F = O.FOUNDATION_DAY
local FB = B.from(F)
local trials, divergences = 0, 0

local function verify(day, label, useOracle)
    local result, context = S.legacyDayTagProbe(day)
    local public = S.dayTagSpaghetti(day)
    local direct = Old.oldDayTag(day)
    local distance = B.abs(B.sub(B.from(day), FB))
    local twice = B.mulSmall(distance, 2)
    assert(B.compare(result, twice) == 0, label .. ": kalkil legacy a")
    assert(B.compare(public, day >= F and twice + B.from(1) or twice) == 0,
           label .. ": wout pwodiksyon ki korije a")
    assert(B.compare(direct, twice) == 0, label .. ": kalkil dirèk la")
    assert(B.compare(result, 0) >= 0, label .. ": rezilta negatif")
    assert(B.mod(result, 2):isZero(), label .. ": legacy a pa pè")
    assert(context.status == "LEGACY_DAY_TAG_RETURNED" and context.commitToken == 1)
    if useOracle then
        local expected = B.from(O.dayCount(day))
        local divergent = B.compare(result, expected) ~= 0
        assert(divergent == (day >= F), label .. ": plas divèjans la")
        assert(B.compare(expected, public) == 0, label .. ": PATCH 02 pa bay rezilta normatif la")
        assert(B.compare(expected, day >= F and result+B.from(1) or result) == 0,
               label .. ": diferans la pa egzakteman youn")
        if divergent then divergences = divergences + 1 end
    end
    trials = trials + 1
    return result
end

-- 501 ka chak jou ozalantou Jou Fondasyon an.
for offset = -250, 250 do
    verify(F + offset, "jou " .. offset, true)
end
assert(trials == 501 and divergences == 251)

-- 128 lòt jou detèminis, san nimewo flotan.
local state = 1729
for index = 1, 128 do
    state = (state * 48271) % 2147483647
    local offset = (state % 200001) - 100000
    verify(F + offset, "jou o aza " .. index, true)
end

-- Verifye simetri legacy a toutotou Fondasyon an.
for offset = 0, 64 do
    local left = S.legacyDayTagProbe(F - offset)
    local right = S.legacyDayTagProbe(F + offset)
    assert(B.compare(left, right) == 0, "Distans legacy a pèdi simetri li")
end

-- Ekstrèm limit nonb antye Lua, kote yon soustraksyon natif ta debòde.
for _, day in ipairs({math.mininteger, math.maxinteger}) do
    verify(day, "limit antye Lua " .. tostring(day), false)
end
assert(trials == 631)
print("PASS pwopriyete Discovery 02: " .. trials ..
      " jou, 501 limit, 128 o aza, 2 ekstrèm Lua, " .. divergences .. " divèjans")
