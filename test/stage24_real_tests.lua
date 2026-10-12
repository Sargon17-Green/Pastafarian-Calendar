local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local selected,ctx=S.visibleFixedNeighborProbe(F,F,1)
assert(selected==2 and ctx.mode=="STAGE_24_DISCOVERY_12"
  and ctx.visibleDropCount==46
  and ctx.metrics["discovery12.visible.calls"]==1
  and #ctx.visibleDropContexts==46
  and ctx.visibleDropContexts[46].status=="PATCH_VISIBLE_COMPLETE")
local values={}
for i=1,46 do
 local data=ctx.stage23SemanticState.perDrop[i]
 values[i]=B.from(data.dropDecimal)
 assert(ctx.visibleDropContexts[i].status=="PATCH_VISIBLE_COMPLETE")
end
local order=O.bowlOrderFromDrop(values[46])
local wanted=O.nextBowlInDrop46Order({orderAtDrop46=order},1)
assert(table.concat(order,",")==table.concat(ctx.semanticState.orderAtDrop46,","))
local start=O.initialBowls(O.workCounts(F,F))
local endBowls=O.applyVisibleDropsToBowls(start,values,O.STONES)
for id=1,6 do assert(ctx.stage23SemanticState.lastBowls[id]==tostring(endBowls[id])) end
assert(wanted>=1 and wanted<=6)
print("PASS Stage 24 real: 46 gout PATCH 01–11, oracle sis bòl, lòd 46 ak vwazen fiks")
