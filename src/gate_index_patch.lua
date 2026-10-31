-- Stage39 PATCH19: correct strict-boundary legacy index without erasing its trace.
-- The 17 gate days are caller-supplied PATCH17/PATCH18 results; no oracle.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_gate_index_lookup")
local Patch={}

local function clone(x,seen)
 if type(x)~="table" then return x end
 seen=seen or {}
 if seen[x] then return seen[x] end
 local out={};seen[x]=out
 for k,v in pairs(x) do out[clone(k,seen)]=clone(v,seen) end
 return out
end

local function inspectLegacy(target,records,old,ctx)
 assert(type(old)=="number" and math.type(old)=="integer"
  and old>=-8 and old<=6,"PATCH19: legacy index invalid")
 assert(type(ctx)=="table"
  and ctx.mode=="STAGE_38_DISCOVERY_19"
  and ctx.status=="LEGACY_GATE_INDEX_COMPLETE"
  and ctx.commitToken==1 and #ctx.branchTrace==1
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.currentHandler=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==1
  and ctx.diagnostics[1].code=="DISCOVERY19_GATE_BOUNDARY_STRICT_LT"
  and ctx.metrics["discovery19.legacy.lookups"]==1,
  "PATCH19: legacy trace not authentic")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="LEGACY_GATE_INDEX_STRICT_LT"
  and s.returnedIndex==old and s.strictLessInsteadOfLessOrEqual==true
  and s.noCanonicalLookupComputed==true and s.noPostStir12==true
  and s.noYearLogic==true
  and type(s.gateDayDecimals)=="table"
  and #s.gateDayDecimals==17,
  "PATCH19: legacy semantic state invalid")
 local day=B.from(target)
 assert(tostring(day)==s.requestedDayDecimal,
  "PATCH19: legacy target changed")
 local days={}
 for i=1,17 do
  days[i]=B.from(s.gateDayDecimals[i])
  assert(type(records[i])=="table" and records[i].index==i-9
   and B.compare(days[i],records[i].day)==0,
   "PATCH19: legacy source mismatch")
 end
 assert(B.compare(days[old+9],day)<0
  and B.compare(day,days[old+10])<=0,
  "PATCH19: historical strict-LT interval invalid")
 return day,days
end

function Patch.correctBoundary(day,days,old)
 local nextDay=days[old+10]
 local atBoundary=B.compare(day,nextDay)==0
 local right=atBoundary and old+1 or old
 assert(B.compare(days[right+9],day)<=0
  and B.compare(day,days[right+10])<0,
  "PATCH19: corrected half-open interval invalid")
 return right,atBoundary
end

function Patch.execute(target,records)
 local historical,ctx=Legacy.execute(target,records)
 local day,days=inspectLegacy(target,records,historical,ctx)
 ctx.legacyGateIndexSemanticState=clone(ctx.semanticState)
 ctx.legacyGateIndex=historical
 ctx.mode="STAGE_39_PATCH_19"
 ctx.phase="PATCH_GATE_INDEX_LEQ_BOUNDARY"
 ctx.status="PATCH_GATE_INDEX_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_INDEX_LEQ_BOUNDARY_PATCH",function(active,owner)
  local right,boundary=Patch.correctBoundary(day,days,historical)
  local copied={}
  for i=1,17 do copied[i]=tostring(days[i]) end
  local state={
   source="PATCH_19_GATE_INDEX_AT_OR_BEFORE",
   requestedDayDecimal=tostring(day),
   historicalStrictIndex=historical,correctedIndex=right,
   exactBoundaryCorrected=boundary,gateDayDecimals=copied,
   preservedLegacyCommitCount=1,ownedGateSnapshots=true,
   noNormativeOracleCalled=true,noPostStir12=true,noYearLogic=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("patch19.boundary.lookups")
  owner.metricsManager:observe("patch19.boundary.indices",right)
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH19_STRICT_LT_TO_LEQ_BOUNDARY",
   historicalIndex=historical,correctedIndex=right,
   exactBoundary=boundary,requestedDay=tostring(day)
  }
  active.status="PATCH_GATE_INDEX_COMPLETE"
  return right
 end)
 local corrected=manager.dispatcher:dispatch(
  ctx,"GATE_INDEX_LEQ_BOUNDARY_PATCH",manager)
 return corrected,ctx
end

return Patch
