local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Patch=require("short_choice_patch")
local original=Patch.execute
local M=B.from("170141183460469231731687303715884105727")
local N=B.add(M,1)
local failures,recoveries=0,0
local function good()
 local answer,ctx=S.legacyShortOnlyChoiceProbe(M,1,N)
 assert(answer==nil and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
   and ctx.commitToken==1 and ctx.pendingSemanticState==nil)
 recoveries=recoveries+1
end
for mode=1,5 do
 Patch.execute=function(...)
  if mode==1 then error({error="injected panic"},0) end
  if mode==2 then error("unexpected runtime error",0) end
  if mode==3 then return B.from(0) end
  if mode==4 then return B.from(1),{} end
  error("BAD_SIZE_OTHER",0)
 end
 local ok=pcall(S.legacyShortOnlyChoiceProbe,M,1,N)
 Patch.execute=original
 assert(not ok,"Unexpected wide failure was masked: "..mode)
 failures=failures+1;good()
end
for mode=1,3 do
 Patch.execute=function(...)
  if mode==1 then error({reason="broken short"},0) end
  if mode==2 then return B.from(0),{} end
  return B.from(2),{mode="FORGED",commitToken=3,branchTrace={1,2,3}}
 end
 local ok=pcall(S.legacyShortOnlyChoiceProbe,1,1,5)
 Patch.execute=original
 assert(not ok,"Short contract accepted invalid child: "..mode)
 failures=failures+1;good()
end
assert(failures==8 and recoveries==8 and Patch.execute==original)
print("PASS Stage 28 fault: 8 unexpected failures fail closed, 8 clean recoveries")
