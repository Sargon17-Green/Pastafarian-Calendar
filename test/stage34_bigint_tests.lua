local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local streams={}
local sum=B.from(F)
for i=1,32 do
 streams[i]={first=B.sub(O.M,i),directionStep=i%2==0 and 1 or -1}
 local rank=O.chooseRankShort(streams[i],922)
 sum=B.add(sum,B.add(41,rank))
end
local value,ctx=S.legacyPositiveGateProbe(32,streams)
local lastGap=ctx.positiveGapDecimals[32]
assert(B.compare(value,B.add(F,lastGap))==0
 and B.compare(ctx.correctCumulativeDayForAudit,sum)==0
 and ctx.gateIndex==32 and #ctx.positiveGapDecimals==32
 and ctx.commitToken==6 and B.compare(value,sum)<0)
for _,bad in ipairs({0,-1,1.5,"2",33,false,{}}) do
 assert(not pcall(S.legacyPositiveGateProbe,bad,streams))
end
assert(not pcall(S.legacyPositiveGateProbe,1,nil))
for _,bad in ipairs({false,"not-a-list",{},{{first=1,directionStep=2}},{{first=0,directionStep=1}}}) do
 assert(not pcall(S.legacyPositiveGateProbe,1,bad))
end
assert(not pcall(S.oldPositiveGateFromLastGapProbe,41))
assert(not pcall(S.oldPositiveGateFromLastGapProbe,964))
assert(B.compare(S.oldPositiveGateFromLastGapProbe(42),B.add(F,42))==0)
assert(B.compare(S.oldPositiveGateFromLastGapProbe(963),B.add(F,963))==0)
print("PASS Stage 34 bounds: 32 high-BigInt streams, exact accumulated comparison, input limits")
