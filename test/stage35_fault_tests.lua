local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_positive_gate_position")
local Patch=require("positive_gate_patch")
local oldExecute=Legacy.execute
local oldCore=Patch.correctPositiveDay
local streams={{first=1,directionStep=1},{first=2,directionStep=-1}}
local failures,recoveries=0,0
local function recover()
 local v,ctx=S.positiveGatePatchProbe(2,streams)
 assert(B.compare(v,B.add(-15055671,85))==0
  and ctx.commitToken==7 and ctx.status=="PATCH_POSITIVE_GATE_COMPLETE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,14 do
 Legacy.execute=function(n,s)
  if mode==1 then error({injected=true},0) end
  if mode==2 then error("injected upstream",0) end
  local wrong,ctx=oldExecute(n,s)
  if mode==3 then return nil,ctx end
  if mode==4 then return false,ctx end
  if mode==5 then return B.add(wrong,1),ctx end
  if mode==6 then ctx.commitToken=5 end
  if mode==7 then ctx.branchTrace[6]="FORGED" end
  if mode==8 then ctx.semanticState.historicalGateDayDecimal="FORGED" end
  if mode==9 then ctx.gapSourceStates[1].correctedGapDecimal="FORGED" end
  if mode==10 then ctx.positiveGapDecimals[1]="FORGED" end
  if mode==11 then ctx.diagnostics[6].code="FORGED" end
  if mode==12 then ctx.metrics["legacy.positiveGate.calls"]=nil end
  if mode==13 then ctx.gapSourceStates[2].selectedRankDecimal="999" end
  if mode==14 then ctx.semanticState.noCorrectCumulativeResultComputed=false end
  return wrong,ctx
 end
 local ok=pcall(S.positiveGatePatchProbe,2,streams)
 Legacy.execute=oldExecute
 assert(not ok,"Stage 35 accepted forged legacy provenance: "..mode)
 failures=failures+1;recover()
end
for mode=1,6 do
 Patch.correctPositiveDay=function(n,gaps,wrong)
  if mode==1 then error("core fault",0) end
  if mode==2 then return B.from(0),{} end
  local repaired,proof=oldCore(n,gaps,wrong)
  if mode==3 then proof.addedPriorGaps=0 end
  if mode==4 then proof.previousDay=B.add(wrong,1) end
  if mode==5 then proof.lastGap=B.from(43) end
  if mode==6 then proof.recomputedFromFoundation=B.add(repaired,1) end
  return repaired,proof
 end
 local ok=pcall(S.positiveGatePatchProbe,2,streams)
 Patch.correctPositiveDay=oldCore
 assert(not ok,"Stage 35 accepted forged cumulative proof: "..mode)
 failures=failures+1;recover()
end
assert(Legacy.execute==oldExecute and Patch.correctPositiveDay==oldCore
 and failures==20 and recoveries==20)
print("PASS Stage 35 faults: 20 injected upstream/proof corruptions rejected, 20 clean recoveries")
