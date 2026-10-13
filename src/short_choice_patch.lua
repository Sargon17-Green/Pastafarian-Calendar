-- PATCH 13: pran premye repons SAVE ki antre nan rejyon akseptasyon an.
-- Konsève DISCOVERY 13 la, epi repare modulo bias san manyen legacy.
-- A_k se yon sik +1/-1: rejyon rejte a se [limit+1,M].
-- Si li gwo, sote rejyon kontig sa a ak prèv olye trillions iterasyon.
local B=require("bigint")
local Base=require("monster_base")
local Legacy=require("legacy_biased_choice")
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
 for k,value in pairs(v) do out[clone(k,seen)]=clone(value,seen) end
 return out
end

local function validateInputs(first,step,n)
 local seed=B.from(first)
 local size=B.from(n)
 assert(B.compare(seed,ONE)>=0 and B.compare(seed,M)<=0,
    "PATCH 13: premye repons SAVE dwe 1..M")
 assert(type(step)=="number" and math.type(step)=="integer"
     and (step==1 or step==-1),"PATCH 13: direksyon dwe +1/-1")
 assert(B.compare(size,ONE)>=0 and B.compare(size,M)<=0,
     "PATCH 13: kantite chwa dwe 1..M")
 return seed,size
end

local function verifyLegacy(wrong,ctx,seed,step,size)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_26_DISCOVERY_13"
   and ctx.status=="LEGACY_BIASED_PICK_COMPLETE"
   and ctx.phase=="LEGACY_DIRECT_MODULO_SELECTION"
   and ctx.commitToken==2 and #ctx.branchTrace==2
   and ctx.branchTrace[1]=="LEGACY_REPLY_STREAM"
   and ctx.branchTrace[2]=="LEGACY_BIASED_MODULO_PICK"
   and ctx.currentHandler=="LEGACY_BIASED_MODULO_PICK"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
   "PATCH 13: tras DISCOVERY 13 pa otantik")
 local state=ctx.semanticState
 local expected=B.add(ONE,B.mod(B.sub(seed,ONE),size))
 assert(type(state)=="table"
   and state.source=="LEGACY_DIRECT_MODULO_WITHOUT_REJECTION"
   and state.firstDecimal==tostring(seed)
   and state.optionCountDecimal==tostring(size)
   and state.directionStep==step
   and state.consumedAnswerCount==1
   and state.sampleIndex==0
   and state.ignoredFurtherAnswers==true
   and state.didApplyAcceptanceThreshold==false
   and state.legacyModuloBiasPreserved==true
   and state.shortPathOnly==true
   and state.resultRankDecimal==tostring(expected)
   and B.compare(wrong,expected)==0,
   "PATCH 13: ansyen chwa modulo pa otantik")
 assert(type(ctx.metrics)=="table"
   and ctx.metrics["legacy.replyStream.calls"]==1
   and ctx.metrics["legacy.biasedModulo.calls"]==1
   and type(ctx.diagnostics)=="table"
   and #ctx.diagnostics==2
   and ctx.diagnostics[1].code=="DISCOVERY_13_VALID_SAVE_REPLY_STREAM"
   and ctx.diagnostics[2].code=="DISCOVERY_13_SKIPS_ACCEPTANCE_LIMIT",
   "PATCH 13: metrik oswa dyagnostik istorik pa otantik")
 assert(state.nextDecimal==tostring(Legacy.answerAt(seed,step,ONE)),
   "PATCH 13: A1 istorik pa valab")
 return B.from(expected)
end

-- N<=M. limit=floor(M/N)*N. Rekonstriksyon egzakt sik la:
-- +1: si A0>limit, tout A0..M rejte, premye aksepte a se 1.
-- -1: si A0>limit, tout A0..(limit+1) rejte, premye aksepte a se limit.
-- Konbinezon sa a bay menm premye akseptasyon ak esè lineyè yo.
function Patch.chooseShort(first,step,n)
 local seed,size=validateInputs(first,step,n)
 local limit=B.mul(B.floorDiv(M,size),size)
 local rejected=ZERO
 if B.compare(seed,limit)>0 then
   if step==1 then rejected=B.add(B.sub(M,seed),ONE)
   else rejected=B.sub(seed,limit) end
 end
 local reply=Legacy.answerAt(seed,step,rejected)
 assert(B.compare(reply,ONE)>=0 and B.compare(reply,limit)<=0,
    "PATCH 13: premye repons aksepte a pa nan limit")
 if B.compare(rejected,ZERO)>0 then
   local prev=Legacy.answerAt(seed,step,B.sub(rejected,ONE))
   assert(B.compare(prev,limit)>0,
      "PATCH 13: repons anvan premye akseptasyon te valab")
   if step==1 then assert(B.compare(reply,ONE)==0
      and B.compare(prev,M)==0,"PATCH 13: sik pozitif pa prouve")
   else assert(B.compare(reply,limit)==0
      and B.compare(prev,B.add(limit,ONE))==0,
      "PATCH 13: sik negatif pa prouve") end
 end
 local maxCheck=B.toNumber(rejected)
 local checked=(maxCheck and math.min(maxCheck,64)) or 64
 for k=0,checked-1 do
   assert(B.compare(Legacy.answerAt(seed,step,k),limit)>0,
     "PATCH 13: sipoze rejè ki te akseptab")
 end
 local rank=B.add(ONE,B.mod(B.sub(reply,ONE),size))
 assert(B.compare(rank,ONE)>=0 and B.compare(rank,size)<=0)
 return B.from(rank),{
   first=B.from(seed),optionCount=B.from(size),limit=B.from(limit),
   accepted=B.from(reply),rejected=B.from(rejected),index=B.from(rejected),
   testedRejections=checked,usedContiguousSkip=B.compare(rejected,64)>0
 }
end

function Patch.execute(first,step,n)
 local seed,size=validateInputs(first,step,n)
 local wrong,ctx=Legacy.execute(seed,step,size)
 local legacy=verifyLegacy(wrong,ctx,seed,step,size)
 ctx.legacyChoiceSemanticState=clone(ctx.semanticState)
 ctx.legacyChoiceRank=B.from(legacy)
 ctx.mode="STAGE_27_PATCH_13"
 ctx.phase="PATCH_SHORT_CHOICE_ACCEPTANCE"
 ctx.status="PATCH_SHORT_CHOICE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("SHORT_CHOICE_REJECTION_PATCH",function(active,owner)
   local rank,proof=Patch.chooseShort(seed,step,size)
   assert(B.compare(proof.first,seed)==0
      and B.compare(proof.optionCount,size)==0,
      "PATCH 13: prèv limit pa itilize sous legacy la")
   local state={
     source="PATCH_13_ACCEPTANCE_REJECTION_SHORT",
     firstDecimal=tostring(seed),directionStep=step,
     optionCountDecimal=tostring(size),
     thresholdDecimal=tostring(proof.limit),
     acceptedAnswerDecimal=tostring(proof.accepted),
     acceptedSampleIndexDecimal=tostring(proof.index),
     logicallyRejectedCountDecimal=tostring(proof.rejected),
     checkedRejectedSamples=proof.testedRejections,
     usedContiguousRejectionSkip=proof.usedContiguousSkip,
     correctedRankDecimal=tostring(rank),
     legacyRankDecimal=tostring(legacy),
     legacyCallPreserved=true,
     previousCommitCount=2,
     appliesAcceptanceThreshold=true,
     shortPathOnly=true
   }
   active:beginSemanticUpdate(state)
   owner.validationManager:requirePendingState(active)
   active:commitSemanticUpdate()
   owner.validationManager:requireNoPendingState(active)
   owner.metricsManager:bump("shortChoice.patch.calls")
   owner.metricsManager:bump("shortChoice.patch.accepted")
   owner.metricsManager:observe("shortChoice.patch.rejected",state.logicallyRejectedCountDecimal)
   owner.metricsManager:observe("shortChoice.patch.acceptedIndex",state.acceptedSampleIndexDecimal)
   if proof.usedContiguousSkip then
      owner.metricsManager:bump("shortChoice.patch.largeSkipProofs")
   end
   active.diagnostics[#active.diagnostics+1]={
      code="PATCH_13_ACCEPTANCE_THRESHOLD_AND_REJECTION",
      legacyRank=tostring(legacy),correctedRank=tostring(rank),
      acceptedAnswer=tostring(proof.accepted),
      limit=tostring(proof.limit),rejected=tostring(proof.rejected)
   }
   active.status="PATCH_SHORT_CHOICE_COMPLETE"
   return B.from(rank)
 end)
 local corrected=manager.dispatcher:dispatch(ctx,"SHORT_CHOICE_REJECTION_PATCH",manager)
 return B.from(corrected),ctx
end

return Patch
