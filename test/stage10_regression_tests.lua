local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY

local counts=O.workCounts(F,F)
local normative=O.buildHiddenDrops(counts,O.STONES)
local production=S.hiddenDropsSpaghetti(F,F)
local legacy=S.legacyHiddenProbe(F,F)
for k=1,7 do
    assert(B.compare(legacy[k],normative[8-k])==0,
           "Depo fizik la pa rete nan lòd envèse li a")
    assert(B.compare(production[k],normative[k])==0,
           "PATCH 05 pa mete gout lojik la nan bon pozisyon: " .. k)
    assert(B.compare(S.hiddenDropSpaghetti(F,F,k),normative[k])==0)
end
print("PASS Stage 10: sèt gout kache yo nan bon lòd")
