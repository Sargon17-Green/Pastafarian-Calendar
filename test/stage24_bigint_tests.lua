local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local original={}
for id=1,6 do original[id]=B.from(tostring(id)..string.rep("0",76)) end
local drops,stones,oracleStones={},{},{}
for i=1,46 do
 drops[i]=B.from((i%2==0 and "-" or "")..tostring(i%9+1)..string.rep("0",55+i))
 stones[i]={w=B.from("2"..string.rep("9",73)),b=B.from("3"..string.rep("7",67)),
   s=B.from("4"..string.rep("0",71)),m=B.from(i+4),r=B.from(i+12)}
 oracleStones[i]={stones[i].w,stones[i].b,stones[i].s,stones[i].m,stones[i].r}
end
local answer,ctx=S.legacyFixedNeighborProbe(drops,stones,original,6)
local order=O.bowlOrderFromDrop(drops[46])
local correct=O.nextBowlInDrop46Order({orderAtDrop46=order},6)
assert(answer==1 and ctx.semanticState.selectedNextId==1)
assert(ctx.semanticState.drop46Decimal==tostring(drops[46])
  and ctx.semanticState.orderAtDrop46[1]==order[1])
assert(ctx.stage23SemanticState.completedDropCount==46
  and ctx.stage23SemanticState.carriedPreviousOutputs==45)
local final=O.applyVisibleDropsToBowls(original,drops,oracleStones)
for id=1,6 do assert(ctx.semanticState.bowlsAfter46[id]==tostring(final[id])) end
assert(correct>=1 and correct<=6)
print("PASS Stage 24 BigInt: 46 gout, 276 bòl, >256-bit negatif, lòd 46 egzak")
