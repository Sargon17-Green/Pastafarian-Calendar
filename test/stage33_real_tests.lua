local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
for _,signed in ipairs({-1,1}) do
 local sauce=O.sauce(F,F+signed)
 local stream=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local oracleRank=O.chooseRankShort(stream,922)
 local expected=B.add(41,oracleRank)
 local corrected,ctx=S.gateGapPatchProbe(signed,stream.first,stream.directionStep)
 local historical=S.legacyGateGapProbe(signed,stream.first,stream.directionStep)
 assert(B.compare(corrected,expected)==0
  and B.compare(historical,B.add(expected,1))==0
  and ctx.semanticState.questionDayDecimal==tostring(B.add(F,signed))
  and ctx.semanticState.selectedRankDecimal==tostring(oracleRank)
  and ctx.legacyGapSemanticState.historicalGapDecimal==tostring(historical))
end
print("PASS Stage 33 real: two authentic canonical sauce gate selections corrected, legacy preserved")
