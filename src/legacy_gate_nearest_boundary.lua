-- Stage44/DISCOVERY22: deliberately wrong nearest-gate midpoint tie.
local B=require("bigint")
local Base=require("monster_base")
local Reverse=require("gate_reverse_ordinal_patch")
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
 local remaining,ctx=Reverse.execute(target,records)
 assert(ctx.mode=="STAGE_43_PATCH_21" and ctx.commitToken==6
  and #ctx.branchTrace==6 and #ctx.diagnostics==6
  and ctx.status=="PATCH_GATE_REVERSE_ORDINAL_COMPLETE"
  and ctx.currentHandler=="GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["patch21.inclusive.reverse.lookups"]==1,
  "DISCOVERY22: authentic six-commit Stage43 required")
 local s=ctx.semanticState
 assert(type(s)=="table" and s.includesCurrentDay==true
  and s.preservedLegacyCommitCount==5 and s.noYearLogic
  and s.noPostStir12 and s.noNormativeOracleCalled)
 local d=B.from(target)
 local a=B.from(s.openingGateDayDecimal)
 local b=B.from(s.nextGateDayDecimal)
 local gap=B.sub(b,a)
 local ordinal=B.from(s.stage41CorrectedOrdinalDecimal)
 local reverse=B.from(s.correctedReverseOrdinalDecimal)
 assert(B.compare(a,d)<=0 and B.compare(d,b)<0
  and B.compare(gap,s.gapLengthDecimal)==0
  and B.compare(ordinal,B.add(B.sub(d,a),1))==0
  and B.compare(reverse,remaining)==0
  and B.compare(reverse,B.sub(b,d))==0
  and B.compare(B.add(ordinal,reverse),B.add(gap,1))==0)
 -- Intentionally wrong: a one-based ordinal is compared with a distance.
 -- Even-gap midpoint ties go to CLOSING rather than OPENING.
 local historical=B.compare(ordinal,reverse)<=0 and "OPENING" or "CLOSING"
 ctx.stage43ReverseOrdinalSemanticState=own(s)
 ctx.mode="STAGE_44_DISCOVERY_22"
 ctx.phase="LEGACY_NEAREST_GATE_ONEBASED_TIE"
 ctx.status="LEGACY_NEAREST_GATE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_NEAREST_GATE_ONEBASED_TIE",function(active,owner)
  local state={
   source="DISCOVERY22_LEGACY_ONEBASED_TIE",
   requestedDayDecimal=tostring(d),correctedGateIndex=s.correctedGateIndex,
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   gapLengthDecimal=tostring(gap),stage41CorrectedOrdinalDecimal=tostring(ordinal),
   stage43CorrectedReverseOrdinalDecimal=tostring(reverse),
   historicalNearestGate=historical,oneBasedOrdinalComparedToDistance=true,
   noCanonicalNearestGateComputed=true,preservedHistoricalCommitCount=6,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery22.legacy.nearest.lookups")
  owner.metricsManager:observe("discovery22.legacy.gate.index",s.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY22_ONEBASED_NEAREST_GATE_TIE",
   gateIndex=s.correctedGateIndex,historicalChoice=historical}
  active.status="LEGACY_NEAREST_GATE_COMPLETE"
  return historical
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_NEAREST_GATE_ONEBASED_TIE",manager),ctx
end
return M
