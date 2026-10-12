local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local rock={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local drops,stones,oracleRows={},{},{}
for i=1,46 do drops[i]=B.from(1);stones[i]=rock;oracleRows[i]={2,3,5,7,11} end
drops[46]=B.from(720)
local old,ctx=S.legacyFixedNeighborProbe(drops,stones,initial,1)
local order=O.bowlOrderFromDrop(drops[46])
local expected=O.nextBowlInDrop46Order({orderAtDrop46=order},1)
assert(old==2 and expected==6)
assert(ctx.mode=="STAGE_24_DISCOVERY_12"
  and ctx.status=="LEGACY_FIXED_NEIGHBOR_COMPLETE"
  and ctx.phase=="LEGACY_NEIGHBOR_BY_FIXED_BOWL_NAME"
  and ctx.commitToken==3 and #ctx.branchTrace==3
  and ctx.branchTrace[1]=="LEGACY_BOWL_STATE_RESET"
  and ctx.branchTrace[2]=="BOWL_CHAIN_STATE_PATCH"
  and ctx.branchTrace[3]=="LEGACY_FIXED_NAME_NEIGHBOR"
  and ctx.currentHandler=="LEGACY_FIXED_NAME_NEIGHBOR"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
assert(ctx.metrics["legacy.fixedNeighbor.calls"]==1
   and ctx.metrics["legacy.fixedNeighbor.permutationIgnored"]==1
   and ctx.metrics["bowl.chain.patch.calls"]==1)
assert(ctx.semanticState.source=="FIXED_BOWL_NAME_CYCLE_IGNORES_DROP46_ORDER"
  and ctx.semanticState.queriedId==1 and ctx.semanticState.selectedNextId==2
  and ctx.semanticState.postStirNotExecuted
  and ctx.semanticState.completedDropCount==46
  and ctx.semanticState.drop46Decimal=="720"
  and ctx.semanticState.permutationIgnoredForNeighbor)
assert(table.concat(ctx.semanticState.orderAtDrop46,",")==table.concat(order,","))
assert(ctx.permutationContext.mode=="STAGE_17_PATCH_08"
  and ctx.permutationContext.commitToken==3
  and ctx.permutationContext.semanticState.permutation==table.concat(order,","))
assert(ctx.stage23SemanticState.source=="PATCH_11_CARRY_PREVIOUS_BOWLS"
  and ctx.stage23SemanticState.carriedPreviousOutputs==45
  and #ctx.childContexts==46 and #ctx.patchedChildContexts==46)
assert(#ctx.diagnostics==3
  and ctx.diagnostics[3].code=="DISCOVERY_12_FIXED_BOWL_NAME_IGNORES_DROP46_ORDER")
local correctBowls=O.applyVisibleDropsToBowls(
 {B.from(10),B.from(20),B.from(30),B.from(40),B.from(50),B.from(60)},
 drops,(function()local rows={}for i=1,46 do rows[i]={B.from(2),B.from(3),B.from(5),B.from(7),B.from(11)} end return rows end)())
for id=1,6 do
 assert(ctx.stage23SemanticState.lastBowls[id]==tostring(correctBowls[id]))
 assert(ctx.semanticState.bowlsAfter46[id]==tostring(correctBowls[id]))
end
ctx.stage23SemanticState.perDrop[2].inputBowls[1]="FAKE"
ctx.semanticState.orderAtDrop46[1]=777
ctx.stage23FinalBowls[1].d[1]=314159
local again,ctx2=S.legacyFixedNeighborProbe(drops,stones,initial,1)
assert(again==2 and ctx2.stage23SemanticState.perDrop[2].inputBowls[1]~="FAKE"
  and ctx2.semanticState.orderAtDrop46[1]==order[1])
for i=1,6 do assert(initial[i]==i*10 and stones[1]==rock) end
print("PASS Stage 24 synthetic: 46 gout, lòd 720 envèse, vwazen fiks mal, 3 commits")
