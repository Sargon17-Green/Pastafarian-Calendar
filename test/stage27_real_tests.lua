local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local c=O.FOUNDATION_DAY
local cases={{c,c},{c,c+1}}
for _,pair in ipairs(cases) do
 local sauce=O.sauce(pair[1],pair[2])
 local stream=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local result,ctx=S.shortChoicePatchProbe(stream.first,stream.directionStep,922)
 local want=O.chooseRankShort(stream,922)
 assert(B.compare(result,want)==0
   and ctx.semanticState.optionCountDecimal=="922"
   and ctx.commitToken==3
   and ctx.status=="PATCH_SHORT_CHOICE_COMPLETE")
end
print("PASS Stage 27 real: two genuine canonical sauce-derived short streams")
