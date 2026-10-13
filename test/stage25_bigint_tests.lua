local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local bowls={}
for i=1,6 do bowls[i]=B.from(tostring(i)..string.rep("0",78)) end
local drops,stones,rows={},{},{}
for i=1,46 do
 drops[i]=B.from((i%2==0 and "-" or "")..tostring(i%9+1)..string.rep("0",65+i))
 stones[i]={w=B.from("2"..string.rep("9",72)),b=B.from("3"..string.rep("8",77)),
   s=B.from("4"..string.rep("0",74)),m=B.from(i+9),r=B.from(i+15)}
 rows[i]={stones[i].w,stones[i].b,stones[i].s,stones[i].m,stones[i].r}
end
local result,ctx=S.neighborPatchProbe(drops,stones,bowls,6)
local order=O.bowlOrderFromDrop(drops[46])
assert(result==O.nextBowlInDrop46Order({orderAtDrop46=order},6))
assert(ctx.semanticState.rank46==ctx.legacyNeighborSemanticState.rank46
   and ctx.semanticState.legacySelectedNextId==1
   and ctx.semanticState.completedDropCount==46
   and ctx.commitToken==4)
local oracle=O.applyVisibleDropsToBowls(bowls,drops,rows)
for i=1,6 do assert(ctx.semanticState.bowlsAfter46[i]==tostring(oracle[i])) end
print("PASS Stage 25 BigInt: 46 drops, negative/256+, 276 bowls; independent next-in-order oracle")
