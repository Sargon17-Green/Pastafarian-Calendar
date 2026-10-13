-- PATCH 14: konsève blokaj legacy laj la, apre sa chwazi nan M^k.
-- Chif nan baz M yo vini nan lòd pi piti pwa an premye.
-- Rejè kontig yo mande prèv, pa yon bouk ki ka depase 2^64.
local B=require("bigint")
local Base=require("monster_base")
local Old=require("legacy_short_only_choice")
local Stream=require("legacy_biased_choice")
local Patch={}
local ONE=B.from(1)
local ZERO=B.from(0)
local M=B.from("170141183460469231731687303715884105727")

local function clone(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local out={}
 seen[v]=out
 for k,x in pairs(v) do out[clone(k,seen)]=clone(x,seen) end
 return out
end

local function inputs(first,step,n)
 local seed=B.from(first)
 local size=B.from(n)
 assert(B.compare(seed,ONE)>=0 and B.compare(seed,M)<=0,
   "PATCH 14: premye repons SAVE dwe 1..M")
 assert(type(step)=="number" and math.type(step)=="integer"
   and (step==1 or step==-1),"PATCH 14: direksyon dwe +1/-1")
 assert(B.compare(size,M)>0,"PATCH 14: chemen laj mande N>M")
 return seed,size
end

local function validateLegacy(missing,ctx,seed,step,size)
 assert(missing==nil and type(ctx)=="table"
   and ctx.mode=="STAGE_28_DISCOVERY_14"
   and ctx.phase=="LEGACY_SHORT_ONLY_SELECTION_DISPATCH"
   and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
   and ctx.commitToken==1 and #ctx.branchTrace==1
   and ctx.currentHandler=="LEGACY_WIDE_SENT_TO_SHORT_PATH"
   and ctx.branchTrace[1]=="LEGACY_WIDE_SENT_TO_SHORT_PATH"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
   "PATCH 14: tras DISCOVERY 14 pa otantik")
 local s=ctx.semanticState
 assert(type(s)=="table"
   and s.source=="LEGACY_SHORT_ASSUMPTION_REJECTS_N_GREATER_THAN_M"
   and s.firstDecimal==tostring(seed)
   and s.directionStep==step
   and s.optionCountDecimal==tostring(size)
   and s.modulusDecimal==tostring(M)
   and s.attemptedShortPatch==true
   and s.failureIsShortSizeRestriction==true
   and s.noWidePath==true
   and s.wideRankAvailable==false
   and s.selectedRankDecimal==nil
   and s.logicallyValidRankAbsent==true
   and s.attemptedCalls==1
   and type(s.shortError)=="string"
   and s.shortError:find("PATCH 13: kantite chwa dwe 1..M",1,true)
   and type(ctx.metrics)=="table"
   and ctx.metrics["legacy.wideBlocked.calls"]==1
   and ctx.metrics["legacy.wideBlocked.shortAttempt"]==1
   and type(ctx.diagnostics)=="table" and #ctx.diagnostics==1
   and ctx.diagnostics[1].code=="DISCOVERY_14_WIDE_SHORT_ONLY_BLOCK",
   "PATCH 14: semantic legacy oswa provenance fo")
end

-- Fonksyon sa a pa enpòte oracle: li aplike regleman normatif la
-- separeman, sou sous SAVE reyèl ki te egziste depi Stage 26.
function Patch.chooseWide(first,step,n)
 local seed,size=inputs(first,step,n)
 local k,space=1,B.from(M)
 while B.compare(space,size)<0 do
   space=B.mul(space,M)
   k=k+1
 end
 local initial=B.from(ONE)
 local weight=B.from(ONE)
 local digits={}
 for j=0,k-1 do
   local reply=Stream.answerAt(seed,step,j)
   assert(B.compare(reply,ONE)>=0 and B.compare(reply,M)<=0,
      "PATCH 14: chif SAVE pa nan 1..M")
   digits[j+1]=B.from(reply)
   initial=B.add(initial,B.mul(B.sub(reply,ONE),weight))
   weight=B.mul(weight,M)
 end
 assert(B.compare(weight,space)==0
   and B.compare(initial,ONE)>=0 and B.compare(initial,space)<=0,
   "PATCH 14: konstriksyon chif ki pi ba an premye pa egzak")
 local limit=B.mul(B.floorDiv(space,size),size)
 local rejected=B.from(ZERO)
 if B.compare(initial,limit)>0 then
   if step==1 then rejected=B.add(B.sub(space,initial),ONE)
   else rejected=B.sub(initial,limit) end
 end
 local accepted=B.add(ONE,B.mod(B.add(B.sub(initial,ONE),
                                  B.mulSmall(rejected,step)),space))
 assert(B.compare(accepted,ONE)>=0 and B.compare(accepted,limit)<=0,
   "PATCH 14: premye echantiyon aksepte a pa valab")
 if B.compare(rejected,ZERO)>0 then
   local previous=B.add(ONE,B.mod(B.add(B.sub(initial,ONE),
                                      B.mulSmall(B.sub(rejected,ONE),step)),space))
   assert(B.compare(previous,limit)>0,"PATCH 14: rejè anvan an valab")
   if step==1 then
     assert(B.compare(accepted,ONE)==0 and B.compare(previous,space)==0,
        "PATCH 14: sik laj pozitif pa prouve")
   else
     assert(B.compare(accepted,limit)==0
        and B.compare(previous,B.add(limit,ONE))==0,
        "PATCH 14: sik laj negatif pa prouve")
   end
 end
 local rejectedNumber=B.toNumber(rejected)
 local check=(rejectedNumber and math.min(rejectedNumber,64)) or 64
 for j=0,check-1 do
   local candidate=B.add(ONE,B.mod(B.add(B.sub(initial,ONE),B.mulSmall(B.from(j),step)),space))
   assert(B.compare(candidate,limit)>0,"PATCH 14: yon rejè te valab")
 end
 local rank=B.add(ONE,B.mod(B.sub(accepted,ONE),size))
 assert(B.compare(rank,ONE)>=0 and B.compare(rank,size)<=0)
 return B.from(rank),{
   digitCount=k,space=B.from(space),initial=B.from(initial),
   limit=B.from(limit),accepted=B.from(accepted),
   rejected=B.from(rejected),digits=digits,
   checkedRejections=check,usedLargeSkip=B.compare(rejected,64)>0
 }
end

function Patch.execute(first,step,n)
 local seed,size=inputs(first,step,n)
 -- Toujou fè chemen istorik la an premye: premye commit la pa pèdi.
 local missing,ctx=Old.execute(seed,step,size)
 validateLegacy(missing,ctx,seed,step,size)
 ctx.legacyWideSemanticState=clone(ctx.semanticState)
 ctx.mode="STAGE_29_PATCH_14"
 ctx.phase="PATCH_WIDE_CHOICE_DETOUR"
 ctx.status="PATCH_WIDE_CHOICE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("WIDE_CHOICE_REJECTION_PATCH",function(active,owner)
   local rank,proof=Patch.chooseWide(seed,step,size)
   local state={
     source="PATCH_14_BASE_M_WIDE_CHOICE",
     firstDecimal=tostring(seed),directionStep=step,
     optionCountDecimal=tostring(size),
     digitCount=proof.digitCount,
     digitRepliesDecimal={},
     answerSpaceDecimal=tostring(proof.space),
     initialWideAnswerDecimal=tostring(proof.initial),
     thresholdDecimal=tostring(proof.limit),
     acceptedWideAnswerDecimal=tostring(proof.accepted),
     rejectedCountDecimal=tostring(proof.rejected),
     checkedRejections=proof.checkedRejections,
     usedContiguousSkip=proof.usedLargeSkip,
     correctedRankDecimal=tostring(rank),
     blockedLegacyRank=nil,legacyBlockPreserved=true,
     wideRankAvailable=true,previousCommitCount=1
   }
   for i,value in ipairs(proof.digits) do state.digitRepliesDecimal[i]=tostring(value) end
   active:beginSemanticUpdate(state)
   owner.validationManager:requirePendingState(active)
   active:commitSemanticUpdate()
   owner.validationManager:requireNoPendingState(active)
   owner.metricsManager:bump("wideChoice.patch.calls")
   owner.metricsManager:observe("wideChoice.patch.digits",proof.digitCount)
   owner.metricsManager:observe("wideChoice.patch.rejections",tostring(proof.rejected))
   if proof.usedLargeSkip then owner.metricsManager:bump("wideChoice.patch.largeSkips") end
   active.diagnostics[#active.diagnostics+1]={
     code="PATCH_14_WIDE_DETOUR_AFTER_HISTORIC_BLOCK",
     digits=proof.digitCount,rank=tostring(rank),rejected=tostring(proof.rejected)
   }
   active.status="PATCH_WIDE_CHOICE_COMPLETE"
   return B.from(rank)
 end)
 local result=manager.dispatcher:dispatch(ctx,"WIDE_CHOICE_REJECTION_PATCH",manager)
 return B.from(result),ctx
end

return Patch
