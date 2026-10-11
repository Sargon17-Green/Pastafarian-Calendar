local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")

-- Prèv istorik la toujou konpare ansyen chemen an, pa chemen ki repare a.
local cases = {
    {name = "M", input = O.M},
    {name = "2M", input = O.M * B.from(2)},
    {name = "3M", input = O.M * B.from(3)},
    {name = "M+1", input = O.M + B.from(1)}
}
local mismatches = {}
for _, case in ipairs(cases) do
    local actual = S.legacySaveProbe(case.input)
    local expected = O.SAVE(case.input)
    if B.compare(actual, expected) ~= 0 then
        mismatches[#mismatches + 1] =
            case.name .. ": legacy=" .. tostring(actual) .. " normative=" .. tostring(expected)
    end
end
if #mismatches > 0 then
    error("EXPECTED_RED Stage 2 DISCOVERY 01: " .. #mismatches ..
          " ka SAVE pa ekivalan: " .. table.concat(mismatches, "; "), 0)
end
print("PASS regresyon legacy istorik: pa gen okenn diferans")
