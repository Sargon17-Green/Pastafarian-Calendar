-- PC-BRANCH-LUA-HAITIAN: bounded genuine year-interval static admission only.
-- This intentionally stops before reference month composition or weaving.
local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path

local B = require("bigint")
local O = require("normative_oracle")

local OFFSETS = {500,1500,2500,3500,4500,5500,6500,7500,8500,9500,10500,11500}
local MAX_GATE_GAP_EVALUATIONS = 200
local MAX_CPU_SECONDS = 55
local MAX_HEAP_KIB = 128 * 1024
local MAX_MONTHS = 16
local MAX_COMPOSITION_STATES = 20000

local started = os.clock()
local gateGapEvaluations = 0

local function checkBudget()
    if os.clock() - started > MAX_CPU_SECONDS then
        error("ABORT_CPU", 0)
    end
    if collectgarbage("count") > MAX_HEAP_KIB then
        error("ABORT_HEAP", 0)
    end
end

local positiveGateGap = O.positiveGateGap
local negativeGateGap = O.negativeGateGap

O.positiveGateGap = function(n)
    gateGapEvaluations = gateGapEvaluations + 1
    if gateGapEvaluations > MAX_GATE_GAP_EVALUATIONS then
        error("ABORT_GATE_GAP_CAP", 0)
    end
    checkBudget()
    return positiveGateGap(n)
end

O.negativeGateGap = function(n)
    gateGapEvaluations = gateGapEvaluations + 1
    if gateGapEvaluations > MAX_GATE_GAP_EVALUATIONS then
        error("ABORT_GATE_GAP_CAP", 0)
    end
    checkBudget()
    return negativeGateGap(n)
end

local function toNumber(x)
    local n = B.toNumber(x)
    assert(n ~= nil and math.type(n) == "integer", "BigInt rank does not fit a Lua integer")
    return n
end

local function compositionStateUpperBound(total, slots)
    local states = 0
    for k = 1, slots do
        local low = 4 * k
        local high = math.min(total, 123 * k)
        if high >= low then
            states = states + high - low + 1
        end
    end
    return states
end

local function recordNoInterval(offset, calculationDay)
    print(table.concat({
        "REAL_YEAR_CANDIDATE",
        "anchorOffset=" .. offset,
        "calculationDay=" .. calculationDay,
        "targetDay=" .. calculationDay,
        "admitted=0",
        "reason=NO_YEAR_CANDIDATE"
    }, "|"))
end

local function recordLongInterval(offset, calculationDay, y, length, gaps)
    local minimumMonths = math.max(3, (length + 122) // 123)
    print(table.concat({
        "REAL_YEAR_CANDIDATE",
        "anchorOffset=" .. offset,
        "calculationDay=" .. calculationDay,
        "targetDay=" .. calculationDay,
        "openGateIndex=" .. y.openGateIndex,
        "closeGateIndex=" .. y.closeGateIndex,
        "openGateDay=" .. y.openGateDay,
        "closeGateDay=" .. y.closeGateDay,
        "yearLength=" .. length,
        "gateGaps=" .. gaps,
        "minimumMonths=" .. minimumMonths,
        "selectedMonthCount=NOT_COMPUTED",
        "compositionStateUpper=NOT_COMPUTED",
        "admitted=0",
        "reason=MIN_MONTHS_OVER_CAP"
    }, "|"))
end

local attempted = 0
local admitted = nil

O.resetGateCache()
debug.sethook(checkBudget, "", 10000)

for _, offset in ipairs(OFFSETS) do
    checkBudget()
    attempted = attempted + 1

    local calculationDay = O.FOUNDATION_DAY + offset
    assert(math.type(calculationDay) == "integer")

    local ok, y = pcall(O.year5000, calculationDay)
    if not ok then
        local message = tostring(y)
        if message:find("Pa gen kandida pou ane 5000", 1, true) then
            recordNoInterval(offset, calculationDay)
        else
            error(message, 0)
        end
    else
        assert(type(y) == "table" and y.number == 5000, "invalid year5000 result")
        for _, key in ipairs({"openGateIndex","closeGateIndex","openGateDay","closeGateDay"}) do
            assert(math.type(y[key]) == "integer", "noninteger year boundary: " .. key)
        end

        local length = y.closeGateDay - y.openGateDay
        local gaps = y.closeGateIndex - y.openGateIndex
        assert(gaps >= 6, "year uses fewer than six gate gaps")
        assert(O.YEAR_MIN_DAYS <= length and length <= O.YEAR_MAX_DAYS, "year length outside normative bounds")
        assert(y.openGateDay < calculationDay and calculationDay <= y.closeGateDay, "anchor is outside selected year")
        assert(O.ensureGateIndex(y.openGateIndex) == y.openGateDay, "open gate mismatch")
        assert(O.ensureGateIndex(y.closeGateIndex) == y.closeGateDay, "close gate mismatch")

        if length > MAX_MONTHS * 123 then
            recordLongInterval(offset, calculationDay, y, length, gaps)
        else
            local minimumMonths = math.max(3, (length + 122) // 123)
            local maximumMonths = math.min(47, length // 4)
            assert(minimumMonths <= maximumMonths, "invalid normative month-count interval")

            -- Exact pre-composition selection used by buildYearStructure; no composition call.
            local structureSauce = O.sauce(calculationDay, y.openGateDay + 1)
            local stream = O.askBowl(structureSauce, 3, O.SEAL_MONTH_COUNT)
            local monthCount = minimumMonths + toNumber(O.chooseRank(stream, B.from(maximumMonths - minimumMonths + 1))) - 1
            local stateUpper = compositionStateUpperBound(length, monthCount)

            local staticallyAdmitted = monthCount <= MAX_MONTHS and stateUpper <= MAX_COMPOSITION_STATES
            local reason = "ADMITTED"
            if monthCount > MAX_MONTHS then
                reason = "SELECTED_MONTH_COUNT_OVER_CAP"
            elseif stateUpper > MAX_COMPOSITION_STATES then
                reason = "COMPOSITION_STATE_BOUND_OVER_CAP"
            end

            print(table.concat({
                "REAL_YEAR_CANDIDATE",
                "anchorOffset=" .. offset,
                "calculationDay=" .. calculationDay,
                "targetDay=" .. calculationDay,
                "openGateIndex=" .. y.openGateIndex,
                "closeGateIndex=" .. y.closeGateIndex,
                "openGateDay=" .. y.openGateDay,
                "closeGateDay=" .. y.closeGateDay,
                "yearLength=" .. length,
                "gateGaps=" .. gaps,
                "minimumMonths=" .. minimumMonths,
                "maximumMonths=" .. maximumMonths,
                "selectedMonthCount=" .. monthCount,
                "compositionStateUpper=" .. stateUpper,
                "admitted=" .. (staticallyAdmitted and "1" or "0"),
                "reason=" .. reason
            }, "|"))

            if staticallyAdmitted then
                admitted = {
                    anchorOffset = offset,
                    calculationDay = calculationDay,
                    targetDay = calculationDay,
                    year = y.number,
                    openGateIndex = y.openGateIndex,
                    closeGateIndex = y.closeGateIndex,
                    openGateDay = y.openGateDay,
                    closeGateDay = y.closeGateDay,
                    yearLength = length,
                    gateGaps = gaps,
                    monthCount = monthCount,
                    compositionStateUpper = stateUpper
                }
                break
            end
        end
    end
end

checkBudget()
debug.sethook()

if admitted then
    print("REAL_YEAR_STATIC_ADMISSION_PASS: 1/1")
    print(table.concat({
        "REAL_YEAR_ADMITTED_WITNESS",
        "anchorOffset=" .. admitted.anchorOffset,
        "calculationDay=" .. admitted.calculationDay,
        "targetDay=" .. admitted.targetDay,
        "year=" .. admitted.year,
        "openGateIndex=" .. admitted.openGateIndex,
        "closeGateIndex=" .. admitted.closeGateIndex,
        "openGateDay=" .. admitted.openGateDay,
        "closeGateDay=" .. admitted.closeGateDay,
        "yearLength=" .. admitted.yearLength,
        "gateGaps=" .. admitted.gateGaps,
        "monthCount=" .. admitted.monthCount,
        "compositionStateUpper=" .. admitted.compositionStateUpper
    }, "|"))
else
    print("REAL_YEAR_STATIC_ADMISSION_NONE: 0/" .. attempted)
end

print("REAL_YEAR_INTERVAL_DISCOVERY_COMPLETED: " .. attempted .. "/" .. #OFFSETS)
print("GATE_GAP_EVALUATIONS: " .. gateGapEvaluations)
print("COMPOSITION_NOT_INVOKED: YES")
print("SCOPE=REAL_YEAR_INTERVAL_STATIC_DISCOVERY_ONLY; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN")
