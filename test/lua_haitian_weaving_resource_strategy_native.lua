-- QA-only extraction of the exact selected month vector and a proof lower bound
-- for the existing memoized month-weaving counter. Never invokes weaving/fullDate.
local root = arg and arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path

local B = require("bigint")
local O = require("normative_oracle")
local Independent = require("lua_haitian_exact_month_composition_qa")

local checks = 0
local function check(ok, name)
    assert(ok, "WEAVING_STRATEGY_CHECK_FAILED: " .. name)
    checks = checks + 1
end

local qaRunSHA = assert(os.getenv("GITHUB_SHA"), "GITHUB_SHA_REQUIRED")
local witnessSHA = "6be926b109073a3161c41446026b8dbc739a5364"
check(#qaRunSHA == 40 and qaRunSHA:match("^[0-9a-f]+$"), "qa-run-sha-format")

-- Frozen year-selection receipt from the completed Native run on witnessSHA.
-- Re-running year5000 here would duplicate 85 expensive gate-gap evaluations.
local targetDay = -15017676
local year = {
    number = 5000,
    openGateIndex = 71,
    closeGateIndex = 82,
    openGateDay = -15018117,
    closeGateDay = -15012823,
}
local totalDays = year.closeGateDay - year.openGateDay
check(totalDays == 5294 and year.openGateDay < targetDay
      and targetDay <= year.closeGateDay, "locked-native-year-receipt")

-- Guard against accidentally crossing the resource boundary in this QA.
for _, name in ipairs({"buildYearStructure", "makeWeavingCounter",
                       "chooseMonthWeaving", "calendarDateIds", "calendarDate"}) do
    O[name] = function() error("UNEXPECTED_PRODUCTION_OR_WEAVING_CALL_" .. name, 0) end
end

local started = os.clock()
local function budget()
    if os.clock() - started > 90 then error("ABORT_MONTH_VECTOR_QA_CPU_90S", 0) end
    if collectgarbage("count") > 131072 then error("ABORT_MONTH_VECTOR_QA_HEAP_131072KIB", 0) end
end
debug.sethook(budget, "", 10000)

-- Reproduce the canonical month-count selection and exact month-length rank
-- from normative_oracle.lua:562-568, using the frozen Native year receipt.
-- The large composition count/unrank uses the independent exact formula; the
-- normative recursive implementation is differentially checked on bounded cases.
local structureSauce = O.sauce(targetDay, year.openGateDay + 1)
local minMonths = (totalDays + 122) // 123
local maxMonths = math.min(47, totalDays // 4)
check(minMonths == 44 and maxMonths == 47, "normative-month-interval")

local monthCountRank = O.chooseRank(
    O.askBowl(structureSauce, 3, O.SEAL_MONTH_COUNT),
    B.from(maxMonths - minMonths + 1)
)
local monthCountRankNumber = assert(B.toNumber(monthCountRank), "MONTH_COUNT_RANK_NOT_NUMBER")
local monthCount = minMonths + monthCountRankNumber - 1
check(monthCountRankNumber >= 1 and monthCountRankNumber <= 4, "month-count-rank")
check(monthCount >= 44 and monthCount <= 47, "selected-month-count")

-- Use the independently verified exact count/unrank for this real witness.
-- Differentially compare it with the normative recursive family on bounded
-- cases, avoiding the production recursion's large 5294-day search here.
local differentialCases = {{252, 3}, {500, 5}, {1000, 9}}
for caseIndex, fixture in ipairs(differentialCases) do
    local total, slots = fixture[1], fixture[2]
    local normative = O.makeBoundedCompositionFamily(total, slots, 4, 123)
    local expectedCount = normative.count()
    local independentCount = Independent.count(total, slots, 4, 123)
    check(B.compare(expectedCount, independentCount) == 0,
          "normative-count-differential-" .. caseIndex)
    local lastRank = expectedCount
    for _, rank in ipairs({B.from(1), lastRank}) do
        local expected = normative.unrank1(rank)
        local actual = Independent.unrank1(total, slots, 4, 123, rank)
        local same = #expected == #actual
        for i = 1, #expected do if expected[i] ~= actual[i] then same = false end end
        check(same, "normative-unrank-differential-" .. caseIndex .. "-" .. tostring(rank))
    end
end

local compositionCount = Independent.count(totalDays, monthCount, 4, 123)
local monthLengthRank = O.chooseRank(
    O.askBowl(structureSauce, 3, O.SEAL_MONTH_LENGTHS), compositionCount
)
local monthLengths = Independent.unrank1(
    totalDays, monthCount, 4, 123, monthLengthRank
)
check(#monthLengths == monthCount, "month-vector-cardinality")
local sum = 0
for i = 1, monthCount do
    check(monthLengths[i] >= 4 and monthLengths[i] <= 123,
          "normative-month-bound-" .. i)
    sum = sum + monthLengths[i]
end
check(sum == totalDays, "month-vector-sum")

-- Every memo state in the a=m,b=0 slice is reachable after opening all months,
-- then emitting 0..(n_i-2) interior occurrences of each month without closing.
-- The exact slice cardinality is therefore product_i (n_i-1).
local stateLowerBound = B.from(1)
for i = 1, monthCount do
    stateLowerBound = stateLowerBound * B.from(monthLengths[i] - 1)
end
local minimumStateLowerBound = B.pow(B.from(3), monthCount)
check(B.compare(stateLowerBound, minimumStateLowerBound) >= 0,
      "memo-state-lower-bound-3powm")

-- At least m! distinct valid weavings exist: open all months, place a fixed
-- sequence of all but one interior occurrence per month, permute one reserved
-- interior occurrence per month, then close all months in order. Since n_i>=4,
-- every month has enough interior occurrences. This also proves rank space > M.
local factorialLowerBound = B.from(1)
for i = 2, monthCount do factorialLowerBound = factorialLowerBound * B.from(i) end
check(B.compare(factorialLowerBound, O.M) > 0, "wide-rank-space-required")

local function csvNumbers(values)
    local out = {}
    for i = 1, #values do out[i] = tostring(values[i]) end
    return table.concat(out, ",")
end
local out = assert(io.open("lua-composition-resource-evidence/weaving_strategy.json", "wb"),
                   "CANNOT_OPEN_WEAVING_STRATEGY_RECEIPT")
out:write(string.format([[
{
  "projectId": "PC-BRANCH-LUA-HAITIAN",
  "qaRunSha": "%s",
  "yearWitnessSha": "%s",
  "targetDay": %d,
  "year": %d,
  "openGateIndex": %d,
  "closeGateIndex": %d,
  "openGateDay": %d,
  "closeGateDay": %d,
  "yearLength": %d,
  "monthCount": %d,
  "monthCountRank": "%s",
  "monthLengthRank": "%s",
  "compositionCount": "%s",
  "compositionSelectionOracle": "independent-inclusion-exclusion",
  "normativeRecursiveRealWitness": "NOT_RUN",
  "monthLengths": [%s],
  "memoStateLowerBound": "%s",
  "minimumStateLowerBound": "%s",
  "factorialWeavingLowerBound": "%s",
  "rankModulus": "%s",
  "normativeFeasibility": "VALID",
  "currentMemoDp": "RESOURCE_UNSUPPORTED_FOR_WITNESS",
  "weaving": "NOT_RUN",
  "fullDate": "NOT_RUN",
  "productionChange": "NONE"
}
]], qaRunSHA, witnessSHA, targetDay, year.number, year.openGateIndex,
    year.closeGateIndex, year.openGateDay, year.closeGateDay, totalDays,
    monthCount, tostring(monthCountRank), tostring(monthLengthRank),
    tostring(compositionCount), csvNumbers(monthLengths),
    tostring(stateLowerBound), tostring(minimumStateLowerBound),
    tostring(factorialLowerBound), tostring(O.M)))
out:close()

debug.sethook()
print(string.format("LUA_HAITIAN_WEAVING_RESOURCE_STRATEGY_NATIVE_PASS: %d/%d", checks, checks))
print("MONTH_WEAVING_RECEIPT: year=5000; day=-15017676; days=5294; months=" .. monthCount)
print("MONTH_LENGTHS: " .. csvNumbers(monthLengths))
print("MEMO_STATE_LOWER_BOUND: " .. tostring(stateLowerBound))
print("MEMO_STATE_MINIMUM_3_POW_M: " .. tostring(minimumStateLowerBound))
print("VALID_WEAVING_COUNT_LOWER_BOUND_M_FACTORIAL: " .. tostring(factorialLowerBound))
print("WIDE_RANK_REQUIRED: YES")
print("NORMATIVE_RECURSIVE_REAL_COMPOSITION: NOT_RUN")
print("WEAVING_NOT_INVOKED: YES; FULL_DATE: NOT_RUN; PRODUCTION: UNCHANGED")
