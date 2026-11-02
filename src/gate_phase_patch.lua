-- Stage49/PATCH24: exact zero-based phase numerator; preserve Stage48 historical fault.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_phase")
local Patch={}

local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local z={};seen[v]=z
 for k,x in pairs(v) do z[own(k,seen)]=own(x,seen) end
 return z
end

function Patch.execute(day,records)
 local historical,ctx=Legacy.execute(day,records)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_48_DISCOVERY_24"
  and ctx.phase=="LEGACY_PHASE_ONE_BASED" and ctx.status=="LEGACY_PHASE_COMPLETE"
  and ctx.commitToken==11 and #ctx.branchTrace==11 and #ctx.diagnostics==11
  and ctx.currentHandler=="LEGACY_GATE_PHASE_ONE_BASED"
  and ctx.diagnostics[11].code=="DISCOVERY24_PHASE_OFF_BY_ONE"
  and ctx.metrics["discovery24.phase.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH24: authenticated Stage48 eleven-commit context required")
 local prior=ctx.semanticState
 assert(type(prior)=="table" and prior.source=="DISCOVERY24_ONE_BASED_PHASE"
  and prior.oneBasedNumerator==true and prior.exactDenominator==true
  and prior.preservedHistoricalCommitCount==10
  and prior.ownedGateSnapshots and prior.noYearLogic
  and prior.noPostStir12 and prior.noNormativeOracleCalled
  and type(ctx.stage47SignedOffsetSemanticState)=="table"
  and ctx.stage47SignedOffsetSemanticState.source=="PATCH_23_NEAREST_GATE_SIGNED_OFFSET"
  and ctx.stage47SignedOffsetSemanticState.closingDirectionRestored==true,
  "PATCH24: historical phase provenance missing")
 local d=B.from(day)
 local a,b=B.from(prior.openingGateDayDecimal),B.from(prior.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local offset=B.sub(d,a)
 local historicalNumerator=B.from(prior.historicalNumeratorDecimal)
 assert(prior.requestedDayDecimal==tostring(d)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(offset,0)>=0 and B.compare(offset,gap)<0
  and B.compare(historicalNumerator,B.add(offset,1))==0
  and prior.fraction==historical
  and historical==tostring(historicalNumerator).."/"..tostring(gap)
  and prior.gapDecimal==tostring(gap),
  "PATCH24: one-based numerator or exact denominator mismatch")
 -- Repair one-based numerator exactly; do not reduce the fraction.
 local correctedNumerator=B.sub(historicalNumerator,1)
 assert(B.compare(correctedNumerator,offset)==0)
 local corrected=tostring(correctedNumerator).."/"..tostring(gap)
 ctx.stage48LegacyPhaseSemanticState=own(prior)
 ctx.legacyOneBasedPhaseFraction=historical
 ctx.mode="STAGE_49_PATCH_24"
 ctx.phase="PATCH_EXACT_GATE_PHASE"
 ctx.status="PATCH_PHASE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",function(active,owner)
  local state={
   source="PATCH_24_ZERO_BASED_PHASE",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   historicalFraction=historical,correctedFraction=corrected,
   historicalNumeratorDecimal=tostring(historicalNumerator),
   correctedNumeratorDecimal=tostring(correctedNumerator),
   denominatorDecimal=tostring(gap),
   zeroBasedNumerator=true,exactDenominator=true,unreducedFraction=true,
   preservedHistoricalCommitCount=11,ownedGateSnapshots=true,
   noYearLogic=true,noPostStir12=true,noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch24.phase.repairs")
  owner.metricsManager:observe("patch24.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH24_PHASE_NUMERATOR_ZERO_BASED",gateIndex=prior.correctedGateIndex,
   historicalFraction=historical,correctedFraction=corrected}
  active.status="PATCH_PHASE_COMPLETE"
  return corrected
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",manager),ctx
end

return Patch
