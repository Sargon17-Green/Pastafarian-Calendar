local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_question_adapter")
local original=Old.execute
local errors,recoveries=0,0
local function recover()
 local value,ctx=S.gateQuestionPatchProbe(-2)
 assert(B.compare(value,-15055673)==0 and ctx.commitToken==3
   and ctx.status=="PATCH_SIGNED_GATE_COMPLETE"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,10 do
 Old.execute=function(step)
  if mode==1 then error({injected="panic"},0) end
  if mode==2 then error("injected upstream failure",0) end
  local answer,ctx=original(step)
  if mode==3 then return nil,ctx end
  if mode==4 then return B.add(answer,1),ctx end
  if mode==5 then ctx.commitToken=1 end
  if mode==6 then ctx.branchTrace[2]="FORGED_HANDLER" end
  if mode==7 then ctx.semanticState.signedStepDecimal="0" end
  if mode==8 then ctx.metrics["legacy.gateSignedInput.calls"]=0 end
  if mode==9 then ctx.diagnostics[2].code="FORGED_DIAGNOSTIC" end
  if mode==10 then ctx.semanticState.didCorrectNegativeGate=true end
  return answer,ctx
 end
 local ok=pcall(S.gateQuestionPatchProbe,-2)
 Old.execute=original
 assert(not ok,"Forged historical gate accepted: "..mode)
 errors=errors+1;recover()
end
assert(errors==10 and recoveries==10 and Old.execute==original)
print("PASS Stage 31 fault: 10 forged/upstream failures rejected, 10 clean patch recoveries")
