local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local streams,expected={},B.from(F)
for i=1,32 do
 streams[i]={first=B.sub(O.M,i),directionStep=i%2==0 and 1 or -1}
 local rank=O.chooseRankShort(streams[i],922)
 expected=B.add(expected,B.add(41,rank))
end
local fixed,ctx=S.positiveGatePatchProbe(32,streams)
local historic=S.legacyPositiveGateProbe(32,streams)
assert(B.compare(expected,B.add(F,16080))==0
 and B.compare(fixed,expected)==0
 and B.compare(historic,B.add(F,42))==0
 and ctx.commitToken==7
 and ctx.semanticState.priorGapsAdded==31
 and ctx.semanticState.correctedGateDayDecimal==tostring(expected))
for i=1,32 do
 assert(ctx.semanticState.gapDecimals[i]==(i%2==0 and "42" or "963"))
end
for _,n in ipairs({0,-1,33,1.5,"2",false,{}}) do
 assert(not pcall(S.positiveGatePatchProbe,n,streams))
end
local badGaps={{},{41},{964},{42,41},{42,964},{42,42,42},{[1]=42,[0]=42}}
for _,gaps in ipairs(badGaps) do
 assert(not pcall(S.positiveGateCoreProbe,2,gaps,B.add(F,42)))
end
assert(not pcall(S.positiveGateCoreProbe,1,{42},nil))
assert(not pcall(S.positiveGateCoreProbe,1,{42},B.add(F,43)))
local one,proof=S.positiveGateCoreProbe(1,{42},B.add(F,42))
assert(B.compare(one,B.add(F,42))==0 and proof.addedPriorGaps==0)
local two,p2=S.positiveGateCoreProbe(2,{963,42},B.add(F,42))
assert(B.compare(two,B.add(F,1005))==0 and p2.addedPriorGaps==1)
print("PASS Stage 35 BigInt: 32 huge SAVE streams, exact 16080-day cumulative chain, invalid core rejected")
