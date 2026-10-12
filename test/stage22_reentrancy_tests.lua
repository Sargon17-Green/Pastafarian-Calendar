local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local B=require("bigint")
local Stir=require("stir_patch")
local saved=Stir.execute
local row={w=2,b=3,s=5,m=7,r=11}
local initial={10,20,30,40,50,60}
local nested=0
for _,drop in ipairs({1,2,121,241,720}) do
 local active=false
 local captured
 Stir.execute=function(...)
   if not active then
     active=true
     local result,ctx=S.legacyResetBowlsProbe({121,241},{row,row},initial)
     captured={result,ctx}
     active=false
   end
   return saved(...)
 end
 local ok,result,ctx=pcall(S.legacyResetBowlsProbe,{drop,241},{row,row},initial)
 Stir.execute=saved
 assert(ok and captured and #result==6 and ctx.commitToken==1)
 assert(captured[2].commitToken==1 and #captured[2].childContexts==2)
 captured[2].semanticState.perDrop[1].inputBowls[1]="FAKE"
 captured[1][1].d[1]=1234
 assert(ctx.semanticState.perDrop[1].inputBowls[1]~="FAKE")
 nested=nested+1
end
assert(nested==5 and Stir.execute==saved)
print("PASS Stage 22 reentrance: 5 nested chains, copied state")
