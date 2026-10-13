-- DISCOVERY 16: ansyen kalkil espas pòtay la fè youn twòp.
-- Rank nan 1..922 se rezilta PATCH 13, men legacy pran 42+rank.
-- Fòm normatif la dwe 41+rank, sa bay 42..963.
-- PATCH 16 pa antre nan chemen sa a.
local B=require("bigint")
local Base=require("monster_base")
local GateQuestion=require("gate_question_patch")
local ShortChoice=require("short_choice_patch")
local Legacy={}
local ONE=B.from(1)
local RANK_COUNT=B.from(922)
local OLD_OFFSET=B.from(42)
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
function Legacy.oldGateGapFromRank(rank)
 local selected=B.from(rank)
 assert(B.compare(selected,ONE)>=0 and B.compare(selected,RANK_COUNT)<=0,
  "DISCOVERY 16: rank pòtay dwe 1..922")
 return B.add(OLD_OFFSET,selected)
end
function Legacy.execute(signedStep,first,direction)
 local step=B.from(signedStep)
 local questionDay,ctx=GateQuestion.execute(step)
 assert(B.compare(questionDay,B.add(F,step))==0
  and ctx.commitToken==3 and #ctx.branchTrace==3
  and ctx.status=="PATCH_SIGNED_GATE_COMPLETE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY 16: kestyon siyen PATCH 15 pa valide")
 local rank,choiceContext=ShortChoice.execute(first,direction,RANK_COUNT)
 local seed=B.from(first)
 assert(type(direction)=="number" and (direction==1 or direction==-1)
  and type(choiceContext)=="table"
  and choiceContext.mode=="STAGE_27_PATCH_13"
  and choiceContext.status=="PATCH_SHORT_CHOICE_COMPLETE"
  and choiceContext.commitToken==3
  and choiceContext.semanticState.correctedRankDecimal==tostring(rank)
  and choiceContext.semanticState.firstDecimal==tostring(seed)
  and choiceContext.semanticState.optionCountDecimal==tostring(RANK_COUNT)
  and choiceContext.semanticState.directionStep==direction
  and choiceContext.pendingSemanticState==nil
  and B.compare(rank,ONE)>=0 and B.compare(rank,RANK_COUNT)<=0,
  "DISCOVERY 16: rank PATCH 13 pa otantik")
 ctx.choiceSemanticState=clone(choiceContext.semanticState)
 ctx.choiceCommitCount=choiceContext.commitToken
 ctx.choiceContextStatus=choiceContext.status
 ctx.previousSignedGateState=clone(ctx.semanticState)
 ctx.mode="STAGE_32_DISCOVERY_16"
 ctx.phase="LEGACY_GATE_GAP_OFFSET"
 ctx.status="LEGACY_GATE_GAP_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_GATE_GAP_PLUS_ONE",function(active,owner)
  local wrong=Legacy.oldGateGapFromRank(rank)
  assert(B.compare(wrong,B.add(OLD_OFFSET,rank))==0,
   "DISCOVERY 16: legacy +1 not authentic")
  local state={
   source="LEGACY_GATE_GAP_EXTRA_ONE",
   signedStepDecimal=tostring(step),
   questionDayDecimal=tostring(questionDay),
   firstDecimal=tostring(seed),directionStep=direction,
   optionsDecimal=tostring(RANK_COUNT),
   selectedRankDecimal=tostring(rank),
   oldOffsetDecimal=tostring(OLD_OFFSET),
   historicalGapDecimal=tostring(wrong),
   noAcceptanceBias=true,
   signedGateQuestionAlreadyPatched=true,
   legacyOffByOnePreserved=true,
   correctedGapAvailable=false,
   previousSignedCommitCount=3,
   noGateSequenceBuilt=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("legacy.gateGap.extraOne.calls")
  owner.metricsManager:observe("legacy.gateGap.selectedRanks",tostring(rank))
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY_16_GATE_GAP_PLUS_ONE",
   questionDay=tostring(questionDay),rank=tostring(rank),
   gap=tostring(wrong),historicalOffset=tostring(OLD_OFFSET)
  }
  active.status="LEGACY_GATE_GAP_COMPLETE"
  return B.from(wrong)
 end)
 local result=manager.dispatcher:dispatch(ctx,"LEGACY_GATE_GAP_PLUS_ONE",manager)
 return B.from(result),ctx
end
return Legacy
