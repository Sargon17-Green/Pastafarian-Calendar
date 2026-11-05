-- Stage55/PATCH27: exact half-open octile-edge correction; Stage54 legacy stays intact.
-- Diagnostic only, with signed BigInt additions and comparisons, no floats or date fields.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_octile")
local Patch={}
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
local function classify(off,gap,sticky)
 local numerator=multiply(off,8)
 for k=1,7 do
  local cmp=B.compare(numerator,multiply(gap,k))
  if cmp<0 or (sticky and cmp==0) then return "E"..k end
 end
 return "E8"
end
function Patch.execute(day,records)
 local historic,ctx=Legacy.execute(day,records)
 assert(ctx.mode=="STAGE_54_DISCOVERY_27"
  and ctx.phase=="LEGACY_OCTILE_STICKY_EDGE"
  and ctx.status=="LEGACY_OCTILE_COMPLETE"
  and ctx.commitToken==17 and #ctx.branchTrace==17 and #ctx.diagnostics==17
  and ctx.currentHandler=="LEGACY_OCTILE_STICKY_EDGE"
  and ctx.diagnostics[17].code=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and ctx.metrics["discovery27.octile.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH27 requires authenticated Stage54 seventeen-commit context")
 local prior=ctx.semanticState
 assert(type(prior)=="table"
  and prior.source=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and prior.legacyOctileLabel==historic and prior.edgeStickyPrevious==true
  and prior.preservedHistoricalCommitCount==16 and prior.ownedGateSnapshots
  and prior.noYearLogic and prior.noPostStir12 and prior.noNormativeOracleCalled
  and type(ctx.stage53PatchedQuartileSemanticState)=="table"
  and ctx.stage53PatchedQuartileSemanticState.source=="PATCH_26_QUARTILE_EDGE_EQUALITY"
  and ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel==prior.correctedQuartileLabel
  and ctx.stage52LegacyQuartileSemanticState.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "PATCH27 historical provenance mismatch")
 local d=B.from(day)
 local a=B.from(prior.openingGateDayDecimal)
 local b=B.from(prior.nextGateDayDecimal)
 local off=B.sub(d,a)
 local gap=B.sub(b,a)
 local eight=multiply(off,8)
 assert(prior.requestedDayDecimal==tostring(d)
  and prior.offsetDecimal==tostring(off)
  and prior.gapDecimal==tostring(gap)
  and prior.eightOffsetDecimal==tostring(eight)
  and prior.exactPhaseFraction==tostring(off).."/"..tostring(gap)
  and B.compare(gap,42)>=0 and B.compare(gap,963)<=0
  and B.compare(off,0)>=0 and B.compare(off,gap)<0,
  "PATCH27 offset, gap or phase mismatch")
 assert(classify(off,gap,true)==historic,"PATCH27 Stage54 historical result changed")
 local corrected=classify(off,gap,false)
 local four=multiply(off,4)
 local quartile="Q4"
 for k=1,3 do
  if B.compare(four,multiply(gap,k))<0 then quartile="Q"..k;break end
 end
 assert(quartile==prior.correctedQuartileLabel,
  "PATCH27 Stage53 corrected quartile regression")
 ctx.stage54LegacyOctileSemanticState=own(prior)
 ctx.mode="STAGE_55_PATCH_27"
 ctx.phase="PATCH_OCTILE_EDGE_EQUALITY"
 ctx.status="PATCH_OCTILE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_OCTILE_EDGE_PATCH",function(active,owner)
  local st={
   source="PATCH_27_OCTILE_EDGE_EQUALITY",
   correctedGateIndex=prior.correctedGateIndex,
   requestedDayDecimal=tostring(d),
   openingGateDayDecimal=tostring(a),nextGateDayDecimal=tostring(b),
   offsetDecimal=tostring(off),gapDecimal=tostring(gap),
   eightOffsetDecimal=tostring(eight),
   exactPhaseFraction=prior.exactPhaseFraction,
   correctedQuartileLabel=quartile,
   legacyOctileLabel=historic,correctedOctileLabel=corrected,
   edgeEqualityRestored=true,preservedHistoricalCommitCount=17,
   ownedGateSnapshots=true,noYearLogic=true,noPostStir12=true,
   noNormativeOracleCalled=true
  }
  active:beginSemanticUpdate(st)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch27.octile.repairs")
  owner.metricsManager:observe("patch27.gate.index",prior.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH27_OCTILE_EDGE_EQUALITY",
   gateIndex=prior.correctedGateIndex,historicalLabel=historic,
   correctedLabel=corrected,exactPhaseFraction=prior.exactPhaseFraction}
  active.status="PATCH_OCTILE_COMPLETE"
  return corrected
 end)
 return manager.dispatcher:dispatch(ctx,"GATE_OCTILE_EDGE_PATCH",manager),ctx
end
return Patch
