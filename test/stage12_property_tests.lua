local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local Old = require("legacy_prior")
local F=O.FOUNDATION_DAY
local originalStore = {
    B.from("170141183460469231731687303715884105728"),
    B.from("-" .. string.rep("9",110)),
    B.from("1" .. string.rep("0",180)),
    B.from(459),B.from(790),B.from(1213),B.from(1609),B.from(2027)
}
local mirror = Old.copyStore(originalStore)
local misses, visible = 0,0
for i=1,8 do
    for back=1,7 do
        local result, ctx = S.legacyPriorProbe(originalStore,F+i,F-i,i,back)
        local slot=i-back
        assert(ctx.semanticState.requestedSlot==slot)
        assert(ctx.nestedHiddenContext.commitToken==2)
        if slot<=0 then
            assert(result==nil and ctx.semanticState.hasValue==false)
            assert(ctx.metrics["legacy.prior.misses"]==1)
            misses=misses+1
        else
            assert(B.compare(result,mirror[slot])==0 and ctx.semanticState.hasValue==true)
            assert(ctx.metrics["legacy.prior.misses"]==nil)
            visible=visible+1
        end
    end
end
for k=1,8 do assert(tostring(originalStore[k])==tostring(mirror[k])) end
assert(misses==28 and visible==28)
-- Ansyen fonksyon an pa kenbe okenn valè hidden, menm si depo gen sa yo.
local adversarial=Old.copyStore(originalStore)
adversarial[0]=B.from(998)
adversarial[-1]=B.from(997)
assert(B.compare(Old.legacyPrior(adversarial,1,1),998)==0)
assert(B.compare(Old.legacyPrior(adversarial,1,2),997)==0)
local got,ctx=S.legacyPriorProbe(adversarial,F,F,1,1)
assert(B.compare(got,998)==0 and ctx.semanticState.source=="VISIBLE_HISTORY_ONLY")
assert(ctx.semanticState.ignoredHiddenCount==7)
-- Pa antre nouvo pwojè gout vizib Stage 13: history rete legacy sèlman.
print("PASS pwopriyete Stage 12: " .. misses .. " mank hidden, " .. visible ..
      " lekti vizib, BigInt >256 bit, depo negatif istorik")
