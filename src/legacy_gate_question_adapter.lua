-- DISCOVERY 15: chemen ansyen pòtay yo efase siy etap negatif la.
-- oldGateQuestionDay(n) mande jou Fondasyon + n pou n ki pa negatif.
-- Adaptè istorik la pase abs(signedStep), menm lè etap la negatif.
-- PATCH 15 pa antre isit la: rezilta istorik la dwe rete erone.
local B=require("bigint")
local Base=require("monster_base")
local Legacy={}
local ZERO=B.from(0)
local ONE=B.from(1)
local FOUNDATION_DAY_OLD=B.from("-15055671")

local function signedStep(value)
 local step=B.from(value)
 return step
end

-- Fonksyon eritaj la konn sèlman distans pozitif apati Fondasyon.
function Legacy.oldGateQuestionDay(distance)
 local nonnegative=B.from(distance)
 assert(B.compare(nonnegative,ZERO)>=0,
   "DISCOVERY 15: oldGateQuestionDay mande distans >=0")
 return B.add(FOUNDATION_DAY_OLD,nonnegative)
end

-- Sa se adaptè defektye a: abs() detwi siy -n.
function Legacy.execute(value)
 local step=signedStep(value)
 local distance=B.abs(step)
 local isNegative=B.compare(step,ZERO)<0
 local ctx=Base.MonsterContext.new(1,1)
 ctx.mode="STAGE_30_DISCOVERY_15"
 ctx.phase="LEGACY_SIGNED_GATE_INPUT"
 ctx.status="LEGACY_GATE_QUERY_PENDING"
 local manager=Base.MonsterManager.new(ctx)
 manager.dispatcher:register("LEGACY_SIGNED_GATE_STEP",function(active,owner)
  local state={
   source="LEGACY_SIGNED_GATE_STEP_INPUT",
   signedStepDecimal=tostring(step),
   distanceMagnitudeDecimal=tostring(distance),
   foundationDayDecimal=tostring(FOUNDATION_DAY_OLD),
   negativeRequested=isNegative,
   signStillKnown=true
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("legacy.gateSignedInput.calls")
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY_15_SIGNED_GATE_REQUEST",
   signedStep=tostring(step),negative=isNegative
  }
  active.status="LEGACY_GATE_INPUT_READY"
  return B.from(step)
 end)
 manager.dispatcher:dispatch(ctx,"LEGACY_SIGNED_GATE_STEP",manager)
 ctx.phase="LEGACY_GATE_ABSOLUTE_QUERY"
 manager.dispatcher:register("LEGACY_ABSOLUTE_GATE_QUERY",function(active,owner)
  local wrong=Legacy.oldGateQuestionDay(distance)
  assert(B.compare(wrong,B.add(FOUNDATION_DAY_OLD,distance))==0,
    "DISCOVERY 15: oldGateQuestionDay istorik pa otantik")
  local state={
   source="LEGACY_ABSOLUTE_GATE_QUERY",
   signedStepDecimal=tostring(step),
   distanceMagnitudeDecimal=tostring(distance),
   foundationDayDecimal=tostring(FOUNDATION_DAY_OLD),
   queriedDayDecimal=tostring(wrong),
   negativeRequested=isNegative,
   passedAbsoluteStep=true,
   signLostForNegative=isNegative,
   preservedOriginalSignedInput=true,
   didCorrectNegativeGate=false
  }
  active:beginSemanticUpdate(state)
  owner.validationManager:requirePendingState(active)
  active:commitSemanticUpdate()
  owner.validationManager:requireNoPendingState(active)
  owner.metricsManager:bump("legacy.gateAbsoluteQuery.calls")
  owner.metricsManager:observe("legacy.gateAbsoluteQuery.day",tostring(wrong))
  active.diagnostics[#active.diagnostics+1]={
   code="DISCOVERY_15_ABSOLUTE_SIGN_LOSS",
   queryDay=tostring(wrong),signedStep=tostring(step),
   absoluteStep=tostring(distance),signLost=isNegative
  }
  active.status="LEGACY_GATE_QUERY_COMPLETE"
  return B.from(wrong)
 end)
 local wrong=manager.dispatcher:dispatch(ctx,"LEGACY_ABSOLUTE_GATE_QUERY",manager)
 return B.from(wrong),ctx
end

return Legacy
