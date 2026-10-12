local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local S = require("spaghetti")
local Old = require("legacy_prior")
local F = -15055671
local store = {B.from(109),B.from(223),B.from(347)}
local original = {tostring(store[1]),tostring(store[2]),tostring(store[3])}
assert(select("#",S.priorSpaghetti(store,F,F,1,1))==1)
assert(select("#",S.legacyPriorProbe(store,F,F,1,1))==2)
for back=1,7 do
    local result, ctx = S.legacyPriorProbe(store,F,F,1,back)
    local slot = 1-back
    assert(result==nil, "Legacy te rezoud hidden san PATCH 06")
    assert(ctx.mode=="STAGE_12_DISCOVERY_06" and ctx.phase=="LEGACY_PRIOR")
    assert(ctx.status=="LEGACY_PRIOR_MISSING" and ctx.currentHandler=="LEGACY_PRIOR")
    assert(ctx.commitToken==1 and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(#ctx.branchTrace==1 and ctx.branchTrace[1]=="LEGACY_PRIOR")
    assert(ctx.semanticState.visibleIndex==1 and ctx.semanticState.back==back)
    assert(ctx.semanticState.requestedSlot==slot and ctx.semanticState.hasValue==false)
    assert(ctx.semanticState.resultDecimal=="MISSING" and ctx.semanticState.ignoredHiddenCount==7)
    assert(ctx.semanticState.source=="VISIBLE_HISTORY_ONLY")
    assert(ctx.metrics["legacy.prior.calls"]==1 and ctx.metrics["legacy.prior.misses"]==1)
    assert(ctx.metrics["legacy.prior.slots"][1]==tostring(slot))
    assert(#ctx.diagnostics==1 and ctx.diagnostics[1].code=="HIDDEN_HISTORY_NOT_RESOLVED")
    assert(ctx.nestedHiddenContext.commitToken==2)
    assert(ctx.nestedHiddenContext.status=="PATCH_HIDDEN_RETURNED")
    assert(ctx.nestedHiddenContext.mode=="STAGE_11_PATCH_05")
end
local seen = 0
for i=2,4 do
    for back=1,i-1 do
        local expected=store[i-back]
        local result,ctx=S.legacyPriorProbe(store,F,F,i,back)
        assert(B.compare(result,expected)==0)
        assert(ctx.semanticState.hasValue==true and ctx.semanticState.resultDecimal==tostring(expected))
        assert(ctx.semanticState.requestedSlot==i-back)
        assert(ctx.metrics["legacy.prior.misses"]==nil)
        assert(ctx.status=="LEGACY_PRIOR_RETURNED")
        seen=seen+1
    end
end
assert(seen==6)
for i=1,3 do assert(tostring(store[i])==original[i]) end
assert(Old.legacyPrior(store,1,1)==nil)
assert(B.compare(Old.legacyPrior(store,3,2),store[1])==0)
assert(not pcall(S.priorSpaghetti,store,F,F,0,1))
assert(not pcall(S.priorSpaghetti,store,F,F,1,0))
assert(not pcall(S.priorSpaghetti,store,F,F,1,8))
assert(not pcall(S.priorSpaghetti,{},F,F,1,"1"))
assert(not pcall(S.priorSpaghetti,{[1]="bad"},F,F,2,1))
assert(not pcall(S.calendarDateSpaghetti))
print("PASS tras Stage 12: 7 mank hidden, 6 lekti vizib, kontex ak validasyon")
