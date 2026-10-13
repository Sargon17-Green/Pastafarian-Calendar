local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
for _,signed in ipairs({-1,1}) do
 local sauce=O.sauce(F,F+signed)
 local stream=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local rank=O.chooseRankShort(stream,922)
 local historical,ctx=S.legacyGateGapProbe(signed,stream.first,stream.directionStep)
 local wanted=B.add(41,rank)
 assert(B.compare(historical,B.add(wanted,1))==0
  and ctx.semanticState.questionDayDecimal==tostring(B.add(F,signed))
  and ctx.semanticState.selectedRankDecimal==tostring(rank)
  and ctx.choiceSemanticState.correctedRankDecimal==tostring(rank))
end
print("PASS Stage 32 real: 2 authentic Foundation-side sauce gate ranks expose +1 historical gap")
