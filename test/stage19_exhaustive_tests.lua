local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stone={w=2,b=3,s=5,m=7,r=11}
local old={10,20,30,40,50,60}
local names={"w","b","s"}
local factors={3,5,7}
local disagreements,matched=0,0
for rank=1,720 do
    local result,ctx=S.pourPatchProbe(rank,4,old,stone)
    local normOrder=O.bowlOrderFromDrop(B.from(rank))
    local changed=0
    assert(ctx.mode=="STAGE_19_PATCH_09" and ctx.phase=="PATCH_POUR_BOWL_ORDER")
    assert(ctx.commitToken==2 and ctx.status=="PATCH_POUR_RETURNED")
    assert(ctx.currentHandler=="BOWL_ORDER_POUR_PATCH")
    assert(ctx.previousHandler=="LEGACY_FIXED_BOWL_POURS")
    assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_FIXED_BOWL_POURS"
           and ctx.branchTrace[2]=="BOWL_ORDER_POUR_PATCH")
    assert(ctx.permutationContext.mode=="STAGE_17_PATCH_08"
           and ctx.permutationContext.commitToken==3)
    assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
    assert(ctx.metrics["legacy.fixedPour.calls"]==1 and ctx.metrics["pour.patch.calls"]==1)
    assert(ctx.metrics["pour.patch.legacyCallsPreserved"]==1)
    assert(#ctx.diagnostics==2)
    assert(ctx.diagnostics[1].code=="DISCOVERY_09_POURS_TO_FIXED_IDS")
    assert(ctx.diagnostics[2].code=="PATCH_09_USE_PERMUTED_BOWL_IDS")
    assert(ctx.semanticState.source=="PATCH_09_POUR_USING_CORRECTED_BOWL_ORDER")
    for p=1,3 do
        local target=O.SAVE(B.from(rank)*B.from(rank)
            + B.from(stone[names[p]])*B.from(old[normOrder[p]])
            + B.from(factors[p]*4))
        local legacy=O.SAVE(B.from(rank)*B.from(rank)
            + B.from(stone[names[p]])*B.from(old[p])
            + B.from(factors[p]*4))
        assert(B.compare(result[p],target)==0,"Rank "..rank.." vide "..p)
        assert(ctx.semanticState.usedBowlIds[p]==normOrder[p])
        assert(ctx.semanticState.historicalFixedBowlIds[p]==p)
        assert(ctx.semanticState.historicalWrongPours[p]==tostring(legacy))
        assert(ctx.semanticState.correctedPours[p]==tostring(target))
        if B.compare(target,legacy)~=0 then changed=changed+1 end
    end
    assert(ctx.semanticState.pourDifferences==changed)
    assert(ctx.metrics["pour.patch.changedPositions"][1]==changed)
    disagreements=disagreements+changed
    if changed==0 then matched=matched+1 end
end
assert(disagreements==1800 and matched==6)
local x=S.fixedBowlPoursSpaghetti(241,4,old,stone)
local y=S.pourPatchProbe(241,4,old,stone)
for p=1,3 do assert(B.compare(x[p],y[p])==0) end
assert(select("#",S.fixedBowlPoursSpaghetti(1,4,old,stone))==1)
assert(select("#",S.pourPatchProbe(1,4,old,stone))==2)
print("PASS Stage 19: 720/720 lòd, 1800 diferans legacy, 6 lòd ki matche")
