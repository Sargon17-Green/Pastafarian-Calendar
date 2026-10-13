local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local M=O.M
for _,power in ipairs({2,3,4,5}) do
 local n=B.add(B.pow(M,power),1)
 local missing,ctx=S.legacyShortOnlyChoiceProbe(1,-1,n)
 assert(missing==nil
   and ctx.semanticState.optionCountDecimal==tostring(n)
   and ctx.semanticState.wideRankAvailable==false
   and ctx.commitToken==1)
 local valid=O.chooseRankWide({first=B.from(1),directionStep=-1},n)
 assert(B.compare(valid,1)>=0 and B.compare(valid,n)<=0)
end
local invalid={0,-1,"0",false,{},1.5}
for _,value in ipairs(invalid) do
 assert(not pcall(S.legacyShortOnlyChoiceProbe,1,1,value))
end
for _,value in ipairs({0,B.add(M,1),false,"-3"}) do
 assert(not pcall(S.legacyShortOnlyChoiceProbe,value,1,B.add(M,1)))
end
print("PASS Stage 28 BigInt: N up to M^5+1, no truncated wide ranks")
