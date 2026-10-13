local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local huge=B.pow(10,120)
for _,step in ipairs({huge,B.neg(huge),B.add(huge,1),B.sub(B.neg(huge),1)}) do
 for _,dir in ipairs({1,-1}) do
  local first=B.sub(O.M,7)
  local value,ctx=S.legacyGateGapProbe(step,first,dir)
  local normRank=O.chooseRankShort({first=first,directionStep=dir},922)
  assert(B.compare(value,B.add(42,normRank))==0
   and ctx.semanticState.questionDayDecimal==tostring(B.add(O.FOUNDATION_DAY,step))
   and ctx.semanticState.signedStepDecimal==tostring(step))
 end
end
for _,bad in ipairs({0,-1,923,"924",false,1.5,{}}) do
 assert(not pcall(S.oldGateGapFromRankProbe,bad))
end
for _,bad in ipairs({0,B.add(O.M,1),false,{}}) do
 assert(not pcall(S.legacyGateGapProbe,-1,bad,1))
end
assert(not pcall(S.legacyGateGapProbe,1,1,0))
print("PASS Stage 32 BigInt: 8 huge signed question steps, rank bounds, reject bad stream inputs")
