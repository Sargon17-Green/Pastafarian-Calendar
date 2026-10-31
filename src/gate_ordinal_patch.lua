-- Stage41 PATCH20: preserve the three Stage40 semantic commits and correct ordinal to one-based.
-- Caller supplies the same corrected gate records; no oracle or calendar integration here.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_ordinal")
local Patch={}

local function own(x,seen)
 if type(x)~="table" then return x end
 seen=seen or {}
 if seen[x] then return seen[x] end
 local y={};seen[x]=y
 for k,v in pairs(x) do y[own(k,seen)]=own(v,seen) end
 return y
end

local function inspectHistorical(day,records,old,ctx)
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_40_DISCOVERY_20"
  and ctx.status=="LEGACY_GATE_ORDINAL_COMPLETE"
  and ctx.commitToken==3 and #ctx.branchTrace==3
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.currentHandler=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==3
  and ctx.diagnostics[3].code=="DISCOVERY20_ZERO_BASED_GATE_ORDINAL"
  and ctx.metrics["discovery19.legacy.lookups"]==1
  and ctx.metrics["patch19.boundary.lookups"]==1
  and ctx.metrics["discovery20.legacy.ordinal.lookups"]==1,
  "PATCH20: Stage40 historical commits not authentic")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="DISCOVERY20_LEGACY_ZERO_BASED"
  and s.zeroBasedInsteadOfOneBased==true
  and s.noCanonicalOrdinalComputed==true
  and s.noYearLogic==true and s.noPostStir12==true
  and type(s.correctedGateIndex)=="number"
  and s.correctedGateIndex>=-7 and s.correctedGateIndex<=7
  and type(ctx.stage39GateIndexSemanticState)=="table"
  and ctx.stage39GateIndexSemanticState.correctedIndex==s.correctedGateIndex
  and ctx.stage39GateIndexSemanticState.ownedGateSnapshots==true,
  "PATCH20: Stage40 semantic state invalid")
 local requested=B.from(day)
 local opening=B.from(s.openingGateDayDecimal)
 local closing=B.from(s.nextGateDayDecimal)
 local gap=B.sub(closing,opening)
 local z=B.sub(requested,opening)
 assert(s.requestedDayDecimal==tostring(requested)
  and B.compare(gap,s.gapLengthDecimal)==0
  and B.compare(z,old)==0
  and B.compare(z,s.historicalOrdinalDecimal)==0
  and B.compare(opening,requested)<=0
  and B.compare(requested,closing)<0,
  "PATCH20: historical zero-based ordinal mismatch")
 return requested,opening,closing,gap,z,s.correctedGateIndex
end

function Patch.correctOrdinal(day,opening,closing,historical)
 assert(B.compare(opening,day)<=0 and B.compare(day,closing)<0,
  "PATCH20: day outside half-open gate interval")
 local ordinal=B.add(B.sub(day,opening),1)
 assert(B.compare(ordinal,B.add(historical,1))==0
  and B.compare(ordinal,1)>=0
  and B.compare(ordinal,B.sub(closing,opening))<=0,
  "PATCH20: one-based ordinal invariant failed")
 return ordinal
end

function Patch.execute(target,records)
 local old,ctx=Legacy.execute(target,records)
 local day,opening,closing,gap,z,k=inspectHistorical(target,records,old,ctx)
 ctx.stage40GateOrdinalSemanticState=own(ctx.semanticState)
 ctx.legacyGateOrdinalDecimal=tostring(z)
 ctx.mode="STAGE_41_PATCH_20"
 ctx.phase="PATCH_GATE_ORDINAL_ONE_BASED"
 ctx.status="PATCH_GATE_ORDINAL_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_ORDINAL_ONE_BASED_PATCH",function(active,owner)
  local ordinal=Patch.correctOrdinal(day,opening,closing,z)
  local state={
   source="PATCH_20_GATE_ORDINAL_ONE_BASED",
   requestedDayDecimal=tostring(day), correctedGateIndex=k,
   openingGateDayDecimal=tostring(opening),
   nextGateDayDecimal=tostring(closing),
   gapLengthDecimal=tostring(gap),
   historicalOrdinalDecimal=tostring(z),
   correctedOrdinalDecimal=tostring(ordinal),
   oneBasedInsteadOfZeroBased=true,
   preservedLegacyCommitCount=3,ownedGateSnapshots=true,
   noNormativeOracleCalled=true,noYearLogic=true,noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch20.onebased.ordinal.lookups")
  owner.metricsManager:observe("patch20.corrected.index",k)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH20_ZERO_BASED_TO_ONE_BASED",
   gateIndex=k,historicalOrdinal=tostring(z),
   correctedOrdinal=tostring(ordinal)
  }
  active.status="PATCH_GATE_ORDINAL_COMPLETE"
  return B.from(ordinal)
 end)
 local corrected=manager.dispatcher:dispatch(
  ctx,"GATE_ORDINAL_ONE_BASED_PATCH",manager)
 return corrected,ctx
end
return Patch
