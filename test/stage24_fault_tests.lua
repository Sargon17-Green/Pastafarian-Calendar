local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local Chain=require("bowl_chain_patch")
local Perm=require("permutation_patch")
local oldChain=Chain.execute
local oldPerm=Perm.execute
local initial={10,20,30,40,50,60}
local row={w=2,b=3,s=5,m=7,r=11}
local drops,stones={},{}
for i=1,46 do drops[i]=i%7+1;stones[i]=row end
drops[46]=720
local failures,recoveries=0,0
local function recover()
 local value,ctx=S.legacyFixedNeighborProbe(drops,stones,initial,1)
 assert(value==2 and ctx.commitToken==3 and ctx.status=="LEGACY_FIXED_NEIGHBOR_COMPLETE")
 recoveries=recoveries+1
end
local function inject(mod,saved,token)
 mod.execute=function(...) error(token,0) end
 local ok,err=pcall(S.legacyFixedNeighborProbe,drops,stones,initial,1)
 mod.execute=saved
 assert(not ok and err==token,"Erè depandans pa pwopaje")
 failures=failures+1;recover()
end
inject(Chain,oldChain,{code="STAGE24_CHAIN_PANIC"})
inject(Perm,oldPerm,{code="STAGE24_PERM_PANIC"})
for kind=1,3 do
 Chain.execute=function(...)
    local output,ctx=oldChain(...)
    if kind==1 then ctx.commitToken=1
    elseif kind==2 then ctx.semanticState.carriedPreviousOutputs=44
    else ctx.semanticState.lastBowls[1]="FALSIFY" end
    return output,ctx
 end
 local ok=pcall(S.legacyFixedNeighborProbe,drops,stones,initial,1)
 Chain.execute=oldChain
 assert(not ok,"Prèv PATCH 11 falsifye aksepte "..kind)
 failures=failures+1;recover()
end
for kind=1,4 do
 Perm.execute=function(...)
    local order,ctx=oldPerm(...)
    if kind==1 then ctx.commitToken=2
    elseif kind==2 then ctx.semanticState.permutation="FAKE"
    elseif kind==3 then order[1]=order[2]
    else ctx.pendingSemanticState={} end
    return order,ctx
 end
 local ok=pcall(S.legacyFixedNeighborProbe,drops,stones,initial,1)
 Perm.execute=oldPerm
 assert(not ok,"Prèv PATCH 08 falsifye aksepte "..kind)
 failures=failures+1;recover()
end
assert(Chain.execute==oldChain and Perm.execute==oldPerm)
assert(failures==9 and recoveries==9)
for _,bad in ipairs({0,7,-1,"1",1.2}) do
 assert(not pcall(S.legacyFixedNeighborProbe,drops,stones,initial,bad))
end
print("PASS Stage 24 fault: 9 enjeksyon/falsifikasyon, 9 rekiperasyon; fail-closed")
