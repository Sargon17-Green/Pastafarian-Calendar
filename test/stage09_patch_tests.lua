local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local BigInt = require("bigint")
local Oracle = require("normative_oracle")
local Spaghetti = require("spaghetti")
local Legacy = require("legacy_stones")
local Patch = require("stone_patch")
local names = {"w", "b", "s", "m", "r"}

-- Referans test-only la li sèlman snapshot old la.
local function expected(i, old)
    local w,b,s,m,r = old.w, old.b, old.s, old.m, old.r
    return {
        w = Oracle.SAVE(BigInt.mul(w,w) + BigInt.mulSmall(b,3) + BigInt.from(i)),
        b = Oracle.SAVE(BigInt.mul(b,b) + BigInt.mulSmall(s,5) + w),
        s = Oracle.SAVE(BigInt.mul(s,s) + BigInt.mulSmall(m,7) + b),
        m = Oracle.SAVE(BigInt.mul(m,m) + BigInt.mulSmall(r,11) + s),
        r = Oracle.SAVE(BigInt.mul(r,r) + BigInt.mulSmall(w,13) + m)
    }
end
local function same(left, right)
    for _, name in ipairs(names) do
        if BigInt.compare(left[name], right[name]) ~= 0 then return false end
    end
    return true
end
local checked, correctedTransitions, differingStones = 0, 0, 0
local function check(i, provided, label)
    local original = Legacy.copy(provided)
    local legacy, legacyContext = Spaghetti.legacyStoneProbe(i, provided)
    local patched, ctx = Spaghetti.stonePatchProbe(i, provided)
    local public = Spaghetti.stoneSpaghetti(i, provided)
    local direct = Patch.stonePatch(i, provided)
    local normative = expected(i, original)
    assert(same(patched, normative), label .. ": dispatcher PATCH 04")
    assert(same(public, normative), label .. ": public pa korije")
    assert(same(direct, normative), label .. ": stonePatch dirèk")
    assert(same(provided, original), label .. ": antre moun nan te chanje")
    assert(same(legacy, Legacy.mutateStonesWrong(i, Legacy.copy(original))),
           label .. ": ansyen mutation an te efase")
    local changed = false
    for _, name in ipairs(names) do
        local oldValue = tostring(original[name])
        local wrongValue = tostring(legacy[name])
        local fixedValue = tostring(normative[name])
        assert(ctx.semanticState["old" .. string.upper(name)] == oldValue)
        assert(ctx.semanticState["garbage" .. string.upper(name)] == wrongValue)
        assert(ctx.semanticState[name] == fixedValue)
        assert(BigInt.compare(patched[name], 1) >= 0 and
               BigInt.compare(patched[name], Oracle.M) <= 0)
        if wrongValue ~= fixedValue then
            changed = true
            differingStones = differingStones + 1
        end
    end
    if changed then correctedTransitions = correctedTransitions + 1 end
    assert(ctx ~= legacyContext and ctx.semanticState ~= legacyContext.semanticState)
    assert(ctx.mode == "STAGE_09_PATCH_04")
    assert(ctx.phase == "PATCH_STONES" and ctx.status == "PATCH_STONES_RETURNED")
    assert(ctx.currentHandler == "STONE_PATCH" and ctx.previousHandler == "LEGACY_STONES")
    assert(#ctx.branchTrace == 2 and ctx.branchTrace[1] == "LEGACY_STONES" and
           ctx.branchTrace[2] == "STONE_PATCH")
    assert(ctx.commitToken == 2 and ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    assert(ctx.semanticState.index == i and ctx.semanticState.legacyCallPreserved == true)
    assert(ctx.semanticState.source == "SNAPSHOT_REPLACES_SEQUENTIAL_GARBAGE")
    assert(ctx.metrics["legacy.stones.calls"] == 1 and ctx.metrics["stone.patch.calls"] == 1)
    assert(ctx.metrics["stone.patch.legacyCallsPreserved"] == 1)
    assert(ctx.metrics["stone.patch.lastBarley"][1] == tostring(normative.b))
    assert(#ctx.diagnostics == 2 and ctx.diagnostics[1].code == "SEQUENTIAL_REUSE_OF_NEW_STONES")
    assert(ctx.diagnostics[2].code == "PATCH_04_REPLACE_ALL_STONES_FROM_OLD")
    assert(ctx.diagnostics[2].legacyBarley == tostring(legacy.b))
    assert(ctx.diagnostics[2].correctedBarley == tostring(normative.b))
    assert(legacyContext.status == "LEGACY_STONES_RETURNED" and legacyContext.commitToken == 1)
    checked = checked + 1
end

local seed = Legacy.seed()
local rows = Spaghetti.stoneTableSpaghetti()
local legacyRows = Legacy.buildLegacyTable()
assert(#rows == 46 and #legacyRows == 46)
assert(same(rows[1], seed) and same(legacyRows[1], seed))
local independent = Legacy.copy(seed)
for i = 2, 46 do
    check(i, rows[i-1], "ranje " .. i)
    independent = expected(i, independent)
    assert(same(rows[i], independent), "Pa gen snapshot antre ranje " .. i)
end
assert(not same(rows[2], legacyRows[2]))
assert(not same(rows[46], legacyRows[46]))
assert(tostring(rows[2].b) == "1073")
assert(tostring(legacyRows[2].b) == "1434")
local fresh = Spaghetti.stoneTableSpaghetti()
rows[2].b = BigInt.from(999)
assert(tostring(fresh[2].b) == "1073", "Kach oswa alias ant de tablo")

-- 5^3 gri sou limit modil M ak gwo antye negatif.
local sample = {"0", "1", "-1", tostring(Oracle.M),
    "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
for a=1,5 do for b=1,5 do for c=1,5 do
    check(2 + (a + b + c) % 45, {
        w=sample[a], b=sample[b], s=sample[c],
        m=sample[(a+b)%5+1], r=sample[(a+c)%5+1]
    }, "gri " .. a .. "," .. b .. "," .. c)
end end end

local state = 17291
local function digit()
    state = (state * 48271) % 2147483647
    return state % 10
end
local function decimal(n)
    local chars = {tostring(1 + (digit() % 9))}
    for _ = 2,n do chars[#chars+1] = tostring(digit()) end
    return table.concat(chars)
end
for i=1,240 do
    local digits = 1 + ((i * 47) % 145)
    local input={}
    for j,name in ipairs(names) do
        local s = decimal(digits + 4 * j)
        if (i+j)%3 == 0 then s = "-" .. s end
        input[name] = s
    end
    check(2+(i*13)%45, input, "gwo antye " .. i)
end

-- Verifye tout 45 index legal yo sou antre sifas fonksyon an.
for i=2,46 do
    check(i, seed, "index " .. i)
end
assert(checked == 455)
assert(correctedTransitions > 400 and differingStones > 1000)

assert(select("#", Spaghetti.stoneSpaghetti(2, seed)) == 1)
assert(select("#", Spaghetti.stonePatchProbe(2, seed)) == 2)
assert(select("#", Spaghetti.legacyStoneProbe(2, seed)) == 2)
local _, first = Spaghetti.stonePatchProbe(2, seed)
first.semanticState.b = "999"
first.metrics["legacy.stones.calls"] = 999
first.branchTrace[1] = "CHANJE"
first.diagnostics[1].code = "CHANJE"
local _, second = Spaghetti.stonePatchProbe(2, seed)
assert(second.semanticState.b == "1073")
assert(second.metrics["legacy.stones.calls"] == 1)
assert(second.branchTrace[1] == "LEGACY_STONES")
assert(second.diagnostics[1].code == "SEQUENTIAL_REUSE_OF_NEW_STONES")

for _, bad in ipairs({0,1,47,48,2.5,"2",true}) do
    assert(not pcall(Spaghetti.stoneSpaghetti, bad, seed))
    assert(not pcall(Patch.stonePatch, bad, seed))
end
for _, bad in ipairs({{}, {w=1,b=2,s=3,m=4}, {w="1.2",b=2,s=3,m=4,r=5}, false}) do
    assert(not pcall(Spaghetti.stoneSpaghetti, 2, bad))
    assert(not pcall(Patch.stonePatch, 2, bad))
end
assert(not pcall(Spaghetti.calendarDateSpaghetti))
print("PASS PATCH 04: " .. checked .. " transitions, " .. correctedTransitions ..
      " divergence, " .. differingStones .. " stones corrected, 46 rows")
