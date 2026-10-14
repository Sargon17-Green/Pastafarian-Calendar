-- PATCH 16: repare +1 anplis nan offset espas pòtay la.
-- Tout travay DISCOVERY 16 la rete, apre sa senkyèm commit retire 1.
-- Fòm kòrèk la se 41+rank pou rank egzak 1..922.
local B=require("bigint")
local Base=require("monster_base")
local Old=require("legacy_gate_gap")
local ShortChoice=require("short_choice_patch")
local Patch={}
local ONE=B.from(1)
local N=B.from(922)
local OLD_OFFSET=B.from(42)
local NEW_OFFSET=B.from(41)
local MIN_GAP=B.from(42)
local MAX_GAP=B.from(963)
local F=B.from("-15055671")

local function clone(v,seen)
 if type(v)~="table" then return v end
 seen=seen or {}
 if seen[v] then return seen[v] end
 local t={};seen[v]=t
 for k,x in pairs(v) do t[clone(k,seen)]=clone(x,seen) end
 return t
end

local function inspectLegacy(wrong,ctx,step,seed,direction)
 assert(type(direction)=="number" and math.type(direction)=="integer"
  and (direction==1 or direction==-1),"PATCH 16: direksyon rank dwe +1/-1")
 local expectedRank=ShortChoice.chooseShort(seed,direction,N)
 local oldExpected=B.add(OLD_OFFSET,expectedRank)
 local question=B.add(F,step)
 assert(B.compare(wrong,oldExpected)==0
  and type(ctx)=="table"
  and ctx.mode=="STAGE_32_DISCOVERY_16"
  and ctx.phase=="LEGACY_GATE_GAP_OFFSET"
  and ctx.status=="LEGACY_GATE_GAP_COMPLETE"
  and ctx.commitToken==4 and #ctx.branchTrace==4
  and ctx.branchTrace[1]=="LEGACY_SIGNED_GATE_STEP"
  and ctx.branchTrace[2]=="LEGACY_ABSOLUTE_GATE_QUERY"
  and ctx.branchTrace[3]=="SIGNED_GATE_QUESTION_PATCH"
  and ctx.branchTrace[4]=="LEGACY_GATE_GAP_PLUS_ONE"
  and ctx.currentHandler=="LEGACY_GATE_GAP_PLUS_ONE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH 16: istwa 4 commits DISCOVERY 16 pa otantik")
 local s=ctx.semanticState
 assert(type(s)=="table"
  and s.source=="LEGACY_GATE_GAP_EXTRA_ONE"
  and s.signedStepDecimal==tostring(step)
  and s.questionDayDecimal==tostring(question)
  and s.firstDecimal==tostring(seed)
  and s.directionStep==direction
  and s.optionsDecimal==tostring(N)
  and s.selectedRankDecimal==tostring(expectedRank)
  and s.oldOffsetDecimal==tostring(OLD_OFFSET)
  and s.historicalGapDecimal==tostring(wrong)
  and s.noAcceptanceBias==true
  and s.signedGateQuestionAlreadyPatched==true
  and s.legacyOffByOnePreserved==true
  and s.correctedGapAvailable==false
  and s.previousSignedCommitCount==3
  and s.noGateSequenceBuilt==true,
  "PATCH 16: eta legacy gap oswa rank fo")
 assert(type(ctx.choiceSemanticState)=="table"
  and ctx.choiceSemanticState.source=="PATCH_13_ACCEPTANCE_REJECTION_SHORT"
  and ctx.choiceSemanticState.optionCountDecimal==tostring(N)
  and ctx.choiceSemanticState.correctedRankDecimal==tostring(expectedRank)
  and ctx.choiceSemanticState.firstDecimal==tostring(seed)
  and ctx.choiceSemanticState.directionStep==direction
  and ctx.choiceCommitCount==3
  and ctx.choiceContextStatus=="PATCH_SHORT_CHOICE_COMPLETE"
  and type(ctx.previousSignedGateState)=="table"
  and ctx.previousSignedGateState.source=="PATCH_15_SIGNED_GATE_QUESTION"
  and ctx.previousSignedGateState.correctedQuestionDayDecimal==tostring(question)
  and type(ctx.metrics)=="table"
  and ctx.metrics["legacy.gateGap.extraOne.calls"]==1
  and ctx.metrics["gateQuestion.patch.calls"]==1
  and type(ctx.diagnostics)=="table"
  and #ctx.diagnostics==4
  and ctx.diagnostics[4].code=="DISCOVERY_16_GATE_GAP_PLUS_ONE"
  and ctx.diagnostics[4].rank==tostring(expectedRank)
  and ctx.diagnostics[4].gap==tostring(wrong)
  and ctx.diagnostics[4].historicalOffset==tostring(OLD_OFFSET),
  "PATCH 16: provenance rank/kestyon legacy pa otantik")
 return B.from(expectedRank),B.from(question)
end

function Patch.correctGateGap(rank,wrong)
 local selected=B.from(rank)
 local old=B.from(wrong)
 assert(B.compare(selected,ONE)>=0 and B.compare(selected,N)<=0,
  "PATCH 16: rank dwe 1..922")
 assert(B.compare(old,B.add(OLD_OFFSET,selected))==0,
  "PATCH 16: ansyen gap pa koresponn ak rank")
 local repaired=B.sub(old,ONE)
 assert(B.compare(repaired,B.add(NEW_OFFSET,selected))==0
  and B.compare(repaired,MIN_GAP)>=0
  and B.compare(repaired,MAX_GAP)<=0,
  "PATCH 16: gap normatif pa nan 42..963")
 return B.from(repaired),{
  rank=B.from(selected),oldGap=B.from(old),newGap=B.from(repaired),
  oldOffset=B.from(OLD_OFFSET),newOffset=B.from(NEW_OFFSET),
  removedExtraOne=true
 }
end

function Patch.execute(signedStep,first,direction)
 local step=B.from(signedStep)
 local seed=B.from(first)
 local oldGap,ctx=Old.execute(step,seed,direction)
 local rank,question=inspectLegacy(oldGap,ctx,step,seed,direction)
 ctx.legacyGapSemanticState=clone(ctx.semanticState)
 ctx.legacyGapValue=B.from(oldGap)
 ctx.mode="STAGE_33_PATCH_16"
 ctx.phase="PATCH_GATE_GAP_OFFSET"
 ctx.status="PATCH_GATE_GAP_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("GATE_GAP_OFFSET_PATCH",function(active,owner)
  local right,proof=Patch.correctGateGap(rank,oldGap)
  assert(B.compare(proof.rank,rank)==0
   and B.compare(proof.oldGap,oldGap)==0
   and B.compare(proof.newGap,right)==0
   and proof.removedExtraOne==true,
   "PATCH 16: prèv koreksyon pa koresponn ak rank")
  local state={
   source="PATCH_16_GATE_GAP_OFFSET",
   signedStepDecimal=tostring(step),
   questionDayDecimal=tostring(question),
   firstDecimal=tostring(seed),
   directionStep=direction,
   optionsDecimal=tostring(N),
   selectedRankDecimal=tostring(rank),
   historicalOffsetDecimal=tostring(OLD_OFFSET),
   correctedOffsetDecimal=tostring(NEW_OFFSET),
   historicalGapDecimal=tostring(oldGap),
   correctedGapDecimal=tostring(right),
   priorCommitCount=4,
   legacyExtraOnePreserved=true,
   originalSignedQueryPreserved=true,
   originalChoiceRankPreserved=true,
   noGateSequenceBuilt=true,
   noPostStir12=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("gateGap.patch.calls")
  owner.metricsManager:bump("gateGap.patch.removedExtraOne")
  owner.metricsManager:observe("gateGap.patch.correctedGaps",tostring(right))
  active.diagnostics[#active.diagnostics+1]={
   code="PATCH_16_REMOVE_GATE_GAP_EXTRA_ONE",
   rank=tostring(rank),historicalGap=tostring(oldGap),
   correctedGap=tostring(right),questionDay=tostring(question)
  }
  active.status="PATCH_GATE_GAP_COMPLETE"
  return B.from(right)
 end)
 local result=manager.dispatcher:dispatch(ctx,"GATE_GAP_OFFSET_PATCH",manager)
 return B.from(result),ctx
end

return Patch
