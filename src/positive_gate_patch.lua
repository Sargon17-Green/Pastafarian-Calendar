-- PATCH 17: reyini tout gap pòtay pozitif yo apre eritaj DISCOVERY 17.
-- Kenbe 6 commits yo, epi ekri setyèm commit pou G(n)=F+sum(gap(1)..gap(n)).
-- Pa modifye modil legacy, pa jwenn repons nan oracle; limit Stage 35 se 1..32.
local B=require("bigint")
local Base=require("monster_base")
local Old=require("legacy_positive_gate_position")
local Short=require("short_choice_patch")
local Patch={}
local F=B.from("-15055671")
local N=B.from(922)
local LO=B.from(42)
local HI=B.from(963)
local ONE=B.from(1)
local function clone(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[clone(k,seen)]=clone(x,seen) end
 return out
end
local function assertDenseGaps(n,gaps)
 assert(type(n)=="number" and math.type(n)=="integer" and n>=1 and n<=32,
  "PATCH 17: endis pozitif dwe 1..32")
 assert(type(gaps)=="table" and #gaps==n,
  "PATCH 17: kantite gap yo pa n")
 for k in pairs(gaps) do
  assert(type(k)=="number" and math.type(k)=="integer" and k>=1 and k<=n,
   "PATCH 17: lis gap la pa dense")
 end
 local values={}
 for i=1,n do
  values[i]=B.from(gaps[i])
  assert(B.compare(values[i],LO)>=0 and B.compare(values[i],HI)<=0,
   "PATCH 17: gap dwe ant 42 ak 963")
 end
 return values
end
function Patch.correctPositiveDay(n,gaps,oldDay)
 local values=assertDenseGaps(n,gaps)
 local wrong=B.from(oldDay)
 assert(B.compare(wrong,B.add(F,values[n]))==0,
  "PATCH 17: jou eritaj pa soti Fondasyon ak denye gap")
 local corrected=B.from(wrong)
 for i=1,n-1 do corrected=B.add(corrected,values[i]) end
 local fromFoundation=B.from(F)
 for i=1,n do fromFoundation=B.add(fromFoundation,values[i]) end
 assert(B.compare(corrected,fromFoundation)==0,
  "PATCH 17: jou kumilatif pa egzak")
 return B.from(corrected),{
  previousDay=B.from(wrong),lastGap=B.from(values[n]),
  correctedDay=B.from(corrected),numberOfGaps=n,
  recomputedFromFoundation=B.from(fromFoundation),
  addedPriorGaps=n-1
 }
end

local function inspectLegacy(wrong,ctx,n,streams)
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_34_DISCOVERY_17"
  and ctx.phase=="LEGACY_POSITIVE_GATE_ANCHOR"
  and ctx.status=="LEGACY_POSITIVE_GATE_COMPLETE"
  and ctx.commitToken==6 and #ctx.branchTrace==6
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
  and ctx.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
  and ctx.branchTrace[6]=="LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"
  and ctx.currentHandler=="LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.gateIndex==n
  and type(ctx.gapSourceStates)=="table" and #ctx.gapSourceStates==n
  and type(ctx.positiveGapDecimals)=="table" and #ctx.positiveGapDecimals==n
  and type(ctx.previousGateGapState)=="table"
  and type(ctx.metrics)=="table"
  and ctx.metrics["legacy.positiveGate.calls"]==1
  and ctx.metrics["gateGap.patch.calls"]==1
  and type(ctx.diagnostics)=="table" and #ctx.diagnostics==6
  and ctx.diagnostics[6].code=="DISCOVERY_17_FORGETS_PREVIOUS_POSITIVE_GAPS"
  and ctx.diagnostics[6].gateIndex==n
  and ctx.diagnostics[6].historicalDay==tostring(wrong)
  and ctx.diagnostics[6].previousGapCount==n-1,
  "PATCH 17: 6 commits legacy pa otantik")
 local s=ctx.semanticState
 assert(type(s)=="table" and s.source=="LEGACY_POSITIVE_GATE_LAST_GAP_ONLY"
  and s.gateIndex==n and s.foundationDayDecimal==tostring(F)
  and s.historicalGateDayDecimal==tostring(wrong)
  and type(s.gapDecimals)=="table" and #s.gapDecimals==n
  and s.resetOriginEachStep==true and s.noCorrectCumulativeResultComputed==true
  and s.usedOnlyLastGap==true and s.noCumulativeChain==true
  and s.signedQuestionsAndGapPatchCorrect==true
  and s.historicalDivergence==(n>1)
  and s.previousGapCommitCount==5
  and s.correctedPositiveChainAvailable==false
  and ctx.correctCumulativeDayForAudit==nil,
  "PATCH 17: eritaj eta final la pa valab")
 local gaps=assertDenseGaps(n,ctx.positiveGapDecimals)
 for i=1,n do
  local source=streams[i]
  assert(type(source)=="table"
   and type(source.directionStep)=="number"
   and math.type(source.directionStep)=="integer"
   and (source.directionStep==1 or source.directionStep==-1),
   "PATCH 17: sous SAVE ki pa otantik")
  local seed=B.from(source.first)
  local rank=Short.chooseShort(seed,source.directionStep,N)
  local expected=B.add(41,rank)
  local historic=B.add(42,rank)
  local state=ctx.gapSourceStates[i]
  assert(B.compare(gaps[i],expected)==0
   and ctx.positiveGapDecimals[i]==tostring(expected)
   and s.gapDecimals[i]==tostring(expected)
   and type(state)=="table"
   and state.source=="PATCH_16_GATE_GAP_OFFSET"
   and state.signedStepDecimal==tostring(i)
   and state.questionDayDecimal==tostring(B.add(F,i))
   and state.firstDecimal==tostring(seed)
   and state.directionStep==source.directionStep
   and state.optionsDecimal=="922"
   and state.selectedRankDecimal==tostring(rank)
   and state.historicalGapDecimal==tostring(historic)
   and state.correctedGapDecimal==tostring(expected)
   and state.historicalOffsetDecimal=="42"
   and state.correctedOffsetDecimal=="41"
   and state.priorCommitCount==4
   and state.legacyExtraOnePreserved==true
   and state.originalSignedQueryPreserved==true
   and state.originalChoiceRankPreserved==true
   and state.noGateSequenceBuilt==true
   and state.noPostStir12==true,
   "PATCH 17: provenance gap rank nan etap "..i.." pa otantik")
 end
 local last=ctx.gapSourceStates[n]
 assert(s.lastGapDecimal==tostring(gaps[n])
  and ctx.previousGateGapState.correctedGapDecimal==last.correctedGapDecimal
  and ctx.previousGateGapState.selectedRankDecimal==last.selectedRankDecimal
  and B.compare(ctx.lastCorrectedGap,gaps[n])==0
  and B.compare(wrong,B.add(F,gaps[n]))==0,
  "PATCH 17: dènye gap pa konsistan ak jou istorik")
 return gaps
end

function Patch.execute(index,streams)
 local wrong,ctx=Old.execute(index,streams)
 local gaps=inspectLegacy(wrong,ctx,index,streams)
 ctx.legacyPositiveSemanticState=clone(ctx.semanticState)
 ctx.legacyPositiveGateDay=B.from(wrong)
 ctx.mode="STAGE_35_PATCH_17"
 ctx.phase="PATCH_POSITIVE_GATE_CUMULATIVE"
 ctx.status="PATCH_POSITIVE_GATE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("POSITIVE_GATE_CUMULATIVE_PATCH",function(active,owner)
  local right,proof=Patch.correctPositiveDay(index,gaps,wrong)
  assert(proof.numberOfGaps==index
   and proof.addedPriorGaps==index-1
   and B.compare(proof.previousDay,wrong)==0
   and B.compare(proof.lastGap,gaps[index])==0
   and B.compare(proof.correctedDay,right)==0
   and B.compare(proof.recomputedFromFoundation,right)==0,
   "PATCH 17: prèv sòm gap yo pa otantik")
  local state={
   source="PATCH_17_CUMULATIVE_POSITIVE_GATE",
   gateIndex=index,
   foundationDayDecimal=tostring(F),
   gapDecimals=clone(active.positiveGapDecimals),
   historicalGateDayDecimal=tostring(wrong),
   lastGapDecimal=tostring(gaps[index]),
   correctedGateDayDecimal=tostring(right),
   previousLegacyCommitCount=6,
   priorGapsAdded=index-1,
   preservedHistoricalReset=true,
   ownedPerGapSnapshots=true,
   noNegativeGateChainBuilt=true,
   noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("positiveGate.patch.calls")
  owner.metricsManager:observe("positiveGate.patch.indices",index)
  owner.metricsManager:observe("positiveGate.patch.correctedDays",tostring(right))
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH_17_ACCUMULATE_ALL_POSITIVE_GAPS",
   gateIndex=index,historicalDay=tostring(wrong),
   correctedDay=tostring(right),addedPreviousGaps=index-1
  }
  active.status="PATCH_POSITIVE_GATE_COMPLETE"
  return B.from(right)
 end)
 local repaired=manager.dispatcher:dispatch(ctx,
  "POSITIVE_GATE_CUMULATIVE_PATCH",manager)
 return B.from(repaired),ctx
end
return Patch
