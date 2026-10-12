local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local Helper=require("stage23_oracle_helper")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local pairs={{F,F},{F+1,F-1},{F-5,F+9}}
local completed=0
for _,pair in ipairs(pairs) do
 local c,t=pair[1],pair[2]
 local initial=O.initialBowls(O.workCounts(c,t))
 local drops,stones,oracleRows,history={},{},{},{}
 for i=1,3 do
   local drop,ctx=S.visibleDropSpaghetti(c,t,i,history)
   assert(ctx.status=="PATCH_VISIBLE_COMPLETE" and ctx.completedGrinds==11)
   drops[i]=B.from(drop);history[i]=B.from(drop)
   local rock=O.STONES[i]
   stones[i]={w=rock[1],b=rock[2],s=rock[3],m=rock[4],r=rock[5]}
   oracleRows[i]={rock[1],rock[2],rock[3],rock[4],rock[5]}
 end
 local result,ctx=S.bowlChainPatchProbe(drops,stones,initial)
 local expected=Helper.apply(initial,drops,oracleRows)
 assert(ctx.semanticState.carriedPreviousOutputs==2
    and #ctx.childContexts==3 and #ctx.patchedChildContexts==3)
 for id=1,6 do assert(B.compare(result[id],expected[id])==0) end
 completed=completed+1
end
local got,ctx=S.visibleBowlChainPatchProbe(F,F,3)
assert(ctx.mode=="STAGE_23_PATCH_11"
   and ctx.visibleDropCount==3 and #ctx.visibleContexts==3
   and ctx.metrics["patch11.visible.calls"]==1)
local public=S.visibleResetChainSpaghetti(F,F,3)
for id=1,6 do assert(B.compare(got[id],public[id])==0) end
assert(select("#",S.visibleResetChainSpaghetti(F,F,1))==1)
print("PASS Stage 23 real: 3 koup jou, 9 gout natif, PATCH 11 kòrèk")