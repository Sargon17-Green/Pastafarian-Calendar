local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_biased_choice")
local savedAnswer=Legacy.answerAt
local savedPick=Legacy.oldBiasedModuloPick
local M=B.from("170141183460469231731687303715884105727")
local failures,recoveries=0,0
local function recover()
 local answer,ctx=S.legacyBiasedChoiceProbe(M,1,5)
 assert(B.compare(answer,2)==0 and ctx.commitToken==2
    and ctx.status=="LEGACY_BIASED_PICK_COMPLETE"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for i=1,4 do
 local injected={fault=i}
 Legacy.answerAt=function(...) error(injected,0) end
 local ok,err=pcall(S.legacyBiasedChoiceProbe,M,1,5)
 Legacy.answerAt=savedAnswer
 assert(not ok and err==injected)
 failures=failures+1;recover()
end
for i=1,4 do
 Legacy.oldBiasedModuloPick=function(...)
  if i==1 then return B.from(0) end
  if i==2 then return B.from(6) end
  if i==3 then error({fault="PICK"},0) end
  return nil
 end
 local ok=pcall(S.legacyBiasedChoiceProbe,M,1,5)
 Legacy.oldBiasedModuloPick=savedPick
 assert(not ok)
 failures=failures+1;recover()
end
assert(Legacy.answerAt==savedAnswer and Legacy.oldBiasedModuloPick==savedPick)
assert(failures==8 and recoveries==8)
print("PASS Stage 26 fault: 8 genuine errors, 8 clean recoveries")
