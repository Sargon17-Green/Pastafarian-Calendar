local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local Legacy=require("legacy_fixed_neighbor")
local S=require("spaghetti")
local saved=Legacy.execute
local drops,stones,initial={},{},{10,20,30,40,50,60}
for i=1,46 do drops[i]=1;stones[i]={w=2,b=3,s=5,m=7,r=11} end
drops[46]=720
local failures,recoveries=0,0
local function recover()
 local val,ctx=S.neighborPatchProbe(drops,stones,initial,1)
 assert(val==6 and ctx.commitToken==4 and ctx.status=="PATCH_NEIGHBOR_COMPLETE")
 recoveries=recoveries+1
end
local token={code="STAGE_25_LEGACY_EXECUTION_PANIC"}
Legacy.execute=function(...) error(token,0) end
local ok,err=pcall(S.neighborPatchProbe,drops,stones,initial,1)
Legacy.execute=saved
assert(not ok and err==token)
failures=failures+1;recover()
for mode=1,7 do
 Legacy.execute=function(...)
  local val,ctx=saved(...)
  if mode==1 then ctx.commitToken=2
  elseif mode==2 then ctx.semanticState.selectedNextId=6
  elseif mode==3 then ctx.semanticState.orderAtDrop46[1]=1
  elseif mode==4 then ctx.permutationContext.semanticState.rankOneBased=719
  elseif mode==5 then ctx.permutationContext.semanticState.permutation="BAD"
  elseif mode==6 then ctx.stage23SemanticState.lastBowls[2]="BOGUS"
  elseif mode==7 then ctx.diagnostics[3].selectedNextId=7
  end
  return val,ctx
 end
 local passed=pcall(S.neighborPatchProbe,drops,stones,initial,1)
 Legacy.execute=saved
 assert(not passed,"PATCH 12 pa dwe aksepte tras falsifye "..mode)
 failures=failures+1;recover()
end
for _,bad in ipairs({0,7,-1,"2",1.2}) do
 assert(not pcall(S.neighborPatchProbe,drops,stones,initial,bad))
end
assert(Legacy.execute==saved and failures==8 and recoveries==8)
print("PASS Stage 25 fault: 8 true failures/forgeries; 8 clean recoveries")
