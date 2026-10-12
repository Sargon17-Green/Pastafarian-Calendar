local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local rows={}
local row={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local samples={{1},{1,2},{121,241},{1,121,241},{720,719,718,717,716},
 {1,121,241,720,0,-37,500},{11,22,33,44,55,66,77,88}}
local examined=0
for _,drops in ipairs(samples) do
 local stones,oracleRows={},{}
 for i=1,#drops do stones[i]=row;oracleRows[i]={2,3,5,7,11} end
 local corrected,ctx=S.bowlChainPatchProbe(drops,stones,initial)
 local oracleDrops={}
 for i=1,#drops do oracleDrops[i]=B.from(drops[i]) end
 local reference=O.applyVisibleDropsToBowls(initial,oracleDrops,oracleRows)
 local legacy,oldctx=S.legacyResetBowlsProbe(drops,stones,initial)
 assert(ctx.mode=="STAGE_23_PATCH_11"
    and ctx.phase=="PATCH_CARRY_BOWLS_BETWEEN_DROPS"
    and ctx.status=="PATCH_CHAIN_COMPLETE"
    and ctx.commitToken==2 and #ctx.branchTrace==2
    and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
    and ctx.branchTrace[2]=="BOWL_CHAIN_STATE_PATCH"
    and ctx.currentHandler=="BOWL_CHAIN_STATE_PATCH"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.metrics["legacy.reset.calls"]==1
    and ctx.metrics["bowl.chain.patch.calls"]==1
    and ctx.metrics["bowl.chain.patch.legacyCallsPreserved"]==1
    and ctx.metrics["bowl.chain.patch.dropCount"][1]==#drops
    and #ctx.childContexts==#drops
    and #ctx.patchedChildContexts==#drops)
 assert(ctx.legacySemanticState.source=="INITIAL_BOWLS_REUSED_AT_EVERY_VISIBLE_DROP"
    and ctx.legacySemanticState.ignoredPreviousOutputs==#drops-1
    and ctx.semanticState.source=="PATCH_11_CARRY_PREVIOUS_BOWLS"
    and ctx.semanticState.carriedPreviousOutputs==#drops-1
    and ctx.semanticState.legacyResetsPreserved==#drops-1
    and ctx.semanticState.legacyCallPreserved
    and ctx.diagnostics[2].code=="PATCH_11_PASS_UPDATED_BOWLS_TO_NEXT_DROP")
 local differences=0
 for id=1,6 do
   assert(B.compare(corrected[id],reference[id])==0,
      "Oracle gout "..#drops..", bòl "..id)
   assert(ctx.semanticState.lastBowls[id]==tostring(corrected[id]))
   assert(ctx.semanticState.legacyLastBowls[id]==tostring(legacy[id]))
   assert(ctx.legacySemanticState.lastBowls[id]==oldctx.semanticState.lastBowls[id])
   if B.compare(corrected[id],legacy[id])~=0 then differences=differences+1 end
 end
 assert(ctx.semanticState.changedBowlIds==differences
    and ctx.metrics["bowl.chain.patch.changedBowlIds"][1]==differences)
 assert((#drops==1 and differences==0) or (#drops>1 and differences>0))
 for i=1,#drops do
    local item=ctx.semanticState.perDrop[i]
    assert(item.index==i and item.sourceIsInitial==(i==1)
       and item.previousDropCarried==(i>1)
       and ctx.patchedChildContexts[i].commitToken==4
       and ctx.patchedChildContexts[i].semanticState.source=="PATCH_10_FROZEN_SIX_BOWL_SNAPSHOT")
    for id=1,6 do
       if i==1 then assert(item.inputBowls[id]==tostring(initial[id]))
       else assert(item.inputBowls[id]==ctx.semanticState.perDrop[i-1].outputBowls[id]) end
       assert(ctx.legacySemanticState.perDrop[i].inputBowls[id]==tostring(initial[id]))
    end
 end
 examined=examined+#drops
end
local public=S.resetBowlsSpaghetti({1,121,241},{row,row,row},initial)
local expected=S.bowlChainPatchProbe({1,121,241},{row,row,row},initial)
for id=1,6 do assert(B.compare(public[id],expected[id])==0) end
assert(select("#",S.resetBowlsSpaghetti({1},{row},initial))==1)
assert(select("#",S.bowlChainPatchProbe({1},{row},initial))==2)
local one,ctx=S.bowlChainPatchProbe({1},{row},initial)
ctx.semanticState.perDrop[1].inputBowls[1]="DEKONEKTE"
ctx.legacySemanticState.perDrop[1].inputBowls[1]="DEKONEKTE"
one[1].d[1]=1234
local again,againCtx=S.bowlChainPatchProbe({1},{row},initial)
assert(againCtx.semanticState.perDrop[1].inputBowls[1]==tostring(initial[1]))
assert(B.compare(again[1],S.stirPatchProbe(1,1,initial,row)[1])==0)
for id=1,6 do assert(initial[id]==id*10) end
print("PASS Stage 23 PATCH 11: 7 sekans, "..examined.." gout, oracle, 2 commits, kopi")