-- Stage45/PATCH22: nearest-boundary tie correction; seven historical commits preserved.
-- Inputs are caller-supplied signed gate records. No calendar date or test oracle here.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_nearest_boundary")
local Patch={}

local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local copy={};seen[v]=copy
 for k,x in pairs(v) do copy[own(k,seen)]=own(x,seen) end
 return copy
end

local function inspect(target,historical,ctx)
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_44_DISCOVERY_22"
  and ctx.status=="LEGACY_NEAREST_GATE_COMPLETE"
  and ctx.commitToken==7 and #ctx.branchTrace==7
  and ctx.currentHandler=="LEGACY_NEAREST_GATE_ONEBASED_TIE"
  and #ctx.diagnostics==7
  and ctx.diagnostics[7].code=="DISCOVERY22_ONEBASED_NEAREST_GATE_TIE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery22.legacy.nearest.lookups"]==1,
  "PATCH22: authentic seven-commit Stage44 history required")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="DISCOVERY22_LEGACY_ONEBASED_TIE"
  and s.preservedHistoricalCommitCount==6
  and s.oneBasedOrdinalComparedToDistance==true
  and s.noCanonicalNearestGateComputed==true
  and s.historicalNearestGate==historical
  and s.noYearLogic and s.noPostStir12 and s.noNormativeOracleCalled
  and type(ctx.stage43ReverseOrdinalSemanticState)=="table"
  and ctx.stage43ReverseOrdinalSemanticState.includesCurrentDay==true,
  "PATCH22: Stage44 state or Stage43 provenance invalid")
 local day=B.from(target)
 local a=B.from(s.openingGateDayDecimal)
 local b=B.from(s.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local ordinal=B.from(s.stage41CorrectedOrdinalDecimal)
 local reverse=B.from(s.stage43CorrectedReverseOrdinalDecimal)
 local left=B.sub(day,a)
 local right=B.sub(b,day)
 assert(s.requestedDayDecimal==tostring(day)
  and B.compare(a,day)<=0 and B.compare(day,b)<0
  and B.compare(gap,s.gapLengthDecimal)==0
  and B.compare(ordinal,B.add(left,1))==0
  and B.compare(reverse,right)==0
  and B.compare(B.add(ordinal,reverse),B.add(gap,1))==0
  and historical==(B.compare(ordinal,reverse)<=0 and "OPENING" or "CLOSING"),
  "PATCH22: historical ordinal comparison changed")
 return day,a,b,ordinal,reverse,left,right,s.correctedGateIndex
end

function Patch.execute(target,records)
 local historical,ctx=Legacy.execute(target,records)
 local day,a,b,ordinal,reverse,left,right,k=inspect(target,historical,ctx)
 ctx.stage44NearestBoundarySemanticState=own(ctx.semanticState)
 ctx.legacyGateNearestBoundaryChoice=historical
 ctx.mode="STAGE_45_PATCH_22"
 ctx.phase="PATCH_NEAREST_GATE_MIDPOINT_TIE"
 ctx.status="PATCH_NEAREST_GATE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",function(active,owner)
  -- Compare zero-based elapsed distance with remaining distance, not ordinal.
  local corrected=B.compare(left,right)<=0 and "OPENING" or "CLOSING"
  local state={
   source="PATCH_22_NEAREST_GATE_MIDPOINT_TIE",
   requestedDayDecimal=tostring(day),correctedGateIndex=k,
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   stage41CorrectedOrdinalDecimal=tostring(ordinal),
   stage43CorrectedReverseOrdinalDecimal=tostring(reverse),
   openingDistanceDecimal=tostring(left),closingDistanceDecimal=tostring(right),
   historicalNearestGate=historical,correctedNearestGate=corrected,
   midpointTieToOpening=true,preservedHistoricalCommitCount=7,
   ownedGateSnapshots=true,noNormativeOracleCalled=true,
   noYearLogic=true,noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch22.nearest.lookups")
  owner.metricsManager:observe("patch22.corrected.gate.index",k)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH22_NEAREST_GATE_MIDPOINT_TIE_TO_OPENING",
   gateIndex=k,historicalChoice=historical,correctedChoice=corrected
  }
  active.status="PATCH_NEAREST_GATE_COMPLETE"
  return corrected
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",manager),ctx
end

return Patch
