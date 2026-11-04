-- Stage54/DISCOVERY27: newly introduced controlled sticky-left eighth labels.
-- Diagnostic only. Parent Stage53/PATCH26 remains authoritative and unchanged.
local B=require("bigint")
local Base=require("monster_base")
local Parent=require("gate_quartile_patch")
local M={}
local function own(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={};seen[v]=out
 for k,x in pairs(v) do out[own(k,seen)]=own(x,seen) end
 return out
end
local function multiply(x,n)
 local r=B.from(0)
 for _=1,n do r=B.add(r,x) end
 return r
end
local function label(off,gap,sticky)
 local numerator=multiply(off,8)
 for k=1,7 do
  local comparison=B.compare(numerator,multiply(gap,k))
  if comparison<0 or (sticky and comparison==0) then return "E"..k end
 end
 return "E8"
end
function M.execute(day,records)
 local quartile,ctx=Parent.execute(day,records)
 assert(ctx.mode=="STAGE_53_PATCH_26"
  and ctx.phase=="PATCH_QUARTILE_EDGE_EQUALITY"
  and ctx.status=="PATCH_QUARTILE_COMPLETE"
  and ctx.commitToken==16 and #ctx.branchTrace==16 and #ctx.diagnostics==16
  and ctx.currentHandler=="GATE_QUARTILE_EDGE_PATCH"
  and ctx.diagnostics[16].code=="PATCH26_QUARTILE_EDGE_EQUALITY"
  and ctx.metrics["patch26.quartile.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY27 requires authenticated Stage53 sixteen-commit context")
 local prior=ctx.semanticState
 assert(prior.source=="PATCH_26_QUARTILE_EDGE_EQUALITY"
  and prior.correctedQuartileLabel==quartile and prior.edgeEqualityRestored
  and prior.preservedHistoricalCommitCount==15 and prior.ownedGateSnapshots
  and prior.noYearLogic and prior.noPostStir12 and prior.noNormativeOracleCalled
  and ctx.stage52LegacyQuartileSemanticState.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "DISCOVERY27: historical state provenance invalid")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local off=B.sub(d,a)
 local gap=B.sub(b,a)
 assert(prior.requestedDayDecimal==tostring(d)
  and prior.offsetDecimal==tostring(off) and prior.gapDecimal==tostring(gap)
  and prior.exactPhaseFraction==tostring(off).."/"..tostring(gap)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(off,0)>=0 and B.compare(off,gap)<0,
  "DISCOVERY27: endpoints or phase mismatch")
 local four=multiply(off,4)
 local expectedQ="Q4"
 for k=1,3 do
  if B.compare(four,multiply(gap,k))<0 then
   expectedQ="Q"..k
   break
  end
 end
 assert(quartile==expectedQ,"DISCOVERY27: Stage53 quartile regression")
 -- The controlled defect is new here; this is NOT a pre-existing bug.
 local historical=label(off,gap,true)
 ctx.stage53PatchedQuartileSemanticState=own(prior)
 ctx.mode="STAGE_54_DISCOVERY_27"
 ctx.phase="LEGACY_OCTILE_STICKY_EDGE"
 ctx.status="LEGACY_OCTILE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_OCTILE_STICKY_EDGE",function(active,owner)
  local st={
   source="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   offsetDecimal=tostring(off),gapDecimal=tostring(gap),
   eightOffsetDecimal=tostring(multiply(off,8)),
   exactPhaseFraction=prior.exactPhaseFraction,
   correctedQuartileLabel=quartile,legacyOctileLabel=historical,
   edgeStickyPrevious=true,preservedHistoricalCommitCount=16,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,
   noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(st)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery27.octile.lookups")
  owner.metricsManager:observe("discovery27.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS",
   gateIndex=prior.correctedGateIndex,legacyOctileLabel=historical,
   exactPhaseFraction=prior.exactPhaseFraction}
  active.status="LEGACY_OCTILE_COMPLETE"
  return historical
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_OCTILE_STICKY_EDGE",manager),ctx
end
return M
