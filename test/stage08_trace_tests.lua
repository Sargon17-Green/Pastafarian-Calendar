local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local S = require("spaghetti")
local L = require("legacy_stones")
local B = require("bigint")
local names = {"w", "b", "s", "m", "r"}
local values = {"378", "1434", "3780", "9932", "25047"}
local seed = L.seed()
local seedBefore = {}
for _, name in ipairs(names) do seedBefore[name] = tostring(seed[name]) end
assert(select("#", S.stoneSpaghetti(2, seed)) == 1)
assert(select("#", S.legacyStoneProbe(2, seed)) == 2)
local result, context = S.legacyStoneProbe(2, seed)
for pos, name in ipairs(names) do
    assert(tostring(result[name]) == values[pos], name .. " move rezilta")
    assert(tostring(seed[name]) == seedBefore[name], "Wout API a chanje antre moun nan")
    assert(context.semanticState[name] == values[pos])
    assert(context.semanticState["old" .. string.upper(name)] == seedBefore[name])
end
assert(context.mode == "STAGE_08_DISCOVERY_04")
assert(context.phase == "LEGACY_STONES" and context.currentHandler == "LEGACY_STONES")
assert(context.status == "LEGACY_STONES_RETURNED" and context.commitToken == 1)
assert(context.pendingSemanticState == nil and context.rollbackSnapshot == nil)
assert(#context.branchTrace == 1 and context.branchTrace[1] == "LEGACY_STONES")
assert(context.metrics["legacy.stones.calls"] == 1)
assert(context.metrics["legacy.stones.lastBarley"][1] == "1434")
assert(#context.diagnostics == 1 and context.diagnostics[1].code == "SEQUENTIAL_REUSE_OF_NEW_STONES")
assert(context.semanticState.source == "SEQUENTIAL_MUTATION")

-- Legacy dirèk la dwe modifye menm tablo li te resevwa a.
local mutable = L.seed()
local same = L.mutateStonesWrong(2, mutable)
assert(same == mutable and tostring(mutable.b) == "1434")

-- Chanjman sou yon rezilta dyagnostik pa dwe travèse nan apèl endepandan.
result.w = B.from(999)
context.semanticState.w = "999"
context.metrics["legacy.stones.calls"] = 99
context.diagnostics[1].code = "CHANJE"
context.branchTrace[1] = "CHANJE"
local second, secondContext = S.legacyStoneProbe(2, seed)
assert(tostring(second.w) == "378" and secondContext.semanticState.w == "378")
assert(secondContext.metrics["legacy.stones.calls"] == 1)
assert(secondContext.diagnostics[1].code == "SEQUENTIAL_REUSE_OF_NEW_STONES")
assert(secondContext.branchTrace[1] == "LEGACY_STONES")

for _, badIndex in ipairs({0,1,47,48,2.5,"2",true}) do
    assert(not pcall(S.stoneSpaghetti, badIndex, seed), "Endis ilegal aksepte")
end
for _, malformed in ipairs({{}, {w=1,b=2,s=3,m=4}, {w="1.5",b=2,s=3,m=4,r=5}, false}) do
    assert(not pcall(S.stoneSpaghetti, 2, malformed), "Tablo ilegal aksepte")
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS tras Stage 8: 5 wòch, alias legacy, dispatcher, reentrancy, validasyon")
