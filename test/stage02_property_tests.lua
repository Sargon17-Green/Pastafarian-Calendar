local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local M = O.M

local trials, differences, ordinary = 0, 0, 0

local function check(value, label)
    local x = B.from(value)
    local actual, ctx = S.legacySaveProbe(x)
    local public = S.saveSpaghetti(x)
    local norm = O.SAVE(x)
    local quotient, remainder = B.divmodFloor(x, M)
    assert(B.compare(actual, remainder) == 0, label .. ": move rès la")
    assert(B.compare(public, norm) == 0, label .. ": chemen pwodiksyon an pa korije")
    assert(B.compare(remainder, B.from(0)) >= 0, label .. ": rès negatif")
    assert(B.compare(remainder, M) < 0, label .. ": rès depase modil la")
    assert(B.compare(B.mul(quotient, M) + remainder, x) == 0,
        label .. ": idantite divizyon an pa kenbe")
    assert(ctx.commitToken == 1 and ctx.status == "LEGACY_RETURNED", label .. ": eta")
    assert(ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil,
        label .. ": eta annatant")
    assert(ctx.semanticState.inputDecimal == tostring(x), label .. ": antre")
    assert(ctx.semanticState.resultDecimal == tostring(remainder), label .. ": sòti")
    assert(B.compare(norm, remainder) == 0 or
           (remainder:isZero() and B.compare(norm, M) == 0),
        label .. ": diferans ki pa soti nan rès zewo")
    local divergent = B.compare(actual, norm) ~= 0
    assert(divergent == remainder:isZero(), label .. ": plas divèjans la")
    if divergent then differences = differences + 1 else ordinary = ordinary + 1 end
    trials = trials + 1
    return actual
end

-- Tout 455 konbinezon sa yo travèse zewo ak baryè +/-kM.
for k = -32, 32 do
    for d = -3, 3 do
        local x = B.mul(M, B.from(k)) + B.from(d)
        check(x, "mayaj " .. k .. "," .. d)
    end
end

-- PRNG antye, repwodiktib, san math.random ni valè float.
local state = 35791
local function nextDigit()
    state = (state * 48271) % 2147483647
    return state % 10
end
local function decimalDigits(length)
    local chars = {tostring(1 + (nextDigit() % 9))}
    for _ = 2, length do chars[#chars + 1] = tostring(nextDigit()) end
    return table.concat(chars)
end

for index = 1, 96 do
    local length = 1 + ((index * 37) % 140)
    local x = B.from(decimalDigits(length))
    if index % 2 == 0 then x = -x end
    check(x, "gwo antye " .. index)
    if index % 8 == 0 then
        local shift = M * B.from(11)
        local a = check(x + shift, "translasyon pozitif " .. index)
        local b = check(x - shift, "translasyon negatif " .. index)
        local original = S.legacySaveProbe(x)
        assert(B.compare(a, original) == 0 and B.compare(b, original) == 0,
            "Translasyon pa yon miltip M chanje rès legacy a")
        assert(B.compare(S.saveSpaghetti(x + shift), S.saveSpaghetti(x)) == 0)
        assert(B.compare(S.saveSpaghetti(x - shift), S.saveSpaghetti(x)) == 0)
    end
end

assert(trials == 575, "Kantite egzekisyon pwopriyete yo pa estab")
assert(differences == 65, "Kantite divèjans atann yo pa estab")
assert(ordinary == 510)
print("PASS pwopriyete Stage 2: " .. trials ..
      " ka, " .. differences .. " divèjans obligatwa")
