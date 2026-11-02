-- Stage48 DISCOVERY24: new exact gate-phase representation, deliberately one-based.
-- Newly introduced defect; no claim of pre-existing historical fault.
local B=require("bigint")
local Base=require("monster_base")
local Signed=require("gate_signed_offset_patch")
local M={}
local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local z={};seen[v]=z
 for k,x in pairs(v) do z[own(k,seen)]=own(x,seen) end
 return z
end
function M.execute(day,records)
 local signed,ctx=Signed.execute(day,records)
 assert(ctx.mode=="STAGE_47_PATCH_23"
  and ctx.status=="PATCH_SIGNED_OFFSET_COMPLETE"
  and ctx.commitToken==10 and #ctx.branchTrace==10
  and ctx.currentHandler=="GATE_SIGNED_OFFSET_DIRECTION_PATCH"
  and #ctx.diagnostics==10
  and ctx.diagnostics[10].code=="PATCH23_CLOSING_DIRECTION_RESTORED"
  and ctx.metrics["patch23.signed.offsets"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY24 requires authenticated Stage47 ten commits")
 local prior=ctx.semanticState
 assert(prior.source=="PATCH_23_NEAREST_GATE_SIGNED_OFFSET"
  and prior.closingDirectionRestored and prior.zeroCanonical
  and prior.preservedHistoricalCommitCount==9
  and prior.correctedSignedOffsetDecimal==tostring(signed)
  and prior.noYearLogic and prior.noPostStir12 and prior.noNormativeOracleCalled)
 local target=B.from(day)
 local a,b=B.from(prior.openingGateDayDecimal),B.from(prior.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local offset=B.sub(target,a)
 assert(prior.requestedDayDecimal==tostring(target)
  and B.compare(offset,0)>=0 and B.compare(offset,gap)<0
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0)
 -- Deliberate new legacy error: phase numerator is offset+1 rather than offset.
 local numerator=B.add(offset,1)
 local fraction=tostring(numerator).."/"..tostring(gap)
 ctx.stage47SignedOffsetSemanticState=own(prior)
 ctx.mode="STAGE_48_DISCOVERY_24"
 ctx.phase="LEGACY_PHASE_ONE_BASED"
 ctx.status="LEGACY_PHASE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_GATE_PHASE_ONE_BASED",function(active,owner)
  local state={
   source="DISCOVERY24_ONE_BASED_PHASE",correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(target),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   historicalNumeratorDecimal=tostring(numerator),gapDecimal=tostring(gap),
   fraction=fraction,oneBasedNumerator=true,exactDenominator=true,
   preservedHistoricalCommitCount=10,ownedGateSnapshots=true,
   noYearLogic=true,noPostStir12=true,noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery24.phase.lookups")
  owner.metricsManager:observe("discovery24.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY24_PHASE_OFF_BY_ONE",gateIndex=prior.correctedGateIndex,
   historicalFraction=fraction}
  active.status="LEGACY_PHASE_COMPLETE"
  return fraction
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_GATE_PHASE_ONE_BASED",manager),ctx
end
return M
