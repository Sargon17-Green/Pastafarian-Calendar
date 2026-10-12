local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local F = O.FOUNDATION_DAY

local visible = {B.from(109), B.from(223), B.from(347)}
local expected = O.buildHiddenDrops(O.workCounts(F,F), O.STONES)
local missed = {}
for back=1,7 do
    local slot = 1-back
    local actual = S.priorSpaghetti(visible,F,F,1,back)
    local normative = expected[1-slot]
    assert(normative ~= nil and B.compare(normative,1)>=0,
           "Oracle a pa gen gout kache normatif pou plas " .. slot)
    if actual == nil or B.compare(actual,normative)~=0 then
        missed[#missed+1] = tostring(slot)
    end
end
assert(table.concat(missed,",")=="0,-1,-2,-3,-4,-5,-6",
       "Pa gen egzakteman sèt mank legacy yo: "..table.concat(missed,","))
if #missed>0 then
    error("EXPECTED_RED Stage 12 DISCOVERY 06: 7 hidden prior manke: " ..
          table.concat(missed,","),0)
end
print("PASS Stage 12: history rezoud tout gout anvan yo")
