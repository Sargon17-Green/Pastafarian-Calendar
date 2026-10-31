-- Stage42 / DISCOVERY21: historic reverse ordinal excludes the current day.
-- Input: signed caller-supplied gates; no oracle or calendar generation in production.
local B=require("bigint")
local Base=require("monster_base")
local Ordinal=require("gate_ordinal_patch")
local Legacy={}

local function own(value,seen)
 if type(value)~="table" then return value end
 seen=seen or {}
 if seen[value] then return seen[value] end
 local out={};seen[value]=out
 for k,v in pairs(value) do out[own(k,seen)]=own(v,seen) end
 return out
end

function Legacy.execute(target,records)
 local ordinal,ctx=Ordinal.execute(target,records)
 assert(ctx.mode=="STAGE_41_PATCH_20"
  and ctx.status=="PATCH_GATE_ORDINAL_COMPLETE"
  and ctx.commitToken==4 and #ctx.branchTrace==4
  and ctx.currentHandler=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==4
  and ctx.metrics["patch20.onebased.ordinal.lookups"]==1,
  "DISCOVERY21: Stage41 four-commit gate is required")
 local s=ctx.semanticState
 assert(type(s)=="table" and s.oneBasedInsteadOfZeroBased==true
  and s.noYearLogic==true and s.noPostStir12==true
  and s.correctedGateIndex>=-7 and s.correctedGateIndex<=7
  and B.compare(s.correctedOrdinalDecimal,ordinal)==0,
  "DISCOVERY21: Stage41 ordinal context is invalid")
 local day=B.from(target)
 local opening=B.from(s.openingGateDayDecimal)
 local closing=B.from(s.nextGateDayDecimal)
 local gap=B.sub(closing,opening)
 assert(B.compare(opening,day)<=0 and B.compare(day,closing)<0
  and B.compare(gap,s.gapLengthDecimal)==0
  and B.compare(ordinal,1)>=0 and B.compare(ordinal,gap)<=0,
  "DISCOVERY21: day outside corrected gate interval")
 -- Deliberate legacy defect: the current day is excluded.
 local historical=B.sub(gap,ordinal)
 assert(B.compare(historical,0)>=0 and B.compare(historical,gap)<0,
  "DISCOVERY21: legacy reverse ordinal outside zero-based range")
 ctx.stage41GateOrdinalSemanticState=own(s)
 ctx.mode="STAGE_42_DISCOVERY_21"
 ctx.phase="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
 ctx.status="LEGACY_GATE_REVERSE_ORDINAL_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY",function(active,owner)
  local state={
   source="DISCOVERY21_LEGACY_EXCLUDES_TODAY",
   requestedDayDecimal=tostring(day),
   correctedGateIndex=s.correctedGateIndex,
   openingGateDayDecimal=tostring(opening),
   nextGateDayDecimal=tostring(closing),
   gapLengthDecimal=tostring(gap),
   stage41CorrectedOrdinalDecimal=tostring(ordinal),
   historicalReverseOrdinalDecimal=tostring(historical),
   excludesCurrentDay=true,noCanonicalReverseOrdinalComputed=true,
   preservedHistoricalCommitCount=4,
   noYearLogic=true,noPostStir12=true,ownedGateSnapshots=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery21.legacy.reverse.lookups")
  owner.metricsManager:observe("discovery21.legacy.gate.index",s.correctedGateIndex)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY21_REVERSE_ORDINAL_EXCLUDES_CURRENT_DAY",
   gateIndex=s.correctedGateIndex, historicalReverseOrdinal=tostring(historical)
  }
  active.status="LEGACY_GATE_REVERSE_ORDINAL_COMPLETE"
  return B.from(historical)
 end)
 return manager.dispatcher:dispatch(ctx,"LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY",manager),ctx
end
return Legacy
