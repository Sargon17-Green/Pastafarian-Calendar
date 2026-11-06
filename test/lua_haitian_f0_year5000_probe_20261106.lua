-- PC-BRANCH-LUA-HAITIAN: bounded, read-only F0 feasibility probe.
-- This probes normative year5000 only; it is NOT a production date integration.
local root = arg[1] or "."
local offset = arg[2]
assert(offset == "0" or offset == "12000", "F0 only permits offsets 0 or 12000")
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local O = require("normative_oracle")
local start = os.clock()
local calculationDay = O.FOUNDATION_DAY + tonumber(offset)
assert(math.type(calculationDay) == "integer")
O.resetGateCache()
local y = O.year5000(calculationDay)
assert(type(y) == "table" and y.number == 5000, "year5000 result is invalid")
for _, key in ipairs({"openGateIndex", "closeGateIndex", "openGateDay", "closeGateDay"}) do
    assert(math.type(y[key]) == "integer", "noninteger year boundary: " .. key)
end
local length = y.closeGateDay - y.openGateDay
local gateCount = y.closeGateIndex - y.openGateIndex
assert(gateCount >= 6, "year uses fewer than six gate gaps")
assert(O.YEAR_MIN_DAYS <= length and length <= O.YEAR_MAX_DAYS, "year length outside normative bounds")
assert(y.openGateDay < calculationDay and calculationDay <= y.closeGateDay, "anchor is not inside selected year")
assert(O.ensureGateIndex(y.openGateIndex) == y.openGateDay, "open gate mismatch")
assert(O.ensureGateIndex(y.closeGateIndex) == y.closeGateDay, "close gate mismatch")
print(table.concat({
    "F0_WITNESS",
    "calculationDay=" .. calculationDay,
    "year=" .. y.number,
    "openGateIndex=" .. y.openGateIndex,
    "closeGateIndex=" .. y.closeGateIndex,
    "openGateDay=" .. y.openGateDay,
    "closeGateDay=" .. y.closeGateDay,
    "gateGaps=" .. gateCount,
    "yearLength=" .. length,
    "cpuSeconds=" .. string.format("%.3f", os.clock() - start)
}, "|"))
