local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local cases={}
for signed=-3,3 do
 for _,first in ipairs({1,2,7,921,922,B.sub(O.M,1)}) do
  for _,dir in ipairs({1,-1}) do
   cases[#cases+1]={signed,first,dir}
  end
 end
end
for signed=-75,74 do cases[#cases+1]={signed,1+((signed+75)%922),1} end
local changed=0
for _,p in ipairs(cases) do
 local signed,first,dir=p[1],p[2],p[3]
 local rank=O.chooseRankShort({first=B.from(first),directionStep=dir},922)
 local historic=B.add(42,rank)
 local correct=B.add(41,rank)
 local got,ctx=S.gateGapPatchProbe(signed,first,dir)
 local old,legacyCtx=S.legacyGateGapProbe(signed,first,dir)
 assert(B.compare(got,correct)==0
  and B.compare(S.gateGapSpaghetti(signed,first,dir),correct)==0
  and B.compare(old,historic)==0
  and B.compare(B.sub(old,got),1)==0
  and legacyCtx.commitToken==4)
 assert(ctx.mode=="STAGE_33_PATCH_16"
  and ctx.phase=="PATCH_GATE_GAP_OFFSET"
  and ctx.status=="PATCH_GATE_GAP_COMPLETE"
  and ctx.commitToken==5 and #ctx.branchTrace==5
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
  and ctx.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
  and ctx.currentHandler=="GATE_GAP_OFFSET_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 local s=ctx.semanticState
 assert(s.source=="PATCH_16_GATE_GAP_OFFSET"
  and s.signedStepDecimal==tostring(B.from(signed))
  and s.questionDayDecimal==tostring(B.add(O.FOUNDATION_DAY,signed))
  and s.firstDecimal==tostring(B.from(first))
  and s.directionStep==dir
  and s.optionsDecimal=="922"
  and s.selectedRankDecimal==tostring(rank)
  and s.historicalOffsetDecimal=="42"
  and s.correctedOffsetDecimal=="41"
  and s.historicalGapDecimal==tostring(historic)
  and s.correctedGapDecimal==tostring(correct)
  and s.priorCommitCount==4 and s.legacyExtraOnePreserved
  and s.originalSignedQueryPreserved and s.originalChoiceRankPreserved
  and s.noGateSequenceBuilt and s.noPostStir12)
 assert(ctx.legacyGapSemanticState.source=="LEGACY_GATE_GAP_EXTRA_ONE"
  and ctx.legacyGapSemanticState.historicalGapDecimal==tostring(historic)
  and ctx.legacyGapSemanticState.correctedGapAvailable==false
  and B.compare(ctx.legacyGapValue,historic)==0
  and ctx.choiceSemanticState.correctedRankDecimal==tostring(rank)
  and ctx.previousSignedGateState.correctedQuestionDayDecimal==tostring(B.add(O.FOUNDATION_DAY,signed))
  and ctx.metrics["legacy.gateGap.extraOne.calls"]==1
  and ctx.metrics["gateGap.patch.calls"]==1
  and ctx.metrics["gateGap.patch.removedExtraOne"]==1
  and #ctx.diagnostics==5
  and ctx.diagnostics[5].code=="PATCH_16_REMOVE_GATE_GAP_EXTRA_ONE")
 ctx.legacyGapSemanticState.historicalGapDecimal="TAMPERED"
 assert(ctx.semanticState.historicalGapDecimal==tostring(historic))
 changed=changed+1
end
assert(changed==234)
print("PASS Stage 33 gate gaps: 234 independent oracle choices, 234 corrected +1 biases, five commits")
