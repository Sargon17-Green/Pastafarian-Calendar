local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local total=0
for signed=-3,3 do
 for _,first in ipairs({1,2,3,921,922}) do
  for _,dir in ipairs({1,-1}) do
   local stream={first=B.from(first),directionStep=dir}
   local normRank=O.chooseRankShort(stream,922)
   local norm=B.add(41,normRank)
   local legacy=B.add(42,normRank)
   local value,ctx=S.legacyGateGapProbe(signed,first,dir)
   assert(B.compare(value,legacy)==0
    and B.compare(value,B.add(norm,1))==0
    and B.compare(S.gateGapSpaghetti(signed,first,dir),legacy)==0)
   assert(ctx.mode=="STAGE_32_DISCOVERY_16"
    and ctx.phase=="LEGACY_GATE_GAP_OFFSET"
    and ctx.status=="LEGACY_GATE_GAP_COMPLETE"
    and ctx.commitToken==4 and #ctx.branchTrace==4
    and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
    and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
    and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
    and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
    and ctx.currentHandler=="LEGACY_GATE_GAP_PLUS_ONE"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
   local st=ctx.semanticState
   assert(st.source=="LEGACY_GATE_GAP_EXTRA_ONE"
    and st.signedStepDecimal==tostring(B.from(signed))
    and st.questionDayDecimal==tostring(B.add(O.FOUNDATION_DAY,signed))
    and st.firstDecimal==tostring(B.from(first))
    and st.directionStep==dir
    and st.selectedRankDecimal==tostring(normRank)
    and st.oldOffsetDecimal=="42"
    and st.historicalGapDecimal==tostring(legacy)
    and st.noAcceptanceBias and st.signedGateQuestionAlreadyPatched
    and st.legacyOffByOnePreserved and not st.correctedGapAvailable
    and st.previousSignedCommitCount==3 and st.noGateSequenceBuilt)
   assert(ctx.previousSignedGateState.source=="PATCH_15_SIGNED_GATE_QUESTION"
    and ctx.choiceSemanticState.source=="PATCH_13_ACCEPTANCE_REJECTION_SHORT"
    and ctx.choiceCommitCount==3
    and ctx.metrics["legacy.gateGap.extraOne.calls"]==1
    and ctx.diagnostics[4].code=="DISCOVERY_16_GATE_GAP_PLUS_ONE")
   total=total+1
  end
 end
end
assert(total==70)
assert(B.compare(S.oldGateGapFromRankProbe(1),43)==0)
assert(B.compare(S.oldGateGapFromRankProbe(922),964)==0)
print("PASS Stage 32 traces: 70 gate-gap oracle witnesses, four owned commits, 43..964")
