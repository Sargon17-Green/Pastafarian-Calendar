-- Stage40 DISCOVERY20: intentionally historical zero-based ordinal.
-- Caller supplies corrected signed gates, no canonical oracle in production.
local B=require("bigint")
local Base=require("monster_base")
local GateIndexPatch=require("gate_index_patch")
local M={}

local function own(x,seen)
 if type(x)~="table" then return x end
 seen=seen or {}
 if seen[x] then return seen[x] end
 local y={};seen[x]=y
 for k,v in pairs(x) do y[own(k,seen)]=own(v,seen) end
 return y
end

function M.execute(target,records)
 local k,ctx=GateIndexPatch.execute(target,records)
 assert(ctx.mode=="STAGE_39_PATCH_19"
  and ctx.status=="PATCH_GATE_INDEX_COMPLETE"
  and ctx.commitToken==2 and #ctx.branchTrace==2
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["patch19.boundary.lookups"]==1
  and type(ctx.semanticState)=="table"
  and ctx.semanticState.correctedIndex==k
  and ctx.semanticState.ownedGateSnapshots==true,
  "DISCOVERY20: bezwen PATCH19 otantik")
 local state=ctx.semanticState
 local day=B.from(target)
 assert(state.requestedDayDecimal==tostring(day),
  "DISCOVERY20: jou a chanje")
 local current=B.from(state.gateDayDecimals[k+9])
 local nextGate=B.from(state.gateDayDecimals[k+10])
 assert(B.compare(current,day)<=0 and B.compare(day,nextGate)<0,
  "DISCOVERY20: jou pa nan entèval pòtay la")
 local gap=B.sub(nextGate,current)
 local zero=B.sub(day,current)
 assert(B.compare(zero,0)>=0 and B.compare(zero,gap)<0,
  "DISCOVERY20: òdinal istorik pa valab")

 ctx.stage39GateIndexSemanticState=own(state)
 ctx.mode="STAGE_40_DISCOVERY_20"
 ctx.phase="LEGACY_GATE_ORDINAL_ZERO_BASED"
 ctx.status="LEGACY_GATE_ORDINAL_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_GATE_ORDINAL_ZERO_BASED",function(active,owner)
  local result=own({
   source="DISCOVERY20_LEGACY_ZERO_BASED",
   requestedDayDecimal=tostring(day),correctedGateIndex=k,
   openingGateDayDecimal=tostring(current),
   nextGateDayDecimal=tostring(nextGate),
   gapLengthDecimal=tostring(gap),
   historicalOrdinalDecimal=tostring(zero),
   zeroBasedInsteadOfOneBased=true,
   noCanonicalOrdinalComputed=true,noYearLogic=true,noPostStir12=true
  })
  active:beginSemanticUpdate(result)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery20.legacy.ordinal.lookups")
  owner.metricsManager:observe("discovery20.legacy.index",k)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY20_ZERO_BASED_GATE_ORDINAL",
   gateIndex=k,historicalOrdinal=tostring(zero)
  }
  active.status="LEGACY_GATE_ORDINAL_COMPLETE"
  return B.from(zero)
 end)
 local value=manager.dispatcher:dispatch(
  ctx,"LEGACY_GATE_ORDINAL_ZERO_BASED",manager)
 return value,ctx
end
return M
