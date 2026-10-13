local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local drops,stones,rows={},{},{}
local original={10,20,30,40,50,60}
for i=1,46 do
 drops[i]=B.from(1);stones[i]={w=2,b=3,s=5,m=7,r=11}
 rows[i]={B.from(2),B.from(3),B.from(5),B.from(7),B.from(11)}
end
drops[46]=B.from(720)
local id,ctx=S.neighborPatchProbe(drops,stones,original,1)
assert(id==6 and ctx.mode=="STAGE_25_PATCH_12"
  and ctx.phase=="PATCH_NEIGHBOR_FROM_DROP46_ORDER"
  and ctx.status=="PATCH_NEIGHBOR_COMPLETE"
  and ctx.currentHandler=="DROP46_NEIGHBOR_ORDER_PATCH"
  and ctx.commitToken==4 and #ctx.branchTrace==4
  and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
  and ctx.branchTrace[2]=="BOWL_CHAIN_STATE_PATCH"
  and ctx.branchTrace[3]=="LEGACY_FIXED_NAME_NEIGHBOR"
  and ctx.branchTrace[4]=="DROP46_NEIGHBOR_ORDER_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
assert(ctx.metrics["neighbor.patch.calls"]==1
  and ctx.metrics["neighbor.patch.legacyCallsPreserved"]==1
  and ctx.metrics["legacy.fixedNeighbor.calls"]==1
  and ctx.metrics["legacy.fixedNeighbor.permutationIgnored"]==1
  and ctx.metrics["bowl.chain.patch.calls"]==1)
assert(ctx.legacyNeighborSelectedId==2
  and ctx.legacyNeighborSemanticState.source=="FIXED_BOWL_NAME_CYCLE_IGNORES_DROP46_ORDER"
  and ctx.legacyNeighborSemanticState.selectedNextId==2
  and ctx.legacyNeighborSemanticState.permutationIgnoredForNeighbor==true
  and ctx.semanticState.source=="PATCH_12_USE_DROP46_ORDER_NEIGHBOR"
  and ctx.semanticState.selectedNextId==6
  and ctx.semanticState.legacySelectedNextId==2
  and ctx.semanticState.queriedId==1
  and ctx.semanticState.positionInDrop46Order==6
  and ctx.semanticState.completedDropCount==46
  and ctx.semanticState.carriedPreviousOutputs==45
  and ctx.semanticState.postStirNotExecuted
  and ctx.semanticState.nextIdFollowsPermutation)
local order=O.bowlOrderFromDrop(drops[46])
assert(table.concat(order,",")==table.concat(ctx.semanticState.orderAtDrop46,","))
assert(#ctx.childContexts==46 and #ctx.patchedChildContexts==46)
assert(ctx.permutationContext.mode=="STAGE_17_PATCH_08"
  and ctx.permutationContext.commitToken==3)
assert(#ctx.diagnostics==4
  and ctx.diagnostics[3].code=="DISCOVERY_12_FIXED_BOWL_NAME_IGNORES_DROP46_ORDER"
  and ctx.diagnostics[4].code=="PATCH_12_NEXT_BOWL_IN_DROP46_ORDER")
local canonical=O.applyVisibleDropsToBowls(
 {B.from(10),B.from(20),B.from(30),B.from(40),B.from(50),B.from(60)},
 drops,rows)
for i=1,6 do
 assert(ctx.semanticState.bowlsAfter46[i]==tostring(canonical[i]))
 assert(ctx.stage23SemanticState.lastBowls[i]==tostring(canonical[i]))
end
local public=S.nextBowlSpaghetti(drops,stones,original,1)
local wrong=S.legacyFixedNeighborProbe(drops,stones,original,1)
assert(public==6 and wrong==2)
assert(select("#",S.nextBowlSpaghetti(drops,stones,original,1))==1)
ctx.legacyNeighborSemanticState.orderAtDrop46[1]=99
ctx.stage23SemanticState.perDrop[3].inputBowls[1]="BROKEN"
ctx.semanticState.orderAtDrop46[2]=99
assert(ctx.legacyNeighborSemanticState.orderAtDrop46[1]~=ctx.semanticState.orderAtDrop46[1])
assert(stones[1].w==2 and drops[46]~=nil)
print("PASS Stage 25 PATCH 12: 46 drops, four commits, historical 2 -> corrected 6")
