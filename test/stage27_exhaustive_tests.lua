local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
local nvalues={1,2,3,4,5,7,11,13,17,31,97,1000}
local counts={passed=0,changed=0,withReject=0}
for _,n in ipairs(nvalues) do
 local seeds={}
 for first=1,25 do seeds[#seeds+1]=B.from(first) end
 for delta=0,25 do seeds[#seeds+1]=B.sub(M,delta) end
 for _,seed in ipairs(seeds) do
  for _,direction in ipairs({-1,1}) do
   local rank,proof=S.shortChoiceCoreProbe(seed,direction,n)
   local expected=O.chooseRankShort({first=seed,directionStep=direction},B.from(n))
   assert(B.compare(rank,expected)==0,"Short choice mismatch for N="..n)
   local old=S.oldBiasedModuloPickProbe(seed,direction,n)
   if B.compare(rank,old)~=0 then counts.changed=counts.changed+1 end
   if B.compare(proof.rejected,0)>0 then counts.withReject=counts.withReject+1 end
   assert(B.compare(proof.accepted,proof.limit)<=0)
   assert(B.compare(proof.index,proof.rejected)==0)
   assert(B.compare(rank,1)>=0 and B.compare(rank,n)<=0)
   counts.passed=counts.passed+1
  end
 end
end
assert(counts.passed==12*51*2 and counts.changed>0 and counts.withReject>0)
for _,n in ipairs({B.from(M),B.sub(M,1),B.floorDiv(M,2)}) do
 for _,seed in ipairs({B.from(1),B.from(2),B.from(10),B.sub(M,1),B.from(M)}) do
  -- Rejè direksyon negatif pou gwo N kapab egzije >2^64 echantiyon.
  -- Pou test exhaustif ki sèvi oracle lineyè, pran +1 sou fen rejyon an.
  local direction=1
  local rank,proof=S.shortChoiceCoreProbe(seed,direction,n)
  local canonical=O.chooseRankShort({first=seed,directionStep=direction},n)
  assert(B.compare(rank,canonical)==0)
  counts.passed=counts.passed+1
 end
end
for _,bad in ipairs({0,-1,B.add(M,1),false,{},1.5}) do
 assert(not pcall(S.shortChoiceCoreProbe,1,1,bad))
end
for _,badStep in ipairs({0,2,-2,1.5,"1",false}) do
 assert(not pcall(S.shortChoiceCoreProbe,1,badStep,5))
end
print("PASS Stage 27 exhaustive: "..counts.passed.." independent oracle short choices; "
 ..counts.changed.." corrected modulo differences")
