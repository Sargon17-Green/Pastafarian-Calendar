local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_aliased_stir")
local Save=require("save_patch")
local oldLegacy=Legacy.execute
local oldSave=Save.savePatch
local stones={w=2,b=3,s=5,m=7,r=11}
local bowls={10,20,30,40,50,60}
local failures,recoveries=0,0
local function recover()
 local answer,ctx=S.stirPatchProbe(241,4,bowls,stones)
 assert(#answer==6 and ctx.commitToken==4 and ctx.status=="PATCH_STIR_RETURNED"
     and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for i=1,4 do
 local tag="LEGACY_STIR_FAIL_"..i
 Legacy.execute=function() error(tag,0) end
 local ok,msg=pcall(S.stirPatchProbe,241,4,bowls,stones)
 Legacy.execute=oldLegacy
 assert(not ok and msg==tag)
 failures=failures+1;recover()
end
for i=1,6 do
 local tag="SNAPSHOT_SAVE_FAIL_"..i
 local hits=0
 Save.savePatch=function(...)
   hits=hits+1
   if hits==12+i then error(tag,0) end
   return oldSave(...)
 end
 local ok,msg=pcall(S.stirPatchProbe,241,4,bowls,stones)
 Save.savePatch=oldSave
 assert(not ok and msg==tag,"Erè SAVE pa deklanche nan pozisyon "..i)
 failures=failures+1;recover()
end
for i=1,5 do
 Legacy.execute=function(...)
   local wrong,ctx=oldLegacy(...)
   if i==1 then ctx.semanticState.correctedOrder[1]=7
   elseif i==2 then ctx.semanticState.previousBowls[1]="777"
   elseif i==3 then ctx.semanticState.historicalAliasedBowls[1]="777"
   elseif i==4 then ctx.semanticState.correctedPours[1]=nil
   else ctx.diagnostics[3].samePhysicalWorkingTable=false end
   return wrong,ctx
 end
 local ok=pcall(S.stirPatchProbe,241,4,bowls,stones)
 Legacy.execute=oldLegacy
 assert(not ok,"Tras falsifye pa bloke: "..i)
 failures=failures+1;recover()
end
assert(Legacy.execute==oldLegacy and Save.savePatch==oldSave)
assert(failures==15 and recoveries==15)
print("PASS Stage 21 fault: 15 erè otantik ak 15 rekiperasyon")
