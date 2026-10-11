local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local F = O.FOUNDATION_DAY

assert(select("#", S.dayTagSpaghetti(F)) == 1)
assert(select("#", S.legacyDayTagProbe(F)) == 2)
local checks = {
    {"BEFORE_2", F-2, "4", false},
    {"BEFORE_1", F-1, "2", false},
    {"FOUNDATION", F, "0", true},
    {"AFTER_1", F+1, "2", true},
    {"AFTER_2", F+2, "4", true},
    {"AFTER_20", F+20, "40", true}
}
for _, x in ipairs(checks) do
    local name, day, wrong, differs = x[1], x[2], x[3], x[4]
    local observed, context = S.legacyDayTagProbe(day)
    local public = S.dayTagSpaghetti(day)
    local normative = B.from(O.dayCount(day))
    assert(tostring(observed) == wrong, name .. ": rès istorik la")
    assert(B.compare(observed, public) == 0, name .. ": dispatcher pa aktive")
    assert((B.compare(observed, normative) ~= 0) == differs, name .. ": move diferans la")
    assert(context.phase == "LEGACY_DAY_TAG" and context.mode == "STAGE_04_DISCOVERY_02")
    assert(context.status == "LEGACY_DAY_TAG_RETURNED")
    assert(context.currentHandler == "LEGACY_DAY_TAG")
    assert(context.commitToken == 1 and context.pendingSemanticState == nil)
    assert(context.rollbackSnapshot == nil)
    assert(#context.branchTrace == 1 and context.branchTrace[1] == "LEGACY_DAY_TAG")
    assert(context.metrics["legacy.daytag.calls"] == 1)
    assert(context.metrics["legacy.daytag.decimalAnswers"][1] == wrong)
    assert(context.semanticState.inputDayDecimal == tostring(day))
    assert(context.semanticState.foundationDecimal == tostring(F))
    assert(context.semanticState.resultDecimal == wrong)
    assert(context.semanticState.source == "TWICE_ABSOLUTE_FOUNDATION_DISTANCE")
    assert(#context.diagnostics == 1 and context.diagnostics[1].code ==
           "EVEN_DAY_TAG_ON_FOUNDATION_AND_AFTER")
    print("TRACE " .. name .. " legacy=" .. wrong .. " normative=" .. tostring(normative) ..
          (differs and " DIVERGENCE" or " MATCH"))
end

-- Modifye yon kontèks pa dwe chanje sa yon lòt invocation genyen.
local _, a = S.legacyDayTagProbe(F)
local _, b = S.legacyDayTagProbe(F+1)
a.semanticState.resultDecimal = "999"
a.metrics["legacy.daytag.calls"] = 100
a.diagnostics[1].code = "CHANJE"
a.branchTrace[1] = "CHANJE"
assert(b.semanticState.resultDecimal == "2")
assert(b.metrics["legacy.daytag.calls"] == 1)
assert(b.diagnostics[1].code == "EVEN_DAY_TAG_ON_FOUNDATION_AND_AFTER")
assert(b.branchTrace[1] == "LEGACY_DAY_TAG")
for _, value in ipairs({"", "1", 2.5, true, {}}) do
    assert(not pcall(S.dayTagSpaghetti, value))
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS tras Discovery 02: izolasyon, dispatcher ak diferans jou")
