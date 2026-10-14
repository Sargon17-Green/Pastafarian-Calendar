-- DISCOVERY 17: kalkil pòtay pozitif istorik pa akimile entèval yo.
-- Gap i soti nan PATCH 16, men legacy toujou mezire li apati Fondasyon F.
-- Pou n>=2, ansyen pozisyon an se F+gap(n), olye F+sum(gap(1)..gap(n)).
-- Sous repons pre-kalkile yo bay kòm antre; pa gen jeneratè sauce pwodiksyon.
local B=require("bigint")
local Base=require("monster_base")
local GateGap=require("gate_gap_patch")
local Legacy={}
local F=B.from("-15055671")
local ONE=B.from(1)
local LO=B.from(42)
local HI=B.from(963)

local function clone(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={}
 seen[v]=out
 for k,x in pairs(v) do out[clone(k,seen)]=clone(x,seen) end
 return out
end

local function validate(n,streams)
 assert(type(n)=="number" and math.type(n)=="integer"
  and n>=1 and n<=32,"DISCOVERY 17: index pozitif dwe 1..32")
 assert(type(streams)=="table" and #streams==n,
  "DISCOVERY 17: egzakteman n sous SAVE yo obligatwa")
 for i=1,n do
  local s=streams[i]
  assert(type(s)=="table" and s.first~=nil
    and (s.directionStep==1 or s.directionStep==-1)
    and type(s.directionStep)=="number"
    and math.type(s.directionStep)=="integer",
   "DISCOVERY 17: sous SAVE nan etap "..i.." pa valab")
 end
 return n
end

function Legacy.oldPositivePosition(lastGap)
 local gap=B.from(lastGap)
 assert(B.compare(gap,LO)>=0 and B.compare(gap,HI)<=0,
  "DISCOVERY 17: gap ki soti nan PATCH 16 dwe 42..963")
 return B.add(F,gap)
end

function Legacy.execute(index,streams)
 local n=validate(index,streams)
 local gaps,ownedStates={},{}
 local running=B.from(F)
 local latestCtx
 for i=1,n do
  local source=streams[i]
  local gap,child=GateGap.execute(i,source.first,source.directionStep)
  assert(type(child)=="table" and child.mode=="STAGE_33_PATCH_16"
    and child.status=="PATCH_GATE_GAP_COMPLETE"
    and child.phase=="PATCH_GATE_GAP_OFFSET"
    and child.commitToken==5 and #child.branchTrace==5
    and child.currentHandler=="GATE_GAP_OFFSET_PATCH"
    and child.pendingSemanticState==nil and child.rollbackSnapshot==nil
    and child.semanticState.source=="PATCH_16_GATE_GAP_OFFSET"
    and child.semanticState.signedStepDecimal==tostring(i)
    and child.semanticState.firstDecimal==tostring(B.from(source.first))
    and child.semanticState.directionStep==source.directionStep
    and child.semanticState.correctedGapDecimal==tostring(gap)
    and child.metrics["gateGap.patch.calls"]==1
    and B.compare(gap,LO)>=0 and B.compare(gap,HI)<=0,
   "DISCOVERY 17: PATCH 16 gap oswa provenance pa otantik")
  gaps[i]=B.from(gap)
  ownedStates[i]=clone(child.semanticState)
  running=B.add(running,gap)
  latestCtx=child
 end
 local old=Legacy.oldPositivePosition(gaps[n])
 assert(B.compare(old,B.add(F,gaps[n]))==0,
  "DISCOVERY 17: eritaj mezire dènye gap depi Fondasyon")
 latestCtx.gapSourceStates=ownedStates
 latestCtx.positiveGapDecimals={}
 for i=1,n do latestCtx.positiveGapDecimals[i]=tostring(gaps[i]) end
 latestCtx.lastCorrectedGap=B.from(gaps[n])
 latestCtx.correctCumulativeDayForAudit=B.from(running)
 latestCtx.gateIndex=n
 latestCtx.previousGateGapState=clone(latestCtx.semanticState)
 latestCtx.mode="STAGE_34_DISCOVERY_17"
 latestCtx.phase="LEGACY_POSITIVE_GATE_ANCHOR"
 latestCtx.status="LEGACY_POSITIVE_GATE_PENDING"
 local manager=Base.MonsterManager.new(latestCtx)
 manager.dispatcher:register("LEGACY_POSITIVE_GATE_RESETS_FOUNDATION",function(active,owner)
  local result=Legacy.oldPositivePosition(gaps[n])
  assert(B.compare(result,old)==0,
   "DISCOVERY 17: jou legacy pa soti nan dènye gap la")
  local state={
   source="LEGACY_POSITIVE_GATE_LAST_GAP_ONLY",
   gateIndex=n,
   foundationDayDecimal=tostring(F),
   gapDecimals=clone(active.positiveGapDecimals),
   lastGapDecimal=tostring(gaps[n]),
   historicalGateDayDecimal=tostring(result),
   referenceCumulativeDayDecimal=tostring(running),
   resetOriginEachStep=true,
   usedOnlyLastGap=true,
   noCumulativeChain=true,
   signedQuestionsAndGapPatchCorrect=true,
   historicalDivergence=(n>1),
   previousGapCommitCount=5,
   correctedPositiveChainAvailable=false
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("legacy.positiveGate.calls")
  owner.metricsManager:observe("legacy.positiveGate.n",n)
  owner.metricsManager:observe("legacy.positiveGate.lastGap",tostring(gaps[n]))
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY_17_FORGETS_PREVIOUS_POSITIVE_GAPS",
   gateIndex=n,historicalDay=tostring(result),
   cumulativeDay=tostring(running)
  }
  active.status="LEGACY_POSITIVE_GATE_COMPLETE"
  return B.from(result)
 end)
 local wrong=manager.dispatcher:dispatch(latestCtx,
  "LEGACY_POSITIVE_GATE_RESETS_FOUNDATION",manager)
 return B.from(wrong),latestCtx
end

return Legacy
