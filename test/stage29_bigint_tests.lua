local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local P=B.mul(M,M)
local n=B.add(B.floorDiv(P,2),1)
local rank,proof=S.wideChoiceCoreProbe(M,-1,n)
local w=B.sub(P,B.add(M,1))
local expectedRejected=B.sub(w,n)
assert(proof.digitCount==2
 and B.compare(proof.initial,w)==0
 and B.compare(proof.limit,n)==0
 and B.compare(proof.rejected,expectedRejected)==0
 and B.compare(proof.rejected,B.pow(2,64))>0
 and proof.usedLargeSkip and proof.checkedRejections==64
 and B.compare(proof.accepted,n)==0 and B.compare(rank,n)==0)
local public,ctx=S.wideChoicePatchProbe(M,-1,n)
assert(B.compare(public,rank)==0
 and ctx.semanticState.usedContiguousSkip
 and ctx.semanticState.rejectedCountDecimal==tostring(expectedRejected)
 and ctx.metrics["wideChoice.patch.largeSkips"]==1)
local n2=B.add(B.floorDiv(P,2),1)
local positive,p2=S.wideChoiceCoreProbe(B.sub(M,1),1,n2)
assert(B.compare(p2.initial,B.sub(P,1))==0
 and B.compare(p2.rejected,2)==0
 and B.compare(p2.accepted,1)==0
 and B.compare(positive,1)==0)
for _,power in ipairs({2,3,4,5}) do
 local size=B.add(B.pow(M,power),1)
 local r=S.choiceSpaghetti(1,1,size)
 assert(B.compare(r,1)>=0 and B.compare(r,size)<=0)
end
for _,bad in ipairs({0,-1,false,{},1.5,"0"}) do
 assert(not pcall(S.wideChoicePatchProbe,1,1,bad))
end
assert(not pcall(S.wideChoicePatchProbe,1,1,M))
assert(not pcall(S.wideChoicePatchProbe,B.add(M,1),1,B.add(M,1)))
assert(not pcall(S.wideChoicePatchProbe,1,0,B.add(M,1)))
print("PASS Stage 29 BigInt: >2^64 exact wide rejections, two directions, M^5+1")
