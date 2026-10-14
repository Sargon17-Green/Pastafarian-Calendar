local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
for _,rank in ipairs({1,2,7,921,922}) do
 local corrected,proof=S.gateGapCoreProbe(rank,42+rank)
 assert(B.compare(corrected,41+rank)==0
  and B.compare(proof.oldGap,42+rank)==0
  and B.compare(proof.newGap,41+rank)==0
  and proof.removedExtraOne)
end
for _,rank in ipairs({0,-1,923,B.pow(10,50),false,{}}) do
 assert(not pcall(S.gateGapCoreProbe,rank,43))
end
for _,wrong in ipairs({0,42,964,-1,false,{}}) do
 assert(not pcall(S.gateGapCoreProbe,1,wrong))
end
local huge=B.pow(10,150)
local count=0
for _,signed in ipairs({huge,B.neg(huge),B.add(huge,1),B.sub(B.neg(huge),1)}) do
 for _,dir in ipairs({1,-1}) do
  local first=B.sub(O.M,7)
  local rank=O.chooseRankShort({first=first,directionStep=dir},922)
  local corrected,ctx=S.gateGapPatchProbe(signed,first,dir)
  assert(B.compare(corrected,B.add(41,rank))==0
   and ctx.semanticState.signedStepDecimal==tostring(signed)
   and ctx.semanticState.questionDayDecimal==tostring(B.add(O.FOUNDATION_DAY,signed)))
  count=count+1
 end
end
assert(count==8)
print("PASS Stage 33 BigInt: 8 exact huge signed steps, 42..963 boundaries and invalid proof rejection")
