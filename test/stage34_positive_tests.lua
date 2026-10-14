local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local cases,differences=0,0
for n=1,8 do
 for scenario=1,3 do
  local streams,gaps={},{}
  local expected=B.from(F)
  for i=1,n do
   local first=((i+scenario)*131)%920+1
   local dir=(i+scenario)%2==0 and 1 or -1
   streams[i]={first=B.from(first),directionStep=dir}
   local rank=O.chooseRankShort(streams[i],922)
   gaps[i]=B.add(41,rank)
   expected=B.add(expected,gaps[i])
  end
  local historic,ctx=S.legacyPositiveGateProbe(n,streams)
  local wrong=B.add(F,gaps[n])
  assert(B.compare(historic,wrong)==0
   and B.compare(S.positiveGateDaySpaghetti(n,streams),wrong)==0)
  assert(ctx.mode=="STAGE_34_DISCOVERY_17"
   and ctx.phase=="LEGACY_POSITIVE_GATE_ANCHOR"
   and ctx.status=="LEGACY_POSITIVE_GATE_COMPLETE"
   and ctx.commitToken==6 and #ctx.branchTrace==6
   and ctx.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
   and ctx.branchTrace[6]=="LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"
   and ctx.currentHandler=="LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
  local st=ctx.semanticState
  assert(st.source=="LEGACY_POSITIVE_GATE_LAST_GAP_ONLY"
   and st.gateIndex==n
   and st.foundationDayDecimal==tostring(F)
   and st.lastGapDecimal==tostring(gaps[n])
   and st.historicalGateDayDecimal==tostring(wrong)
   and st.resetOriginEachStep and st.noCorrectCumulativeResultComputed
   and st.usedOnlyLastGap
   and st.noCumulativeChain and st.signedQuestionsAndGapPatchCorrect
   and st.historicalDivergence==(n>1)
   and st.previousGapCommitCount==5
   and st.correctedPositiveChainAvailable==false)
  assert(#st.gapDecimals==n and #ctx.gapSourceStates==n
   and #ctx.positiveGapDecimals==n
   and ctx.gateIndex==n
   and ctx.correctCumulativeDayForAudit==nil
   and B.compare(ctx.lastCorrectedGap,gaps[n])==0
   and ctx.metrics["legacy.positiveGate.calls"]==1
   and #ctx.diagnostics==6
   and ctx.diagnostics[6].code=="DISCOVERY_17_FORGETS_PREVIOUS_POSITIVE_GAPS")
  for i=1,n do
   assert(st.gapDecimals[i]==tostring(gaps[i])
    and ctx.gapSourceStates[i].source=="PATCH_16_GATE_GAP_OFFSET"
    and ctx.gapSourceStates[i].signedStepDecimal==tostring(i)
    and ctx.gapSourceStates[i].correctedGapDecimal==tostring(gaps[i]))
  end
  ctx.gapSourceStates[1].correctedGapDecimal="TAMPERED"
  assert(ctx.semanticState.gapDecimals[1]==tostring(gaps[1]))
  if n==1 then assert(B.compare(historic,expected)==0)
  else
   assert(B.compare(historic,expected)<0)
   differences=differences+1
  end
  cases=cases+1
 end
end
assert(cases==24 and differences==21)
print("PASS Stage 34 positive: 24 oracle chains, 21 cumulative divergences, all six commits")
