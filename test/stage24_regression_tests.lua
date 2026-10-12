local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local initial={10,20,30,40,50,60}
local row={w=2,b=3,s=5,m=7,r=11}
local drops,stones={},{}
for i=1,46 do drops[i]=B.from(1);stones[i]=row end
drops[46]=B.from(720)
local legacy,ctx=S.legacyFixedNeighborProbe(drops,stones,initial,1)
local corrected=O.nextBowlInDrop46Order({orderAtDrop46=O.bowlOrderFromDrop(drops[46])},1)
assert(legacy==2 and corrected==6 and legacy~=corrected)
assert(ctx.semanticState.permutationIgnoredForNeighbor
 and ctx.semanticState.orderAtDrop46[1]==6
 and ctx.stage23SemanticState.carriedPreviousOutputs==45)
error("EXPECTED_RED Stage 24 DISCOVERY 12: vwazen pa non fiks inyore lòd gout 46",0)
