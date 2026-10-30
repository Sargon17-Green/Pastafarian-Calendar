-- Stage 37 / PATCH 18. Correct the negative cumulative gate chain.
-- Preserve all six authentic Stage36 legacy commits and append one owned patch.
-- Production does not import normative_oracle or implement postStir12.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_negative_gate_position")
local Short=require("short_choice_patch")
local Patch={}
local F=B.from("-15055671")
local N=B.from(922)
local LO=B.from(42)
local HI=B.from(963)

local function clone(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[clone(k,seen)]=clone(x,seen) end
 return out
end

local function dense(n,gaps)
 assert(type(n)=="number" and math.type(n)=="integer" and n>=1 and n<=32,
  "PATCH 18: endis absoli dwe 1..32")
 assert(type(gaps)=="table" and #gaps==n,
  "PATCH 18: kantite gap yo dwe n")
 for k in pairs(gaps) do
  assert(type(k)=="number" and math.type(k)=="integer" and k>=1 and k<=n,
   "PATCH 18: gap yo dwe dense")
 end
 local values={}
 for i=1,n do
  values[i]=B.from(gaps[i])
  assert(B.compare(values[i],LO)>=0 and B.compare(values[i],HI)<=0,
   "PATCH 18: gap pa nan limit 42..963")
 end
 return values
end

function Patch.correctNegativeDay(n,gaps,historicalDay)
 local values=dense(n,gaps)
 local wrong=B.from(historicalDay)
 assert(B.compare(wrong,B.sub(F,values[n]))==0,
  "PATCH 18: jou legacy pa F - denye gap")
 local right=B.from(wrong)
 for i=1,n-1 do right=B.sub(right,values[i]) end
 local independent=B.from(F)
 for i=1,n do independent=B.sub(independent,values[i]) end
 assert(B.compare(right,independent)==0,
  "PATCH 18: akimilasyon negatif pa egzak")
 return B.from(right),{
  oldDay=B.from(wrong),lastGap=B.from(values[n]),
  patchedDay=B.from(right),fromFoundation=B.from(independent),
  previousGapsSubtracted=n-1,numberOfGaps=n
 }
end

local function inspectLegacy(wrong,ctx,n,streams)
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_36_DISCOVERY_18"
  and ctx.phase=="LEGACY_NEGATIVE_GATE_ANCHOR"
  and ctx.status=="LEGACY_NEGATIVE_GATE_COMPLETE"
  and ctx.commitToken==6 and #ctx.branchTrace==6
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
  and ctx.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
  and ctx.branchTrace[6]=="LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION"
  and ctx.currentHandler=="LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.negativeGateIndex==-n
  and type(ctx.gapSourceStates)=="table" and #ctx.gapSourceStates==n
  and type(ctx.negativeGapDecimals)=="table" and #ctx.negativeGapDecimals==n
  and type(ctx.metrics)=="table"
  and ctx.metrics["legacy.negativeGate.calls"]==1
  and type(ctx.diagnostics)=="table" and #ctx.diagnostics==6
  and ctx.diagnostics[6].code=="DISCOVERY_18_FORGETS_PREVIOUS_NEGATIVE_GAPS",
  "PATCH 18: sis commits Discovery18 yo pa otantik")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="LEGACY_NEGATIVE_GATE_LAST_GAP_ONLY"
  and s.negativeGateIndex==-n and s.foundationDayDecimal==tostring(F)
  and s.historicalNegativeGateDayDecimal==tostring(wrong)
  and s.missingPreviousGaps==true
  and s.usedOnlyLastGap==true
  and s.noCorrectCumulativeResultComputed==true
  and s.historicalDivergence==(n>1)
  and s.previousGapCommitCount==5
  and s.noPositiveGatePatchMutated==true
  and s.noPostStir12==true,
  "PATCH 18: semantic state legacy la pa otantik")
 local gaps=dense(n,ctx.negativeGapDecimals)
 for i=1,n do
  local source=streams[i]
  assert(type(source)=="table"
   and type(source.directionStep)=="number"
   and math.type(source.directionStep)=="integer"
   and (source.directionStep==1 or source.directionStep==-1),
   "PATCH 18: sous SAVE invalid")
  local seed=B.from(source.first)
  local rank=Short.chooseShort(seed,source.directionStep,N)
  local expected=B.add(41,rank)
  local st=ctx.gapSourceStates[i]
  assert(B.compare(gaps[i],expected)==0
   and tostring(expected)==ctx.negativeGapDecimals[i]
   and tostring(expected)==s.gapDecimals[i]
   and type(st)=="table" and st.source=="PATCH_16_GATE_GAP_OFFSET"
   and st.signedStepDecimal==tostring(-i)
   and st.questionDayDecimal==tostring(B.sub(F,i))
   and st.firstDecimal==tostring(seed)
   and st.directionStep==source.directionStep
   and st.correctedGapDecimal==tostring(expected)
   and st.priorCommitCount==4
   and st.legacyExtraOnePreserved==true
   and st.originalSignedQueryPreserved==true
   and st.originalChoiceRankPreserved==true,
   "PATCH 18: provenance gap negatif pa otantik")
 end
 assert(s.lastGapDecimal==tostring(gaps[n])
  and B.compare(ctx.lastCorrectedGap,gaps[n])==0
  and B.compare(wrong,B.sub(F,gaps[n]))==0,
  "PATCH 18: denye gap legacy pa konsistan")
 return gaps
end

function Patch.execute(index,streams)
 local wrong,ctx=Legacy.execute(index,streams)
 local gaps=inspectLegacy(wrong,ctx,index,streams)
 ctx.legacyNegativeSemanticState=clone(ctx.semanticState)
 ctx.legacyNegativeGateDay=B.from(wrong)
 ctx.mode="STAGE_37_PATCH_18"
 ctx.phase="PATCH_NEGATIVE_GATE_CUMULATIVE"
 ctx.status="PATCH_NEGATIVE_GATE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("NEGATIVE_GATE_CUMULATIVE_PATCH",function(active,owner)
  local right,proof=Patch.correctNegativeDay(index,gaps,wrong)
  assert(proof.numberOfGaps==index
   and proof.previousGapsSubtracted==index-1
   and B.compare(proof.oldDay,wrong)==0
   and B.compare(proof.lastGap,gaps[index])==0
   and B.compare(proof.patchedDay,right)==0
   and B.compare(proof.fromFoundation,right)==0,
   "PATCH 18: de chemen akimilasyon pa dakò")
  local state={
   source="PATCH_18_CUMULATIVE_NEGATIVE_GATE",
   negativeGateIndex=-index,foundationDayDecimal=tostring(F),
   gapDecimals=clone(active.negativeGapDecimals),
   historicalNegativeGateDayDecimal=tostring(wrong),
   lastGapDecimal=tostring(gaps[index]),
   correctedNegativeGateDayDecimal=tostring(right),
   previousLegacyCommitCount=6,priorGapsSubtracted=index-1,
   preservedHistoricalReset=true,ownedPerGapSnapshots=true,
   noPositiveGatePatchMutated=true,noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("negativeGate.patch.calls")
  owner.metricsManager:observe("negativeGate.patch.indices",index)
  owner.metricsManager:observe("negativeGate.patch.correctedDays",tostring(right))
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH_18_ACCUMULATE_ALL_NEGATIVE_GAPS",
   negativeGateIndex=-index,historicalDay=tostring(wrong),
   correctedDay=tostring(right),subtractedPreviousGaps=index-1
  }
  active.status="PATCH_NEGATIVE_GATE_COMPLETE"
  return B.from(right)
 end)
 local repaired=manager.dispatcher:dispatch(ctx,
  "NEGATIVE_GATE_CUMULATIVE_PATCH",manager)
 return B.from(repaired),ctx
end
return Patch
