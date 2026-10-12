local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local B=require("bigint")
local Stir=require("stir_patch")
local saved=Stir.execute
local stones={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local nested=0
for _,drop in ipairs({1,2,121,241,720}) do
 local active=false
 local innerResult,innerCtx
 Stir.execute=function(...)
    if not active then
      active=true
      innerResult,innerCtx=S.bowlChainPatchProbe({241,121},{stones,stones},initial)
      active=false
    end
    return saved(...)
 end
 local ok,result,ctx=pcall(S.bowlChainPatchProbe,{drop,241},{stones,stones},initial)
 Stir.execute=saved
 assert(ok and innerResult and innerCtx and #result==6 and ctx.commitToken==2)
 assert(innerCtx.commitToken==2 and #innerCtx.patchedChildContexts==2)
 innerCtx.semanticState.perDrop[1].outputBowls[1]="FAKE"
 innerResult[1].d[1]=1234
 assert(ctx.semanticState.perDrop[1].outputBowls[1]~="FAKE")
 nested=nested+1
end
assert(Stir.execute==saved and nested==5)
print("PASS Stage 23 reentrance: 5 nested chains, no state leakage")