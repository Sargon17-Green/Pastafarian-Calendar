-- Stage52/DISCOVERY26: controlled sticky-left quartile boundaries, NOT an inherited defect.
-- Diagnostic only; exact signed BigInt arithmetic and no public calendar field.
local B=require("bigint")
local Base=require("monster_base")
local Parent=require("gate_midpoint_patch")
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
 local correctedMidpoint,ctx=Parent.execute(day,records)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_51_PATCH_25"
  and ctx.phase=="PATCH_MIDPOINT_TIE_EQUALITY"
  and ctx.status=="PATCH_MIDPOINT_COMPLETE"
  and ctx.commitToken==14 and #ctx.branchTrace==14 and #ctx.diagnostics==14
  and ctx.currentHandler=="GATE_MIDPOINT_EQUALITY_PATCH"
  and ctx.diagnostics[14].code=="PATCH25_MIDPOINT_TIE_EQUALITY"
  and ctx.metrics["patch25.midpoint.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY26 requires authenticated Stage51 fourteen-commit state")
 local prior=ctx.semanticState
 assert(type(prior)=="table" and prior.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and prior.correctedMidpointLabel==correctedMidpoint
  and prior.tieEqualityRestored and prior.preservedHistoricalCommitCount==13
  and prior.ownedGateSnapshots and prior.noYearLogic and prior.noPostStir12
  and prior.noNormativeOracleCalled
  and type(ctx.stage50LegacyMidpointSemanticState)=="table"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and type(ctx.stage49PatchedPhaseSemanticState)=="table"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "DISCOVERY26: historical provenance missing")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local offset=B.sub(d,a)
 local twice=B.add(offset,offset)
 local four=B.add(twice,twice)
 local twiceGap=B.add(gap,gap)
 local thr3=B.add(twiceGap,gap)
 assert(prior.requestedDayDecimal==tostring(d)
  and prior.offsetDecimal==tostring(offset)
  and prior.gapDecimal==tostring(gap)
  and prior.twiceOffsetDecimal==tostring(twice)
  and prior.exactPhaseFraction==tostring(offset).."/"..tostring(gap)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(offset,0)>=0 and B.compare(offset,gap)<0,
  "DISCOVERY26: endpoints or unreduced phase mismatch")
 local correctMidpoint=(B.compare(twice,gap)<0 and "BEFORE_MIDPOINT")
  or (B.compare(twice,gap)==0 and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 assert(correctedMidpoint==correctMidpoint,
  "DISCOVERY26: authenticated midpoint repair changed")
 -- NEW CONTROLLED ERROR: exact quarter equality sticks to the preceding bucket.
 local label
 if B.compare(four,gap)<=0 then label="Q1"
 elseif B.compare(four,twiceGap)<=0 then label="Q2"
 elseif B.compare(four,thr3)<=0 then label="Q3"
 else label="Q4" end
 ctx.stage51PatchedMidpointSemanticState=own(prior)
 ctx.mode="STAGE_52_DISCOVERY_26"
 ctx.phase="LEGACY_QUARTILE_STICKY_EDGE"
 ctx.status="LEGACY_QUARTILE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_QUARTILE_STICKY_EDGE",function(active,owner)
  local state={
   source="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   offsetDecimal=tostring(offset),gapDecimal=tostring(gap),
   fourOffsetDecimal=tostring(four),twiceGapDecimal=tostring(twiceGap),
   threeGapDecimal=tostring(thr3),exactPhaseFraction=prior.exactPhaseFraction,
   correctedMidpointLabel=correctedMidpoint,legacyQuartileLabel=label,
   edgeStickyPrevious=true,preservedHistoricalCommitCount=14,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,
   noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery26.quartile.lookups")
  owner.metricsManager:observe("discovery26.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
    code="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS",
    gateIndex=prior.correctedGateIndex,legacyQuartileLabel=label,
    exactPhaseFraction=prior.exactPhaseFraction}
  active.status="LEGACY_QUARTILE_COMPLETE"
  return label
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_QUARTILE_STICKY_EDGE",manager),ctx
end

return M
