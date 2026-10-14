local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_positive_gate_position")
local Gap=require("gate_gap_patch")
local originalPosition=Old.oldPositivePosition
local originalGap=Gap.execute
local streams={{first=1,directionStep=1},{first=2,directionStep=-1}}
local errors,recoveries=0,0
local function recover()
 local value,ctx=S.legacyPositiveGateProbe(2,streams)
 assert(B.compare(value,-15055671+43)==0
  and ctx.status=="LEGACY_POSITIVE_GATE_COMPLETE"
  and ctx.commitToken==6 and ctx.pendingSemanticState==nil
  and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,9 do
 Old.oldPositivePosition=function(gap)
  if mode==1 then error({panic="injected"},0) end
  if mode==2 then error("injected origin failure",0) end
  if mode==3 then return nil end
  if mode==4 then return false end
  if mode==5 then return "not-decimal" end
  if mode==6 then return B.from(0) end
  if mode==7 then return B.add(originalPosition(gap),1) end
  if mode==8 then return B.sub(originalPosition(gap),1) end
  return B.add(originalPosition(gap),42)
 end
 local ok=pcall(S.legacyPositiveGateProbe,2,streams)
 Old.oldPositivePosition=originalPosition
 assert(not ok,"Malformed legacy position accepted: "..mode)
 errors=errors+1;recover()
end
for mode=1,5 do
 Gap.execute=function(step,first,dir)
  if mode==1 then error("upstream gate gap failure",0) end
  local gap,ctx=originalGap(step,first,dir)
  if mode==2 then return B.add(gap,1),ctx end
  if mode==3 then ctx.commitToken=4 end
  if mode==4 then ctx.semanticState.correctedGapDecimal="FORGED" end
  if mode==5 then ctx.status="FORGED" end
  return gap,ctx
 end
 local ok=pcall(S.legacyPositiveGateProbe,2,streams)
 Gap.execute=originalGap
 assert(not ok,"Forged PATCH16 context accepted: "..mode)
 errors=errors+1;recover()
end
assert(Old.oldPositivePosition==originalPosition and Gap.execute==originalGap
 and errors==14 and recoveries==14)
print("PASS Stage 34 fault: 14 legacy/upstream failures rejected and 14 clean recoveries")
