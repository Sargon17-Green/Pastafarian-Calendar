-- PATCH 15: repare jou kestyon pòtay negatif apre de commits eritaj yo.
-- Lòd Fondasyon an dwe kenbe siy etap orijinal la: F + signedStep.
-- Pa efase ni modifye adaptè istorik DISCOVERY 15 la.
local B=require("bigint")
local Base=require("monster_base")
local Old=require("legacy_gate_question_adapter")
local Patch={}
local ZERO=B.from(0)
local F=B.from("-15055671")

local function clone(value,seen)
 if type(value)~="table" then return value end
 seen=seen or {}
 if seen[value] then return seen[value] end
 local out={}
 seen[value]=out
 for k,v in pairs(value) do out[clone(k,seen)]=clone(v,seen) end
 return out
end

local function validate(wrong,ctx,step)
 local distance=B.abs(step)
 local oldExpected=B.add(F,distance)
 local isNegative=B.compare(step,ZERO)<0
 assert(B.compare(wrong,oldExpected)==0
    and type(ctx)=="table"
    and ctx.mode=="STAGE_30_DISCOVERY_15"
    and ctx.phase=="LEGACY_GATE_ABSOLUTE_QUERY"
    and ctx.status=="LEGACY_GATE_QUERY_COMPLETE"
    and ctx.commitToken==2 and #ctx.branchTrace==2
    and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
    and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
    and ctx.currentHandler=="LEGACY_ABSOLUTE_GATE_QUERY"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
    "PATCH 15: tras legacy de commits pa otantik")
 local s=ctx.semanticState
 assert(type(s)=="table"
    and s.source=="LEGACY_ABSOLUTE_GATE_QUERY"
    and s.signedStepDecimal==tostring(step)
    and s.distanceMagnitudeDecimal==tostring(distance)
    and s.foundationDayDecimal==tostring(F)
    and s.queriedDayDecimal==tostring(wrong)
    and s.negativeRequested==isNegative
    and s.passedAbsoluteStep==true
    and s.signLostForNegative==isNegative
    and s.preservedOriginalSignedInput==true
    and s.didCorrectNegativeGate==false
    and type(ctx.metrics)=="table"
    and ctx.metrics["legacy.gateSignedInput.calls"]==1
    and ctx.metrics["legacy.gateAbsoluteQuery.calls"]==1
    and type(ctx.diagnostics)=="table" and #ctx.diagnostics==2
    and ctx.diagnostics[1].code=="DISCOVERY_15_SIGNED_GATE_REQUEST"
    and ctx.diagnostics[1].signedStep==tostring(step)
    and ctx.diagnostics[2].code=="DISCOVERY_15_ABSOLUTE_SIGN_LOSS"
    and ctx.diagnostics[2].queryDay==tostring(wrong)
    and ctx.diagnostics[2].signLost==isNegative,
    "PATCH 15: eta semantik oswa audit legacy fo")
 return distance,isNegative
end

-- Prèv aritmetik la separe de oracle test la; tout antye BigInt.
function Patch.correctQuestionDay(signedStep,legacyDay)
 local step=B.from(signedStep)
 local old=B.from(legacyDay)
 local distance=B.abs(step)
 assert(B.compare(old,B.add(F,distance))==0,
    "PATCH 15: jou kestyon legacy pa matche ak Fondasyon+abs")
 local corrected
 if B.compare(step,ZERO)<0 then
   corrected=B.sub(old,B.mulSmall(distance,2))
 else corrected=B.from(old) end
 assert(B.compare(corrected,B.add(F,step))==0,
    "PATCH 15: koreksyon jou siyen pa egzak")
 return B.from(corrected),{
   originalStep=B.from(step),legacyDay=B.from(old),
   magnitude=B.from(distance),correctedDay=B.from(corrected),
   changedNegative=B.compare(step,ZERO)<0
 }
end

function Patch.execute(signedStep)
 local step=B.from(signedStep)
 local wrong,ctx=Old.execute(step)
 local distance,isNegative=validate(wrong,ctx,step)
 ctx.legacyGateSemanticState=clone(ctx.semanticState)
 ctx.legacyGateQuestionDay=B.from(wrong)
 ctx.mode="STAGE_31_PATCH_15"
 ctx.phase="PATCH_SIGNED_GATE_QUESTION_DAY"
 ctx.status="PATCH_SIGNED_GATE_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("SIGNED_GATE_QUESTION_PATCH",function(active,owner)
   local right,proof=Patch.correctQuestionDay(step,wrong)
   assert(B.compare(proof.originalStep,step)==0
     and B.compare(proof.magnitude,distance)==0
     and B.compare(proof.legacyDay,wrong)==0
     and proof.changedNegative==isNegative,
     "PATCH 15: prèv nan move kontèks")
   local state={
     source="PATCH_15_SIGNED_GATE_QUESTION",
     signedStepDecimal=tostring(step),
     distanceMagnitudeDecimal=tostring(distance),
     foundationDayDecimal=tostring(F),
     legacyQuestionDayDecimal=tostring(wrong),
     correctedQuestionDayDecimal=tostring(right),
     originalLegacyStatePreserved=true,
     legacySignLossDetected=isNegative,
     correctedNegativeSide=isNegative,
     originalSignUsed=true,
     previousCommitCount=2,
     noGateChainConstructed=true,
     noPostStir12=true
   }
   active:beginSemanticUpdate(state)
   owner.validationManager:requirePendingState(active)
   active:commitSemanticUpdate()
   owner.validationManager:requireNoPendingState(active)
   owner.metricsManager:bump("gateQuestion.patch.calls")
   owner.metricsManager:observe("gateQuestion.patch.correctedDays",tostring(right))
   if isNegative then owner.metricsManager:bump("gateQuestion.patch.negativeCorrections") end
   active.diagnostics[#active.diagnostics+1]={
     code="PATCH_15_RESTORE_SIGNED_GATE_SIDE",
     signedStep=tostring(step),
     historicalDay=tostring(wrong),
     correctedDay=tostring(right),changed=isNegative
   }
   active.status="PATCH_SIGNED_GATE_COMPLETE"
   return B.from(right)
 end)
 local corrected=manager.dispatcher:dispatch(ctx,"SIGNED_GATE_QUESTION_PATCH",manager)
 return B.from(corrected),ctx
end

return Patch
