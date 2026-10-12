local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Stir=require("stir_patch")
local old=Stir.execute
local row={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local failures,recoveries=0,0
local function recover()
 local r,ctx=S.legacyResetBowlsProbe({1,121,241},{row,row,row},initial)
 assert(#r==6 and ctx.commitToken==1 and ctx.status=="LEGACY_RESET_COMPLETE"
    and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
    and #ctx.childContexts==3)
 recoveries=recoveries+1
end
for phase=1,3 do
  for attempt=1,3 do
    local tag="STAGE22_STIR_INJECT_"..phase.."_"..attempt
    Stir.execute=function(drop,index,...)
       if index==phase then error(tag,0) end
       return old(drop,index,...)
    end
    local ok,err=pcall(S.legacyResetBowlsProbe,{1,121,241},{row,row,row},initial)
    Stir.execute=old
    assert(not ok and err==tag,"Echèk gou "..phase.." pa otantik")
    failures=failures+1
    recover()
  end
end
for forgery=1,4 do
  Stir.execute=function(...)
    local bowls,ctx=old(...)
    if forgery==1 then ctx.commitToken=3
    elseif forgery==2 then ctx.mode="FALSIFIKASYON"
    elseif forgery==3 then ctx.pendingSemanticState={}
    else ctx.branchTrace[4]="FAKE" end
    return bowls,ctx
  end
  local ok=pcall(S.legacyResetBowlsProbe,{1,121},{row,row},initial)
  Stir.execute=old
  assert(not ok,"Prèv PATCH 10 falsifye te aksepte "..forgery)
  failures=failures+1;recover()
end
assert(Stir.execute==old and failures==13 and recoveries==13)
print("PASS Stage 22 fault: 13 piki otantik, 13 rekiperasyon")
