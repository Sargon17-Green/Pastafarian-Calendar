local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local Legacy=require("legacy_fixed_neighbor")
local S=require("spaghetti")
local saved=Legacy.execute
local drops,stones,initial={},{},{10,20,30,40,50,60}
for i=1,46 do drops[i]=1;stones[i]={w=2,b=3,s=5,m=7,r=11} end
drops[46]=720
local inside=false
local nested,innerContext,outerContext
Legacy.execute=function(...)
 if not inside then
  inside=true
  nested,innerContext=S.neighborPatchProbe(drops,stones,initial,6)
  inside=false
 end
 return saved(...)
end
local ok,outer,ctx=pcall(S.neighborPatchProbe,drops,stones,initial,1)
Legacy.execute=saved
assert(ok and nested==5 and outer==6)
assert(innerContext and ctx and innerContext~=ctx
  and ctx.commitToken==4 and innerContext.commitToken==4
  and #ctx.diagnostics==4 and #innerContext.diagnostics==4)
innerContext.semanticState.orderAtDrop46[1]=99
innerContext.legacyNeighborSemanticState.bowlsAfter46[1]="BOGUS"
assert(ctx.semanticState.orderAtDrop46[1]==6
  and ctx.legacyNeighborSemanticState.bowlsAfter46[1]~="BOGUS")
assert(Legacy.execute==saved)
print("PASS Stage 25 reentrance: true nested 46-drop PATCH 12 invocations, owned states")
