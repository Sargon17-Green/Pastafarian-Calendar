local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local F = O.FOUNDATION_DAY

local cases = {
    {name = "BEFORE_2", day = F - 2},
    {name = "BEFORE_1", day = F - 1},
    {name = "FOUNDATION", day = F},
    {name = "AFTER_1", day = F + 1},
    {name = "AFTER_2", day = F + 2},
    {name = "AFTER_20", day = F + 20}
}
local mismatches = {}
for _, item in ipairs(cases) do
    local observed = S.dayTagSpaghetti(item.day)
    local normative = B.from(O.dayCount(item.day))
    if B.compare(observed, normative) ~= 0 then
        mismatches[#mismatches + 1] = item.name .. ": legacy=" ..
            tostring(observed) .. " normative=" .. tostring(normative)
    end
end
if #mismatches ~= 0 then
    error("EXPECTED_RED Stage 4 DISCOVERY 02: " .. #mismatches ..
          " ka dayTag pa ekivalan: " .. table.concat(mismatches, "; "), 0)
end
print("PASS Stage 4: tout ka dayTag ekivalan")
