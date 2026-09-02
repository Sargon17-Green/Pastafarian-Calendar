local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local O=require("normative_oracle")
local F=require("generated_stage01_fixtures")
assert(F.foundationDay==O.FOUNDATION_DAY)
assert(O.dayCount(O.FOUNDATION_DAY)==F.dayCounts[1])
assert(O.dayCount(O.FOUNDATION_DAY-1)==F.dayCounts[2])
assert(O.dayCount(O.FOUNDATION_DAY+1)==F.dayCounts[3])
local sauce=O.sauce(O.FOUNDATION_DAY,O.FOUNDATION_DAY)
for i=1,6 do assert(tostring(sauce.bowls[i])==F.sauceFoundation.bowls[i]) end
assert(table.concat(sauce.orderAtDrop46,",")==table.concat(F.sauceFoundation.orderAtDrop46,","))
assert(O.positiveGateGap(1)==F.gateGapPlus1)
assert(O.negativeGateGap(1)==F.gateGapMinus1)
print("PASS fixtures")
