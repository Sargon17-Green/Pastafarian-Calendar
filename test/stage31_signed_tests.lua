local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local correctedNegatives=0
for step=-150,150 do
 local corrected,ctx=S.gateQuestionPatchProbe(step)
 local want=B.add(F,step)
 local legacy=B.add(F,B.abs(step))
 assert(B.compare(corrected,want)==0
  and B.compare(S.gateQuestionDaySpaghetti(step),want)==0
  and B.compare(S.legacyGateQuestionProbe(step),legacy)==0)
 assert(ctx.mode=="STAGE_31_PATCH_15"
  and ctx.phase=="PATCH_SIGNED_GATE_QUESTION_DAY"
  and ctx.status=="PATCH_SIGNED_GATE_COMPLETE"
  and ctx.commitToken==3 and #ctx.branchTrace==3
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.currentHandler=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 local st=ctx.semanticState
 assert(st.source=="PATCH_15_SIGNED_GATE_QUESTION"
  and st.signedStepDecimal==tostring(B.from(step))
  and st.distanceMagnitudeDecimal==tostring(B.abs(step))
  and st.foundationDayDecimal==tostring(F)
  and st.legacyQuestionDayDecimal==tostring(legacy)
  and st.correctedQuestionDayDecimal==tostring(want)
  and st.originalLegacyStatePreserved and st.originalSignUsed
  and st.previousCommitCount==2
  and st.noGateChainConstructed and st.noPostStir12
  and st.correctedNegativeSide==(step<0))
 assert(ctx.legacyGateSemanticState.queriedDayDecimal==tostring(legacy)
  and ctx.legacyGateSemanticState.signLostForNegative==(step<0)
  and B.compare(ctx.legacyGateQuestionDay,legacy)==0
  and ctx.metrics["legacy.gateSignedInput.calls"]==1
  and ctx.metrics["legacy.gateAbsoluteQuery.calls"]==1
  and ctx.metrics["gateQuestion.patch.calls"]==1
  and #ctx.diagnostics==3
  and ctx.diagnostics[3].code=="PATCH_15_RESTORE_SIGNED_GATE_SIDE")
 if step<0 then
  assert(ctx.metrics["gateQuestion.patch.negativeCorrections"]==1
   and B.compare(corrected,legacy)~=0)
  correctedNegatives=correctedNegatives+1
 else
  assert(ctx.metrics["gateQuestion.patch.negativeCorrections"]==nil
   and B.compare(corrected,legacy)==0)
 end
end
assert(correctedNegatives==150)
print("PASS Stage 31 signed: 301 exact oracle days, 150 negative repairs, 3 commits and historical states")
