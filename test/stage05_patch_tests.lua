local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local Patch = require("day_tag_patch")
local Old = require("legacy_day_tag")
local F = O.FOUNDATION_DAY
local trials, oddFixes, guardChecks = 0, 0, 0

local function check(day, label, oracleSafe)
    local old, oldCtx = S.legacyDayTagProbe(day)
    local patched, ctx = S.dayTagPatchProbe(day)
    local public = S.dayTagSpaghetti(day)
    local direct = Patch.dayTagWithFoundationScar(day)
    local expected = day >= F and B.add(old, 1) or old
    assert(B.compare(patched, expected) == 0, label .. ": PATCH 02")
    assert(B.compare(public, expected) == 0, label .. ": chemen piblik")
    assert(B.compare(direct, expected) == 0, label .. ": fonksyon patch")
    assert(B.compare(Old.oldDayTag(day), old) == 0, label .. ": legacy chanje")
    assert(B.compare(patched, 1) >= 0, label .. ": jou a dwe pozitif")
    if oracleSafe then
        assert(B.compare(patched, O.dayCount(day)) == 0, label .. ": oracle normatif")
    end
    local parity = B.mod(patched, 2)
    assert(B.compare(parity, day >= F and 1 or 0) == 0, label .. ": parite")
    assert(ctx ~= oldCtx and ctx.semanticState ~= oldCtx.semanticState)
    assert(ctx.mode == "STAGE_05_PATCH_02" and ctx.phase == "PATCH_DAY_TAG")
    assert(ctx.status == "PATCH_DAY_TAG_RETURNED")
    assert(ctx.currentHandler == "DAY_TAG_PATCH" and ctx.previousHandler == "LEGACY_DAY_TAG")
    assert(#ctx.branchTrace == 2 and ctx.branchTrace[1] == "LEGACY_DAY_TAG"
           and ctx.branchTrace[2] == "DAY_TAG_PATCH")
    assert(ctx.commitToken == 2 and ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    assert(ctx.semanticState.inputDayDecimal == tostring(day))
    assert(ctx.semanticState.legacyResultDecimal == tostring(old))
    assert(ctx.semanticState.resultDecimal == tostring(expected))
    assert(ctx.semanticState.correction == (day >= F and "ODD_PARITY" or "UNCHANGED"))
    assert(ctx.semanticState.foundationGuard == (day == F))
    assert(ctx.metrics["legacy.daytag.calls"] == 1)
    assert(ctx.metrics["daytag.patch.calls"] == 1)
    assert(ctx.metrics["daytag.patch.oddCorrections"] == (day >= F and 1 or nil))
    assert(ctx.metrics["daytag.patch.foundationGuardChecks"] == (day == F and 1 or nil))
    assert(ctx.metrics["daytag.patch.decimalAnswers"][1] == tostring(expected))
    assert(#ctx.diagnostics == 2)
    assert(ctx.diagnostics[1].code == "EVEN_DAY_TAG_ON_FOUNDATION_AND_AFTER")
    assert(ctx.diagnostics[2].code == (day >= F and "PATCH_02_ADD_ODD_PARITY" or "PATCH_02_PASSTHROUGH"))
    assert(ctx.diagnostics[2].foundationGuardPresent == true)
    assert(ctx.diagnostics[2].original == tostring(old))
    assert(ctx.diagnostics[2].corrected == tostring(expected))
    assert(oldCtx.commitToken == 1 and oldCtx.status == "LEGACY_DAY_TAG_RETURNED")
    if day >= F then oddFixes = oddFixes + 1 end
    if day == F then guardChecks = guardChecks + 1 end
    trials = trials + 1
end

-- 2001 jou konsèkítif toude bò jou Fondasyon an.
for offset = -1000, 1000 do
    check(F + offset, "jou " .. offset, true)
end
assert(trials == 2001 and oddFixes == 1001 and guardChecks == 1)

-- 320 jou detèminis san flote; tès sa yo endepandan de echantiyon Stage 4.
local state = 14321
for index = 1, 320 do
    state = (state * 48271) % 2147483647
    local distance = (state % 40000001) - 20000000
    check(F + distance, "echantiyon " .. index, true)
end

-- BigInt dwe travay nan limit natif Lua: oracle dayCount pa sèvi la.
for _, day in ipairs({math.mininteger, math.mininteger + 1, math.maxinteger - 1, math.maxinteger}) do
    check(day, "limit Lua " .. tostring(day), false)
end
assert(trials == 2325)

assert(select("#", S.dayTagSpaghetti(F)) == 1)
assert(select("#", S.dayTagPatchProbe(F)) == 2)
assert(select("#", S.legacyDayTagProbe(F)) == 2)
local _, first = S.dayTagPatchProbe(F)
first.semanticState.resultDecimal = "999"
first.diagnostics[1].code = "CHANJE"
first.metrics["legacy.daytag.calls"] = 111
first.branchTrace[1] = "CHANJE"
local _, next = S.dayTagPatchProbe(F)
assert(next.semanticState.resultDecimal == "1")
assert(next.diagnostics[1].code == "EVEN_DAY_TAG_ON_FOUNDATION_AND_AFTER")
assert(next.metrics["legacy.daytag.calls"] == 1)
assert(next.branchTrace[1] == "LEGACY_DAY_TAG")
for _, bad in ipairs({"", "-1", true, {}, 2.5}) do
    assert(not pcall(S.dayTagSpaghetti, bad), "Antre jou ki pa valab aksepte")
    assert(not pcall(S.legacyDayTagProbe, bad), "Antre legacy ki pa valab aksepte")
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS PATCH 02: " .. trials .. " jou, " .. oddFixes ..
      " koreksyon parite, " .. guardChecks .. " verifikasyon guard Fondasyon")
