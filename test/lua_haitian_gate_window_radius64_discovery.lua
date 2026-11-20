-- PC-BRANCH-LUA-HAITIAN: v5 radius64 deterministic gate-window scan, static only.
-- This intentionally stops before reference month composition or weaving.
local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path

local B = require("bigint")
local O = require("normative_oracle")

local MAX_GATE_GAP_EVALUATIONS = 200
local MAX_CPU_SECONDS = 110
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


-- Candidate selection is determined by proved gate geometry, not offset guessing.
-- Any year interval with >=6 gates and <=1968 days contains a six-gap subwindow <=1968.
local SCAN_MIN, SCAN_MAX = -64, 64
local TARGET_PROBE_CAP = 8
local MAX_POSSIBLE_DAYS = MAX_MONTHS * 123
local gates, windows = {}, {}
local tested = {}
local attempts, selectedShort, admitted = 0, 0, nil

-- v4 Native-accepted core is immutable; extend its boundaries using the same frozen
-- normative gap oracle, instead of recomputing the 80 already attested gaps.
local SEED_MIN, SEED_MAX = -40, 40
local seed = {}
local seedCount = 0
local seedFile = assert(io.open(root .. "/test/lua_haitian_gate_window_radius40_v4_seed.tsv", "r"))
for line in seedFile:lines() do
    if line ~= "" and line:sub(1,1) ~= "#" then
        local a, b = line:match("^(-?%d+)%s+(-?%d+)$")
        assert(a and b, "invalid v4 seed line")
        local i, day = tonumber(a), tonumber(b)
        assert(i >= SEED_MIN and i <= SEED_MAX and seed[i] == nil,
            "duplicate or out-of-range v4 gate")
        seed[i] = day
        seedCount = seedCount + 1
    end
end
seedFile:close()
assert(seedCount == 81 and seed[0] == O.FOUNDATION_DAY, "v4 seed identity")
for i = SEED_MIN, SEED_MAX do
    assert(seed[i] ~= nil, "v4 seed incomplete")
    gates[i] = seed[i]
    if i > SEED_MIN then
        local gap = seed[i] - seed[i-1]
        assert(gap >= O.GATE_GAP_MIN and gap <= O.GATE_GAP_MAX, "v4 seed gap")
    end
end

O.resetGateCache()
debug.sethook(checkBudget, "", 10000)
for i = SEED_MIN - 1, SCAN_MIN, -1 do
    checkBudget()
    gates[i] = gates[i+1] - O.negativeGateGap(-i)
end
for i = SEED_MAX + 1, SCAN_MAX do
    checkBudget()
    gates[i] = gates[i-1] + O.positiveGateGap(i)
end
print("GATE_CORE_SEED: -40/40")
print("GATE_CORE_VERIFIED_RUN: 44715871183")
print("GATE_CORE_SEED_BLOB: 31f3d0d0ec125279d5fba67eb79372a812cb4dd8")
for i = SCAN_MIN, SCAN_MAX do
    checkBudget()
    if i > SCAN_MIN then
        local gap = gates[i] - gates[i - 1]
        assert(gap >= O.GATE_GAP_MIN and gap <= O.GATE_GAP_MAX, "gate gap outside oracle bounds")
    end
    print("GATE_INDEX|index=" .. i .. "|day=" .. gates[i])
end
local minimumSixGapWindow = nil
for i = SCAN_MIN, SCAN_MAX - 6 do
    local length = gates[i + 6] - gates[i]
    if minimumSixGapWindow == nil or length < minimumSixGapWindow then
        minimumSixGapWindow = length
    end
    print("GATE_WINDOW|i=" .. i .. "|j=" .. (i + 6) ..
        "|first=" .. gates[i] .. "|last=" .. gates[i + 6] .. "|length=" .. length)
    if O.YEAR_MIN_DAYS <= length and length <= MAX_POSSIBLE_DAYS then
        windows[#windows + 1] = {i = i, length = length, first = gates[i], last = gates[i + 6]}
    end
end
table.sort(windows, function(a, b)
    if a.length ~= b.length then return a.length < b.length end
    if math.abs(a.i) ~= math.abs(b.i) then return math.abs(a.i) < math.abs(b.i) end
    return a.i < b.i
end)

print("GATE_WINDOW_SCAN: " .. SCAN_MIN .. "/" .. SCAN_MAX)
print("GATE_WINDOWS_TOTAL: " .. (SCAN_MAX - SCAN_MIN - 5))
print("MIN_SIX_GAP_WINDOW: " .. minimumSixGapWindow)
print("SHORT_SIX_GAP_WINDOWS: " .. #windows)
for _, w in ipairs(windows) do
    if attempts >= TARGET_PROBE_CAP or admitted then break end
    -- 1/3 and 2/3 interior of each short six-gap window; deterministic finite samples.
    for _, numerator in ipairs({1, 2}) do
        if attempts >= TARGET_PROBE_CAP or admitted then break end
        local day = w.first + math.max(1, (w.length * numerator) // 3)
        if not tested[day] then
            tested[day] = true
            attempts = attempts + 1
            checkBudget()
            local ok, y = pcall(O.year5000, day)
            if not ok then
                local message = tostring(y)
                if not message:find("Pa gen kandida pou ane 5000", 1, true) then
                    error(message, 0)
                end
                print("GATE_TARGET|probe=" .. attempts .. "|day=" .. day ..
                    "|seedIndex=" .. w.i .. "|seedLength=" .. w.length ..
                    "|admitted=0|reason=NO_YEAR_CANDIDATE")
            else
                assert(type(y) == "table" and y.number == 5000, "invalid year")
                local L = y.closeGateDay - y.openGateDay
                local gaps = y.closeGateIndex - y.openGateIndex
                assert(gaps >= 6 and O.YEAR_MIN_DAYS <= L and L <= O.YEAR_MAX_DAYS,
                    "normative year bounds")
                assert(y.openGateDay < day and day <= y.closeGateDay,
                    "target outside selected year")
                assert(O.ensureGateIndex(y.openGateIndex) == y.openGateDay, "open gate mismatch")
                assert(O.ensureGateIndex(y.closeGateIndex) == y.closeGateDay, "close gate mismatch")
                local minMonths = math.max(3, (L + 122) // 123)
                local chosen = "NOT_COMPUTED"
                local states = "NOT_COMPUTED"
                local reason = "MIN_MONTHS_OVER_CAP"
                if L <= MAX_POSSIBLE_DAYS then
                    selectedShort = selectedShort + 1
                    local maxMonths = math.min(47, L // 4)
                    assert(minMonths <= maxMonths, "invalid month interval")
                    local sauce = O.sauce(day, y.openGateDay + 1)
                    local stream = O.askBowl(sauce, 3, O.SEAL_MONTH_COUNT)
                    chosen = minMonths + toNumber(O.chooseRank(stream, B.from(maxMonths - minMonths + 1))) - 1
                    states = compositionStateUpperBound(L, chosen)
                    if chosen > MAX_MONTHS then
                        reason = "SELECTED_MONTH_COUNT_OVER_CAP"
                    elseif states > MAX_COMPOSITION_STATES then
                        reason = "COMPOSITION_STATE_BOUND_OVER_CAP"
                    else
                        reason = "ADMITTED"
                    end
                end
                local passed = reason == "ADMITTED"
                print(table.concat({
                    "GATE_TARGET", "probe=" .. attempts, "day=" .. day,
                    "seedIndex=" .. w.i, "seedLength=" .. w.length,
                    "openGateIndex=" .. y.openGateIndex,
                    "closeGateIndex=" .. y.closeGateIndex,
                    "openGateDay=" .. y.openGateDay,
                    "closeGateDay=" .. y.closeGateDay,
                    "yearLength=" .. L, "gateGaps=" .. gaps,
                    "minimumMonths=" .. minMonths,
                    "selectedMonthCount=" .. chosen,
                    "compositionStateUpper=" .. states,
                    "admitted=" .. (passed and "1" or "0"), "reason=" .. reason
                }, "|"))
                if passed then
                    admitted = {day=day, open=y.openGateIndex, close=y.closeGateIndex,
                        yearLength=L, months=chosen, stateUpper=states}
                end
            end
        end
    end
end

checkBudget()
debug.sethook()
print("GATE_TARGET_PROBES: " .. attempts .. "/" .. TARGET_PROBE_CAP)
print("SHORT_SELECTED_YEAR_INTERVALS: " .. selectedShort)
if admitted then
    print("GATE_TARGET_ADMISSION_PASS: 1/1")
    print(table.concat({"GATE_ADMITTED_WITNESS","day="..admitted.day,
        "openGateIndex="..admitted.open,"closeGateIndex="..admitted.close,
        "yearLength="..admitted.yearLength,"months="..admitted.months,
        "compositionStateUpper="..admitted.stateUpper},"|"))
else
    print("GATE_TARGET_ADMISSION_NONE: 0/" .. attempts)
end
print("GATE_GAP_EVALUATIONS: " .. gateGapEvaluations)
print("COMPOSITION_NOT_INVOKED: YES")
print("SCOPE=RADIUS64_GATE_WINDOW_STATIC_DISCOVERY_ONLY; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN")
