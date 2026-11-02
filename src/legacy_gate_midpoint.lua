-- Stage50/DISCOVERY25: controlled midpoint-tie error, NOT a pre-existing defect.
-- Diagnostic only; no sixth calendar-date component, no floating point or year logic.
local B=require("bigint")
local Base=require("monster_base")
local Phase=require("gate_phase_patch")
local M={}
local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[own(k,seen)]=own(x,seen) end
 return out
end

function M.execute(day,records)
 local fraction,ctx=Phase.execute(day,records)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_49_PATCH_24"
  and ctx.phase=="PATCH_EXACT_GATE_PHASE" and ctx.status=="PATCH_PHASE_COMPLETE"
  and ctx.commitToken==12 and #ctx.branchTrace==12 and #ctx.diagnostics==12
  and ctx.currentHandler=="GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH"
  and ctx.diagnostics[12].code=="PATCH24_PHASE_NUMERATOR_ZERO_BASED"
  and ctx.metrics["patch24.phase.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY25 requires authenticated Stage49 twelve commits")
 local prior=ctx.semanticState
 assert(type(prior)=="table" and prior.source=="PATCH_24_ZERO_BASED_PHASE"
  and prior.zeroBasedNumerator and prior.exactDenominator and prior.unreducedFraction
  and prior.ownedGateSnapshots and prior.preservedHistoricalCommitCount==11
  and prior.noYearLogic and prior.noPostStir12 and prior.noNormativeOracleCalled
  and prior.correctedFraction==fraction
  and type(ctx.stage48LegacyPhaseSemanticState)=="table"
  and ctx.stage48LegacyPhaseSemanticState.source=="DISCOVERY24_ONE_BASED_PHASE",
  "DISCOVERY25 cannot authenticate prior phase")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local offset=B.sub(d,a)
 assert(prior.requestedDayDecimal==tostring(d)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(offset,0)>=0 and B.compare(offset,gap)<0
  and prior.correctedNumeratorDecimal==tostring(offset)
  and prior.denominatorDecimal==tostring(gap)
  and fraction==tostring(offset).."/"..tostring(gap),
  "DISCOVERY25 corrected exact phase provenance mismatch")
 local twice=B.add(offset,offset)
 local comparison=B.compare(twice,gap)
 -- INTENTIONAL new fault: exact midpoint equality is mislabeled BEFORE.
 local historical=(comparison<=0) and "BEFORE_MIDPOINT" or "AFTER_MIDPOINT"
 ctx.stage49PatchedPhaseSemanticState=own(prior)
 ctx.mode="STAGE_50_DISCOVERY_25"
 ctx.phase="LEGACY_MIDPOINT_TIE_BEFORE"
 ctx.status="LEGACY_MIDPOINT_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_MIDPOINT_TIE_BEFORE",function(active,owner)
  local state={
   source="DISCOVERY25_MIDPOINT_TIE_BEFORE",correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),openingGateDayDecimal=tostring(a),
   nextGateDayDecimal=tostring(b),offsetDecimal=tostring(offset),
   gapDecimal=tostring(gap),twiceOffsetDecimal=tostring(twice),
   exactPhaseFraction=fraction,legacyMidpointLabel=historical,
   tieMislabeledBefore=true,preservedHistoricalCommitCount=12,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,
   noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery25.midpoint.lookups")
  owner.metricsManager:observe("discovery25.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
    code="DISCOVERY25_MIDPOINT_TIE_BEFORE",gateIndex=prior.correctedGateIndex,
    exactPhaseFraction=fraction,legacyLabel=historical}
  active.status="LEGACY_MIDPOINT_COMPLETE"
  return historical
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_MIDPOINT_TIE_BEFORE",manager),ctx
end
return M
