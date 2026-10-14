local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_gap")
local Patch=require("gate_gap_patch")
local genuine=Old.execute
local core=Patch.correctGateGap
local failures,recoveries=0,0
local function recover()
 local got,ctx=S.gateGapPatchProbe(-1,1,1)
 assert(B.compare(got,42)==0
  and ctx.commitToken==5 and ctx.status=="PATCH_GATE_GAP_COMPLETE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,10 do
 Old.execute=function(signed,first,dir)
  if mode==1 then error({panic="injected"},0) end
  if mode==2 then error("upstream fault",0) end
  local gap,ctx=genuine(signed,first,dir)
  if mode==3 then return nil,ctx end
  if mode==4 then return false,ctx end
  if mode==5 then return B.add(gap,1),ctx end
  if mode==6 then ctx.commitToken=3 end
  if mode==7 then ctx.branchTrace[4]="FORGED_HANDLER" end
  if mode==8 then ctx.semanticState.selectedRankDecimal="FAKE" end
  if mode==9 then ctx.previousSignedGateState.correctedQuestionDayDecimal="0" end
  if mode==10 then ctx.metrics["legacy.gateGap.extraOne.calls"]=nil end
  return gap,ctx
 end
 local ok=pcall(S.gateGapPatchProbe,-1,1,1)
 Old.execute=genuine
 assert(not ok,"Forged legacy state accepted: "..mode)
 failures=failures+1;recover()
end
for mode=1,4 do
 Patch.correctGateGap=function(rank,wrong)
  if mode==1 then error("core failure",0) end
  if mode==2 then return B.from(41),{} end
  local corrected,proof=core(rank,wrong)
  if mode==3 then proof.removedExtraOne=false end
  if mode==4 then proof.oldGap=B.add(wrong,1) end
  return corrected,proof
 end
 local ok=pcall(S.gateGapPatchProbe,-1,1,1)
 Patch.correctGateGap=core
 assert(not ok,"Forged correction proof accepted: "..mode)
 failures=failures+1;recover()
end
assert(Old.execute==genuine and Patch.correctGateGap==core
 and failures==14 and recoveries==14)
print("PASS Stage 33 faults: 14 upstream/proof failures rejected and 14 clean recoveries")
