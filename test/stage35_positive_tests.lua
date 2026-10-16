local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local cases,changed=0,0
for n=1,8 do
 for scenario=1,4 do
  local streams,expectedGaps={},{}
  local oracle=B.from(F)
  for i=1,n do
   local first=1+((i*139+scenario*223)%920)
   local direction=(i+scenario)%2==0 and 1 or -1
   streams[i]={first=B.from(first),directionStep=direction}
   local rank=O.chooseRankShort(streams[i],922)
   expectedGaps[i]=B.add(41,rank)
   oracle=B.add(oracle,expectedGaps[i])
  end
  local corrected,ctx=S.positiveGatePatchProbe(n,streams)
  local historical,older=S.legacyPositiveGateProbe(n,streams)
  assert(B.compare(corrected,oracle)==0
   and B.compare(S.positiveGateDaySpaghetti(n,streams),oracle)==0
   and B.compare(historical,B.add(F,expectedGaps[n]))==0
   and older.commitToken==6)
  assert(ctx.mode=="STAGE_35_PATCH_17"
   and ctx.phase=="PATCH_POSITIVE_GATE_CUMULATIVE"
   and ctx.status=="PATCH_POSITIVE_GATE_COMPLETE"
   and ctx.commitToken==7 and #ctx.branchTrace==7
   and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
   and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
   and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
   and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
   and ctx.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
   and ctx.branchTrace[6]=="LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"
   and ctx.branchTrace[7]=="POSITIVE_GATE_CUMULATIVE_PATCH"
   and ctx.currentHandler=="POSITIVE_GATE_CUMULATIVE_PATCH"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
  local st=ctx.semanticState
  assert(st.source=="PATCH_17_CUMULATIVE_POSITIVE_GATE"
   and st.gateIndex==n
   and st.foundationDayDecimal==tostring(F)
   and st.historicalGateDayDecimal==tostring(historical)
   and st.lastGapDecimal==tostring(expectedGaps[n])
   and st.correctedGateDayDecimal==tostring(oracle)
   and st.previousLegacyCommitCount==6
   and st.priorGapsAdded==n-1
   and st.preservedHistoricalReset and st.ownedPerGapSnapshots
   and st.noNegativeGateChainBuilt and st.noPostStir12)
  assert(type(ctx.legacyPositiveSemanticState)=="table"
   and ctx.legacyPositiveSemanticState.source=="LEGACY_POSITIVE_GATE_LAST_GAP_ONLY"
   and ctx.legacyPositiveSemanticState.historicalGateDayDecimal==tostring(historical)
   and ctx.legacyPositiveSemanticState.correctedPositiveChainAvailable==false
   and ctx.metrics["positiveGate.patch.calls"]==1
   and ctx.metrics["legacy.positiveGate.calls"]==1
   and #ctx.diagnostics==7
   and ctx.diagnostics[7].code=="PATCH_17_ACCUMULATE_ALL_POSITIVE_GAPS"
   and ctx.diagnostics[7].correctedDay==tostring(oracle))
  for i=1,n do
   assert(st.gapDecimals[i]==tostring(expectedGaps[i])
    and ctx.gapSourceStates[i].correctedGapDecimal==tostring(expectedGaps[i]))
  end
  ctx.legacyPositiveSemanticState.gapDecimals[1]="TAMPERED"
  assert(st.gapDecimals[1]==tostring(expectedGaps[1]))
  if n==1 then assert(B.compare(corrected,historical)==0)
  else
   assert(B.compare(corrected,historical)>0)
   changed=changed+1
  end
  cases=cases+1
 end
end
assert(cases==32 and changed==28)
print("PASS Stage 35 positive: 32 independent oracle chains, 28 cumulative corrections, seven commits")
