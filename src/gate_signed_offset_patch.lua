-- Stage47/PATCH23: restore sign of the nearest-gate offset.
-- Stage46's unsigned historical diagnostic remains immutable and callable.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_signed_offset")
local Patch={}

local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[own(k,seen)]=own(x,seen) end
 return out
end

function Patch.execute(target,records)
 local historic,ctx=Legacy.execute(target,records)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_46_DISCOVERY_23"
  and ctx.status=="LEGACY_SIGNED_OFFSET_COMPLETE"
  and ctx.currentHandler=="LEGACY_UNSIGNED_NEAREST_GATE_OFFSET"
  and ctx.commitToken==9 and #ctx.branchTrace==9 and #ctx.diagnostics==9
  and ctx.diagnostics[9].code=="DISCOVERY23_CLOSING_DIRECTION_LOST"
  and ctx.metrics["discovery23.legacy.unsigned.offsets"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH23: authentic nine-commit Stage46 context required")
 local s=ctx.semanticState
 local prior=ctx.stage45NearestBoundarySemanticState
 assert(type(s)=="table" and type(prior)=="table"
  and s.source=="DISCOVERY23_UNSIGNED_NEAREST_GATE_OFFSET"
  and s.discardsClosingDirection==true
  and s.noCanonicalSignedOffsetComputed==true
  and s.preservedHistoricalCommitCount==8
  and s.correctedNearestGate==prior.correctedNearestGate
  and prior.midpointTieToOpening==true
  and s.noYearLogic and s.noPostStir12 and s.noNormativeOracleCalled,
  "PATCH23: historical unsigned state is not authentic")
 local day=B.from(target)
 local a,b=B.from(s.openingGateDayDecimal),B.from(s.nextGateDayDecimal)
 local left,right=B.sub(day,a),B.sub(b,day)
 local choice=B.compare(left,right)<=0 and "OPENING" or "CLOSING"
 local magnitude=B.from(historic)
 assert(s.requestedDayDecimal==tostring(day)
  and B.compare(a,day)<=0 and B.compare(day,b)<0
  and s.correctedNearestGate==choice
  and B.compare(left,prior.openingDistanceDecimal)==0
  and B.compare(right,prior.closingDistanceDecimal)==0
  and B.compare(magnitude,s.historicalUnsignedOffsetDecimal)==0
  and B.compare(magnitude,choice=="OPENING" and left or right)==0
  and type(ctx.stage44NearestBoundarySemanticState)=="table"
  and ctx.stage44NearestBoundarySemanticState.oneBasedOrdinalComparedToDistance==true,
  "PATCH23: signed-distance provenance mismatch")
 ctx.stage46SignedOffsetSemanticState=own(s)
 ctx.legacyUnsignedGateOffsetDecimal=tostring(magnitude)
 ctx.mode="STAGE_47_PATCH_23"
 ctx.phase="PATCH_NEAREST_GATE_SIGNED_OFFSET"
 ctx.status="PATCH_SIGNED_OFFSET_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_SIGNED_OFFSET_DIRECTION_PATCH",function(active,owner)
  -- Zero remains exactly "0"; closing direction is represented by a minus sign.
  local corrected=choice=="OPENING" and magnitude or B.neg(magnitude)
  local state={
   source="PATCH_23_NEAREST_GATE_SIGNED_OFFSET",
   requestedDayDecimal=tostring(day),correctedGateIndex=s.correctedGateIndex,
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   correctedNearestGate=choice,
   historicalUnsignedOffsetDecimal=tostring(magnitude),
   correctedSignedOffsetDecimal=tostring(corrected),
   closingDirectionRestored=true,zeroCanonical=true,
   midpointTieToOpening=true,preservedHistoricalCommitCount=9,
   ownedGateSnapshots=true,noNormativeOracleCalled=true,
   noYearLogic=true,noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch23.signed.offsets")
  owner.metricsManager:observe("patch23.corrected.gate.index",s.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH23_CLOSING_DIRECTION_RESTORED",gateIndex=s.correctedGateIndex,
   nearestChoice=choice,historicalMagnitudeDecimal=tostring(magnitude),
   correctedSignedOffsetDecimal=tostring(corrected)}
  active.status="PATCH_SIGNED_OFFSET_COMPLETE"
  return tostring(corrected)
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_SIGNED_OFFSET_DIRECTION_PATCH",manager),ctx
end

return Patch
