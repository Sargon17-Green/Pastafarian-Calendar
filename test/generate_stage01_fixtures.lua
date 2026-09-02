local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local O = require("normative_oracle")
local B = require("bigint")

local sauce = O.sauce(O.FOUNDATION_DAY, O.FOUNDATION_DAY)
local p1 = O.positiveGateGap(1)
local n1 = O.negativeGateGap(1)
local path = root .. "/test/generated_stage01_fixtures.lua"
local f = assert(io.open(path, "w"))
f:write("return {\n")
f:write("  foundationDay = ", O.FOUNDATION_DAY, ",\n")
f:write("  dayCounts = {1,2,3},\n")
f:write("  save = {\n")
f:write("    M = \"", tostring(O.SAVE(O.M)), "\",\n")
f:write("    twoM = \"", tostring(O.SAVE(O.M * B.from(2))), "\",\n")
f:write("    Mplus1 = \"", tostring(O.SAVE(O.M + B.from(1))), "\"\n")
f:write("  },\n")
f:write("  sauceFoundation = {\n")
f:write("    bowls = {\n")
for i=1,6 do f:write("      \"", tostring(sauce.bowls[i]), "\"", i<6 and ",\n" or "\n") end
f:write("    },\n")
f:write("    orderAtDrop46 = {", table.concat(sauce.orderAtDrop46, ","), "}\n")
f:write("  },\n")
f:write("  gateGapPlus1 = ", p1, ",\n")
f:write("  gateGapMinus1 = ", n1, "\n")
f:write("}\n")
f:close()
print("PASS jenerasyon fixture Stage 1")
