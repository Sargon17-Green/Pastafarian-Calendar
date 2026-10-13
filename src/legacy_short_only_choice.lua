-- DISCOVERY 14: routing istorik panse chak kantite chwa N pa depase M.
-- Pou N>M, li eseye PATCH 13 short la; echèk li bloke rank la.
-- Pa mete okenn chwa wide oswa detour PATCH 14 nan Stage 28.
local B=require("bigint")
local Base=require("monster_base")
local Short=require("short_choice_patch")
local Old={}
local ONE=B.from(1)
local M=B.from("170141183460469231731687303715884105727")
local SHORT_LIMIT_MESSAGE="PATCH 13: kantite chwa dwe 1..M"

local function validate(first,direction,n)
 local initial=B.from(first)
 local options=B.from(n)
 assert(B.compare(initial,ONE)>=0 and B.compare(initial,M)<=0,
   "DISCOVERY 14: premye repons lan dwe ant 1 ak M")
 assert(type(direction)=="number" and math.type(direction)=="integer"
    and (direction==1 or direction==-1),
    "DISCOVERY 14: direksyon dwe +1/-1")
 assert(B.compare(options,ONE)>=0,
    "DISCOVERY 14: kantite opsyon dwe pozitif")
 return initial,options
end

-- Sa a se dispatcher istorik la. Li pa gen chemen N>M.
-- Li sèvi ak PATCH 13 otantik menm lè N mande chemen laj.
function Old.execute(first,direction,n)
 local initial,options=validate(first,direction,n)
 local isWide=B.compare(options,M)>0
 local ok,result,child=pcall(Short.execute,initial,direction,options)
 if not isWide then
   if not ok then error(result,0) end
   assert(type(child)=="table"
       and child.mode=="STAGE_27_PATCH_13"
       and child.status=="PATCH_SHORT_CHOICE_COMPLETE"
       and child.commitToken==3 and #child.branchTrace==3
       and child.branchTrace[3]=="SHORT_CHOICE_REJECTION_PATCH"
       and child.pendingSemanticState==nil and child.rollbackSnapshot==nil,
       "DISCOVERY 14: chemen short PATCH 13 pa otantik")
   assert(B.compare(result,ONE)>=0 and B.compare(result,options)<=0,
       "DISCOVERY 14: rank short pa valab")
   return B.from(result),child
 end
 assert(not ok and type(result)=="string"
    and result:find(SHORT_LIMIT_MESSAGE,1,true),
    "DISCOVERY 14: se sèlman limit short ki ka bloke chemen laj la")
 local ctx=Base.MonsterContext.new(1,1)
 ctx.mode="STAGE_28_DISCOVERY_14"
 ctx.phase="LEGACY_SHORT_ONLY_SELECTION_DISPATCH"
 ctx.status="LEGACY_WIDE_BLOCK_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_WIDE_SENT_TO_SHORT_PATH",function(active,owner)
   local state={
     source="LEGACY_SHORT_ASSUMPTION_REJECTS_N_GREATER_THAN_M",
     firstDecimal=tostring(initial),
     directionStep=direction,
     optionCountDecimal=tostring(options),
     modulusDecimal=tostring(M),
     attemptedShortPatch=true,
     shortError=result,
     noWidePath=true,
     failureIsShortSizeRestriction=true,
     shortPathStillPreserved=true,
     wideRankAvailable=false,
     selectedRankDecimal=nil,
     logicallyValidRankAbsent=true,
     attemptedCalls=1
   }
   active:beginSemanticUpdate(state)
   owner.validationManager:requirePendingState(active)
   active:commitSemanticUpdate()
   owner.validationManager:requireNoPendingState(active)
   owner.metricsManager:bump("legacy.wideBlocked.calls")
   owner.metricsManager:bump("legacy.wideBlocked.shortAttempt")
   owner.metricsManager:observe("legacy.wideBlocked.optionCount",tostring(options))
   active.diagnostics[#active.diagnostics+1]={
      code="DISCOVERY_14_WIDE_SHORT_ONLY_BLOCK",
      attemptedShort=true,rankMissing=true,
      options=tostring(options),shortError=result
   }
   active.status="LEGACY_WIDE_CHOICE_BLOCKED"
   return nil
 end)
 local wrong=manager.dispatcher:dispatch(ctx,"LEGACY_WIDE_SENT_TO_SHORT_PATH",manager)
 assert(wrong==nil and ctx.semanticState.wideRankAvailable==false,
   "DISCOVERY 14: chemen istorik laj la pa dwe bay rank")
 return nil,ctx
end

return Old
