-- Stage 36 DISCOVERY 18: legacy negative gate keeps only the last correct gap.
-- It is intentionally wrong for n>=2; PATCH18 must not be applied here.
local B=require("bigint")
local Base=require("monster_base")
local GateGap=require("gate_gap_patch")
local Legacy={}
local F=B.from("-15055671")
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

local function validate(n,streams)
 assert(type(n)=="number" and math.type(n)=="integer" and n>=1 and n<=32,
  "DISCOVERY 18: endis negatif absoli dwe 1..32")
 assert(type(streams)=="table" and #streams==n,
  "DISCOVERY 18: egzakteman n sous SAVE yo obligatwa")
 for k in pairs(streams) do
  assert(type(k)=="number" and math.type(k)=="integer" and k>=1 and k<=n,
   "DISCOVERY 18: endis stream pa dense")
 end
 for i=1,n do
  local s=streams[i]
  assert(type(s)=="table" and s.first~=nil
   and type(s.directionStep)=="number"
   and math.type(s.directionStep)=="integer"
   and (s.directionStep==1 or s.directionStep==-1),
   "DISCOVERY 18: sous SAVE nan etap "..i.." pa valab")
  B.from(s.first)
 end
 return n
end

function Legacy.oldNegativePosition(lastGap)
 local gap=B.from(lastGap)
 assert(B.compare(gap,LO)>=0 and B.compare(gap,HI)<=0,
  "DISCOVERY 18: gap dwe ant 42 ak 963")
 return B.sub(F,gap)
end

function Legacy.execute(index,streams)
 local n=validate(index,streams)
 local gaps,ownedStates={},{}
 local latestCtx
 for i=1,n do
  local s=streams[i]
  local gap,child=GateGap.execute(-i,s.first,s.directionStep)
  assert(type(child)=="table"
   and child.mode=="STAGE_33_PATCH_16"
   and child.status=="PATCH_GATE_GAP_COMPLETE"
   and child.phase=="PATCH_GATE_GAP_OFFSET"
   and child.commitToken==5 and #child.branchTrace==5
   and child.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
   and child.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
   and child.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
   and child.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
   and child.branchTrace[5]=="GATE_GAP_OFFSET_PATCH"
   and child.currentHandler=="GATE_GAP_OFFSET_PATCH"
   and child.pendingSemanticState==nil and child.rollbackSnapshot==nil
   and type(child.semanticState)=="table"
   and child.semanticState.source=="PATCH_16_GATE_GAP_OFFSET"
   and child.semanticState.signedStepDecimal==tostring(-i)
   and child.semanticState.questionDayDecimal==tostring(B.sub(F,i))
   and child.semanticState.firstDecimal==tostring(B.from(s.first))
   and child.semanticState.directionStep==s.directionStep
   and child.semanticState.correctedGapDecimal==tostring(gap)
   and child.semanticState.correctedOffsetDecimal=="41"
   and child.semanticState.priorCommitCount==4
   and child.semanticState.originalSignedQueryPreserved==true
   and child.semanticState.originalChoiceRankPreserved==true
   and child.semanticState.legacyExtraOnePreserved==true
   and type(child.diagnostics)=="table" and #child.diagnostics==5
   and child.diagnostics[5].code=="PATCH_16_REMOVE_GATE_GAP_EXTRA_ONE"
   and type(child.metrics)=="table"
   and child.metrics["gateGap.patch.calls"]==1
   and B.compare(gap,LO)>=0 and B.compare(gap,HI)<=0,
   "DISCOVERY 18: sous, siy oswa provenance PATCH 16 pa otantik")
  gaps[i]=B.from(gap)
  ownedStates[i]=clone(child.semanticState)
  latestCtx=child
 end
 local wrong=Legacy.oldNegativePosition(gaps[n])
 latestCtx.gapSourceStates=ownedStates
 latestCtx.negativeGapDecimals={}
 for i=1,n do latestCtx.negativeGapDecimals[i]=tostring(gaps[i]) end
 latestCtx.lastCorrectedGap=B.from(gaps[n])
 latestCtx.negativeGateIndex=-n
 latestCtx.previousGateGapState=clone(latestCtx.semanticState)
 latestCtx.mode="STAGE_36_DISCOVERY_18"
 latestCtx.phase="LEGACY_NEGATIVE_GATE_ANCHOR"
 latestCtx.status="LEGACY_NEGATIVE_GATE_PENDING"
 local manager=Base.MonsterManager.new(latestCtx)
 manager.dispatcher:register("LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION",function(active,owner)
  local value=Legacy.oldNegativePosition(gaps[n])
  assert(B.compare(value,wrong)==0,
   "DISCOVERY 18: ansyen jou pa sèvi sèlman dènye gap la")
  local state={
   source="LEGACY_NEGATIVE_GATE_LAST_GAP_ONLY",
   negativeGateIndex=-n,
   foundationDayDecimal=tostring(F),
   gapDecimals=clone(active.negativeGapDecimals),
   lastGapDecimal=tostring(gaps[n]),
   historicalNegativeGateDayDecimal=tostring(value),
   missingPreviousGaps=true,
   usedOnlyLastGap=true,
   noCorrectCumulativeResultComputed=true,
   previousGapCommitCount=5,
   historicalDivergence=(n>1),
   noPositiveGatePatchMutated=true,
   noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("legacy.negativeGate.calls")
  owner.metricsManager:observe("legacy.negativeGate.n",n)
  owner.metricsManager:observe("legacy.negativeGate.lastGap",tostring(gaps[n]))
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY_18_FORGETS_PREVIOUS_NEGATIVE_GAPS",
   negativeGateIndex=-n,
   historicalDay=tostring(value),
   previousGapCount=n-1
  }
  active.status="LEGACY_NEGATIVE_GATE_COMPLETE"
  return B.from(value)
 end)
 local result=manager.dispatcher:dispatch(latestCtx,
  "LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION",manager)
 return B.from(result),latestCtx
end
return Legacy
