local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local Perm=require("permutation_patch")
local previous=Perm.execute
local row={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local drops,stones={},{}
for i=1,46 do drops[i]=1;stones[i]=row end
drops[46]=720
local nested=0
for _,qid in ipairs({1,3,6}) do
 local active=false
 local inner,innerCtx
 Perm.execute=function(...)
   if not active then
     active=true
     inner,innerCtx=S.legacyFixedNeighborProbe(drops,stones,initial,6)
     active=false
   end
   return previous(...)
 end
 local ok,value,ctx=pcall(S.legacyFixedNeighborProbe,drops,stones,initial,qid)
 Perm.execute=previous
 assert(ok and inner==1 and innerCtx and ctx)
 assert(value==qid%6+1 and ctx.commitToken==3 and innerCtx.commitToken==3)
 innerCtx.semanticState.orderAtDrop46[1]=100
 innerCtx.stage23SemanticState.perDrop[46].outputBowls[1]="FAKE"
 assert(ctx.semanticState.orderAtDrop46[1]~=100
    and ctx.stage23SemanticState.perDrop[46].outputBowls[1]~="FAKE")
 nested=nested+1
end
assert(nested==3 and Perm.execute==previous)
print("PASS Stage 24 reentrance: 3 nested 46-gout chains, eta posede endepandan")
