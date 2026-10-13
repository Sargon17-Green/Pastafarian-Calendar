local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_question_adapter")
local original=Old.oldGateQuestionDay
local errors,recoveries=0,0
local function recover()
 local value,ctx=S.legacyGateQuestionProbe(-2)
 assert(B.compare(value,-15055669)==0 and ctx.commitToken==2
  and ctx.status=="LEGACY_GATE_QUERY_COMPLETE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,8 do
 Old.oldGateQuestionDay=function(n)
  if mode==1 then error({panic="injected"},0) end
  if mode==2 then error("unexpected error",0) end
  if mode==3 then return nil end
  if mode==4 then return false end
  if mode==5 then return "not decimal" end
  if mode==6 then return B.from(-15055671) end
  if mode==7 then return B.add(original(n),1) end
  return B.sub(original(n),1)
 end
 local ok=pcall(S.legacyGateQuestionProbe,-2)
 Old.oldGateQuestionDay=original
 assert(not ok,"Malformed gate legacy accepted: "..mode)
 errors=errors+1;recover()
end
assert(errors==8 and recoveries==8 and Old.oldGateQuestionDay==original)
print("PASS Stage 30 fault: 8 failures/forgeries and 8 clean recoveries")
