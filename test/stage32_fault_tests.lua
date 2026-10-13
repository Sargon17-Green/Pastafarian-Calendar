local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local L=require("legacy_gate_gap")
local Short=require("short_choice_patch")
local oldGap=L.oldGateGapFromRank
local oldChoice=Short.execute
local errors,recoveries=0,0
local function recover()
 local got,ctx=S.legacyGateGapProbe(-2,1,1)
 assert(B.compare(got,43)==0 and ctx.commitToken==4
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for mode=1,8 do
 L.oldGateGapFromRank=function(rank)
  if mode==1 then error({fault="injected"},0) end
  if mode==2 then error("injected",0) end
  if mode==3 then return nil end
  if mode==4 then return false end
  if mode==5 then return "not-numeric" end
  if mode==6 then return B.from(42) end
  if mode==7 then return B.add(oldGap(rank),1) end
  return B.sub(oldGap(rank),1)
 end
 local ok=pcall(S.legacyGateGapProbe,-2,1,1)
 L.oldGateGapFromRank=oldGap
 assert(not ok,"Forged historical gap accepted: "..mode)
 errors=errors+1;recover()
end
for mode=1,2 do
 Short.execute=function(first,dir,n)
  if mode==1 then return B.from(1),{} end
  error("injected child selection fault",0)
 end
 local ok=pcall(S.legacyGateGapProbe,-2,1,1)
 Short.execute=oldChoice
 assert(not ok,"Forged PATCH 13 result accepted")
 errors=errors+1;recover()
end
assert(Short.execute==oldChoice and L.oldGateGapFromRank==oldGap
 and errors==10 and recoveries==10)
print("PASS Stage 32 faults: 10 corruptions rejected, 10 recoveries, no state leakage")
