-- Stage51/PATCH25: exact three-way midpoint equality; Stage50 legacy is preserved.
-- Diagnostic only. No public calendar-date field, GCD, floating point or year logic.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_midpoint")
local Patch={}

local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[own(k,seen)]=own(x,seen) end
 return out
end

function Patch.execute(day,records)
 local historical,ctx=Legacy.execute(day,records)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_50_DISCOVERY_25"
  and ctx.phase=="LEGACY_MIDPOINT_TIE_BEFORE"
  and ctx.status=="LEGACY_MIDPOINT_COMPLETE"
  and ctx.commitToken==13 and #ctx.branchTrace==13 and #ctx.diagnostics==13
  and ctx.currentHandler=="LEGACY_MIDPOINT_TIE_BEFORE"
  and ctx.diagnostics[13].code=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.metrics["discovery25.midpoint.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH25: authenticated Stage50 thirteen-commit context required")
 local prior=ctx.semanticState
 assert(type(prior)=="table" and prior.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and prior.tieMislabeledBefore==true
  and prior.preservedHistoricalCommitCount==12
  and prior.ownedGateSnapshots and prior.noYearLogic
  and prior.noPostStir12 and prior.noNormativeOracleCalled
  and prior.legacyMidpointLabel==historical
  and type(ctx.stage49PatchedPhaseSemanticState)=="table"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE"
  and ctx.stage49PatchedPhaseSemanticState.correctedFraction==prior.exactPhaseFraction,
  "PATCH25: historical midpoint provenance missing")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local offset=B.sub(d,a)
 local twice=B.add(offset,offset)
 assert(prior.requestedDayDecimal==tostring(d)
  and prior.offsetDecimal==tostring(offset)
  and prior.gapDecimal==tostring(gap)
  and prior.twiceOffsetDecimal==tostring(twice)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(offset,0)>=0 and B.compare(offset,gap)<0
  and prior.exactPhaseFraction==tostring(offset).."/"..tostring(gap),
  "PATCH25: Stage50 exact endpoint values mismatched")
 local cmp=B.compare(twice,gap)
 local predictedHistorical=(cmp<=0) and "BEFORE_MIDPOINT" or "AFTER_MIDPOINT"
 assert(historical==predictedHistorical,"PATCH25: controlled legacy midpoint fault changed")
 local corrected=(cmp<0 and "BEFORE_MIDPOINT") or
  (cmp==0 and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 ctx.stage50LegacyMidpointSemanticState=own(prior)
 ctx.mode="STAGE_51_PATCH_25"
 ctx.phase="PATCH_MIDPOINT_TIE_EQUALITY"
 ctx.status="PATCH_MIDPOINT_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_MIDPOINT_EQUALITY_PATCH",function(active,owner)
  local state={
   source="PATCH_25_MIDPOINT_TIE_EQUALITY",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   offsetDecimal=tostring(offset),gapDecimal=tostring(gap),
   twiceOffsetDecimal=tostring(twice),exactPhaseFraction=prior.exactPhaseFraction,
   legacyMidpointLabel=historical,correctedMidpointLabel=corrected,
   tieEqualityRestored=true,preservedHistoricalCommitCount=13,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,
   noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch25.midpoint.repairs")
  owner.metricsManager:observe("patch25.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
    code="PATCH25_MIDPOINT_TIE_EQUALITY",
    gateIndex=prior.correctedGateIndex,
    historicalLabel=historical,correctedLabel=corrected,
    exactPhaseFraction=prior.exactPhaseFraction}
  active.status="PATCH_MIDPOINT_COMPLETE"
  return corrected
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_MIDPOINT_EQUALITY_PATCH",manager),ctx
end

return Patch
