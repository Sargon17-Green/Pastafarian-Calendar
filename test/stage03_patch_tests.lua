local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local SavePatch = require("save_patch")
local LegacySave = require("legacy_save")
local M = O.M

local trials, correctedCount = 0, 0
local function check(value, label)
    local x = B.from(value)
    local inputBefore = tostring(x)
    local legacy, legacyContext = S.legacySaveProbe(x)
    local corrected, ctx = S.savePatchProbe(x)
    local public = S.saveSpaghetti(x)
    local direct = SavePatch.savePatch(x)
    local expected = O.SAVE(x)
    assert(B.compare(corrected, expected) == 0, label .. ": chemen PATCH 01")
    assert(B.compare(public, expected) == 0, label .. ": chemen piblik la")
    assert(B.compare(direct, expected) == 0, label .. ": savePatch dirèk")
    assert(B.compare(legacy, LegacySave.oldRemainder(x)) == 0, label .. ": legacy chanje")
    assert(tostring(x) == inputBefore, label .. ": antre a te modifye")
    assert(B.compare(corrected, 1) >= 0 and B.compare(corrected, M) <= 0)
    local zero = legacy:isZero()
    assert((B.compare(legacy, expected) ~= 0) == zero, label .. ": pozisyon ansyen defo a")
    if zero then correctedCount = correctedCount + 1 end
    assert(ctx ~= legacyContext and ctx.semanticState ~= legacyContext.semanticState)
    assert(ctx.status == "PATCH_RETURNED" and ctx.mode == "STAGE_03_PATCH_01")
    assert(ctx.phase == "PATCH_SAVE" and ctx.currentHandler == "SAVE_PATCH")
    assert(ctx.previousHandler == "LEGACY_SAVE")
    assert(#ctx.branchTrace == 2 and ctx.branchTrace[1] == "LEGACY_SAVE"
           and ctx.branchTrace[2] == "SAVE_PATCH")
    assert(ctx.commitToken == 2 and ctx.pendingSemanticState == nil
           and ctx.rollbackSnapshot == nil)
    assert(ctx.semanticState.inputDecimal == inputBefore)
    assert(ctx.semanticState.legacyResultDecimal == tostring(legacy))
    assert(ctx.semanticState.resultDecimal == tostring(expected))
    assert(ctx.semanticState.correction == (zero and "ZERO_TO_M" or "UNCHANGED"))
    assert(ctx.metrics["legacy.save.calls"] == 1 and ctx.metrics["save.patch.calls"] == 1)
    assert(ctx.metrics["save.patch.zeroFixes"] == (zero and 1 or nil))
    assert(#ctx.diagnostics == 2 and ctx.diagnostics[1].code == "REGULAR_MOD_INSTEAD_OF_SAVE")
    assert(ctx.diagnostics[2].code == (zero and "PATCH_01_ZERO_TO_M" or "PATCH_01_PASSTHROUGH"))
    assert(legacyContext.status == "LEGACY_RETURNED" and legacyContext.commitToken == 1)
    trials = trials + 1
end

-- 903 ka sou limit miltip M yo, pozitif kou negatif.
for k = -64, 64 do
    for offset = -3, 3 do
        check(M * B.from(k) + B.from(offset), "baryè " .. k .. "," .. offset)
    end
end
assert(trials == 903 and correctedCount == 129)

-- Valè ki depase 256 bit; diferan siy ak translasyon pa M.
local huge = B.from("1" .. string.rep("0", 110))
for _, x in ipairs({huge, -huge, huge + M, -huge - M,
                     huge * M, -(huge * M), B.from(math.mininteger), B.from(math.maxinteger)}) do
    check(x, "limit long " .. tostring(x):sub(1, 18))
    local base = S.saveSpaghetti(x)
    assert(B.compare(S.saveSpaghetti(x + M * B.from(41)), base) == 0)
    assert(B.compare(S.saveSpaghetti(x - M * B.from(41)), base) == 0)
end

assert(select("#", S.saveSpaghetti(M)) == 1)
assert(select("#", S.savePatchProbe(M)) == 2)
assert(select("#", S.legacySaveProbe(M)) == 2)
local _, private = S.savePatchProbe(M)
private.semanticState.resultDecimal = "999"
private.branchTrace[1] = "CHANJE"
private.diagnostics[1].code = "CHANJE"
local _, again = S.savePatchProbe(M)
assert(again.semanticState.resultDecimal == tostring(M))
assert(again.branchTrace[1] == "LEGACY_SAVE")
assert(again.diagnostics[1].code == "REGULAR_MOD_INSTEAD_OF_SAVE")
for _, bad in ipairs({"", "1.5", "mal", {}, true, 0.5}) do
    assert(not pcall(S.saveSpaghetti, bad), "Antre pa valab te aksepte")
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS PATCH 01: " .. trials .. " ka, " .. correctedCount .. " koreksyon rès zewo")
