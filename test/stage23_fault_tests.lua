local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local Stir=require("stir_patch")
local Legacy=require("legacy_reset_chain")
local originalStir=Stir.execute
local originalLegacy=Legacy.execute
local row={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local failures,recoveries=0,0
local function recovery()
 local result,ctx=S.bowlChainPatchProbe({1,121,241},{row,row,row},initial)
 assert(#result==6 and ctx.commitToken==2 and ctx.status=="PATCH_CHAIN_COMPLETE"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recoveries=recoveries+1
end
for stage=1,3 do
 for attempt=1,2 do
   local count=0
   local token={name="STAGE23_PATCH_INJECTION_"..stage.."_"..attempt}
   Stir.execute=function(...)
     count=count+1
     if count==3+stage then error(token,0) end
     return originalStir(...)
   end
   local ok,err=pcall(S.bowlChainPatchProbe,{1,121,241},{row,row,row},initial)
   Stir.execute=originalStir
   assert(not ok and err==token and count==3+stage,
      "Echèk PATCH 11 kache nan gout "..stage)
   failures=failures+1
   recovery()
 end
end
for kind=1,5 do
 local count=0
 Stir.execute=function(...)
   count=count+1
   local r,ctx=originalStir(...)
   if count==5 then
      if kind==1 then ctx.commitToken=3
      elseif kind==2 then ctx.mode="FALSIFY"
      elseif kind==3 then ctx.semanticState.previousBowls[1]="WRONG"
      elseif kind==4 then ctx.semanticState.correctedBowls[1]="WRONG"
      else ctx.branchTrace[4]="FALSIFY" end
   end
   return r,ctx
 end
 local ok=pcall(S.bowlChainPatchProbe,{1,121,241},{row,row,row},initial)
 Stir.execute=originalStir
 assert(not ok,"Patch 11 aksepte tras PATCH 10 falsifye "..kind)
 failures=failures+1
 recovery()
end
for kind=1,5 do
 Legacy.execute=function(...)
    local r,ctx=originalLegacy(...)
    if kind==1 then ctx.commitToken=0
    elseif kind==2 then ctx.semanticState.ignoredPreviousOutputs=0
    elseif kind==3 then ctx.semanticState.perDrop[2].inputBowls[1]="WRONG"
    elseif kind==4 then ctx.diagnostics[1].code="FALSIFY"
    else ctx.childContexts[1].semanticState.correctedBowls[1]="WRONG" end
    return r,ctx
 end
 local ok=pcall(S.bowlChainPatchProbe,{1,121,241},{row,row,row},initial)
 Legacy.execute=originalLegacy
 assert(not ok,"Patch 11 aksepte reset falsifye "..kind)
 failures=failures+1
 recovery()
end
assert(Stir.execute==originalStir and Legacy.execute==originalLegacy)
assert(failures==16 and recoveries==16)
print("PASS Stage 23 fault: 16 erè oswa falsifikasyon, 16 rekiperasyon")