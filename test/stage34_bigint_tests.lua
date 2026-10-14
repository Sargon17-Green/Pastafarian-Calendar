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
-- M mod 922 = 221: all M-i for i=1..32 are beyond the acceptance
-- threshold. Negative directions accept limit (rank 922);
-- positive directions wrap to 1 (rank 1).
assert(B.compare(B.mod(O.M,922),221)==0)
for i=1,32 do
 assert(ctx.positiveGapDecimals[i]==(i%2==0 and "42" or "963"),
  "Wrong BigInt acceptance wrap at positive gate "..i)
end
assert(B.compare(sum,B.add(F,16080))==0
 and lastGap=="42"
 and B.compare(value,B.add(F,42))==0
 and B.compare(value,B.add(F,lastGap))==0
 and ctx.correctCumulativeDayForAudit==nil
 and ctx.gateIndex==32 and #ctx.positiveGapDecimals==32
 and ctx.commitToken==6 and B.compare(value,sum)<0)
for _,bad in ipairs({0,-1,1.5,"2",33,false,{}}) do
 assert(not pcall(S.legacyPositiveGateProbe,bad,streams))
end
assert(not pcall(S.legacyPositiveGateProbe,1,nil))
assert(not pcall(S.legacyPositiveGateProbe,1,{[1]={first=1,directionStep=1},[0]={first=2,directionStep=1}}))
assert(not pcall(S.legacyPositiveGateProbe,1,{[1]={first=1,directionStep=1},note="bad-extra-key"}))
assert(not pcall(S.legacyPositiveGateProbe,2,{[1]={first=1,directionStep=1},[3]={first=2,directionStep=1}}))
for _,bad in ipairs({false,"not-a-list",{},{{first=1,directionStep=2}},{{first=0,directionStep=1}}}) do
 assert(not pcall(S.legacyPositiveGateProbe,1,bad))
end
assert(not pcall(S.oldPositiveGateFromLastGapProbe,41))
assert(not pcall(S.oldPositiveGateFromLastGapProbe,964))
assert(B.compare(S.oldPositiveGateFromLastGapProbe(42),B.add(F,42))==0)
assert(B.compare(S.oldPositiveGateFromLastGapProbe(963),B.add(F,963))==0)
print("PASS Stage 34 bounds: 32 high-BigInt streams, exact accumulated comparison, input limits")
