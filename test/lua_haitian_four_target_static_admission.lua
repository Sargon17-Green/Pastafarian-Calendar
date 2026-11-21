-- PC-BRANCH-LUA-HAITIAN. Four new radius96 targets: QA-only static admission.
-- One isolated Lua 5.3 process per ordinal; no composition, year structure, or full date.
local root, ordinal, planPath = arg[1] or ".", tonumber(arg[2]), arg[3]
assert(ordinal and math.type(ordinal) == "integer" and ordinal >= 1 and ordinal <= 4,
       "ordinal must be 1..4")
assert(type(planPath) == "string", "verified plan.tsv path required")
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path

local B = require("bigint")
local O = require("normative_oracle")
local expected = {
    {70, 76, 1, -15017677},
    {70, 76, 2, -15017114},
    {71, 77, 1, -15017465},
    {71, 77, 2, -15016813}
}
local old = {
    [-15033432] = true, [-15032867] = true, [-15034166] = true,
    [-15033568] = true, [-15034351] = true, [-15033701] = true
}
local rows, seen, file = {}, {}, assert(io.open(planPath, "r"))
for line in file:lines() do
    local a, b, c, d, e = line:match("^(%d+)\t(%d+)\t(%d+)\t(%d+)\t(-?%d+)$")
    assert(a and b and c and d and e, "malformed verified plan row")
    local row = {tonumber(b), tonumber(c), tonumber(d), tonumber(e)}
    local id = tonumber(a)
    assert(id >= 1 and id <= 4 and not rows[id], "duplicate/bad plan ordinal")
    for k = 1, 4 do assert(row[k] == expected[id][k], "plan differs from locked transcript target") end
    assert(not seen[row[4]] and not old[row[4]], "duplicate/old target")
    seen[row[4]] = true
    rows[id] = row
end
file:close()
for i = 1, 4 do assert(rows[i], "incomplete plan") end

local begun, gapCalls = os.clock(), 0
local function budget()
    if os.clock() - begun > 110 then error("ABORT_CPU_CAP", 0) end
    if collectgarbage("count") > 131072 then error("ABORT_HEAP_CAP", 0) end
end
local p, n = O.positiveGateGap, O.negativeGateGap
O.positiveGateGap = function(i)
    gapCalls = gapCalls + 1
    if gapCalls > 200 then error("ABORT_FRESH_GAP_CAP", 0) end
    budget()
    return p(i)
end
O.negativeGateGap = function(i)
    gapCalls = gapCalls + 1
    if gapCalls > 200 then error("ABORT_FRESH_GAP_CAP", 0) end
    budget()
    return n(i)
end
local function integer(x, label)
    assert(math.type(x) == "integer", "non-integer " .. label)
    return x
end
local function toInt(x)
    local v = B.toNumber(x)
    assert(v ~= nil and math.type(v) == "integer", "invalid BigInt selection")
    return v
end
-- Upper bound on the number of reachable (slot count, partial sum) DP states.
-- This is arithmetic only: the composition constructor is NEVER called.
local function stateUpper(days, months)
    local count = 0
    for slots = 1, months do
        local low, high = 4 * slots, math.min(days, 123 * slots)
        if high >= low then count = count + high - low + 1 end
    end
    return count
end
local function record(fields)
    local out = {"PROBE_RESULT"}
    for _, pair in ipairs(fields) do out[#out + 1] = pair[1] .. "=" .. tostring(pair[2]) end
    print(table.concat(out, "|"))
end

local w = rows[ordinal]
local day = integer(w[4], "calculationDay")
O.resetGateCache()
debug.sethook(budget, "", 10000)
print("PROJECT_ID: PC-BRANCH-LUA-HAITIAN")
print("QA_SCOPE: NEW_RADIUS96_FOUR_TARGET_STATIC_ADMISSION")
print("COMPOSITION_NOT_INVOKED: YES")
print("FULL_DATE: NOT_RUN")
local fields = {
    {"ordinal", ordinal}, {"window", w[1] .. ".." .. w[2]},
    {"fraction", w[3]}, {"day", day}, {"year", "NOT_COMPUTED"},
    {"openIndex", "NOT_COMPUTED"}, {"closeIndex", "NOT_COMPUTED"},
    {"openDay", "NOT_COMPUTED"}, {"closeDay", "NOT_COMPUTED"},
    {"length", "NOT_COMPUTED"}, {"gaps", "NOT_COMPUTED"},
    {"minimumMonths", "NOT_COMPUTED"}, {"maximumMonths", "NOT_COMPUTED"},
    {"selectedMonths", "NOT_COMPUTED"}, {"stateUpper", "NOT_COMPUTED"},
    {"reason", "NOT_COMPUTED"}
}
local function put(key, value)
    for _, pair in ipairs(fields) do
        if pair[1] == key then pair[2] = value; return end
    end
    error("internal field error " .. key)
end

local ok, year = pcall(O.year5000, day)
if not ok then
    assert(tostring(year):find("Pa gen kandida pou ane 5000", 1, true),
           "ABORT_YEAR5000: " .. tostring(year))
    put("reason", "NO_YEAR_CANDIDATE")
else
    assert(type(year) == "table" and year.number == 5000, "invalid normative year")
    for _, key in ipairs({"openGateIndex", "closeGateIndex", "openGateDay", "closeGateDay"}) do
        integer(year[key], key)
    end
    local open, close = year.openGateDay, year.closeGateDay
    local length, gaps = close - open, year.closeGateIndex - year.openGateIndex
    assert(open < day and day <= close, "day outside selected year")
    assert(gaps >= 6 and length >= 252 and length <= 5778, "year range")
    assert(O.ensureGateIndex(year.openGateIndex) == open, "open index mismatch")
    assert(O.ensureGateIndex(year.closeGateIndex) == close, "close index mismatch")
    local minMonths = math.max(3, (length + 122) // 123)
    put("year", 5000)
    put("openIndex", year.openGateIndex)
    put("closeIndex", year.closeGateIndex)
    put("openDay", open)
    put("closeDay", close)
    put("length", length)
    put("gaps", gaps)
    put("minimumMonths", minMonths)
    if length > 1968 then
        put("reason", "MIN_MONTHS_OVER_CAP")
    else
        local maxMonths = math.min(47, length // 4)
        assert(minMonths <= maxMonths, "invalid month range")
        local sauce = O.sauce(day, open + 1)
        local selected = minMonths + toInt(O.chooseRank(
            O.askBowl(sauce, 3, O.SEAL_MONTH_COUNT),
            B.from(maxMonths - minMonths + 1))) - 1
        assert(selected >= minMonths and selected <= maxMonths, "month selection range")
        local states = stateUpper(length, selected)
        put("maximumMonths", maxMonths)
        put("selectedMonths", selected)
        put("stateUpper", states)
        if selected > 16 then
            put("reason", "SELECTED_MONTH_COUNT_OVER_CAP")
        elseif states > 20000 then
            put("reason", "COMPOSITION_STATE_BOUND_OVER_CAP")
        else
            put("reason", "ADMITTED")
        end
    end
end
budget()
debug.sethook()
record(fields)
print("GAP_CALLS: " .. gapCalls)
print(string.format("LUA_CPU_SECONDS: %.6f", os.clock() - begun))
print("QA_FINAL: COMPLETE")
