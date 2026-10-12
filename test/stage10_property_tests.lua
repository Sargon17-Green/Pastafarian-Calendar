local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local H=require("legacy_hidden")
local F=O.FOUNDATION_DAY

local cases={
    {F,F},
    {F-1,F+1},
    {F+3,F-2},
    {F-20,F-15},
    {F+17,F+29}
}
local trials=0
local unexpected=0
for i,pair in ipairs(cases) do
    local c,t=pair[1],pair[2]
    local expected=O.buildHiddenDrops(O.workCounts(c,t),O.STONES)
    local physical,context=S.legacyHiddenProbe(c,t)
    local logical=S.hiddenDropsSpaghetti(c,t)
    assert(#physical==7 and context.commitToken==1)
    assert(context.pendingSemanticState==nil and context.rollbackSnapshot==nil)
    for k=1,7 do
        assert(B.compare(physical[k],expected[8-k])==0,
               "Depo fizik la pa hidden(8-k): echantiyon "..i..", index "..k)
        assert(B.compare(H.oldHiddenAt(physical,k),physical[k])==0)
        assert(B.compare(logical[k],expected[k])==0, "PATCH 05 pa korek")
        assert(context.semanticState["physical"..k]==tostring(physical[k]))
        assert(B.compare(physical[k],1)>=0 and B.compare(physical[k],O.M)<=0)
        if k==4 then
            assert(B.compare(physical[k],expected[k])==0,"Mitan an dwe kòrèk")
        elseif B.compare(physical[k],expected[k])==0 then
            unexpected=unexpected+1
        end
        trials=trials+1
    end
end
assert(trials==35 and unexpected==0)
print("PASS pwopriyete Stage 10: "..trials.." pozisyon, 5 kontèks, sant ki pa chanje")
