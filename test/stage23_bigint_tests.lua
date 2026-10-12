local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local original={}
for id=1,6 do original[id]=B.from(tostring(id)..string.rep("0",70)) end
local drops,stones,rows={},{},{}
for i=1,46 do
 drops[i]=B.from((i%2==0 and "-" or "")..tostring(i%9+1)..string.rep("0",53+i))
 stones[i]={w=B.from("2"..string.rep("9",80)),b=B.from("3"..string.rep("7",71)),
    s=B.from("4"..string.rep("0",69)),m=B.from(i+6),r=B.from(i+15)}
 rows[i]={stones[i].w,stones[i].b,stones[i].s,stones[i].m,stones[i].r}
end
local result,ctx=S.bowlChainPatchProbe(drops,stones,original)
local expected=O.applyVisibleDropsToBowls(original,drops,rows)
assert(ctx.semanticState.completedDropCount==46
   and ctx.semanticState.carriedPreviousOutputs==45
   and ctx.legacySemanticState.ignoredPreviousOutputs==45
   and #ctx.patchedChildContexts==46
   and #ctx.childContexts==46)
for id=1,6 do assert(B.compare(result[id],expected[id])==0) end
for i=2,46 do
 for id=1,6 do
   assert(ctx.semanticState.perDrop[i].inputBowls[id]
       ==ctx.semanticState.perDrop[i-1].outputBowls[id])
 end
end
local neg={B.from("-"..string.rep("9",247)),B.from("1"..string.rep("0",223))}
local y,z=S.bowlChainPatchProbe(neg,{stones[1],stones[2]},original)
assert(#y==6 and z.semanticState.carriedPreviousOutputs==1)
print("PASS Stage 23 BigInt: 46 gout, 276 bòl, negatif, >256-bit")