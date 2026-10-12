local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local F = O.FOUNDATION_DAY
local visible = {B.from(109), B.from(223), B.from(347)}
local expected = O.buildHiddenDrops(O.workCounts(F,F), O.STONES)
for back=1,7 do
    local slot = 1-back
    local normative = expected[1-slot]
    assert(normative ~= nil and B.compare(normative,1)>=0)
    local actual = S.priorSpaghetti(visible,F,F,1,back)
    assert(actual ~= nil and B.compare(actual,normative)==0,
           "PATCH 06 pa rezoud gout hidden nan plas "..slot)
end
for i=2,4 do
    for back=1,i-1 do
        local v = S.priorSpaghetti(visible,F,F,i,back)
        assert(B.compare(v,visible[i-back])==0, "Wout vizib la pa sèvi ak legacy")
    end
end
print("PASS Stage 12: history rezoud tout gout anvan yo")
