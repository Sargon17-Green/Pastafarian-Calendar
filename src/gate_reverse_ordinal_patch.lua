-- Stage43 / PATCH21: include the current day in reverse gate ordinal.
-- Keep Stage42's five semantic commits; append an independent sixth correction.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_reverse_ordinal")
local Patch={}

local function own(value,seen)
 if type(value)~="table" then return value end
 seen=seen or {}
 if seen[value] then return seen[value] end
 local out={};seen[value]=out
 for k,v in pairs(value) do out[own(k,seen)]=own(v,seen) end
 return out
end

local function inspectHistorical(target,historical,ctx)
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_42_DISCOVERY_21"
  and ctx.status=="LEGACY_GATE_REVERSE_ORDINAL_COMPLETE"
  and ctx.commitToken==5 and #ctx.branchTrace==5
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.branchTrace[4]=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.branchTrace[5]=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and ctx.currentHandler=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and #ctx.diagnostics==5
  and ctx.diagnostics[5].code=="DISCOVERY21_REVERSE_ORDINAL_EXCLUDES_CURRENT_DAY"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery21.legacy.reverse.lookups"]==1,
  "PATCH21: authentic five-commit Stage42 history required")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="DISCOVERY21_LEGACY_EXCLUDES_TODAY"
  and s.excludesCurrentDay==true
  and s.noCanonicalReverseOrdinalComputed==true
  and s.preservedHistoricalCommitCount==4
  and s.noYearLogic==true and s.noPostStir12==true
  and type(ctx.stage41GateOrdinalSemanticState)=="table"
  and ctx.stage41GateOrdinalSemanticState.correctedGateIndex==s.correctedGateIndex
  and ctx.stage41GateOrdinalSemanticState.oneBasedInsteadOfZeroBased==true,
  "PATCH21: Stage42 semantic state invalid")
 local day=B.from(target)
 local opening=B.from(s.openingGateDayDecimal)
 local closing=B.from(s.nextGateDayDecimal)
 local gap=B.sub(closing,opening)
 local ordinal=B.from(s.stage41CorrectedOrdinalDecimal)
 assert(s.requestedDayDecimal==tostring(day)
  and B.compare(day,opening)>=0 and B.compare(day,closing)<0
  and B.compare(gap,s.gapLengthDecimal)==0
  and B.compare(ordinal,B.add(B.sub(day,opening),1))==0
  and B.compare(historical,s.historicalReverseOrdinalDecimal)==0
  and B.compare(historical,B.sub(gap,ordinal))==0,
  "PATCH21: historical reverse ordinal no longer authentic")
 return day,opening,closing,gap,ordinal,s.correctedGateIndex
end

function Patch.correctReverseOrdinal(day,closing,historical)
 local remaining=B.sub(closing,day)
 assert(B.compare(remaining,1)>=0
  and B.compare(remaining,B.add(historical,1))==0,
  "PATCH21: inclusive reverse ordinal invariant failed")
 return remaining
end

function Patch.execute(target,records)
 local historical,ctx=Legacy.execute(target,records)
 local day,opening,closing,gap,ordinal,k=inspectHistorical(target,historical,ctx)
 ctx.stage42GateReverseOrdinalSemanticState=own(ctx.semanticState)
 ctx.legacyGateReverseOrdinalDecimal=tostring(historical)
 ctx.mode="STAGE_43_PATCH_21"
 ctx.phase="PATCH_GATE_REVERSE_ORDINAL_INCLUSIVE"
 ctx.status="PATCH_GATE_REVERSE_ORDINAL_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",function(active,owner)
  local corrected=Patch.correctReverseOrdinal(day,closing,historical)
  assert(B.compare(corrected,gap)<=0
   and B.compare(B.add(corrected,ordinal),B.add(gap,1))==0,
   "PATCH21: reciprocal ordinal conservation failed")
  local state={
   source="PATCH_21_REVERSE_ORDINAL_INCLUDES_TODAY",
   requestedDayDecimal=tostring(day),correctedGateIndex=k,
   openingGateDayDecimal=tostring(opening),
   nextGateDayDecimal=tostring(closing),
   gapLengthDecimal=tostring(gap),
   stage41CorrectedOrdinalDecimal=tostring(ordinal),
   historicalReverseOrdinalDecimal=tostring(historical),
   correctedReverseOrdinalDecimal=tostring(corrected),
   includesCurrentDay=true,preservedLegacyCommitCount=5,
   ownedGateSnapshots=true,noNormativeOracleCalled=true,
   noYearLogic=true,noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch21.inclusive.reverse.lookups")
  owner.metricsManager:observe("patch21.corrected.gate.index",k)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH21_REVERSE_ORDINAL_INCLUDES_CURRENT_DAY",
   gateIndex=k,historicalReverseOrdinal=tostring(historical),
   correctedReverseOrdinal=tostring(corrected)
  }
  active.status="PATCH_GATE_REVERSE_ORDINAL_COMPLETE"
  return B.from(corrected)
 end)
 local corrected=manager.dispatcher:dispatch(ctx,"GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",manager)
 return corrected,ctx
end

return Patch
