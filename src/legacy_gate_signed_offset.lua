-- Stage46/DISCOVERY23: deliberately unsigned nearest-gate offset.
-- This is a new projection of validated Stage45 choice, not a calendar component.
local B=require("bigint")
local Base=require("monster_base")
local Nearest=require("gate_nearest_boundary_patch")
local M={}

local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local y={};seen[v]=y
 for k,x in pairs(v) do y[own(k,seen)]=own(x,seen) end
 return y
end

function M.execute(target,records)
 local nearest,ctx=Nearest.execute(target,records)
 assert(ctx.mode=="STAGE_45_PATCH_22"
  and ctx.status=="PATCH_NEAREST_GATE_COMPLETE"
  and ctx.commitToken==8 and #ctx.branchTrace==8
  and ctx.currentHandler=="GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH"
  and #ctx.diagnostics==8
  and ctx.diagnostics[8].code=="PATCH22_NEAREST_GATE_MIDPOINT_TIE_TO_OPENING"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["patch22.nearest.lookups"]==1,
  "DISCOVERY23: authentic Stage45 eight-commit context required")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="PATCH_22_NEAREST_GATE_MIDPOINT_TIE"
  and s.correctedNearestGate==nearest
  and s.midpointTieToOpening==true and s.preservedHistoricalCommitCount==7
  and s.noYearLogic and s.noPostStir12 and s.noNormativeOracleCalled,
  "DISCOVERY23: Stage45 provenance invalid")
 local day=B.from(target)
 local a,b=B.from(s.openingGateDayDecimal),B.from(s.nextGateDayDecimal)
 local left,right=B.sub(day,a),B.sub(b,day)
 assert(s.requestedDayDecimal==tostring(day)
  and B.compare(a,day)<=0 and B.compare(day,b)<0
  and B.compare(left,s.openingDistanceDecimal)==0
  and B.compare(right,s.closingDistanceDecimal)==0
  and nearest==(B.compare(left,right)<=0 and "OPENING" or "CLOSING")
  and type(ctx.stage44NearestBoundarySemanticState)=="table"
  and ctx.stage44NearestBoundarySemanticState.oneBasedOrdinalComparedToDistance==true,
  "DISCOVERY23: inconsistent locked nearest-gate evidence")
 -- Deliberate legacy defect: an unsigned magnitude even when next gate is nearer.
 -- Do not calculate the normative signed offset in this historical module.
 local magnitude=nearest=="OPENING" and left or right
 ctx.stage45NearestBoundarySemanticState=own(s)
 ctx.mode="STAGE_46_DISCOVERY_23"
 ctx.phase="LEGACY_UNSIGNED_NEAREST_GATE_OFFSET"
 ctx.status="LEGACY_SIGNED_OFFSET_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_UNSIGNED_NEAREST_GATE_OFFSET",function(active,owner)
  local state={
   source="DISCOVERY23_UNSIGNED_NEAREST_GATE_OFFSET",
   requestedDayDecimal=tostring(day),correctedGateIndex=s.correctedGateIndex,
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   correctedNearestGate=nearest,
   historicalUnsignedOffsetDecimal=tostring(magnitude),
   discardsClosingDirection=true,noCanonicalSignedOffsetComputed=true,
   preservedHistoricalCommitCount=8,ownedGateSnapshots=true,
   noYearLogic=true,noPostStir12=true,noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery23.legacy.unsigned.offsets")
  owner.metricsManager:observe("discovery23.legacy.gate.index",s.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY23_CLOSING_DIRECTION_LOST",
   gateIndex=s.correctedGateIndex,nearestChoice=nearest,
   unsignedMagnitudeDecimal=tostring(magnitude)}
  active.status="LEGACY_SIGNED_OFFSET_COMPLETE"
  return tostring(magnitude)
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_UNSIGNED_NEAREST_GATE_OFFSET",manager),ctx
end

return M
