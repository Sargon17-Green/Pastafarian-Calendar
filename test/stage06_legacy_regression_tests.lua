local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local F = O.FOUNDATION_DAY

local function normativeDistance(c, t)
    return B.add(B.abs(B.sub(B.from(t), B.from(c))), 1)
end

local cases = {
    {name = "SELF", c = F, t = F},
    {name = "BEFORE_NEIGHBORS", c = F - 1, t = F - 2},
    {name = "AFTER_NEIGHBORS", c = F + 1, t = F + 2},
    {name = "ACROSS", c = F - 1, t = F + 1},
    {name = "LONG_BEFORE", c = F - 5, t = F - 2},
    {name = "LONG_AFTER", c = F + 2, t = F + 5},
    {name = "REVERSE_CROSS", c = F + 1, t = F - 1}
}

local mismatches = {}
for _, item in ipairs(cases) do
    local actual = S.legacyDistanceProbe(item.c, item.t)
    local expected = normativeDistance(item.c, item.t)
    if B.compare(actual, expected) ~= 0 then
        mismatches[#mismatches + 1] = item.name .. ": legacy=" ..
            tostring(actual) .. " normative=" .. tostring(expected)
    end
end
if #mismatches > 0 then
    error("EXPECTED_RED Stage 6 DISCOVERY 03: " .. #mismatches ..
          " ka distance pa ekivalan: " .. table.concat(mismatches, "; "), 0)
end
print("PASS ansyen regresyon Stage 6: legacy pa divèje")
