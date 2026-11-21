-- PC-BRANCH-LUA-HAITIAN: one held-out normative year-selection witness.
-- QA only. Explicitly forbidden here: month selection, composition, full-date conversion.
local root = arg[1] or "."
local day = tonumber(arg[2])
assert(day == -15017676 and math.type(day) == "integer",
       "HELDOUT_INPUT_REJECTED: exact calculation day -15017676 required")
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local sourceSha = assert(os.getenv("GITHUB_SHA"), "CI source SHA required")
assert(sourceSha:match("^[0-9a-f]+$") and #sourceSha == 40, "invalid source SHA")
local oldSamples = {
  [-15033432]=true, [-15032867]=true, [-15034166]=true,
  [-15033568]=true, [-15034351]=true, [-15033701]=true,
  [-15017677]=true, [-15017114]=true, [-15017465]=true, [-15016813]=true
}
assert(not oldSamples[day], "held-out sample overlaps accepted negatives")
local started, gapCalls = os.clock(), 0
local function budget()
  if os.clock() - started > 110 then error("ABORT_CPU_110S", 0) end
  if collectgarbage("count") > 131072 then error("ABORT_HEAP_131072KIB", 0) end
end
local pos, neg = O.positiveGateGap, O.negativeGateGap
local function gap_guard(fn, index)
  gapCalls = gapCalls + 1
  if gapCalls > 200 then error("ABORT_FRESH_GAPS_200", 0) end
  budget()
  return fn(index)
end
O.positiveGateGap = function(index) return gap_guard(pos, index) end
O.negativeGateGap = function(index) return gap_guard(neg, index) end
local rankCalls, candidateCount, rank1 = 0, nil, nil
local nativeChoose = O.chooseRank
O.chooseRank = function(stream, N)
  local answer = nativeChoose(stream, N)
  local count = assert(B.toNumber(N), "rank-choice count outside bounded Lua number")
  if count ~= 922 then
    rankCalls = rankCalls + 1
    assert(rankCalls == 1, "ABORT_MULTIPLE_YEAR_RANKS")
    candidateCount = count
    rank1 = assert(B.toNumber(answer), "selected rank outside bounded Lua number")
    assert(1 <= rank1 and rank1 <= candidateCount and candidateCount <= 18528,
           "ABORT_YEAR_RANK_DOMAIN")
  end
  return answer
end
local function integer(x, name)
  assert(type(x) == "number" and math.type(x) == "integer", "non-integer " .. name)
  return x
end
O.resetGateCache()
debug.sethook(budget, "", 10000)
print("PROJECT_ID: PC-BRANCH-LUA-HAITIAN")
print("QA_SCOPE: HELDOUT_YEAR5000_SELECTION_ONLY")
print("COMPOSITION_NOT_INVOKED: YES")
print("FULL_DATE: NOT_RUN")
local year = O.year5000(day)
assert(type(year) == "table" and year.number == 5000, "ABORT_NO_YEAR5000")
assert(rankCalls == 1 and candidateCount and rank1, "ABORT_NO_YEAR_RANK_RECEIPT")
local a = integer(year.openGateIndex, "openIndex")
local b = integer(year.closeGateIndex, "closeIndex")
local open = integer(year.openGateDay, "openDay")
local close = integer(year.closeGateDay, "closeDay")
local length, gaps = close - open, b - a
assert(a < b and gaps >= 6 and 252 <= length and length <= 5778,
       "ABORT_INVALID_YEAR_INTERVAL")
assert(open < day and day <= close, "ABORT_DAY_OUTSIDE_YEAR")
assert(O.ensureGateIndex(a) == open and O.ensureGateIndex(b) == close,
       "ABORT_GATE_BOUNDARY_MISMATCH")
local minMonths = math.max(3, (length + 122) // 123)
local reason = minMonths > 16 and "MIN_MONTHS_OVER_CAP" or "WITHIN_MONTH_CAP_NOT_COMPOSED"
budget()
debug.sethook()
local fields = {
  {"sourceSha", sourceSha}, {"day", day}, {"year", 5000},
  {"candidateCount", candidateCount}, {"rank1", rank1},
  {"openIndex", a}, {"closeIndex", b}, {"openDay", open},
  {"closeDay", close}, {"length", length}, {"gaps", gaps},
  {"minimumMonths", minMonths}, {"reason", reason}
}
local encoded = {"HELDOUT_RESULT"}
for _, row in ipairs(fields) do
  encoded[#encoded+1] = row[1] .. "=" .. tostring(row[2])
end
print(table.concat(encoded, "|"))
print("GAP_CALLS: " .. gapCalls)
print(string.format("LUA_CPU_SECONDS: %.6f", os.clock()-started))
print("QA_FINAL: COMPLETE")
