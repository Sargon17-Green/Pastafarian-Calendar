-- Stage53/PATCH26: exact half-open quartile repair, preserving Stage52 legacy.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_quartile")
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
 assert(ctx.mode=="STAGE_52_DISCOVERY_26"
  and ctx.phase=="LEGACY_QUARTILE_STICKY_EDGE"
  and ctx.status=="LEGACY_QUARTILE_COMPLETE"
  and ctx.commitToken==15 and #ctx.branchTrace==15 and #ctx.diagnostics==15
  and ctx.currentHandler=="LEGACY_QUARTILE_STICKY_EDGE"
  and ctx.diagnostics[15].code=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.metrics["discovery26.quartile.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH26 requires authenticated Stage52 15-commit state")
 local prior=ctx.semanticState
 assert(prior.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and prior.legacyQuartileLabel==historical and prior.edgeStickyPrevious
  and prior.preservedHistoricalCommitCount==14 and prior.ownedGateSnapshots
  and prior.noYearLogic and prior.noPostStir12 and prior.noNormativeOracleCalled
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "PATCH26 historical provenance mismatch")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local off=B.sub(d,a)
 local gap=B.sub(b,a)
 local four=B.add(B.add(off,off),B.add(off,off))
 local twiceGap=B.add(gap,gap)
 local thr3=B.add(twiceGap,gap)
 assert(prior.requestedDayDecimal==tostring(d)
  and prior.offsetDecimal==tostring(off) and prior.gapDecimal==tostring(gap)
  and prior.fourOffsetDecimal==tostring(four)
  and prior.twiceGapDecimal==tostring(twiceGap)
  and prior.threeGapDecimal==tostring(thr3)
  and prior.exactPhaseFraction==tostring(off).."/"..tostring(gap)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(off,0)>=0 and B.compare(off,gap)<0,
  "PATCH26 mismatched endpoints")
 local old
 if B.compare(four,gap)<=0 then old="Q1"
 elseif B.compare(four,twiceGap)<=0 then old="Q2"
 elseif B.compare(four,thr3)<=0 then old="Q3"
 else old="Q4" end
 assert(old==historical,"PATCH26 Stage52 historical result changed")
 local corrected
 if B.compare(four,gap)<0 then corrected="Q1"
 elseif B.compare(four,twiceGap)<0 then corrected="Q2"
 elseif B.compare(four,thr3)<0 then corrected="Q3"
 else corrected="Q4" end
 local twice=B.add(off,off)
 local midpoint=(B.compare(twice,gap)<0 and "BEFORE_MIDPOINT")
  or (B.compare(twice,gap)==0 and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 assert(prior.correctedMidpointLabel==midpoint
  and ctx.stage51PatchedMidpointSemanticState.correctedMidpointLabel==midpoint,
  "PATCH26 Stage51 midpoint regression")
 ctx.stage52LegacyQuartileSemanticState=own(prior)
 ctx.mode="STAGE_53_PATCH_26"
 ctx.phase="PATCH_QUARTILE_EDGE_EQUALITY"
 ctx.status="PATCH_QUARTILE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_QUARTILE_EDGE_PATCH",function(active,owner)
  local st={
   source="PATCH_26_QUARTILE_EDGE_EQUALITY",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   offsetDecimal=tostring(off),gapDecimal=tostring(gap),
   fourOffsetDecimal=tostring(four),twiceGapDecimal=tostring(twiceGap),
   threeGapDecimal=tostring(thr3),exactPhaseFraction=prior.exactPhaseFraction,
   correctedMidpointLabel=midpoint,legacyQuartileLabel=historical,
   correctedQuartileLabel=corrected,edgeEqualityRestored=true,
   preservedHistoricalCommitCount=15,ownedGateSnapshots=true,
   noYearLogic=true,noPostStir12=true,noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(st)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch26.quartile.repairs")
  owner.metricsManager:observe("patch26.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH26_QUARTILE_EDGE_EQUALITY",
   gateIndex=prior.correctedGateIndex,historicalLabel=historical,
   correctedLabel=corrected,exactPhaseFraction=prior.exactPhaseFraction}
  active.status="PATCH_QUARTILE_COMPLETE"
  return corrected
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_QUARTILE_EDGE_PATCH",manager),ctx
end
return Patch
