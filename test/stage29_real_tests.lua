local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local f=O.FOUNDATION_DAY
local sauce=O.sauce(f,f)
local stream=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
for _,n in ipairs({B.add(O.M,1),B.mul(O.M,O.M)}) do
 local expected=O.chooseRankWide(stream,n)
 local result,ctx=S.wideChoicePatchProbe(stream.first,stream.directionStep,n)
 assert(B.compare(result,expected)==0
    and ctx.semanticState.firstDecimal==tostring(stream.first)
    and ctx.legacyWideSemanticState.wideRankAvailable==false
    and ctx.semanticState.wideRankAvailable==true)
end
print("PASS Stage 29 real: two sauce-derived wide selections match independent oracle")
