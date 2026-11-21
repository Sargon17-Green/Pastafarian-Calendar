-- Targeted, bounded Lua 5.3 QA for selected-year -> composition resource boundary.
-- PROJECT_ID: PC-BRANCH-LUA-HAITIAN
-- No changes to test/normative_oracle.lua, no production integration, no full date.
local root = arg and arg[1] or "."
local mode = arg and arg[2] or "selftest-only"
assert(mode == "selftest-only" or mode == "native", "INVALID_MODE")
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path

local A = require("lua_haitian_composition_resource_adapter")
local nchecks = 0
local function check(value, name)
    assert(value, "QA_CHECK_FAILED: " .. name)
    nchecks = nchecks + 1
end
local function synthetic(length)
    return {number = 5000, openGateIndex = 1, closeGateIndex = 9,
            openGateDay = 0, closeGateDay = length}
end
local function spy()
    error("QA_UNEXPECTED_COMPOSITION_INVOKED", 0)
end

local frozen = synthetic(5294)
local r = A.preflight(frozen, 16, spy)
check(r.status == "RESOURCE_REJECT", "witness-resource-rejection")
check(not r.admitted and not r.called, "witness-zero-calls")
check(r.minMonths == 44 and r.maxMonths == 47 and r.length == 5294, "witness-normative-interval")
check(A.preflight(synthetic(1968), 16).status == "ADMISSIBLE_TO_NEXT_RESOURCE_GATE",
      "cap-boundary-1968-admitted")
check(A.preflight(synthetic(1969), 16, spy).status == "RESOURCE_REJECT",
      "cap-boundary-1969-rejected")
check(A.preflight(synthetic(251), 16).status == "INVALID_YEAR_LENGTH",
      "normative-lower-invalid")
check(A.preflight(synthetic(5779), 16).status == "INVALID_YEAR_LENGTH",
      "normative-upper-invalid")
check(A.preflight(synthetic(5778), 47).status == "ADMISSIBLE_TO_NEXT_RESOURCE_GATE",
      "normative-47-not-resource-rejected")
check(A.preflight({number=5000,openGateIndex=1,closeGateIndex=6,
                   openGateDay=0,closeGateDay=1000},16).status == "INVALID_YEAR_ENVELOPE",
      "six-gap-envelope")
local called = 0
r = A.preflight(frozen, 47, function(y)
    called = called + 1
    return y.closeGateDay - y.openGateDay
end)
check(r.admitted and r.called and r.downstreamResult == 5294 and called == 1,
      "cap47-admission-only-with-sentinel")
for _, bad in ipairs({0, 48, -1}) do
    local ok = pcall(A.preflight, frozen, bad, spy)
    check(not ok, "invalid-cap-" .. bad)
end
check(A.preflight(nil, 16).status == "INVALID_YEAR_ENVELOPE", "nil-year-reject")
check(not pcall(A.preflight, frozen, 16, "not-a-function"), "bad-downstream-reject")

print(string.format("QA_BOUNDARY_ADAPTER_SELFTEST_PASS: %d/%d", nchecks, nchecks))
print("QA_ONLY=YES; NORMATIVE_MAX_MONTHS=47; MONTH_CAP=16_NOT_NORMATIVE")

if mode == "selftest-only" then
    print("LUA_NATIVE_YEAR_SELECTION: NOT_RUN")
    print("COMPOSITION_NOT_INVOKED: YES")
    print("FULL_DATE: NOT_RUN")
    return
end

local sourceSHA = assert(os.getenv("GITHUB_SHA"), "GITHUB_SHA_REQUIRED")
assert(#sourceSHA == 40 and sourceSHA:match("^[0-9a-f]+$"),
       "GITHUB_SHA_INVALID")
local B = require("bigint")
local O = require("normative_oracle")
assert(O.YEAR_MIN_DAYS == 252 and O.YEAR_MAX_DAYS == 5778
       and O.MIN_MONTHS == 3 and O.MAX_MONTHS == 47
       and O.MIN_MONTH_DAYS == 4 and O.MAX_MONTH_DAYS == 123,
       "NORMATIVE_CONSTANTS_DRIFT")
local targetDay = -15017676
local started, gaps, rankCalls = os.clock(), 0, 0
local count, rank = nil, nil
local function budget()
    if os.clock() - started > 110 then error("ABORT_CPU_110S", 0) end
    if collectgarbage("count") > 131072 then error("ABORT_HEAP_131072KIB", 0) end
end
local pos, neg = O.positiveGateGap, O.negativeGateGap
local function boundedGap(fn, k)
    gaps = gaps + 1
    assert(gaps <= 200, "ABORT_FRESH_GAPS_200")
    budget()
    return fn(k)
end
O.positiveGateGap = function(k) return boundedGap(pos, k) end
O.negativeGateGap = function(k) return boundedGap(neg, k) end
local oldChoose = O.chooseRank
O.chooseRank = function(stream, total)
    local chosen = oldChoose(stream, total)
    local n = B.toNumber(total)
    if n ~= 922 then
        rankCalls = rankCalls + 1
        assert(rankCalls == 1, "ABORT_MULTIPLE_YEAR_RANKS")
        count = n
        rank = B.toNumber(chosen)
    end
    return chosen
end

O.resetGateCache()
debug.sethook(budget, "", 10000)
local year = O.year5000(targetDay)
budget()
check(rankCalls == 1 and count == 69 and rank == 56, "native-rank-receipt")
check(year.number == 5000 and year.openGateIndex == 71 and year.closeGateIndex == 82,
      "native-gate-index-receipt")
check(year.openGateDay == -15018117 and year.closeGateDay == -15012823,
      "native-gate-day-receipt")
check(year.openGateDay < targetDay and targetDay <= year.closeGateDay,
      "native-day-contained")

-- Install traps for both cutlet and month composition, weaving and full date.
local probeNames = {"buildYearStructure", "makeCutletPartitionFamily",
                    "makeBoundedCompositionFamily", "makeWeavingCounter",
                    "chooseMonthWeaving", "calendarDateIds", "calendarDate"}
local probeCount = {}
for _, method in ipairs(probeNames) do
    probeCount[method] = 0
    O[method] = function(...)
        probeCount[method] = probeCount[method] + 1
        error("UNEXPECTED_REFERENCE_CALL_" .. method, 0)
    end
end

-- The adapter's only possible compose path is wired to the actual oracle builder.
-- The resource rejection MUST prevent that callback and every downstream probe.
local result = A.preflight(year, 16, function(y)
    return O.buildYearStructure(targetDay, y)
end)
check(result.status == "RESOURCE_REJECT" and not result.admitted
      and not result.called, "native-guard-reject-before-build")
check(result.length == 5294 and result.minMonths == 44
      and result.maxMonths == 47 and result.cap == 16, "native-month-bounds")
for _, method in ipairs(probeNames) do
    check(probeCount[method] == 0, "native-no-call-" .. method)
end
debug.sethook()
print(string.format("SELECTED_YEAR_RECEIPT|sourceSha=%s|day=%d|year=%d|candidateCount=%d|rank1=%d|openIndex=%d|closeIndex=%d|openDay=%d|closeDay=%d|length=%d|minMonths=%d|maxMonths=%d|qaCap=16|status=%s",
    sourceSHA, targetDay, year.number, count, rank,
    year.openGateIndex, year.closeGateIndex, year.openGateDay,
    year.closeGateDay, result.length, result.minMonths, result.maxMonths, result.status))
print("NATIVE_QA_RESOURCE_REJECT_BEFORE_COMPOSITION: PASS")
print("COMPOSITION_SPY_CALLS: 0")
print("COMPOSITION_NOT_INVOKED: YES")
print("WEAVING_NOT_INVOKED: YES")
print("FULL_DATE: NOT_RUN")
print(string.format("GAP_CALLS: %d", gaps))
print(string.format("LUA_CPU_SECONDS: %.6f", os.clock() - started))
print(string.format("QA_BOUNDARY_NATIVE_ASSERTIONS_PASS: %d/%d", nchecks, nchecks))
