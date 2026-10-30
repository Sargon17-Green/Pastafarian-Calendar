-- Stage38 DISCOVERY19: deliberately introduced strict-boundary legacy lookup.
-- Caller supplies corrected gate days; no normative oracle in production.
local B=require("bigint")
local Base=require("monster_base")
local M={}
local LO,HI=B.from(42),B.from(963)
local function validate(target,records)
 assert(type(records)=="table" and #records==17,
  "DISCOVERY19: bezwen 17 potay")
 for k in pairs(records) do
  assert(type(k)=="number" and math.type(k)=="integer"
   and k>=1 and k<=17,"DISCOVERY19: lis pa dense")
 end
 local days={}
 for i=1,17 do
  assert(type(records[i])=="table" and records[i].index==i-9,
   "DISCOVERY19: endis yo dwe -8..8")
  days[i]=B.from(records[i].day)
  if i>1 then
   local gap=B.sub(days[i],days[i-1])
   assert(B.compare(gap,LO)>=0 and B.compare(gap,HI)<=0,
    "DISCOVERY19: gap dwe 42..963")
  end
 end
 local day=B.from(target)
 assert(B.compare(day,days[2])>=0 and B.compare(day,days[16])<=0,
  "DISCOVERY19: jou deyò domèn -7..7")
 return day,days
end
function M.execute(target,records)
 local day,days=validate(target,records)
 local ctx=Base.MonsterContext.new(0,0)
 ctx.mode="STAGE_38_DISCOVERY_19"
 ctx.phase="LEGACY_GATE_INDEX_STRICT_BEFORE"
 ctx.status="LEGACY_GATE_INDEX_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_GATE_INDEX_STRICT_LT",function(active,owner)
  local result
  for i=1,17 do
   if B.compare(days[i],day)<0 then result=i-9 else break end
  end
  assert(result~=nil,"DISCOVERY19: pa gen pòtay anvan")
  local snapshot={}
  for i=1,17 do snapshot[i]=tostring(days[i]) end
  local state={
   source="LEGACY_GATE_INDEX_STRICT_LT",
   requestedDayDecimal=tostring(day),returnedIndex=result,
   gateDayDecimals=snapshot,strictLessInsteadOfLessOrEqual=true,
   noCanonicalLookupComputed=true,noPostStir12=true,noYearLogic=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("discovery19.legacy.lookups")
  owner.metricsManager:observe("discovery19.legacy.index",result)
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY19_GATE_BOUNDARY_STRICT_LT",
   requestedDay=tostring(day),historicalIndex=result
  }
  active.status="LEGACY_GATE_INDEX_COMPLETE"
  return result
 end)
 local result=manager.dispatcher:dispatch(
  ctx,"LEGACY_GATE_INDEX_STRICT_LT",manager)
 return result,ctx
end
return M
