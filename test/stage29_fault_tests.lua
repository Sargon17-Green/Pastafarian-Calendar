local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_short_only_choice")
local Stream=require("legacy_biased_choice")
local M=B.from("170141183460469231731687303715884105727")
local N=B.add(M,1)
local original=Old.execute
local oldAnswer=Stream.answerAt
local failures,recoveries=0,0
local function recover()
 local v,ctx=S.wideChoicePatchProbe(1,1,N)
 assert(v and ctx.commitToken==2 and ctx.status=="PATCH_WIDE_CHOICE_COMPLETE")
 recoveries=recoveries+1
end
for mode=1,6 do
 Old.execute=function(...)
  if mode==1 then error({panic="injected"},0) end
  if mode==2 then error("unexpected legacy failure",0) end
  if mode==3 then return B.from(1),{} end
  if mode==4 then return nil,{} end
  local v,ctx=original(...)
  if mode==5 then ctx.semanticState.wideRankAvailable=true end
  if mode==6 then ctx.branchTrace[1]="FAKE" end
  return v,ctx
 end
 local ok=pcall(S.wideChoicePatchProbe,1,1,N)
 Old.execute=original
 assert(not ok,"Inauthentic historical block accepted: "..mode)
 failures=failures+1;recover()
end
for mode=1,4 do
 Stream.answerAt=function(...)
  if mode==1 then error("synthetic digit fault",0) end
  if mode==2 then return B.from(0) end
  if mode==3 then return B.add(M,1) end
  return nil
 end
 local ok=pcall(S.wideChoicePatchProbe,1,1,N)
 Stream.answerAt=oldAnswer
 assert(not ok,"Bad wide digit escaped fail-closed: "..mode)
 failures=failures+1;recover()
end
assert(Old.execute==original and Stream.answerAt==oldAnswer
   and failures==10 and recoveries==10)
print("PASS Stage 29 faults: 10 invalid legacy/digit calls and 10 clean recoveries")
