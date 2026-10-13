local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local id,ctx=S.visibleNeighborPatchProbe(F,F,1)
assert(ctx.mode=="STAGE_25_PATCH_12"
   and ctx.status=="PATCH_NEIGHBOR_COMPLETE"
   and ctx.visibleDropCount==46
   and ctx.metrics["patch12.visible.calls"]==1
   and #ctx.visibleDropContexts==46
   and ctx.commitToken==4)
local drops={}
for i=1,46 do
 drops[i]=B.from(ctx.stage23SemanticState.perDrop[i].dropDecimal)
 assert(ctx.visibleDropContexts[i].status=="PATCH_VISIBLE_COMPLETE"
   and ctx.visibleDropContexts[i].completedGrinds==11)
end
local order=O.bowlOrderFromDrop(drops[46])
assert(table.concat(ctx.semanticState.orderAtDrop46,",")==table.concat(order,","))
assert(id==O.nextBowlInDrop46Order({orderAtDrop46=order},1))
local oracle=O.applyVisibleDropsToBowls(O.initialBowls(O.workCounts(F,F)),drops,O.STONES)
for i=1,6 do assert(ctx.semanticState.bowlsAfter46[i]==tostring(oracle[i])) end
print("PASS Stage 25 real: 46 authentic visible drops, full bowl oracle and corrected neighbor")
