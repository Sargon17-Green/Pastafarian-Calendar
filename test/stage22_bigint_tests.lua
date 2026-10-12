local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local bowls={}
for id=1,6 do bowls[id]=B.from(tostring(id)..string.rep("0",81)) end
local stones={}
for i=1,46 do
  stones[i]={w=B.from("1"..string.rep("9",80)),b=B.from("2"..string.rep("7",76)),
    s=B.from("3"..string.rep("0",73)),m=B.from(7+i),r=B.from(11+i)}
end
local arr={}
for i=1,46 do
  arr[i]=B.from((i%2==0 and "-" or "")..tostring((i%9)+1)..string.rep("0",66+i))
end
local latest,ctx=S.legacyResetBowlsProbe(arr,stones,bowls)
assert(ctx.semanticState.completedDropCount==46)
assert(ctx.semanticState.ignoredPreviousOutputs==45 and #ctx.childContexts==46)
local lastOnly=S.stirPatchProbe(arr[46],46,bowls,stones[46])
for id=1,6 do assert(B.compare(latest[id],lastOnly[id])==0) end
for i=1,46 do
  assert(ctx.childContexts[i].commitToken==4)
  assert(ctx.semanticState.perDrop[i].inputBowls[1]==tostring(bowls[1]))
end
local negative={B.from("-"..string.rep("9",230)),B.from("1"..string.rep("0",214))}
local result,negativeCtx=S.legacyResetBowlsProbe(negative,{stones[1],stones[2]},bowls)
assert(#result==6 and negativeCtx.semanticState.ignoredPreviousOutputs==1)
print("PASS Stage 22 BigInt: 46 gout, 276 brase bòl, negatif, 200+ chif")
