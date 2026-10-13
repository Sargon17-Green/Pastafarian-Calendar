local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local N=B.add(B.floorDiv(M,2),1)
local threshold=B.mul(B.floorDiv(M,N),N)
assert(B.compare(threshold,N)==0)
-- Direksyon -1 depase 2^64 rejè si nou mache youn apre lòt.
local corrected,ctx=S.shortChoicePatchProbe(M,-1,N)
local index=B.sub(M,N)
assert(B.compare(index,B.from("18446744073709551616"))>0)
assert(B.compare(corrected,N)==0
 and ctx.semanticState.acceptedSampleIndexDecimal==tostring(index)
 and ctx.semanticState.acceptedAnswerDecimal==tostring(N)
 and ctx.semanticState.usedContiguousRejectionSkip==true
 and ctx.semanticState.checkedRejectedSamples==64
 and ctx.metrics["shortChoice.patch.largeSkipProofs"]==1)
local prev=S.answerAtSpaghetti(M,-1,B.sub(index,1))
assert(B.compare(prev,B.add(N,1))==0)
local wrapped,wrappedCtx=S.shortChoicePatchProbe(M,1,N)
assert(B.compare(wrapped,1)==0
 and wrappedCtx.semanticState.acceptedSampleIndexDecimal=="1"
 and wrappedCtx.semanticState.acceptedAnswerDecimal=="1")
for _,n in ipairs({B.from(1),B.from(M),B.sub(M,1),B.floorDiv(M,2)}) do
 for _,step in ipairs({-1,1}) do
  local seed=B.from(1)
  local rank=S.shortChoicePatchProbe(seed,step,n)
  assert(B.compare(rank,1)==0)
 end
end
print("PASS Stage 27 BigInt: >2^64 logical rejections in constant work, exact first acceptance")
